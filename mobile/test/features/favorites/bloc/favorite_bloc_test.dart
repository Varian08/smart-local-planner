import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/features/favorites/bloc/favorite_bloc.dart';
import 'package:smart_local_planner/features/favorites/bloc/favorite_event.dart';
import 'package:smart_local_planner/features/favorites/bloc/favorite_state.dart';
import 'package:smart_local_planner/features/favorites/data/repositories/favorite_repository.dart';
import 'package:smart_local_planner/features/places/data/models/place_model.dart';

class MockFavoriteRepository implements FavoriteRepository {
  List<PlaceModel> favoritesToReturn = [];
  Object? shouldThrow;
  String? lastAddedPlaceId;
  String? lastRemovedPlaceId;
  int addCallCount = 0;
  int removeCallCount = 0;
  Completer<void>? inFlightCompleter;

  @override
  Future<List<PlaceModel>> getFavorites() async {
    if (shouldThrow != null) throw shouldThrow!;
    return favoritesToReturn;
  }

  @override
  Future<void> addFavorite(String placeId) async {
    addCallCount++;
    if (inFlightCompleter != null) {
      await inFlightCompleter!.future;
    }
    if (shouldThrow != null) throw shouldThrow!;
    lastAddedPlaceId = placeId;
  }

  @override
  Future<void> removeFavorite(String placeId) async {
    removeCallCount++;
    if (inFlightCompleter != null) {
      await inFlightCompleter!.future;
    }
    if (shouldThrow != null) throw shouldThrow!;
    lastRemovedPlaceId = placeId;
  }
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

void main() {
  late MockFavoriteRepository mockRepository;
  late FavoriteBloc favoriteBloc;

  setUp(() {
    mockRepository = MockFavoriteRepository();
    favoriteBloc = FavoriteBloc(favoriteRepository: mockRepository);
  });

  tearDown(() {
    favoriteBloc.close();
  });

  group('FavoriteBloc - FetchStarted', () {
    test('initial state is FavoriteInitial', () {
      expect(favoriteBloc.state, const FavoriteInitial());
    });

    test('emits [FavoriteLoading, FavoriteLoaded] on fetch success', () async {
      final p1 = _createDummyPlace('p-1', 'Bà Nà');
      final p2 = _createDummyPlace('p-2', 'Cầu Rồng');
      mockRepository.favoritesToReturn = [p1, p2];

      final expectedStates = [
        const FavoriteLoading(),
        FavoriteLoaded(
          favoritePlaceIds: const {'p-1', 'p-2'},
          favorites: [p1, p2],
        ),
      ];

      expectLater(favoriteBloc.stream, emitsInOrder(expectedStates));

      favoriteBloc.add(const FavoriteFetchStarted());
    });

    test('emits [FavoriteLoading, FavoriteFailure] on fetch error', () async {
      mockRepository.shouldThrow = DioException(
        requestOptions: RequestOptions(path: '/favorites'),
        type: DioExceptionType.connectionError,
      );

      final expectedStates = [
        const FavoriteLoading(),
        const FavoriteFailure(
          message: 'Unable to load your saved favorites. Please check your connection.',
        ),
      ];

      expectLater(favoriteBloc.stream, emitsInOrder(expectedStates));

      favoriteBloc.add(const FavoriteFetchStarted());
    });
  });

  group('FavoriteBloc - ToggleRequested Optimistic UI', () {
    test('optimistically adds place to favorites when not currently favorite', () async {
      final p1 = _createDummyPlace('p-1', 'Bà Nà');
      final p2 = _createDummyPlace('p-2', 'Cầu Rồng');

      mockRepository.favoritesToReturn = [p1];
      favoriteBloc.add(const FavoriteFetchStarted());
      await Future.delayed(Duration.zero);

      final expectedStates = [
        FavoriteLoaded(
          favoritePlaceIds: const {'p-1', 'p-2'},
          favorites: [p1, p2],
          errorMessage: null,
        ),
      ];

      expectLater(favoriteBloc.stream, emitsInOrder(expectedStates));

      favoriteBloc.add(FavoriteToggleRequested(p2));
      await Future.delayed(Duration.zero);

      expect(mockRepository.lastAddedPlaceId, 'p-2');
    });

    test('optimistically removes place from favorites when already favorite', () async {
      final p1 = _createDummyPlace('p-1', 'Bà Nà');
      mockRepository.favoritesToReturn = [p1];
      favoriteBloc.add(const FavoriteFetchStarted());
      await Future.delayed(Duration.zero);

      final expectedStates = [
        const FavoriteLoaded(
          favoritePlaceIds: {},
          favorites: [],
          errorMessage: null,
        ),
      ];

      expectLater(favoriteBloc.stream, emitsInOrder(expectedStates));

      favoriteBloc.add(FavoriteToggleRequested(p1));
      await Future.delayed(Duration.zero);

      expect(mockRepository.lastRemovedPlaceId, 'p-1');
    });

    test('rolls back to previous state and emits errorMessage on add API failure', () async {
      final p1 = _createDummyPlace('p-1', 'Bà Nà');
      mockRepository.favoritesToReturn = [];
      favoriteBloc.add(const FavoriteFetchStarted());
      await Future.delayed(Duration.zero);

      mockRepository.shouldThrow = DioException(
        requestOptions: RequestOptions(path: '/favorites/p-1'),
        type: DioExceptionType.connectionTimeout,
      );

      final expectedStates = [
        // 1. Optimistic toggle
        FavoriteLoaded(
          favoritePlaceIds: const {'p-1'},
          favorites: [p1],
          errorMessage: null,
        ),
        // 2. Rollback upon network failure
        const FavoriteLoaded(
          favoritePlaceIds: {},
          favorites: [],
          errorMessage: 'Failed to bookmark place. Reverted.',
        ),
      ];

      expectLater(favoriteBloc.stream, emitsInOrder(expectedStates));

      favoriteBloc.add(FavoriteToggleRequested(p1));
    });

    test('rolls back to previous state and emits errorMessage on remove API failure', () async {
      final p1 = _createDummyPlace('p-1', 'Bà Nà');
      mockRepository.favoritesToReturn = [p1];
      favoriteBloc.add(const FavoriteFetchStarted());
      await Future.delayed(Duration.zero);

      mockRepository.shouldThrow = DioException(
        requestOptions: RequestOptions(path: '/favorites/p-1'),
        type: DioExceptionType.connectionTimeout,
      );

      final expectedStates = [
        // 1. Optimistic remove
        const FavoriteLoaded(
          favoritePlaceIds: {},
          favorites: [],
          errorMessage: null,
        ),
        // 2. Rollback to keep favorite upon failure
        FavoriteLoaded(
          favoritePlaceIds: const {'p-1'},
          favorites: [p1],
          errorMessage: 'Failed to remove from favorites. Reverted.',
        ),
      ];

      expectLater(favoriteBloc.stream, emitsInOrder(expectedStates));

      favoriteBloc.add(FavoriteToggleRequested(p1));
    });

    test('ignores duplicate rapid FavoriteToggleRequested for the same placeId while in flight', () async {
      final p1 = _createDummyPlace('p-1', 'Bà Nà');
      mockRepository.favoritesToReturn = [];
      favoriteBloc.add(const FavoriteFetchStarted());
      await Future.delayed(Duration.zero);

      final completer = Completer<void>();
      mockRepository.inFlightCompleter = completer;

      // Rapid double-tap on the same place before network completes
      favoriteBloc.add(FavoriteToggleRequested(p1));
      favoriteBloc.add(FavoriteToggleRequested(p1));
      await Future.delayed(Duration.zero);

      expect(mockRepository.addCallCount, 1);
      expect(mockRepository.removeCallCount, 0);

      completer.complete();
      await Future.delayed(Duration.zero);
    });
  });

  group('FavoriteBloc - ResetRequested', () {
    test('resets cache to empty FavoriteLoaded on logout', () async {
      final p1 = _createDummyPlace('p-1', 'Bà Nà');
      mockRepository.favoritesToReturn = [p1];
      favoriteBloc.add(const FavoriteFetchStarted());
      await Future.delayed(Duration.zero);

      final expectedStates = [
        const FavoriteLoaded(favoritePlaceIds: {}, favorites: []),
      ];

      expectLater(favoriteBloc.stream, emitsInOrder(expectedStates));

      favoriteBloc.add(const FavoriteResetRequested());
    });
  });
}

