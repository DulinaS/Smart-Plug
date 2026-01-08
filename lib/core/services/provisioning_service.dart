import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/error_handler.dart';

// Optional: automatic AP connect on Android via wifi_iot
// Add wifi_iot to pubspec.yaml to use this path. If unavailable, connectToAp will no-op gracefully.
import 'package:wifi_iot/wifi_iot.dart' as wifi_iot;

/// Riverpod provider
final provisioningServiceProvider = Provider<ProvisioningService>(
  (ref) => ProvisioningService(),
);

/// Result returned by waitForStatus/getStatus
@immutable
class StatusResult {
  final bool connected;
  final String state; // "connected", "connecting", "ap", "waiting", "error"
  final String? deviceId;
  final String? message;
  final String? ssid;
  final String? bssid;
  final String? ip;
  final int? rssi;
  final int? channel;
  final Map<String, dynamic>? raw;

  const StatusResult({
    required this.connected,
    required this.state,
    this.deviceId,
    this.message,
    this.ssid,
    this.bssid,
    this.ip,
    this.rssi,
    this.channel,
    this.raw,
  });

  factory StatusResult.fromJson(Map<String, dynamic> json) {
    final state = (json['state'] as String?) ?? 'waiting';
    return StatusResult(
      connected: state == 'connected',
      state: state,
      deviceId: json['deviceId'] as String?,
      message: json['message'] as String?,
      ssid: json['ssid'] as String?,
      bssid: json['bssid'] as String?,
      ip: json['ip'] as String?,
      rssi: (json['rssi'] is num) ? (json['rssi'] as num).toInt() : null,
      channel: (json['channel'] is num)
          ? (json['channel'] as num).toInt()
          : null,
      raw: json,
    );
  }
}

class ProvisioningService {
  ProvisioningService({this.deviceApBaseUrl = 'http://192.168.4.1', Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 4),
            ),
          );

  /// Base URL of the device while in AP (SoftAP) mode
  final String deviceApBaseUrl;

  final Dio _dio;

  Uri _u(String path) => Uri.parse('$deviceApBaseUrl$path');

  // ---------- Auto-connect to device AP (best-effort) ----------

  /// Attempts to connect to the device hotspot (Android only).
  /// If the plugin is not available or platform is unsupported, this is a no-op that returns false.
  Future<bool> connectToAp({
    required String deviceSsid,
    String? deviceApPassword,
  }) async {
    try {
      if (!Platform.isAndroid) return false;

      // If already connected to the target SSID, return
      final current = await wifi_iot.WiFiForIoTPlugin.getSSID();
      if ((current ?? '').replaceAll('"', '') == deviceSsid) {
        return true;
      }

      final success = await wifi_iot.WiFiForIoTPlugin.connect(
        deviceSsid,
        password: deviceApPassword,
        security: (deviceApPassword == null || deviceApPassword.isEmpty)
            ? wifi_iot.NetworkSecurity.NONE
            : wifi_iot.NetworkSecurity.WPA,
        joinOnce: true,
        withInternet: false,
        isHidden: false,
      );

      if (!success) return false;

      // Wait until SSID matches
      final end = DateTime.now().add(const Duration(seconds: 20));
      while (DateTime.now().isBefore(end)) {
        final ssid = await wifi_iot.WiFiForIoTPlugin.getSSID();
        if ((ssid ?? '').replaceAll('"', '') == deviceSsid) {
          return true;
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      debugPrint('connectToAp failed: $e');
    }
    return false;
  }

  // ---------- Device HTTP APIs ----------

  Future<bool> pingDevice() async {
    try {
      final res = await _dio.getUri(_u('/ping'));
      if (res.statusCode == 200) {
        final data = _asMap(res.data);
        return data['ok'] == true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  Future<void> sendWifiCredentials({
    required String ssid,
    required String password,
  }) async {
    try {
      final body = {'ssid': ssid, 'password': password};
      final res = await _dio.postUri(
        _u('/config'),
        data: jsonEncode(body),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (res.statusCode != 200) {
        throw 'Device rejected Wi-Fi credentials. Please check the password and try again.';
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw 'Device not responding. Please ensure you are connected to the device hotspot.';
      }
      throw 'Failed to send Wi-Fi credentials to device. Please try again.';
    } catch (e) {
      if (e is String) rethrow;
      throw ErrorHandler.handleException(e, context: 'Configure device');
    }
  }

  /// Polls /status until state is 'connected' or 'error' or timeout.
  Future<StatusResult> waitForStatus({
    Duration timeout = const Duration(seconds: 45),
    Duration pollEvery = const Duration(milliseconds: 1500),
  }) async {
    final end = DateTime.now().add(timeout);
    StatusResult? last;
    while (DateTime.now().isBefore(end)) {
      try {
        final res = await _dio.getUri(_u('/status'));
        if (res.statusCode == 200) {
          final data = _asMap(res.data);
          final status = StatusResult.fromJson(data);
          last = status;

          // The firmware may send a one-shot "error" pulse; treat that as terminal failure
          if (status.state == 'connected' || status.state == 'error') {
            return status;
          }
        }
      } catch (e) {
        // Ignore transient failures while AP/STA transitions happen
      }
      await Future.delayed(pollEvery);
    }
    return last ??
        const StatusResult(
          connected: false,
          state: 'timeout',
          message: 'Timed out waiting for device',
        );
  }

  /// Tells device to turn AP off (STA only).
  Future<void> finalizeDevice() async {
    try {
      await _dio.getUri(_u('/finalize'));
    } catch (e) {
      // Not fatal; the phone may be switching networks right now.
      debugPrint('finalizeDevice error: $e');
    }
  }

  /// Re-enable AP without clearing creds (AP+STA mode).
  Future<void> reprovisionAp() async {
    try {
      final res = await _dio.getUri(_u('/reprovision'));
      if (res.statusCode != 200) {
        throw 'Failed to re-enable device access point.';
      }
    } on DioException catch (e) {
      throw ErrorHandler.handleException(e, context: 'Re-enable device AP');
    } catch (e) {
      if (e is String) rethrow;
      throw ErrorHandler.handleException(e, context: 'Re-enable device AP');
    }
  }

  /// Clear saved Wi‑Fi credentials and start AP.
  Future<void> resetDevice() async {
    try {
      final res = await _dio.getUri(_u('/reset'));
      if (res.statusCode != 200) {
        throw 'Failed to reset device. Please try again.';
      }
    } on DioException catch (e) {
      throw ErrorHandler.handleException(e, context: 'Reset device');
    } catch (e) {
      if (e is String) rethrow;
      throw ErrorHandler.handleException(e, context: 'Reset device');
    }
  }

  /// Single read of /status (no waiting)
  Future<StatusResult> getStatus() async {
    try {
      final res = await _dio.getUri(_u('/status'));
      if (res.statusCode != 200) {
        throw 'Failed to get device status.';
      }
      return StatusResult.fromJson(_asMap(res.data));
    } on DioException catch (e) {
      throw 'Device not responding. Please check your connection to the device hotspot.';
    } catch (e) {
      if (e is String) rethrow;
      throw ErrorHandler.handleException(e, context: 'Get device status');
    }
  }

  // ---------- Helpers ----------

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String && data.isNotEmpty)
      return jsonDecode(data) as Map<String, dynamic>;
    throw const FormatException('Malformed JSON');
  }
}
