import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/place_model.dart';

/// Contract definition for Place Data Operations.
/// Enables mockability and decouples business logic from concrete network implementations.
abstract class PlaceRepository {
  /// Fetches a paginated list of places with optional search and filter criteria
  Future<List<PlaceModel>> getPlaces({
    String? query,
    String? category,
    int? priceLevel,
    int page = 0,
    int size = 10,
    String sort = 'averageRating,desc',
  });

  /// Fetches detailed information of a single place by its unique ID
  Future<PlaceModel> getPlaceById(String id);
}

/// Concrete implementation of PlaceRepository using DioClient.
class PlaceRepositoryImpl implements PlaceRepository {
  final DioClient _dioClient;

  PlaceRepositoryImpl({DioClient? dioClient})
    : _dioClient = dioClient ?? DioClient();

  // ---------------------------------------------------------------------------
  // 1. Fetch Paginated Places
  // ---------------------------------------------------------------------------
  @override
  Future<List<PlaceModel>> getPlaces({
    String? query,
    String? category,
    int? priceLevel,
    int page = 0,
    int size = 10,
    String sort = 'averageRating,desc',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        ApiEndpoints.paramPage: page,
        ApiEndpoints.paramSize: size,
        ApiEndpoints.paramSort: sort,
      };

      if (query != null && query.trim().isNotEmpty) {
        queryParams[ApiEndpoints.paramQuery] = query.trim();
      }
      if (category != null && category.trim().isNotEmpty) {
        queryParams[ApiEndpoints.paramCategory] = category.trim();
      }
      if (priceLevel != null) {
        queryParams[ApiEndpoints.paramPriceLevel] = priceLevel;
      }

      final response = await _dioClient.get(
        ApiEndpoints.places,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['content'] is List) {
        final contentList = data['content'] as List<dynamic>;
        return contentList
            .map((item) => PlaceModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException {
      // Propagate exception to be handled by presentation BLoC
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Fetch Place Details By ID
  // ---------------------------------------------------------------------------
  @override
  Future<PlaceModel> getPlaceById(String id) async {
    try {
      final response = await _dioClient.get(ApiEndpoints.placeDetails(id));
      return PlaceModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }
}
