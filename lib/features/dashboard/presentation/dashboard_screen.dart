import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/utils/formatters.dart';
import '../application/dashboard_controller.dart';
import '../../auth/application/auth_controller.dart';
import 'widgets/device_card.dart';
import 'widgets/usage_summary_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hello, ${authState.user?.displayName ?? authState.user?.username ?? 'User'}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(dashboardControllerProvider.notifier).loadDevices(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.go('/profile');
                  break;
                case 'settings':
                  context.go('/settings');
                  break;
                case 'logout':
                  ref.read(authControllerProvider.notifier).logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(dashboardControllerProvider.notifier).loadDevices(),
        child: CustomScrollView(
          slivers: [
            // Usage Summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: UsageSummaryCard(devices: dashboardState.devices),
              ),
            ),

            // Error Banner
            if (dashboardState.error != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: MaterialBanner(
                    content: Text(dashboardState.error!),
                    leading: const Icon(Icons.error, color: Colors.red),
                    actions: [
                      TextButton(
                        onPressed: () => ref
                            .read(dashboardControllerProvider.notifier)
                            .clearError(),
                        child: const Text('DISMISS'),
                      ),
                    ],
                  ),
                ),
              ),

            // Loading or Device List
            if (dashboardState.isLoading && dashboardState.devices.isEmpty)
              const SliverFillRemaining(child: LoadingWidget())
            else if (dashboardState.devices.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.devices, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No devices found',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text('Add your first smart plug to get started'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/add-device'),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Device'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final device = dashboardState.devices[index];
                    return DeviceCard(
                      device: device,
                      onTap: () => context.go('/device/${device.id}'),
                      onToggle: () => _toggleDevice(ref, device.id),
                    );
                  }, childCount: dashboardState.devices.length),
                ),
              ),

            // Last updated info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Last updated: ${Formatters.timeAgo(dashboardState.lastUpdated)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/add-device'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _toggleDevice(WidgetRef ref, String deviceId) async {
    try {
      await ref
          .read(dashboardControllerProvider.notifier)
          .toggleDevice(deviceId);
    } catch (e) {
      // Error handling is done in the controller
    }
  }
}
