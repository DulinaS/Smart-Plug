import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/modern_ui.dart';
import '../../../devices/application/user_devices_controller.dart';
import '../../../timer/application/timer_controller.dart';

class AutoOffTimerCard extends ConsumerStatefulWidget {
  const AutoOffTimerCard({super.key});

  @override
  ConsumerState<AutoOffTimerCard> createState() => _AutoOffTimerCardState();
}

class _AutoOffTimerCardState extends ConsumerState<AutoOffTimerCard> {
  String? _deviceId;
  Duration _pending = const Duration(minutes: 10);
  bool _showPicker = false;

  final List<Duration> _presets = const [
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 4),
  ];

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(userDevicesControllerProvider);

    // If a device is selected, subscribe to that timer state.
    final timerState = _deviceId != null
        ? ref.watch(deviceTimerControllerProvider(_deviceId!))
        : null;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.timer_rounded,
                  color: AppTheme.accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Auto-OFF Timer',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (timerState?.active == true)
                _RemainingBadge(remaining: timerState!.remaining),
            ],
          ),
          const SizedBox(height: 16),

          devices.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (e, _) => Text('Failed to load devices: $e'),
            data: (list) {
              if (list.isEmpty) return const Text('No devices linked');
              final initial = _deviceId ?? list.first.deviceId;
              _deviceId ??= initial;
              return DropdownButtonFormField<String>(
                value: _deviceId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Select Device',
                  isDense: true,
                  filled: true,
                  fillColor: AppTheme.darkCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                dropdownColor: AppTheme.darkCard,
                items: list
                    .map(
                      (d) => DropdownMenuItem(
                        value: d.deviceId,
                        child: Text(
                          d.deviceName.isNotEmpty ? d.deviceName : d.deviceId,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _deviceId = v),
              );
            },
          ),
          const SizedBox(height: 12),

          if (timerState?.error != null) ...[
            _ErrorBanner(
              message: timerState!.error!,
              onClose: () => ref
                  .read(deviceTimerControllerProvider(_deviceId!).notifier)
                  .clearError(),
            ),
            const SizedBox(height: 8),
          ],

          if (timerState?.active == true)
            _ActiveControls(deviceId: _deviceId!, endsAt: timerState!.endsAt!)
          else
            _InactiveControls(
              pending: _pending,
              presets: _presets,
              onPreset: (d) => setState(() => _pending = d),
              onPickCustom: _openPicker,
              onStart: _startTimer,
              minReached: _pending.inSeconds >= 300,
            ),

          if (!_showPicker) ...[
            const SizedBox(height: 12),
            Text(
              'Minimum 5 minutes. Plug will auto-turn OFF when time elapses.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white54),
            ),
          ],
        ],
      ),
    );
  }

  void _openPicker() async {
    Duration temp = _pending;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: SizedBox(
          height: 300,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Custom Duration',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Minimum 5 minutes',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white54),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.dark,
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    initialTimerDuration: temp,
                    minuteInterval: 1,
                    onTimerDurationChanged: (d) => temp = d,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (temp.inSeconds >= 300) {
                            setState(() => _pending = temp);
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Select ≥ 5 minutes'),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startTimer() async {
    if (_deviceId == null) return;
    final ctrl = ref.read(deviceTimerControllerProvider(_deviceId!).notifier);
    await ctrl.start(_pending);
    // Success / error banners handled via state
  }
}

class _InactiveControls extends StatelessWidget {
  final Duration pending;
  final List<Duration> presets;
  final ValueChanged<Duration> onPreset;
  final VoidCallback onPickCustom;
  final VoidCallback onStart;
  final bool minReached;

  const _InactiveControls({
    required this.pending,
    required this.presets,
    required this.onPreset,
    required this.onPickCustom,
    required this.onStart,
    required this.minReached,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Turn OFF after',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...presets.map(
              (d) => _DurationChip(
                duration: d,
                isSelected: pending == d,
                onSelected: () => onPreset(d),
              ),
            ),
            GestureDetector(
              onTap: onPickCustom,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      'Custom',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: minReached ? onStart : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              minReached
                  ? 'Start Timer (${_fmt(pending)})'
                  : 'Select ≥ 5 minutes',
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    if (d.inHours >= 1) {
      final h = d.inHours;
      final m = d.inMinutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${d.inMinutes}m';
  }
}

class _DurationChip extends StatelessWidget {
  final Duration duration;
  final bool isSelected;
  final VoidCallback onSelected;

  const _DurationChip({
    required this.duration,
    required this.isSelected,
    required this.onSelected,
  });

  String _fmt(Duration d) {
    if (d.inHours >= 1) {
      final h = d.inHours;
      final m = d.inMinutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${d.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.2)
              : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          _fmt(duration),
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ActiveControls extends ConsumerWidget {
  final String deviceId;
  final DateTime endsAt;
  const _ActiveControls({required this.deviceId, required this.endsAt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deviceTimerControllerProvider(deviceId));
    final ctrl = ref.read(deviceTimerControllerProvider(deviceId).notifier);
    final remaining = state.remaining ?? Duration.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const PulsingDot(color: AppTheme.successColor, size: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Timer running – OFF in ${_fmt(remaining)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Cancel'),
                onPressed: ctrl.cancel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('+15 min'),
                onPressed: () => ctrl.addTime(const Duration(minutes: 15)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

class _RemainingBadge extends StatelessWidget {
  final Duration? remaining;
  const _RemainingBadge({this.remaining});

  @override
  Widget build(BuildContext context) {
    final r = remaining ?? Duration.zero;
    final m = r.inMinutes;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        m >= 1 ? '${m}m left' : '${r.inSeconds}s left',
        style: const TextStyle(
          color: AppTheme.accentColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  const _ErrorBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.errorColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }
}
