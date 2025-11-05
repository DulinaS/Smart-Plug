import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/application/auth_controller.dart';
import '../../devices/application/user_devices_controller.dart';
import 'widgets/quick_control_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final devicesAsync = ref.watch(userDevicesControllerProvider);

    final deviceCountText = devicesAsync.when(
      data: (list) => '${list.length}',
      loading: () => '…',
      error: (_, __) => '—',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hello, ${authState.user?.displayName ?? authState.user?.username ?? 'User'}',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh devices',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(userDevicesControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 1,
            child: ListTile(
              leading: const Icon(Icons.devices_other),
              title: const Text('Linked devices'),
              subtitle: const Text('Devices connected to your account'),
              trailing: Text(
                deviceCountText,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          const SizedBox(height: 16),

          devicesAsync.when(
            data: (list) {
              if (list.isEmpty || list.length > 2)
                return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick controls',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (list.length == 1) ...[
                    QuickControlCard(device: list.first),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: QuickControlCard(device: list[0])),
                        const SizedBox(width: 12),
                        Expanded(child: QuickControlCard(device: list[1])),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _Tile(
                icon: Icons.devices,
                color: Colors.blue,
                title: 'My Devices',
                subtitle: 'View and manage',
                // CHANGE: push so there’s a back arrow
                onTap: () => context.push('/devices'),
              ),
              _Tile(
                icon: Icons.add_circle_outline,
                color: Colors.green,
                title: 'Add Device',
                subtitle: 'Wi‑Fi provisioning',
                onTap: () async {
                  final res = await context.push('/add-device');
                  await ref
                      .read(userDevicesControllerProvider.notifier)
                      .refresh();
                  if (res == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Device linked')),
                    );
                  }
                },
              ),
              _Tile(
                icon: Icons.settings_outlined,
                color: Colors.teal,
                title: 'Settings',
                subtitle: 'App & preferences',
                // CHANGE: push so there’s a back arrow
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
