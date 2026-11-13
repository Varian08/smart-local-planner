import 'package:flutter/material.dart';

/// Reusable Star Rating widget supporting both interactive selection and read-only display.
class StarRatingWidget extends StatelessWidget {
  final int rating;
  final ValueChanged<int>? onRatingChanged;
  final double size;
  final Color color;
  final Color unselectedColor;
  final int maxRating;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.onRatingChanged,
    this.size = 24.0,
    this.color = Colors.amber,
    this.unselectedColor = const Color(0xFFE0E0E0),
    this.maxRating = 5,
  });

  bool get isInteractive => onRatingChanged != null;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starValue = index + 1;
        final isFilled = starValue <= rating;

        final starIcon = Icon(
          isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: isFilled ? color : unselectedColor,
          size: size,
        );

        if (!isInteractive) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: starIcon,
          );
        }

        return InkWell(
          onTap: () => onRatingChanged!(starValue),
          borderRadius: BorderRadius.circular(size / 2),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: starIcon,
          ),
        );
      }),
    );
  }
}
