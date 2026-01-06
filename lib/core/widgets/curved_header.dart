import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// A beautifully curved header widget with glowing border effect
class CurvedHeader extends StatelessWidget {
  final Widget child;
  final double height;
  final Gradient? gradient;
  final bool showGlowingBorder;
  final double borderRadius;

  const CurvedHeader({
    super.key,
    required this.child,
    this.height = 180,
    this.gradient,
    this.showGlowingBorder = true,
    this.borderRadius = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Stack(
        children: [
          // Main curved container
          ClipPath(
            clipper: _CurvedHeaderClipper(borderRadius: borderRadius),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                bottom: 24,
              ),
              decoration: BoxDecoration(gradient: gradient ?? _defaultGradient),
              child: Stack(
                children: [
                  // Decorative elements
                  _buildDecorativeOrbs(),
                  // Glass noise overlay
                  Positioned.fill(
                    child: CustomPaint(painter: _HeaderNoisePainter()),
                  ),
                  // Content
                  child,
                ],
              ),
            ),
          ),
          // Glowing border effect
          if (showGlowingBorder)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomPaint(
                painter: _GlowingBorderPainter(borderRadius: borderRadius),
                size: Size(double.infinity, height),
              ),
            ),
        ],
      ),
    );
  }

  LinearGradient get _defaultGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppTheme.primaryColor.withOpacity(0.4),
      AppTheme.darkSurface.withOpacity(0.95),
      AppTheme.darkBackground,
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  Widget _buildDecorativeOrbs() {
    return Stack(
      children: [
        // Top right orb
        Positioned(
          top: -30,
          right: -20,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.3),
                  AppTheme.primaryColor.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Bottom left orb
        Positioned(
          bottom: -20,
          left: -30,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.secondaryColor.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Accent orb
        Positioned(
          top: 40,
          left: 60,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentColor.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Standard header height constants for consistency across screens
const double kHeaderContentHeight = 120.0; // For ScreenHeader (simpler layout)
const double kHomeHeaderContentHeight =
    160.0; // For HomeHeader (with welcome card)

/// Home screen specific header with welcome message and modern design
class HomeHeader extends StatelessWidget {
  final String userName;
  final VoidCallback? onRefresh;
  final VoidCallback? onNotifications;
  final int deviceCount;

  const HomeHeader({
    super.key,
    required this.userName,
    this.onRefresh,
    this.onNotifications,
    this.deviceCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + kHomeHeaderContentHeight;

    return Container(
      width: double.infinity,
      // Fixed height to prevent layout issues
      height: headerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main curved container with gradient
          ClipPath(
            clipper: _CurvedHeaderClipper(borderRadius: 36),
            child: Container(
              width: double.infinity,
              height: headerHeight,
              padding: EdgeInsets.only(
                top: topPadding + 16,
                left: 20,
                right: 20,
                bottom: 36,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2D1B69), // Deep purple
                    const Color(0xFF1A1035), // Dark purple
                    AppTheme.darkBackground,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Animated mesh background
                  _buildMeshBackground(),
                  // Glassmorphism card
                  _buildGlassCard(context, greeting),
                ],
              ),
            ),
          ),
          // Glowing animated border
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _GlowingAnimatedBorder(borderRadius: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildMeshBackground() {
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Primary orb - top right
          Positioned(
            top: -40,
            right: -30,
            child: _AnimatedOrb(
              size: 160,
              color: AppTheme.primaryColor.withOpacity(0.4),
              blur: 60,
            ),
          ),
          // Secondary orb - bottom left
          Positioned(
            bottom: 0,
            left: -40,
            child: _AnimatedOrb(
              size: 120,
              color: AppTheme.secondaryColor.withOpacity(0.3),
              blur: 50,
            ),
          ),
          // Accent orb - center
          Positioned(
            top: 60,
            right: 100,
            child: _AnimatedOrb(
              size: 80,
              color: AppTheme.accentColor.withOpacity(0.25),
              blur: 40,
            ),
          ),
          // Small sparkle orbs
          ..._buildSparkles(),
        ],
      ),
    );
  }

  List<Widget> _buildSparkles() {
    return [
      Positioned(
        top: 30,
        left: 50,
        child: _SparkleOrb(size: 6, color: Colors.white.withOpacity(0.5)),
      ),
      Positioned(
        top: 80,
        right: 60,
        child: _SparkleOrb(
          size: 4,
          color: AppTheme.secondaryColor.withOpacity(0.6),
        ),
      ),
      Positioned(
        bottom: 50,
        left: 100,
        child: _SparkleOrb(
          size: 5,
          color: AppTheme.accentColor.withOpacity(0.5),
        ),
      ),
      Positioned(
        bottom: 80,
        right: 120,
        child: _SparkleOrb(size: 3, color: Colors.white.withOpacity(0.4)),
      ),
    ];
  }

  Widget _buildGlassCard(BuildContext context, String greeting) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.04),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Welcome icon
                _buildWelcomeIcon(),
                const SizedBox(width: 16),
                // Greeting and name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        greeting,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      _buildDeviceStats(),
                    ],
                  ),
                ),
                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeIcon() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onRefresh != null)
          _HeaderIconButton(
            icon: Icons.refresh_rounded,
            onTap: onRefresh!,
            tooltip: 'Refresh',
          ),
        if (onNotifications != null) ...[
          const SizedBox(width: 8),
          _HeaderIconButton(
            icon: Icons.notifications_outlined,
            onTap: onNotifications!,
            tooltip: 'Notifications',
            showBadge: true,
          ),
        ],
      ],
    );
  }

  Widget _buildDeviceStats() {
    return Row(
      children: [
        Icon(
          Icons.devices_rounded,
          size: 12,
          color: Colors.white.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          '$deviceCount ${deviceCount == 1 ? 'device' : 'devices'} connected',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }
}

/// Simple curved header for other screens
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? accentColor;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actions,
    this.leading,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.primaryColor;
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + kHeaderContentHeight;

    return Container(
      width: double.infinity,
      height: headerHeight,
      child: Stack(
        children: [
          // Curved background
          ClipPath(
            clipper: _CurvedHeaderClipper(borderRadius: 36),
            child: Container(
              width: double.infinity,
              height: headerHeight,
              padding: EdgeInsets.only(
                top: topPadding + 12,
                left: 16,
                right: 16,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.25),
                    AppTheme.darkSurface.withOpacity(0.85),
                    AppTheme.darkBackground.withOpacity(0.95),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  // Subtle accent orb
                  Positioned(
                    top: -20,
                    right: 40,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [color.withOpacity(0.15), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Row(
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 12),
                      ] else if (Navigator.canPop(context)) ...[
                        _HeaderIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context),
                          tooltip: 'Back',
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (icon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color.withOpacity(0.2),
                                color.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: color.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: Icon(icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (actions != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions!
                              .map(
                                (a) => Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: a,
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Glowing border
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomPaint(
              painter: _GlowingBorderPainter(borderRadius: 36, color: color),
              size: const Size(double.infinity, 0),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widgets
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool showBadge;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: Colors.white.withOpacity(0.9), size: 22),
                if (showBadge)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.darkBackground,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedOrb extends StatefulWidget {
  final double size;
  final Color color;
  final double blur;

  const _AnimatedOrb({
    required this.size,
    required this.color,
    required this.blur,
  });

  @override
  State<_AnimatedOrb> createState() => _AnimatedOrbState();
}

class _AnimatedOrbState extends State<_AnimatedOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size * _animation.value,
          height: widget.size * _animation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color,
                blurRadius: widget.blur,
                spreadRadius: widget.size * 0.1,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SparkleOrb extends StatefulWidget {
  final double size;
  final Color color;

  const _SparkleOrb({required this.size, required this.color});

  @override
  State<_SparkleOrb> createState() => _SparkleOrbState();
}

class _SparkleOrbState extends State<_SparkleOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(_animation.value),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_animation.value * 0.5),
                blurRadius: widget.size * 2,
                spreadRadius: widget.size * 0.5,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowingAnimatedBorder extends StatefulWidget {
  final double borderRadius;

  const _GlowingAnimatedBorder({required this.borderRadius});

  @override
  State<_GlowingAnimatedBorder> createState() => _GlowingAnimatedBorderState();
}

class _GlowingAnimatedBorderState extends State<_GlowingAnimatedBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _GlowingBorderPainter(
            borderRadius: widget.borderRadius,
            glowIntensity: _animation.value,
          ),
          size: const Size(double.infinity, 0),
        );
      },
    );
  }
}

// Clipper for curved header shape - matches settings screen style
class _CurvedHeaderClipper extends CustomClipper<Path> {
  final double borderRadius;

  _CurvedHeaderClipper({this.borderRadius = 36});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - borderRadius);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height + 10,
      size.width * 0.5,
      size.height - 5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 20,
      size.width,
      size.height - borderRadius,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Painter for glowing border effect - matches settings screen style
class _GlowingBorderPainter extends CustomPainter {
  final double borderRadius;
  final double glowIntensity;
  final Color color;

  _GlowingBorderPainter({
    this.borderRadius = 36,
    this.glowIntensity = 0.7,
    this.color = AppTheme.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.accentColor.withOpacity(0.7 * glowIntensity),
          color.withOpacity(0.8 * glowIntensity),
          AppTheme.secondaryColor.withOpacity(0.6 * glowIntensity),
          AppTheme.accentColor.withOpacity(0.7 * glowIntensity),
        ],
        stops: const [0.0, 0.35, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 4))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * glowIntensity);

    final path = Path();
    path.moveTo(0, -borderRadius);
    path.quadraticBezierTo(size.width * 0.25, 10, size.width * 0.5, -5);
    path.quadraticBezierTo(size.width * 0.75, -20, size.width, -borderRadius);

    canvas.drawPath(path, paint);

    // Inner glow line
    final innerPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.3 * glowIntensity),
          Colors.white.withOpacity(0.5 * glowIntensity),
          Colors.white.withOpacity(0.3 * glowIntensity),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 2))
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _GlowingBorderPainter oldDelegate) =>
      oldDelegate.glowIntensity != glowIntensity;
}

// Subtle noise painter for header texture
class _HeaderNoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..style = PaintingStyle.fill;

    const spacing = 5.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        if ((x.toInt() + y.toInt()) % 8 == 0) {
          canvas.drawCircle(Offset(x, y), 0.6, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
