import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_plug/app/theme.dart';

/// Modern glass card with blur effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.color,
    this.gradient,
    this.onTap,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                padding: padding ?? const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: gradient ?? AppTheme.glassGradient,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  color: color ?? AppTheme.darkCard.withOpacity(0.7),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated gradient card
class GradientCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Gradient gradient;
  final VoidCallback? onTap;
  final bool animate;

  const GradientCard({
    super.key,
    required this.child,
    required this.gradient,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.onTap,
    this.animate = false,
  });

  @override
  State<GradientCard> createState() => _GradientCardState();
}

class _GradientCardState extends State<GradientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: GestureDetector(
        onTapDown: widget.onTap != null ? _onTapDown : null,
        onTapUp: widget.onTap != null ? _onTapUp : null,
        onTapCancel: widget.onTap != null ? _onTapCancel : null,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(scale: _scaleAnimation.value, child: child);
          },
          child: Container(
            padding: widget.padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: widget.gradient,
              boxShadow: [
                BoxShadow(
                  color: widget.gradient.colors.first.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Modern stat card with icon
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColor ?? AppTheme.primaryColor).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

/// Animated icon button
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final double size;
  final String? tooltip;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 24,
    this.tooltip,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget button = GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (widget.color ?? AppTheme.primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon,
                color: widget.color ?? AppTheme.primaryColor,
                size: widget.size,
              ),
            ),
          );
        },
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}

/// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(_controller);
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
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                AppTheme.darkCard,
                AppTheme.darkCardAlt,
                AppTheme.darkCard,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Animated list item that fades and slides in
class AnimatedListItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration duration;
  final Duration delay;

  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }
}

/// Section header with optional action
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (actionText != null || actionIcon != null)
            TextButton.icon(
              onPressed: onAction,
              icon: actionIcon != null
                  ? Icon(actionIcon, size: 18)
                  : const SizedBox.shrink(),
              label: Text(actionText ?? ''),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.secondaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// Modern toggle switch with animation
class ModernSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const ModernSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 56,
        height: 32,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: value
              ? (activeColor ?? AppTheme.successColor)
              : AppTheme.darkCard,
          border: Border.all(
            color: value
                ? (activeColor ?? AppTheme.successColor)
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pulsating indicator for online status
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({
    super.key,
    this.color = AppTheme.successColor,
    this.size = 12,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.5,
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
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _animation.value * 0.6),
                blurRadius: widget.size,
                spreadRadius: widget.size * 0.2 * _animation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Beautiful animated gradient background with floating orbs
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color>? colors;
  final bool showOrbs;
  final bool animate;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.showOrbs = true,
    this.animate = true,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _orbController;
  late Animation<double> _gradientAnimation;
  late Animation<double> _orbAnimation;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _orbController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _gradientAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
    );
    _orbAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _orbController, curve: Curves.easeInOut));

    if (widget.animate) {
      _gradientController.repeat(reverse: true);
      _orbController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultColors = [
      AppTheme.darkBackground,
      const Color(0xFF1A1035), // Deep purple-black
      const Color(0xFF0D1B2A), // Deep blue-black
    ];
    final colors = widget.colors ?? defaultColors;

    return AnimatedBuilder(
      animation: Listenable.merge([_gradientAnimation, _orbAnimation]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                -1 + _gradientAnimation.value * 0.5,
                -1 + _gradientAnimation.value * 0.3,
              ),
              end: Alignment(
                1 - _gradientAnimation.value * 0.3,
                1 - _gradientAnimation.value * 0.5,
              ),
              colors: colors,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Floating orbs
              if (widget.showOrbs) ...[
                _buildOrb(
                  top: 60 + (_orbAnimation.value * 30),
                  right: 20 + (_orbAnimation.value * 20),
                  size: 180,
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  blur: 80,
                ),
                _buildOrb(
                  bottom: 150 + (_orbAnimation.value * 40),
                  left: -50 + (_orbAnimation.value * 30),
                  size: 220,
                  color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                  blur: 100,
                ),
                _buildOrb(
                  top:
                      MediaQuery.of(context).size.height * 0.4 +
                      (_orbAnimation.value * 25),
                  right: -40 + (_orbAnimation.value * 20),
                  size: 160,
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  blur: 70,
                ),
                _buildOrb(
                  bottom: 300 - (_orbAnimation.value * 35),
                  right: 80 + (_orbAnimation.value * 25),
                  size: 120,
                  color: AppTheme.successColor.withValues(alpha: 0.08),
                  blur: 60,
                ),
              ],
              // Content
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }

  Widget _buildOrb({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
    required double blur,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: blur, spreadRadius: size * 0.3),
          ],
        ),
      ),
    );
  }
}

/// Mesh gradient background (static but visually stunning)
class MeshGradientBackground extends StatelessWidget {
  final Widget child;

  const MeshGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F0F23), Color(0xFF1A1035), Color(0xFF0F0F23)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Top-right gradient blob
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.3),
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          // Bottom-left gradient blob
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.secondaryColor.withValues(alpha: 0.25),
                    AppTheme.secondaryColor.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          // Center accent
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentColor.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          // Noise/grain overlay for texture
          Positioned.fill(child: CustomPaint(painter: _NoiseOverlayPainter())),
          // Content
          child,
        ],
      ),
    );
  }
}

/// Subtle noise overlay for texture
class _NoiseOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // This creates a very subtle grain effect
    // In production, you'd use an actual noise texture image
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    // Simple dot pattern for grain effect
    const spacing = 4.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        if ((x.toInt() + y.toInt()) % 7 == 0) {
          canvas.drawCircle(Offset(x, y), 0.5, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
