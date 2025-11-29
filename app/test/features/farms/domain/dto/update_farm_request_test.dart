import 'package:flutter_test/flutter_test.dart';
import 'package:dowa/features/farms/domain/dto/update_farm_request.dart';
import 'package:dowa/features/farms/domain/entities/farm.dart';

void main() {
  group('UpdateFarmRequest', () {
    test('should create request with all fields null', () {
      final request = UpdateFarmRequest();

      expect(request.name, null);
      expect(request.type, null);
      expect(request.polygon, null);
      expect(request.isEmpty, true);
    });

    test('should create request with name only', () {
      final request = UpdateFarmRequest(name: 'Updated Name');

      expect(request.name, 'Updated Name');
      expect(request.type, null);
      expect(request.polygon, null);
      expect(request.isEmpty, false);
    });

    test('should create request with type only', () {
      final request = UpdateFarmRequest(type: FarmType.wheat);

      expect(request.name, null);
      expect(request.type, FarmType.wheat);
      expect(request.polygon, null);
      expect(request.isEmpty, false);
    });

    test('should create request with polygon only', () {
      final polygon = [
        LatLng(latitude: 36.7538, longitude: 3.0588),
      ];
      final request = UpdateFarmRequest(polygon: polygon);

      expect(request.name, null);
      expect(request.type, null);
      expect(request.polygon?.length, 1);
      expect(request.isEmpty, false);
    });

    test('should create request with all fields', () {
      final polygon = [
        LatLng(latitude: 36.7538, longitude: 3.0588),
      ];
      final request = UpdateFarmRequest(
        name: 'Updated Name',
        type: FarmType.corn,
        polygon: polygon,
      );

      expect(request.name, 'Updated Name');
      expect(request.type, FarmType.corn);
      expect(request.polygon?.length, 1);
      expect(request.isEmpty, false);
    });

    test('should be equal when all properties match', () {
      final polygon1 = [
        LatLng(latitude: 36.7538, longitude: 3.0588),
      ];
      final polygon2 = [
        LatLng(latitude: 36.7538, longitude: 3.0588),
      ];

      final request1 = UpdateFarmRequest(
        name: 'Test',
        type: FarmType.grapes,
        polygon: polygon1,
      );
      final request2 = UpdateFarmRequest(
        name: 'Test',
        type: FarmType.grapes,
        polygon: polygon2,
      );

      expect(request1, request2);
    });

    test('should not be equal when properties differ', () {
      final request1 = UpdateFarmRequest(name: 'Farm 1');
      final request2 = UpdateFarmRequest(name: 'Farm 2');

      expect(request1, isNot(request2));
    });
  });
}

