import 'package:flutter_test/flutter_test.dart';
import 'package:dowa/features/farms/data/models/farm_model.dart';
import 'package:dowa/features/farms/domain/entities/farm.dart';

void main() {
  group('FarmModel', () {
    test('should create FarmModel from JSON', () {
      final json = {
        'id': 'farm-1',
        'userId': 'user-1',
        'name': 'Test Farm',
        'type': 'GRAPES',
        'polygon': [
          {'latitude': 36.7538, 'longitude': 3.0588},
          {'latitude': 36.7548, 'longitude': 3.0598},
        ],
        'area': 1000.0,
      };

      final farm = FarmModel.fromJson(json);

      expect(farm.id, equals('farm-1'));
      expect(farm.userId, equals('user-1'));
      expect(farm.name, equals('Test Farm'));
      expect(farm.type, equals(FarmType.grapes));
      expect(farm.polygon.length, equals(2));
      expect(farm.area, equals(1000.0));
    });

    test('should parse all farm types correctly', () {
      final types = ['GRAPES', 'WHEAT', 'CORN', 'TOMATOES', 'OLIVES', 'DATES'];
      final expectedTypes = [
        FarmType.grapes,
        FarmType.wheat,
        FarmType.corn,
        FarmType.tomatoes,
        FarmType.olives,
        FarmType.dates,
      ];

      for (var i = 0; i < types.length; i++) {
        final json = {
          'id': 'farm-1',
          'userId': 'user-1',
          'name': 'Test Farm',
          'type': types[i],
          'polygon': [],
          'area': 0.0,
        };

        final farm = FarmModel.fromJson(json);
        expect(farm.type, equals(expectedTypes[i]));
      }
    });

    test('should convert to JSON', () {
      const farm = FarmModel(
        id: 'farm-1',
        userId: 'user-1',
        name: 'Test Farm',
        type: FarmType.grapes,
        polygon: [
          LatLng(latitude: 36.7538, longitude: 3.0588),
        ],
        area: 1000.0,
      );

      final json = farm.toJson();

      expect(json['id'], equals('farm-1'));
      expect(json['name'], equals('Test Farm'));
      expect(json['type'], equals('GRAPES'));
      expect(json['polygon'], isA<List>());
      expect(json['area'], equals(1000.0));
    });

    test('should implement Farm entity', () {
      const farm = FarmModel(
        id: 'farm-1',
        userId: 'user-1',
        name: 'Test Farm',
        type: FarmType.grapes,
        polygon: [],
        area: 0.0,
      );

      expect(farm, isA<Farm>());
    });
  });
}

