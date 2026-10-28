import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/features/places/bloc/place_bloc.dart';
import 'package:smart_local_planner/features/places/bloc/place_event.dart';
import 'package:smart_local_planner/features/places/bloc/place_state.dart';
import 'package:smart_local_planner/features/places/data/models/place_model.dart';
import 'package:smart_local_planner/features/places/data/repositories/place_repository.dart';

class MockPlaceRepository implements PlaceRepository {
  List<PlaceModel> returnPlaces = [];
  String? lastQuery;
  String? lastCategory;
  int? lastPage;
  int? lastSize;
  bool shouldThrow = false;
  Object? customException;

  @override
  Future<List<PlaceModel>> getPlaces({
    String? query,
    String? category,
    int? priceLevel,
    int page = 0,
    int size = 10,
    String sort = 'averageRating,desc',
  }) async {
    if (customException != null) {
      throw customException!;
    }
    if (shouldThrow) {
      throw Exception('Repository simulated error');
    }
    lastQuery = query;
    lastCategory = category;
    lastPage = page;
    lastSize = size;
    return returnPlaces;
  }

  @override
  Future<PlaceModel> getPlaceById(String id) async {
    throw UnimplementedError();
  }
}

PlaceModel _createDummyPlace(String id, String name) {
  return PlaceModel(
    id: id,
    name: name,
    category: 'ATTRACTION',
    address: 'Da Nang, Vietnam',
    latitude: 16.0544,
    longitude: 108.2022,
    averageRating: 4.8,
    totalReviews: 120,
    priceLevel: 2,
    openingHours: '08:00 - 22:00',
    imageUrl: 'https://example.com/image.jpg',
    description: 'Scenic Da Nang destination',
  );
}

void main() {
  late MockPlaceRepository repository;
  late PlaceBloc bloc;

  setUp(() {
    repository = MockPlaceRepository();
    bloc = PlaceBloc(placeRepository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  test('Initial state is PlaceInitial', () {
    expect(bloc.state, isA<PlaceInitial>());
  });

  test(
    'Emits [PlaceLoading, PlaceLoaded] on successful initial PlaceFetchStarted',
    () async {
      final dummyPlaces = [_createDummyPlace('1', 'Dragon Bridge')];
      repository.returnPlaces = dummyPlaces;

      final expectedStates = [
        isA<PlaceLoading>(),
        isA<PlaceLoaded>()
            .having((s) => s.places.length, 'places.length', 1)
            .having((s) => s.currentPage, 'currentPage', 0)
            .having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const PlaceFetchStarted());
    },
  );

  test('Emits [PlaceLoading, PlaceEmpty] when 0 places are returned', () async {
    repository.returnPlaces = [];

    final expectedStates = [
      isA<PlaceLoading>(),
      isA<PlaceEmpty>().having(
        (s) => s.message,
        'message',
        contains('No tourist places'),
      ),
    ];

    expectLater(bloc.stream, emitsInOrder(expectedStates));
    bloc.add(const PlaceFetchStarted(query: 'NonExistentSpot'));
  });

  test(
    'Preserves search query when category changed after keyword search',
    () async {
      repository.returnPlaces = [_createDummyPlace('1', 'Cong Cafe')];

      // Step 1: User types search query
      bloc.add(const PlaceSearchQueryChanged('coffee'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<PlaceLoaded>().having((s) => s.searchQuery, 'searchQuery', 'coffee'),
        ),
      );

      // Step 2: User taps category chip 'CAFE' -> query 'coffee' must be preserved!
      bloc.add(const PlaceCategoryChanged('CAFE'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<PlaceLoaded>()
              .having((s) => s.selectedCategory, 'selectedCategory', 'CAFE')
              .having((s) => s.searchQuery, 'searchQuery', 'coffee'),
        ),
      );

      expect(repository.lastCategory, 'CAFE');
      expect(repository.lastQuery, 'coffee');
    },
  );

  test(
    'Preserves category filter when keyword query is typed after category selection',
    () async {
      repository.returnPlaces = [_createDummyPlace('2', 'My Khe Beach')];

      // Step 1: User selects category 'BEACH'
      bloc.add(const PlaceCategoryChanged('BEACH'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<PlaceLoaded>().having(
            (s) => s.selectedCategory,
            'selectedCategory',
            'BEACH',
          ),
        ),
      );

      // Step 2: User types search query 'resort' -> category 'BEACH' must be preserved!
      bloc.add(const PlaceSearchQueryChanged('resort'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<PlaceLoaded>()
              .having((s) => s.selectedCategory, 'selectedCategory', 'BEACH')
              .having((s) => s.searchQuery, 'searchQuery', 'resort'),
        ),
      );

      expect(repository.lastCategory, 'BEACH');
      expect(repository.lastQuery, 'resort');
    },
  );

  test(
    'Coordinates infinite scroll pagination correctly on PlaceNextPageFetched',
    () async {
      // Simulate page 0 with full 10 places
      final page0Places = List.generate(
        10,
        (i) => _createDummyPlace('$i', 'Place $i'),
      );
      repository.returnPlaces = page0Places;

      bloc.add(const PlaceFetchStarted());
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<PlaceLoaded>()
              .having((s) => s.places.length, 'places.length', 10)
              .having((s) => s.hasReachedMax, 'hasReachedMax', false),
        ),
      );

      // Simulate page 1 returning 5 places
      final page1Places = List.generate(
        5,
        (i) => _createDummyPlace('${i + 10}', 'Place ${i + 10}'),
      );
      repository.returnPlaces = page1Places;

      bloc.add(const PlaceNextPageFetched());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<PlaceLoaded>().having(
            (s) => s.isFetchingNextPage,
            'isFetchingNextPage',
            true,
          ),
          isA<PlaceLoaded>()
              .having((s) => s.places.length, 'places.length', 15)
              .having((s) => s.currentPage, 'currentPage', 1)
              .having((s) => s.hasReachedMax, 'hasReachedMax', true)
              .having(
                (s) => s.isFetchingNextPage,
                'isFetchingNextPage',
                false,
              ),
        ]),
      );

      expect(repository.lastPage, 1);
    },
  );

  test(
    'Emits [PlaceLoading, PlaceError] with message extracted from ApiErrorResponse',
    () async {
      repository.customException = DioException(
        requestOptions: RequestOptions(path: '/places'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/places'),
          statusCode: 400,
          data: {
            'timestamp': '2026-10-28T12:00:00Z',
            'status': 400,
            'code': 'VALIDATION_FAILED',
            'message': 'Page size must not exceed 50.',
          },
        ),
      );

      bloc.add(const PlaceFetchStarted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<PlaceLoading>(),
          isA<PlaceError>().having(
            (s) => s.message,
            'message',
            'Page size must not exceed 50.',
          ),
        ]),
      );
    },
  );
}

