"""
Convert PROJECT_REPORT.md to PDF using reportlab
"""
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle, Preformatted
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT, TA_CENTER
import re

def parse_markdown_to_pdf(md_file, pdf_file):
    # Read markdown
    with open(md_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Create PDF
    doc = SimpleDocTemplate(
        pdf_file,
        pagesize=A4,
        rightMargin=2*cm,
        leftMargin=2*cm,
        topMargin=2*cm,
        bottomMargin=2*cm
    )
    
    # Styles
    styles = getSampleStyleSheet()
    
    # Custom styles
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=24,
        textColor=colors.HexColor('#2c3e50'),
        spaceAfter=30,
        alignment=TA_CENTER
    )
    
    h1_style = ParagraphStyle(
        'CustomH1',
        parent=styles['Heading1'],
        fontSize=18,
        textColor=colors.HexColor('#2c3e50'),
        spaceAfter=12,
        spaceBefore=20,
        borderWidth=2,
        borderColor=colors.HexColor('#3498db'),
        borderPadding=5
    )
    
    h2_style = ParagraphStyle(
        'CustomH2',
        parent=styles['Heading2'],
        fontSize=14,
        textColor=colors.HexColor('#34495e'),
        spaceAfter=10,
        spaceBefore=15
    )
    
    h3_style = ParagraphStyle(
        'CustomH3',
        parent=styles['Heading3'],
        fontSize=12,
        textColor=colors.HexColor('#7f8c8d'),
        spaceAfter=8,
        spaceBefore=10
    )
    
    body_style = ParagraphStyle(
        'CustomBody',
        parent=styles['BodyText'],
        fontSize=10,
        leading=14,
        spaceAfter=6
    )
    
    code_style = ParagraphStyle(
        'Code',
        parent=styles['Code'],
        fontSize=8,
        fontName='Courier',
        backColor=colors.HexColor('#f8f8f8'),
        borderWidth=1,
        borderColor=colors.HexColor('#ddd'),
        borderPadding=10
    )
    
    # Parse content
    story = []
    lines = content.split('\n')
    i = 0
    in_code_block = False
    code_buffer = []
    in_table = False
    table_buffer = []
    
    while i < len(lines):
        line = lines[i]
        
        # Code blocks
        if line.startswith('```'):
            if in_code_block:
                # End code block
                code_text = '\n'.join(code_buffer)
                story.append(Preformatted(code_text, code_style))
                story.append(Spacer(1, 0.3*cm))
                code_buffer = []
                in_code_block = False
            else:
                # Start code block
                in_code_block = True
            i += 1
            continue
        
        if in_code_block:
            code_buffer.append(line)
            i += 1
            continue
        
        # Table detection
        if '|' in line and line.strip().startswith('|'):
            if not in_table:
                in_table = True
                table_buffer = []
            table_buffer.append(line)
            i += 1
            # Check if next line is separator or end of table
            if i < len(lines) and not ('|' in lines[i] and lines[i].strip()):
                # End of table
                story.extend(create_table_from_markdown(table_buffer))
                story.append(Spacer(1, 0.3*cm))
                in_table = False
                table_buffer = []
            continue
        else:
            if in_table:
                # End table if we hit non-table line
                story.extend(create_table_from_markdown(table_buffer))
                story.append(Spacer(1, 0.3*cm))
                in_table = False
                table_buffer = []
        
        # Headers
        if line.startswith('# '):
            text = line[2:].strip()
            text = clean_markdown(text)
            if i == 0:  # First line is title
                story.append(Paragraph(text, title_style))
            else:
                story.append(Paragraph(text, h1_style))
            story.append(Spacer(1, 0.2*cm))
        
        elif line.startswith('## '):
            text = clean_markdown(line[3:].strip())
            story.append(Paragraph(text, h2_style))
            story.append(Spacer(1, 0.1*cm))
        
        elif line.startswith('### '):
            text = clean_markdown(line[4:].strip())
            story.append(Paragraph(text, h3_style))
        
        # Horizontal rule
        elif line.startswith('---'):
            story.append(Spacer(1, 0.3*cm))
            story.append(Paragraph('_' * 80, body_style))
            story.append(Spacer(1, 0.3*cm))
        
        # Lists
        elif line.strip().startswith('- ') or line.strip().startswith('* ') or re.match(r'^\d+\.', line.strip()):
            text = clean_markdown(line.strip()[2:] if line.strip().startswith(('- ', '* ')) else re.sub(r'^\d+\.\s+', '', line.strip()))
            bullet = '•' if line.strip().startswith(('- ', '* ')) else '○'
            indent = len(line) - len(line.lstrip())
            text = '&nbsp;' * (indent * 2) + bullet + ' ' + text
            story.append(Paragraph(text, body_style))
        
        # Regular text
        elif line.strip():
            text = clean_markdown(line.strip())
            story.append(Paragraph(text, body_style))
        
        # Empty line
        else:
            story.append(Spacer(1, 0.2*cm))
        
        i += 1
    
    # Build PDF
    print("Generating PDF... This may take a moment.")
    doc.build(story)
    print(f"✓ PDF generated successfully: {pdf_file}")

def clean_markdown(text):
    """Remove markdown formatting and clean text"""
    # Remove emojis and special characters that might cause issues
    text = re.sub(r'[✅❌📱🎯🏗️🔧📊🧪📡🔐📈🎓🔮📝📞🚀🌍🏗️]', '', text)
    
    # Bold
    text = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', text)
    text = re.sub(r'__(.+?)__', r'<b>\1</b>', text)
    
    # Italic
    text = re.sub(r'\*(.+?)\*', r'<i>\1</i>', text)
    text = re.sub(r'_(.+?)_', r'<i>\1</i>', text)
    
    # Code
    text = re.sub(r'`(.+?)`', r'<font face="Courier">\1</font>', text)
    
    # Links - just show text
    text = re.sub(r'\[(.+?)\]\(.+?\)', r'\1', text)
    
    return text

def create_table_from_markdown(table_lines):
    """Convert markdown table to reportlab table"""
    if not table_lines:
        return []
    
    # Parse table data
    data = []
    for line in table_lines:
        if line.strip().startswith('|---') or line.strip().startswith('| ---'):
            continue  # Skip separator line
        
        cells = [cell.strip() for cell in line.split('|')[1:-1]]
        if cells:
            data.append(cells)
    
    if not data:
        return []
    
    # Create table
    table = Table(data, colWidths=[None] * len(data[0]))
    
    # Style
    style = TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#3498db')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
        ('BACKGROUND', (0, 1), (-1, -1), colors.white),
        ('GRID', (0, 0), (-1, -1), 1, colors.HexColor('#ddd')),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f9f9f9')])
    ])
    
    table.setStyle(style)
    return [table]

if __name__ == '__main__':
    parse_markdown_to_pdf('PROJECT_REPORT.md', 'PROJECT_REPORT.pdf')
