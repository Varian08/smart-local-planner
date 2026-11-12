import 'package:flutter_test/flutter_test.dart';
import 'package:smart_local_planner/features/itineraries/data/models/itinerary_item_model.dart';
import 'package:smart_local_planner/features/itineraries/data/models/itinerary_model.dart';
import 'package:smart_local_planner/features/itineraries/data/models/itinerary_request_model.dart';

void main() {
  group('ItineraryItemModel Serialization Tests', () {
    test('fromJson and toJson deserialize and serialize complete item', () {
      final json = {
        'id': 'item-1',
        'placeId': 'place-1',
        'dayNumber': 1,
        'orderIndex': 0,
        'startTime': '09:00:00',
        'notes': 'Coffee stop',
        'place': {
          'id': 'place-1',
          'name': 'Bà Nà Hills',
          'category': 'ATTRACTION',
          'address': 'Da Nang, Vietnam',
          'averageRating': 4.8,
          'totalReviews': 120,
        },
      };

      final item = ItineraryItemModel.fromJson(json);

      expect(item.id, 'item-1');
      expect(item.placeId, 'place-1');
      expect(item.dayNumber, 1);
      expect(item.orderIndex, 0);
      expect(item.startTime, '09:00:00');
      expect(item.notes, 'Coffee stop');
      expect(item.place, isNotNull);
      expect(item.place!.name, 'Bà Nà Hills');

      final serialized = item.toJson();
      expect(serialized['id'], 'item-1');
      expect(serialized['placeId'], 'place-1');
      expect(serialized['dayNumber'], 1);
      expect(serialized['orderIndex'], 0);
      expect(serialized['startTime'], '09:00:00');
      expect(serialized['notes'], 'Coffee stop');
      expect(serialized['place'], isNotNull);

      final requestJson = item.toRequestJson();
      expect(requestJson['placeId'], 'place-1');
      expect(requestJson['dayNumber'], 1);
      expect(requestJson['orderIndex'], 0);
      expect(requestJson['startTime'], '09:00:00');
      expect(requestJson['notes'], 'Coffee stop');
      expect(requestJson.containsKey('place'), isFalse);
    });

    test('fromJson resolves placeId from nested place when placeId is absent', () {
      final json = {
        'dayNumber': 2,
        'orderIndex': 1,
        'place': {
          'id': 'place-nested-id',
          'name': 'Cầu Rồng',
          'category': 'ATTRACTION',
          'address': 'Da Nang, Vietnam',
        },
      };

      final item = ItineraryItemModel.fromJson(json);
      expect(item.placeId, 'place-nested-id');
      expect(item.dayNumber, 2);
      expect(item.orderIndex, 1);
      expect(item.startTime, isNull);
      expect(item.notes, isNull);
    });

    test('copyWith produces updated instance preserving untouched fields', () {
      const item = ItineraryItemModel(
        id: 'orig-id',
        placeId: 'orig-place',
        dayNumber: 1,
        orderIndex: 0,
        startTime: '10:00:00',
      );

      final updated = item.copyWith(
        dayNumber: 2,
        notes: 'Updated note',
      );

      expect(updated.id, 'orig-id');
      expect(updated.placeId, 'orig-place');
      expect(updated.dayNumber, 2);
      expect(updated.orderIndex, 0);
      expect(updated.startTime, '10:00:00');
      expect(updated.notes, 'Updated note');
    });
  });

  group('ItineraryModel Serialization Tests', () {
    test('fromJson and toJson handle complete response payload', () {
      final json = {
        'id': 'itinerary-123',
        'title': 'Weekend in Danang',
        'description': 'Exploring bridges and mountains.',
        'startDate': '2026-11-20',
        'endDate': '2026-11-22',
        'totalDays': 3,
        'totalPlaces': 2,
        'isPublic': true,
        'items': [
          {
            'id': 'item-1',
            'placeId': 'place-1',
            'dayNumber': 1,
            'orderIndex': 0,
            'startTime': '08:30:00',
          },
          {
            'id': 'item-2',
            'placeId': 'place-2',
            'dayNumber': 1,
            'orderIndex': 1,
            'startTime': '13:00:00',
          },
        ],
        'createdAt': '2026-11-12T10:00:00Z',
        'updatedAt': '2026-11-12T10:30:00Z',
      };

      final model = ItineraryModel.fromJson(json);

      expect(model.id, 'itinerary-123');
      expect(model.title, 'Weekend in Danang');
      expect(model.description, 'Exploring bridges and mountains.');
      expect(model.startDate, '2026-11-20');
      expect(model.endDate, '2026-11-22');
      expect(model.totalDays, 3);
      expect(model.totalPlaces, 2);
      expect(model.isPublic, isTrue);
      expect(model.items.length, 2);
      expect(model.createdAt, isNotNull);
      expect(model.updatedAt, isNotNull);

      final serialized = model.toJson();
      expect(serialized['id'], 'itinerary-123');
      expect(serialized['title'], 'Weekend in Danang');
      expect((serialized['items'] as List).length, 2);

      final reqJson = model.toRequestJson();
      expect(reqJson['title'], 'Weekend in Danang');
      expect(reqJson.containsKey('id'), isFalse);
    });

    test('fromJson handles minimal summary payload without items gracefully', () {
      final json = {
        'id': 'itinerary-summary',
        'title': 'Quick Trip',
      };

      final model = ItineraryModel.fromJson(json);

      expect(model.id, 'itinerary-summary');
      expect(model.title, 'Quick Trip');
      expect(model.description, isNull);
      expect(model.items, isEmpty);
      expect(model.totalDays, 1);
      expect(model.totalPlaces, 0);
      expect(model.isPublic, isFalse);
    });

    test('copyWith updates fields correctly', () {
      const model = ItineraryModel(
        id: 'i-1',
        title: 'Initial',
        totalDays: 1,
      );

      final updated = model.copyWith(
        title: 'New Title',
        totalDays: 4,
      );

      expect(updated.id, 'i-1');
      expect(updated.title, 'New Title');
      expect(updated.totalDays, 4);
    });
  });

  group('ItineraryRequestModel Serialization Tests', () {
    test('toJson produces valid request payload matching Backend expectations', () {
      final request = ItineraryRequestModel(
        title: 'Food Tour',
        description: 'Street food discovery',
        startDate: '2026-11-15',
        endDate: '2026-11-16',
        isPublic: false,
        items: [
          const ItineraryItemModel(
            placeId: 'place-food-1',
            dayNumber: 1,
            orderIndex: 0,
            startTime: '18:00:00',
            notes: 'Try Bánh xèo',
          ),
        ],
      );

      final json = request.toJson();

      expect(json['title'], 'Food Tour');
      expect(json['description'], 'Street food discovery');
      expect(json['startDate'], '2026-11-15');
      expect(json['endDate'], '2026-11-16');
      expect(json['isPublic'], false);
      expect((json['items'] as List).length, 1);
      expect((json['items'] as List)[0]['placeId'], 'place-food-1');
    });

    test('fromItinerary and fromJson work reversibly', () {
      const itinerary = ItineraryModel(
        id: 'i-1',
        title: 'From Itinerary',
        description: 'Some desc',
        startDate: '2026-12-01',
        endDate: '2026-12-05',
        isPublic: true,
        items: [],
      );

      final request = ItineraryRequestModel.fromItinerary(itinerary);
      expect(request.title, 'From Itinerary');
      expect(request.description, 'Some desc');
      expect(request.isPublic, isTrue);

      final recreated = ItineraryRequestModel.fromJson(request.toJson());
      expect(recreated.title, request.title);
      expect(recreated.startDate, request.startDate);
      expect(recreated.isPublic, request.isPublic);
    });
  });
}
