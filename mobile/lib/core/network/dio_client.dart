import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';

/// Enterprise HTTP Client wrapper based on Dio.
/// Enforces SLA timeouts, centralized headers, and developer logging.
class DioClient {
  late final Dio _dio;

  // ---------------------------------------------------------------------------
  // 1. Client Initialization & Interceptor Pipeline
  // ---------------------------------------------------------------------------
  DioClient({Dio? dio}) {
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
}
