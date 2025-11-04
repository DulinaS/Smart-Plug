import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/env.dart';
import '../../core/services/http_client.dart';
import '../../core/services/secure_store.dart';

@immutable
class UserDevice {
  final String deviceId;
  final String deviceName; // display name
  final String? roomName;
  final String? plugType;
  final DateTime createdAt;

  const UserDevice({
    required this.deviceId,
    required this.deviceName,
    this.roomName,
    this.plugType,
    required this.createdAt,
  });

  factory UserDevice.fromJson(Map<String, dynamic> json) {
    return UserDevice(
      deviceId: json['deviceId'] as String,
      deviceName: (json['deviceName'] as String?) ?? '',
      roomName: json['roomName'] as String?,
      plugType: json['plugType'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class UserDeviceRepository {
  final HttpClient _http;
  final SecureStore _secure;

  UserDeviceRepository(this._http, this._secure);

  // Link a device to the current user (Option B)
  Future<void> linkDeviceToCurrentUser({
    required String deviceId,
    required String deviceName,
    required String roomName,
    required String plugType,
  }) async {
    final email = await _secure.getUserEmail();
    if (email == null || email.isEmpty) {
      throw 'No user email found. Please log in again.';
    }

    try {
      await _http.dio.post(
        AppConfig.userDeviceBaseUrl,
        data: {
          'userId': email, // email per your API
          'deviceId': deviceId, // sticker/printed id
          'deviceName': deviceName, // friendly name the user typed
          'roomName': roomName,
          'plugType': plugType, // e.g., Fan, Refrigerator, Oven...
        },
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 400) throw 'Missing required fields';
      throw 'Failed to link device';
    }
  }

  // List devices for current user
  Future<List<UserDevice>> getDevicesForCurrentUser() async {
    final email = await _secure.getUserEmail();
    if (email == null || email.isEmpty) {
      throw 'No user email found. Please log in again.';
    }

    try {
      final res = await _http.dio.post(
        '${AppConfig.userDeviceBaseUrl}/get',
        data: {'userId': email},
      );
      final data = res.data as Map<String, dynamic>;
      final list = (data['devices'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(UserDevice.fromJson)
          .toList();
      return list;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 400) throw 'Missing required field: userId';
      throw 'Error fetching user devices';
    }
  }

  // NEW: Update user device fields (deviceName, roomName, plugType)
  Future<void> updateUserDevice({
    required String deviceId,
    String? deviceName,
    String? roomName,
    String? plugType,
  }) async {
    final email = await _secure.getUserEmail();
    if (email == null || email.isEmpty) {
      throw 'No user email found. Please log in again.';
    }

    final body = <String, dynamic>{'userId': email, 'deviceId': deviceId};
    if (deviceName != null) body['deviceName'] = deviceName;
    if (roomName != null) body['roomName'] = roomName;
    if (plugType != null) body['plugType'] = plugType;

    try {
      await _http.dio.post('${AppConfig.userDeviceBaseUrl}/update', data: body);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 400) throw 'Missing required fields';
      throw 'Failed to update device';
    }
  }

  // NEW: Unlink user device
  Future<void> unlinkUserDevice({required String deviceId}) async {
    final email = await _secure.getUserEmail();
    if (email == null || email.isEmpty) {
      throw 'No user email found. Please log in again.';
    }

    try {
      await _http.dio.post(
        '${AppConfig.userDeviceBaseUrl}/unlink',
        data: {'userId': email, 'deviceId': deviceId},
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 400) throw 'Missing required fields';
      if (code == 404) throw 'Device not found';
      throw 'Failed to unlink device';
    }
  }
}

final userDeviceRepositoryProvider = Provider<UserDeviceRepository>((ref) {
  final http = ref.read(httpClientProvider);
  final secure = ref.read(secureStoreProvider);
  return UserDeviceRepository(http, secure);
});
