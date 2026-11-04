import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/core/network/dio_client.dart';
import 'package:smart_local_planner/core/storage/secure_storage_service.dart';
import 'package:smart_local_planner/features/auth/data/models/auth_request_model.dart';
import 'package:smart_local_planner/features/auth/data/repositories/auth_repository.dart';

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

class FakeDioClient extends Fake implements DioClient {
  Response<dynamic>? mockResponse;
  DioException? mockError;
  String? lastPath;
  dynamic lastData;

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastData = data;
    if (mockError != null) {
      throw mockError!;
    }
    return mockResponse as Response<T>;
  }
}

void main() {
  late FakeFlutterSecureStorage fakeStorage;
  late SecureStorageService storageService;
  late FakeDioClient fakeDioClient;
  late AuthRepository repository;

  setUp(() {
    fakeStorage = FakeFlutterSecureStorage();
    storageService = SecureStorageService(storage: fakeStorage);
    fakeDioClient = FakeDioClient();
    repository = AuthRepositoryImpl(
      dioClient: fakeDioClient,
      storageService: storageService,
    );
  });

  group('AuthRepository Tests', () {
    test('login succeeds and persists tokens', () async {
      fakeDioClient.mockResponse = Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        statusCode: 200,
        data: {
          'accessToken': 'access_token_123',
          'refreshToken': 'refresh_token_456',
          'tokenType': 'Bearer',
          'user': {
            'id': 'usr-1',
            'email': 'user@test.com',
            'fullName': 'Test User',
            'role': 'ROLE_TRAVELER',
          },
        },
      );

      final result = await repository.login(
        const LoginRequestModel(email: 'user@test.com', password: 'password'),
      );

      expect(result.accessToken, 'access_token_123');
      expect(result.refreshToken, 'refresh_token_456');
      expect(result.user?.fullName, 'Test User');
      expect(await storageService.getAccessToken(), 'access_token_123');
      expect(await storageService.getRefreshToken(), 'refresh_token_456');
      expect(await repository.isAuthenticated(), isTrue);
    });

    test('register succeeds and persists tokens', () async {
      fakeDioClient.mockResponse = Response(
        requestOptions: RequestOptions(path: '/auth/register'),
        statusCode: 201,
        data: {
          'accessToken': 'reg_access_123',
          'refreshToken': 'reg_refresh_456',
          'tokenType': 'Bearer',
          'user': {
            'id': 'usr-2',
            'email': 'newuser@test.com',
            'fullName': 'New User',
            'role': 'ROLE_TRAVELER',
          },
        },
      );

      final result = await repository.register(
        const RegisterRequestModel(
          email: 'newuser@test.com',
          password: 'password123',
          fullName: 'New User',
        ),
      );

      expect(result.accessToken, 'reg_access_123');
      expect(await storageService.getAccessToken(), 'reg_access_123');
      expect(await storageService.getRefreshToken(), 'reg_refresh_456');
    });

    test('logout purges stored tokens cleanly', () async {
      await storageService.saveTokens(
        accessToken: 'access_abc',
        refreshToken: 'refresh_xyz',
      );

      fakeDioClient.mockResponse = Response(
        requestOptions: RequestOptions(path: '/auth/logout'),
        statusCode: 200,
        data: {'message': 'Logged out'},
      );

      await repository.logout();

      expect(await storageService.getAccessToken(), isNull);
      expect(await storageService.getRefreshToken(), isNull);
      expect(await repository.isAuthenticated(), isFalse);
    });

    test('logout purges tokens even if backend API fails', () async {
      await storageService.saveTokens(
        accessToken: 'access_abc',
        refreshToken: 'refresh_xyz',
      );

      fakeDioClient.mockError = DioException(
        requestOptions: RequestOptions(path: '/auth/logout'),
        type: DioExceptionType.connectionError,
      );

      await repository.logout();

      expect(await storageService.getAccessToken(), isNull);
      expect(await storageService.getRefreshToken(), isNull);
    });

    test('isAuthenticated returns false when no access token stored', () async {
      expect(await repository.isAuthenticated(), isFalse);
    });
  });
}

