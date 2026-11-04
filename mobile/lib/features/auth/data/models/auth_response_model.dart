import 'package:equatable/equatable.dart';

/// User profile entity returned within authentication responses.
/// Strictly mapped to Backend com.smartplanner.dto.response.UserResponse.
class UserModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String role;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? 'ROLE_TRAVELER',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
    };
  }

  @override
  List<Object?> get props => [id, email, fullName, role];
}

/// Authentication Response carrying access/refresh tokens and user profile.
/// Strictly mapped to Backend com.smartplanner.dto.response.AuthResponse.
class AuthResponseModel extends Equatable {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int? expiresIn;
  final UserModel? user;

  const AuthResponseModel({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn,
    this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String?,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: json['expiresIn'] as int?,
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
      'tokenType': tokenType,
      if (expiresIn != null) 'expiresIn': expiresIn,
      if (user != null) 'user': user!.toJson(),
    };
  }

  @override
  List<Object?> get props => [
    accessToken,
    refreshToken,
    tokenType,
    expiresIn,
    user,
  ];
}

