import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/control_repo.dart';

class DeviceControlState {
  final bool? isOn; // null until user takes an action or we add status polling
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
  final ControlRepository _control;
  final String deviceId;

  DeviceControlController(this._control, this.deviceId)
    : super(const DeviceControlState());

  Future<void> setOn(bool on) async {
    final prev = state;
    state = state.copyWith(busy: true, error: null, isOn: on); // optimistic
    try {
      await _control.setOnOff(deviceId: deviceId, on: on);
      state = state.copyWith(busy: false);
    } catch (e) {
      state = prev.copyWith(busy: false, error: e.toString());
    }
  }

  Future<void> toggle() async {
    await setOn(!(state.isOn ?? false));
  }

  void clearError() => state = state.copyWith(error: null);
}

final deviceControlControllerProvider =
    StateNotifierProvider.family<
      DeviceControlController,
      DeviceControlState,
      String
    >((ref, deviceId) {
      final repo = ref.read(controlRepositoryProvider);
      return DeviceControlController(repo, deviceId);
    });
