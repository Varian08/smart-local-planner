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
/// Triggered when the place discovery screen is mounted or explicitly initialized.
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
/// Triggered when the user taps on a category chip (e.g. HISTORICAL, CAFE).
/// Preserves active search query.
class PlaceCategoryChanged extends PlaceEvent {
  final String? category;

  const PlaceCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

// ---------------------------------------------------------------------------
// 3. Search Keyword Submission Event
// ---------------------------------------------------------------------------
/// Triggered when the user updates the search keyword in the search bar.
/// Preserves active category filter.
class PlaceSearchQueryChanged extends PlaceEvent {
  final String query;

  const PlaceSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

// ---------------------------------------------------------------------------
// 4. Infinite Scroll Pagination Event
// ---------------------------------------------------------------------------
/// Triggered when the user scrolls near the bottom of the place list.
class PlaceNextPageFetched extends PlaceEvent {
  const PlaceNextPageFetched();
}

// ---------------------------------------------------------------------------
// 5. Pull-To-Refresh Event
// ---------------------------------------------------------------------------
/// Triggered on swipe-down pull-to-refresh; resets pagination to page 0 while preserving active filters.
class PlaceRefreshRequested extends PlaceEvent {
  const PlaceRefreshRequested();
}
