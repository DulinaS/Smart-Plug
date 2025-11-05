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

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => context.go('/device/${device.deviceId}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.power_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      device.deviceName.isNotEmpty
                          ? device.deviceName
                          : device.deviceId,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              if ((device.roomName ?? '').isNotEmpty ||
                  (device.plugType ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    if ((device.roomName ?? '').isNotEmpty) device.roomName!,
                    if ((device.plugType ?? '').isNotEmpty) device.plugType!,
                  ].join(' • '),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              if (control.error != null) ...[
                ErrorInlineBanner(
                  message: control.error!,
                  onDismiss: ctrl.clearError,
                ),
                const SizedBox(height: 8),
              ],

              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 260;

                  final compactStyle = ButtonStyle(
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    minimumSize: WidgetStateProperty.all(const Size(0, 36)),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );

                  return Row(
                    children: [
                      Expanded(
                        child: isCompact
                            ? FilledButton(
                                onPressed: control.busy
                                    ? null
                                    : () => ctrl.setOn(true),
                                style: compactStyle,
                                child: control.busy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('ON'),
                              )
                            : FilledButton.icon(
                                onPressed: control.busy
                                    ? null
                                    : () => ctrl.setOn(true),
                                icon: control.busy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.toggle_on),
                                label: const Text('ON'),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: isCompact
                            ? OutlinedButton(
                                onPressed: control.busy
                                    ? null
                                    : () => ctrl.setOn(false),
                                style: compactStyle,
                                child: const Text('OFF'),
                              )
                            : OutlinedButton.icon(
                                onPressed: control.busy
                                    ? null
                                    : () => ctrl.setOn(false),
                                icon: const Icon(Icons.toggle_off),
                                label: const Text('OFF'),
                              ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 8),
              Text(
                'Requested: ${control.isOn == null
                    ? '—'
                    : control.isOn!
                    ? 'ON'
                    : 'OFF'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
