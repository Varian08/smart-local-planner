import 'package:flutter_test/flutter_test.dart';

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

void main() {
  testWidgets('App smoke test initializes successfully', (
    WidgetTester tester,
  ) async {
    // Build our app with injected FakePlaceRepository and trigger a frame.
    await tester.pumpWidget(
      const SmartLocalPlannerApp(placeRepository: FakePlaceRepository()),
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
      SmartLocalPlannerApp(placeRepository: fakeRepoWithNullImage),
    );
    await tester.pumpAndSettle();

    // Verify place name is rendered
    expect(find.text('Bảo tàng không ảnh'), findsOneWidget);
    // Verify fallback placeholder banner text is rendered cleanly
    expect(find.text('Photo preview unavailable'), findsOneWidget);
    // Verify Category badge is displayed
    expect(find.text('CULTURE'), findsWidgets);
  });
}
