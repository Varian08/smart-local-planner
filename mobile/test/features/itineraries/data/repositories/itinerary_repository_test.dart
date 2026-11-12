import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/core/network/dio_client.dart';
import 'package:smart_local_planner/features/itineraries/data/models/itinerary_item_model.dart';
import 'package:smart_local_planner/features/itineraries/data/models/itinerary_request_model.dart';
import 'package:smart_local_planner/features/itineraries/data/repositories/itinerary_repository.dart';

class FakeDioClient extends Fake implements DioClient {
  Response<dynamic>? mockGetResponse;
  Response<dynamic>? mockPostResponse;
  Response<dynamic>? mockPutResponse;
  Response<dynamic>? mockDeleteResponse;
  DioException? mockError;

  String? lastGetPath;
  Map<String, dynamic>? lastGetParams;
  String? lastPostPath;
  dynamic lastPostData;
  String? lastPutPath;
  dynamic lastPutData;
  String? lastDeletePath;

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

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPutPath = path;
    lastPutData = data;
    if (mockError != null) throw mockError!;
    return mockPutResponse as Response<T>;
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
  late ItineraryRepository repository;

  setUp(() {
    fakeDioClient = FakeDioClient();
    repository = ItineraryRepositoryImpl(dioClient: fakeDioClient);
  });

  group('ItineraryRepository Tests', () {
    test('getItineraries returns parsed list of itineraries from PageResponse', () async {
      fakeDioClient.mockGetResponse = Response(
        requestOptions: RequestOptions(path: '/itineraries'),
        statusCode: 200,
        data: {
          'content': [
            {
              'id': 'itin-1',
              'title': 'Trip 1',
              'totalDays': 2,
              'totalPlaces': 3,
            },
            {
              'id': 'itin-2',
              'title': 'Trip 2',
              'totalDays': 1,
              'totalPlaces': 1,
            },
          ],
          'pageNumber': 0,
          'pageSize': 10,
          'totalElements': 2,
          'totalPages': 1,
          'isLast': true,
        },
      );

      final result = await repository.getItineraries(page: 0, size: 10);

      expect(result.length, 2);
      expect(result[0].id, 'itin-1');
      expect(result[0].title, 'Trip 1');
      expect(result[1].id, 'itin-2');
      expect(fakeDioClient.lastGetPath, '/itineraries');
      expect(fakeDioClient.lastGetParams?['page'], 0);
      expect(fakeDioClient.lastGetParams?['size'], 10);
    });

    test('getItineraries returns empty list when content is absent or empty', () async {
      fakeDioClient.mockGetResponse = Response(
        requestOptions: RequestOptions(path: '/itineraries'),
        statusCode: 200,
        data: {
          'content': [],
          'pageNumber': 0,
        },
      );

      final result = await repository.getItineraries();
      expect(result, isEmpty);
    });

    test('getItineraryDetail calls /itineraries/{id} and parses full detail', () async {
      fakeDioClient.mockGetResponse = Response(
        requestOptions: RequestOptions(path: '/itineraries/itin-100'),
        statusCode: 200,
        data: {
          'id': 'itin-100',
          'title': 'Danang Highlights',
          'description': 'Coastal tour',
          'items': [
            {
              'id': 'item-1',
              'dayNumber': 1,
              'orderIndex': 0,
              'startTime': '09:00:00',
              'place': {
                'id': 'p-1',
                'name': 'My Khe Beach',
                'category': 'NATURE',
                'address': 'Danang',
              },
            },
          ],
        },
      );

      final result = await repository.getItineraryDetail('itin-100');

      expect(result.id, 'itin-100');
      expect(result.title, 'Danang Highlights');
      expect(result.items.length, 1);
      expect(result.items[0].place?.name, 'My Khe Beach');
      expect(fakeDioClient.lastGetPath, '/itineraries/itin-100');
    });

    test('createItinerary calls POST /itineraries with request payload', () async {
      fakeDioClient.mockPostResponse = Response(
        requestOptions: RequestOptions(path: '/itineraries'),
        statusCode: 201,
        data: {
          'id': 'new-itin-id',
          'title': 'New Vacation',
          'totalDays': 2,
        },
      );

      final request = ItineraryRequestModel(
        title: 'New Vacation',
        description: 'Sunny days',
        startDate: '2026-11-25',
        endDate: '2026-11-26',
        items: [
          const ItineraryItemModel(
            placeId: 'p-123',
            dayNumber: 1,
            orderIndex: 0,
          ),
        ],
      );

      final created = await repository.createItinerary(request);

      expect(created.id, 'new-itin-id');
      expect(created.title, 'New Vacation');
      expect(fakeDioClient.lastPostPath, '/itineraries');
      expect(fakeDioClient.lastPostData['title'], 'New Vacation');
      expect((fakeDioClient.lastPostData['items'] as List).length, 1);
    });

    test('updateItinerary calls PUT /itineraries/{id} with request payload', () async {
      fakeDioClient.mockPutResponse = Response(
        requestOptions: RequestOptions(path: '/itineraries/itin-99'),
        statusCode: 200,
        data: {
          'id': 'itin-99',
          'title': 'Updated Title',
        },
      );

      const request = ItineraryRequestModel(
        title: 'Updated Title',
      );

      final updated = await repository.updateItinerary('itin-99', request);

      expect(updated.id, 'itin-99');
      expect(updated.title, 'Updated Title');
      expect(fakeDioClient.lastPutPath, '/itineraries/itin-99');
      expect(fakeDioClient.lastPutData['title'], 'Updated Title');
    });

    test('deleteItinerary calls DELETE /itineraries/{id}', () async {
      fakeDioClient.mockDeleteResponse = Response(
        requestOptions: RequestOptions(path: '/itineraries/itin-to-del'),
        statusCode: 204,
      );

      await repository.deleteItinerary('itin-to-del');

      expect(fakeDioClient.lastDeletePath, '/itineraries/itin-to-del');
    });

    test('propagates DioException on failure', () async {
      fakeDioClient.mockError = DioException(
        requestOptions: RequestOptions(path: '/itineraries'),
        response: Response(
          requestOptions: RequestOptions(path: '/itineraries'),
          statusCode: 403,
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        () => repository.getItineraries(),
        throwsA(isA<DioException>()),
      );
    });
  });
}
