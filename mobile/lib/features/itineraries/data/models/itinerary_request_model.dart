import 'package:equatable/equatable.dart';

import 'itinerary_item_model.dart';
import 'itinerary_model.dart';

/// Request Payload Model for creating or updating an Itinerary.
/// Matches Backend ItineraryRequest contract (docs/API_SPECIFICATION.md § 4.2).
class ItineraryRequestModel extends Equatable {
  final String title;
  final String? description;
  final String? startDate;
  final String? endDate;
  final bool isPublic;
  final List<ItineraryItemModel> items;

  const ItineraryRequestModel({
    required this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.isPublic = false,
    this.items = const [],
  });

  /// Factory helper to build request from existing ItineraryModel
  factory ItineraryRequestModel.fromItinerary(ItineraryModel itinerary) {
    return ItineraryRequestModel(
      title: itinerary.title,
      description: itinerary.description,
      startDate: itinerary.startDate,
      endDate: itinerary.endDate,
      isPublic: itinerary.isPublic,
      items: itinerary.items,
    );
  }

  /// Deserialization from JSON Map
  factory ItineraryRequestModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final itemsList = (rawItems is List)
        ? rawItems
            .map((e) => ItineraryItemModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <ItineraryItemModel>[];

    return ItineraryRequestModel(
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      items: itemsList,
    );
  }

  /// Serializes request matching Backend ItineraryRequest validation expectations
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (description != null) 'description': description,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'isPublic': isPublic,
      'items': items.map((e) => e.toRequestJson()).toList(),
    };
  }

  ItineraryRequestModel copyWith({
    String? title,
    String? description,
    String? startDate,
    String? endDate,
    bool? isPublic,
    List<ItineraryItemModel>? items,
  }) {
    return ItineraryRequestModel(
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isPublic: isPublic ?? this.isPublic,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
        title,
        description,
        startDate,
        endDate,
        isPublic,
        items,
      ];
}

