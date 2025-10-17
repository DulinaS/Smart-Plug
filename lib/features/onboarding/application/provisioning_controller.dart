import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

@immutable
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
  ProvisioningController(this._prov, this._devices)
    : super(ProvisioningState.initial());

  final ProvisioningService _prov;
  final DeviceRepository _devices;

  // IMPORTANT: Set this to your backend host. Pulled from your logs for now.
  // Prefer moving to a central config and injecting here later.
  static const String kCloudApiHost =
      'glpv8i3uvc.execute-api.us-east-1.amazonaws.com';

  // UI actions

  void pickMethod(String method) {
    state = state.copyWith(
      selectedMethod: method,
      step: ProvisioningStep.connectToDeviceAP,
      message: null,
    );
  }

  Future<void> connectToAp({
    String? deviceSsid,
    String? deviceApPassword,
  }) async {
    try {
      state = state.copyWith(
        busy: true,
        message: 'Connecting to device hotspot...',
      );
      await _prov.connectToAp(
        deviceSsid: deviceSsid ?? '',
        deviceApPassword: deviceApPassword,
      );
      state = state.copyWith(
        busy: false,
        message:
            'Connected to device hotspot. Tap "I am connected" or proceed.',
      );
    } catch (e) {
      state = state.copyWith(
        busy: false,
        message:
            'Failed to connect automatically. Open Wi‑Fi settings and connect manually.',
      );
    }
  }

  Future<void> verifyDeviceAP() async {
    try {
      state = state.copyWith(
        busy: true,
        message: 'Verifying device hotspot...',
      );
      final ok = await _prov.pingDevice();
      if (ok) {
        state = state.copyWith(
          step: ProvisioningStep.enterWifiCredentials,
          busy: false,
          message: null,
        );
      } else {
        state = state.copyWith(
          busy: false,
          message:
              'Device not reachable. Ensure you are connected to the device AP.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        busy: false,
        message:
            'Verification failed. Ensure you are connected to the device AP.',
      );
    }
  }

  void setWifiCredentials({required String ssid, required String password}) {
    state = state.copyWith(ssid: ssid, password: password);
  }

  void setMetadata({required String deviceName, required String room}) {
    state = state.copyWith(deviceName: deviceName, room: room);
  }

  Future<void> submitCredentials() async {
    final ssid = state.ssid?.trim();
    final pwd = state.password ?? '';
    if (ssid == null || ssid.isEmpty) {
      state = state.copyWith(message: 'SSID is required');
      return;
    }
    state = state.copyWith(
      step: ProvisioningStep.sendingCredentials,
      busy: true,
      message: 'Sending Wi‑Fi credentials...',
    );
    try {
      await _prov.sendWifiCredentials(ssid: ssid, password: pwd);
      state = state.copyWith(
        step: ProvisioningStep.waitingForDevice,
        busy: false,
        message: 'Waiting for device to join Wi‑Fi...',
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
    // 1) Poll the device until connected (while AP is still up)
    state = state.copyWith(
      busy: true,
      message: 'Verifying device is online...',
    );
    late final StatusResult result;
    try {
      result = await _prov
          .waitForStatus(); // resolves on "connected" or "error"
    } catch (e) {
      state = state.copyWith(
        step: ProvisioningStep.error,
        busy: false,
        message: 'Provisioning failed: $e',
      );
      return;
    }

    if (!result.connected) {
      state = state.copyWith(
        step: ProvisioningStep.error,
        busy: false,
        message: result.message ?? 'Provisioning failed',
      );
      return;
    }

    // 2) Finalize: tell device to turn AP off (may error as networks switch)
    try {
      await _prov.finalizeDevice();
    } catch (e) {
      debugPrint('Finalize failed (non-fatal): $e');
    }

    // 3) Wait for the phone to restore internet AND DNS for your backend host
    state = state.copyWith(message: 'Restoring internet connection...');
    final online = await _waitForInternetAndDns(
      kCloudApiHost,
      timeout: const Duration(seconds: 60),
    );
    if (!online) {
      state = state.copyWith(
        step: ProvisioningStep.error,
        busy: false,
        message:
            'No internet yet. Reconnect your phone to Wi‑Fi and try again.',
      );
      return;
    }

    // 4) Register device in backend (retry with backoff)
    final id = result.deviceId ?? state.deviceId ?? _fallbackDeviceId();
    state = state.copyWith(
      step: ProvisioningStep.registeringDevice,
      deviceId: id,
      message: 'Registering device...',
    );

    Object? lastErr;
    for (int attempt = 0; attempt < 5; attempt++) {
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
        return;
      } catch (e, st) {
        lastErr = e;
        debugPrint('addDevice attempt ${attempt + 1} failed: $e\n$st');
        await Future.delayed(Duration(seconds: 2 << attempt)); // 2,4,8,16,32
      }
    }
    state = state.copyWith(
      step: ProvisioningStep.error,
      busy: false,
      message: 'Backend registration failed: $lastErr',
    );
  }

  Future<void> reprovision() async {
    try {
      await _prov.reprovisionAp(); // turn AP back on without clearing creds
      state = state.copyWith(
        step: ProvisioningStep.connectToDeviceAP,
        message: 'Device AP is on. Reconnect and continue.',
      );
    } catch (e) {
      state = state.copyWith(
        step: ProvisioningStep.error,
        message: 'Failed to re-enable AP: $e',
      );
    }
  }

  Future<void> factoryReset() async {
    try {
      await _prov.resetDevice(); // clear creds and turn AP on
      state = state.copyWith(
        step: ProvisioningStep.connectToDeviceAP,
        message: 'Device reset. Connect to AP to set up again.',
      );
    } catch (e) {
      state = state.copyWith(
        step: ProvisioningStep.error,
        message: 'Failed to reset device: $e',
      );
    }
  }

  void reset() {
    state = ProvisioningState.initial();
  }

  // Helpers

  // Wait for connectivity + a tiny HTTPS probe AND confirm DNS resolves for host.
  Future<bool> _waitForInternetAndDns(
    String host, {
    required Duration timeout,
  }) async {
    final end = DateTime.now().add(timeout);
    final connectivity = Connectivity();
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ),
    );

    while (DateTime.now().isBefore(end)) {
      final type = await connectivity.checkConnectivity();
      final hasLink = type != ConnectivityResult.none;

      if (hasLink) {
        // 1) Try a fast probe that returns 204
        try {
          await dio.get('https://www.google.com/generate_204');
        } catch (_) {
          await Future.delayed(const Duration(seconds: 2));
          continue; // still not online
        }

        // 2) Ensure DNS works for the backend host
        try {
          final addrs = await InternetAddress.lookup(host);
          if (addrs.isNotEmpty) return true;
        } catch (_) {
          // DNS still not ready; keep waiting
        }
      }
      await Future.delayed(const Duration(seconds: 2));
    }
    return false;
  }

  String _fallbackDeviceId() =>
      'SmartPlug-${DateTime.now().millisecondsSinceEpoch}';
}

// Provider wiring
final provisioningControllerProvider =
    StateNotifierProvider<ProvisioningController, ProvisioningState>((ref) {
      final service = ref.read(provisioningServiceProvider);
      final devices = ref.read(deviceRepositoryProvider);
      return ProvisioningController(service, devices);
    });
