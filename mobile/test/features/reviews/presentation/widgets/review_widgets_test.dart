import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/features/reviews/bloc/review_bloc.dart';
import 'package:smart_local_planner/features/reviews/bloc/review_state.dart';
import 'package:smart_local_planner/features/reviews/data/models/review_model.dart';
import 'package:smart_local_planner/features/reviews/data/models/review_request_model.dart';
import 'package:smart_local_planner/features/reviews/data/repositories/review_repository.dart';
import 'package:smart_local_planner/features/reviews/presentation/widgets/review_form_bottom_sheet.dart';
import 'package:smart_local_planner/features/reviews/presentation/widgets/review_list_widget.dart';
import 'package:smart_local_planner/features/reviews/presentation/widgets/star_rating_widget.dart';

class FakeReviewRepository implements ReviewRepository {
  List<ReviewModel> reviews = [];
  ReviewModel? createdReview;

  @override
  Future<List<ReviewModel>> getPlaceReviews(
    String placeId, {
    int page = 0,
    int size = 10,
    String sort = 'createdAt,desc',
  }) async {
    return reviews;
  }

  @override
  Future<ReviewModel> submitReview(
    String placeId,
    ReviewRequestModel request,
  ) async {
    return createdReview ??
        ReviewModel(
          id: 'new-id',
          userId: 'user-id',
          authorName: 'Test Author',
          rating: request.rating,
          comment: request.comment,
        );
  }
}

void main() {
  group('StarRatingWidget Tests', () {
    testWidgets('renders read-only stars without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StarRatingWidget(rating: 4),
          ),
        ),
      );

      expect(find.byType(StarRatingWidget), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(1));
    });

    testWidgets('interactive star selection triggers onRatingChanged callback', (tester) async {
      int selectedRating = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRatingWidget(
              rating: 3,
              onRatingChanged: (rating) {
                selectedRating = rating;
              },
            ),
          ),
        ),
      );

      // Tap on the 5th star
      final stars = find.byType(InkWell);
      expect(stars, findsNWidgets(5));
      await tester.tap(stars.at(4));
      await tester.pump();

      expect(selectedRating, 5);
    });
  });

  group('ReviewListWidget Tests', () {
    testWidgets('renders empty state when reviews list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReviewListWidget(reviews: []),
          ),
        ),
      );

      expect(find.text('No reviews yet'), findsOneWidget);
      expect(
        find.text('Be the first to share your experience with this place!'),
        findsOneWidget,
      );
    });

    testWidgets('renders review cards and community rating summary when reviews exist', (tester) async {
      final reviews = [
        ReviewModel(
          id: 'r-1',
          userId: 'u-1',
          authorName: 'Linh Tran',
          rating: 5,
          comment: 'Fantastic local food and friendly atmosphere!',
          createdAt: DateTime(2026, 10, 20),
        ),
        ReviewModel(
          id: 'r-2',
          userId: 'u-2',
          authorName: 'Minh Le',
          rating: 4,
          comment: 'Good value for money.',
          createdAt: DateTime(2026, 10, 21),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReviewListWidget(
                reviews: reviews,
                averageRating: 4.5,
                totalReviews: 2,
              ),
            ),
          ),
        ),
      );

      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('2 reviews'), findsOneWidget);
      expect(find.text('Linh Tran'), findsOneWidget);
      expect(find.text('Fantastic local food and friendly atmosphere!'), findsOneWidget);
      expect(find.text('Minh Le'), findsOneWidget);
      expect(find.text('Good value for money.'), findsOneWidget);
    });

    testWidgets(
        'preserves server averageRating and totalReviews when reviews is a partial page',
        (WidgetTester tester) async {
      const partialReviews = [
        ReviewModel(
          id: 'rev-page-1',
          userId: 'user-1',
          authorName: 'Linh Tran',
          rating: 5,
          comment: 'Great view!',
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReviewListWidget(
                reviews: partialReviews,
                averageRating: 4.7,
                totalReviews: 24,
              ),
            ),
          ),
        ),
      );

      expect(find.text('4.7'), findsOneWidget);
      expect(find.text('24 reviews'), findsOneWidget);
      expect(find.text('5.0'), findsNothing);
      expect(find.text('1 review'), findsNothing);
    });
  });

  group('ReviewFormBottomSheet Tests', () {
    testWidgets('renders rating picker, comment textfield, and submits review', (tester) async {
      final repo = FakeReviewRepository();
      final bloc = ReviewBloc(reviewRepository: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<ReviewBloc>.value(
              value: bloc,
              child: const ReviewFormBottomSheet(
                placeId: 'p-1',
                placeName: 'Dragon Bridge',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Review Dragon Bridge'), findsOneWidget);
      expect(find.text('5 Stars - Outstanding'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Submit Review'), findsOneWidget);

      // Enter comment
      await tester.enterText(
        find.byType(TextField),
        'Spectacular fire-breathing show on weekends!',
      );
      await tester.pump();

      // Tap submit
      await tester.tap(find.text('Submit Review'));
      await tester.pump();

      // ReviewSubmitting or Success processed
      expect(find.byType(ReviewFormBottomSheet), findsOneWidget);
    });

    testWidgets('displays inline error banner on ReviewFailure and clears on user input', (tester) async {
      final repo = FakeReviewRepository();
      final bloc = ReviewBloc(reviewRepository: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<ReviewBloc>.value(
              value: bloc,
              child: const ReviewFormBottomSheet(
                placeId: 'p-conflict-1',
                placeName: 'Han River',
              ),
            ),
          ),
        ),
      );

      // Verify no error banner initially
      expect(find.byKey(const Key('review_form_error_banner')), findsNothing);

      // Simulate conflict error
      bloc.emit(
        const ReviewFailure(
          message: 'You have already reviewed this place.',
          statusCode: 409,
        ),
      );
      await tester.pump();

      // Error banner must be rendered inline
      expect(find.byKey(const Key('review_form_error_banner')), findsOneWidget);
      expect(find.text('You have already reviewed this place.'), findsOneWidget);

      // Typing into comment field clears error banner
      await tester.enterText(find.byType(TextField), 'Updating my thoughts...');
      await tester.pump();

      expect(find.byKey(const Key('review_form_error_banner')), findsNothing);
    });
  });
}
