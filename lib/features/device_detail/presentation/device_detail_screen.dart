import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_plug/features/onboarding/domain/plug_types.dart';
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

        return Scaffold(
          appBar: AppBar(
            title: Text(
              device.deviceName.isNotEmpty
                  ? device.deviceName
                  : device.deviceId,
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device ID',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.deviceId,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Display name',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.deviceName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Room',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.roomName ?? '-',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Plug type',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.plugType ?? '-',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Linked at',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.createdAt.toIso8601String(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // NEW: Controls (uses your /device/command API)
              DeviceControlCard(deviceId: device.deviceId),

              const SizedBox(height: 16),

              // Placeholder for monitoring (to be implemented once telemetry APIs are ready)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monitoring',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Live status and power charts will appear here once telemetry API is provided.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
