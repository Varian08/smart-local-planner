import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/review_model.dart';
import '../models/review_request_model.dart';

/// Contract definition for Place Review Data Operations.
/// Decouples BLoC state management from HTTP networking.
abstract class ReviewRepository {
  /// Retrieves a paginated list of reviews for a specific place.
  Future<List<ReviewModel>> getPlaceReviews(
    String placeId, {
    int page = 0,
    int size = 10,
    String sort = 'createdAt,desc',
  });

  /// Submits a new review and rating for a specific place.
  Future<ReviewModel> submitReview(
    String placeId,
    ReviewRequestModel request,
  );
}

/// Concrete implementation of ReviewRepository using DioClient.
class ReviewRepositoryImpl implements ReviewRepository {
  final DioClient _dioClient;

  ReviewRepositoryImpl({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  @override
  Future<List<ReviewModel>> getPlaceReviews(
    String placeId, {
    int page = 0,
    int size = 10,
    String sort = 'createdAt,desc',
  }) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.placeReviews(placeId),
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
            .whereType<Map<String, dynamic>>()
            .map(ReviewModel.fromJson)
            .toList();
      }

      return [];
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<ReviewModel> submitReview(
    String placeId,
    ReviewRequestModel request,
  ) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.placeReviews(placeId),
        data: request.toJson(),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ReviewModel.fromJson(data);
      }
      throw Exception('Invalid response format received from review submission');
    } on DioException {
      rethrow;
    }
  }
}
