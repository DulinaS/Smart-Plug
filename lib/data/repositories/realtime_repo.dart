import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sensor_reading.dart';
import 'device_repo.dart';

class RealtimeRepository {
  final DeviceRepository _deviceRepository;

  RealtimeRepository(this._deviceRepository);

  final Map<String, Timer?> _timers = {};
  final Map<String, int> _errors = {};
  final Map<String, List<SensorReading>> _buffers = {};
  final Map<String, StreamController<List<SensorReading>>> _controllers = {};

  static const int defaultIntervalSeconds = 2; // Poll every 2s
  static const int defaultBufferSeconds = 240; // Keep last 4 minutes
  static const int _maxConsecutiveErrors = 5;
  static const int _maxDelaySeconds = 60;

  // Consider a long gap if no sample for more than this → start fresh
  static const Duration gapThreshold = Duration(seconds: 15);

  // Broadcast stream of the rolling 4-minute buffer for a deviceId
  Stream<List<SensorReading>> startRealtimeUpdates({
    required String deviceId,
    int intervalSeconds = defaultIntervalSeconds,
    int bufferSeconds = defaultBufferSeconds,
  }) {
    _buffers.putIfAbsent(deviceId, () => <SensorReading>[]);
    _errors.putIfAbsent(deviceId, () => 0);

    final controller = _controllers.putIfAbsent(
      deviceId,
      () => StreamController<List<SensorReading>>.broadcast(),
    );

    Future<void> poll() async {
      try {
        final reading = await _deviceRepository.getLatestReadingForDevice(
          deviceId,
        );

        if (reading != null) {
          final buf = _buffers[deviceId]!;
          final newTs = DateTime.parse(reading.timestamp);

          // If there's a long gap, start fresh (don't connect over the gap)
          if (buf.isNotEmpty) {
            final lastTs = DateTime.parse(buf.last.timestamp);
            if (newTs.difference(lastTs) > gapThreshold) {
              buf.clear();
            }
          }

          // Append if new timestamp
          if (buf.isEmpty || buf.last.timestamp != reading.timestamp) {
            buf.add(reading);
          }

          // TIME-BASED TRIM: only keep samples newer than (newTs - bufferSeconds)
          final cutoff = newTs.subtract(Duration(seconds: bufferSeconds));
          while (buf.isNotEmpty &&
              DateTime.parse(buf.first.timestamp).isBefore(cutoff)) {
            buf.removeAt(0);
          }

          // Safety bound by count too (in case sample rate increases)
          final maxCount = max(1, bufferSeconds ~/ max(1, intervalSeconds));
          if (buf.length > maxCount) {
            buf.removeRange(0, buf.length - maxCount);
          }

          controller.add(List.unmodifiable(buf));
        }

        // "no data" is normal; reset errors and schedule next poll
        _errors[deviceId] = 0;
        _scheduleNextPoll(deviceId, intervalSeconds, poll);
      } catch (e) {
        final newErr = (_errors[deviceId] ?? 0) + 1;
        _errors[deviceId] = newErr;

        if (newErr >= _maxConsecutiveErrors) {
          controller.addError('Realtime unavailable: $e');
          stopRealtimeUpdates(deviceId);
          return;
        }
        _scheduleNextPoll(deviceId, intervalSeconds, poll);
      }
    }

    // Emit current (possibly empty) buffer immediately (no prefill)
    controller.add(List.unmodifiable(_buffers[deviceId]!));

    // Kick off polling
    _scheduleNextPoll(deviceId, intervalSeconds, poll);

    return controller.stream;
  }

  void _scheduleNextPoll(
    String deviceId,
    int baseIntervalSeconds,
    Future<void> Function() poll,
  ) {
    final err = _errors[deviceId] ?? 0;
    final delay = err == 0
        ? baseIntervalSeconds
        : min(
            baseIntervalSeconds * pow(2, min(err, 4)).toInt(),
            _maxDelaySeconds,
          );

    _timers[deviceId]?.cancel();
    _timers[deviceId] = Timer(Duration(seconds: delay), () {
      poll(); // ignore unawaited
    });
  }

  void stopRealtimeUpdates(String deviceId) {
    _timers[deviceId]?.cancel();
    _timers.remove(deviceId);
    _errors.remove(deviceId);
    _buffers.remove(deviceId);
    _controllers[deviceId]?.close();
    _controllers.remove(deviceId);
  }

  void dispose() {
    for (final t in _timers.values) {
      t?.cancel();
    }
    for (final c in _controllers.values) {
      c.close();
    }
    _timers.clear();
    _errors.clear();
    _buffers.clear();
    _controllers.clear();
  }
}

final realtimeRepositoryProvider = Provider<RealtimeRepository>((ref) {
  final deviceRepository = ref.read(deviceRepositoryProvider);
  final repo = RealtimeRepository(deviceRepository);
  ref.onDispose(repo.dispose);
  return repo;
});

// StreamProvider to consume in UI: ref.watch(realtimeBufferStreamProvider(deviceId))
final realtimeBufferStreamProvider =
    StreamProvider.family<List<SensorReading>, String>((ref, deviceId) {
      final repo = ref.read(realtimeRepositoryProvider);
      final stream = repo.startRealtimeUpdates(deviceId: deviceId);
      ref.onDispose(() => repo.stopRealtimeUpdates(deviceId));
      return stream;
    });
