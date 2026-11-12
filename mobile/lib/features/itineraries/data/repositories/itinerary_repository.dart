import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/itinerary_model.dart';
import '../models/itinerary_request_model.dart';

/// Contract definition for Itinerary Data Operations.
/// Decouples BLoC state management from HTTP networking.
abstract class ItineraryRepository {
  /// Retrieves a paginated list of itineraries owned by the authenticated user.
  Future<List<ItineraryModel>> getItineraries({
    int page = 0,
    int size = 10,
    String sort = 'createdAt,desc',
  });

  /// Retrieves full itinerary details with scheduled items and nested places by ID.
  Future<ItineraryModel> getItineraryDetail(String id);

  /// Creates a new itinerary with optional scheduled items.
  Future<ItineraryModel> createItinerary(ItineraryRequestModel request);

  /// Updates itinerary metadata and replaces scheduled items.
  Future<ItineraryModel> updateItinerary(
    String id,
    ItineraryRequestModel request,
  );

  /// Deletes an itinerary and cascade-deletes its items.
  Future<void> deleteItinerary(String id);
}

/// Concrete implementation of ItineraryRepository using DioClient.
class ItineraryRepositoryImpl implements ItineraryRepository {
  final DioClient _dioClient;

  ItineraryRepositoryImpl({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  @override
  Future<List<ItineraryModel>> getItineraries({
    int page = 0,
    int size = 10,
    String sort = 'createdAt,desc',
  }) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.itineraries,
        queryParameters: {
          ApiEndpoints.paramPage: page,
          ApiEndpoints.paramSize: size,
          ApiEndpoints.paramSort: sort,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['content'] is List) {
        final contentList = data['content'] as List<dynamic>;
        return contentList
            .map((item) =>
                ItineraryModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<ItineraryModel> getItineraryDetail(String id) async {
    try {
      final response = await _dioClient.get(ApiEndpoints.itineraryDetails(id));
      return ItineraryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<ItineraryModel> createItinerary(ItineraryRequestModel request) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.itineraries,
        data: request.toJson(),
      );
      return ItineraryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<ItineraryModel> updateItinerary(
    String id,
    ItineraryRequestModel request,
  ) async {
    try {
      final response = await _dioClient.put(
        ApiEndpoints.itineraryDetails(id),
        data: request.toJson(),
      );
      return ItineraryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<void> deleteItinerary(String id) async {
    try {
      await _dioClient.delete(ApiEndpoints.itineraryDetails(id));
    } on DioException {
      rethrow;
    }
  }
}
