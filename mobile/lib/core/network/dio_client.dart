import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

/// Enterprise HTTP Client wrapper based on Dio.
/// Enforces SLA timeouts, centralized headers, and developer logging.
class DioClient {
  late final Dio _dio;

  // ---------------------------------------------------------------------------
  // 1. Client Initialization & Interceptor Pipeline
  // ---------------------------------------------------------------------------
  DioClient({
    Dio? dio,
    SecureStorageService? storageService,
    void Function()? onSessionExpired,
  }) {
    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: ApiEndpoints.connectTimeout,
            receiveTimeout: ApiEndpoints.receiveTimeout,
            sendTimeout: ApiEndpoints.sendTimeout,
            headers: const {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            responseType: ResponseType.json,
          ),
        );

    final storage = storageService ?? SecureStorageService();
    _dio.interceptors.add(
      AuthInterceptor(
        storageService: storage,
        dio: _dio,
        onSessionExpired: onSessionExpired,
      ),
    );

    // Enable verbose logging interceptor only during active development (Debug mode)
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Underlying Instance Accessor
  // ---------------------------------------------------------------------------
  /// Exposes the underlying configured Dio instance for repositories
  Dio get instance => _dio;

  // ---------------------------------------------------------------------------
  // 3. Generic HTTP Methods with Clean Exception Handling
  // ---------------------------------------------------------------------------
  /// Performs an HTTP GET request with centralized error propagation
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Performs an HTTP POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Performs an HTTP DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
