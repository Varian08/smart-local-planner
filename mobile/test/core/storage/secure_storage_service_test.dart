import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/core/storage/secure_storage_service.dart';

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.clear();
  }
}

void main() {
  late FakeFlutterSecureStorage fakeStorage;
  late SecureStorageService storageService;

  setUp(() {
    fakeStorage = FakeFlutterSecureStorage();
    storageService = SecureStorageService(storage: fakeStorage);
  });

  group('SecureStorageService Tests', () {
    test('saveAccessToken and getAccessToken work correctly', () async {
      await storageService.saveAccessToken('test_access_token');
      final token = await storageService.getAccessToken();
      expect(token, equals('test_access_token'));
    });

    test('deleteAccessToken removes access token', () async {
      await storageService.saveAccessToken('test_access_token');
      await storageService.deleteAccessToken();
      final token = await storageService.getAccessToken();
      expect(token, isNull);
    });

    test('saveRefreshToken and getRefreshToken work correctly', () async {
      await storageService.saveRefreshToken('test_refresh_token');
      final token = await storageService.getRefreshToken();
      expect(token, equals('test_refresh_token'));
    });

    test('deleteRefreshToken removes refresh token', () async {
      await storageService.saveRefreshToken('test_refresh_token');
      await storageService.deleteRefreshToken();
      final token = await storageService.getRefreshToken();
      expect(token, isNull);
    });

    test('saveTokens saves both access and refresh tokens', () async {
      await storageService.saveTokens(
        accessToken: 'access_123',
        refreshToken: 'refresh_456',
      );

      expect(await storageService.getAccessToken(), equals('access_123'));
      expect(await storageService.getRefreshToken(), equals('refresh_456'));
    });

    test('clearAll removes both access and refresh tokens', () async {
      await storageService.saveTokens(
        accessToken: 'access_123',
        refreshToken: 'refresh_456',
      );

      await storageService.clearAll();

      expect(await storageService.getAccessToken(), isNull);
      expect(await storageService.getRefreshToken(), isNull);
    });
  });
}
