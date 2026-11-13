import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/review_model.dart';
import '../data/repositories/review_repository.dart';
import 'review_event.dart';
import 'review_state.dart';

/// Business Logic Component managing Place Reviews and Rating submissions.
/// Follows strict unidirectional data flow (Event -> Bloc -> State).
class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final ReviewRepository reviewRepository;

  ReviewBloc({required this.reviewRepository}) : super(const ReviewInitial()) {
    on<LoadReviews>(_onLoadReviews);
    on<SubmitReview>(_onSubmitReview);
  }

  // ---------------------------------------------------------------------------
  // 1. Load Reviews (List / Pagination / Refresh)
  // ---------------------------------------------------------------------------
  Future<void> _onLoadReviews(
    LoadReviews event,
    Emitter<ReviewState> emit,
  ) async {
    if (state is! ReviewLoaded || event.isRefresh || event.page == 0) {
      emit(const ReviewLoading());
    }

    try {
      final reviews = await reviewRepository.getPlaceReviews(
        event.placeId,
        page: event.page,
        size: event.size,
      );

      final hasMore = reviews.length >= event.size;

      if (event.page > 0 && state is ReviewLoaded && !event.isRefresh) {
        final currentReviews = (state as ReviewLoaded).reviews;
        emit(ReviewLoaded(
          reviews: [...currentReviews, ...reviews],
          page: event.page,
          hasMore: hasMore,
        ));
      } else {
        emit(ReviewLoaded(
          reviews: reviews,
          page: event.page,
          hasMore: hasMore,
        ));
      }
    } on DioException catch (e) {
      emit(_mapDioErrorToFailure(e, _extractCurrentReviews()));
    } catch (e) {
      emit(ReviewFailure(
        message: 'Failed to load reviews: ${e.toString()}',
        reviews: _extractCurrentReviews(),
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Submit Review
  // ---------------------------------------------------------------------------
  Future<void> _onSubmitReview(
    SubmitReview event,
    Emitter<ReviewState> emit,
  ) async {
    final currentReviews = _extractCurrentReviews();
    emit(ReviewSubmitting(currentReviews: currentReviews));

    try {
      final newReview = await reviewRepository.submitReview(
        event.placeId,
        event.request,
      );

      final updatedReviews = [newReview, ...currentReviews];
      emit(ReviewSubmitSuccess(
        newReview: newReview,
        reviews: updatedReviews,
        message: 'Review submitted successfully!',
      ));
    } on DioException catch (e) {
      emit(_mapDioErrorToFailure(e, currentReviews));
    } catch (e) {
      emit(ReviewFailure(
        message: 'Failed to submit review: ${e.toString()}',
        reviews: currentReviews,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------
  List<ReviewModel> _extractCurrentReviews() {
    final currentState = state;
    if (currentState is ReviewLoaded) {
      return currentState.reviews;
    } else if (currentState is ReviewSubmitSuccess) {
      return currentState.reviews;
    } else if (currentState is ReviewFailure) {
      return currentState.reviews;
    } else if (currentState is ReviewSubmitting) {
      return currentState.currentReviews;
    }
    return const [];
  }

  ReviewFailure _mapDioErrorToFailure(
    DioException e,
    List<ReviewModel> fallbackReviews,
  ) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    String? serverMessage;
    if (responseData is Map<String, dynamic>) {
      if (responseData['message'] is String) {
        serverMessage = responseData['message'] as String;
      } else if (responseData['error'] is String) {
        serverMessage = responseData['error'] as String;
      }
    }

    switch (statusCode) {
      case 409:
        return ReviewFailure(
          message: serverMessage ?? 'You have already reviewed this place.',
          statusCode: 409,
          reviews: fallbackReviews,
        );
      case 401:
        return ReviewFailure(
          message: serverMessage ?? 'Please sign in to submit a review.',
          statusCode: 401,
          reviews: fallbackReviews,
        );
      case 400:
        return ReviewFailure(
          message: serverMessage ?? 'Rating must be between 1 and 5 stars.',
          statusCode: 400,
          reviews: fallbackReviews,
        );
      case 404:
        return ReviewFailure(
          message: serverMessage ?? 'Place not found.',
          statusCode: 404,
          reviews: fallbackReviews,
        );
      default:
        return ReviewFailure(
          message: serverMessage ??
              e.message ??
              'An unexpected network error occurred.',
          statusCode: statusCode,
          reviews: fallbackReviews,
        );
    }
  }
}
