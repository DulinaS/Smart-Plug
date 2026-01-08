import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/modern_ui.dart';
import '../../../core/widgets/curved_header.dart';
import '../../auth/application/auth_controller.dart';
import '../../devices/application/user_devices_controller.dart';
import 'widgets/quick_control_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final devicesAsync = ref.watch(userDevicesControllerProvider);

    final deviceCount =
        devicesAsync.whenOrNull(data: (list) => list.length) ?? 0;

    final userName =
        authState.user?.displayName ?? authState.user?.username ?? 'User';

    return AnimatedGradientBackground(
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: false,
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // Modern Curved Header with Welcome Message
              SliverToBoxAdapter(
                child: HomeHeader(
                  userName: userName,
                  deviceCount: deviceCount,
                  onRefresh: () => ref
                      .read(userDevicesControllerProvider.notifier)
                      .refresh(),
                ),
              ),

              // Stats Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.devices_rounded,
                          value: '$deviceCount',
                          label: 'Connected Devices',
                          color: AppTheme.primaryColor,
                          onTap: () => context.go('/devices'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.bolt_rounded,
                          value: devicesAsync.when(
                            data: (list) =>
                                list.where((d) => true).length.toString(),
                            loading: () => '-',
                            error: (_, __) => '-',
                          ),
                          label: 'Active Now',
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Controls Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: devicesAsync.when(
                    data: (list) {
                      if (list.isEmpty) {
                        return _buildEmptyState(context);
                      }
                      final quickDevices = list.take(4).toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Quick Controls',
                            actionText: 'View All',
                            actionIcon: Icons.arrow_forward_rounded,
                            onAction: () => context.go('/devices'),
                          ),
                          _buildResponsiveDeviceGrid(context, quickDevices),
                        ],
                      );
                    },
                    loading: () => _buildLoadingGrid(),
                    error: (e, _) => _buildErrorState(context, e.toString()),
                  ),
                ),
              ),

              // Shortcuts Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Shortcuts'),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _ShortcutTile(
                            icon: Icons.add_circle_rounded,
                            title: 'Add Device',
                            subtitle: 'Wi-Fi setup',
                            gradient: AppTheme.successGradient,
                            onTap: () => context.push('/add-device'),
                          ),
                          _ShortcutTile(
                            icon: Icons.timer_rounded,
                            title: 'Timer',
                            subtitle: 'Auto-off timer',
                            gradient: AppTheme.accentGradient,
                            onTap: () => context.push('/timer'),
                          ),
                          _ShortcutTile(
                            icon: Icons.analytics_rounded,
                            title: 'Analytics',
                            subtitle: 'Usage summary',
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.primaryColor.withOpacity(0.7),
                              ],
                            ),
                            onTap: () => context.go('/summary'),
                          ),
                          _ShortcutTile(
                            icon: Icons.settings_rounded,
                            title: 'Settings',
                            subtitle: 'App preferences',
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.grey.shade700,
                                Colors.grey.shade800,
                              ],
                            ),
                            onTap: () => context.go('/settings'),
                          ),
                        ],
                      ),
                      // Bottom padding to account for navbar
                      SizedBox(height: AppTheme.navBarTotalHeight),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveDeviceGrid(
    BuildContext context,
    List<dynamic> quickDevices,
  ) {
    final deviceCount = quickDevices.length;

    // If only 1 device, take full width
    if (deviceCount == 1) {
      return AnimatedListItem(
        index: 0,
        child: SizedBox(
          height: 140,
          width: double.infinity,
          child: QuickControlCard(device: quickDevices[0]),
        ),
      );
    }

    // For 2 devices, show side by side
    if (deviceCount == 2) {
      return Row(
        children: [
          Expanded(
            child: AnimatedListItem(
              index: 0,
              child: SizedBox(
                height: 140,
                child: QuickControlCard(device: quickDevices[0]),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedListItem(
              index: 1,
              child: SizedBox(
                height: 140,
                child: QuickControlCard(device: quickDevices[1]),
              ),
            ),
          ),
        ],
      );
    }

    // For 3+ devices, use grid
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 140,
      ),
      itemCount: deviceCount,
      itemBuilder: (context, index) {
        return AnimatedListItem(
          index: index,
          child: QuickControlCard(device: quickDevices[index]),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
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

  Widget _buildEmptyState(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.devices_other_rounded,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No devices yet',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first smart plug to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.push('/add-device'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Device'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 140,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return const ShimmerLoading(
          width: double.infinity,
          height: 140,
          borderRadius: 20,
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load devices',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white60),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ShortcutTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ShortcutTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_ShortcutTile> createState() => _ShortcutTileState();
}

class _ShortcutTileState extends State<_ShortcutTile>
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: widget.gradient,
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
