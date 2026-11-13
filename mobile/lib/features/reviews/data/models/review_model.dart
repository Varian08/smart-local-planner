import 'package:equatable/equatable.dart';

/// Enterprise Data Model representing a Place Review and Community Rating.
/// Maps 1-to-1 with Backend ReviewResponse DTO contract (docs/API_SPECIFICATION.md § 5).
class ReviewModel extends Equatable {
  final String id;
  final String userId;
  final String authorName;
  final String? authorAvatar;
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  const ReviewModel({
    required this.id,
    required this.userId,
    required this.authorName,
    this.authorAvatar,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  /// Factory constructor to safely deserialize JSON received from Backend API
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedCreatedAt;
    if (json['createdAt'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt'] as String);
    }

    return ReviewModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Anonymous',
      authorAvatar: json['authorAvatar'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] as String?,
      createdAt: parsedCreatedAt,
    );
  }

  /// Converts model to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// CopyWith helper for immutable state manipulations
  ReviewModel copyWith({
    String? id,
    String? userId,
    String? authorName,
    String? authorAvatar,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        authorName,
        authorAvatar,
        rating,
        comment,
        createdAt,
      ];
}
