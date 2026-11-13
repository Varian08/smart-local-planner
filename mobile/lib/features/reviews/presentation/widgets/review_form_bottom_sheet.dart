import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/review_bloc.dart';
import '../../bloc/review_event.dart';
import '../../bloc/review_state.dart';
import '../../data/models/review_request_model.dart';
import 'star_rating_widget.dart';

/// Modal bottom sheet for composing and submitting a place review and rating.
class ReviewFormBottomSheet extends StatefulWidget {
  final String placeId;
  final String placeName;

  const ReviewFormBottomSheet({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  /// Static helper to present the bottom sheet with appropriate theme and padding.
  static Future<bool?> show(
    BuildContext context, {
    required String placeId,
    required String placeName,
  }) {
    final reviewBloc = context.read<ReviewBloc>();

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => BlocProvider.value(
        value: reviewBloc,
        child: ReviewFormBottomSheet(
          placeId: placeId,
          placeName: placeName,
        ),
      ),
    );
  }

  @override
  State<ReviewFormBottomSheet> createState() => _ReviewFormBottomSheetState();
}

class _ReviewFormBottomSheetState extends State<ReviewFormBottomSheet> {
  final _commentController = TextEditingController();
  int _selectedRating = 5;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String get _ratingLabel {
    switch (_selectedRating) {
      case 5:
        return '5 Stars - Outstanding';
      case 4:
        return '4 Stars - Very Good';
      case 3:
        return '3 Stars - Average';
      case 2:
        return '2 Stars - Poor';
      case 1:
        return '1 Star - Terrible';
      default:
        return 'Tap to rate';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocConsumer<ReviewBloc, ReviewState>(
      listener: (context, state) {
        if (state is ReviewSubmitSuccess) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is ReviewFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state is ReviewSubmitting;

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: bottomInset + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row with Handle & Close Button
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Review ${widget.placeName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Star Rating Picker
              Center(
                child: Column(
                  children: [
                    StarRatingWidget(
                      rating: _selectedRating,
                      size: 36,
                      onRatingChanged: isSubmitting
                          ? null
                          : (val) {
                              setState(() {
                                _selectedRating = val;
                              });
                            },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _ratingLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Comment Field
              TextField(
                controller: _commentController,
                enabled: !isSubmitting,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText:
                      'Share your experience, recommendations, or tips for fellow travelers...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.teal, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 16),

              // Submit Button
              ElevatedButton(
                onPressed: isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitReview() {
    final comment = _commentController.text.trim();
    context.read<ReviewBloc>().add(
          SubmitReview(
            placeId: widget.placeId,
            request: ReviewRequestModel(
              rating: _selectedRating,
              comment: comment.isNotEmpty ? comment : null,
            ),
          ),
        );
  }
}
