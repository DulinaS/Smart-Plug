import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/control_repo.dart';
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

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Auto‑OFF timer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (timerState?.active == true)
                  _RemainingBadge(remaining: timerState!.remaining),
              ],
            ),
            const SizedBox(height: 12),

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
                  decoration: const InputDecoration(
                    labelText: 'Device',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
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
              const SizedBox(height: 8),
              Text(
                'Minimum 5 minutes. When time elapses the plug will auto‑turn OFF.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openPicker() async {
    Duration temp = _pending;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: SizedBox(
          height: 280,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                'Custom duration (min 5m)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  initialTimerDuration: temp,
                  minuteInterval: 1,
                  onTimerDurationChanged: (d) => temp = d,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (temp.inSeconds >= 300) {
                            setState(() => _pending = temp);
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Select ≥ 5 minutes'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text('Use'),
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
        Text('Turn OFF after', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...presets.map(
              (d) => ChoiceChip(
                label: Text(_fmt(d)),
                selected: pending == d,
                onSelected: (s) {
                  if (s) onPreset(d);
                },
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.tune, size: 18),
              label: const Text('Custom…'),
              onPressed: onPickCustom,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: minReached ? onStart : null,
            icon: const Icon(Icons.play_arrow),
            label: Text(
              minReached ? 'Start (${_fmt(pending)})' : 'Select ≥ 5 minutes',
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

class _ActiveControls extends ConsumerWidget {
  final String deviceId;
  final DateTime endsAt;
  const _ActiveControls({
    super.key,
    required this.deviceId,
    required this.endsAt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deviceTimerControllerProvider(deviceId));
    final ctrl = ref.read(deviceTimerControllerProvider(deviceId).notifier);
    final remaining = state.remaining ?? Duration.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timer running – will turn OFF in ${_fmt(remaining)}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.stop),
                label: const Text('Cancel'),
                onPressed: ctrl.cancel,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.add),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        m >= 1 ? '${m}m left' : '${r.inSeconds}s left',
        style: TextStyle(
          color: Colors.deepPurple[700],
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
