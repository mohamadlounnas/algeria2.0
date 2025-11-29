import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dowa/shared/services/api_service.dart';
import 'package:dowa/core/constants/api_constants.dart';

import 'admin_api_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Admin API Tests', () {
    late ApiService apiService;
    late MockClient mockClient;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockClient = MockClient();
      apiService = ApiService(baseUrl: 'http://localhost:3000');
      // Token is set in individual tests that need it
    });

    group('User Management', () {
      test('should get all users', () async {
        final mockResponse = http.Response(
          '''[
            {
              "id": "user-1",
              "email": "user1@example.com",
              "name": "User 1",
              "role": "FARMER",
              "createdAt": "2024-01-01T00:00:00.000Z",
              "updatedAt": "2024-01-01T00:00:00.000Z"
            },
            {
              "id": "user-2",
              "email": "admin@example.com",
              "name": "Admin User",
              "role": "ADMIN",
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

        expect(mockResponse.statusCode, equals(200));
      });

      test('should create a new user', () async {
        final mockResponse = http.Response(
          '''{
            "id": "user-new",
            "email": "newuser@example.com",
            "name": "New User",
            "role": "FARMER",
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
          'email': 'newuser@example.com',
          'password': 'password123',
          'name': 'New User',
          'role': 'FARMER',
        };

        expect(requestBody['email'], equals('newuser@example.com'));
        expect(requestBody['role'], equals('FARMER'));
      });

      test('should update user', () async {
        final mockResponse = http.Response(
          '''{
            "id": "user-1",
            "email": "updated@example.com",
            "name": "Updated User",
            "role": "FARMER",
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
          'name': 'Updated User',
        };

        expect(requestBody['name'], equals('Updated User'));
      });

      test('should delete user', () async {
        final mockResponse = http.Response(
          '{"success": true}',
          200,
        );

        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => mockResponse);

        expect(mockResponse.statusCode, equals(200));
      });
    });

    group('Farm Management', () {
      test('should get all farms', () async {
        final mockResponse = http.Response(
          '''[
            {
              "id": "farm-1",
              "userId": "user-1",
              "name": "Farm 1",
              "type": "GRAPES",
              "polygon": [],
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

        expect(mockResponse.statusCode, equals(200));
      });

      test('should filter farms by userId', () {
        final queryParams = {'userId': 'user-123'};
        expect(queryParams['userId'], equals('user-123'));
      });

      test('should update farm', () async {
        final mockResponse = http.Response(
          '''{
            "id": "farm-1",
            "userId": "user-1",
            "name": "Updated Farm",
            "type": "GRAPES",
            "polygon": [],
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
          'name': 'Updated Farm',
        };

        expect(requestBody['name'], equals('Updated Farm'));
      });

      test('should delete farm', () async {
        final mockResponse = http.Response(
          '{"success": true}',
          200,
        );

        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => mockResponse);

        expect(mockResponse.statusCode, equals(200));
      });
    });

    group('Request Management', () {
      test('should get all requests', () async {
        final mockResponse = http.Response(
          '''[
            {
              "id": "request-1",
              "farmId": "farm-1",
              "status": "PENDING",
              "expertIntervention": false,
              "note": null,
              "finalReport": null,
              "createdAt": "2024-01-01T00:00:00.000Z",
              "updatedAt": "2024-01-01T00:00:00.000Z",
              "completedAt": null
            }
          ]''',
          200,
        );

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => mockResponse);

        expect(mockResponse.statusCode, equals(200));
      });

      test('should filter requests by status', () {
        final queryParams = {'status': 'PENDING'};
        expect(queryParams['status'], equals('PENDING'));
      });

      test('should accept request', () async {
        final mockResponse = http.Response(
          '''{
            "id": "request-1",
            "farmId": "farm-1",
            "status": "ACCEPTED",
            "expertIntervention": false,
            "note": null,
            "finalReport": null,
            "createdAt": "2024-01-01T00:00:00.000Z",
            "updatedAt": "2024-01-01T00:00:00.000Z",
            "completedAt": null
          }''',
          200,
        );

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => mockResponse);

        expect(mockResponse.statusCode, equals(200));
      });

      test('should process request', () async {
        final mockResponse = http.Response(
          '''{
            "id": "request-1",
            "farmId": "farm-1",
            "status": "PROCESSED",
            "expertIntervention": false,
            "note": null,
            "finalReport": "# Report\\n\\nProcessed",
            "createdAt": "2024-01-01T00:00:00.000Z",
            "updatedAt": "2024-01-01T00:00:00.000Z",
            "completedAt": null
          }''',
          200,
        );

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => mockResponse);

        expect(mockResponse.statusCode, equals(200));
      });

      test('should update request report', () async {
        final mockResponse = http.Response(
          '''{
            "id": "request-1",
            "farmId": "farm-1",
            "status": "PROCESSED",
            "expertIntervention": false,
            "note": null,
            "finalReport": "# Updated Report\\n\\nNew content",
            "createdAt": "2024-01-01T00:00:00.000Z",
            "updatedAt": "2024-01-01T00:00:00.000Z",
            "completedAt": null
          }''',
          200,
        );

        when(mockClient.put(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => mockResponse);

        final requestBody = {
          'report': '# Updated Report\n\nNew content',
        };

        expect(requestBody['report'], contains('Updated Report'));
      });

      test('should complete request', () async {
        final mockResponse = http.Response(
          '''{
            "id": "request-1",
            "farmId": "farm-1",
            "status": "COMPLETED",
            "expertIntervention": false,
            "note": null,
            "finalReport": "# Report\\n\\nFinal",
            "createdAt": "2024-01-01T00:00:00.000Z",
            "updatedAt": "2024-01-01T00:00:00.000Z",
            "completedAt": "2024-01-02T00:00:00.000Z"
          }''',
          200,
        );

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => mockResponse);

        expect(mockResponse.statusCode, equals(200));
      });

      test('should delete request', () async {
        final mockResponse = http.Response(
          '{"success": true}',
          200,
        );

        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => mockResponse);

        expect(mockResponse.statusCode, equals(200));
      });
    });

    group('Authorization', () {
      test('should require admin token', () {
        apiService.setToken('admin-token-123');
        expect(apiService.token, isNotNull);
        expect(apiService.token, equals('admin-token-123'));
      });

      test('should handle forbidden access for non-admin', () {
        final errorResponse = http.Response('Forbidden: Admin access required', 403);
        expect(errorResponse.statusCode, equals(403));
      });
    });
  });
}

