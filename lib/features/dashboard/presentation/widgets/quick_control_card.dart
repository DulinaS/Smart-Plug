import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/modern_ui.dart';
import '../../../devices/application/user_devices_controller.dart';
import '../../../device_detail/application/device_control_controller.dart';

class QuickControlCard extends ConsumerWidget {
  final UserDeviceView device;
  const QuickControlCard({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final control = ref.watch(deviceControlControllerProvider(device.deviceId));
    final ctrl = ref.read(
      deviceControlControllerProvider(device.deviceId).notifier,
    );

    Color statusColor() {
      if (control.busy) return AppTheme.warningColor;
      if (control.isOn == null) return Colors.grey;
      return control.isOn! ? AppTheme.successColor : AppTheme.errorColor;
    }

    return GlassCard(
      onTap: () => context.push('/device/${device.deviceId}'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.power_rounded,
                  color: statusColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  device.deviceName.isNotEmpty
                      ? device.deviceName
                      : device.deviceId,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PulsingDot(color: statusColor(), size: 8),
            ],
          ),

          if ((device.roomName ?? '').isNotEmpty ||
              (device.plugType ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              [
                if ((device.roomName ?? '').isNotEmpty) device.roomName!,
                if ((device.plugType ?? '').isNotEmpty) device.plugType!,
              ].join(' • '),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const Spacer(),

          // Control buttons
          Row(
            children: [
              Expanded(
                child: _ControlButton(
                  label: 'On',
                  isActive: control.isOn == true,
                  isLoading: control.busy,
                  onPressed: control.busy ? null : () => ctrl.setOn(true),
                  activeColor: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ControlButton(
                  label: 'Off',
                  isActive: control.isOn == false,
                  isLoading: false,
                  onPressed: control.busy ? null : () => ctrl.setOn(false),
                  activeColor: AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color activeColor;

  const _ControlButton({
    required this.label,
    required this.isActive,
    required this.isLoading,
    required this.onPressed,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: isActive ? activeColor.withOpacity(0.2) : AppTheme.darkCard,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? activeColor : Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: activeColor,
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        color: isActive ? activeColor : Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
