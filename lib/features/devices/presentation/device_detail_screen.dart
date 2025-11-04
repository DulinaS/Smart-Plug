import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_plug/features/devices/application/user_devices_controller.dart';
import 'package:smart_plug/features/onboarding/domain/plug_types.dart';

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
    // Ensure list is loaded so we can find the device
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
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      await _showEditSheet(context, ref, device);
                      break;
                    case 'unlink':
                      await _confirmAndUnlink(context, ref, device.deviceId);
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'unlink', child: Text('Unlink')),
                ],
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
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    UserDeviceView device,
  ) async {
    final nameCtrl = TextEditingController(text: device.deviceName);
    final roomCtrl = TextEditingController(text: device.roomName ?? '');
    PlugType? selected = defaultPlugTypes.firstWhere(
      (t) => t.label.toLowerCase() == (device.plugType ?? '').toLowerCase(),
      orElse: () => PlugType.custom,
    );

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) {
            return ListView(
              shrinkWrap: true,
              children: [
                Text('Edit device', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  textInputAction: TextInputAction.next,
                ),
                TextField(
                  controller: roomCtrl,
                  decoration: const InputDecoration(labelText: 'Room'),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),
                Text('Plug type', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: defaultPlugTypes.map((t) {
                    final isSel = selected == t;
                    return ChoiceChip(
                      label: Text(t.label),
                      selected: isSel,
                      onSelected: (_) => setState(() => selected = t),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await ref
                          .read(userDevicesControllerProvider.notifier)
                          .updateUserDevice(
                            deviceId: device.deviceId,
                            deviceName: nameCtrl.text.trim().isEmpty
                                ? device.deviceName
                                : nameCtrl.text.trim(),
                            roomName: roomCtrl.text.trim(),
                            plugType: selected?.label ?? 'Custom',
                          );
                      if (context.mounted) Navigator.pop(context, true);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Update failed: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save'),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

  Future<void> _confirmAndUnlink(
    BuildContext context,
    WidgetRef ref,
    String deviceId,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unlink device'),
        content: const Text('This will remove the device from your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref
            .read(userDevicesControllerProvider.notifier)
            .unlinkUserDevice(deviceId);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Unlinked')));
          Navigator.pop(context);
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unlink failed: $e')));
      }
    }
  }
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
