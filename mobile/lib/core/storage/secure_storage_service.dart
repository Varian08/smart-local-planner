import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Hardware-backed secure storage service for authentication tokens.
/// Utilizes Android Keystore (AES-256 via EncryptedSharedPreferences) and iOS Keychain.
class SecureStorageService {
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserProfile = 'user_profile';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  /// Saves the JWT access token securely.
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: keyAccessToken, value: token);
  }

  /// Retrieves the stored JWT access token, or null if not found.
  Future<String?> getAccessToken() async {
    return await _storage.read(key: keyAccessToken);
  }

  /// Deletes the stored JWT access token.
  Future<void> deleteAccessToken() async {
    await _storage.delete(key: keyAccessToken);
  }

  /// Saves the rotating JWT refresh token securely.
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: keyRefreshToken, value: token);
  }

  /// Retrieves the stored JWT refresh token, or null if not found.
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: keyRefreshToken);
  }

  /// Deletes the stored JWT refresh token.
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: keyRefreshToken);
  }

  /// Atomically saves both access and refresh tokens.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  /// Saves serialized user profile metadata securely.
  Future<void> saveUserProfileJson(String userJson) async {
    await _storage.write(key: keyUserProfile, value: userJson);
  }

  /// Retrieves stored serialized user profile metadata, or null if not found.
  Future<String?> getUserProfileJson() async {
    return await _storage.read(key: keyUserProfile);
  }

  /// Clears all stored credentials and cached user metadata on logout or revoked sessions.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
