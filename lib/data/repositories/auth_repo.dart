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
    String fullName, {
    // NEW: make billingType selectable, default General for flows like resend
    BillingType billingType = BillingType.general,
  }) async {
    try {
      final response = await _httpClient.dio.post(
        '${AppConfig.authBaseUrl}/signup',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'billingType': billingType.toApiString(), // NEW
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> login(String email, String password) async {
    try {
      final response = await _httpClient.dio.post(
        '${AppConfig.authBaseUrl}/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final token = (data['accessToken'] ?? data['token']) as String?;
      if (token != null) {
        await _secureStore.saveAuthToken(token);
      }
      final refresh =
          (data['refreshToken'] ?? data['refresh_token']) as String?;
      if (refresh != null) {
        await _secureStore.saveRefreshToken(refresh);
      }

      final nestedUser = data['user'] as Map<String, dynamic>?;
      final userId =
          (data['sub'] as String?) ??
          (nestedUser?['id'] as String?) ??
          (data['id'] as String?) ??
          'unknown';
      await _secureStore.saveUserId(userId);

      final emailFromResponse =
          (data['email'] ?? nestedUser?['email'] ?? email) as String;
      await _secureStore.saveUserEmail(emailFromResponse);

      final usernameFromResponse =
          (data['username'] ??
                  nestedUser?['username'] ??
                  emailFromResponse.split('@')[0])
              as String;
      final displayNameFromResponse =
          (data['name'] ?? nestedUser?['displayName']) as String?;

      // NEW: pull billingType from API if present, else default to General
      final rawBilling = (data['billingType'] ?? nestedUser?['billingType'])
          ?.toString();
      final billing = BillingTypeX.fromString(rawBilling);
      // Persist for cold start restore
      await _secureStore.saveUsername(usernameFromResponse);
      await _secureStore.saveDisplayName(displayNameFromResponse);
      await _secureStore.saveUserBillingType(billing.toApiString());

      return User(
        id: userId,
        email: emailFromResponse,
        username: usernameFromResponse,
        displayName: displayNameFromResponse,
        createdAt: DateTime.now(),
        billingType: billing, // NEW
      );
    } on DioException catch (e) {
      throw _handleError(e);
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

  // Restore profile on app start using persisted values
  Future<User?> getCurrentUser() async {
    try {
      final token = await _secureStore.getAuthToken();
      final userId = await _secureStore.getUserId();
      final email = await _secureStore.getUserEmail();
      if (token == null || userId == null || email == null) return null;

      final username =
          (await _secureStore.getUsername()) ?? email.split('@').first;
      final displayName = await _secureStore.getDisplayName();
      final btRaw = (await _secureStore.getUserBillingType()) ?? 'General';
      final billing = BillingTypeX.fromString(btRaw);

      return User(
        id: userId,
        email: email,
        username: username,
        displayName: displayName,
        createdAt: DateTime.now(),
        billingType: billing, // NEW
      );
    } catch (_) {
      return null;
    }
  }

  String _handleError(DioException e) {
    if (e.response?.statusCode == 401) return 'Invalid credentials';
    if (e.response?.statusCode == 409) return 'User already exists';
    if (e.response?.data?['message'] != null) {
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
