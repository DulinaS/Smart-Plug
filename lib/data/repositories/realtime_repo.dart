/* import 'dart:async';
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

  // Polling and window
  static const int defaultIntervalSeconds = 2; // poll every 2s
  static const int defaultBufferSeconds = 240; // last 4 minutes
  static const int _maxConsecutiveErrors = 5;
  static const int _maxDelaySeconds = 60;

  // If no sample for > gapThreshold, start fresh (don’t connect across big gaps)
  static const Duration gapThreshold = Duration(seconds: 15);

  // Do NOT reset on every OFF; we keep history and extend with zeros
  static const bool resetOnEveryOff = false;

  // Broadcast stream of a device’s rolling buffer
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
        final raw = await _deviceRepository.getLatestReadingForDevice(deviceId);
        final buf = _buffers[deviceId]!;

        SensorReading? effective;
        DateTime? newTs;

        if (raw != null) {
          final isOff = (raw.state?.toUpperCase() == 'OFF');
          final rawTs = DateTime.parse(raw.timestamp);
          newTs = rawTs;

          // If there's a long gap, start fresh
          if (buf.isNotEmpty) {
            final lastTs = DateTime.parse(buf.last.timestamp);
            if (rawTs.difference(lastTs) > gapThreshold) {
              buf.clear();
            }
          }

          if (isOff) {
            // Normalize OFF to clean zeros
            var tsForOff = rawTs;

            // If backend reuses same timestamp while OFF, extend with synthetic +interval
            if (buf.isNotEmpty && buf.last.timestamp == raw.timestamp) {
              tsForOff = DateTime.parse(
                buf.last.timestamp,
              ).add(Duration(seconds: intervalSeconds));
            }

            effective = SensorReading(
              voltage: 0.0,
              current: 0.0,
              power: 0.0,
              timestamp: tsForOff.toIso8601String(),
              state: 'OFF',
            );
            newTs = tsForOff;

            // Optional immediate reset on OFF (disabled by default)
            if (resetOnEveryOff && buf.isNotEmpty) {
              final prevState = buf.last.state?.toUpperCase();
              if (prevState == 'ON') {
                buf.clear();
              }
            }
          } else {
            // ON: use backend values as-is
            effective = raw;
          }
        } else {
          // No payload this tick. If last known is OFF, synthesize a zero point
          if (buf.isNotEmpty && (buf.last.state?.toUpperCase() == 'OFF')) {
            final lastTs = DateTime.parse(buf.last.timestamp);
            final synthTs = lastTs.add(Duration(seconds: intervalSeconds));
            newTs = synthTs;
            effective = SensorReading(
              voltage: 0.0,
              current: 0.0,
              power: 0.0,
              timestamp: synthTs.toIso8601String(),
              state: 'OFF',
            );
          }
        }

        if (effective != null) {
          _upsertAndEmit(
            deviceId: deviceId,
            controller: controller,
            next: effective,
            currentTs: newTs ?? DateTime.parse(effective.timestamp),
            intervalSeconds: intervalSeconds,
            bufferSeconds: bufferSeconds,
          );
        }

        // Normal path: keep polling
        _errors[deviceId] = 0;
        _scheduleNextPoll(deviceId, intervalSeconds, poll);
      } catch (e) {
        final newErr = (_errors[deviceId] ?? 0) + 1;
        _errors[deviceId] = newErr;

        if (newErr >= _maxConsecutiveErrors) {
          _controllers[deviceId]?.addError('Realtime unavailable: $e');
          stopRealtimeUpdates(deviceId);
          return;
        }
        _scheduleNextPoll(deviceId, intervalSeconds, poll);
      }
    }

    // Emit current buffer (may be empty)
    controller.add(List.unmodifiable(_buffers[deviceId]!));

    // Start polling
    _scheduleNextPoll(deviceId, intervalSeconds, poll);

    return controller.stream;
  }

  // Public: inject an OFF reading immediately (used by control flow for instant UI response)
  void pushSyntheticOff(String deviceId, {DateTime? at}) {
    final buf = _buffers.putIfAbsent(deviceId, () => <SensorReading>[]);
    final nowTs =
        at ??
        (buf.isNotEmpty
            ? DateTime.parse(
                buf.last.timestamp,
              ).add(const Duration(seconds: defaultIntervalSeconds))
            : DateTime.now());
    final r = SensorReading(
      voltage: 0.0,
      current: 0.0,
      power: 0.0,
      timestamp: nowTs.toIso8601String(),
      state: 'OFF',
    );
    final controller = _controllers.putIfAbsent(
      deviceId,
      () => StreamController<List<SensorReading>>.broadcast(),
    );
    _upsertAndEmit(
      deviceId: deviceId,
      controller: controller,
      next: r,
      currentTs: nowTs,
      intervalSeconds: defaultIntervalSeconds,
      bufferSeconds: defaultBufferSeconds,
    );
  }

  // Public: fetch once now and merge into buffer (speeds up indicator after ON)
  Future<void> forceRefresh(String deviceId) async {
    try {
      final r = await _deviceRepository.getLatestReadingForDevice(deviceId);
      if (r == null) return;
      final controller = _controllers.putIfAbsent(
        deviceId,
        () => StreamController<List<SensorReading>>.broadcast(),
      );
      _upsertAndEmit(
        deviceId: deviceId,
        controller: controller,
        next: r,
        currentTs: DateTime.parse(r.timestamp),
        intervalSeconds: defaultIntervalSeconds,
        bufferSeconds: defaultBufferSeconds,
      );
    } catch (_) {
      // best-effort
    }
  }

  void _upsertAndEmit({
    required String deviceId,
    required StreamController<List<SensorReading>> controller,
    required SensorReading next,
    required DateTime currentTs,
    required int intervalSeconds,
    required int bufferSeconds,
  }) {
    final buf = _buffers.putIfAbsent(deviceId, () => <SensorReading>[]);

    // Replace if same timestamp; otherwise append
    if (buf.isNotEmpty && buf.last.timestamp == next.timestamp) {
      buf[buf.length - 1] = next;
    } else {
      buf.add(next);
    }

    // TIME-BASED TRIM to last [bufferSeconds]
    final cutoff = currentTs.subtract(Duration(seconds: bufferSeconds));
    while (buf.isNotEmpty &&
        DateTime.parse(buf.first.timestamp).isBefore(cutoff)) {
      buf.removeAt(0);
    }

    // Safety bound by count in case sampling speeds up
    final maxCount = max(1, bufferSeconds ~/ max(1, intervalSeconds));
    if (buf.length > maxCount) {
      buf.removeRange(0, buf.length - maxCount);
    }

    controller.add(List.unmodifiable(buf));
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
      // ignore: discarded_futures
      poll();
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

final realtimeBufferStreamProvider =
    StreamProvider.family<List<SensorReading>, String>((ref, deviceId) {
      final repo = ref.read(realtimeRepositoryProvider);
      final stream = repo.startRealtimeUpdates(deviceId: deviceId);
      ref.onDispose(() => repo.stopRealtimeUpdates(deviceId));
      return stream;
    });
 */

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

  // Track commanded state to prevent race conditions
  final Map<String, String?> _commandedState = {};
  final Map<String, DateTime?> _lastStateChangeTime = {};

  // Polling and window
  static const int defaultIntervalSeconds = 2;
  static const int defaultBufferSeconds = 240;
  static const int _maxConsecutiveErrors = 5;
  static const int _maxDelaySeconds = 60;

  // Only clear buffer if gap > 15s from REAL TIME (not just data timestamps)
  static const Duration gapThreshold = Duration(seconds: 15);

  // Grace period to let commanded state override backend (prevent race condition)
  static const Duration _commandGracePeriod = Duration(seconds: 3);

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
        final raw = await _deviceRepository.getLatestReadingForDevice(deviceId);
        final buf = _buffers[deviceId]!;
        final now = DateTime.now();

        SensorReading? effective;
        DateTime? newTs;

        if (raw != null) {
          final rawState = raw.state?.toUpperCase();
          final rawTs = DateTime.parse(raw.timestamp);
          newTs = rawTs;

          // Check if we have a recent command that should override backend data
          final commandedState = _commandedState[deviceId];
          final lastCommandTime = _lastStateChangeTime[deviceId];
          final isWithinGracePeriod =
              lastCommandTime != null &&
              now.difference(lastCommandTime) < _commandGracePeriod;

          String actualState;
          if (isWithinGracePeriod && commandedState != null) {
            // Use commanded state during grace period
            actualState = commandedState;
          } else {
            // Use backend state
            actualState = rawState ?? 'UNKNOWN';
          }

          // Check for REAL TIME gap (not just data timestamp gap)
          // Only clear if we haven't received ANY data for > 15s
          if (buf.isNotEmpty) {
            final lastRealUpdateTime = _lastStateChangeTime[deviceId];
            if (lastRealUpdateTime != null &&
                now.difference(lastRealUpdateTime) > gapThreshold) {
              // Long gap in real time - start fresh
              buf.clear();
            }
          }

          if (actualState == 'OFF') {
            // Normalize OFF to clean zeros
            var tsForOff = rawTs;

            // If backend reuses same timestamp while OFF, extend with synthetic +interval
            if (buf.isNotEmpty && buf.last.timestamp == raw.timestamp) {
              tsForOff = DateTime.parse(
                buf.last.timestamp,
              ).add(Duration(seconds: intervalSeconds));
            }

            effective = SensorReading(
              voltage: 0.0,
              current: 0.0,
              power: 0.0,
              timestamp: tsForOff.toIso8601String(),
              state: 'OFF',
            );
            newTs = tsForOff;
          } else {
            // ON: use backend values as-is
            effective = SensorReading(
              voltage: raw.voltage,
              current: raw.current,
              power: raw.power,
              timestamp: raw.timestamp,
              state: actualState,
            );
          }
        } else {
          // No payload this tick. If last known is OFF, synthesize a zero point
          if (buf.isNotEmpty && (buf.last.state?.toUpperCase() == 'OFF')) {
            final lastTs = DateTime.parse(buf.last.timestamp);
            final synthTs = lastTs.add(Duration(seconds: intervalSeconds));
            newTs = synthTs;
            effective = SensorReading(
              voltage: 0.0,
              current: 0.0,
              power: 0.0,
              timestamp: synthTs.toIso8601String(),
              state: 'OFF',
            );
          }
        }

        if (effective != null) {
          _upsertAndEmit(
            deviceId: deviceId,
            controller: controller,
            next: effective,
            currentTs: newTs ?? DateTime.parse(effective.timestamp),
            intervalSeconds: intervalSeconds,
            bufferSeconds: bufferSeconds,
          );

          // Update last real update time
          _lastStateChangeTime[deviceId] = now;
        }

        _errors[deviceId] = 0;
        _scheduleNextPoll(deviceId, intervalSeconds, poll);
      } catch (e) {
        final newErr = (_errors[deviceId] ?? 0) + 1;
        _errors[deviceId] = newErr;

        if (newErr >= _maxConsecutiveErrors) {
          _controllers[deviceId]?.addError('Realtime unavailable: $e');
          stopRealtimeUpdates(deviceId);
          return;
        }
        _scheduleNextPoll(deviceId, intervalSeconds, poll);
      }
    }

    controller.add(List.unmodifiable(_buffers[deviceId]!));
    _scheduleNextPoll(deviceId, intervalSeconds, poll);

    return controller.stream;
  }

  // Public: inject an OFF reading immediately with commanded state tracking
  void pushSyntheticOff(String deviceId, {DateTime? at}) {
    final buf = _buffers.putIfAbsent(deviceId, () => <SensorReading>[]);
    final now = DateTime.now();
    final nowTs = at ?? now;

    // Set commanded state to prevent race condition
    _commandedState[deviceId] = 'OFF';
    _lastStateChangeTime[deviceId] = now;

    final r = SensorReading(
      voltage: 0.0,
      current: 0.0,
      power: 0.0,
      timestamp: nowTs.toIso8601String(),
      state: 'OFF',
    );

    final controller = _controllers.putIfAbsent(
      deviceId,
      () => StreamController<List<SensorReading>>.broadcast(),
    );

    _upsertAndEmit(
      deviceId: deviceId,
      controller: controller,
      next: r,
      currentTs: nowTs,
      intervalSeconds: defaultIntervalSeconds,
      bufferSeconds: defaultBufferSeconds,
    );
  }

  // Public: mark device as commanded ON (prevents race condition)
  void setCommandedOn(String deviceId) {
    _commandedState[deviceId] = 'ON';
    _lastStateChangeTime[deviceId] = DateTime.now();
  }

  // Public: fetch once now and merge into buffer
  Future<void> forceRefresh(String deviceId) async {
    try {
      final r = await _deviceRepository.getLatestReadingForDevice(deviceId);
      if (r == null) return;

      final controller = _controllers.putIfAbsent(
        deviceId,
        () => StreamController<List<SensorReading>>.broadcast(),
      );

      _upsertAndEmit(
        deviceId: deviceId,
        controller: controller,
        next: r,
        currentTs: DateTime.parse(r.timestamp),
        intervalSeconds: defaultIntervalSeconds,
        bufferSeconds: defaultBufferSeconds,
      );

      _lastStateChangeTime[deviceId] = DateTime.now();
    } catch (_) {
      // best-effort
    }
  }

  void _upsertAndEmit({
    required String deviceId,
    required StreamController<List<SensorReading>> controller,
    required SensorReading next,
    required DateTime currentTs,
    required int intervalSeconds,
    required int bufferSeconds,
  }) {
    final buf = _buffers.putIfAbsent(deviceId, () => <SensorReading>[]);

    // Replace if same timestamp; otherwise append
    if (buf.isNotEmpty && buf.last.timestamp == next.timestamp) {
      buf[buf.length - 1] = next;
    } else {
      buf.add(next);
    }

    // TIME-BASED TRIM: Keep last [bufferSeconds] of DATA
    // This preserves history across OFF/ON cycles if gap < 15s
    final cutoff = currentTs.subtract(Duration(seconds: bufferSeconds));
    while (buf.isNotEmpty &&
        DateTime.parse(buf.first.timestamp).isBefore(cutoff)) {
      buf.removeAt(0);
    }

    // Safety bound by count in case sampling speeds up
    final maxCount = max(1, bufferSeconds ~/ max(1, intervalSeconds));
    if (buf.length > maxCount) {
      buf.removeRange(0, buf.length - maxCount);
    }

    controller.add(List.unmodifiable(buf));
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
      // ignore: discarded_futures
      poll();
    });
  }

  void stopRealtimeUpdates(String deviceId) {
    _timers[deviceId]?.cancel();
    _timers.remove(deviceId);
    _errors.remove(deviceId);
    _buffers.remove(deviceId);
    _controllers[deviceId]?.close();
    _controllers.remove(deviceId);
    _commandedState.remove(deviceId);
    _lastStateChangeTime.remove(deviceId);
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
    _commandedState.clear();
    _lastStateChangeTime.clear();
  }
}

final realtimeRepositoryProvider = Provider<RealtimeRepository>((ref) {
  final deviceRepository = ref.read(deviceRepositoryProvider);
  final repo = RealtimeRepository(deviceRepository);
  ref.onDispose(repo.dispose);
  return repo;
});

final realtimeBufferStreamProvider =
    StreamProvider.family<List<SensorReading>, String>((ref, deviceId) {
      final repo = ref.read(realtimeRepositoryProvider);
      final stream = repo.startRealtimeUpdates(deviceId: deviceId);
      ref.onDispose(() => repo.stopRealtimeUpdates(deviceId));
      return stream;
    });
