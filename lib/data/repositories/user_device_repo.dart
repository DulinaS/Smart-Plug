import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/env.dart';
import '../../core/services/http_client.dart';
import '../../core/services/secure_store.dart';

@immutable
class UserDevice {
  final String deviceId;
  final String deviceName;
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

    await _http.dio.post(
      AppConfig.userDeviceBaseUrl,
      data: {
        'userId': email,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'roomName': roomName,
        'plugType': plugType,
      },
    );
  }

  Future<List<UserDevice>> getDevicesForCurrentUser() async {
    final email = await _secure.getUserEmail();
    if (email == null || email.isEmpty) {
      throw 'No user email found. Please log in again.';
    }

    final res = await _http.dio.post(
      '${AppConfig.userDeviceBaseUrl}/get',
      data: {'userId': email},
    );

    final raw = res.data;
    if (kDebugMode) {
      debugPrint(
        'UserDeviceRepo.getDevicesForCurrentUser email=$email, rawType=${raw.runtimeType}',
      );
    }

    dynamic root = raw;

    // NEW: API returns a JSON string → decode it first
    if (root is String) {
      try {
        root = json.decode(root);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to decode string body: $e');
        }
        root = {};
      }
    }

    List<dynamic> list = const [];

    if (root is List) {
      list = root;
    } else if (root is Map<String, dynamic>) {
      if (root['devices'] is List) {
        list = root['devices'] as List;
      } else if (root['Items'] is List) {
        list = root['Items'] as List;
      } else if (root['data'] is List) {
        list = root['data'] as List;
      } else if (root['body'] is String) {
        // Sometimes API Gateway nests JSON in "body"
        try {
          final decoded = json.decode(root['body']);
          if (decoded is List) {
            list = decoded;
          } else if (decoded is Map && decoded['devices'] is List) {
            list = decoded['devices'] as List;
          }
        } catch (_) {}
      }
    }

    final devices = list
        .whereType<Map<String, dynamic>>()
        .map(UserDevice.fromJson)
        .toList();

    if (kDebugMode) {
      debugPrint(
        'UserDeviceRepo.getDevicesForCurrentUser parsed=${devices.length}',
      );
    }

    return devices;
  }

  Future<void> updateUserDevice({
    required String deviceId,
    String? deviceName,
    String? roomName,
    String? plugType,
  }) async {
    final email = await _secure.getUserEmail();
    if (email == null || email.isEmpty)
      throw 'No user email found. Please log in again.';

    final body = <String, dynamic>{'userId': email, 'deviceId': deviceId};
    if (deviceName != null) body['deviceName'] = deviceName;
    if (roomName != null) body['roomName'] = roomName;
    if (plugType != null) body['plugType'] = plugType;

    await _http.dio.post('${AppConfig.userDeviceBaseUrl}/update', data: body);
  }

  Future<void> unlinkUserDevice({required String deviceId}) async {
    final email = await _secure.getUserEmail();
    if (email == null || email.isEmpty)
      throw 'No user email found. Please log in again.';

    await _http.dio.post(
      '${AppConfig.userDeviceBaseUrl}/unlink',
      data: {'userId': email, 'deviceId': deviceId},
    );
  }
}

final userDeviceRepositoryProvider = Provider<UserDeviceRepository>((ref) {
  final http = ref.read(httpClientProvider);
  final secure = ref.read(secureStoreProvider);
  return UserDeviceRepository(http, secure);
});
