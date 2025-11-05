import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/user_devices_controller.dart';
import '../../onboarding/domain/plug_types.dart';

class UserDevicesScreen extends ConsumerWidget {
  const UserDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(userDevicesControllerProvider);

    Future<void> goToAddDevice() async {
      final res = await context.push('/add-device');
      await ref.read(userDevicesControllerProvider.notifier).refresh();
      if (res == true && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Device linked')));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Devices'),
        // When navigated via push (from Dashboard), you’ll get a default back arrow here.
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(userDevicesControllerProvider.notifier).refresh(),
          ),
          IconButton(
            tooltip: 'Add Device',
            icon: const Icon(Icons.add),
            onPressed: goToAddDevice,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: goToAddDevice,
        child: const Icon(Icons.add),
      ),
      body: devicesAsync.when(
        data: (devices) {
          if (devices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.devices, size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'No devices yet.\nProvision a plug to link it here.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: goToAddDevice,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Device'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(userDevicesControllerProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: devices.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final d = devices[i];
                final subtitleLines = <String>[
                  'ID: ${d.deviceId}',
                  if ((d.roomName ?? '').isNotEmpty) 'Room: ${d.roomName}',
                  if ((d.plugType ?? '').isNotEmpty) 'Type: ${d.plugType}',
                  'Added: ${d.createdAt.toIso8601String()}',
                ];
                return ListTile(
                  leading: const Icon(Icons.power_outlined),
                  title: Text(
                    d.deviceName.isNotEmpty ? d.deviceName : d.deviceId,
                  ),
                  subtitle: Text(subtitleLines.join(' • ')),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          await _showQuickEditSheet(ctx, ref, d);
                          break;
                        case 'unlink':
                          await _confirmAndUnlink(ctx, ref, d.deviceId);
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'unlink', child: Text('Unlink')),
                    ],
                  ),
                  // CHANGE: push so the detail page has a back arrow
                  onTap: () => context.push('/device/${d.deviceId}'),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
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
    );
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
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unlink failed: $e')));
      }
    }
  }

  Future<void> _showQuickEditSheet(
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

    final saved = await showModalBottomSheet<bool>(
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

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }
}
