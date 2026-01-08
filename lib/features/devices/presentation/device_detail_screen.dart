import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_plug/features/devices/application/user_devices_controller.dart';
import 'package:smart_plug/features/onboarding/domain/plug_types.dart';
import 'package:smart_plug/features/device_detail/presentation/widgets/device_control_card.dart';
import 'package:smart_plug/app/theme.dart';
import 'package:smart_plug/core/widgets/modern_ui.dart';
// Realtime
import '../../../data/repositories/realtime_repo.dart';
import '../widgets/power_chart.dart';

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
      loading: () => Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.power_settings_new_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading device...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Device'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: AppTheme.errorColor,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Failed to load devices',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$e',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => ref
                          .read(userDevicesControllerProvider.notifier)
                          .refresh(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Retry',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            backgroundColor: AppTheme.darkBackground,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: const Text('Device'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GlassCard(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.power_off_rounded,
                          color: AppTheme.warningColor,
                          size: 56,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Device Not Found',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This device is not linked to your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => ref
                              .read(userDevicesControllerProvider.notifier)
                              .refresh(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                          ),
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Refresh',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Subscribe to realtime buffer (last 4 minutes, 2s polling)
        final live = ref.watch(realtimeBufferStreamProvider(device.deviceId));

        return MeshGradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: Text(
                device.deviceName.isNotEmpty
                    ? device.deviceName
                    : device.deviceId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: () => ref
                        .read(userDevicesControllerProvider.notifier)
                        .refresh(),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white70,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: AppTheme.darkCard,
                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          await _showEditSheet(context, ref, device);
                          break;
                        case 'unlink':
                          await _confirmAndUnlink(
                            context,
                            ref,
                            device.deviceId,
                          );
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: AppTheme.primaryColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Edit Device'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'unlink',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.link_off_rounded,
                                color: AppTheme.errorColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Unlink Device'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Metadata Card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Device Info',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _InfoRow(
                        label: 'Device ID',
                        value: device.deviceId,
                        icon: Icons.tag_rounded,
                      ),
                      _InfoRow(
                        label: 'Display Name',
                        value: device.deviceName,
                        icon: Icons.label_outline_rounded,
                      ),
                      _InfoRow(
                        label: 'Room',
                        value: device.roomName ?? '-',
                        icon: Icons.room_outlined,
                      ),
                      _InfoRow(
                        label: 'Plug Type',
                        value: device.plugType ?? '-',
                        icon: Icons.electrical_services_rounded,
                      ),
                      _InfoRow(
                        label: 'Linked At',
                        value: _formatDate(device.createdAt),
                        icon: Icons.access_time_rounded,
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Controls (uses /device/command via ControlRepository)
                DeviceControlCard(deviceId: device.deviceId),

                const SizedBox(height: 16),

                // Realtime chart + stats
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.secondaryColor.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.show_chart_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Realtime',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.successColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Live',
                                  style: TextStyle(
                                    color: AppTheme.successColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      live.when(
                        data: (buffer) => PowerChart(sensorData: buffer),
                        loading: () => const PowerChart(sensorData: []),
                        error: (e, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.errorColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppTheme.errorColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Realtime unavailable: $e',
                                      style: const TextStyle(
                                        color: AppTheme.errorColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const PowerChart(sensorData: []),
                          ],
                        ),
                      ),
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

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setState) {
              return ListView(
                shrinkWrap: true,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Edit Device',
                        style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: nameCtrl,
                    label: 'Display Name',
                    icon: Icons.label_outline_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: roomCtrl,
                    label: 'Room',
                    icon: Icons.room_outlined,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 20),
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
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => selected = t),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSel
                                    ? AppTheme.primaryGradient
                                    : null,
                                color: isSel ? null : AppTheme.darkCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel
                                      ? Colors.transparent
                                      : Colors.white.withOpacity(0.1),
                                ),
                                boxShadow: isSel
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                t.label,
                                style: TextStyle(
                                  color: isSel
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.8),
                                  fontWeight: isSel
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
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
                            SnackBar(
                              content: Text('Update failed: $e'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.save_rounded, color: Colors.white),
                      label: const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Device updated successfully'),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputAction? textInputAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        textInputAction: textInputAction,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
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
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.link_off_rounded,
                color: AppTheme.errorColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Unlink Device',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'This will remove the device from your account. You can re-link it later if needed.',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.errorColor, Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.errorColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Unlink',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('Device unlinked successfully'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unlink failed: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

/// Helper widget for displaying info rows in device detail
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: Colors.white.withOpacity(0.08), height: 1),
      ],
    );
  }
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
