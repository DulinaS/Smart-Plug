import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/device_control_controller.dart';
import '../../../../core/widgets/error_inline_banner.dart';

class DeviceControlCard extends ConsumerWidget {
  final String deviceId;
  const DeviceControlCard({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deviceControlControllerProvider(deviceId));
    final ctrl = ref.read(deviceControlControllerProvider(deviceId).notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Controls',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (state.error != null) ...[
              ErrorInlineBanner(
                message: state.error!,
                onDismiss: ctrl.clearError,
              ),
              const SizedBox(height: 8),
            ],

            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 320;
                final compactStyle = ButtonStyle(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  minimumSize: WidgetStateProperty.all(const Size(0, 40)),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );

                return Row(
                  children: [
                    Expanded(
                      child: isCompact
                          ? FilledButton(
                              onPressed: state.busy
                                  ? null
                                  : () => ctrl.setOn(true),
                              style: compactStyle,
                              child: state.busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Turn ON'),
                            )
                          : FilledButton.icon(
                              onPressed: state.busy
                                  ? null
                                  : () => ctrl.setOn(true),
                              icon: state.busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.power),
                              label: const Text('Turn ON'),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: isCompact
                          ? OutlinedButton(
                              onPressed: state.busy
                                  ? null
                                  : () => ctrl.setOn(false),
                              style: compactStyle,
                              child: const Text('Turn OFF'),
                            )
                          : OutlinedButton.icon(
                              onPressed: state.busy
                                  ? null
                                  : () => ctrl.setOn(false),
                              icon: const Icon(Icons.power_off),
                              label: const Text('Turn OFF'),
                            ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 8),
            if (state.isOn != null)
              Text(
                'Requested state: ${state.isOn! ? 'ON' : 'OFF'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
