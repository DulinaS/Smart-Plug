import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/http_client.dart';
import '../../core/services/secure_store.dart';

abstract class ControlRepository {
  Future<void> setOnOff({required String deviceId, required bool on});
}

class ControlRepositoryImpl implements ControlRepository {
  final HttpClient _http;
  final SecureStore _secure;

  ControlRepositoryImpl(this._http, this._secure);

  static const String _commandUrl =
      'https://iqb73k9a2h.execute-api.us-east-1.amazonaws.com/device/command';

  @override
  Future<void> setOnOff({required String deviceId, required bool on}) async {
    // If you need the user email for auditing later, it’s available:
    // final email = await _secure.getUserEmail();

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
}

final controlRepositoryProvider = Provider<ControlRepository>((ref) {
  final http = ref.read(httpClientProvider);
  final secure = ref.read(secureStoreProvider);
  return ControlRepositoryImpl(http, secure);
});
