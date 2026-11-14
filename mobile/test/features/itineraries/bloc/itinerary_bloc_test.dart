import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/features/itineraries/bloc/itinerary_bloc.dart';
import 'package:smart_local_planner/features/itineraries/bloc/itinerary_event.dart';
import 'package:smart_local_planner/features/itineraries/bloc/itinerary_state.dart';
import 'package:smart_local_planner/features/itineraries/data/models/itinerary_item_model.dart';
import 'package:smart_local_planner/features/itineraries/data/models/itinerary_model.dart';
import 'package:smart_local_planner/features/itineraries/data/models/itinerary_request_model.dart';
import 'package:smart_local_planner/features/itineraries/data/repositories/itinerary_repository.dart';

class MockItineraryRepository implements ItineraryRepository {
  List<ItineraryModel> itinerariesToReturn = [];
  ItineraryModel? detailToReturn;
  ItineraryModel? createdToReturn;
  ItineraryModel? updatedToReturn;
  Object? shouldThrow;

  int getItinerariesCallCount = 0;
  String? lastDetailId;
  ItineraryRequestModel? lastCreatedRequest;
  ItineraryRequestModel? lastUpdatedRequest;
  String? lastDeletedId;

  @override
  Future<List<ItineraryModel>> getItineraries({
    int page = 0,
    int size = 10,
    String sort = 'createdAt,desc',
  }) async {
    getItinerariesCallCount++;
    if (shouldThrow != null) throw shouldThrow!;
    return itinerariesToReturn;
  }

  @override
  Future<ItineraryModel> getItineraryDetail(String id) async {
    lastDetailId = id;
    if (shouldThrow != null) throw shouldThrow!;
    return detailToReturn ?? ItineraryModel(id: id, title: 'Detail Mock');
  }

  @override
  Future<ItineraryModel> createItinerary(ItineraryRequestModel request) async {
    lastCreatedRequest = request;
    if (shouldThrow != null) throw shouldThrow!;
    return createdToReturn ??
        ItineraryModel(id: 'created-id', title: request.title);
  }

  @override
  Future<ItineraryModel> updateItinerary(
    String id,
    ItineraryRequestModel request,
  ) async {
    lastUpdatedRequest = request;
    if (shouldThrow != null) throw shouldThrow!;
    return updatedToReturn ??
        ItineraryModel(id: id, title: request.title);
  }

  @override
  Future<void> deleteItinerary(String id) async {
    lastDeletedId = id;
    if (shouldThrow != null) throw shouldThrow!;
  }
}

