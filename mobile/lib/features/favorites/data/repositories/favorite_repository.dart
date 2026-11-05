import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../places/data/models/place_model.dart';

/// Contract definition for Favorite Places Data Operations.
/// Decouples BLoC state management from HTTP networking.
abstract class FavoriteRepository {
  /// Retrieves all favorite places saved by the authenticated user.
  Future<List<PlaceModel>> getFavorites();

  /// Adds a place to user's favorites by its unique placeId.
  Future<void> addFavorite(String placeId);

  /// Removes a place from user's favorites by its unique placeId.
  Future<void> removeFavorite(String placeId);
}

/// Concrete implementation of FavoriteRepository using DioClient.
class FavoriteRepositoryImpl implements FavoriteRepository {
  final DioClient _dioClient;

  FavoriteRepositoryImpl({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  @override
  Future<List<PlaceModel>> getFavorites() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.favorites);
      final data = response.data;
      if (data is List) {
        return data
            .map((item) => PlaceModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<void> addFavorite(String placeId) async {
    try {
      await _dioClient.post(ApiEndpoints.favoritePlace(placeId));
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<void> removeFavorite(String placeId) async {
    try {
      await _dioClient.delete(ApiEndpoints.favoritePlace(placeId));
    } on DioException {
      rethrow;
    }
  }
}

