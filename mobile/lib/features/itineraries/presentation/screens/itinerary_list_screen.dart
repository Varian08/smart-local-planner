import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/itinerary_bloc.dart';
import '../../bloc/itinerary_event.dart';
import '../../bloc/itinerary_state.dart';
import '../../data/models/itinerary_model.dart';
import '../../data/repositories/itinerary_repository.dart';
import '../widgets/create_itinerary_dialog.dart';
import '../widgets/itinerary_card.dart';
import 'itinerary_detail_screen.dart';

/// Primary Presentation Screen displaying the user's travel itineraries.
/// Strictly adheres to the enterprise Mandatory 4-State UI Contract:
/// 1. LoadingState: Non-blocking shimmer skeleton.
/// 2. SuccessState: Populated List of ItineraryCards with pull-to-refresh.
/// 3. EmptyState: High-contrast empty graphic with 'Create Trip' action button.
/// 4. ErrorState: Informative error banner with actionable 'Try Again' button.
class ItineraryListScreen extends StatelessWidget {
  const ItineraryListScreen({super.key});

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ItineraryBloc>(),
        child: const CreateItineraryDialog(),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ItineraryModel itinerary) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Itinerary?'),
        content: Text(
          'Are you sure you want to delete "${itinerary.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ItineraryBloc>().add(DeleteItinerary(itinerary.id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.route_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Text(
              'My Itineraries',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            key: const Key('itinerary_add_appbar_button'),
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: Colors.indigo),
            tooltip: 'Create Itinerary',
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('itinerary_create_fab'),
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Trip'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<ItineraryBloc, ItineraryState>(
        listener: (context, state) {
          if (state is ItineraryOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
              ),
            );
            // Refresh itineraries list on successful operation
            context
                .read<ItineraryBloc>()
                .add(const LoadItineraries(isRefresh: true));
          } else if (state is ItineraryFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: BlocBuilder<ItineraryBloc, ItineraryState>(
              builder: (context, state) {
                // -------------------------------------------------------------
                // State 1: Loading
                // -------------------------------------------------------------
                if (state is ItineraryLoading || state is ItineraryInitial) {
                  return _buildLoadingSkeleton();
                }

                // -------------------------------------------------------------
                // State 2: Error
                // -------------------------------------------------------------
                if (state is ItineraryFailure) {
                  if (state.itineraries.isNotEmpty) {
                    return _buildItineraryListView(context, state.itineraries);
                  }
                  return _buildErrorView(context, state.message);
                }

                // -------------------------------------------------------------
                // State 3 & 4: Loaded (Success or Empty)
                // -------------------------------------------------------------
                if (state is ItineraryLoaded) {
                  if (state.itineraries.isEmpty) {
                    return _buildEmptyView(context);
                  }

                  return _buildItineraryListView(context, state.itineraries);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItineraryListView(
    BuildContext context,
    List<ItineraryModel> itineraries,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<ItineraryBloc>()
            .add(const LoadItineraries(isRefresh: true));
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        itemCount: itineraries.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final itinerary = itineraries[index];
          return ItineraryCard(
            itinerary: itinerary,
            onTap: () {
              final parentBloc = context.read<ItineraryBloc>();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RepositoryProvider<ItineraryRepository>.value(
                    value: parentBloc.itineraryRepository,
                    child: ItineraryDetailScreen(
                      itineraryId: itinerary.id,
                    ),
                  ),
                ),
              );
            },
            onDelete: () => _confirmDelete(context, itinerary),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Loading Skeleton
  // ---------------------------------------------------------------------------
  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      key: const Key('itinerary_loading_skeleton'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 140,
                            height: 16,
                            color: Colors.grey.shade200,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 180,
                            height: 12,
                            color: Colors.grey.shade200,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 70,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Empty State View
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
                Icons.map_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Travel Itineraries Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Plan your dream vacation by creating a multi-day trip with scheduled stops and visits.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('itinerary_empty_create_button'),
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Your First Trip'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
  // 3. Error State View
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
              'Failed to Load Itineraries',
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
                context
                    .read<ItineraryBloc>()
                    .add(const LoadItineraries(isRefresh: true));
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
