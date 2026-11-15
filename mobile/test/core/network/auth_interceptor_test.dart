import 'dart:convert';
import 'dart:typed_data';

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

class StubHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  StubHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler(options);

  @override
  void close({bool force = false}) {}
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

    test('onError on 401 refreshes tokens via refreshDio (200 OK) and retries original request', () async {
      await storageService.saveTokens(
        accessToken: 'expired_access_123',
        refreshToken: 'valid_refresh_123',
      );

      dynamic capturedRefreshBody;
      final stubRefreshDio = Dio();
      stubRefreshDio.httpClientAdapter = StubHttpClientAdapter((options) async {
        capturedRefreshBody = options.data;
        return ResponseBody.fromString(
          jsonEncode({
            'accessToken': 'rotated_access_456',
            'refreshToken': 'rotated_refresh_789',
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      String? retriedAuthHeader;
      final retryDio = Dio();
      retryDio.httpClientAdapter = StubHttpClientAdapter((options) async {
        retriedAuthHeader = options.headers['Authorization'] as String?;
        return ResponseBody.fromString(
          jsonEncode({'items': []}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      var sessionExpiredCalled = false;
      final refreshableInterceptor = AuthInterceptor(
        storageService: storageService,
        dio: retryDio,
        refreshDio: stubRefreshDio,
        onSessionExpired: () {
          sessionExpiredCalled = true;
        },
      );

      final requestOptions = RequestOptions(path: '/places');
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );
      final handler = TestErrorHandler();

      await refreshableInterceptor.onError(error, handler);

      expect(capturedRefreshBody, equals({'refreshToken': 'valid_refresh_123'}));
      expect(retriedAuthHeader, equals('Bearer rotated_access_456'));
      expect(handler.resolvedResponse?.statusCode, equals(200));
      expect(handler.nextError, isNull);
      expect(await storageService.getAccessToken(), equals('rotated_access_456'));
      expect(await storageService.getRefreshToken(), equals('rotated_refresh_789'));
      expect(sessionExpiredCalled, isFalse);
    });

    test('onError on 401 clears storage and invokes onSessionExpired when refreshDio returns 401', () async {
      await storageService.saveTokens(
        accessToken: 'expired_access',
        refreshToken: 'revoked_refresh',
      );

      final failingRefreshDio = Dio();
      failingRefreshDio.httpClientAdapter = StubHttpClientAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({'detail': 'Refresh token expired or revoked'}),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      var sessionExpiredCalled = false;
      final interceptorWithFailingRefresh = AuthInterceptor(
        storageService: storageService,
        dio: dio,
        refreshDio: failingRefreshDio,
        onSessionExpired: () {
          sessionExpiredCalled = true;
        },
      );

      final requestOptions = RequestOptions(path: '/favorites');
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );
      final handler = TestErrorHandler();

      await interceptorWithFailingRefresh.onError(error, handler);

      expect(handler.resolvedResponse, isNull);
      expect(handler.nextError, equals(error));
      expect(await storageService.getAccessToken(), isNull);
      expect(await storageService.getRefreshToken(), isNull);
      expect(sessionExpiredCalled, isTrue);
    });
  });
}
