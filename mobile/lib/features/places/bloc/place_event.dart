import 'package:equatable/equatable.dart';

/// Base contract for all Place Events dispatched from UI presentation layer.
abstract class PlaceEvent extends Equatable {
  const PlaceEvent();

  @override
  List<Object?> get props => [];
}

// ---------------------------------------------------------------------------
// 1. Initial Fetch Event
// ---------------------------------------------------------------------------
/// Triggered when the place discovery screen is first mounted or pulled to refresh.
class PlaceFetchStarted extends PlaceEvent {
  final String? category;
  final String? query;

  const PlaceFetchStarted({this.category, this.query});

  @override
  List<Object?> get props => [category, query];
}

// ---------------------------------------------------------------------------
// 2. Filter & Category Selection Event
// ---------------------------------------------------------------------------
/// Triggered when the user taps on a category chip (e.g. HISTORICAL, CAFE)
class PlaceCategoryChanged extends PlaceEvent {
  final String? category;

  const PlaceCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

// ---------------------------------------------------------------------------
// 3. Search Keyword Submission Event
// ---------------------------------------------------------------------------
/// Triggered when the user types a search keyword in the search bar
class PlaceSearchQueryChanged extends PlaceEvent {
  final String query;

  const PlaceSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}