void main() {
  late MockItineraryRepository mockRepository;
  late ItineraryBloc itineraryBloc;

  setUp(() {
    mockRepository = MockItineraryRepository();
    itineraryBloc = ItineraryBloc(itineraryRepository: mockRepository);
  });

  tearDown(() {
    itineraryBloc.close();
  });

  group('ItineraryBloc - LoadItineraries', () {
    test('initial state is ItineraryInitial', () {
      expect(itineraryBloc.state, const ItineraryInitial());
    });

    test('emits [ItineraryLoading, ItineraryLoaded] on successful fetch', () async {
      final mockList = [
        const ItineraryModel(id: 'itin-1', title: 'Hoi An Discovery'),
        const ItineraryModel(id: 'itin-2', title: 'Hue Heritage Tour'),
      ];
      mockRepository.itinerariesToReturn = mockList;

      expectLater(
        itineraryBloc.stream,
        emitsInOrder([
          const ItineraryLoading(),
          ItineraryLoaded(itineraries: mockList, page: 0, hasMore: false),
        ]),
      );

      itineraryBloc.add(const LoadItineraries(page: 0, size: 10));
    });

    test('appends items when page > 0 and state is already ItineraryLoaded', () async {
      final initialList = [
        const ItineraryModel(id: 'itin-1', title: 'Trip 1'),
      ];
      final page2List = [
        const ItineraryModel(id: 'itin-2', title: 'Trip 2'),
      ];

      mockRepository.itinerariesToReturn = initialList;
      itineraryBloc.add(const LoadItineraries(page: 0, size: 1));
      await expectLater(
        itineraryBloc.stream,
        emitsThrough(
          ItineraryLoaded(itineraries: initialList, page: 0, hasMore: true),
        ),
      );

      mockRepository.itinerariesToReturn = page2List;
      itineraryBloc.add(const LoadItineraries(page: 1, size: 1));

      await expectLater(
        itineraryBloc.stream,
        emits(
          ItineraryLoaded(
            itineraries: [...initialList, ...page2List],
            page: 1,
            hasMore: true,
          ),
        ),
      );
    });

    test('emits [ItineraryLoading, ItineraryFailure] on DioException', () async {
      mockRepository.shouldThrow = DioException(
        requestOptions: RequestOptions(path: '/itineraries'),
        response: Response(
          requestOptions: RequestOptions(path: '/itineraries'),
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      );

      expectLater(
        itineraryBloc.stream,
        emitsInOrder([
          const ItineraryLoading(),
          const ItineraryFailure(
            message: 'An unexpected network error occurred.',
            statusCode: 500,
          ),
        ]),
      );

      itineraryBloc.add(const LoadItineraries());
    });
  });

  group('ItineraryBloc - LoadItineraryDetail', () {
    test('emits [ItineraryLoading, ItineraryDetailLoaded] on success', () async {
      const detail = ItineraryModel(
        id: 'detail-id-1',
        title: 'Detail Title',
        items: [
          ItineraryItemModel(dayNumber: 1, orderIndex: 0),
        ],
      );
      mockRepository.detailToReturn = detail;

      expectLater(
        itineraryBloc.stream,
        emitsInOrder([
          const ItineraryLoading(),
          const ItineraryDetailLoaded(detail),
        ]),
      );

      itineraryBloc.add(const LoadItineraryDetail('detail-id-1'));
    });

    test('emits [ItineraryLoading, ItineraryFailure] on 404 Not Found', () async {
      mockRepository.shouldThrow = DioException(
        requestOptions: RequestOptions(path: '/itineraries/missing'),
        response: Response(
          requestOptions: RequestOptions(path: '/itineraries/missing'),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      );

      expectLater(
        itineraryBloc.stream,
        emitsInOrder([
          const ItineraryLoading(),
          const ItineraryFailure(
            message: 'Itinerary not found.',
            statusCode: 404,
          ),
        ]),
      );

      itineraryBloc.add(const LoadItineraryDetail('missing'));
    });
  });

  group('ItineraryBloc - CreateItinerary', () {
    test('emits [ItineraryLoading, ItineraryOperationSuccess] on success', () async {
      const request = ItineraryRequestModel(title: 'New Trip');
      const created = ItineraryModel(id: 'created-1', title: 'New Trip');
      mockRepository.createdToReturn = created;

      expectLater(
        itineraryBloc.stream,
        emitsInOrder([
          const ItineraryLoading(),
          const ItineraryOperationSuccess(
            message: 'Itinerary created successfully',
            itinerary: created,
          ),
        ]),
      );

      itineraryBloc.add(const CreateItinerary(request));
    });

    test('emits [ItineraryLoading, ItineraryFailure] on 400 validation error', () async {
      mockRepository.shouldThrow = DioException(
        requestOptions: RequestOptions(path: '/itineraries'),
        response: Response(
          requestOptions: RequestOptions(path: '/itineraries'),
          statusCode: 400,
          data: {'message': 'Title cannot be blank'},
        ),
        type: DioExceptionType.badResponse,
      );

      expectLater(
        itineraryBloc.stream,
        emitsInOrder([
          const ItineraryLoading(),
          const ItineraryFailure(
            message: 'Title cannot be blank',
            statusCode: 400,
          ),
        ]),
      );

      itineraryBloc.add(const CreateItinerary(ItineraryRequestModel(title: '')));
    });
  });

  group('ItineraryBloc - UpdateItinerary', () {
    test('emits [ItineraryLoading, ItineraryOperationSuccess] on success', () async {
      const request = ItineraryRequestModel(title: 'Updated Trip');
      const updated = ItineraryModel(id: 'itin-up', title: 'Updated Trip');
      mockRepository.updatedToReturn = updated;

      expectLater(
        itineraryBloc.stream,
        emitsInOrder([
          const ItineraryLoading(),
          const ItineraryOperationSuccess(
            message: 'Itinerary updated successfully',
            itinerary: updated,
          ),
        ]),
      );

      itineraryBloc.add(
        const UpdateItinerary(id: 'itin-up', request: request),
      );
    });

    test('emits [ItineraryLoading, ItineraryFailure] on 403 Forbidden', () async {
      mockRepository.shouldThrow = DioException(
        requestOptions: RequestOptions(path: '/itineraries/other-user-itin'),
        response: Response(
          requestOptions: RequestOptions(path: '/itineraries/other-user-itin'),
          statusCode: 403,
        ),
        type: DioExceptionType.badResponse,
      );

      expectLater(
        itineraryBloc.stream,
        emitsInOrder([
          const ItineraryLoading(),
          const ItineraryFailure(
            message:
                'You do not have permission to access or modify this itinerary.',
            statusCode: 403,
          ),
        ]),
      );

      itineraryBloc.add(
        const UpdateItinerary(
          id: 'other-user-itin',
          request: ItineraryRequestModel(title: 'Hack'),
        ),
      );
    });
  });

  group('ItineraryBloc - DeleteItinerary', () {
    test('emits [ItineraryLoading, ItineraryOperationSuccess] on success', () async {
      expectLater(
        itineraryBloc.stream,
        emitsInOrder([
          const ItineraryLoading(),
          const ItineraryOperationSuccess(
            message: 'Itinerary deleted successfully',
            deletedId: 'del-123',
          ),
        ]),
      );

      itineraryBloc.add(const DeleteItinerary('del-123'));
    });

    test('emits [ItineraryLoading, ItineraryFailure] on 401 Unauthorized', () async {
      mockRepository.shouldThrow = DioException(
        requestOptions: RequestOptions(path: '/itineraries/del-123'),
        response: Response(
          requestOptions: RequestOptions(path: '/itineraries/del-123'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );

      expectLater(
        itineraryBloc.stream,
        emitsInOrder([
          const ItineraryLoading(),
          const ItineraryFailure(
            message: 'Session expired. Please sign in again.',
            statusCode: 401,
          ),
        ]),
      );

      itineraryBloc.add(const DeleteItinerary('del-123'));
    });

    test('preserves loaded itineraries when delete operation fails', () async {
      final mockList = [
        const ItineraryModel(id: 'itin-preserve-1', title: 'Existing Trip'),
      ];
      mockRepository.itinerariesToReturn = mockList;

      // 1. Initial successful load
      itineraryBloc.add(const LoadItineraries());
      await expectLater(
        itineraryBloc.stream,
        emitsThrough(
          ItineraryLoaded(itineraries: mockList, page: 0, hasMore: false),
        ),
      );

      // 2. Delete fails
      mockRepository.shouldThrow = Exception('Network error during delete');

      expectLater(
        itineraryBloc.stream,
        emitsInOrder([
          const ItineraryLoading(),
          ItineraryFailure(
            message: 'Failed to delete itinerary: Exception: Network error during delete',
            itineraries: mockList,
          ),
        ]),
      );

      itineraryBloc.add(const DeleteItinerary('itin-preserve-1'));
    });
  });
}

