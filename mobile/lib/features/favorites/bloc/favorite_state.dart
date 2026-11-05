import 'package:equatable/equatable.dart';

import '../../places/data/models/place_model.dart';

/// Base contract for all Favorite States emitted by FavoriteBloc.
abstract class FavoriteState extends Equatable {
  const FavoriteState();

  @override
  List<Object?> get props => [];
}

/// Initial idle state before fetching favorite places.
class FavoriteInitial extends FavoriteState {
  const FavoriteInitial();
}

/// Loading state emitted during initial favorites retrieval.
class FavoriteLoading extends FavoriteState {
  const FavoriteLoading();
}

/// Success state holding active favorite IDs and place models.
/// Emits immediately upon optimistic toggle; carries errorMessage on network rollback.
class FavoriteLoaded extends FavoriteState {
  final Set<String> favoritePlaceIds;
  final List<PlaceModel> favorites;
  final String? errorMessage;

  const FavoriteLoaded({
    required this.favoritePlaceIds,
    required this.favorites,
    this.errorMessage,
  });

  FavoriteLoaded copyWith({
    Set<String>? favoritePlaceIds,
    List<PlaceModel>? favorites,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FavoriteLoaded(
      favoritePlaceIds: favoritePlaceIds ?? this.favoritePlaceIds,
      favorites: favorites ?? this.favorites,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [favoritePlaceIds, favorites, errorMessage];
}

/// Failure state emitted when fetching favorites from backend fails.
class FavoriteFailure extends FavoriteState {
  final String message;

  const FavoriteFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

