"""
Convert PROJECT_REPORT.md to a printable HTML file
"""
import markdown
import os

# Read markdown
with open('PROJECT_REPORT.md', 'r', encoding='utf-8') as f:
    md_content = f.read()

# Convert to HTML
html_body = markdown.markdown(
    md_content,
    extensions=['tables', 'fenced_code', 'toc', 'nl2br', 'sane_lists']
)

# Create styled HTML document
html_doc = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Smart Plug Project Report</title>
    <style>
        @media print {{
            @page {{
                size: A4;
                margin: 2cm;
            }}
            body {{
                margin: 0;
                padding: 0;
            }}
            h1, h2, h3 {{
                page-break-after: avoid;
            }}
            table, pre, blockquote {{
                page-break-inside: avoid;
            }}
        }}
        
        body {{
            font-family: 'Segoe UI', 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 210mm;
            margin: 0 auto;
            padding: 20px;
            background: #fff;
        }}
        
        h1 {{
            color: #2c3e50;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
            margin-top: 40px;
            font-size: 28px;
        }}
        
        h1:first-child {{
            margin-top: 0;
            text-align: center;
            font-size: 36px;
        }}
        
        h2 {{
            color: #34495e;
            border-bottom: 2px solid #95a5a6;
            padding-bottom: 8px;
            margin-top: 30px;
            font-size: 22px;
        }}
        
        h3 {{
            color: #7f8c8d;
            margin-top: 20px;
            font-size: 18px;
        }}
        
        h4 {{
            color: #95a5a6;
            margin-top: 15px;
            font-size: 16px;
        }}
        
        p {{
            margin: 10px 0;
            text-align: justify;
        }}
        
        code {{
            background-color: #f4f4f4;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
            font-size: 0.9em;
            color: #e74c3c;
        }}
        
        pre {{
            background-color: #f8f8f8;
            border: 1px solid #ddd;
            border-left: 4px solid #3498db;
            border-radius: 4px;
            padding: 15px;
            overflow-x: auto;
            margin: 15px 0;
        }}
        
        pre code {{
            background-color: transparent;
            padding: 0;
            color: #333;
            font-size: 0.85em;
            line-height: 1.4;
        }}
        
        table {{
            border-collapse: collapse;
            width: 100%;
            margin: 20px 0;
            font-size: 0.9em;
        }}
        
        th {{
            background-color: #3498db;
            color: white;
            font-weight: bold;
            padding: 12px;
            text-align: left;
            border: 1px solid #2980b9;
        }}
        
        td {{
            padding: 10px 12px;
            border: 1px solid #ddd;
        }}
        
        tr:nth-child(even) {{
            background-color: #f9f9f9;
        }}
        
        tr:hover {{
            background-color: #f0f0f0;
        }}
        
        ul, ol {{
            margin: 10px 0;
            padding-left: 30px;
        }}
        
        li {{
            margin: 8px 0;
        }}
        
        blockquote {{
            border-left: 4px solid #3498db;
            padding-left: 20px;
            margin: 20px 0;
            color: #555;
            font-style: italic;
            background-color: #f9f9f9;
            padding: 15px 20px;
        }}
        
        hr {{
            border: none;
            border-top: 2px solid #eee;
            margin: 30px 0;
        }}
        
        a {{
            color: #3498db;
            text-decoration: none;
        }}
        
        a:hover {{
            text-decoration: underline;
        }}
        
        strong {{
            color: #2c3e50;
            font-weight: 600;
        }}
        
        .print-button {{
            position: fixed;
            top: 20px;
            right: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 12px 24px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
            font-weight: 600;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
            z-index: 1000;
        }}
        
        .print-button:hover {{
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(0,0,0,0.3);
        }}
        
        @media print {{
            .print-button {{
                display: none;
            }}
        }}
        
        /* Checkmark styling */
        li:has(input[type="checkbox"]) {{
            list-style: none;
            margin-left: -20px;
        }}
        
        /* Status badges */
        .status-complete {{
            background: #27ae60;
            color: white;
            padding: 2px 8px;
            border-radius: 3px;
            font-size: 0.85em;
            font-weight: 600;
        }}
    </style>
</head>
<body>
    <button class="print-button" onclick="window.print()">🖨️ Print / Save as PDF</button>
    
    <div class="content">
        {html_body}
    </div>
    
    <script>
        // Add print keyboard shortcut
        document.addEventListener('keydown', function(e) {{
            if ((e.ctrlKey || e.metaKey) && e.key === 'p') {{
                e.preventDefault();
                window.print();
            }}
        }});
    </script>
</body>
</html>"""

# Write HTML file
with open('PROJECT_REPORT.html', 'w', encoding='utf-8') as f:
    f.write(html_doc)

print("✓ HTML file generated: PROJECT_REPORT.html")
print("\nTo create PDF:")
print("1. Open PROJECT_REPORT.html in your web browser")
print("2. Press Ctrl+P (or click the 'Print / Save as PDF' button)")
print("3. Select 'Save as PDF' as the printer")
print("4. Click 'Save' and choose PROJECT_REPORT.pdf as filename")
print("\nAlternatively, the HTML file is now open-ready in your default browser!")

# Try to open in default browser
import webbrowser
file_path = os.path.abspath('PROJECT_REPORT.html')
webbrowser.open('file://' + file_path)
