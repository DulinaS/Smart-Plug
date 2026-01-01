import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/modern_ui.dart';
import '../../../core/widgets/curved_header.dart';
import '../../devices/application/user_devices_controller.dart';
import 'widgets/device_control_card.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  final String deviceId;
  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  ConsumerState<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final state = ref.read(userDevicesControllerProvider);
      if (!state.hasValue) {
        ref.read(userDevicesControllerProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(userDevicesControllerProvider);

    return devicesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Device')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load devices:\n$e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.read(userDevicesControllerProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (list) {
        final device = list
            .where((d) => d.deviceId == widget.deviceId)
            .cast<UserDeviceView?>()
            .firstOrNull;
        if (device == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Device')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.power_off, size: 48),
                  const SizedBox(height: 8),
                  const Text('Device not found or not linked to your account'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref
                        .read(userDevicesControllerProvider.notifier)
                        .refresh(),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          );
        }

        return MeshGradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                // Beautiful Curved Header
                ScreenHeader(
                  title: device.deviceName.isNotEmpty
                      ? device.deviceName
                      : device.deviceId,
                  subtitle: device.roomName ?? 'Smart Plug',
                  icon: Icons.power_rounded,
                  accentColor: AppTheme.secondaryColor,
                  actions: [
                    _DetailHeaderActionButton(
                      icon: Icons.refresh_rounded,
                      onTap: () => ref
                          .read(userDevicesControllerProvider.notifier)
                          .refresh(),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                // Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Device Info Card
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Device Info',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              context,
                              'Device ID',
                              device.deviceId,
                            ),
                            _buildInfoRow(
                              context,
                              'Display Name',
                              device.deviceName,
                            ),
                            _buildInfoRow(
                              context,
                              'Room',
                              device.roomName ?? '-',
                            ),
                            _buildInfoRow(
                              context,
                              'Plug Type',
                              device.plugType ?? '-',
                            ),
                            _buildInfoRow(
                              context,
                              'Linked At',
                              _formatDate(device.createdAt),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Controls Card
                      DeviceControlCard(deviceId: device.deviceId),

                      const SizedBox(height: 16),

                      // Monitoring Card
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successColor.withOpacity(
                                      0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.analytics_rounded,
                                    color: AppTheme.successColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Monitoring',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Live status and power charts will appear here once telemetry API is provided.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom padding
                      SizedBox(height: AppTheme.navBarTotalHeight),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Helper widget for header action buttons
class _DetailHeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _DetailHeaderActionButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
          ),
        ),
      ),
    );
  }
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
