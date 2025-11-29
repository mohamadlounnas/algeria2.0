import 'package:flutter_test/flutter_test.dart';
import 'package:dowa/features/farms/domain/dto/create_farm_request.dart';
import 'package:dowa/features/farms/domain/entities/farm.dart';

void main() {
  group('CreateFarmRequest', () {
    test('should create request with all required fields', () {
      final polygon = [
        LatLng(latitude: 36.7538, longitude: 3.0588),
        LatLng(latitude: 36.7540, longitude: 3.0590),
      ];

      final request = CreateFarmRequest(
        name: 'Test Farm',
        type: FarmType.grapes,
        polygon: polygon,
      );

      expect(request.name, 'Test Farm');
      expect(request.type, FarmType.grapes);
      expect(request.polygon.length, 2);
      expect(request.polygon[0].latitude, 36.7538);
    });

    test('should be equal when all properties match', () {
      final polygon1 = [
        LatLng(latitude: 36.7538, longitude: 3.0588),
      ];
      final polygon2 = [
        LatLng(latitude: 36.7538, longitude: 3.0588),
      ];

      final request1 = CreateFarmRequest(
        name: 'Test Farm',
        type: FarmType.grapes,
        polygon: polygon1,
      );
      final request2 = CreateFarmRequest(
        name: 'Test Farm',
        type: FarmType.grapes,
        polygon: polygon2,
      );

      expect(request1, request2);
    });

    test('should not be equal when properties differ', () {
      final polygon = [
        LatLng(latitude: 36.7538, longitude: 3.0588),
      ];

      final request1 = CreateFarmRequest(
        name: 'Farm 1',
        type: FarmType.grapes,
        polygon: polygon,
      );
      final request2 = CreateFarmRequest(
        name: 'Farm 2',
        type: FarmType.wheat,
        polygon: polygon,
      );

      expect(request1, isNot(request2));
    });

    test('should support all farm types', () {
      final polygon = [LatLng(latitude: 36.7538, longitude: 3.0588)];

      for (final type in FarmType.values) {
        final request = CreateFarmRequest(
          name: 'Test Farm',
          type: type,
          polygon: polygon,
        );
        expect(request.type, type);
      }
    });

    test('should handle empty polygon', () {
      final request = CreateFarmRequest(
        name: 'Test Farm',
        type: FarmType.grapes,
        polygon: [],
      );

      expect(request.polygon.length, 0);
    });
  });
}

