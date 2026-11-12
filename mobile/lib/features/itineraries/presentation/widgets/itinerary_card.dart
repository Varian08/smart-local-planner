import 'package:flutter/material.dart';

import '../../data/models/itinerary_model.dart';

/// Reusable Card component representing a saved Itinerary summary.
/// Follows Material 3 card styling with trip metadata badges and delete action.
class ItineraryCard extends StatelessWidget {
  final ItineraryModel itinerary;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ItineraryCard({
    super.key,
    required this.itinerary,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDates = (itinerary.startDate != null &&
            itinerary.startDate!.isNotEmpty) &&
        (itinerary.endDate != null && itinerary.endDate!.isNotEmpty);

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title & Delete Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      color: Colors.indigo,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itinerary.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hasDates) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${itinerary.startDate} → ${itinerary.endDate}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red.shade400,
                        size: 22,
                      ),
                      tooltip: 'Delete itinerary',
                      onPressed: onDelete,
                    ),
                ],
              ),

              // Description if present
              if (itinerary.description != null &&
                  itinerary.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  itinerary.description!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Bottom Badges: Total Days & Places Count
              Row(
                children: [
                  _buildBadge(
                    context,
                    icon: Icons.timelapse_rounded,
                    label:
                        '${itinerary.totalDays} ${itinerary.totalDays == 1 ? 'day' : 'days'}',
                    color: Colors.indigo,
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(
                    context,
                    icon: Icons.place_rounded,
                    label:
                        '${itinerary.totalPlaces} ${itinerary.totalPlaces == 1 ? 'place' : 'places'}',
                    color: Colors.teal,
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              fontWeight: FontWeight.w600,
              color: color.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
