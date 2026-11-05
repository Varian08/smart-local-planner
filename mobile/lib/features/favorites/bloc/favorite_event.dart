import 'package:equatable/equatable.dart';

import '../../places/data/models/place_model.dart';

/// Base contract for all Favorite Events dispatched to FavoriteBloc.
abstract class FavoriteEvent extends Equatable {
  const FavoriteEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched to load the authenticated user's bookmarked favorites.
class FavoriteFetchStarted extends FavoriteEvent {
  const FavoriteFetchStarted();
}

/// Dispatched when the user taps the heart/bookmark button on a place.
/// Triggers optimistic local state toggle followed by asynchronous network sync.
class FavoriteToggleRequested extends FavoriteEvent {
  final PlaceModel place;

  const FavoriteToggleRequested(this.place);

  @override
  List<Object?> get props => [place];
}

/// Dispatched when the user logs out to clear favorite states in memory.
class FavoriteResetRequested extends FavoriteEvent {
  const FavoriteResetRequested();
}

