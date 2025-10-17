import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_plug/core/services/provisioning_service.dart';
import 'package:smart_plug/data/repositories/device_repo.dart';

enum ProvisioningStep {
  pickMethod,
  connectToDeviceAP,
  enterWifiCredentials,
  sendingCredentials,
  waitingForDevice,
  registeringDevice,
  success,
  error,
}

class ProvisioningState {
  final ProvisioningStep step;
  final String? selectedMethod;
  final String? ssid;
  final String? password;
  final String? deviceName;
  final String? room;
  final String? deviceId;
  final String? message;
  final bool busy;

  const ProvisioningState({
    required this.step,
    this.selectedMethod,
    this.ssid,
    this.password,
    this.deviceName,
    this.room,
    this.deviceId,
    this.message,
    this.busy = false,
  });

  ProvisioningState copyWith({
    ProvisioningStep? step,
    String? selectedMethod,
    String? ssid,
    String? password,
    String? deviceName,
    String? room,
    String? deviceId,
    String? message,
    bool? busy,
  }) {
    return ProvisioningState(
      step: step ?? this.step,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      deviceName: deviceName ?? this.deviceName,
      room: room ?? this.room,
      deviceId: deviceId ?? this.deviceId,
      message: message ?? this.message,
      busy: busy ?? this.busy,
    );
  }

  static ProvisioningState initial() =>
      const ProvisioningState(step: ProvisioningStep.pickMethod);
}

class ProvisioningController extends StateNotifier<ProvisioningState> {
  ProvisioningController(this._provisioning, this._devices)
    : super(ProvisioningState.initial());

  final ProvisioningService _provisioning;
  final DeviceRepository _devices;

  void pickMethod(String method) {
    state = state.copyWith(selectedMethod: method);
    if (method == 'softap') {
      state = state.copyWith(step: ProvisioningStep.connectToDeviceAP);
    } else {
      state = state.copyWith(
        step: ProvisioningStep.error,
        message: 'Only SoftAP is implemented in this version.',
      );
    }
  }

  Future<void> connectToAp({
    required String deviceSsid,
    String? deviceApPassword,
  }) async {
    state = state.copyWith(
      busy: true,
      message: 'Requesting OS to join $deviceSsid...',
    );
    final ok = await _provisioning.connectToDeviceAp(
      ssid: deviceSsid,
      password: deviceApPassword,
    );
    if (!ok) {
      state = state.copyWith(
        busy: false,
        message: 'Could not start Wi‑Fi join. Use Wi‑Fi settings instead.',
      );
      return;
    }
    final reachable = await _provisioning.pingDeviceAP();
    state = state.copyWith(
      busy: false,
      message: reachable
          ? 'Device hotspot detected.'
          : 'Device hotspot not reachable yet. Try again or use Wi‑Fi settings.',
      step: reachable
          ? ProvisioningStep.enterWifiCredentials
          : ProvisioningStep.connectToDeviceAP,
    );
  }

  Future<void> verifyDeviceAP() async {
    state = state.copyWith(busy: true, message: 'Checking device hotspot...');
    final ok = await _provisioning.pingDeviceAP();
    state = state.copyWith(
      busy: false,
      message: ok
          ? 'Device hotspot detected.'
          : 'Device hotspot not reachable. Connect and try again.',
      step: ok
          ? ProvisioningStep.enterWifiCredentials
          : ProvisioningStep.connectToDeviceAP,
    );
  }

  void setWifiCredentials({required String ssid, required String password}) {
    state = state.copyWith(ssid: ssid, password: password);
  }

  void setMetadata({String? deviceName, String? room}) {
    state = state.copyWith(deviceName: deviceName, room: room);
  }

  Future<void> submitCredentials({String? mqttEndpoint}) async {
    if (state.ssid == null || state.password == null) {
      state = state.copyWith(
        step: ProvisioningStep.error,
        message: 'Please provide Wi‑Fi SSID and password.',
      );
      return;
    }
    state = state.copyWith(
      step: ProvisioningStep.sendingCredentials,
      busy: true,
      message: 'Sending credentials to device...',
    );
    try {
      await _provisioning.sendWifiCredentials(
        ssid: state.ssid!,
        password: state.password!,
        mqttEndpoint: mqttEndpoint,
        deviceIdHint: state.deviceId,
      );
      state = state.copyWith(
        step: ProvisioningStep.waitingForDevice,
        busy: false,
        message: 'Waiting for device to join your Wi‑Fi...',
      );
    } catch (e) {
      state = state.copyWith(
        step: ProvisioningStep.error,
        busy: false,
        message: 'Failed to send credentials: $e',
      );
    }
  }

  Future<void> waitAndRegister() async {
    state = state.copyWith(
      busy: true,
      message: 'Verifying device is online...',
    );
    final result = await _provisioning.waitForStatus();
    if (!result.connected) {
      state = state.copyWith(
        step: ProvisioningStep.error,
        busy: false,
        message: result.message ?? 'Provisioning failed',
      );
      return;
    }

    // NEW: finalize AP shutdown once connected (firmware /finalize)
    await _provisioning.finalizeDevice();

    final id =
        result.deviceId ??
        state.deviceId ??
        'SmartPlug-${DateTime.now().millisecondsSinceEpoch}';
    state = state.copyWith(
      step: ProvisioningStep.registeringDevice,
      message: 'Registering device...',
      deviceId: id,
    );

    try {
      await _devices.addDevice(
        id,
        state.deviceName ?? 'Smart Plug',
        state.room ?? 'Living Room',
      );
      state = state.copyWith(
        step: ProvisioningStep.success,
        busy: false,
        message: 'Device added successfully',
      );
    } catch (e) {
      state = state.copyWith(
        step: ProvisioningStep.error,
        busy: false,
        message: 'Backend registration failed: $e',
      );
    }
  }

  void reset() {
    state = ProvisioningState.initial();
  }
}

final provisioningControllerProvider =
    StateNotifierProvider<ProvisioningController, ProvisioningState>((ref) {
      final service = ProvisioningService();
      final devices = ref.read(deviceRepositoryProvider);
      return ProvisioningController(service, devices);
    });
