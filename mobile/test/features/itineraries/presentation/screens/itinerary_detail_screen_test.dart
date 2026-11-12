import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/features/itineraries/bloc/itinerary_bloc.dart';
import 'package:smart_local_planner/features/itineraries/data/models/itinerary_item_model.dart';
import 'package:smart_local_planner/features/itineraries/data/models/itinerary_model.dart';
import 'package:smart_local_planner/features/itineraries/data/models/itinerary_request_model.dart';
import 'package:smart_local_planner/features/itineraries/data/repositories/itinerary_repository.dart';
import 'package:smart_local_planner/features/itineraries/presentation/screens/itinerary_detail_screen.dart';
import 'package:smart_local_planner/features/places/data/models/place_model.dart';

class FakeItineraryDetailRepository implements ItineraryRepository {
  ItineraryModel? detailToReturn;
  bool shouldThrow = false;

  @override
  Future<List<ItineraryModel>> getItineraries({
    int page = 0,
    int size = 10,
    String sort = 'createdAt,desc',
  }) async =>
      const [];

  @override
  Future<ItineraryModel> getItineraryDetail(String id) async {
    if (shouldThrow) throw Exception('Network error');
    return detailToReturn ??
        ItineraryModel(
          id: id,
          title: 'Detailed Tour',
          totalDays: 2,
        );
  }

  @override
  Future<ItineraryModel> createItinerary(ItineraryRequestModel request) async =>
      throw UnimplementedError();

  @override
  Future<ItineraryModel> updateItinerary(
    String id,
    ItineraryRequestModel request,
  ) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteItinerary(String id) async {}
}

Widget _wrapDetail({
  required ItineraryBloc itineraryBloc,
  required String itineraryId,
}) {
  return BlocProvider<ItineraryBloc>.value(
    value: itineraryBloc,
    child: MaterialApp(
      home: ItineraryDetailScreen(itineraryId: itineraryId),
    ),
  );
}

void main() {
  group('ItineraryDetailScreen 4-State UI Contract Tests', () {
    testWidgets('renders LoadingState skeleton while fetching detail', (
      WidgetTester tester,
    ) async {
      final repo = FakeItineraryDetailRepository();
      final bloc = ItineraryBloc(itineraryRepository: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(
        _wrapDetail(itineraryBloc: bloc, itineraryId: 'detail-test-1'),
      );

      // Loading skeleton is shown initially
      expect(
        find.byKey(const Key('itinerary_detail_loading_skeleton')),
        findsOneWidget,
      );
      expect(find.text('Itinerary Details'), findsOneWidget);
    });

    testWidgets('renders ErrorState with retry button on detail load failure', (
      WidgetTester tester,
    ) async {
      final repo = FakeItineraryDetailRepository()..shouldThrow = true;
      final bloc = ItineraryBloc(itineraryRepository: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(
        _wrapDetail(itineraryBloc: bloc, itineraryId: 'fail-id'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to Load Itinerary'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Retry
      repo.shouldThrow = false;
      repo.detailToReturn = const ItineraryModel(
        id: 'fail-id',
        title: 'Recovered Itinerary',
        totalDays: 1,
      );

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.text('Recovered Itinerary'), findsOneWidget);
    });

    testWidgets(
        'renders Overview, multi-day tabs, and timeline items when loaded', (
      WidgetTester tester,
    ) async {
      final repo = FakeItineraryDetailRepository()
        ..detailToReturn = const ItineraryModel(
          id: 'itin-detail-ok',
          title: 'Saigon to Da Nang',
          description: 'A 2-day journey',
          totalDays: 2,
          totalPlaces: 2,
          items: [
            ItineraryItemModel(
              id: 'item-d1',
              dayNumber: 1,
              orderIndex: 0,
              startTime: '09:00:00',
              notes: 'Morning coffee',
              place: PlaceModel(
                id: 'place-1',
                name: 'Bà Nà Hills',
                category: 'ATTRACTION',
                address: 'Da Nang, Vietnam',
              ),
            ),
            ItineraryItemModel(
              id: 'item-d2',
              dayNumber: 2,
              orderIndex: 0,
              startTime: '14:30:00',
              notes: 'Sunset bridge walk',
              place: PlaceModel(
                id: 'place-2',
                name: 'Cầu Rồng',
                category: 'ATTRACTION',
                address: 'Hải Châu, Đà Nẵng',
              ),
            ),
          ],
        );
      final bloc = ItineraryBloc(itineraryRepository: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(
        _wrapDetail(itineraryBloc: bloc, itineraryId: 'itin-detail-ok'),
      );
      await tester.pumpAndSettle();

      // Verify Header and Overview Card
      expect(find.text('Saigon to Da Nang'), findsOneWidget);
      expect(find.text('A 2-day journey'), findsOneWidget);
      expect(find.text('2 Days'), findsOneWidget);

      // Verify Day 1 tab chip is selected by default
      expect(find.byKey(const Key('itinerary_day_chip_1')), findsOneWidget);
      expect(find.byKey(const Key('itinerary_day_chip_2')), findsOneWidget);

      // Day 1 item is visible
      expect(find.text('Bà Nà Hills'), findsOneWidget);
      expect(find.text('09:00:00'), findsOneWidget);
      expect(find.text('Morning coffee'), findsOneWidget);
      // Day 2 item should not be rendered yet
      expect(find.text('Cầu Rồng'), findsNothing);

      // Switch to Day 2
      await tester.tap(find.byKey(const Key('itinerary_day_chip_2')));
      await tester.pumpAndSettle();

      // Day 2 item is now visible
      expect(find.text('Cầu Rồng'), findsOneWidget);
      expect(find.text('14:30:00'), findsOneWidget);
      expect(find.text('Sunset bridge walk'), findsOneWidget);
    });

    testWidgets('renders empty day placeholder when selected day has no items', (
      WidgetTester tester,
    ) async {
      final repo = FakeItineraryDetailRepository()
        ..detailToReturn = const ItineraryModel(
          id: 'itin-empty-day',
          title: 'Relaxed Trip',
          totalDays: 2,
          items: [
            ItineraryItemModel(
              id: 'item-1',
              dayNumber: 1,
              orderIndex: 0,
              place: PlaceModel(
                id: 'p-1',
                name: 'Place 1',
                category: 'ATTRACTION',
                address: 'Address 1',
              ),
            ),
          ],
        );
      final bloc = ItineraryBloc(itineraryRepository: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(
        _wrapDetail(itineraryBloc: bloc, itineraryId: 'itin-empty-day'),
      );
      await tester.pumpAndSettle();

      // Switch to Day 2 (which has 0 items)
      await tester.tap(find.byKey(const Key('itinerary_day_chip_2')));
      await tester.pumpAndSettle();

      expect(find.text('No places scheduled for Day 2'), findsOneWidget);
    });
  });
}
