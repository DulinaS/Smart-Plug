import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';
import 'secure_store.dart';

class HttpClient {
  late final Dio _dio;
  final SecureStore _secureStore;

  HttpClient(this._secureStore) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl, // repos mostly use full URLs
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStore.getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Guard against infinite loop while refresh is unimplemented
          final alreadyRetried = error.requestOptions.extra['ret'] == true;

          if (error.response?.statusCode == 401 && !alreadyRetried) {
            error.requestOptions.extra['ret'] = true;

            // TODO: implement refresh using _secureStore.getRefreshToken()
            // For now, do not retry blindly; just pass the error through.
            return handler.next(error);
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }

  Future<void> _refreshToken() async {
    // Implement token refresh logic if your auth service supports it.
  }

  Dio get dio => _dio;
}

final httpClientProvider = Provider<HttpClient>((ref) {
  final secureStore = ref.read(secureStoreProvider);
  return HttpClient(secureStore);
});
