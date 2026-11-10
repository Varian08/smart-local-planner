import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/favorite_repository.dart';
import 'favorite_event.dart';
import 'favorite_state.dart';

/// Business Logic Component managing user's Favorite places collection.
/// Implements Optimistic UI state updates with automatic network failure rollback.
class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  final FavoriteRepository favoriteRepository;
  final Set<String> _inFlightPlaceIds = {};

  FavoriteBloc({required this.favoriteRepository})
      : super(const FavoriteInitial()) {
    on<FavoriteFetchStarted>(_onFetchStarted);
    on<FavoriteToggleRequested>(_onToggleRequested);
    on<FavoriteResetRequested>(_onResetRequested);
  }

  // ---------------------------------------------------------------------------
  // 1. Fetch User Favorites
  // ---------------------------------------------------------------------------
  Future<void> _onFetchStarted(
    FavoriteFetchStarted event,
    Emitter<FavoriteState> emit,
  ) async {
    emit(const FavoriteLoading());
    try {
      final favorites = await favoriteRepository.getFavorites();
      final ids = favorites.map((p) => p.id).toSet();
      emit(FavoriteLoaded(
        favoritePlaceIds: ids,
        favorites: favorites,
      ));
    } catch (e) {
      emit(const FavoriteFailure(
        message: 'Unable to load your saved favorites. Please check your connection.',
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Optimistic Favorite Toggle with Rollback on Error & Concurrency Guard
  // ---------------------------------------------------------------------------
  Future<void> _onToggleRequested(
    FavoriteToggleRequested event,
    Emitter<FavoriteState> emit,
  ) async {
    final placeId = event.place.id;
    if (_inFlightPlaceIds.contains(placeId)) {
      return;
    }
    _inFlightPlaceIds.add(placeId);

    final currentState = state;
    final currentLoaded = currentState is FavoriteLoaded
        ? currentState
        : const FavoriteLoaded(favoritePlaceIds: {}, favorites: []);

    final previousIds = Set<String>.from(currentLoaded.favoritePlaceIds);
    final previousFavorites = List.from(currentLoaded.favorites);
    final isCurrentlyFavorite = previousIds.contains(placeId);

    // 1. Optimistic Update: Immediately toggle locally before network roundtrip
    final newIds = Set<String>.from(previousIds);
    final newFavorites = List.from(previousFavorites);

    if (isCurrentlyFavorite) {
      newIds.remove(placeId);
      newFavorites.removeWhere((p) => p.id == placeId);
    } else {
      newIds.add(placeId);
      newFavorites.add(event.place);
    }

    emit(FavoriteLoaded(
      favoritePlaceIds: newIds,
      favorites: newFavorites.cast(),
      errorMessage: null,
    ));

    // 2. Asynchronous Network Call
    try {
      if (isCurrentlyFavorite) {
        await favoriteRepository.removeFavorite(placeId);
      } else {
        await favoriteRepository.addFavorite(placeId);
      }
    } catch (_) {
      // 3. Rollback on Failure: Revert this place's mutation on the latest state
      final latestState = state;
      final latestLoaded = latestState is FavoriteLoaded
          ? latestState
          : currentLoaded;
      final rollbackIds = Set<String>.from(latestLoaded.favoritePlaceIds);
      final rollbackFavorites = List.from(latestLoaded.favorites);

      if (isCurrentlyFavorite) {
        if (!rollbackIds.contains(placeId)) {
          rollbackIds.add(placeId);
          rollbackFavorites.add(event.place);
        }
      } else {
        rollbackIds.remove(placeId);
        rollbackFavorites.removeWhere((p) => p.id == placeId);
      }

      emit(FavoriteLoaded(
        favoritePlaceIds: rollbackIds,
        favorites: rollbackFavorites.cast(),
        errorMessage: isCurrentlyFavorite
            ? 'Failed to remove from favorites. Reverted.'
            : 'Failed to bookmark place. Reverted.',
      ));
    } finally {
      _inFlightPlaceIds.remove(placeId);
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Reset Session Cache on Logout
  // ---------------------------------------------------------------------------
  void _onResetRequested(
    FavoriteResetRequested event,
    Emitter<FavoriteState> emit,
  ) {
    _inFlightPlaceIds.clear();
    emit(const FavoriteLoaded(favoritePlaceIds: {}, favorites: []));
  }
}

