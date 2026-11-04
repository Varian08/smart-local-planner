import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/places/bloc/place_bloc.dart';
import 'features/places/bloc/place_event.dart';
import 'features/places/data/repositories/place_repository.dart';
import 'features/places/presentation/screens/place_list_screen.dart';

/// Application Entrypoint.
/// Configures Root MultiBlocProvider (AuthBloc + PlaceBloc), Material 3 Design Tokens, and initial Fetching.
void main() {
  runApp(const SmartLocalPlannerApp());
}

class SmartLocalPlannerApp extends StatelessWidget {
  final PlaceRepository? placeRepository;
  final AuthRepository? authRepository;

  const SmartLocalPlannerApp({
    super.key,
    this.placeRepository,
    this.authRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: authRepository ?? AuthRepositoryImpl(),
          )..add(const AuthCheckRequested()),
        ),
        BlocProvider<PlaceBloc>(
          create: (context) => PlaceBloc(
            placeRepository: placeRepository ?? PlaceRepositoryImpl(),
          )..add(const PlaceFetchStarted()),
        ),
      ],
      child: MaterialApp(
        title: 'Smart Local Planner',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          scaffoldBackgroundColor: Colors.grey.shade50,
        ),
        home: const PlaceListScreen(),
      ),
    );
  }
}
