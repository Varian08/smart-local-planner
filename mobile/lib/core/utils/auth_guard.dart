import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

/// Centralized authentication guard utility.
///
/// Inspects the current [AuthBloc] state. If the user is authenticated ([AuthAuthenticated]),
/// [onAuthenticated] callback is executed immediately.
///
/// If unauthenticated, displays a floating [SnackBar] prompting the user to sign in
/// with a one-tap action routing directly to [LoginScreen].
void requireAuth(
  BuildContext context, {
  required VoidCallback onAuthenticated,
  String message = 'Please sign in to continue.',
}) {
  final authState = context.read<AuthBloc>().state;
  if (authState is AuthAuthenticated) {
    onAuthenticated();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Sign In',
          textColor: Colors.amber,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
