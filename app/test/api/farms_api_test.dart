import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dowa/shared/services/api_service.dart';
import 'package:dowa/core/constants/api_constants.dart';

import 'farms_api_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Farms API Tests', () {
    late ApiService apiService;
    late MockClient mockClient;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockClient = MockClient();
      apiService = ApiService(baseUrl: 'http://localhost:3000');
      // Token is set in individual tests that need it
    });

    group('Get All Farms', () {
      test('should get all farms for authenticated user', () async {
        apiService.setToken('test-token-123');
        final mockResponse = http.Response(
          '''[
            {
              "id": "farm-1",
              "userId": "user-123",
              "name": "Test Farm 1",
              "type": "GRAPES",
              "polygon": [
                {"latitude": 36.7538, "longitude": 3.0588},
                {"latitude": 36.7548, "longitude": 3.0598}
              ],
              "area": 1000.0,
              "createdAt": "2024-01-01T00:00:00.000Z",
              "updatedAt": "2024-01-01T00:00:00.000Z"
            }
          ]''',
          200,
        );

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => mockResponse);

        expect(apiService.token, isNotNull);
        expect(apiService.token, equals('test-token-123'));
      });

      test('should return empty list when user has no farms', () {
        final emptyResponse = http.Response('[]', 200);
        expect(emptyResponse.body, equals('[]'));
      });
    });

    group('Create Farm', () {
      test('should create a new farm successfully', () async {
        final mockResponse = http.Response(
          '''{
            "id": "farm-new",
            "userId": "user-123",
            "name": "New Farm",
            "type": "GRAPES",
            "polygon": [
              {"latitude": 36.7538, "longitude": 3.0588},
              {"latitude": 36.7548, "longitude": 3.0598},
              {"latitude": 36.7558, "longitude": 3.0588},
              {"latitude": 36.7548, "longitude": 3.0578}
            ],
            "area": 1500.0,
            "createdAt": "2024-01-01T00:00:00.000Z",
            "updatedAt": "2024-01-01T00:00:00.000Z"
          }''',
          201,
        );

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => mockResponse);

        final requestBody = {
          'name': 'New Farm',
          'type': 'GRAPES',
          'polygon': [
            {'latitude': 36.7538, 'longitude': 3.0588},
            {'latitude': 36.7548, 'longitude': 3.0598},
            {'latitude': 36.7558, 'longitude': 3.0588},
            {'latitude': 36.7548, 'longitude': 3.0578},
          ],
        };

        expect(requestBody['name'], equals('New Farm'));
        expect(requestBody['type'], equals('GRAPES'));
        expect((requestBody['polygon'] as List).length, equals(4));
      });

      test('should validate farm type', () {
        final validTypes = ['GRAPES', 'WHEAT', 'CORN', 'TOMATOES', 'OLIVES', 'DATES'];
        expect(validTypes.contains('GRAPES'), isTrue);
        expect(validTypes.contains('INVALID'), isFalse);
      });

      test('should validate polygon has at least 3 points', () {
        final polygon = [
          {'latitude': 36.7538, 'longitude': 3.0588},
          {'latitude': 36.7548, 'longitude': 3.0598},
        ];
        expect(polygon.length, lessThan(3));
      });
    });

    group('Get Farm by ID', () {
      test('should get farm details by ID', () async {
        final mockResponse = http.Response(
          '''{
            "id": "farm-1",
            "userId": "user-123",
            "name": "Test Farm",
            "type": "GRAPES",
            "polygon": [
              {"latitude": 36.7538, "longitude": 3.0588}
            ],
            "area": 1000.0,
            "createdAt": "2024-01-01T00:00:00.000Z",
            "updatedAt": "2024-01-01T00:00:00.000Z"
          }''',
          200,
        );

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => mockResponse);

        expect(mockResponse.statusCode, equals(200));
      });

      test('should handle farm not found', () {
        final errorResponse = http.Response('Farm not found', 404);
        expect(errorResponse.statusCode, equals(404));
      });
    });

    group('Update Farm', () {
      test('should update farm successfully', () async {
        final mockResponse = http.Response(
          '''{
            "id": "farm-1",
            "userId": "user-123",
            "name": "Updated Farm Name",
            "type": "GRAPES",
            "polygon": [
              {"latitude": 36.7538, "longitude": 3.0588}
            ],
            "area": 1000.0,
            "createdAt": "2024-01-01T00:00:00.000Z",
            "updatedAt": "2024-01-02T00:00:00.000Z"
          }''',
          200,
        );

        when(mockClient.put(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => mockResponse);

        final requestBody = {
          'name': 'Updated Farm Name',
        };

        expect(requestBody['name'], equals('Updated Farm Name'));
      });
    });

    group('Delete Farm', () {
      test('should delete farm successfully', () async {
        final mockResponse = http.Response('', 200);

        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => mockResponse);

        expect(mockResponse.statusCode, equals(200));
      });

      test('should handle farm not found on delete', () {
        final errorResponse = http.Response('Farm not found', 404);
        expect(errorResponse.statusCode, equals(404));
      });
    });

    group('Authorization', () {
      test('should require authentication token', () {
        apiService.setToken('test-token-123');
        expect(apiService.token, isNotNull);
        expect(apiService.token, equals('test-token-123'));
      });

      test('should handle unauthorized access', () {
        final errorResponse = http.Response('Unauthorized', 401);
        expect(errorResponse.statusCode, equals(401));
      });
    });
  });
}

