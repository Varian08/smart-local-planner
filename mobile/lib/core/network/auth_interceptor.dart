import 'dart:async';
import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';

/// Enterprise HTTP Interceptor managing JWT token lifecycle, automatic Bearer injection,
/// and transparent 401 token rotation retry loops.
class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageService storageService;
  final Dio dio;

  AuthInterceptor({
    required this.storageService,
    required this.dio,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Avoid attaching Bearer token to public authentication endpoints
    final isAuthEndpoint = options.path.contains('/auth/login') ||
        options.path.contains('/auth/register') ||
        options.path.contains('/auth/refresh-token');

    if (!isAuthEndpoint) {
      final token = await storageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final requestOptions = err.requestOptions;

    // Check if error is 401 Unauthorized and not already from an auth refresh or login attempt
    final is401 = response?.statusCode == 401;
    final isRefreshEndpoint =
        requestOptions.path.contains('/auth/refresh-token');
    final isLoginEndpoint = requestOptions.path.contains('/auth/login');
    final isRegisterEndpoint = requestOptions.path.contains('/auth/register');

    if (is401 && !isRefreshEndpoint && !isLoginEndpoint && !isRegisterEndpoint) {
      final refreshToken = await storageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await storageService.clearAll();
        return handler.next(err);
      }

      try {
        // Perform token refresh using dedicated, non-intercepted request
        final refreshDio = Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: ApiEndpoints.connectTimeout,
            receiveTimeout: ApiEndpoints.receiveTimeout,
            sendTimeout: ApiEndpoints.sendTimeout,
            headers: const {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
          ),
        );

        final refreshResponse = await refreshDio.post(
          ApiEndpoints.refreshToken,
          data: {'refreshToken': refreshToken},
        );

        if (refreshResponse.statusCode == 200 &&
            refreshResponse.data != null) {
          final data = refreshResponse.data as Map<String, dynamic>;
          final newAccessToken = data['accessToken'] as String?;
          final newRefreshToken = data['refreshToken'] as String?;

          if (newAccessToken != null && newRefreshToken != null) {
            await storageService.saveTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
            );

            // Update original request options with new access token
            requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

            // Retry the original request
            final retryResponse = await dio.fetch(requestOptions);
            return handler.resolve(retryResponse);
          }
        }

        // If payload is invalid or missing tokens
        await storageService.clearAll();
        return handler.next(err);
      } catch (_) {
        // Refresh failed (e.g. refresh token expired or revoked)
        await storageService.clearAll();
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
