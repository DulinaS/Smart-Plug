import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/http_client.dart';
import '../../core/services/secure_store.dart';
import '../../core/config/env.dart';
import '../models/user.dart';

class AuthRepository {
  final HttpClient _httpClient;
  final SecureStore _secureStore;

  AuthRepository(this._httpClient, this._secureStore);

  Future<Map<String, dynamic>> signUp(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      print('🔵 Attempting signup to: ${AppConfig.authBaseUrl}/signup');
      print('📧 Email: $email');

      final response = await _httpClient.dio.post(
        '${AppConfig.authBaseUrl}/signup',
        data: {'email': email, 'password': password, 'fullName': fullName},
      );

      print('✅ Signup response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('❌ Signup DioException:');
      print('   Status: ${e.response?.statusCode}');
      print('   Data: ${e.response?.data}');
      print('   Message: ${e.message}');
      throw _handleError(e);
    } catch (e) {
      print('❌ Signup unexpected error: $e');
      rethrow;
    }
  }

  Future<User> login(String email, String password) async {
    try {
      print('🔵 Attempting login to: ${AppConfig.authBaseUrl}/login');
      print('📧 Email: $email');

      final response = await _httpClient.dio.post(
        '${AppConfig.authBaseUrl}/login',
        data: {'email': email, 'password': password},
      );

      print('✅ Login response: ${response.data}');
      final data = response.data;

      if (data['accessToken'] != null) {
        await _secureStore.saveAuthToken(data['accessToken']);
        print('✅ Token saved');
      }
      if (data['refreshToken'] != null) {
        await _secureStore.saveRefreshToken(data['refreshToken']);
      }
      if (data['sub'] != null) {
        await _secureStore.saveUserId(data['sub']);
      }

      return User(
        id: data['sub'] ?? 'unknown',
        email: data['email'] ?? email,
        username: data['username'] ?? email.split('@')[0],
        displayName: data['name'],
        createdAt: DateTime.now(),
      );
    } on DioException catch (e) {
      print('❌ Login DioException:');
      print('   Status: ${e.response?.statusCode}');
      print('   Data: ${e.response?.data}');
      print('   Message: ${e.message}');
      throw _handleError(e);
    } catch (e) {
      print('❌ Login unexpected error: $e');
      rethrow;
    }
  }

  Future<bool> confirmSignUp(String email, String confirmationCode) async {
    try {
      final response = await _httpClient.dio.post(
        '${AppConfig.authBaseUrl}/confirm',
        data: {'email': email, 'confirmationCode': confirmationCode},
      );
      return response.data['message']?.toString().contains('verified') ?? false;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    await _secureStore.clearAll();
  }

  Future<User?> getCurrentUser() async {
    try {
      final token = await _secureStore.getAuthToken();
      final userId = await _secureStore.getUserId();

      if (token == null || userId == null) return null;

      return User(
        id: userId,
        email: 'cached@user.com',
        username: 'user',
        createdAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  String _handleError(DioException e) {
    if (e.response?.statusCode == 401) {
      return 'Invalid credentials';
    } else if (e.response?.statusCode == 409) {
      return 'User already exists';
    } else if (e.response?.data?['message'] != null) {
      return e.response!.data['message'];
    }
    return 'Authentication failed';
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final httpClient = ref.read(httpClientProvider);
  final secureStore = ref.read(secureStoreProvider);
  return AuthRepository(httpClient, secureStore);
});
