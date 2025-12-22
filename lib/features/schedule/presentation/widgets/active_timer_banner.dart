import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../timer/application/timer_controller.dart';

class ActiveTimerBanner extends ConsumerWidget {
  final String deviceId;
  const ActiveTimerBanner({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deviceTimerControllerProvider(deviceId));
    if (!state.active || state.remaining == null)
      return const SizedBox.shrink();

    final remaining = state.remaining!;
    final text = _fmt(remaining);

    return Card(
      color: Colors.deepPurple.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.timer, color: Colors.deepPurple),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Auto‑OFF timer active: $text remaining',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple[800],
                ),
              ),
            ),
            TextButton(
              onPressed: () => ref
                  .read(deviceTimerControllerProvider(deviceId).notifier)
                  .cancel(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
