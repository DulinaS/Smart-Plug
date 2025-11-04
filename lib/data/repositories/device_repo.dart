import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/http_client.dart';
import '../../core/config/env.dart';
import '../models/device.dart';
import '../models/sensor_reading.dart';
import '../../core/services/secure_store.dart';

class DeviceRepository {
  final HttpClient _httpClient;
  final SecureStore _secureStore;

  DeviceRepository(this._httpClient, this._secureStore);

  Future<SensorReading> getLatestReading() async {
    try {
      final response = await _httpClient.dio.get(
        '${AppConfig.dataBaseUrl}/latest',
      );
      return SensorReading.fromApiResponse(response.data);
    } on DioException catch (e) {
      // Keep mock on failure
      print('DioException in getLatestReading: ${e.type} ${e.message}');
      return SensorReading(
        voltage: 230.0 + (DateTime.now().millisecond % 10),
        current: 1.5 + (DateTime.now().millisecond % 100) / 100,
        power: 345.0 + (DateTime.now().millisecond % 50),
        timestamp: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Unexpected error in getLatestReading: $e');
      return SensorReading(
        voltage: 230.0,
        current: 1.5,
        power: 345.0,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<void> toggleDevice(String deviceId, bool turnOn) async {
    try {
      await _httpClient.dio.post(
        '${AppConfig.controlBaseUrl}/command',
        data: {'deviceId': deviceId, 'command': turnOn ? 'ON' : 'OFF'},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /*  // UPDATED: return the canonical deviceId from backend response.
  Future<String> addDevice(
    String provisionalId,
    String displayName,
    String room,
  ) async {
    try {
      // AWS IoT thingName must match: [a-zA-Z0-9:_-]+
      final sanitizedThingName = _sanitizeThingName(displayName);
      final userId = await _secureStore
          .getUserId(); // optional if backend derives from JWT

      final data = <String, dynamic>{
        'deviceId': provisionalId,
        'deviceName': sanitizedThingName, // thingName-safe
        'displayName': displayName, // user-facing label with spaces
        'room': room,
      };
      if (userId != null) {
        data['userId'] = userId;
      }

      final res = await _httpClient.dio.post(
        '${AppConfig.deviceBaseUrl}/add-device',
        data: data,
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw 'Unexpected response: ${res.statusCode}';
      }

      // Parse canonical ID from response: { device: { deviceId: "..." }, ... }
      final body = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};
      final device = body['device'] as Map<String, dynamic>?;
      final canonical = (device?['deviceId'] as String?)?.trim();

      // Fallbacks: if backend didn’t echo, prefer sanitized thingName (stable), else provisional
      if (canonical != null && canonical.isNotEmpty) return canonical;
      return sanitizedThingName.isNotEmpty ? sanitizedThingName : provisionalId;
    } on DioException catch (e) {
      print(
        'addDevice error: status=${e.response?.statusCode} data=${e.response?.data} type=${e.type} message=${e.message}',
      );
      throw _handleError(e);
    }
  }

  // Matches your UpdateDevice API
  Future<void> updateDevice(
    String deviceId, {
    String? name,
    String? room,
    DeviceConfig? config,
  }) async {
    try {
      final body = <String, dynamic>{'deviceId': deviceId};
      if (name != null) body['name'] = name;
      if (room != null) body['room'] = room;
      if (config != null) {
        body['config'] = {
          'maxCurrent': config.maxCurrent,
          'maxPower': config.maxPower,
          'safetyEnabled': config.safetyEnabled,
          'reportInterval': config.reportInterval,
        };
      }

      await _httpClient.dio.put(
        '${AppConfig.deviceBaseUrl}/update-device',
        data: body,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    try {
      await _httpClient.dio.delete(
        '${AppConfig.deviceBaseUrl}/delete-device',
        data: {'deviceId': deviceId},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
 */
  // Currently mock until you wire a real GET
  Future<List<Device>> getDevices() async {
    try {
      final reading = await getLatestReading();

      final device = Device(
        id: 'LivingRoomESP325',
        name: 'Smart Plug Device',
        room: 'Living Room',
        status: DeviceExtensions.statusFromSensorReading(reading),
        lastSeen: DateTime.parse(reading.timestamp),
        firmwareVersion: 'v1.0.0',
        isOnline: true,
        config: const DeviceConfig(
          maxCurrent: 16.0,
          maxPower: 3680.0,
          safetyEnabled: true,
          reportInterval: 5,
        ),
      );

      return [device];
    } catch (_) {
      final mockReading = SensorReading(
        voltage: 230.5,
        current: 2.1,
        power: 484.05,
        timestamp: DateTime.now().toIso8601String(),
      );

      final mockDevice = Device(
        id: 'LivingRoomESP324',
        name: 'Smart Plug (Demo)',
        room: 'Living Room',
        status: DeviceExtensions.statusFromSensorReading(mockReading),
        lastSeen: DateTime.now(),
        firmwareVersion: 'v1.0.0',
        isOnline: false,
        config: const DeviceConfig(
          maxCurrent: 16.0,
          maxPower: 3680.0,
          safetyEnabled: true,
          reportInterval: 5,
        ),
      );

      return [mockDevice];
    }
  }

  Future<Device> getDevice(String deviceId) async {
    final devices = await getDevices();
    return devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => throw Exception('Device not found'),
    );
  }

  // Replace disallowed chars with '-', collapse repeats, trim '-'
  String _sanitizeThingName(String input) {
    final replaced = input.replaceAll(RegExp(r'[^a-zA-Z0-9:_-]'), '-');
    final collapsed = replaced.replaceAll(RegExp(r'-{2,}'), '-');
    final trimmed = collapsed
        .replaceAll(RegExp(r'^-+'), '')
        .replaceAll(RegExp(r'-+$'), '');
    return trimmed.isEmpty ? 'Device' : trimmed;
  }

  String _handleError(DioException e) {
    final code = e.response?.statusCode;
    if (code == 401) return 'Not authenticated. Please log in again.';
    if (code == 403) return 'Access denied';
    if (code == 404) return 'Device not found';
    if (code == 409) return 'Device already registered';
    if (e.type == DioExceptionType.connectionTimeout)
      return 'Connection timeout';
    if (e.type == DioExceptionType.receiveTimeout)
      return 'Device not responding';
    if (e.type == DioExceptionType.unknown)
      return 'Network error. Please check your connection.';
    final msg = e.response?.data is Map<String, dynamic>
        ? e.response?.data['error']
        : null;
    return msg is String && msg.isNotEmpty ? msg : 'Device operation failed';
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final httpClient = ref.read(httpClientProvider);
  final secureStore = ref.read(secureStoreProvider);
  return DeviceRepository(httpClient, secureStore);
});
