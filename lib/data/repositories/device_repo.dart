import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/http_client.dart';
import '../../core/config/env.dart';
import '../models/device.dart';
import '../models/sensor_reading.dart';

class DeviceRepository {
  final HttpClient _httpClient;

  DeviceRepository(this._httpClient);

  Future<SensorReading> getLatestReading() async {
    try {
      final response = await _httpClient.dio.get(
        '${AppConfig.dataBaseUrl}/latest',
      );
      return SensorReading.fromApiResponse(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
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

  Future<void> addDevice(String deviceId, String name, String room) async {
    try {
      await _httpClient.dio.post(
        '${AppConfig.deviceBaseUrl}/add-device',
        data: {
          'deviceId': deviceId,
          'name': name,
          'room': room,
          'config': {
            'maxCurrent': 16.0,
            'maxPower': 3680.0,
            'safetyEnabled': true,
            'reportInterval': 5,
          },
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateDevice(
    String deviceId, {
    String? name,
    String? room,
  }) async {
    try {
      final data = <String, dynamic>{
        'deviceId': deviceId,
        'config': {
          'maxCurrent': 16.0,
          'maxPower': 3680.0,
          'safetyEnabled': true,
          'reportInterval': 5,
        },
      };

      if (name != null) data['name'] = name;
      if (room != null) data['room'] = room;

      await _httpClient.dio.put(
        '${AppConfig.deviceBaseUrl}/update-device',
        data: data,
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

  Future<List<Device>> getDevices() async {
    try {
      final reading = await getLatestReading();

      final device = Device(
        id: 'LivingRoomESP32',
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
    } catch (e) {
      final mockReading = SensorReading(
        voltage: 230.5,
        current: 2.1,
        power: 484.05,
        timestamp: DateTime.now().toIso8601String(),
      );

      final mockDevice = Device(
        id: 'LivingRoomESP32',
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

  String _handleError(DioException e) {
    if (e.response?.statusCode == 404) return 'Device not found';
    if (e.response?.statusCode == 403) return 'Access denied';
    if (e.type == DioExceptionType.connectionTimeout)
      return 'Connection timeout';
    if (e.type == DioExceptionType.receiveTimeout)
      return 'Device not responding';
    return 'Device operation failed';
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final httpClient = ref.read(httpClientProvider);
  return DeviceRepository(httpClient);
});
