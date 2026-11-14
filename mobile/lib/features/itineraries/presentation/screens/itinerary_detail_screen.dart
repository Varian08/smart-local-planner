import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/itinerary_bloc.dart';
import '../../bloc/itinerary_event.dart';
import '../../bloc/itinerary_state.dart';
import '../../data/models/itinerary_item_model.dart';
import '../../data/models/itinerary_model.dart';
import '../../data/repositories/itinerary_repository.dart';

/// Screen displaying full multi-day itinerary timeline with tabbed day-by-day navigation.
/// Conforms to the enterprise Mandatory 4-State UI Contract.
class ItineraryDetailScreen extends StatelessWidget {
  final String itineraryId;
  final ItineraryBloc? itineraryBloc;

  const ItineraryDetailScreen({
    super.key,
    required this.itineraryId,
    this.itineraryBloc,
  });

  @override
  Widget build(BuildContext context) {
    if (itineraryBloc != null) {
      return BlocProvider<ItineraryBloc>.value(
        value: itineraryBloc!,
        child: _ItineraryDetailContent(itineraryId: itineraryId),
      );
    }

    try {
      final repository = context.read<ItineraryRepository>();
      return BlocProvider<ItineraryBloc>(
        create: (context) => ItineraryBloc(itineraryRepository: repository),
        child: _ItineraryDetailContent(itineraryId: itineraryId),
      );
    } catch (_) {
      return _ItineraryDetailContent(itineraryId: itineraryId);
    }
  }
}

class _ItineraryDetailContent extends StatefulWidget {
  final String itineraryId;

  const _ItineraryDetailContent({required this.itineraryId});

  @override
  State<_ItineraryDetailContent> createState() => _ItineraryDetailContentState();
}

class _ItineraryDetailContentState extends State<_ItineraryDetailContent> {
  int _selectedDay = 1;

  @override
  void initState() {
    super.initState();
    context.read<ItineraryBloc>().add(LoadItineraryDetail(widget.itineraryId));
  }

  void _onRefresh() {
    context.read<ItineraryBloc>().add(LoadItineraryDetail(widget.itineraryId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Itinerary Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: BlocBuilder<ItineraryBloc, ItineraryState>(
        builder: (context, state) {
          // 1. Loading State
          if (state is ItineraryLoading || state is ItineraryInitial) {
            return _buildLoadingSkeleton();
          }

          // 2. Error State
          if (state is ItineraryFailure) {
            return _buildErrorView(context, state.message);
          }

          // 3. Success State
          if (state is ItineraryDetailLoaded) {
            return _buildDetailContent(context, state.itinerary);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, ItineraryModel itinerary) {
    final totalDays = itinerary.totalDays > 0 ? itinerary.totalDays : 1;
    final dayItems = itinerary.items
        .where((item) => item.dayNumber == _selectedDay)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return RefreshIndicator(
      onRefresh: () async => _onRefresh(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header Card
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itinerary.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (itinerary.description != null &&
                      itinerary.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      itinerary.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                        icon: Icons.calendar_today_rounded,
                        label:
                            '${itinerary.totalDays} ${itinerary.totalDays == 1 ? 'Day' : 'Days'}',
                        color: Colors.indigo,
                      ),
                      _buildChip(
                        icon: Icons.place_rounded,
                        label:
                            '${itinerary.totalPlaces} ${itinerary.totalPlaces == 1 ? 'Place' : 'Places'}',
                        color: Colors.teal,
                      ),
                      if (itinerary.startDate != null)
                        _buildChip(
                          icon: Icons.date_range_rounded,
                          label:
                              '${itinerary.startDate} → ${itinerary.endDate ?? ''}',
                          color: Colors.purple,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Multi-Day Tab Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(totalDays, (index) {
                final dayNum = index + 1;
                final isSelected = dayNum == _selectedDay;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    key: Key('itinerary_day_chip_$dayNum'),
                    label: Text(
                      'Day $dayNum',
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.indigo,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDay = dayNum;
                        });
                      }
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Day Timeline Items
          if (dayItems.isEmpty)
            _buildEmptyDayView(_selectedDay)
          else
            ...dayItems.map((item) => _buildTimelineCard(context, item)),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, ItineraryItemModel item) {
    final theme = Theme.of(context);
    final place = item.place;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order sequence circle
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.indigo,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${item.orderIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Thumbnail if available
              if (place?.imageUrl != null &&
                  place!.imageUrl!.trim().isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: CachedNetworkImage(
                      imageUrl: place.imageUrl!.trim(),
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.photo, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Place Details & Notes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.startTime != null &&
                        item.startTime!.trim().isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 14, color: Colors.indigo.shade400),
                          const SizedBox(width: 4),
                          Text(
                            item.startTime!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      place?.name ?? 'Scheduled Stop',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (place?.address != null &&
                        place!.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        place.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    if (item.notes != null &&
                        item.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Text(
                          item.notes!.trim(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.brown.shade800,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDayView(int dayNum) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.event_note_rounded,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No places scheduled for Day $dayNum',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Explore places and add them to this day\'s schedule.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      key: const Key('itinerary_detail_loading_skeleton'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(
            3,
            (_) => Container(
              width: 70,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          2,
          (_) => Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: Colors.red.shade400),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Itinerary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
