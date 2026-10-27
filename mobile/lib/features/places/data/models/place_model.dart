import 'package:equatable/equatable.dart';

/// Enterprise Data Model representing a Tourist Place.
/// Maps 1-to-1 with Backend PlaceResponse DTO contract and ensures value equality via Equatable.
class PlaceModel extends Equatable {
  // ---------------------------------------------------------------------------
  // 1. Model Properties (Direct contract parity with Backend PlaceResponse)
  // ---------------------------------------------------------------------------
  final String id;
  final String name;
  final String? description;
  final String category;
  final String address;
  final double? latitude;
  final double? longitude;
  final int? priceLevel;
  final String? openingHours;
  final String? imageUrl;
  final double averageRating;
  final int totalReviews;

  // ---------------------------------------------------------------------------
  // 2. Immutable Constructor
  // ---------------------------------------------------------------------------
  const PlaceModel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.address,
    this.latitude,
    this.longitude,
    this.priceLevel,
    this.openingHours,
    this.imageUrl,
    this.averageRating = 0.0,
    this.totalReviews = 0,
  });

  // ---------------------------------------------------------------------------
  // 3. JSON Deserialization & Serialization Factory
  // ---------------------------------------------------------------------------
  /// Deserializes JSON Map received from Backend REST API into a typed PlaceModel
  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      priceLevel: json['priceLevel'] as int?,
      openingHours: json['openingHours'] as String?,
      imageUrl: json['imageUrl'] as String?,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
    );
  }

  /// Serializes PlaceModel into a JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'priceLevel': priceLevel,
      'openingHours': openingHours,
      'imageUrl': imageUrl,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
    };
  }

  // ---------------------------------------------------------------------------
  // 4. Equatable Value Equality Props
  // ---------------------------------------------------------------------------
  @override
  List<Object?> get props => [
    id,
    name,
    description,
    category,
    address,
    latitude,
    longitude,
    priceLevel,
    openingHours,
    imageUrl,
    averageRating,
    totalReviews,
  ];
}
