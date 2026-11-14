import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/auth_guard.dart';
import '../../../favorites/bloc/favorite_bloc.dart';
import '../../../favorites/bloc/favorite_event.dart';
import '../../../favorites/bloc/favorite_state.dart';
import '../../../reviews/bloc/review_bloc.dart';
import '../../../reviews/bloc/review_event.dart';
import '../../../reviews/bloc/review_state.dart';
import '../../../reviews/data/models/review_model.dart';
import '../../../reviews/data/repositories/review_repository.dart';
import '../../../reviews/presentation/widgets/review_form_bottom_sheet.dart';
import '../../../reviews/presentation/widgets/review_list_widget.dart';
import '../../data/models/place_model.dart';

/// Screen presenting full place details, artwork, ratings, and community reviews.
class PlaceDetailScreen extends StatelessWidget {
  final PlaceModel place;
  final ReviewBloc? reviewBloc;

  const PlaceDetailScreen({
    super.key,
    required this.place,
    this.reviewBloc,
  });

  @override
  Widget build(BuildContext context) {
    if (reviewBloc != null) {
      return BlocProvider<ReviewBloc>.value(
        value: reviewBloc!,
        child: _PlaceDetailContent(place: place),
      );
    }

    return BlocProvider<ReviewBloc>(
      create: (context) => ReviewBloc(
        reviewRepository: context.read<ReviewRepository>(),
      )..add(LoadReviews(placeId: place.id)),
      child: _PlaceDetailContent(place: place),
    );
  }
}

class _PlaceDetailContent extends StatelessWidget {
  final PlaceModel place;

  const _PlaceDetailContent({required this.place});

  @override
  Widget build(BuildContext context) {
    final effectivePriceLevel = place.priceLevel ?? 1;
    final priceIcons = List.generate(
      effectivePriceLevel,
      (_) => const Text(
        '₫',
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Collapsible or Pinned App Bar with Hero Artwork
          SliverAppBar(
            expandedHeight: 260.0,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: BlocBuilder<FavoriteBloc, FavoriteState>(
                    builder: (context, favoriteState) {
                      final isFavorite = favoriteState is FavoriteLoaded &&
                          favoriteState.favoritePlaceIds.contains(place.id);

                      return IconButton(
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite ? Colors.redAccent : Colors.black87,
                        ),
                        onPressed: () {
                          requireAuth(
                            context,
                            message: 'Please sign in to save favorite places.',
                            onAuthenticated: () {
                              context.read<FavoriteBloc>().add(
                                    FavoriteToggleRequested(place),
                                  );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: (place.imageUrl != null &&
                      place.imageUrl!.trim().isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: place.imageUrl!.trim(),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildPlaceholderBanner(),
                    )
                  : _buildPlaceholderBanner(),
            ),
          ),

          // Main Place Information & Reviews Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Tag & Rating Badge
                  BlocBuilder<ReviewBloc, ReviewState>(
                    builder: (context, state) {
                      final reviews = state is ReviewLoaded
                          ? state.reviews
                          : (state is ReviewSubmitSuccess
                              ? state.reviews
                              : (state is ReviewFailure
                                  ? state.reviews
                                  : (state is ReviewSubmitting
                                      ? state.currentReviews
                                      : <ReviewModel>[])));

                      final effectiveRating = reviews.isNotEmpty
                          ? reviews
                                  .map((r) => r.rating)
                                  .reduce((a, b) => a + b) /
                              reviews.length
                          : place.averageRating;
                      final effectiveTotalReviews = reviews.isNotEmpty
                          ? reviews.length
                          : place.totalReviews;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.teal.shade200),
                            ),
                            child: Text(
                              place.category.toUpperCase(),
                              style: TextStyle(
                                color: Colors.teal.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                effectiveRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '($effectiveTotalReviews)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Place Title
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Address Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          place.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Price Level Row
                  Row(
                    children: [
                      Text(
                        'Price Level: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Row(children: priceIcons),
                    ],
                  ),

                  // Opening Hours (if present)
                  if (place.openingHours != null &&
                      place.openingHours!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            place.openingHours!.trim(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Description (if present)
                  if (place.description != null &&
                      place.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      place.description!.trim(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        height: 1.5,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),

                  // Community Reviews Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Community Reviews',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      OutlinedButton.icon(
                        key: const Key('write_review_button'),
                        onPressed: () {
                          requireAuth(
                            context,
                            message: 'Please sign in to submit a review.',
                            onAuthenticated: () {
                              ReviewFormBottomSheet.show(
                                context,
                                placeId: place.id,
                                placeName: place.name,
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.rate_review_outlined, size: 16),
                        label: const Text('Write a Review'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal,
                          side: const BorderSide(color: Colors.teal),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Reviews List Reactive State
                  BlocBuilder<ReviewBloc, ReviewState>(
                    builder: (context, state) {
                      if (state is ReviewLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (state is ReviewFailure && state.reviews.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            children: [
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<ReviewBloc>().add(
                                        LoadReviews(
                                          placeId: place.id,
                                          isRefresh: true,
                                        ),
                                      );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final reviews = state is ReviewLoaded
                          ? state.reviews
                          : (state is ReviewSubmitSuccess
                              ? state.reviews
                              : (state is ReviewFailure
                                  ? state.reviews
                                  : (state is ReviewSubmitting
                                      ? state.currentReviews
                                      : <ReviewModel>[])));

                      final effectiveRating = reviews.isNotEmpty
                          ? reviews
                                  .map((r) => r.rating)
                                  .reduce((a, b) => a + b) /
                              reviews.length
                          : place.averageRating;
                      final effectiveTotalReviews = reviews.isNotEmpty
                          ? reviews.length
                          : place.totalReviews;

                      return ReviewListWidget(
                        reviews: reviews,
                        averageRating: effectiveRating,
                        totalReviews: effectiveTotalReviews,
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderBanner() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_outlined,
              size: 50,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'No photo available',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
