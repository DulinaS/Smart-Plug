import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/http_client.dart';
import '../models/device.dart';

class DeviceRepository {
  final HttpClient _httpClient;

  DeviceRepository(this._httpClient);

  Future<List<Device>> getDevices() async {
    try {
      final response = await _httpClient.dio.get('/devices');
      final List<dynamic> data = response.data['devices'];
      return data.map((json) => Device.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Device> getDevice(String deviceId) async {
    try {
      final response = await _httpClient.dio.get('/devices/$deviceId');
      return Device.fromJson(response.data['device']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> toggleDevice(String deviceId, bool turnOn) async {
    try {
      await _httpClient.dio.post(
        '/devices/$deviceId/command',
        data: {'action': turnOn ? 'ON' : 'OFF'},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Device> addDevice(String deviceId, String deviceSecret) async {
    try {
      final response = await _httpClient.dio.post(
        '/devices',
        data: {'deviceId': deviceId, 'secret': deviceSecret},
      );
      return Device.fromJson(response.data['device']);
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
      await _httpClient.dio.put(
        '/devices/$deviceId',
        data: {if (name != null) 'name': name, if (room != null) 'room': room},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    try {
      await _httpClient.dio.delete('/devices/$deviceId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response?.statusCode == 404) {
      return 'Device not found';
    } else if (e.response?.statusCode == 403) {
      return 'Access denied';
    } else {
      return 'Device operation failed. Please try again.';
    }
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final httpClient = ref.read(httpClientProvider);
  return DeviceRepository(httpClient);
});
