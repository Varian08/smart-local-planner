import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/place_bloc.dart';
import '../../bloc/place_event.dart';
import '../../bloc/place_state.dart';
import '../../data/models/place_model.dart';

/// Primary Place Discovery Screen implementing the mandatory 4-state UI contract.
/// Renders search query input, category filter chips, and responsive place cards with cached artwork.
class PlaceListScreen extends StatelessWidget {
  const PlaceListScreen({super.key});

  // ---------------------------------------------------------------------------
  // 1. Screen Scaffold & Reactive State Builder
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.explore_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Text(
              'Smart Local Planner',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
          ],
        ),
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
      ),
      body: Center(
        // Responsive Container constraint: Keeps layout elegant on wide desktop monitors
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              _buildSearchBar(context),
              _buildCategoryFilters(context),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<PlaceBloc, PlaceState>(
                  builder: (context, state) {
                    // State 1: Loading
                    if (state is PlaceLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // State 2: Empty
                    if (state is PlaceEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // State 3: Error with Retry Mechanism
                    if (state is PlaceError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 64,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.read<PlaceBloc>().add(
                                    const PlaceFetchStarted(),
                                  );
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // State 4: Success Loaded List with Pull-to-Refresh
                    if (state is PlaceLoaded) {
                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<PlaceBloc>().add(
                            const PlaceFetchStarted(),
                          );
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: state.places.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return _buildPlaceCard(context, state.places[index]);
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Search Input Component
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search places, attractions, cafes in Da Nang...',
          prefixIcon: const Icon(Icons.search, color: Colors.indigo),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onSubmitted: (query) {
          context.read<PlaceBloc>().add(PlaceSearchQueryChanged(query));
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Category Filter Chips Component (Aligned with Backend Enums)
  // ---------------------------------------------------------------------------
  Widget _buildCategoryFilters(BuildContext context) {
    const categories = [
      'ALL',
      'ATTRACTION',
      'CULTURE',
      'NATURE',
      'BEACH',
      'FOOD',
      'CAFE',
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return ActionChip(
            label: Text(
              cat,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            backgroundColor: Colors.grey.shade100,
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () {
              final selected = cat == 'ALL' ? null : cat;
              context.read<PlaceBloc>().add(PlaceCategoryChanged(selected));
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Place Card Component (Modern Traveloka / Airbnb Aesthetic)
  // ---------------------------------------------------------------------------
  Widget _buildPlaceCard(BuildContext context, PlaceModel place) {
    final effectivePriceLevel = place.priceLevel ?? 1;
    final priceIcons = List.generate(
      effectivePriceLevel,
      (_) => const Text(
        '₫',
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Place Artwork with AspectRatio & Category Overlay
          Stack(
            children: [
              if (place.imageUrl != null && place.imageUrl!.isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: place.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade100,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_outlined, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 6),
                            Text(
                              'Photo preview unavailable',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // Category Pill Badge overlay
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    place.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            place.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        place.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                if (place.description != null && place.description!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    place.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Price: ',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Row(children: priceIcons),
                      ],
                    ),
                    Text(
                      '${place.totalReviews} reviews',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
