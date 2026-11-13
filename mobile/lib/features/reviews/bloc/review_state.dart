import 'package:equatable/equatable.dart';

import '../data/models/review_model.dart';

/// Base class for all Review states.
abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any review actions have been dispatched.
class ReviewInitial extends ReviewState {
  const ReviewInitial();
}

/// Emitted when reviews are loading from the network.
class ReviewLoading extends ReviewState {
  const ReviewLoading();
}

/// Emitted when reviews have been loaded successfully.
class ReviewLoaded extends ReviewState {
  final List<ReviewModel> reviews;
  final int page;
  final bool hasMore;

  const ReviewLoaded({
    required this.reviews,
    this.page = 0,
    this.hasMore = false,
  });

  ReviewLoaded copyWith({
    List<ReviewModel>? reviews,
    int? page,
    bool? hasMore,
  }) {
    return ReviewLoaded(
      reviews: reviews ?? this.reviews,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [reviews, page, hasMore];
}

/// Emitted while review submission is actively in flight.
class ReviewSubmitting extends ReviewState {
  final List<ReviewModel> currentReviews;

  const ReviewSubmitting({this.currentReviews = const []});

  @override
  List<Object?> get props => [currentReviews];
}

/// Emitted when review submission succeeded.
class ReviewSubmitSuccess extends ReviewState {
  final ReviewModel newReview;
  final List<ReviewModel> reviews;
  final String message;

  const ReviewSubmitSuccess({
    required this.newReview,
    required this.reviews,
    this.message = 'Review submitted successfully!',
  });

  @override
  List<Object?> get props => [newReview, reviews, message];
}

/// Emitted when any review operation fails.
class ReviewFailure extends ReviewState {
  final String message;
  final int? statusCode;
  final List<ReviewModel> reviews;

  const ReviewFailure({
    required this.message,
    this.statusCode,
    this.reviews = const [] ,
  });

  @override
  List<Object?> get props => [message, statusCode, reviews];
}
