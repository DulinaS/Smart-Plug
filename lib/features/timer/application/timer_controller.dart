import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/control_repo.dart';

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
      _startTicker();
    } catch (e) {
      state = state.copyWith(scheduling: false, error: e.toString());
    }
  }

  void cancel() {
    _ticker?.cancel();
    state = state.copyWith(active: false, endsAt: null, remaining: null);
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
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isActive) {
        _ticker?.cancel();
        return;
      }
      final now = DateTime.now();
      final remaining = state.endsAt!.difference(now);
      if (remaining <= Duration.zero) {
        // Timer finished: we do not send an extra command; backend already will auto-off.
        _ticker?.cancel();
        state = state.copyWith(
          active: false,
          endsAt: null,
          remaining: Duration.zero,
        );
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
