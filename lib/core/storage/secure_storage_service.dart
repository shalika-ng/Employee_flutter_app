import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists auth tokens on-device using platform secure storage
/// (Keychain on iOS/macOS, EncryptedSharedPreferences on Android).
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _userDataKey = 'auth_user_data';

  Future<void> saveTokens({
    required String token,
    required String refreshToken,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveUserData(String userData) =>
      _storage.write(key: _userDataKey, value: userData);

  Future<String?> readUserData() => _storage.read(key: _userDataKey);

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userDataKey);
  }
}
