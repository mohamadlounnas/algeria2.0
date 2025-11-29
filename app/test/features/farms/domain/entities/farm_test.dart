import 'package:flutter_test/flutter_test.dart';
import 'package:dowa/features/farms/domain/entities/farm.dart';

void main() {
  group('Farm Entity', () {
    test('should create a farm with all properties', () {
      const farm = Farm(
        id: 'farm-1',
        userId: 'user-1',
        name: 'Test Farm',
        type: FarmType.grapes,
        polygon: [
          LatLng(latitude: 36.7538, longitude: 3.0588),
          LatLng(latitude: 36.7548, longitude: 3.0598),
        ],
        area: 1000.0,
      );

      expect(farm.id, equals('farm-1'));
      expect(farm.userId, equals('user-1'));
      expect(farm.name, equals('Test Farm'));
      expect(farm.type, equals(FarmType.grapes));
      expect(farm.polygon.length, equals(2));
      expect(farm.area, equals(1000.0));
    });

    test('should support all farm types', () {
      final types = [
        FarmType.grapes,
        FarmType.wheat,
        FarmType.corn,
        FarmType.tomatoes,
        FarmType.olives,
        FarmType.dates,
      ];

      for (final type in types) {
        final farm = Farm(
          id: 'farm-1',
          userId: 'user-1',
          name: 'Test Farm',
          type: type,
          polygon: const [],
          area: 0,
        );
        expect(farm.type, equals(type));
      }
    });

    test('should be equal when all properties match', () {
      const farm1 = Farm(
        id: 'farm-1',
        userId: 'user-1',
        name: 'Test Farm',
        type: FarmType.grapes,
        polygon: [],
        area: 1000.0,
      );

      const farm2 = Farm(
        id: 'farm-1',
        userId: 'user-1',
        name: 'Test Farm',
        type: FarmType.grapes,
        polygon: [],
        area: 1000.0,
      );

      expect(farm1, equals(farm2));
    });
  });

  group('LatLng Entity', () {
    test('should create LatLng with coordinates', () {
      const latLng = LatLng(latitude: 36.7538, longitude: 3.0588);
      expect(latLng.latitude, equals(36.7538));
      expect(latLng.longitude, equals(3.0588));
    });

    test('should be equal when coordinates match', () {
      const latLng1 = LatLng(latitude: 36.7538, longitude: 3.0588);
      const latLng2 = LatLng(latitude: 36.7538, longitude: 3.0588);
      expect(latLng1, equals(latLng2));
    });
  });
}

