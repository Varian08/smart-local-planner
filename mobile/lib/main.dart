import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/places/bloc/place_bloc.dart';
import 'features/places/bloc/place_event.dart';
import 'features/places/data/repositories/place_repository.dart';
import 'features/places/presentation/screens/place_list_screen.dart';

/// Application Entrypoint.
/// Configures Root BlocProvider, Material 3 Design Tokens, and initial Place Fetching.
void main() {
  runApp(const SmartLocalPlannerApp());
}

class SmartLocalPlannerApp extends StatelessWidget {
  final PlaceRepository? placeRepository;

  const SmartLocalPlannerApp({super.key, this.placeRepository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Initialize PlaceBloc and trigger initial fetch event to populate places on startup
      create: (context) =>
          PlaceBloc(placeRepository: placeRepository ?? PlaceRepositoryImpl())
            ..add(const PlaceFetchStarted()),
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
