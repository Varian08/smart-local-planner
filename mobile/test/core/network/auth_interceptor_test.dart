import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/core/network/auth_interceptor.dart';
import 'package:smart_local_planner/core/storage/secure_storage_service.dart';

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> data = {};

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
      data[key] = value;
    } else {
      data.remove(key);
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
    return data[key];
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
    data.remove(key);
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
    data.clear();
  }
}

class TestRequestHandler extends RequestInterceptorHandler {
  RequestOptions? nextOptions;

  @override
  void next(RequestOptions requestOptions) {
    nextOptions = requestOptions;
  }
}

class TestErrorHandler extends ErrorInterceptorHandler {
  DioException? nextError;
  Response? resolvedResponse;

  @override
  void next(DioException err) {
    nextError = err;
  }

  @override
  void resolve(Response response) {
    resolvedResponse = response;
  }
}

void main() {
  late FakeFlutterSecureStorage fakeStorage;
  late SecureStorageService storageService;
  late Dio dio;
  late AuthInterceptor interceptor;

  setUp(() {
    fakeStorage = FakeFlutterSecureStorage();
    storageService = SecureStorageService(storage: fakeStorage);
    dio = Dio();
    interceptor = AuthInterceptor(
      storageService: storageService,
      dio: dio,
    );
  });

  group('AuthInterceptor Tests', () {
    test('onRequest attaches Bearer token when accessToken exists for protected route', () async {
      await storageService.saveAccessToken('jwt_valid_token_123');

      final options = RequestOptions(path: '/places');
      final handler = TestRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(handler.nextOptions, isNotNull);
      expect(
        handler.nextOptions!.headers['Authorization'],
        equals('Bearer jwt_valid_token_123'),
      );
    });

    test('onRequest does NOT attach Bearer token for /auth/login, /auth/register, /auth/refresh-token', () async {
      await storageService.saveAccessToken('jwt_valid_token_123');

      final loginOptions = RequestOptions(path: '/auth/login');
      final registerOptions = RequestOptions(path: '/auth/register');
      final refreshOptions = RequestOptions(path: '/auth/refresh-token');

      final loginHandler = TestRequestHandler();
      final registerHandler = TestRequestHandler();
      final refreshHandler = TestRequestHandler();

      await interceptor.onRequest(loginOptions, loginHandler);
      await interceptor.onRequest(registerOptions, registerHandler);
      await interceptor.onRequest(refreshOptions, refreshHandler);

      expect(loginHandler.nextOptions!.headers['Authorization'], isNull);
      expect(registerHandler.nextOptions!.headers['Authorization'], isNull);
      expect(refreshHandler.nextOptions!.headers['Authorization'], isNull);
    });

    test('onError passes through non-401 error without clearing storage', () async {
      await storageService.saveTokens(
        accessToken: 'access_123',
        refreshToken: 'refresh_456',
      );

      final error = DioException(
        requestOptions: RequestOptions(path: '/places'),
        response: Response(
          requestOptions: RequestOptions(path: '/places'),
          statusCode: 500,
        ),
      );
      final handler = TestErrorHandler();

      await interceptor.onError(error, handler);

      expect(handler.nextError, equals(error));
      expect(await storageService.getAccessToken(), equals('access_123'));
    });

    test('onError on 401 when refreshToken is null clears storage, invokes onSessionExpired, and passes error', () async {
      var sessionExpiredCalled = false;
      final sessionAwareInterceptor = AuthInterceptor(
        storageService: storageService,
        dio: dio,
        onSessionExpired: () {
          sessionExpiredCalled = true;
        },
      );
      await storageService.saveAccessToken('access_without_refresh');

      final error = DioException(
        requestOptions: RequestOptions(path: '/places'),
        response: Response(
          requestOptions: RequestOptions(path: '/places'),
          statusCode: 401,
        ),
      );
      final handler = TestErrorHandler();

      await sessionAwareInterceptor.onError(error, handler);

      expect(handler.nextError, equals(error));
      expect(await storageService.getAccessToken(), isNull);
      expect(sessionExpiredCalled, isTrue);
    });

    test('onError on 401 for /auth/refresh-token itself does not retry to prevent infinite loop', () async {
      await storageService.saveRefreshToken('refresh_expired');

      final error = DioException(
        requestOptions: RequestOptions(path: '/auth/refresh-token'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/refresh-token'),
          statusCode: 401,
        ),
      );
      final handler = TestErrorHandler();

      await interceptor.onError(error, handler);

      expect(handler.nextError, equals(error));
    });
  });
}
