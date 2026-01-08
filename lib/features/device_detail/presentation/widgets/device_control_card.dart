import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/device_control_controller.dart';
import '../../../../core/widgets/error_inline_banner.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/modern_ui.dart';

class DeviceControlCard extends ConsumerWidget {
  final String deviceId;
  const DeviceControlCard({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deviceControlControllerProvider(deviceId));
    final ctrl = ref.read(deviceControlControllerProvider(deviceId).notifier);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.successGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.successColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.power_settings_new_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Controls',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (state.isOn != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: state.isOn!
                        ? AppTheme.successColor.withOpacity(0.2)
                        : AppTheme.errorColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: state.isOn!
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.isOn! ? 'ON' : 'OFF',
                        style: TextStyle(
                          color: state.isOn!
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          if (state.error != null) ...[
            ErrorInlineBanner(
              message: state.error!,
              onDismiss: ctrl.clearError,
            ),
            const SizedBox(height: 16),
          ],

          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 320;

              return Row(
                children: [
                  // Turn ON Button
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: state.busy ? null : AppTheme.successGradient,
                        color: state.busy ? AppTheme.darkCard : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: state.busy
                            ? null
                            : [
                                BoxShadow(
                                  color: AppTheme.successColor.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: ElevatedButton(
                        onPressed: state.busy ? null : () => ctrl.setOn(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: isCompact ? 10 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: state.busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white70,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.power_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  if (!isCompact) ...[
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Turn ON',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Turn OFF Button
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: state.busy ? null : () => ctrl.setOn(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: isCompact ? 10 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.power_off_rounded,
                              color: Colors.white.withOpacity(
                                state.busy ? 0.4 : 0.9,
                              ),
                              size: 22,
                            ),
                            if (!isCompact) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Turn OFF',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(
                                    state.busy ? 0.4 : 0.9,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
