import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/auth_request_model.dart';
import '../models/auth_response_model.dart';

/// Contract definition for Authentication Data Operations.
/// Decouples UI & BLoC state management from networking and secure storage.
abstract class AuthRepository {
  /// Authenticates with email and password, persisting session tokens upon success.
  Future<AuthResponseModel> login(LoginRequestModel request);

  /// Registers a new user account and persists the generated session tokens.
  Future<AuthResponseModel> register(RegisterRequestModel request);

  /// Revokes active session on Backend and purges stored credentials from Keystore/Keychain.
  Future<void> logout();

  /// Inspects local secure storage for existing active access token.
  Future<bool> isAuthenticated();

  /// Returns current access token from secure storage.
  Future<String?> getAccessToken();

  /// Restores cached basic user profile metadata from secure storage, if present.
  Future<UserModel?> getCachedUser();
}

/// Concrete implementation of AuthRepository.
class AuthRepositoryImpl implements AuthRepository {
  final DioClient _dioClient;
  final SecureStorageService _storageService;

  AuthRepositoryImpl({
    DioClient? dioClient,
    SecureStorageService? storageService,
  })  : _dioClient = dioClient ?? DioClient(),
        _storageService = storageService ?? SecureStorageService();

  Future<void> _persistSession(AuthResponseModel authResponse) async {
    await _storageService.saveAccessToken(authResponse.accessToken);
    if (authResponse.refreshToken != null) {
      await _storageService.saveRefreshToken(authResponse.refreshToken!);
    }
    if (authResponse.user != null) {
      await _storageService.saveUserProfileJson(
        jsonEncode(authResponse.user!.toJson()),
      );
    }
  }

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      final authResponse = AuthResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );

      await _persistSession(authResponse);

      return authResponse;
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.register,
        data: request.toJson(),
      );

      final authResponse = AuthResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );

      await _persistSession(authResponse);

      return authResponse;
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _dioClient.post(
          ApiEndpoints.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Defensive fallback: local storage must be purged even if remote logout fails
    } finally {
      await _storageService.clearAll();
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _storageService.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> getAccessToken() async {
    return _storageService.getAccessToken();
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final rawJson = await _storageService.getUserProfileJson();
    if (rawJson == null || rawJson.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        return UserModel.fromJson(decoded);
      }
    } catch (_) {
      // Ignore corrupted cached metadata cleanly instead of failing session check
    }
    return null;
  }
}
