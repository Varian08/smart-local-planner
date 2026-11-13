import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/features/reviews/bloc/review_bloc.dart';
import 'package:smart_local_planner/features/reviews/bloc/review_event.dart';
import 'package:smart_local_planner/features/reviews/bloc/review_state.dart';
import 'package:smart_local_planner/features/reviews/data/models/review_model.dart';
import 'package:smart_local_planner/features/reviews/data/models/review_request_model.dart';
import 'package:smart_local_planner/features/reviews/data/repositories/review_repository.dart';

class MockReviewRepository implements ReviewRepository {
  List<ReviewModel> reviewsToReturn = [];
  ReviewModel? createdToReturn;
  Object? shouldThrow;

  int getPlaceReviewsCallCount = 0;
  int submitReviewCallCount = 0;
  String? lastPlaceId;
  ReviewRequestModel? lastRequest;

  @override
  Future<List<ReviewModel>> getPlaceReviews(
    String placeId, {
    int page = 0,
    int size = 10,
    String sort = 'createdAt,desc',
  }) async {
    getPlaceReviewsCallCount++;
    lastPlaceId = placeId;
    if (shouldThrow != null) throw shouldThrow!;
    return reviewsToReturn;
  }

  @override
  Future<ReviewModel> submitReview(
    String placeId,
    ReviewRequestModel request,
  ) async {
    submitReviewCallCount++;
    lastPlaceId = placeId;
    lastRequest = request;
    if (shouldThrow != null) throw shouldThrow!;
    return createdToReturn ??
        ReviewModel(
          id: 'mock-created-id',
          userId: 'mock-user-id',
          authorName: 'Mock Reviewer',
          rating: request.rating,
          comment: request.comment,
        );
  }
}

void main() {
  late MockReviewRepository mockRepository;
  late ReviewBloc bloc;

  setUp(() {
    mockRepository = MockReviewRepository();
    bloc = ReviewBloc(reviewRepository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  const testReview = ReviewModel(
    id: 'rev-1',
    userId: 'u-1',
    authorName: 'Jane Doe',
    rating: 5,
    comment: 'Splendid view!',
  );

  test('Initial state is ReviewInitial', () {
    expect(bloc.state, const ReviewInitial());
  });

  group('LoadReviews Event Tests', () {
    test('emits [ReviewLoading, ReviewLoaded] on successful fetch', () async {
      mockRepository.reviewsToReturn = [testReview];

      final expectedStates = [
        const ReviewLoading(),
        const ReviewLoaded(
          reviews: [testReview],
          page: 0,
          hasMore: false,
        ),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const LoadReviews(placeId: 'p-1'));
    });

    test('emits [ReviewLoading, ReviewLoaded] with empty list when no reviews exist', () async {
      mockRepository.reviewsToReturn = [];

      final expectedStates = [
        const ReviewLoading(),
        const ReviewLoaded(
          reviews: [],
          page: 0,
          hasMore: false,
        ),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const LoadReviews(placeId: 'p-empty'));
    });

    test('emits [ReviewLoading, ReviewFailure] on DioException', () async {
      mockRepository.shouldThrow = DioException(
        requestOptions: RequestOptions(path: '/places/p-1/reviews'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/places/p-1/reviews'),
          statusCode: 404,
          data: {'message': 'Place not found.'},
        ),
      );

      final expectedStates = [
        const ReviewLoading(),
        const ReviewFailure(
          message: 'Place not found.',
          statusCode: 404,
          reviews: [],
        ),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const LoadReviews(placeId: 'p-1'));
    });
  });

  group('SubmitReview Event Tests', () {
    test('emits [ReviewSubmitting, ReviewSubmitSuccess] and prepends new review', () async {
      const createdReview = ReviewModel(
        id: 'rev-new',
        userId: 'u-me',
        authorName: 'Me',
        rating: 5,
        comment: 'Freshly posted',
      );
      mockRepository.createdToReturn = createdReview;

      final expectedStates = [
        const ReviewSubmitting(currentReviews: []),
        const ReviewSubmitSuccess(
          newReview: createdReview,
          reviews: [createdReview],
          message: 'Review submitted successfully!',
        ),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(
        const SubmitReview(
          placeId: 'p-1',
          request: ReviewRequestModel(rating: 5, comment: 'Freshly posted'),
        ),
      );
    });

    test('emits ReviewFailure with statusCode 409 on duplicate review attempt', () async {
      mockRepository.shouldThrow = DioException(
        requestOptions: RequestOptions(path: '/places/p-1/reviews'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/places/p-1/reviews'),
          statusCode: 409,
          data: {
            'code': 'DUPLICATE_RESOURCE',
            'message': 'You have already reviewed this place.',
          },
        ),
      );

      final expectedStates = [
        const ReviewSubmitting(currentReviews: []),
        const ReviewFailure(
          message: 'You have already reviewed this place.',
          statusCode: 409,
          reviews: [],
        ),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(
        const SubmitReview(
          placeId: 'p-1',
          request: ReviewRequestModel(rating: 5),
        ),
      );
    });

    test('emits ReviewFailure with statusCode 401 when unauthorized', () async {
      mockRepository.shouldThrow = DioException(
        requestOptions: RequestOptions(path: '/places/p-1/reviews'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/places/p-1/reviews'),
          statusCode: 401,
          data: {'message': 'Please sign in to submit a review.'},
        ),
      );

      final expectedStates = [
        const ReviewSubmitting(currentReviews: []),
        const ReviewFailure(
          message: 'Please sign in to submit a review.',
          statusCode: 401,
          reviews: [],
        ),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(
        const SubmitReview(
          placeId: 'p-1',
          request: ReviewRequestModel(rating: 4),
        ),
      );
    });

    test('emits ReviewFailure with statusCode 400 when validation fails', () async {
      mockRepository.shouldThrow = DioException(
        requestOptions: RequestOptions(path: '/places/p-1/reviews'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/places/p-1/reviews'),
          statusCode: 400,
          data: {'message': 'Rating must be between 1 and 5 stars.'},
        ),
      );

      final expectedStates = [
        const ReviewSubmitting(currentReviews: []),
        const ReviewFailure(
          message: 'Rating must be between 1 and 5 stars.',
          statusCode: 400,
          reviews: [],
        ),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(
        const SubmitReview(
          placeId: 'p-1',
          request: ReviewRequestModel(rating: 6),
        ),
      );
    });
  });
}
