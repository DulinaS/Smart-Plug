import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStore {
  static const _storage = FlutterSecureStorage();

  static const _authTokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userEmailKey = 'user_email';

  // NEW: persist username + displayName so we can restore real profile on app start
  static const _usernameKey = 'user_username';
  static const _displayNameKey = 'user_display_name';

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _userEmailKey, value: email);
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  // NEW
  Future<void> saveUsername(String username) async {
    await _storage.write(key: _usernameKey, value: username);
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  // NEW
  Future<void> saveDisplayName(String? displayName) async {
    if (displayName == null || displayName.isEmpty) {
      await _storage.delete(key: _displayNameKey);
    } else {
      await _storage.write(key: _displayNameKey, value: displayName);
    }
  }

  Future<String?> getDisplayName() async {
    return await _storage.read(key: _displayNameKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());
