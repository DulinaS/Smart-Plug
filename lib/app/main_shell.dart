import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/lib/animated_bottom_navigation_bar.dart';
import 'theme.dart';

/// Provider to track current navigation index
final navigationIndexProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  final String location;

  const MainShell({super.key, required this.child, required this.location});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late AnimationController _tabAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _borderRadiusAnimation;
  late Animation<double> _curveAnimation;
  int _previousIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_rounded, label: 'Home', route: '/dashboard'),
    _NavItem(icon: Icons.devices_rounded, label: 'Devices', route: '/devices'),
    _NavItem(
      icon: Icons.analytics_rounded,
      label: 'Summary',
      route: '/summary',
    ),
    _NavItem(
      icon: Icons.settings_rounded,
      label: 'Settings',
      route: '/settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOut,
    );
    _borderRadiusAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
    );
    _curveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _tabAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fabAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }

  int _getIndexFromLocation(String location) {
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getIndexFromLocation(widget.location);

    // Trigger animation when tab changes
    if (currentIndex != _previousIndex) {
      _tabAnimationController.forward(from: 0);
      _previousIndex = currentIndex;
    }

    return Scaffold(
      extendBody: true,
      body: widget.child,
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: () => context.push('/add-device'),
          elevation: 8,
          backgroundColor: AppTheme.primaryColor,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBuilder(
        animation: Listenable.merge([_borderRadiusAnimation, _curveAnimation]),
        builder: (context, _) => AnimatedBottomNavigationBar.builder(
          itemCount: _navItems.length,
          tabBuilder: (index, isActive) {
            final item = _navItems[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: isActive ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.15 * value),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Transform.scale(
                        scale: 1.0 + (0.1 * value),
                        child: Icon(
                          item.icon,
                          size: 26,
                          color: Color.lerp(
                            Colors.white.withOpacity(0.5),
                            AppTheme.primaryColor,
                            value,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: value > 0.5
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: Color.lerp(
                          Colors.white.withOpacity(0.5),
                          AppTheme.primaryColor,
                          value,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          activeIndex: currentIndex,
          gapLocation: GapLocation.center,
          gapWidth: 72,
          notchSmoothness: NotchSmoothness.verySmoothEdge,
          leftCornerRadius: 28,
          rightCornerRadius: 28,
          backgroundColor: AppTheme.darkSurface,
          splashColor: AppTheme.primaryColor.withOpacity(0.3),
          splashSpeedInMilliseconds: 400,
          notchAndCornersAnimation: _borderRadiusAnimation,
          notchMargin: 10,
          elevation: 0,
          height: AppTheme.navBarHeight,
          shadow: const Shadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
          onTap: (index) {
            if (index != currentIndex) {
              context.go(_navItems[index].route);
            }
          },
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
