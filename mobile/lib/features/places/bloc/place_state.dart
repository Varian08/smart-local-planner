import 'package:equatable/equatable.dart';

import '../data/models/place_model.dart';

/// Base contract for all Place States emitted from PlaceBloc.
/// Guarantees value equality to eliminate unnecessary widget re-renders.
abstract class PlaceState extends Equatable {
  const PlaceState();

  @override
  List<Object?> get props => [];
}

// ---------------------------------------------------------------------------
// 1. Initial State
// ---------------------------------------------------------------------------
/// Idle state before any data fetching event has been dispatched.
class PlaceInitial extends PlaceState {}

// ---------------------------------------------------------------------------
// 2. Loading State (Mandatory Contract)
// ---------------------------------------------------------------------------
/// Emitted during pending network requests to render non-blocking loading spinner.
class PlaceLoading extends PlaceState {}

// ---------------------------------------------------------------------------
// 3. Success Loaded State (Mandatory Contract)
// ---------------------------------------------------------------------------
/// Emitted when places are successfully retrieved and ready for UI rendering.
/// Holds active filter contexts and pagination progress.
class PlaceLoaded extends PlaceState {
  final List<PlaceModel> places;
  final String? selectedCategory;
  final String? searchQuery;
  final int currentPage;
  final bool hasReachedMax;
  final bool isFetchingNextPage;

  const PlaceLoaded({
    required this.places,
    this.selectedCategory,
    this.searchQuery,
    this.currentPage = 0,
    this.hasReachedMax = false,
    this.isFetchingNextPage = false,
  });

  PlaceLoaded copyWith({
    List<PlaceModel>? places,
    String? selectedCategory,
    bool clearCategory = false,
    String? searchQuery,
    bool clearQuery = false,
    int? currentPage,
    bool? hasReachedMax,
    bool? isFetchingNextPage,
  }) {
    return PlaceLoaded(
      places: places ?? this.places,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: clearQuery ? null : (searchQuery ?? this.searchQuery),
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isFetchingNextPage: isFetchingNextPage ?? this.isFetchingNextPage,
    );
  }

  @override
  List<Object?> get props => [
    places,
    selectedCategory,
    searchQuery,
    currentPage,
    hasReachedMax,
    isFetchingNextPage,
  ];
}

// ---------------------------------------------------------------------------
// 4. Empty State (Mandatory Contract)
// ---------------------------------------------------------------------------
/// Emitted when API returns an empty list (0 places matching criteria).
/// Retains active category and search query so user context is not lost.
class PlaceEmpty extends PlaceState {
  final String message;
  final String? selectedCategory;
  final String? searchQuery;

  const PlaceEmpty({
    this.message = 'No tourist places found matching your criteria.',
    this.selectedCategory,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [message, selectedCategory, searchQuery];
}

// ---------------------------------------------------------------------------
// 5. Error Failure State (Mandatory Contract)
// ---------------------------------------------------------------------------
/// Emitted upon network timeouts, HTTP errors, or server exceptions.
/// Provides an actionable error message for rendering with a Retry button.
class PlaceError extends PlaceState {
  final String message;
  final String? selectedCategory;
  final String? searchQuery;

  const PlaceError({
    required this.message,
    this.selectedCategory,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [message, selectedCategory, searchQuery];
}
