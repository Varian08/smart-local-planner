import 'package:equatable/equatable.dart';

import '../data/models/auth_response_model.dart';

/// Base contract for all Authentication States emitted by AuthBloc.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial idle state before session verification.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Non-blocking loading state emitted during asynchronous authentication requests.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Emitted when the user is successfully authenticated and holds an active session.
class AuthAuthenticated extends AuthState {
  final UserModel? user;

  const AuthAuthenticated({this.user});

  @override
  List<Object?> get props => [user];
}

/// Emitted when no active authentication session exists or user logs out.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Emitted when an authentication operation fails with a descriptive error message.
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

