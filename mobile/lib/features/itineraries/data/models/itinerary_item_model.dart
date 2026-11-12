import 'package:equatable/equatable.dart';

import '../../../places/data/models/place_model.dart';

/// Enterprise Data Model representing an individual scheduled item in an itinerary.
/// Aligns with Backend ItineraryItemResponse and ItineraryItemRequest DTO contracts.
class ItineraryItemModel extends Equatable {
  final String? id;
  final String? placeId;
  final int dayNumber;
  final int orderIndex;
  final String? startTime;
  final String? notes;
  final PlaceModel? place;

  const ItineraryItemModel({
    this.id,
    this.placeId,
    required this.dayNumber,
    required this.orderIndex,
    this.startTime,
    this.notes,
    this.place,
  });

  /// Factory constructor to safely deserialize JSON received from Backend API
  factory ItineraryItemModel.fromJson(Map<String, dynamic> json) {
    final placeJson = json['place'] as Map<String, dynamic>?;
    return ItineraryItemModel(
      id: json['id'] as String?,
      placeId: json['placeId'] as String? ??
          (placeJson != null ? placeJson['id'] as String? : null),
      dayNumber: (json['dayNumber'] as num?)?.toInt() ?? 1,
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      startTime: json['startTime'] as String?,
      notes: json['notes'] as String?,
      place: placeJson != null ? PlaceModel.fromJson(placeJson) : null,
    );
  }

  /// Full JSON serialization including nested place
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'placeId': placeId ?? place?.id,
      'dayNumber': dayNumber,
      'orderIndex': orderIndex,
      if (startTime != null) 'startTime': startTime,
      if (notes != null) 'notes': notes,
      if (place != null) 'place': place!.toJson(),
    };
  }

  /// Request JSON serialization matching Backend ItineraryItemRequest
  Map<String, dynamic> toRequestJson() {
    final resolvedPlaceId = placeId ?? place?.id;
    return {
      'placeId': resolvedPlaceId,
      'dayNumber': dayNumber,
      'orderIndex': orderIndex,
      if (startTime != null) 'startTime': startTime,
      if (notes != null) 'notes': notes,
    };
  }

  ItineraryItemModel copyWith({
    String? id,
    String? placeId,
    int? dayNumber,
    int? orderIndex,
    String? startTime,
    String? notes,
    PlaceModel? place,
  }) {
    return ItineraryItemModel(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      dayNumber: dayNumber ?? this.dayNumber,
      orderIndex: orderIndex ?? this.orderIndex,
      startTime: startTime ?? this.startTime,
      notes: notes ?? this.notes,
      place: place ?? this.place,
    );
  }

  @override
  List<Object?> get props => [
        id,
        placeId,
        dayNumber,
        orderIndex,
        startTime,
        notes,
        place,
      ];
}

