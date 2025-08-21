import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/http_client.dart';
import '../../core/services/secure_store.dart';
import '../models/user.dart';

class AuthRepository {
  final HttpClient _httpClient;
  final SecureStore _secureStore;

  AuthRepository(this._httpClient, this._secureStore);

  Future<User> login(String email, String password) async {
    try {
      final response = await _httpClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data;
      await _secureStore.saveAuthToken(data['token']);
      await _secureStore.saveRefreshToken(data['refreshToken']);
      await _secureStore.saveUserId(data['user']['id']);

      return User.fromJson(data['user']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> register(String email, String password, String username) async {
    try {
      final response = await _httpClient.dio.post(
        '/auth/register',
        data: {'email': email, 'password': password, 'username': username},
      );

      final data = response.data;
      return User.fromJson(data['user']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _httpClient.dio.post('/auth/logout');
    } catch (e) {
      // Continue with logout even if API fails
    } finally {
      await _secureStore.clearAll();
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final token = await _secureStore.getAuthToken();
      if (token == null) return null;

      final response = await _httpClient.dio.get('/auth/me');
      return User.fromJson(response.data['user']);
    } catch (e) {
      return null;
    }
  }

  String _handleError(DioException e) {
    if (e.response?.statusCode == 401) {
      return 'Invalid credentials';
    } else if (e.response?.statusCode == 409) {
      return 'User already exists';
    } else {
      return 'Authentication failed. Please try again.';
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final httpClient = ref.read(httpClientProvider);
  final secureStore = ref.read(secureStoreProvider);
  return AuthRepository(httpClient, secureStore);
});
