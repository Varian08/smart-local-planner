import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/dio_client.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/favorites/bloc/favorite_bloc.dart';
import 'features/favorites/data/repositories/favorite_repository.dart';
import 'features/itineraries/bloc/itinerary_bloc.dart';
import 'features/itineraries/data/repositories/itinerary_repository.dart';
import 'features/places/bloc/place_bloc.dart';
import 'features/places/bloc/place_event.dart';
import 'features/places/data/repositories/place_repository.dart';
import 'features/places/presentation/screens/place_list_screen.dart';
import 'features/reviews/data/repositories/review_repository.dart';

/// Application Entrypoint.
/// Configures Root MultiBlocProvider (AuthBloc + PlaceBloc + FavoriteBloc), Material 3 Design Tokens, and initial Fetching.
void main() {
  runApp(const SmartLocalPlannerApp());
}

class SmartLocalPlannerApp extends StatefulWidget {
  final PlaceRepository? placeRepository;
  final AuthRepository? authRepository;
  final FavoriteRepository? favoriteRepository;
  final ItineraryRepository? itineraryRepository;
  final ReviewRepository? reviewRepository;
  final DioClient? dioClient;

  const SmartLocalPlannerApp({
    super.key,
    this.placeRepository,
    this.authRepository,
    this.favoriteRepository,
    this.itineraryRepository,
    this.reviewRepository,
    this.dioClient,
  });

  @override
  State<SmartLocalPlannerApp> createState() => _SmartLocalPlannerAppState();
}

class _SmartLocalPlannerAppState extends State<SmartLocalPlannerApp> {
  late final DioClient _dioClient;
  late final AuthRepository _authRepository;
  late final PlaceRepository _placeRepository;
  late final FavoriteRepository _favoriteRepository;
  late final ItineraryRepository _itineraryRepository;
  late final ReviewRepository _reviewRepository;
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _dioClient = widget.dioClient ??
        DioClient(
          onSessionExpired: () {
            _authBloc.add(const AuthSessionExpired());
          },
        );
    _authRepository =
        widget.authRepository ?? AuthRepositoryImpl(dioClient: _dioClient);
    _placeRepository =
        widget.placeRepository ?? PlaceRepositoryImpl(dioClient: _dioClient);
    _favoriteRepository = widget.favoriteRepository ??
        FavoriteRepositoryImpl(dioClient: _dioClient);
    _itineraryRepository = widget.itineraryRepository ??
        ItineraryRepositoryImpl(dioClient: _dioClient);
    _reviewRepository = widget.reviewRepository ??
        ReviewRepositoryImpl(dioClient: _dioClient);
    _authBloc = AuthBloc(authRepository: _authRepository)
      ..add(const AuthCheckRequested());
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ReviewRepository>.value(value: _reviewRepository),
        RepositoryProvider<ItineraryRepository>.value(value: _itineraryRepository),
        RepositoryProvider<PlaceRepository>.value(value: _placeRepository),
        RepositoryProvider<FavoriteRepository>.value(value: _favoriteRepository),
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: _authBloc),
          BlocProvider<PlaceBloc>(
            create: (context) => PlaceBloc(
              placeRepository: _placeRepository,
            )..add(const PlaceFetchStarted()),
          ),
          BlocProvider<FavoriteBloc>(
            create: (context) => FavoriteBloc(
              favoriteRepository: _favoriteRepository,
            ),
          ),
          BlocProvider<ItineraryBloc>(
            create: (context) => ItineraryBloc(
              itineraryRepository: _itineraryRepository,
            ),
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
      ),
    );
  }
}
