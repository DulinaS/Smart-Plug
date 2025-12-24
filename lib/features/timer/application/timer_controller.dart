import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/control_repo.dart';
import '../../../data/repositories/realtime_repo.dart';
import '../../device_detail/application/device_control_controller.dart';

// Represents the live timer state for one device.
@immutable
class DeviceTimerState {
  final String deviceId;
  final bool active;
  final DateTime? endsAt;
  final Duration? remaining;
  final bool scheduling; // network in progress
  final String? error;

  const DeviceTimerState({
    required this.deviceId,
    this.active = false,
    this.endsAt,
    this.remaining,
    this.scheduling = false,
    this.error,
  });

  DeviceTimerState copyWith({
    bool? active,
    DateTime? endsAt,
    Duration? remaining,
    bool? scheduling,
    String? error,
  }) {
    return DeviceTimerState(
      deviceId: deviceId,
      active: active ?? this.active,
      endsAt: endsAt ?? this.endsAt,
      remaining: remaining ?? this.remaining,
      scheduling: scheduling ?? this.scheduling,
      error: error,
    );
  }
}

class DeviceTimerController extends StateNotifier<DeviceTimerState> {
  final Ref _ref;
  Timer? _ticker;

  DeviceTimerController(this._ref, String deviceId)
    : super(DeviceTimerState(deviceId: deviceId));

  bool get isActive => state.active && state.endsAt != null;

  Future<void> start(Duration duration) async {
    if (duration.inSeconds < 300) {
      state = state.copyWith(error: 'Minimum is 5 minutes');
      return;
    }
    if (state.scheduling) return;
    state = state.copyWith(scheduling: true, error: null);

    try {
      final repo = _ref.read(controlRepositoryProvider);
      await repo.scheduleAutoOff(deviceId: state.deviceId, duration: duration);

      final ends = DateTime.now().add(duration);
      state = state.copyWith(
        active: true,
        endsAt: ends,
        remaining: duration,
        scheduling: false,
        error: null,
      );

      // SYNC: Mark device as ON in the control state and realtime repo
      // The backend turns the device ON when scheduling auto-off timer
      _ref
          .read(deviceControlControllerProvider(state.deviceId).notifier)
          .syncStateFromTimer(true);

      // Also notify realtime repo that device is commanded ON
      final rt = _ref.read(realtimeRepositoryProvider);
      rt.setCommandedOn(state.deviceId);
      // Force refresh to get latest readings
      // ignore: discarded_futures
      rt.forceRefresh(state.deviceId);

      _startTicker();
    } catch (e) {
      state = state.copyWith(scheduling: false, error: e.toString());
    }
  }

  Future<void> cancel() async {
    _ticker?.cancel();
    final deviceId = state.deviceId;
    state = state.copyWith(active: false, endsAt: null, remaining: null);

    // Send OFF command to turn off the device immediately
    try {
      final repo = _ref.read(controlRepositoryProvider);
      await repo.setOnOff(deviceId: deviceId, on: false);
    } catch (_) {
      // Best effort - continue with UI update even if command fails
    }

    // SYNC: Mark device as OFF
    _ref
        .read(deviceControlControllerProvider(deviceId).notifier)
        .syncStateFromTimer(false);

    // Push synthetic OFF to realtime repo for immediate UI feedback
    final rt = _ref.read(realtimeRepositoryProvider);
    rt.pushSyntheticOff(deviceId);
  }

  void addTime(Duration extra) {
    if (!isActive) return;
    final newEnd = state.endsAt!.add(extra);
    state = state.copyWith(endsAt: newEnd);
    // remaining recalculated on next tick
  }

  void clearError() => state = state.copyWith(error: null);

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!isActive) {
        _ticker?.cancel();
        return;
      }
      final now = DateTime.now();
      final remaining = state.endsAt!.difference(now);
      if (remaining <= Duration.zero) {
        // Timer finished: send explicit OFF command for immediate response
        _ticker?.cancel();
        state = state.copyWith(
          active: false,
          endsAt: null,
          remaining: Duration.zero,
        );

        // **Removes Delay of 30-40s**
        // Send explicit OFF command to turn off device immediately
        // This ensures the device turns off exactly when timer reaches 0
        // instead of waiting for backend's scheduled job (~30-40s delay)
        try {
          final repo = _ref.read(controlRepositoryProvider);
          await repo.setOnOff(deviceId: state.deviceId, on: false);
        } catch (_) {
          // Best effort - backend scheduled job will turn it off anyway
        }

        // SYNC: Mark device as OFF since the timer has elapsed
        _ref
            .read(deviceControlControllerProvider(state.deviceId).notifier)
            .syncStateFromTimer(false);

        // Also push synthetic OFF to realtime repo for immediate UI feedback
        final rt = _ref.read(realtimeRepositoryProvider);
        rt.pushSyntheticOff(state.deviceId);
      } else {
        state = state.copyWith(remaining: remaining);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

// Family provider so each device can have its own timer state.
final deviceTimerControllerProvider =
    StateNotifierProvider.family<
      DeviceTimerController,
      DeviceTimerState,
      String
    >((ref, deviceId) {
      return DeviceTimerController(ref, deviceId);
    });
