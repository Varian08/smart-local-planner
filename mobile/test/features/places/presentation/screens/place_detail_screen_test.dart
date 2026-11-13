import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/features/auth/bloc/auth_bloc.dart';
import 'package:smart_local_planner/features/auth/bloc/auth_event.dart';
import 'package:smart_local_planner/features/auth/data/models/auth_request_model.dart';
import 'package:smart_local_planner/features/auth/data/models/auth_response_model.dart';
import 'package:smart_local_planner/features/auth/data/repositories/auth_repository.dart';
import 'package:smart_local_planner/features/favorites/bloc/favorite_bloc.dart';
import 'package:smart_local_planner/features/favorites/data/repositories/favorite_repository.dart';
import 'package:smart_local_planner/features/places/data/models/place_model.dart';
import 'package:smart_local_planner/features/places/presentation/screens/place_detail_screen.dart';
import 'package:smart_local_planner/features/reviews/bloc/review_bloc.dart';
import 'package:smart_local_planner/features/reviews/data/models/review_model.dart';
import 'package:smart_local_planner/features/reviews/data/models/review_request_model.dart';
import 'package:smart_local_planner/features/reviews/data/repositories/review_repository.dart';
import 'package:smart_local_planner/features/reviews/presentation/widgets/review_form_bottom_sheet.dart';

class FakeAuthRepo implements AuthRepository {
  final bool authenticated;
  FakeAuthRepo({this.authenticated = false});

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async =>
      throw UnimplementedError();

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isAuthenticated() async => authenticated;

  @override
  Future<String?> getAccessToken() async =>
      authenticated ? 'fake-token' : null;
}

class FakeFavRepo implements FavoriteRepository {
  final List<PlaceModel> favorites;
  FakeFavRepo({this.favorites = const []});

  @override
  Future<List<PlaceModel>> getFavorites() async => favorites;

  @override
  Future<void> addFavorite(String placeId) async {}

  @override
  Future<void> removeFavorite(String placeId) async {}
}

class FakeReviewRepo implements ReviewRepository {
  List<ReviewModel> reviews;
  FakeReviewRepo({this.reviews = const []});

  @override
  Future<List<ReviewModel>> getPlaceReviews(
    String placeId, {
    int page = 0,
    int size = 10,
    String sort = 'createdAt,desc',
  }) async =>
      reviews;

  @override
  Future<ReviewModel> submitReview(
    String placeId,
    ReviewRequestModel request,
  ) async =>
      ReviewModel(
        id: 'new-id',
        userId: 'u-1',
        authorName: 'Tester',
        rating: request.rating,
        comment: request.comment,
      );
}

Widget _buildTestApp({
  required PlaceModel place,
  required AuthRepository authRepo,
  required FavoriteRepository favRepo,
  required ReviewRepository reviewRepo,
  ReviewBloc? reviewBloc,
}) {
  final authBloc = AuthBloc(authRepository: authRepo)
    ..add(const AuthCheckRequested());
  final favBloc = FavoriteBloc(favoriteRepository: favRepo);

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ReviewRepository>.value(value: reviewRepo),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<FavoriteBloc>.value(value: favBloc),
      ],
      child: MaterialApp(
        home: PlaceDetailScreen(
          place: place,
          reviewBloc: reviewBloc,
        ),
      ),
    ),
  );
}

void main() {
  const testPlace = PlaceModel(
    id: 'place-detail-1',
    name: 'Marble Mountains',
    category: 'ATTRACTION',
    address: 'Hoa Hai, Ngu Hanh Son, Da Nang',
    description: 'Cluster of five marble and limestone hills.',
    priceLevel: 2,
    openingHours: '07:00 - 17:30',
    averageRating: 4.7,
    totalReviews: 24,
  );

  testWidgets('PlaceDetailScreen renders place details properly', (tester) async {
    final authRepo = FakeAuthRepo(authenticated: false);
    final favRepo = FakeFavRepo();
    final reviewRepo = FakeReviewRepo();

    await tester.pumpWidget(
      _buildTestApp(
        place: testPlace,
        authRepo: authRepo,
        favRepo: favRepo,
        reviewRepo: reviewRepo,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Marble Mountains'), findsOneWidget);
    expect(find.text('ATTRACTION'), findsOneWidget);
    expect(find.text('Hoa Hai, Ngu Hanh Son, Da Nang'), findsOneWidget);
    expect(find.text('Cluster of five marble and limestone hills.'), findsOneWidget);
    expect(find.text('07:00 - 17:30'), findsOneWidget);
    expect(find.text('4.7'), findsAtLeastNWidgets(1));
    expect(find.text('(24)'), findsOneWidget);
    expect(find.text('Community Reviews'), findsOneWidget);
    expect(find.byKey(const Key('write_review_button')), findsOneWidget);
  });

  testWidgets('PlaceDetailScreen renders empty state when no reviews exist', (tester) async {
    final authRepo = FakeAuthRepo(authenticated: false);
    final favRepo = FakeFavRepo();
    final reviewRepo = FakeReviewRepo(reviews: []);

    await tester.pumpWidget(
      _buildTestApp(
        place: testPlace,
        authRepo: authRepo,
        favRepo: favRepo,
        reviewRepo: reviewRepo,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No reviews yet'), findsOneWidget);
    expect(
      find.text('Be the first to share your experience with this place!'),
      findsOneWidget,
    );
  });

  testWidgets('PlaceDetailScreen renders community reviews list when reviews exist', (tester) async {
    final reviews = [
      ReviewModel(
        id: 'rev-1',
        userId: 'u-1',
        authorName: 'Hoang Nam',
        rating: 5,
        comment: 'Incredible caves and pagodas inside!',
        createdAt: DateTime(2026, 11, 1),
      ),
    ];

    final authRepo = FakeAuthRepo(authenticated: false);
    final favRepo = FakeFavRepo();
    final reviewRepo = FakeReviewRepo(reviews: reviews);

    await tester.pumpWidget(
      _buildTestApp(
        place: testPlace,
        authRepo: authRepo,
        favRepo: favRepo,
        reviewRepo: reviewRepo,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hoang Nam'), findsOneWidget);
    expect(find.text('Incredible caves and pagodas inside!'), findsOneWidget);
  });

  testWidgets('tapping Write a Review while unauthenticated displays sign-in prompt', (tester) async {
    final authRepo = FakeAuthRepo(authenticated: false);
    final favRepo = FakeFavRepo();
    final reviewRepo = FakeReviewRepo();

    await tester.pumpWidget(
      _buildTestApp(
        place: testPlace,
        authRepo: authRepo,
        favRepo: favRepo,
        reviewRepo: reviewRepo,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('write_review_button')));
    await tester.pumpAndSettle();

    expect(find.text('Please sign in to submit a review.'), findsOneWidget);
  });

  testWidgets('tapping Write a Review while authenticated opens ReviewFormBottomSheet', (tester) async {
    final authRepo = FakeAuthRepo(authenticated: true);
    final favRepo = FakeFavRepo();
    final reviewRepo = FakeReviewRepo();

    final reviewBloc = ReviewBloc(reviewRepository: reviewRepo);
    addTearDown(reviewBloc.close);

    await tester.pumpWidget(
      _buildTestApp(
        place: testPlace,
        authRepo: authRepo,
        favRepo: favRepo,
        reviewRepo: reviewRepo,
        reviewBloc: reviewBloc,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('write_review_button')));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewFormBottomSheet), findsOneWidget);
    expect(find.text('Review Marble Mountains'), findsOneWidget);
  });
}
