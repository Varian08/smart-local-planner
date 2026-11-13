import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/features/reviews/data/models/review_model.dart';
import 'package:smart_local_planner/features/reviews/data/models/review_request_model.dart';

void main() {
  group('ReviewModel Unit Tests', () {
    test('fromJson and toJson deserialize and serialize complete review object', () {
      final json = {
        'id': 'rev-1',
        'userId': 'user-123',
        'authorName': 'Nguyen Van A',
        'authorAvatar': 'https://example.com/avatar.jpg',
        'rating': 5,
        'comment': 'Stunning view and peaceful ambience!',
        'createdAt': '2026-10-15T14:20:00.000Z',
      };

      final review = ReviewModel.fromJson(json);

      expect(review.id, 'rev-1');
      expect(review.userId, 'user-123');
      expect(review.authorName, 'Nguyen Van A');
      expect(review.authorAvatar, 'https://example.com/avatar.jpg');
      expect(review.rating, 5);
      expect(review.comment, 'Stunning view and peaceful ambience!');
      expect(review.createdAt, isNotNull);
      expect(review.createdAt!.year, 2026);

      final serialized = review.toJson();
      expect(serialized['id'], 'rev-1');
      expect(serialized['userId'], 'user-123');
      expect(serialized['authorName'], 'Nguyen Van A');
      expect(serialized['authorAvatar'], 'https://example.com/avatar.jpg');
      expect(serialized['rating'], 5);
      expect(serialized['comment'], 'Stunning view and peaceful ambience!');
      expect(serialized['createdAt'], contains('2026-10-15'));
    });

    test('fromJson handles null or missing optional fields gracefully', () {
      final json = <String, dynamic>{
        'id': 'rev-2',
        'userId': 'user-456',
        'rating': 4,
      };

      final review = ReviewModel.fromJson(json);

      expect(review.id, 'rev-2');
      expect(review.userId, 'user-456');
      expect(review.authorName, 'Anonymous');
      expect(review.authorAvatar, isNull);
      expect(review.rating, 4);
      expect(review.comment, isNull);
      expect(review.createdAt, isNull);
    });

    test('copyWith updates fields while preserving unmutated properties', () {
      const original = ReviewModel(
        id: 'rev-3',
        userId: 'user-789',
        authorName: 'Original Author',
        rating: 3,
        comment: 'Initial feedback',
      );

      final updated = original.copyWith(
        rating: 5,
        comment: 'Updated feedback',
      );

      expect(updated.id, 'rev-3');
      expect(updated.userId, 'user-789');
      expect(updated.authorName, 'Original Author');
      expect(updated.rating, 5);
      expect(updated.comment, 'Updated feedback');
    });

    test('Equatable value equality compares props identically', () {
      const review1 = ReviewModel(
        id: 'rev-4',
        userId: 'user-1',
        authorName: 'User',
        rating: 5,
      );
      const review2 = ReviewModel(
        id: 'rev-4',
        userId: 'user-1',
        authorName: 'User',
        rating: 5,
      );

      expect(review1, equals(review2));
    });
  });

  group('ReviewRequestModel Unit Tests', () {
    test('toJson produces valid request payload with comment', () {
      const request = ReviewRequestModel(
        rating: 5,
        comment: 'Exceptional service and friendly staff!',
      );

      final json = request.toJson();
      expect(json['rating'], 5);
      expect(json['comment'], 'Exceptional service and friendly staff!');
    });

    test('toJson produces valid request payload omitting empty comment', () {
      const request = ReviewRequestModel(
        rating: 4,
        comment: '   ',
      );

      final json = request.toJson();
      expect(json['rating'], 4);
      expect(json.containsKey('comment'), isFalse);
    });

    test('Equatable value equality compares props identically', () {
      const req1 = ReviewRequestModel(rating: 5, comment: 'Nice');
      const req2 = ReviewRequestModel(rating: 5, comment: 'Nice');

      expect(req1, equals(req2));
    });
  });
}
