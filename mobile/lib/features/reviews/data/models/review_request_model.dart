import 'package:equatable/equatable.dart';

/// Request DTO for submitting a place review and rating.
/// Maps 1-to-1 with Backend ReviewRequest DTO contract (docs/API_SPECIFICATION.md § 5.2).
class ReviewRequestModel extends Equatable {
  final int rating;
  final String? comment;

  const ReviewRequestModel({
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'rating': rating,
    };
    if (comment != null && comment!.trim().isNotEmpty) {
      map['comment'] = comment!.trim();
    }
    return map;
  }

  @override
  List<Object?> get props => [rating, comment];
}
