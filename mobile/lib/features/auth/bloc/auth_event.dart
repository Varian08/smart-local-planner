import 'package:equatable/equatable.dart';

/// Base contract for all Authentication Events dispatched to AuthBloc.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched upon application launch to verify if a valid session token exists in Secure Storage.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Dispatched when the user submits the login form with credentials.
class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginSubmitted({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Dispatched when the user submits the registration form to create a new account.
class AuthRegisterSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String fullName;

  const AuthRegisterSubmitted({
    required this.email,
    required this.password,
    required this.fullName,
  });

  @override
  List<Object?> get props => [email, password, fullName];
}

/// Dispatched when the user logs out of their active session.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

