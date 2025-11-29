import 'package:flutter_test/flutter_test.dart';
import 'package:dowa/features/farms/data/models/farm_model.dart';
import 'package:dowa/features/farms/domain/entities/farm.dart';
import 'dart:convert';

void main() {
  group('FarmModel Polygon Parsing', () {
    test('should parse polygon from array of objects format', () {
      final Map<String, dynamic> json = {
        'id': 'farm1',
        'userId': 'user1',
        'name': 'Test Farm',
        'type': 'GRAPES',
        'polygon': [
          {'latitude': 36.7538, 'longitude': 3.0588},
          {'latitude': 36.7540, 'longitude': 3.0590},
          {'latitude': 36.7542, 'longitude': 3.0592},
        ],
        'area': 100.5,
      };
      
      final farmModel = FarmModel.fromJson(json);
      
      expect(farmModel.polygon.length, 3);
      expect(farmModel.polygon[0].latitude, 36.7538);
      expect(farmModel.polygon[0].longitude, 3.0588);
      expect(farmModel.polygon[1].latitude, 36.7540);
      expect(farmModel.polygon[1].longitude, 3.0590);
    });

    test('should parse polygon from JSON string format', () {
      final polygonString = jsonEncode([
        {'latitude': 36.7538, 'longitude': 3.0588},
        {'latitude': 36.7540, 'longitude': 3.0590},
      ]);
      
      final Map<String, dynamic> json = {
        'id': 'farm1',
        'userId': 'user1',
        'name': 'Test Farm',
        'type': 'GRAPES',
        'polygon': polygonString,
        'area': 100.5,
      };
      
      final farmModel = FarmModel.fromJson(json);
      
      expect(farmModel.polygon.length, 2);
      expect(farmModel.polygon[0].latitude, 36.7538);
      expect(farmModel.polygon[0].longitude, 3.0588);
    });

    test('should parse polygon from array format [lat, lng]', () {
      final Map<String, dynamic> json = {
        'id': 'farm1',
        'userId': 'user1',
        'name': 'Test Farm',
        'type': 'GRAPES',
        'polygon': [
          [36.7538, 3.0588],
          [36.7540, 3.0590],
        ],
        'area': 100.5,
      };
      
      final farmModel = FarmModel.fromJson(json);
      
      expect(farmModel.polygon.length, 2);
      expect(farmModel.polygon[0].latitude, 36.7538);
      expect(farmModel.polygon[0].longitude, 3.0588);
    });

    test('should handle polygon with alternative key names (lat/lng)', () {
      final Map<String, dynamic> json = {
        'id': 'farm1',
        'userId': 'user1',
        'name': 'Test Farm',
        'type': 'GRAPES',
        'polygon': [
          {'lat': 36.7538, 'lng': 3.0588},
          {'lat': 36.7540, 'lon': 3.0590},
        ],
        'area': 100.5,
      };
      
      final farmModel = FarmModel.fromJson(json);
      
      expect(farmModel.polygon.length, 2);
      expect(farmModel.polygon[0].latitude, 36.7538);
      expect(farmModel.polygon[0].longitude, 3.0588);
    });

    test('should throw FormatException for invalid polygon format', () {
      final Map<String, dynamic> json = {
        'id': 'farm1',
        'userId': 'user1',
        'name': 'Test Farm',
        'type': 'GRAPES',
        'polygon': 'invalid',
        'area': 100.5,
      };
      
      expect(() => FarmModel.fromJson(json), throwsFormatException);
    });

    test('should convert polygon to JSON correctly', () {
      final polygon = [
        LatLng(latitude: 36.7538, longitude: 3.0588),
        LatLng(latitude: 36.7540, longitude: 3.0590),
      ];
      
      final farmModel = FarmModel(
        id: 'farm1',
        userId: 'user1',
        name: 'Test Farm',
        type: FarmType.grapes,
        polygon: polygon,
        area: 100.5,
      );
      
      final json = farmModel.toJson();
      
      expect(json['polygon'], isA<List>());
      expect(json['polygon'].length, 2);
      expect(json['polygon'][0]['latitude'], 36.7538);
      expect(json['polygon'][0]['longitude'], 3.0588);
    });

    test('should handle empty polygon', () {
      final Map<String, dynamic> json = {
        'id': 'farm1',
        'userId': 'user1',
        'name': 'Test Farm',
        'type': 'GRAPES',
        'polygon': [],
        'area': 100.5,
      };
      
      final farmModel = FarmModel.fromJson(json);
      
      expect(farmModel.polygon.length, 0);
    });
  });
}

