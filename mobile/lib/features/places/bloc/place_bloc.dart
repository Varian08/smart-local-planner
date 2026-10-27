import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/place_repository.dart';
import 'place_event.dart';
import 'place_state.dart';

/// Business Logic Component managing state transitions for the Place Discovery domain.
/// Enforces unidirectional reactive data flow (Event -> Bloc -> State).
class PlaceBloc extends Bloc<PlaceEvent, PlaceState> {
  final PlaceRepository placeRepository;

  // ---------------------------------------------------------------------------
  // 1. Constructor & Event Handler Registration
  // ---------------------------------------------------------------------------
  PlaceBloc({required this.placeRepository}) : super(PlaceInitial()) {
    on<PlaceFetchStarted>(_onFetchStarted);
    on<PlaceCategoryChanged>(_onCategoryChanged);
    on<PlaceSearchQueryChanged>(_onSearchQueryChanged);
  }

  // ---------------------------------------------------------------------------
  // 2. Fetch Places Handler (Enforces 4-State Lifecycle)
  // ---------------------------------------------------------------------------
  Future<void> _onFetchStarted(
    PlaceFetchStarted event,
    Emitter<PlaceState> emit,
  ) async {
    emit(PlaceLoading());
    try {
      final places = await placeRepository.getPlaces(
        category: event.category,
        query: event.query,
      );

      if (places.isEmpty) {
        emit(const PlaceEmpty());
      } else {
        emit(
          PlaceLoaded(
            places: places,
            selectedCategory: event.category,
            searchQuery: event.query,
          ),
        );
      }
    } on DioException catch (dioError) {
      emit(PlaceError(message: _mapDioExceptionToMessage(dioError)));
    } catch (e) {
      emit(
        const PlaceError(
          message: 'An unexpected system error occurred. Please try again.',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Category Filter Changed Handler
  // ---------------------------------------------------------------------------
  Future<void> _onCategoryChanged(
    PlaceCategoryChanged event,
    Emitter<PlaceState> emit,
  ) async {
    add(PlaceFetchStarted(category: event.category));
  }

  // ---------------------------------------------------------------------------
  // 4. Search Keyword Changed Handler
  // ---------------------------------------------------------------------------
  Future<void> _onSearchQueryChanged(
    PlaceSearchQueryChanged event,
    Emitter<PlaceState> emit,
  ) async {
    add(PlaceFetchStarted(query: event.query));
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
        final statusCode = error.response?.statusCode;
        return 'Server responded with error status: ${statusCode ?? 'Unknown'}.';
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      default:
        return 'A network communication error occurred. Please tap Retry.';
    }
  }
}
