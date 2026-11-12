import 'package:equatable/equatable.dart';

import 'itinerary_item_model.dart';

/// Enterprise Data Model representing a Multi-Day Travel Itinerary.
/// Maps 1-to-1 with Backend ItineraryResponse and ItinerarySummaryResponse contracts.
class ItineraryModel extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? startDate;
  final String? endDate;
  final int totalDays;
  final int totalPlaces;
  final bool isPublic;
  final List<ItineraryItemModel> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ItineraryModel({
    required this.id,
    required this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.totalDays = 1,
    this.totalPlaces = 0,
    this.isPublic = false,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to safely deserialize JSON received from Backend API
  factory ItineraryModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final itemsList = (rawItems is List)
        ? rawItems
            .map((e) => ItineraryItemModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <ItineraryItemModel>[];

    return ItineraryModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      totalDays: (json['totalDays'] as num?)?.toInt() ?? 1,
      totalPlaces:
          (json['totalPlaces'] as num?)?.toInt() ?? itemsList.length,
      isPublic: json['isPublic'] as bool? ?? false,
      items: itemsList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Full JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'totalDays': totalDays,
      'totalPlaces': totalPlaces,
      'isPublic': isPublic,
      'items': items.map((e) => e.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Request payload serialization for create/update requests
  Map<String, dynamic> toRequestJson() {
    return {
      'title': title,
      if (description != null) 'description': description,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'isPublic': isPublic,
      'items': items.map((e) => e.toRequestJson()).toList(),
    };
  }

  ItineraryModel copyWith({
    String? id,
    String? title,
    String? description,
    String? startDate,
    String? endDate,
    int? totalDays,
    int? totalPlaces,
    bool? isPublic,
    List<ItineraryItemModel>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItineraryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      totalPlaces: totalPlaces ?? this.totalPlaces,
      isPublic: isPublic ?? this.isPublic,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        startDate,
        endDate,
        totalDays,
        totalPlaces,
        isPublic,
        items,
        createdAt,
        updatedAt,
      ];
}
