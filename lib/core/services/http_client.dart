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
        baseUrl: AppConfig.apiBaseUrl,
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
          if (error.response?.statusCode == 401) {
            // Token expired, try to refresh
            await _refreshToken();
            // Retry the request
            final options = error.requestOptions;
            final token = await _secureStore.getAuthToken();
            options.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(options);
            handler.resolve(response);
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }

  Future<void> _refreshToken() async {
    // Implement token refresh logic
  }

  Dio get dio => _dio;
}

final httpClientProvider = Provider<HttpClient>((ref) {
  final secureStore = ref.read(secureStoreProvider);
  return HttpClient(secureStore);
});
