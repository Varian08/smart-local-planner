import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/features/auth/bloc/auth_bloc.dart';
import 'package:smart_local_planner/features/auth/data/models/auth_request_model.dart';
import 'package:smart_local_planner/features/auth/data/models/auth_response_model.dart';
import 'package:smart_local_planner/features/auth/data/repositories/auth_repository.dart';
import 'package:smart_local_planner/features/favorites/bloc/favorite_bloc.dart';
import 'package:smart_local_planner/features/favorites/bloc/favorite_event.dart';
import 'package:smart_local_planner/features/favorites/data/repositories/favorite_repository.dart';
import 'package:smart_local_planner/features/favorites/presentation/screens/favorite_list_screen.dart';
import 'package:smart_local_planner/features/places/data/models/place_model.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async =>
      throw UnimplementedError();

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<String?> getAccessToken() async => null;
}

class FakeFavoriteRepository implements FavoriteRepository {
  List<PlaceModel> placesToReturn = [];
  bool shouldThrow = false;
  int fetchCallCount = 0;

  @override
  Future<List<PlaceModel>> getFavorites() async {
    fetchCallCount++;
    if (shouldThrow) {
      throw Exception('Network error');
    }
    return placesToReturn;
  }

  @override
  Future<void> addFavorite(String placeId) async {}

  @override
  Future<void> removeFavorite(String placeId) async {}
}

PlaceModel _createDummyPlace(String id, String name) {
  return PlaceModel(
    id: id,
    name: name,
    category: 'ATTRACTION',
    address: 'Da Nang, Vietnam',
    averageRating: 4.8,
    totalReviews: 50,
  );
}

Widget _wrapWithProviders({
  required FavoriteBloc favoriteBloc,
  AuthBloc? authBloc,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<FavoriteBloc>.value(value: favoriteBloc),
      BlocProvider<AuthBloc>(
        create: (_) => authBloc ?? AuthBloc(authRepository: FakeAuthRepository()),
      ),
    ],
    child: const MaterialApp(
      home: FavoriteListScreen(),
    ),
  );
}

void main() {
  group('FavoriteListScreen 4-State UI Contract Tests', () {
    testWidgets('renders LoadingState skeleton while fetching', (
      WidgetTester tester,
    ) async {
      final repo = FakeFavoriteRepository();
      final bloc = FavoriteBloc(favoriteRepository: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrapWithProviders(favoriteBloc: bloc));

      // Initial state is FavoriteInitial -> renders loading skeleton
      expect(find.byKey(const Key('favorite_loading_skeleton')), findsOneWidget);
      expect(find.text('Saved Places'), findsOneWidget);
    });

    testWidgets('renders EmptyState when user has no bookmarked places', (
      WidgetTester tester,
    ) async {
      final repo = FakeFavoriteRepository()..placesToReturn = [];
      final bloc = FavoriteBloc(favoriteRepository: repo);
      addTearDown(bloc.close);

      bloc.add(const FavoriteFetchStarted());
      await tester.pumpWidget(_wrapWithProviders(favoriteBloc: bloc));
      await tester.pumpAndSettle();

      // Verify Empty State elements
      expect(find.text('No Saved Places Yet'), findsOneWidget);
      expect(
        find.text(
          'Tap the heart icon on any place card to bookmark your dream destinations for quick access.',
        ),
        findsOneWidget,
      );
      expect(find.text('Explore Places'), findsOneWidget);
    });

    testWidgets('renders SuccessState with PlaceCards when favorites exist', (
      WidgetTester tester,
    ) async {
      final p1 = _createDummyPlace('place-1', 'Bà Nà Hills');
      final p2 = _createDummyPlace('place-2', 'Cầu Rồng');
      final repo = FakeFavoriteRepository()..placesToReturn = [p1, p2];
      final bloc = FavoriteBloc(favoriteRepository: repo);
      addTearDown(bloc.close);

      bloc.add(const FavoriteFetchStarted());
      await tester.pumpWidget(_wrapWithProviders(favoriteBloc: bloc));
      await tester.pumpAndSettle();

      // Verify both place cards are rendered
      expect(find.text('Bà Nà Hills'), findsOneWidget);
      expect(find.text('Cầu Rồng'), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('renders ErrorState with Retry button on failure', (
      WidgetTester tester,
    ) async {
      final repo = FakeFavoriteRepository()..shouldThrow = true;
      final bloc = FavoriteBloc(favoriteRepository: repo);
      addTearDown(bloc.close);

      bloc.add(const FavoriteFetchStarted());
      await tester.pumpWidget(_wrapWithProviders(favoriteBloc: bloc));
      await tester.pumpAndSettle();

      // Verify Error State layout
      expect(find.text('Failed to Load Favorites'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Tap Retry button and verify fetch is retried
      repo.shouldThrow = false;
      repo.placesToReturn = [_createDummyPlace('p-1', 'Đà Nẵng')];

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.text('Đà Nẵng'), findsOneWidget);
    });
  });
}
