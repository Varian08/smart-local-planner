import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/core/network/dio_client.dart';
import 'package:smart_local_planner/features/reviews/data/models/review_request_model.dart';
import 'package:smart_local_planner/features/reviews/data/repositories/review_repository.dart';

class FakeDioClient extends Fake implements DioClient {
  Response<dynamic>? mockGetResponse;
  Response<dynamic>? mockPostResponse;
  DioException? mockError;

  String? lastGetPath;
  Map<String, dynamic>? lastGetParams;
  String? lastPostPath;
  dynamic lastPostData;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastGetPath = path;
    lastGetParams = queryParameters;
    if (mockError != null) throw mockError!;
    return mockGetResponse as Response<T>;
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    if (mockError != null) throw mockError!;
    return mockPostResponse as Response<T>;
  }
}

void main() {
  late FakeDioClient fakeDio;
  late ReviewRepository repository;

  setUp(() {
    fakeDio = FakeDioClient();
    repository = ReviewRepositoryImpl(dioClient: fakeDio);
  });

  group('ReviewRepository getPlaceReviews Tests', () {
    test('parses paginated reviews with content key successfully', () async {
      fakeDio.mockGetResponse = Response(
        requestOptions: RequestOptions(path: '/places/p-1/reviews'),
        statusCode: 200,
        data: {
          'content': [
            {
              'id': 'rev-1',
              'userId': 'user-1',
              'authorName': 'Alice',
              'rating': 5,
              'comment': 'Amazing experience!',
              'createdAt': '2026-10-15T14:20:00Z',
            },
          ],
          'pageNumber': 0,
          'pageSize': 10,
          'totalElements': 1,
        },
      );

      final reviews = await repository.getPlaceReviews('p-1');

      expect(reviews.length, 1);
      expect(reviews.first.id, 'rev-1');
      expect(reviews.first.authorName, 'Alice');
      expect(reviews.first.rating, 5);
      expect(fakeDio.lastGetPath, '/places/p-1/reviews');
      expect(fakeDio.lastGetParams?['page'], 0);
      expect(fakeDio.lastGetParams?['size'], 10);
    });

    test('parses paginated reviews with data key defensively', () async {
      fakeDio.mockGetResponse = Response(
        requestOptions: RequestOptions(path: '/places/p-2/reviews'),
        statusCode: 200,
        data: {
          'data': [
            {
              'id': 'rev-2',
              'userId': 'user-2',
              'authorName': 'Bob',
              'rating': 4,
            },
          ],
        },
      );

      final reviews = await repository.getPlaceReviews('p-2');

      expect(reviews.length, 1);
      expect(reviews.first.id, 'rev-2');
      expect(reviews.first.authorName, 'Bob');
      expect(reviews.first.rating, 4);
    });

    test('rethrows DioException on network failure', () async {
      fakeDio.mockError = DioException(
        requestOptions: RequestOptions(path: '/places/p-err/reviews'),
        type: DioExceptionType.connectionTimeout,
        message: 'Timeout connecting to server',
      );

      expect(
        () => repository.getPlaceReviews('p-err'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('ReviewRepository submitReview Tests', () {
    test('submits review and parses created ReviewModel response', () async {
      fakeDio.mockPostResponse = Response(
        requestOptions: RequestOptions(path: '/places/p-1/reviews'),
        statusCode: 201,
        data: {
          'id': 'rev-new',
          'userId': 'user-me',
          'authorName': 'My Name',
          'rating': 5,
          'comment': 'Fresh review',
          'createdAt': '2026-11-13T10:00:00Z',
        },
      );

      const request = ReviewRequestModel(
        rating: 5,
        comment: 'Fresh review',
      );

      final created = await repository.submitReview('p-1', request);

      expect(created.id, 'rev-new');
      expect(created.rating, 5);
      expect(created.comment, 'Fresh review');
      expect(fakeDio.lastPostPath, '/places/p-1/reviews');
      expect(fakeDio.lastPostData?['rating'], 5);
    });

    test('rethrows 409 conflict DioException on duplicate review attempt', () async {
      fakeDio.mockError = DioException(
        requestOptions: RequestOptions(path: '/places/p-1/reviews'),
        response: Response(
          requestOptions: RequestOptions(path: '/places/p-1/reviews'),
          statusCode: 409,
          data: {
            'code': 'DUPLICATE_RESOURCE',
            'message': 'You have already reviewed this place.',
          },
        ),
      );

      const request = ReviewRequestModel(rating: 4);

      expect(
        () => repository.submitReview('p-1', request),
        throwsA(isA<DioException>()),
      );
    });
  });
}
