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
      List<dynamic>? items;
      if (data is Map<String, dynamic>) {
        if (data['content'] is List) {
          items = data['content'] as List<dynamic>;
        } else if (data['data'] is List) {
          items = data['data'] as List<dynamic>;
        }
      } else if (data is List) {
        items = data;
      }

      if (items != null) {
        return items
            .map((item) => ReviewModel.fromJson(item as Map<String, dynamic>))
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
