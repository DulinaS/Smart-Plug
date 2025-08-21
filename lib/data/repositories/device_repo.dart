import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/http_client.dart';
import '../../core/config/env.dart';
import '../models/device.dart';
import '../models/sensor_reading.dart';

class DeviceRepository {
  final HttpClient _httpClient;

  DeviceRepository(this._httpClient);

  // Get latest sensor reading from your friend's API
  Future<SensorReading> getLatestReading() async {
    try {
      final response = await _httpClient.dio.get(
        AppConfig.latestReadingEndpoint,
      );
      return SensorReading.fromApiResponse(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Send control command to device
  Future<void> toggleDevice(String deviceId, bool turnOn) async {
    try {
      final command = DeviceCommand(command: turnOn ? 'ON' : 'OFF');
      await _httpClient.dio.post(
        AppConfig.controlEndpoint,
        data: command.toJson(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Mock methods for screens that need device list (update when friend provides APIs)
  Future<List<Device>> getDevices() async {
    try {
      // Get latest reading to create a mock device
      final reading = await getLatestReading();

      // Create a mock device with real sensor data
      final device = Device(
        id: 'esp32-device-001',
        name: 'Smart Plug Device',
        room: 'Living Room',
        status: DeviceExtensions.statusFromSensorReading(reading),
        lastSeen: DateTime.parse(reading.timestamp),
        firmwareVersion: 'v1.0.0',
        isOnline: true, // Device is online if we got recent data
        config: const DeviceConfig(
          maxCurrent: 16.0,
          maxPower: 3680.0,
          safetyEnabled: true,
          reportInterval: 5,
        ),
      );

      return [device];
    } catch (e) {
      // Return empty list if API fails
      return [];
    }
  }

  Future<Device> getDevice(String deviceId) async {
    final devices = await getDevices();
    final device = devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => throw Exception('Device not found'),
    );
    return device;
  }

  // Placeholder methods (implement when friend provides APIs)
  Future<Device> addDevice(String deviceId, String deviceSecret) async {
    // TODO: Implement when friend provides device registration API
    throw UnimplementedError('Device registration API not yet available');
  }

  Future<void> updateDevice(
    String deviceId, {
    String? name,
    String? room,
  }) async {
    // TODO: Implement when friend provides device update API
    throw UnimplementedError('Device update API not yet available');
  }

  Future<void> deleteDevice(String deviceId) async {
    // TODO: Implement when friend provides device deletion API
    throw UnimplementedError('Device deletion API not yet available');
  }

  String _handleError(DioException e) {
    if (e.response?.statusCode == 404) {
      return 'Device not found';
    } else if (e.response?.statusCode == 403) {
      return 'Access denied';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout - check your internet';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Device not responding';
    } else {
      return 'Device operation failed: ${e.message}';
    }
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final httpClient = ref.read(httpClientProvider);
  return DeviceRepository(httpClient);
});
