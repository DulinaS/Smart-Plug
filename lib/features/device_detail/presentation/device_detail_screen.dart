import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_plug/data/models/device.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/utils/formatters.dart';
import '../application/device_detail_controller.dart';
import '../widgets/device_controls.dart';
import '../widgets/device_status_card.dart';
import '../widgets/power_chart.dart';
import 'device_info_card.dart';

class DeviceDetailScreen extends ConsumerWidget {
  final String deviceId;

  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceState = ref.watch(deviceDetailControllerProvider(deviceId));

    ref.listen<DeviceDetailState>(deviceDetailControllerProvider(deviceId), (
      previous,
      next,
    ) {
      if (next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
        ref
            .read(deviceDetailControllerProvider(deviceId).notifier)
            .clearError();
      }
    });

    if (deviceState.isLoading && deviceState.device == null) {
      return const Scaffold(body: LoadingWidget());
    }

    if (deviceState.device == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Device Not Found')),
        body: const Center(
          child: Text('Device not found or you don\'t have access to it.'),
        ),
      );
    }

    final device = deviceState.device!;

    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(deviceDetailControllerProvider(deviceId).notifier)
                .loadDevice(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditDialog(context, ref, device);
                  break;
                case 'schedules':
                  context.go('/device/$deviceId/schedules');
                  break;
                case 'history':
                  context.go('/device/$deviceId/history');
                  break;
                case 'settings':
                  context.go('/device/$deviceId/settings');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Device')),
              const PopupMenuItem(value: 'schedules', child: Text('Schedules')),
              const PopupMenuItem(
                value: 'history',
                child: Text('Usage History'),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Device Settings'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(deviceDetailControllerProvider(deviceId).notifier)
            .loadDevice(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Status Card
              DeviceStatusCard(device: device),
              const SizedBox(height: 16),

              // Device Controls
              DeviceControls(
                device: device,
                isToggling: deviceState.isToggling,
                onToggle: () => ref
                    .read(deviceDetailControllerProvider(deviceId).notifier)
                    .toggleDevice(),
              ),
              const SizedBox(height: 16),

              // Real-time Power Chart
              if (device.isOnline) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Real-time Monitoring',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300, // Increased height for stats + chart
                          child: PowerChart(
                            sensorData: deviceState.realtimeData,
                          ), // Changed parameter
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Device Information
              DeviceInfoCard(device: device),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Device device) {
    final nameController = TextEditingController(text: device.name);
    final roomController = TextEditingController(text: device.room ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: roomController,
              decoration: const InputDecoration(
                labelText: 'Room (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(deviceDetailControllerProvider(deviceId).notifier)
                  .updateDevice(
                    name: nameController.text.trim(),
                    room: roomController.text.trim().isEmpty
                        ? null
                        : roomController.text.trim(),
                  );
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
