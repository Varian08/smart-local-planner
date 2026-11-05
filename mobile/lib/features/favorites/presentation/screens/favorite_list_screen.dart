import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../places/presentation/widgets/place_card.dart';
import '../../bloc/favorite_bloc.dart';
import '../../bloc/favorite_event.dart';
import '../../bloc/favorite_state.dart';

/// Presentation Screen displaying the authenticated user's curated favorite places.
/// Strictly adheres to the enterprise Mandatory 4-State UI Contract:
/// 1. LoadingState: Non-blocking shimmer skeleton.
/// 2. SuccessState: Populated List with pull-to-refresh (RefreshIndicator).
/// 3. EmptyState: Friendly empty-state graphic with 'Explore Places' navigation button.
/// 4. ErrorState: Informative error banner with actionable 'Retry' button.
class FavoriteListScreen extends StatelessWidget {
  const FavoriteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bookmark_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Text(
              'Saved Places',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: BlocBuilder<FavoriteBloc, FavoriteState>(
            builder: (context, state) {
              // ---------------------------------------------------------------
              // State 1: Loading
              // ---------------------------------------------------------------
              if (state is FavoriteLoading || state is FavoriteInitial) {
                return _buildLoadingSkeleton();
              }

              // ---------------------------------------------------------------
              // State 2: Error
              // ---------------------------------------------------------------
              if (state is FavoriteFailure) {
                return _buildErrorView(context, state.message);
              }

              // ---------------------------------------------------------------
              // State 3 & 4: Loaded (Success or Empty)
              // ---------------------------------------------------------------
              if (state is FavoriteLoaded) {
                if (state.favorites.isEmpty) {
                  return _buildEmptyView(context);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<FavoriteBloc>().add(const FavoriteFetchStarted());
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    itemCount: state.favorites.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final place = state.favorites[index];
                      return PlaceCard(place: place);
                    },
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Loading Skeleton / Shimmer Loader
  // ---------------------------------------------------------------------------
  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      key: const Key('favorite_loading_skeleton'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 160,
                      height: 18,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 220,
                      height: 14,
                      color: Colors.grey.shade200,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Empty State View with 'Explore Places' Action
  // ---------------------------------------------------------------------------
  Widget _buildEmptyView(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Saved Places Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on any place card to bookmark your dream destinations for quick access.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Explore Places'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Error State View with Actionable 'Retry' Button
  // ---------------------------------------------------------------------------
  Widget _buildErrorView(BuildContext context, String message) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to Load Favorites',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                context.read<FavoriteBloc>().add(const FavoriteFetchStarted());
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
