import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_plug/core/config/env.dart';
import 'package:smart_plug/core/services/provisioning_service.dart';
import 'package:smart_plug/data/repositories/user_device_repo.dart';

/// Provisioning flow (Option B: pre-provisioned device; link only)
/// 1) Connect to device AP (optionally auto-connect).
/// 2) Verify device AP is reachable (/ping).
/// 3) Send home Wi‑Fi credentials to device (/config).
/// 4) Wait until device reports connected (/status).
/// 5) Finalize device (turn AP off).
/// 6) Wait for phone internet/DNS to be restored.
/// 7) Link device to current user in User Device Service (/user-device) with deviceId, deviceName, roomName, plugType.
/// 8) Done.
enum ProvisioningStep {
  pickMethod,
  connectToDeviceAP,
  enterWifiCredentials,
  sendingCredentials,
  waitingForDevice,
  linkingDevice,
  success,
  error,
}

@immutable
class ProvisioningState {
  final ProvisioningStep step;
  final String? selectedMethod;
  final String? ssid;
  final String? password;
  final String? deviceId;
  final String? deviceName;
  final String? roomName;
  final String? plugType;
  final String? message;
  final bool busy;

  const ProvisioningState({
    required this.step,
    this.selectedMethod,
    this.ssid,
    this.password,
    this.deviceId,
    this.deviceName,
    this.roomName,
    this.plugType,
    this.message,
    this.busy = false,
  });

  ProvisioningState copyWith({
    ProvisioningStep? step,
    String? selectedMethod,
    String? ssid,
    String? password,
    String? deviceId,
    String? deviceName,
    String? roomName,
    String? plugType,
    String? message,
    bool? busy,
  }) {
    return ProvisioningState(
      step: step ?? this.step,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      roomName: roomName ?? this.roomName,
      plugType: plugType ?? this.plugType,
      message: message ?? this.message,
      busy: busy ?? this.busy,
    );
  }

  // CHANGED: start directly on the SoftAP path so UI does not need to mutate provider in initState.
  static ProvisioningState initial() => const ProvisioningState(
    step: ProvisioningStep.connectToDeviceAP,
    selectedMethod: 'softap',
  );
}

class ProvisioningController extends StateNotifier<ProvisioningState> {
  ProvisioningController(this._prov, this._userDevices)
    : super(ProvisioningState.initial());

  final ProvisioningService _prov;
  final UserDeviceRepository _userDevices;

  static final String _userDeviceApiHost = Uri.parse(
    AppConfig.userDeviceBaseUrl,
  ).host;

  // You can still keep this for future UI toggles between methods.
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

  void setDeviceDetails({
    required String deviceId,
    required String deviceName,
    required String roomName,
    required String plugType,
  }) {
    state = state.copyWith(
      deviceId: deviceId.trim(),
      deviceName: deviceName.trim(),
      roomName: roomName.trim(),
      plugType: plugType.trim(),
    );
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

  Future<void> waitAndLink() async {
    state = state.copyWith(
      busy: true,
      message: 'Verifying device is online...',
    );

    late final StatusResult result;
    try {
      result = await _prov.waitForStatus();
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

    try {
      await _prov.finalizeDevice();
    } catch (e) {
      debugPrint('Finalize failed (non-fatal): $e');
    }

    state = state.copyWith(message: 'Restoring internet connection...');
    final online = await _waitForInternetAndDns(
      _userDeviceApiHost,
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

    final deviceId =
        (state.deviceId?.isNotEmpty == true ? state.deviceId : result.deviceId)
            ?.trim();
    final deviceName = (state.deviceName ?? 'Smart Plug').trim();
    final roomName = (state.roomName ?? 'Living Room').trim();
    final plugType = (state.plugType ?? 'Custom').trim();

    if (deviceId == null || deviceId.isEmpty) {
      state = state.copyWith(
        step: ProvisioningStep.error,
        busy: false,
        message:
            'Device ID is required. Enter the ID from the sticker before continuing.',
      );
      return;
    }

    state = state.copyWith(
      step: ProvisioningStep.linkingDevice,
      message: 'Linking device to your account...',
    );

    Object? lastErr;
    for (int attempt = 0; attempt < 5; attempt++) {
      try {
        await _userDevices.linkDeviceToCurrentUser(
          deviceId: deviceId,
          deviceName: deviceName,
          roomName: roomName,
          plugType: plugType,
        );

        state = state.copyWith(
          deviceId: deviceId,
          step: ProvisioningStep.success,
          busy: false,
          message: 'Device linked successfully',
        );
        return;
      } catch (e, st) {
        lastErr = e;
        debugPrint('Link attempt ${attempt + 1} failed: $e\n$st');
        await Future.delayed(Duration(seconds: 2 << attempt));
      }
    }

    state = state.copyWith(
      step: ProvisioningStep.error,
      busy: false,
      message: 'Linking failed: $lastErr',
    );
  }

  Future<void> reprovision() async {
    try {
      await _prov.reprovisionAp();
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
      await _prov.resetDevice();
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
        try {
          await dio.get('https://www.google.com/generate_204');
        } catch (_) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
        try {
          final addrs = await InternetAddress.lookup(host);
          if (addrs.isNotEmpty) return true;
        } catch (_) {}
      }
      await Future.delayed(const Duration(seconds: 2));
    }
    return false;
  }
}

final provisioningControllerProvider =
    StateNotifierProvider<ProvisioningController, ProvisioningState>((ref) {
      final service = ref.read(provisioningServiceProvider);
      final userDevices = ref.read(userDeviceRepositoryProvider);
      return ProvisioningController(service, userDevices);
    });
