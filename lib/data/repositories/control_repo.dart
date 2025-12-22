import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/http_client.dart';
import '../../core/services/secure_store.dart';
import '../../core/config/env.dart';

abstract class ControlRepository {
  Future<void> setOnOff({required String deviceId, required bool on});

  // NEW: schedule auto-off (or “on for N seconds” per backend semantics)
  Future<String> scheduleAutoOff({
    required String deviceId,
    required Duration duration,
  });
}

class ControlRepositoryImpl implements ControlRepository {
  final HttpClient _http;
  final SecureStore _secure;

  ControlRepositoryImpl(this._http, this._secure);

  static const String _commandUrl =
      'https://iqb73k9a2h.execute-api.us-east-1.amazonaws.com/device/command';

  @override
  Future<void> setOnOff({required String deviceId, required bool on}) async {
    final body = {'deviceId': deviceId, 'command': on ? 'ON' : 'OFF'};

    try {
      await _http.dio.post(_commandUrl, data: body);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404) throw 'Device not found';
      if (code == 400) throw 'Invalid request';
      if (code == 409) throw 'Device is offline or busy';
      throw 'Command failed';
    }
  }

  @override
  Future<String> scheduleAutoOff({
    required String deviceId,
    required Duration duration,
  }) async {
    // Enforce minimum 5 minutes (300 seconds)
    if (duration.inSeconds < 300) {
      throw 'Minimum timer is 5 minutes';
    }

    try {
      final res = await _http.dio.post(
        AppConfig.scheduleCommandEndpoint,
        data: {'deviceId': deviceId, 'seconds': duration.inSeconds},
      );
      // API returns {"message":"Device ... turned ON for 30 seconds"} or similar
      final msg = (res.data is Map && res.data['message'] != null)
          ? res.data['message'].toString()
          : 'Timer scheduled';
      return msg;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg =
          e.response?.data?.toString() ?? e.message ?? 'Schedule failed';
      if (code == 404) throw 'Device not found';
      if (code == 400) throw 'Invalid timer request';
      if (code == 409) throw 'Device is offline or busy';
      throw msg;
    }
  }
}

final controlRepositoryProvider = Provider<ControlRepository>((ref) {
  final http = ref.read(httpClientProvider);
  final secure = ref.read(secureStoreProvider);
  return ControlRepositoryImpl(http, secure);
});
