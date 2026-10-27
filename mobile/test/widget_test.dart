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
}
