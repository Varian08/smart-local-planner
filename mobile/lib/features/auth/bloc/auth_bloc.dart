import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/auth_request_model.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Business Logic Component managing user authentication lifecycle and state transitions.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository})
      : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  // ---------------------------------------------------------------------------
  // 1. Session Verification on Startup
  // ---------------------------------------------------------------------------
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isAuth = await authRepository.isAuthenticated();
      if (isAuth) {
        emit(const AuthAuthenticated());
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  // ---------------------------------------------------------------------------
  // 2. User Login Flow
  // ---------------------------------------------------------------------------
  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await authRepository.login(
        LoginRequestModel(
          email: event.email,
          password: event.password,
        ),
      );
      emit(AuthAuthenticated(user: response.user));
    } on DioException catch (e) {
      emit(AuthFailure(message: _extractErrorMessage(e)));
    } catch (_) {
      emit(const AuthFailure(
        message: 'An unexpected error occurred. Please try again.',
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // 3. User Registration Flow
  // ---------------------------------------------------------------------------
  Future<void> _onRegisterSubmitted(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await authRepository.register(
        RegisterRequestModel(
          email: event.email,
          password: event.password,
          fullName: event.fullName,
        ),
      );
      emit(AuthAuthenticated(user: response.user));
    } on DioException catch (e) {
      emit(AuthFailure(message: _extractErrorMessage(e)));
    } catch (_) {
      emit(const AuthFailure(
        message: 'An unexpected error occurred. Please try again.',
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // 4. User Logout Flow
  // ---------------------------------------------------------------------------
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await authRepository.logout();
    } finally {
      emit(const AuthUnauthenticated());
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: Extract RFC 7807 / Spring Boot Error Messages
  // ---------------------------------------------------------------------------
  String _extractErrorMessage(DioException exception) {
    final response = exception.response;
    if (response != null && response.data != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['detail'] is String && (data['detail'] as String).isNotEmpty) {
          return data['detail'] as String;
        }
        if (data['message'] is String && (data['message'] as String).isNotEmpty) {
          return data['message'] as String;
        }
        if (data['title'] is String && (data['title'] as String).isNotEmpty) {
          return data['title'] as String;
        }
      }
    }

    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. Please check your internet connection.';
    }

    if (exception.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server. Please verify the Backend is running.';
    }

    return 'Authentication failed. Please verify your credentials and try again.';
  }
}
