import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/core/utils/auth_guard.dart';
import 'package:smart_local_planner/features/auth/bloc/auth_bloc.dart';
import 'package:smart_local_planner/features/auth/bloc/auth_state.dart';
import 'package:smart_local_planner/features/auth/data/models/auth_request_model.dart';
import 'package:smart_local_planner/features/auth/data/models/auth_response_model.dart';
import 'package:smart_local_planner/features/auth/data/repositories/auth_repository.dart';
import 'package:smart_local_planner/features/auth/presentation/screens/login_screen.dart';

class FakeAuthRepository implements AuthRepository {
  final bool authenticated;
  FakeAuthRepository({this.authenticated = false});

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async =>
      throw UnimplementedError();

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isAuthenticated() async => authenticated;

  @override
  Future<String?> getAccessToken() async =>
      authenticated ? 'fake_token' : null;
}

Widget _buildTestApp({
  required AuthBloc authBloc,
  required VoidCallback onAuthenticated,
  String message = 'Test auth message',
}) {
  return BlocProvider<AuthBloc>.value(
    value: authBloc,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                requireAuth(
                  context,
                  onAuthenticated: onAuthenticated,
                  message: message,
                );
              },
              child: const Text('Trigger Action'),
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  group('AuthGuard requireAuth Tests', () {
    testWidgets('executes onAuthenticated directly when user is AuthAuthenticated', (
      WidgetTester tester,
    ) async {
      var callbackExecuted = false;
      final authBloc = AuthBloc(
        authRepository: FakeAuthRepository(authenticated: true),
      );
      addTearDown(authBloc.close);

      // Force authenticated state
      authBloc.emit(const AuthAuthenticated(
        user: UserModel(
          id: 'u-1',
          email: 'test@example.com',
          fullName: 'Test User',
          role: 'ROLE_USER',
        ),
      ));

      await tester.pumpWidget(
        _buildTestApp(
          authBloc: authBloc,
          onAuthenticated: () {
            callbackExecuted = true;
          },
        ),
      );

      await tester.tap(find.text('Trigger Action'));
      await tester.pump();

      expect(callbackExecuted, isTrue);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('shows floating SnackBar and skips callback when user is unauthenticated', (
      WidgetTester tester,
    ) async {
      var callbackExecuted = false;
      final authBloc = AuthBloc(
        authRepository: FakeAuthRepository(authenticated: false),
      );
      addTearDown(authBloc.close);

      authBloc.emit(const AuthUnauthenticated());

      await tester.pumpWidget(
        _buildTestApp(
          authBloc: authBloc,
          message: 'Sign in to access feature.',
          onAuthenticated: () {
            callbackExecuted = true;
          },
        ),
      );

      await tester.tap(find.text('Trigger Action'));
      await tester.pumpAndSettle();

      expect(callbackExecuted, isFalse);
      expect(find.text('Sign in to access feature.'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // Tap Sign In action
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
