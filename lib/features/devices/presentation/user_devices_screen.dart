import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/modern_ui.dart';
import '../../../core/widgets/curved_header.dart';
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

    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Beautiful Curved Header
            ScreenHeader(
              title: 'My Devices',
              subtitle: 'Manage your smart plugs',
              icon: Icons.devices_rounded,
              accentColor: AppTheme.primaryColor,
              actions: [
                _HeaderActionButton(
                  icon: Icons.refresh_rounded,
                  onTap: () => ref
                      .read(userDevicesControllerProvider.notifier)
                      .refresh(),
                  tooltip: 'Refresh',
                ),
                _HeaderActionButton(
                  icon: Icons.add_rounded,
                  onTap: goToAddDevice,
                  tooltip: 'Add Device',
                  isPrimary: true,
                ),
              ],
            ),
            // Device List
            Expanded(
              child: devicesAsync.when(
                data: (devices) {
                  if (devices.isEmpty) {
                    return _EmptyDevicesState(onAddDevice: goToAddDevice);
                  }
                  return RefreshIndicator(
                    color: AppTheme.primaryColor,
                    backgroundColor: AppTheme.darkCard,
                    onRefresh: () =>
                        ref.read(userDevicesControllerProvider.notifier).refresh(),
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        AppTheme.navBarTotalHeight,
                      ),
                      itemCount: devices.length,
                      itemBuilder: (ctx, i) {
                        final d = devices[i];
                        return AnimatedListItem(
                          index: i,
                          child: _DeviceCard(
                            device: d,
                            onTap: () => context.push('/device/${d.deviceId}'),
                            onEdit: () => _showQuickEditSheet(ctx, ref, d),
                            onUnlink: () =>
                                _confirmAndUnlink(ctx, ref, d.deviceId),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation(AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading devices...',
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
                error: (e, _) => _ErrorState(
                  error: e.toString(),
                  onRetry: () =>
                      ref.read(userDevicesControllerProvider.notifier).refresh(),
                ),
              ),
            ),
          ],
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
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.link_off_rounded,
                color: AppTheme.errorColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Unlink Device', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'This will remove the device from your account. You can re-link it later.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.errorColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Unlink',
                style: TextStyle(color: Colors.white),
              ),
            ),
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 20,
          right: 20,
          top: 8,
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Edit Device',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Name field
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: Icon(
                      Icons.label_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                // Room field
                TextField(
                  controller: roomCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Room',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: Icon(
                      Icons.room_rounded,
                      color: AppTheme.secondaryColor,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppTheme.secondaryColor),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),
                // Plug type section
                Text(
                  'Plug Type',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: defaultPlugTypes.map((t) {
                    final isSel = selected == t;
                    return GestureDetector(
                      onTap: () => setState(() => selected = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSel ? AppTheme.primaryGradient : null,
                          color: isSel ? null : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel
                                ? Colors.transparent
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          t.label,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isSel
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () async {
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.save_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Saved'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}

class _EmptyDevicesState extends StatelessWidget {
  final VoidCallback onAddDevice;

  const _EmptyDevicesState({required this.onAddDevice});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.darkCard,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(
              Icons.devices_rounded,
              size: 48,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No devices yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Provision a plug to link it here.',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onAddDevice,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Add Device',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.errorColor.withOpacity(0.1),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load devices',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final UserDeviceView device;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onUnlink;

  const _DeviceCard({
    required this.device,
    required this.onTap,
    required this.onEdit,
    required this.onUnlink,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.secondaryColor.withOpacity(0.3),
                    AppTheme.primaryColor.withOpacity(0.2),
                  ],
                ),
              ),
              child: Icon(
                Icons.power_rounded,
                color: AppTheme.secondaryColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.deviceName.isNotEmpty
                        ? device.deviceName
                        : device.deviceId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if ((device.roomName ?? '').isNotEmpty) ...[
                        Icon(
                          Icons.room_rounded,
                          size: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          device.roomName!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if ((device.plugType ?? '').isNotEmpty) ...[
                        Icon(
                          Icons.electrical_services_rounded,
                          size: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          device.plugType!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: Colors.white.withOpacity(0.6),
              ),
              color: AppTheme.darkCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'unlink') onUnlink();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text('Edit', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'unlink',
                  child: Row(
                    children: [
                      Icon(
                        Icons.link_off_rounded,
                        size: 18,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Unlink',
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget for header action buttons
class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool isPrimary;

  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isPrimary = false,
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
              gradient: isPrimary ? AppTheme.primaryGradient : null,
              color: isPrimary ? null : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPrimary
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.15),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white.withOpacity(isPrimary ? 1.0 : 0.9),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
