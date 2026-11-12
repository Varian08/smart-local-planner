import 'package:equatable/equatable.dart';

import '../data/models/itinerary_request_model.dart';

/// Base class for all Itinerary events.
abstract class ItineraryEvent extends Equatable {
  const ItineraryEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched to load user's itineraries with pagination and refresh support.
class LoadItineraries extends ItineraryEvent {
  final int page;
  final int size;
  final bool isRefresh;

  const LoadItineraries({
    this.page = 0,
    this.size = 10,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [page, size, isRefresh];
}

/// Dispatched to load full itinerary details including scheduled items.
class LoadItineraryDetail extends ItineraryEvent {
  final String id;

  const LoadItineraryDetail(this.id);

  @override
  List<Object?> get props => [id];
}

/// Dispatched to create a new multi-day itinerary.
class CreateItinerary extends ItineraryEvent {
  final ItineraryRequestModel request;

  const CreateItinerary(this.request);

  @override
  List<Object?> get props => [request];
}

/// Dispatched to update an itinerary's metadata and replace its schedule items.
class UpdateItinerary extends ItineraryEvent {
  final String id;
  final ItineraryRequestModel request;

  const UpdateItinerary({
    required this.id,
    required this.request,
  });

  @override
  List<Object?> get props => [id, request];
}

/// Dispatched to delete an itinerary by its unique ID.
class DeleteItinerary extends ItineraryEvent {
  final String id;

  const DeleteItinerary(this.id);

  @override
  List<Object?> get props => [id];
}

