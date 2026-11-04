import 'package:equatable/equatable.dart';

/// Request DTO for authenticating an existing user with credentials.
/// Strictly mapped to Backend com.smartplanner.dto.request.LoginRequest.
class LoginRequestModel extends Equatable {
  final String email;
  final String password;

  const LoginRequestModel({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim(),
      'password': password,
    };
  }

  @override
  List<Object?> get props => [email, password];
}

/// Request DTO for creating a new user account.
/// Strictly mapped to Backend com.smartplanner.dto.request.RegisterRequest.
class RegisterRequestModel extends Equatable {
  final String email;
  final String password;
  final String fullName;

  const RegisterRequestModel({
    required this.email,
    required this.password,
    required this.fullName,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim(),
      'password': password,
      'fullName': fullName.trim(),
    };
  }

  @override
  List<Object?> get props => [email, password, fullName];
}

