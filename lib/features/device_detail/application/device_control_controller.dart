import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/control_repo.dart';
import '../../../data/repositories/realtime_repo.dart';
import '../../../data/models/sensor_reading.dart';

class DeviceControlState {
  final bool? isOn; // requested state
  final bool busy;
  final String? error;

  const DeviceControlState({this.isOn, this.busy = false, this.error});

  DeviceControlState copyWith({bool? isOn, bool? busy, String? error}) {
    return DeviceControlState(
      isOn: isOn ?? this.isOn,
      busy: busy ?? this.busy,
      error: error,
    );
  }
}

class DeviceControlController extends StateNotifier<DeviceControlState> {
  final Ref _ref;
  final ControlRepository _control;
  final String deviceId;

  DateTime? _lastCommandAt;
  static const Duration _minInterval = Duration(milliseconds: 900);
  static const Duration _ackTimeout = Duration(seconds: 6);

  DeviceControlController(this._ref, this._control, this.deviceId)
    : super(const DeviceControlState());

  Future<void> setOn(bool on) async {
    final now = DateTime.now();
    if (_lastCommandAt != null &&
        now.difference(_lastCommandAt!) < _minInterval) {
      return;
    }
    _lastCommandAt = now;

    final prev = state;
    state = state.copyWith(busy: true, error: null, isOn: on);

    try {
      // Send command to backend
      await _control.setOnOff(deviceId: deviceId, on: on);

      final rt = _ref.read(realtimeRepositoryProvider);

      if (!on) {
        // Immediate UI response for OFF
        // This injects synthetic OFF data AND sets commanded state
        rt.pushSyntheticOff(deviceId);
      } else {
        // For ON, mark as commanded ON to prevent race condition
        rt.setCommandedOn(deviceId);

        // Try to fetch latest data to speed up indicator
        // ignore: discarded_futures
        rt.forceRefresh(deviceId);
      }

      // Wait for explicit ack from realtime (backend confirms state change)
      final ackOk = await _waitForAck(desiredOn: on, timeout: _ackTimeout);

      if (!ackOk) {
        state = prev.copyWith(
          busy: false,
          isOn: on,
          error: 'No acknowledgement from device (timeout).',
        );
      } else {
        state = state.copyWith(busy: false);
      }
    } catch (e) {
      state = prev.copyWith(busy: false, error: e.toString());
    }
  }

  Future<void> toggle() async => setOn(!(state.isOn ?? false));

  void clearError() => state = state.copyWith(error: null);

  Future<bool> _waitForAck({
    required bool desiredOn,
    required Duration timeout,
  }) async {
    final stream = _ref.read(realtimeBufferStreamProvider(deviceId).stream);
    final desired = desiredOn ? 'ON' : 'OFF';

    final completer = Completer<bool>();
    late final StreamSubscription<List<SensorReading>> sub;

    final timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(false);
      sub.cancel();
    });

    sub = stream.listen((buffer) {
      if (buffer.isEmpty) return;
      final s = buffer.last.state?.toUpperCase();
      if (s == desired) {
        if (!completer.isCompleted) completer.complete(true);
        timer.cancel();
        sub.cancel();
      }
    }, onError: (_) {});

    return completer.future;
  }
}

final deviceControlControllerProvider =
    StateNotifierProvider.family<
      DeviceControlController,
      DeviceControlState,
      String
    >((ref, deviceId) {
      final control = ref.read(controlRepositoryProvider);
      return DeviceControlController(ref, control, deviceId);
    });
