import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/features/auth/data/models/auth_request_model.dart';
import 'package:smart_local_planner/features/auth/data/models/auth_response_model.dart';

void main() {
  group('AuthRequestModel Tests', () {
    test('LoginRequestModel serializes correctly to JSON', () {
      const model = LoginRequestModel(
        email: '  user@example.com  ',
        password: 'password123',
      );

      final json = model.toJson();

      expect(json['email'], 'user@example.com');
      expect(json['password'], 'password123');
      expect(model.props, ['  user@example.com  ', 'password123']);
    });

    test('RegisterRequestModel serializes correctly to JSON', () {
      const model = RegisterRequestModel(
        email: '  newuser@example.com  ',
        password: 'securePassword!',
        fullName: '  Jane Doe  ',
      );

      final json = model.toJson();

      expect(json['email'], 'newuser@example.com');
      expect(json['password'], 'securePassword!');
      expect(json['fullName'], 'Jane Doe');
      expect(model.props, ['  newuser@example.com  ', 'securePassword!', '  Jane Doe  ']);
    });
  });

  group('AuthResponseModel & UserModel Tests', () {
    test('UserModel deserializes and serializes correctly', () {
      final json = {
        'id': 'usr-123',
        'email': 'traveler@test.com',
        'fullName': 'Traveler One',
        'role': 'ROLE_TRAVELER',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'usr-123');
      expect(user.email, 'traveler@test.com');
      expect(user.fullName, 'Traveler One');
      expect(user.role, 'ROLE_TRAVELER');
      expect(user.toJson(), json);
      expect(user.props, ['usr-123', 'traveler@test.com', 'Traveler One', 'ROLE_TRAVELER']);
    });

    test('AuthResponseModel deserializes complete JSON with user', () {
      final json = {
        'accessToken': 'jwt.access.token',
        'refreshToken': 'jwt.refresh.token',
        'tokenType': 'Bearer',
        'expiresIn': 1800000,
        'user': {
          'id': 'usr-123',
          'email': 'traveler@test.com',
          'fullName': 'Traveler One',
          'role': 'ROLE_TRAVELER',
        },
      };

      final authResponse = AuthResponseModel.fromJson(json);

      expect(authResponse.accessToken, 'jwt.access.token');
      expect(authResponse.refreshToken, 'jwt.refresh.token');
      expect(authResponse.tokenType, 'Bearer');
      expect(authResponse.expiresIn, 1800000);
      expect(authResponse.user?.fullName, 'Traveler One');
      expect(authResponse.toJson(), json);
    });

    test('AuthResponseModel handles missing nullable fields gracefully', () {
      final json = {
        'accessToken': 'jwt.access.token',
      };

      final authResponse = AuthResponseModel.fromJson(json);

      expect(authResponse.accessToken, 'jwt.access.token');
      expect(authResponse.refreshToken, isNull);
      expect(authResponse.tokenType, 'Bearer');
      expect(authResponse.expiresIn, isNull);
      expect(authResponse.user, isNull);
      expect(authResponse.toJson(), {
        'accessToken': 'jwt.access.token',
        'tokenType': 'Bearer',
      });
    });
  });
}

