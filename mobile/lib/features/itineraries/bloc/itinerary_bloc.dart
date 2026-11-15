import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/itinerary_model.dart';
import '../data/repositories/itinerary_repository.dart';
import 'itinerary_event.dart';
import 'itinerary_state.dart';

/// Business Logic Component managing user's Itineraries lifecycle and state transitions.
/// Follows strict unidirectional data flow (Event -> Bloc -> State).
class ItineraryBloc extends Bloc<ItineraryEvent, ItineraryState> {
  final ItineraryRepository itineraryRepository;

  ItineraryBloc({required this.itineraryRepository})
      : super(const ItineraryInitial()) {
    on<LoadItineraries>(_onLoadItineraries);
    on<LoadItineraryDetail>(_onLoadItineraryDetail);
    on<CreateItinerary>(_onCreateItinerary);
    on<UpdateItinerary>(_onUpdateItinerary);
    on<DeleteItinerary>(_onDeleteItinerary);
  }

  // ---------------------------------------------------------------------------
  // 1. Load Itineraries (List / Pagination / Refresh)
  // ---------------------------------------------------------------------------
  Future<void> _onLoadItineraries(
    LoadItineraries event,
    Emitter<ItineraryState> emit,
  ) async {
    final currentList = _extractCurrentItineraries();
    // Preserve existing list via ItinerarySubmitting when refreshing after mutation or pull-to-refresh
    if (event.isRefresh && currentList.isNotEmpty) {
      emit(ItinerarySubmitting(itineraries: currentList));
    } else if (state is! ItineraryLoaded || event.isRefresh || event.page == 0) {
      emit(const ItineraryLoading());
    }

    try {
      final items = await itineraryRepository.getItineraries(
        page: event.page,
        size: event.size,
      );

      final hasMore = items.length >= event.size;

      if (event.page > 0 && state is ItineraryLoaded && !event.isRefresh) {
        final currentList = (state as ItineraryLoaded).itineraries;
        emit(ItineraryLoaded(
          itineraries: [...currentList, ...items],
          page: event.page,
          hasMore: hasMore,
        ));
      } else {
        emit(ItineraryLoaded(
          itineraries: items,
          page: event.page,
          hasMore: hasMore,
        ));
      }
    } on DioException catch (e) {
      emit(_mapDioErrorToFailure(e, _extractCurrentItineraries()));
    } catch (e) {
      emit(ItineraryFailure(
        message: 'Failed to load itineraries: ${e.toString()}',
        itineraries: _extractCurrentItineraries(),
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Load Itinerary Detail
  // ---------------------------------------------------------------------------
  Future<void> _onLoadItineraryDetail(
    LoadItineraryDetail event,
    Emitter<ItineraryState> emit,
  ) async {
    emit(const ItineraryLoading());
    try {
      final detail = await itineraryRepository.getItineraryDetail(event.id);
      emit(ItineraryDetailLoaded(detail));
    } on DioException catch (e) {
      emit(_mapDioErrorToFailure(e));
    } catch (e) {
      emit(ItineraryFailure(
        message: 'Failed to load itinerary detail: ${e.toString()}',
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Create Itinerary
  // ---------------------------------------------------------------------------
  Future<void> _onCreateItinerary(
    CreateItinerary event,
    Emitter<ItineraryState> emit,
  ) async {
    final currentList = _extractCurrentItineraries();
    emit(ItinerarySubmitting(itineraries: currentList));
    try {
      final created = await itineraryRepository.createItinerary(event.request);
      emit(ItineraryOperationSuccess(
        message: 'Itinerary created successfully',
        itinerary: created,
        itineraries: currentList,
      ));
    } on DioException catch (e) {
      emit(_mapDioErrorToFailure(e, currentList));
    } catch (e) {
      emit(ItineraryFailure(
        message: 'Failed to create itinerary: ${e.toString()}',
        itineraries: currentList,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // 4. Update Itinerary
  // ---------------------------------------------------------------------------
  Future<void> _onUpdateItinerary(
    UpdateItinerary event,
    Emitter<ItineraryState> emit,
  ) async {
    final currentList = _extractCurrentItineraries();
    emit(ItinerarySubmitting(itineraries: currentList));
    try {
      final updated = await itineraryRepository.updateItinerary(
        event.id,
        event.request,
      );
      final optimisticList = currentList
          .map((item) => item.id == event.id ? updated : item)
          .toList();
      emit(ItineraryOperationSuccess(
        message: 'Itinerary updated successfully',
        itinerary: updated,
        itineraries: optimisticList,
      ));
    } on DioException catch (e) {
      emit(_mapDioErrorToFailure(e, currentList));
    } catch (e) {
      emit(ItineraryFailure(
        message: 'Failed to update itinerary: ${e.toString()}',
        itineraries: currentList,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // 5. Delete Itinerary
  // ---------------------------------------------------------------------------
  Future<void> _onDeleteItinerary(
    DeleteItinerary event,
    Emitter<ItineraryState> emit,
  ) async {
    final currentList = _extractCurrentItineraries();
    emit(ItinerarySubmitting(itineraries: currentList));
    try {
      await itineraryRepository.deleteItinerary(event.id);
      final optimisticList =
          currentList.where((item) => item.id != event.id).toList();
      emit(ItineraryOperationSuccess(
        message: 'Itinerary deleted successfully',
        deletedId: event.id,
        itineraries: optimisticList,
      ));
    } on DioException catch (e) {
      emit(_mapDioErrorToFailure(e, currentList));
    } catch (e) {
      emit(ItineraryFailure(
        message: 'Failed to delete itinerary: ${e.toString()}',
        itineraries: currentList,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: Extract Current Itineraries List Defensively
  // ---------------------------------------------------------------------------
  List<ItineraryModel> _extractCurrentItineraries() {
    final currentState = state;
    if (currentState is ItineraryLoaded) return currentState.itineraries;
    if (currentState is ItinerarySubmitting) return currentState.itineraries;
    if (currentState is ItineraryOperationSuccess) {
      return currentState.itineraries;
    }
    if (currentState is ItineraryFailure) return currentState.itineraries;
    return const [];
  }

  // ---------------------------------------------------------------------------
  // Helper: Defensive DioException Translation
  // ---------------------------------------------------------------------------
  ItineraryFailure _mapDioErrorToFailure(
    DioException e, [
    List<ItineraryModel> fallbackItineraries = const [],
  ]) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    String? serverMessage;
    if (responseData is Map<String, dynamic> &&
        responseData['message'] is String) {
      serverMessage = responseData['message'] as String;
    }

    switch (statusCode) {
      case 401:
        return ItineraryFailure(
          message: serverMessage ?? 'Session expired. Please sign in again.',
          statusCode: 401,
          itineraries: fallbackItineraries,
        );
      case 403:
        return ItineraryFailure(
          message: serverMessage ??
              'You do not have permission to access or modify this itinerary.',
          statusCode: 403,
          itineraries: fallbackItineraries,
        );
      case 404:
        return ItineraryFailure(
          message: serverMessage ?? 'Itinerary not found.',
          statusCode: 404,
          itineraries: fallbackItineraries,
        );
      case 400:
        return ItineraryFailure(
          message: serverMessage ?? 'Invalid itinerary data provided.',
          statusCode: 400,
          itineraries: fallbackItineraries,
        );
      default:
        return ItineraryFailure(
          message: serverMessage ??
              e.message ??
              'An unexpected network error occurred.',
          statusCode: statusCode,
          itineraries: fallbackItineraries,
        );
    }
  }
}
