import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/core/network/dio_client.dart';
import 'package:smart_local_planner/features/favorites/data/repositories/favorite_repository.dart';

class FakeDioClient extends Fake implements DioClient {
  Response<dynamic>? mockGetResponse;
  Response<dynamic>? mockPostResponse;
  Response<dynamic>? mockDeleteResponse;
  DioException? mockError;
  String? lastGetPath;
  String? lastPostPath;
  String? lastDeletePath;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastGetPath = path;
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
    if (mockError != null) throw mockError!;
    return mockPostResponse as Response<T>;
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastDeletePath = path;
    if (mockError != null) throw mockError!;
    return mockDeleteResponse as Response<T>;
  }
}

void main() {
  late FakeDioClient fakeDioClient;
  late FavoriteRepository repository;

  setUp(() {
    fakeDioClient = FakeDioClient();
    repository = FavoriteRepositoryImpl(dioClient: fakeDioClient);
  });

  group('FavoriteRepository Tests', () {
    test('getFavorites returns parsed list of places', () async {
      fakeDioClient.mockGetResponse = Response(
        requestOptions: RequestOptions(path: '/favorites'),
        statusCode: 200,
        data: [
          {
            'id': 'place-1',
            'name': 'Bà Nà Hills',
            'category': 'ATTRACTION',
            'address': 'Đà Nẵng',
            'averageRating': 4.8,
            'totalReviews': 150,
          },
          {
            'id': 'place-2',
            'name': 'Cầu Rồng',
            'category': 'ATTRACTION',
            'address': 'Đà Nẵng',
            'averageRating': 4.9,
            'totalReviews': 300,
          },
        ],
      );

      final result = await repository.getFavorites();

      expect(result.length, 2);
      expect(result[0].id, 'place-1');
      expect(result[0].name, 'Bà Nà Hills');
      expect(result[1].id, 'place-2');
      expect(fakeDioClient.lastGetPath, '/favorites');
    });

    test('getFavorites returns empty list when response is empty', () async {
      fakeDioClient.mockGetResponse = Response(
        requestOptions: RequestOptions(path: '/favorites'),
        statusCode: 200,
        data: [],
      );

      final result = await repository.getFavorites();

      expect(result, isEmpty);
    });

    test('addFavorite calls POST /favorites/{placeId}', () async {
      fakeDioClient.mockPostResponse = Response(
        requestOptions: RequestOptions(path: '/favorites/place-123'),
        statusCode: 201,
        data: {'message': 'Place added to favorites.'},
      );

      await repository.addFavorite('place-123');

      expect(fakeDioClient.lastPostPath, '/favorites/place-123');
    });

    test('removeFavorite calls DELETE /favorites/{placeId}', () async {
      fakeDioClient.mockDeleteResponse = Response(
        requestOptions: RequestOptions(path: '/favorites/place-123'),
        statusCode: 200,
        data: {'message': 'Place removed from favorites.'},
      );

      await repository.removeFavorite('place-123');

      expect(fakeDioClient.lastDeletePath, '/favorites/place-123');
    });

    test('propagates DioException on network failure', () async {
      fakeDioClient.mockError = DioException(
        requestOptions: RequestOptions(path: '/favorites/place-999'),
        type: DioExceptionType.connectionTimeout,
      );

      expect(
        () => repository.addFavorite('place-999'),
        throwsA(isA<DioException>()),
      );
    });
  });
}

