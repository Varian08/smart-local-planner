import 'package:flutter_test/flutter_test.dart';

import 'package:smart_local_planner/features/auth/data/models/auth_request_model.dart';
import 'package:smart_local_planner/features/auth/data/models/auth_response_model.dart';
import 'package:smart_local_planner/features/auth/data/repositories/auth_repository.dart';
import 'package:smart_local_planner/features/favorites/data/repositories/favorite_repository.dart';
import 'package:smart_local_planner/features/itineraries/data/models/itinerary_model.dart';
import 'package:smart_local_planner/features/itineraries/data/models/itinerary_request_model.dart';
import 'package:smart_local_planner/features/itineraries/data/repositories/itinerary_repository.dart';
import 'package:smart_local_planner/features/places/data/models/place_model.dart';
import 'package:smart_local_planner/features/places/data/repositories/place_repository.dart';
import 'package:smart_local_planner/main.dart';

/// Test double simulating PlaceRepository without triggering network calls or pending timers.
class FakePlaceRepository implements PlaceRepository {
  const FakePlaceRepository();

  @override
  Future<List<PlaceModel>> getPlaces({
    String? query,
    String? category,
    int? priceLevel,
    int page = 0,
    int size = 10,
    String sort = 'averageRating,desc',
  }) async {
    return const [];
  }

  @override
  Future<PlaceModel> getPlaceById(String id) async {
    throw UnimplementedError('Not needed for widget smoke test');
  }
}

class FakePlaceRepositoryWithData implements PlaceRepository {
  final List<PlaceModel> places;
  const FakePlaceRepositoryWithData({required this.places});

  @override
  Future<List<PlaceModel>> getPlaces({
    String? query,
    String? category,
    int? priceLevel,
    int page = 0,
    int size = 10,
    String sort = 'averageRating,desc',
  }) async {
    return places;
  }

  @override
  Future<PlaceModel> getPlaceById(String id) async {
    return places.firstWhere((p) => p.id == id);
  }
}

/// Test double simulating AuthRepository in unauthenticated state for widget tests.
class FakeAuthRepository implements AuthRepository {
  const FakeAuthRepository();

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<String?> getAccessToken() async => null;
}

/// Test double simulating FavoriteRepository in empty state for widget tests.
class FakeFavoriteRepository implements FavoriteRepository {
  const FakeFavoriteRepository();

  @override
  Future<List<PlaceModel>> getFavorites() async => const [];

  @override
  Future<void> addFavorite(String placeId) async {}

  @override
  Future<void> removeFavorite(String placeId) async {}
}

/// Test double simulating ItineraryRepository for widget smoke tests.
class FakeItineraryRepository implements ItineraryRepository {
  const FakeItineraryRepository();

  @override
  Future<List<ItineraryModel>> getItineraries({
    int page = 0,
    int size = 10,
    String sort = 'createdAt,desc',
  }) async => const [];

  @override
  Future<ItineraryModel> getItineraryDetail(String id) async =>
      throw UnimplementedError();

  @override
  Future<ItineraryModel> createItinerary(ItineraryRequestModel request) async =>
      throw UnimplementedError();

  @override
  Future<ItineraryModel> updateItinerary(
    String id,
    ItineraryRequestModel request,
  ) async => throw UnimplementedError();

  @override
  Future<void> deleteItinerary(String id) async {}
}

void main() {
  testWidgets('App smoke test initializes successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const SmartLocalPlannerApp(
        placeRepository: FakePlaceRepository(),
        authRepository: FakeAuthRepository(),
        favoriteRepository: FakeFavoriteRepository(),
        itineraryRepository: FakeItineraryRepository(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify root app widget is mounted
    expect(find.byType(SmartLocalPlannerApp), findsOneWidget);
  });

  testWidgets('PlaceCard renders placeholder banner when imageUrl is null', (
    WidgetTester tester,
  ) async {
    final fakeRepoWithNullImage = FakePlaceRepositoryWithData(
      places: [
        const PlaceModel(
          id: 'place-no-img-1',
          name: 'Bảo tàng không ảnh',
          category: 'CULTURE',
          address: '01 Trần Phú, Hải Châu, Đà Nẵng',
          imageUrl: null,
          averageRating: 4.5,
          totalReviews: 20,
        ),
      ],
    );

    await tester.pumpWidget(
      SmartLocalPlannerApp(
        placeRepository: fakeRepoWithNullImage,
        authRepository: const FakeAuthRepository(),
        favoriteRepository: const FakeFavoriteRepository(),
        itineraryRepository: const FakeItineraryRepository(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify place name is rendered
    expect(find.text('Bảo tàng không ảnh'), findsOneWidget);
    // Verify fallback placeholder banner text is rendered cleanly
    expect(find.text('Photo preview unavailable'), findsOneWidget);
    // Verify Category badge is displayed
    expect(find.text('CULTURE'), findsWidgets);
  });

  testWidgets('Tapping Saved Places while unauthenticated shows sign-in SnackBar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const SmartLocalPlannerApp(
        placeRepository: FakePlaceRepository(),
        authRepository: FakeAuthRepository(),
        favoriteRepository: FakeFavoriteRepository(),
        itineraryRepository: FakeItineraryRepository(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the Saved Places bookmark button in the AppBar
    await tester.tap(find.byTooltip('Saved Places'));
    await tester.pumpAndSettle();

    // Verify prompt SnackBar is displayed instead of opening an infinite loading skeleton
    expect(
      find.text('Please sign in to view your saved places.'),
      findsOneWidget,
    );
  });
}
