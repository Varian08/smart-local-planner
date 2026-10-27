import 'package:flutter/foundation.dart';

/// Enterprise-grade centralized API endpoint definitions and dynamic host resolution.
/// Enforces Twelve-Factor Configuration (Principle III) and multi-platform loopback resolution.
class ApiEndpoints {
  // Private constructor to prevent direct instantiation
  ApiEndpoints._();

  // ---------------------------------------------------------------------------
  // 1. Twelve-Factor Base URL Resolution
  // ---------------------------------------------------------------------------
  /// Reads from compile-time environment injection (--dart-define=API_BASE_URL=...)
  /// If not provided, dynamically resolves based on runtime platform matrix.
  static String get baseUrl {
    const injectedUrl = String.fromEnvironment('API_BASE_URL');
    if (injectedUrl.isNotEmpty) {
      return injectedUrl;
    }

    // Dynamic fallback for Local Development environments
    if (kIsWeb) {
      // Browser shares the host machine's network stack directly
      return 'http://localhost:8080/api/v1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android Emulator loopback alias to host machine
        return 'http://10.0.2.2:8080/api/v1';
      case TargetPlatform.iOS:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:8080/api/v1';
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Network SLA & Timeout Constraints
  // ---------------------------------------------------------------------------
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);

  // ---------------------------------------------------------------------------
  // 3. API Resource Routes (Strictly mapped to docs/API_SPECIFICATION.md)
  // ---------------------------------------------------------------------------
  // Places Discovery Domain
  static const String places = '/places';
  static String placeDetails(String id) => '/places/$id';

  // ---------------------------------------------------------------------------
  // 4. Standardized Query Parameters Contract
  // ---------------------------------------------------------------------------
  static const String paramQuery = 'query';
  static const String paramCategory = 'category';
  static const String paramPriceLevel = 'priceLevel';
  static const String paramPage = 'page';
  static const String paramSize = 'size';
  static const String paramSort = 'sort';
}
