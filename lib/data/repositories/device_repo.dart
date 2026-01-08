import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/http_client.dart';
import '../../core/services/secure_store.dart';
import '../../core/config/env.dart';
import '../../core/utils/error_handler.dart';
import '../models/sensor_reading.dart';

class DeviceRepository {
  final HttpClient _httpClient;
  final SecureStore _secureStore;

  DeviceRepository(this._httpClient, this._secureStore);

  // Fetch the latest reading for a device.
  // Returns null when the API effectively says "no data" (empty/null/wrapped) so callers treat it as normal.
  // Adds +5h 30m to convert US-EAST-1 time to Sri Lanka time per your requirement.
  Future<SensorReading?> getLatestReadingForDevice(String deviceId) async {
    try {
      final res = await _httpClient.dio.post(
        '${AppConfig.dataBaseUrl}/latest',
        data: {'deviceId': deviceId},
      );

      if (res.statusCode == 204) return null;

      dynamic root = res.data;
      if (root == null) return null;

      // String body → JSON decode if possible; else treat as "no data"
      if (root is String) {
        final trimmed = root.trim().toLowerCase();
        if (trimmed.isEmpty ||
            trimmed == 'null' ||
            trimmed == 'no' ||
            trimmed == 'none') {
          return null;
        }
        try {
          root = json.decode(root);
        } catch (_) {
          return null;
        }
      }

      // API Gateway wrapping
      if (root is Map<String, dynamic> && root['body'] != null) {
        final body = root['body'];
        if (body is String) {
          final trimmed = body.trim().toLowerCase();
          if (trimmed.isEmpty ||
              trimmed == 'null' ||
              trimmed == 'no' ||
              trimmed == 'none') {
            return null;
          }
          root = json.decode(body);
        } else if (body is Map<String, dynamic>) {
          root = body;
        }
      }

      if (root is! Map<String, dynamic>) return null;
      final map = root as Map<String, dynamic>;

      // Message-like responses that mean "no data"
      final msg = (map['message'] ?? map['status'] ?? '')
          .toString()
          .toLowerCase();
      if (msg.contains('no data') ||
          msg.contains('empty') ||
          msg.contains('not found')) {
        return null;
      }

      // Extract required fields (0 values are valid)
      final tsStr = map['timestamp']?.toString();
      final current = (map['current'] as num?)?.toDouble();
      final voltage = (map['voltage'] as num?)?.toDouble();
      final power = (map['power'] as num?)?.toDouble();
      if (tsStr == null ||
          current == null ||
          voltage == null ||
          power == null) {
        return null;
      }

      // Convert to Sri Lanka time (+5h 03m)
      final serverTs = DateTime.parse(tsStr);
      final slTs = serverTs.add(const Duration(hours: 5, minutes: 30));

      return SensorReading(
        voltage: voltage,
        current: current,
        power: power,
        timestamp: slTs.toIso8601String(),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handleDeviceError(e);
    } catch (e) {
      throw ErrorHandler.handleException(e, context: 'Fetch device data');
    }
  }

  // Send ON/OFF command
  Future<void> toggleDevice(String deviceId, bool turnOn) async {
    try {
      await _httpClient.dio.post(
        '${AppConfig.controlBaseUrl}/command',
        data: {'deviceId': deviceId, 'command': turnOn ? 'ON' : 'OFF'},
      );
    } on DioException catch (e) {
      throw ErrorHandler.handleControlError(e);
    } catch (e) {
      throw ErrorHandler.handleException(e, context: 'Device control');
    }
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final httpClient = ref.read(httpClientProvider);
  final secureStore = ref.read(secureStoreProvider);
  return DeviceRepository(httpClient, secureStore);
});
