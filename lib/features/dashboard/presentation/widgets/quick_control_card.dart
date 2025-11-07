import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../devices/application/user_devices_controller.dart';
import '../../../device_detail/application/device_control_controller.dart';
import '../../../../core/widgets/error_inline_banner.dart';

class QuickControlCard extends ConsumerWidget {
  final UserDeviceView device;
  const QuickControlCard({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final control = ref.watch(deviceControlControllerProvider(device.deviceId));
    final ctrl = ref.read(
      deviceControlControllerProvider(device.deviceId).notifier,
    );

    Color _statusColor() {
      if (control.busy) return Colors.amber;
      if (control.isOn == null) return Colors.grey;
      return control.isOn! ? Colors.green : Colors.red;
    }

    final compactStyle = ButtonStyle(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      minimumSize: WidgetStateProperty.all(const Size(0, 32)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => context.push('/device/${device.deviceId}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          // Tighter padding for compact layout
          padding: const EdgeInsets.all(10.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Compact mode thresholds
              final showSubtitle = constraints.maxHeight >= 165;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with tiny status dot
                  Row(
                    children: [
                      const Icon(Icons.power_outlined, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          device.deviceName.isNotEmpty
                              ? device.deviceName
                              : device.deviceId,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: control.busy
                            ? 'Updating…'
                            : control.isOn == null
                            ? 'Unknown'
                            : control.isOn!
                            ? 'Requested: ON'
                            : 'Requested: OFF',
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _statusColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (showSubtitle &&
                      ((device.roomName ?? '').isNotEmpty ||
                          (device.plugType ?? '').isNotEmpty)) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if ((device.roomName ?? '').isNotEmpty)
                          device.roomName!,
                        if ((device.plugType ?? '').isNotEmpty)
                          device.plugType!,
                      ].join(' • '),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const Spacer(),

                  // Controls row (compact)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: control.busy
                              ? null
                              : () => ctrl.setOn(true),
                          style: compactStyle,
                          child: control.busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('On'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: control.busy
                              ? null
                              : () => ctrl.setOn(false),
                          style: compactStyle,
                          child: const Text('Off'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
