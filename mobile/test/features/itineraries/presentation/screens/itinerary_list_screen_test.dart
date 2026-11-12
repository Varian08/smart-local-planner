import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/features/itineraries/bloc/itinerary_bloc.dart';
import 'package:smart_local_planner/features/itineraries/bloc/itinerary_event.dart';
import 'package:smart_local_planner/features/itineraries/data/models/itinerary_model.dart';
import 'package:smart_local_planner/features/itineraries/data/models/itinerary_request_model.dart';
import 'package:smart_local_planner/features/itineraries/data/repositories/itinerary_repository.dart';
import 'package:smart_local_planner/features/itineraries/presentation/screens/itinerary_list_screen.dart';

class FakeItineraryRepository implements ItineraryRepository {
  List<ItineraryModel> itinerariesToReturn = [];
  bool shouldThrow = false;
  int fetchCallCount = 0;
  String? lastDeletedId;

  @override
  Future<List<ItineraryModel>> getItineraries({
    int page = 0,
    int size = 10,
    String sort = 'createdAt,desc',
  }) async {
    fetchCallCount++;
    if (shouldThrow) {
      throw Exception('Network error');
    }
    return itinerariesToReturn;
  }

  @override
  Future<ItineraryModel> getItineraryDetail(String id) async {
    if (shouldThrow) throw Exception('Network error');
    return ItineraryModel(id: id, title: 'Detail $id');
  }

  @override
  Future<ItineraryModel> createItinerary(ItineraryRequestModel request) async {
    if (shouldThrow) throw Exception('Network error');
    return ItineraryModel(
      id: 'created-itin-id',
      title: request.title,
      description: request.description,
    );
  }

  @override
  Future<ItineraryModel> updateItinerary(
    String id,
    ItineraryRequestModel request,
  ) async {
    if (shouldThrow) throw Exception('Network error');
    return ItineraryModel(id: id, title: request.title);
  }

  @override
  Future<void> deleteItinerary(String id) async {
    lastDeletedId = id;
    if (shouldThrow) throw Exception('Network error');
  }
}

Widget _wrapWithProviders({required ItineraryBloc itineraryBloc}) {
  return BlocProvider<ItineraryBloc>.value(
    value: itineraryBloc,
    child: const MaterialApp(
      home: ItineraryListScreen(),
    ),
  );
}

