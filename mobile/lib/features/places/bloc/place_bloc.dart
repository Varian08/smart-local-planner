import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/place_repository.dart';
import 'place_event.dart';
import 'place_state.dart';

/// Business Logic Component managing state transitions for the Place Discovery domain.
/// Enforces unidirectional reactive data flow (Event -> Bloc -> State).
/// Preserves active filters across search and category selection, and coordinates infinite scroll pagination.
class PlaceBloc extends Bloc<PlaceEvent, PlaceState> {
  static const int defaultPageSize = 10;
  final PlaceRepository placeRepository;

  // ---------------------------------------------------------------------------
  // 1. Constructor & Event Handler Registration (Concurrent Transformers)
  // ---------------------------------------------------------------------------
  PlaceBloc({required this.placeRepository}) : super(PlaceInitial()) {
    // restartable(): Cancels superseded in-flight requests when new queries/filters arrive
    on<PlaceFetchStarted>(_onFetchStarted, transformer: restartable());
    on<PlaceCategoryChanged>(_onCategoryChanged, transformer: restartable());
    on<PlaceSearchQueryChanged>(_onSearchQueryChanged, transformer: restartable());
    on<PlaceRefreshRequested>(_onRefreshRequested, transformer: restartable());

    // droppable(): Ignores duplicate pagination requests until current page loads
    on<PlaceNextPageFetched>(_onNextPageFetched, transformer: droppable());
  }

  // ---------------------------------------------------------------------------
  // Helper Getters to Extract Active Filters
  // ---------------------------------------------------------------------------
  String? get _currentCategory {
    final s = state;
    if (s is PlaceLoaded) return s.selectedCategory;
    if (s is PlaceEmpty) return s.selectedCategory;
    if (s is PlaceError) return s.selectedCategory;
    return null;
  }

  String? get _currentQuery {
    final s = state;
    if (s is PlaceLoaded) return s.searchQuery;
    if (s is PlaceEmpty) return s.searchQuery;
    if (s is PlaceError) return s.searchQuery;
    return null;
  }

  // ---------------------------------------------------------------------------
  // 2. Fetch Places Handler (Initial & Clean Reload)
  // ---------------------------------------------------------------------------
  Future<void> _onFetchStarted(
    PlaceFetchStarted event,
    Emitter<PlaceState> emit,
  ) async {
    emit(PlaceLoading());
    await _fetchInitialPage(
      category: event.category,
      query: event.query,
      emit: emit,
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Category Filter Changed Handler (Preserves Search Query)
  // ---------------------------------------------------------------------------
  Future<void> _onCategoryChanged(
    PlaceCategoryChanged event,
    Emitter<PlaceState> emit,
  ) async {
    final activeQuery = _currentQuery;
    emit(PlaceLoading());
    await _fetchInitialPage(
      category: event.category,
      query: activeQuery,
      emit: emit,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Search Keyword Changed Handler (Preserves Selected Category)
  // ---------------------------------------------------------------------------
  Future<void> _onSearchQueryChanged(
    PlaceSearchQueryChanged event,
    Emitter<PlaceState> emit,
  ) async {
    final activeCategory = _currentCategory;
    final normalizedQuery =
        event.query.trim().isEmpty ? null : event.query.trim();
    emit(PlaceLoading());
    await _fetchInitialPage(
      category: activeCategory,
      query: normalizedQuery,
      emit: emit,
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Pull-To-Refresh Handler
  // ---------------------------------------------------------------------------
  Future<void> _onRefreshRequested(
    PlaceRefreshRequested event,
    Emitter<PlaceState> emit,
  ) async {
    await _fetchInitialPage(
      category: _currentCategory,
      query: _currentQuery,
      emit: emit,
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Infinite Scroll Pagination Handler
  // ---------------------------------------------------------------------------
  Future<void> _onNextPageFetched(
    PlaceNextPageFetched event,
    Emitter<PlaceState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PlaceLoaded) return;
    if (currentState.hasReachedMax || currentState.isFetchingNextPage) return;

    emit(currentState.copyWith(isFetchingNextPage: true));

    final nextPage = currentState.currentPage + 1;
    try {
      final newPlaces = await placeRepository.getPlaces(
        category: currentState.selectedCategory,
        query: currentState.searchQuery,
        page: nextPage,
        size: defaultPageSize,
      );

      if (newPlaces.isEmpty) {
        emit(
          currentState.copyWith(hasReachedMax: true, isFetchingNextPage: false),
        );
      } else {
        emit(
          currentState.copyWith(
            places: List.of(currentState.places)..addAll(newPlaces),
            currentPage: nextPage,
            hasReachedMax: newPlaces.length < defaultPageSize,
            isFetchingNextPage: false,
          ),
        );
      }
    } catch (_) {
      // On pagination failure, do not obliterate existing list; simply reset fetching flag
      emit(currentState.copyWith(isFetchingNextPage: false));
    }
  }

  // ---------------------------------------------------------------------------
  // Private Helper: Fetch First Page (Page 0)
  // ---------------------------------------------------------------------------
  Future<void> _fetchInitialPage({
    required String? category,
    required String? query,
    required Emitter<PlaceState> emit,
  }) async {
    try {
      final places = await placeRepository.getPlaces(
        category: category,
        query: query,
        page: 0,
        size: defaultPageSize,
      );

      if (places.isEmpty) {
        emit(
          PlaceEmpty(
            selectedCategory: category,
            searchQuery: query,
            message:
                (query != null || category != null)
                    ? 'No tourist places found matching your filter criteria.'
                    : 'No tourist places currently available.',
          ),
        );
      } else {
        emit(
          PlaceLoaded(
            places: places,
            selectedCategory: category,
            searchQuery: query,
            currentPage: 0,
            hasReachedMax: places.length < defaultPageSize,
            isFetchingNextPage: false,
          ),
        );
      }
    } on DioException catch (dioError) {
      emit(
        PlaceError(
          message: _mapDioExceptionToMessage(dioError),
          selectedCategory: category,
          searchQuery: query,
        ),
      );
    } catch (_) {
      emit(
        PlaceError(
          message: 'An unexpected system error occurred. Please try again.',
          selectedCategory: category,
          searchQuery: query,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: Resilient Error Message Normalization
  // ---------------------------------------------------------------------------
  String _mapDioExceptionToMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet connectivity.';
      case DioExceptionType.connectionError:
        return 'Cannot establish connection to backend service. Please verify server status.';
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        if (data is Map<String, dynamic> && data['message'] != null) {
          return data['message'].toString();
        }
        final statusCode = error.response?.statusCode;
        return 'Server responded with error status: ${statusCode ?? 'Unknown'}.';
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      default:
        return 'A network communication error occurred. Please tap Retry.';
    }
  }
}
