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
class PlaceLoaded extends PlaceState {
  final List<PlaceModel> places;
  final String? selectedCategory;
  final String? searchQuery;

  const PlaceLoaded({
    required this.places,
    this.selectedCategory,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [places, selectedCategory, searchQuery];
}

// ---------------------------------------------------------------------------
// 4. Empty State (Mandatory Contract)
// ---------------------------------------------------------------------------
/// Emitted when API returns an empty list (0 places matching criteria).
class PlaceEmpty extends PlaceState {
  final String message;

  const PlaceEmpty({
    this.message = 'No tourist places found matching your criteria.',
  });

  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// 5. Error Failure State (Mandatory Contract)
// ---------------------------------------------------------------------------
/// Emitted upon network timeouts, HTTP errors, or server exceptions.
/// Provides an actionable error message for rendering with a Retry button.
class PlaceError extends PlaceState {
  final String message;

  const PlaceError({required this.message});

  @override
  List<Object?> get props => [message];
}