void main() {
  group('ItineraryListScreen 4-State UI Contract Tests', () {
    testWidgets('renders LoadingState skeleton while initial/loading', (
      WidgetTester tester,
    ) async {
      final repo = FakeItineraryRepository();
      final bloc = ItineraryBloc(itineraryRepository: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrapWithProviders(itineraryBloc: bloc));

      // Initial state renders skeleton
      expect(find.byKey(const Key('itinerary_loading_skeleton')), findsOneWidget);
      expect(find.text('My Itineraries'), findsOneWidget);
    });

    testWidgets('renders EmptyState when user has no itineraries', (
      WidgetTester tester,
    ) async {
      final repo = FakeItineraryRepository()..itinerariesToReturn = [];
      final bloc = ItineraryBloc(itineraryRepository: repo);
      addTearDown(bloc.close);

      bloc.add(const LoadItineraries(isRefresh: true));
      await tester.pumpWidget(_wrapWithProviders(itineraryBloc: bloc));
      await tester.pumpAndSettle();

      // Verify Empty State elements
      expect(find.text('No Travel Itineraries Yet'), findsOneWidget);
      expect(
        find.text(
          'Plan your dream vacation by creating a multi-day trip with scheduled stops and visits.',
        ),
        findsOneWidget,
      );
      expect(find.text('Create Your First Trip'), findsOneWidget);
    });

    testWidgets('renders SuccessState with ItineraryCards when itineraries exist', (
      WidgetTester tester,
    ) async {
      final repo = FakeItineraryRepository()
        ..itinerariesToReturn = [
          const ItineraryModel(
            id: 'itin-1',
            title: 'Da Nang Explorer',
            description: '3-day coastal discovery trip',
            startDate: '2026-11-20',
            endDate: '2026-11-22',
            totalDays: 3,
            totalPlaces: 4,
          ),
          const ItineraryModel(
            id: 'itin-2',
            title: 'Hoi An Ancient Town',
            description: 'Lanterns and culinary delight',
            totalDays: 2,
            totalPlaces: 2,
          ),
        ];
      final bloc = ItineraryBloc(itineraryRepository: repo);
      addTearDown(bloc.close);

      bloc.add(const LoadItineraries(isRefresh: true));
      await tester.pumpWidget(_wrapWithProviders(itineraryBloc: bloc));
      await tester.pumpAndSettle();

      // Verify both itineraries are displayed
      expect(find.text('Da Nang Explorer'), findsOneWidget);
      expect(find.text('Hoi An Ancient Town'), findsOneWidget);
      expect(find.text('3 days'), findsOneWidget);
      expect(find.text('4 places'), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('renders ErrorState with Retry button on failure', (
      WidgetTester tester,
    ) async {
      final repo = FakeItineraryRepository()..shouldThrow = true;
      final bloc = ItineraryBloc(itineraryRepository: repo);
      addTearDown(bloc.close);

      bloc.add(const LoadItineraries());
      await tester.pumpWidget(_wrapWithProviders(itineraryBloc: bloc));
      await tester.pumpAndSettle();

      // Verify Error State
      expect(find.text('Failed to Load Itineraries'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Tap Retry and verify success
      repo.shouldThrow = false;
      repo.itinerariesToReturn = [
        const ItineraryModel(id: 'i-1', title: 'Recovered Trip', totalDays: 1),
      ];

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.text('Recovered Trip'), findsOneWidget);
    });

    testWidgets('tapping Create New Trip opens CreateItineraryDialog', (
      WidgetTester tester,
    ) async {
      final repo = FakeItineraryRepository()..itinerariesToReturn = [];
      final bloc = ItineraryBloc(itineraryRepository: repo);
      addTearDown(bloc.close);

      bloc.add(const LoadItineraries());
      await tester.pumpWidget(_wrapWithProviders(itineraryBloc: bloc));
      await tester.pumpAndSettle();

      // Tap the FAB to open Create dialog
      await tester.tap(find.byKey(const Key('itinerary_create_fab')));
      await tester.pumpAndSettle();

      expect(find.text('Create New Itinerary'), findsOneWidget);
      expect(find.byKey(const Key('itinerary_title_input')), findsOneWidget);
      expect(find.byKey(const Key('itinerary_submit_button')), findsOneWidget);

      // Test validation: blank title should fail
      await tester.tap(find.byKey(const Key('itinerary_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Title cannot be blank'), findsOneWidget);

      // Enter valid title
      await tester.enterText(
        find.byKey(const Key('itinerary_title_input')),
        'My Summer Trip',
      );
      await tester.tap(find.byKey(const Key('itinerary_submit_button')));
      await tester.pumpAndSettle();

      // Dialog should close
      expect(find.text('Create New Itinerary'), findsNothing);
    });

    testWidgets('tapping Delete on ItineraryCard displays confirmation dialog', (
      WidgetTester tester,
    ) async {
      final repo = FakeItineraryRepository()
        ..itinerariesToReturn = [
          const ItineraryModel(
            id: 'itin-delete-test',
            title: 'Trip to Cancel',
            totalDays: 2,
          ),
        ];
      final bloc = ItineraryBloc(itineraryRepository: repo);
      addTearDown(bloc.close);

      bloc.add(const LoadItineraries());
      await tester.pumpWidget(_wrapWithProviders(itineraryBloc: bloc));
      await tester.pumpAndSettle();

      expect(find.text('Trip to Cancel'), findsOneWidget);

      // Tap delete icon button on card
      await tester.tap(find.byTooltip('Delete itinerary'));
      await tester.pumpAndSettle();

      // Verify modal content
      expect(find.text('Delete Itinerary?'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to delete "Trip to Cancel"? This action cannot be undone.',
        ),
        findsOneWidget,
      );

      // Confirm delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(repo.lastDeletedId, 'itin-delete-test');
    });
  });
}
