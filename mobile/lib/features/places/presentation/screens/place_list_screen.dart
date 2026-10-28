import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/place_bloc.dart';
import '../../bloc/place_event.dart';
import '../../bloc/place_state.dart';
import '../../data/models/place_model.dart';

/// Primary Place Discovery Screen implementing the mandatory 4-state UI contract.
/// Features search query input, category filter chips with selected visual states,
/// and responsive place cards with infinite scroll pagination.
class PlaceListScreen extends StatefulWidget {
  const PlaceListScreen({super.key});

  @override
  State<PlaceListScreen> createState() => _PlaceListScreenState();
}

class _PlaceListScreenState extends State<PlaceListScreen> {
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<PlaceBloc>().add(const PlaceNextPageFetched());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Trigger next page when user has scrolled past 85% of content
    return currentScroll >= (maxScroll * 0.85);
  }

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
                              if (state.selectedCategory != null ||
                                  state.searchQuery != null) ...[
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    _searchController.clear();
                                    context.read<PlaceBloc>().add(
                                      const PlaceFetchStarted(),
                                    );
                                  },
                                  icon: const Icon(Icons.clear_all_rounded),
                                  label: const Text('Reset filters'),
                                ),
                              ],
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
                                    const PlaceRefreshRequested(),
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

                    // State 4: Success Loaded List with Pull-to-Refresh & Infinite Scroll
                    if (state is PlaceLoaded) {
                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<PlaceBloc>().add(
                            const PlaceRefreshRequested(),
                          );
                        },
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          itemCount:
                              state.hasReachedMax
                                  ? state.places.length
                                  : state.places.length + 1,
                          separatorBuilder:
                              (_, _) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index >= state.places.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.0),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return _buildPlaceCard(
                              context,
                              state.places[index],
                            );
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
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search places, attractions, cafes in Da Nang...',
          prefixIcon: const Icon(Icons.search, color: Colors.indigo),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                      context.read<PlaceBloc>().add(
                        const PlaceSearchQueryChanged(''),
                      );
                    },
                  )
                  : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (_) => setState(() {}),
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

    return BlocBuilder<PlaceBloc, PlaceState>(
      buildWhen: (prev, curr) {
        final prevCat =
            prev is PlaceLoaded
                ? prev.selectedCategory
                : (prev is PlaceEmpty ? prev.selectedCategory : null);
        final currCat =
            curr is PlaceLoaded
                ? curr.selectedCategory
                : (curr is PlaceEmpty ? curr.selectedCategory : null);
        return prevCat != currCat;
      },
      builder: (context, state) {
        final activeCategory =
            state is PlaceLoaded
                ? state.selectedCategory
                : (state is PlaceEmpty ? state.selectedCategory : null);

        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected =
                  (cat == 'ALL' && activeCategory == null) ||
                  (cat == activeCategory);

              return FilterChip(
                label: Text(
                  cat,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 12,
                    color:
                        isSelected
                            ? Colors.indigo.shade900
                            : Colors.grey.shade700,
                  ),
                ),
                selected: isSelected,
                showCheckmark: false,
                selectedColor: Colors.indigo.shade50,
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? Colors.indigo : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                onSelected: (_) {
                  final target =
                      cat == 'ALL' ? null : (isSelected ? null : cat);
                  context.read<PlaceBloc>().add(PlaceCategoryChanged(target));
                },
              );
            },
          ),
        );
      },
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
                    placeholder:
                        (context, url) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Colors.grey.shade100,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_outlined,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Photo preview unavailable',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Colors.amber,
                          ),
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
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        place.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (place.description != null &&
                    place.description!.isNotEmpty) ...[
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
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Row(children: priceIcons),
                      ],
                    ),
                    Text(
                      '${place.totalReviews} reviews',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
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
