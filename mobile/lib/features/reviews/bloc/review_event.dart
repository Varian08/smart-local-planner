import 'package:equatable/equatable.dart';

import '../data/models/review_request_model.dart';

/// Base class for all Review events.
abstract class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched to load reviews for a place with pagination and refresh support.
class LoadReviews extends ReviewEvent {
  final String placeId;
  final int page;
  final int size;
  final bool isRefresh;

  const LoadReviews({
    required this.placeId,
    this.page = 0,
    this.size = 10,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [placeId, page, size, isRefresh];
}

/// Dispatched to submit a new review for a place.
class SubmitReview extends ReviewEvent {
  final String placeId;
  final ReviewRequestModel request;

  const SubmitReview({
    required this.placeId,
    required this.request,
  });

  @override
  List<Object?> get props => [placeId, request];
}
