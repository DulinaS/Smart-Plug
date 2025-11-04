import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/application/auth_controller.dart';
import '../../devices/application/user_devices_controller.dart';

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
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Small info card (devices count)
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

          // Quick actions grid
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
                onTap: () => context.go('/devices'),
              ),
              _Tile(
                icon: Icons.add_circle_outline,
                color: Colors.green,
                title: 'Add Device',
                subtitle: 'Wi‑Fi provisioning',
                onTap: () async {
                  final res = await context.push('/add-device');
                  // Refresh the devices list on return
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
                icon: Icons.schedule,
                color: Colors.orange,
                title: 'Schedules',
                subtitle: 'Automations',
                onTap: () => context.go('/schedules'),
              ),
              _Tile(
                icon: Icons.person_outline,
                color: Colors.purple,
                title: 'Profile',
                subtitle: 'Account info',
                onTap: () => context.go('/profile'),
              ),
              _Tile(
                icon: Icons.settings_outlined,
                color: Colors.teal,
                title: 'Settings',
                subtitle: 'App & preferences',
                onTap: () => context.go('/settings'),
              ),
              // Add more tiles here as needed (Usage, Help, etc.)
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
