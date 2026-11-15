import 'package:equatable/equatable.dart';

import '../data/models/itinerary_model.dart';

/// Base class for all Itinerary states.
abstract class ItineraryState extends Equatable {
  const ItineraryState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any itinerary actions have been dispatched.
class ItineraryInitial extends ItineraryState {
  const ItineraryInitial();
}

/// Emitted when an asynchronous itinerary operation is in progress.
class ItineraryLoading extends ItineraryState {
  const ItineraryLoading();
}

/// Emitted when a mutation (create, update, delete) or background reload is in progress,
/// preserving the existing list on screen to avoid skeleton flashes.
class ItinerarySubmitting extends ItineraryState {
  final List<ItineraryModel> itineraries;

  const ItinerarySubmitting({this.itineraries = const []});

  @override
  List<Object?> get props => [itineraries];
}

/// Emitted when user's itineraries have been loaded successfully.
class ItineraryLoaded extends ItineraryState {
  final List<ItineraryModel> itineraries;
  final int page;
  final bool hasMore;

  const ItineraryLoaded({
    required this.itineraries,
    this.page = 0,
    this.hasMore = false,
  });

  ItineraryLoaded copyWith({
    List<ItineraryModel>? itineraries,
    int? page,
    bool? hasMore,
  }) {
    return ItineraryLoaded(
      itineraries: itineraries ?? this.itineraries,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [itineraries, page, hasMore];
}

/// Emitted when detailed itinerary data with schedule items has been loaded.
class ItineraryDetailLoaded extends ItineraryState {
  final ItineraryModel itinerary;

  const ItineraryDetailLoaded(this.itinerary);

  @override
  List<Object?> get props => [itinerary];
}

/// Emitted when a mutation (create, update, delete) succeeds.
class ItineraryOperationSuccess extends ItineraryState {
  final String message;
  final ItineraryModel? itinerary;
  final String? deletedId;
  final List<ItineraryModel> itineraries;

  const ItineraryOperationSuccess({
    required this.message,
    this.itinerary,
    this.deletedId,
    this.itineraries = const [],
  });

  @override
  List<Object?> get props => [message, itinerary, deletedId, itineraries];
}

/// Emitted when an itinerary operation fails.
class ItineraryFailure extends ItineraryState {
  final String message;
  final int? statusCode;
  final List<ItineraryModel> itineraries;

  const ItineraryFailure({
    required this.message,
    this.statusCode,
    this.itineraries = const [],
  });

  @override
  List<Object?> get props => [message, statusCode, itineraries];
}

