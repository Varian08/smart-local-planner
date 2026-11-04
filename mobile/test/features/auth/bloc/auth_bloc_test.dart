import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/features/auth/bloc/auth_bloc.dart';
import 'package:smart_local_planner/features/auth/bloc/auth_event.dart';
import 'package:smart_local_planner/features/auth/bloc/auth_state.dart';
import 'package:smart_local_planner/features/auth/data/models/auth_request_model.dart';
import 'package:smart_local_planner/features/auth/data/models/auth_response_model.dart';
import 'package:smart_local_planner/features/auth/data/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  bool authenticated = false;
  AuthResponseModel? loginResult;
  AuthResponseModel? registerResult;
  Object? shouldThrow;
  bool logoutCalled = false;

  @override
  Future<bool> isAuthenticated() async {
    if (shouldThrow != null) throw shouldThrow!;
    return authenticated;
  }

  @override
  Future<String?> getAccessToken() async {
    return authenticated ? 'fake_access_token' : null;
  }

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async {
    if (shouldThrow != null) throw shouldThrow!;
    return loginResult ??
        const AuthResponseModel(
          accessToken: 'login_jwt',
          user: UserModel(
            id: 'u1',
            email: 'u1@test.com',
            fullName: 'User One',
            role: 'ROLE_TRAVELER',
          ),
        );
  }

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    if (shouldThrow != null) throw shouldThrow!;
    return registerResult ??
        const AuthResponseModel(
          accessToken: 'reg_jwt',
          user: UserModel(
            id: 'u2',
            email: 'u2@test.com',
            fullName: 'User Two',
            role: 'ROLE_TRAVELER',
          ),
        );
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    if (shouldThrow != null) throw shouldThrow!;
  }
}

void main() {
  late MockAuthRepository mockRepository;
  late AuthBloc authBloc;

  setUp(() {
    mockRepository = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc - CheckRequested', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, const AuthInitial());
    });

    test('emits AuthAuthenticated when session exists', () async {
      mockRepository.authenticated = true;

      final expectedStates = [
        const AuthAuthenticated(),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const AuthCheckRequested());
    });

    test('emits AuthUnauthenticated when no session exists', () async {
      mockRepository.authenticated = false;

      final expectedStates = [
        const AuthUnauthenticated(),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const AuthCheckRequested());
    });
  });

  group('AuthBloc - LoginSubmitted', () {
    test('emits [AuthLoading, AuthAuthenticated] on success', () async {
      const user = UserModel(
        id: 'u1',
        email: 'u1@test.com',
        fullName: 'User One',
        role: 'ROLE_TRAVELER',
      );
      mockRepository.loginResult = const AuthResponseModel(
        accessToken: 'valid_token',
        user: user,
      );

      final expectedStates = [
        const AuthLoading(),
        const AuthAuthenticated(user: user),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(
        const AuthLoginSubmitted(email: 'u1@test.com', password: 'password123'),
      );
    });

    test('emits [AuthLoading, AuthFailure] when credentials invalid', () async {
      mockRepository.shouldThrow = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
          data: {'detail': 'Invalid email or password.'},
        ),
      );

      final expectedStates = [
        const AuthLoading(),
        const AuthFailure(message: 'Invalid email or password.'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(
        const AuthLoginSubmitted(email: 'wrong@test.com', password: 'wrong'),
      );
    });
  });

  group('AuthBloc - RegisterSubmitted', () {
    test('emits [AuthLoading, AuthAuthenticated] on register success', () async {
      const user = UserModel(
        id: 'u2',
        email: 'u2@test.com',
        fullName: 'User Two',
        role: 'ROLE_TRAVELER',
      );
      mockRepository.registerResult = const AuthResponseModel(
        accessToken: 'reg_token',
        user: user,
      );

      final expectedStates = [
        const AuthLoading(),
        const AuthAuthenticated(user: user),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(
        const AuthRegisterSubmitted(
          fullName: 'User Two',
          email: 'u2@test.com',
          password: 'password123',
        ),
      );
    });

    test('emits [AuthLoading, AuthFailure] when email already registered', () async {
      mockRepository.shouldThrow = DioException(
        requestOptions: RequestOptions(path: '/auth/register'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/register'),
          statusCode: 409,
          data: {'message': 'User with this email already exists.'},
        ),
      );

      final expectedStates = [
        const AuthLoading(),
        const AuthFailure(message: 'User with this email already exists.'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(
        const AuthRegisterSubmitted(
          fullName: 'User Two',
          email: 'dup@test.com',
          password: 'password123',
        ),
      );
    });
  });

  group('AuthBloc - LogoutRequested', () {
    test('emits [AuthLoading, AuthUnauthenticated] on logout', () async {
      final expectedStates = [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const AuthLogoutRequested());
      await Future.delayed(Duration.zero);
      expect(mockRepository.logoutCalled, isTrue);
    });
  });
}

