import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:wifi_iot/wifi_iot.dart';

/// Handles SoftAP provisioning flow by talking to the device's temporary hotspot.
class ProvisioningService {
  ProvisioningService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'http://192.168.4.1',
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 4),
              contentType: Headers.jsonContentType,
            ),
          );

  final Dio _dio;

  /// Try to join the device hotspot from inside the app.
  /// Returns true if the OS accepted and switched to the SSID (may still take a moment to get IP).
  Future<bool> connectToDeviceAp({
    required String ssid,
    String? password,
    bool withInternet = false, // SoftAPs typically have no internet
  }) async {
    try {
      final security = (password != null && password.isNotEmpty)
          ? NetworkSecurity.WPA
          : NetworkSecurity.NONE;

      final ok = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        joinOnce: true,
        withInternet: withInternet,
        security: security,
      );

      if (ok == true) {
        await Future.delayed(const Duration(seconds: 2));
      }
      return ok == true;
    } catch (e) {
      debugPrint('connectToDeviceAp error: $e');
      return false;
    }
  }

  /// Optionally read current SSID (may require platform/location toggles on some Android devices).
  Future<String?> getCurrentSsid() async {
    try {
      return await WiFiForIoTPlugin.getSSID();
    } catch (e) {
      debugPrint('getCurrentSsid error: $e');
      return null;
    }
  }

  /// Pings the device AP to check that we’re connected to it.
  Future<bool> pingDeviceAP() async {
    try {
      final resp = await _dio.get('/ping');
      return resp.data is Map && (resp.data['ok'] == true);
    } on DioException {
      try {
        final resp = await _dio.get(
          '/provision',
        ); // firmware includes this no-op too
        return resp.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
  }

  /// Sends Wi‑Fi credentials for the home network to the device.
  Future<void> sendWifiCredentials({
    required String ssid,
    required String password,
    String? region,
    String? mqttEndpoint,
    String? deviceIdHint,
  }) async {
    await _dio.post(
      '/config',
      data: {
        'ssid': ssid,
        'password': password,
        if (region != null) 'region': region,
        if (mqttEndpoint != null) 'mqttEndpoint': mqttEndpoint,
        if (deviceIdHint != null) 'deviceId': deviceIdHint,
      },
    );
  }

  /// Tells the device to shut down AP and stay in STA mode after success.
  Future<bool> finalizeDevice() async {
    try {
      final resp = await _dio.get('/finalize');
      return resp.statusCode == 200 &&
          (resp.data is Map ? resp.data['ok'] == true : true);
    } catch (e) {
      debugPrint('finalizeDevice error: $e');
      return false;
    }
  }

  /// Poll provisioning status until connected or timeout.
  /// Returns a tuple of (connected, deviceId, message).
  Future<({bool connected, String? deviceId, String? message})> waitForStatus({
    Duration timeout = const Duration(minutes: 2),
    Duration interval = const Duration(seconds: 3),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      try {
        final resp = await _dio.get('/status');
        if (resp.data is Map) {
          final state = resp.data['state']?.toString().toLowerCase();
          final msg = resp.data['message']?.toString();
          final id = resp.data['deviceId']?.toString();
          if (state == 'connected') {
            return (connected: true, deviceId: id, message: msg);
          }
          if (state == 'error') {
            return (connected: false, deviceId: id, message: msg ?? 'Error');
          }
        }
      } catch (e) {
        debugPrint('Provisioning status check error: $e');
      }
      await Future.delayed(interval);
    }
    return (
      connected: false,
      deviceId: null,
      message: 'Provisioning timed out',
    );
  }
}
