import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/env.dart';
import '../../core/services/http_client.dart';
import '../../core/services/secure_store.dart';

@immutable
class UserDevice {
  final String deviceId;
  final String deviceName; // display name as stored in user-device svc
  final DateTime createdAt;

  const UserDevice({
    required this.deviceId,
    required this.deviceName,
    required this.createdAt,
  });

  factory UserDevice.fromJson(Map<String, dynamic> json) {
    return UserDevice(
      deviceId: json['deviceId'] as String,
      deviceName: (json['deviceName'] as String?) ?? '',
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

  // POST {base}/user-device
  Future<void> linkDeviceToCurrentUser({
    required String deviceId,
    required String deviceName,
  }) async {
    final email = await _secure.getUserEmail();
    if (email == null || email.isEmpty) {
      throw 'No user email found. Please log in again.';
    }

    try {
      await _http.dio.post(
        AppConfig.userDeviceBaseUrl,
        data: {
          'userId': email, // API expects email as userId
          'deviceId': deviceId, // canonical device id to link
          'deviceName': deviceName,
        },
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 400) throw 'Missing required fields';
      throw 'Failed to add user-device link';
    }
  }

  // POST {base}/user-device/get
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
}

final userDeviceRepositoryProvider = Provider<UserDeviceRepository>((ref) {
  final http = ref.read(httpClientProvider);
  final secure = ref.read(secureStoreProvider);
  return UserDeviceRepository(http, secure);
});
