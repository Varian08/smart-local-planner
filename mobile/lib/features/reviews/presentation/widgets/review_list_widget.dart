import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/models/review_model.dart';
import 'star_rating_widget.dart';

/// Renders the community reviews list, rating distribution summary, and empty state.
class ReviewListWidget extends StatelessWidget {
  final List<ReviewModel> reviews;
  final double averageRating;
  final int totalReviews;

  const ReviewListWidget({
    super.key,
    required this.reviews,
    this.averageRating = 0.0,
    this.totalReviews = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRatingSummary(context),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => Divider(
            height: 24,
            thickness: 0.8,
            color: Colors.grey.shade200,
          ),
          itemBuilder: (context, index) {
            return _buildReviewItem(context, reviews[index]);
          },
        ),
      ],
    );
  }

  Widget _buildRatingSummary(BuildContext context) {
    final hasAuthoritativeTotal =
        totalReviews > 0 && totalReviews >= reviews.length;
    final effectiveRating = hasAuthoritativeTotal && averageRating > 0
        ? averageRating
        : (reviews.isNotEmpty
            ? reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                reviews.length
            : (averageRating > 0 ? averageRating : 0.0));
    final count = hasAuthoritativeTotal ? totalReviews : reviews.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade100),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    effectiveRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ 5.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              StarRatingWidget(
                rating: effectiveRating.round(),
                size: 18,
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count ${count == 1 ? "review" : "reviews"}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Community Rating',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, ReviewModel review) {
    final dateStr = review.createdAt != null
        ? '${review.createdAt!.year}-${review.createdAt!.month.toString().padLeft(2, '0')}-${review.createdAt!.day.toString().padLeft(2, '0')}'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildAvatar(review),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.authorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            StarRatingWidget(
              rating: review.rating,
              size: 16,
            ),
          ],
        ),
        if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            review.comment!.trim(),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatar(ReviewModel review) {
    final avatarUrl = review.authorAvatar;
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: CachedNetworkImageProvider(avatarUrl.trim()),
      );
    }

    final initial = review.authorName.isNotEmpty
        ? review.authorName.characters.first.toUpperCase()
        : 'U';
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.teal.shade100,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.teal.shade900,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Be the first to share your experience with this place!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
