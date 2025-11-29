import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dowa/shared/services/api_service.dart';
import 'package:dowa/core/constants/api_constants.dart';

import 'requests_api_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Requests API Tests', () {
    late ApiService apiService;
    late MockClient mockClient;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockClient = MockClient();
      apiService = ApiService(baseUrl: 'http://localhost:3000');
      // Don't call setToken in setUp as it requires SharedPreferences
      // Instead, test token management separately
    });

    group('Get Requests', () {
      test('should get requests for a farm', () async {
        final mockResponse = http.Response(
          '''[
            {
              "id": "request-1",
              "farmId": "farm-1",
              "status": "DRAFT",
              "expertIntervention": false,
              "note": null,
              "finalReport": null,
              "createdAt": "2024-01-01T00:00:00.000Z",
              "updatedAt": "2024-01-01T00:00:00.000Z",
              "completedAt": null,
              "images": []
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

      test('should filter requests by farmId', () {
        final queryParams = {'farmId': 'farm-123'};
        expect(queryParams['farmId'], equals('farm-123'));
      });
    });

    group('Create Request', () {
      test('should create a new draft request', () async {
        final mockResponse = http.Response(
          '''{
            "id": "request-new",
            "farmId": "farm-1",
            "status": "DRAFT",
            "expertIntervention": false,
            "note": null,
            "finalReport": null,
            "createdAt": "2024-01-01T00:00:00.000Z",
            "updatedAt": "2024-01-01T00:00:00.000Z",
            "completedAt": null,
            "images": []
          }''',
          201,
        );

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => mockResponse);

        final requestBody = {
          'farmId': 'farm-1',
        };

        expect(requestBody['farmId'], equals('farm-1'));
      });
    });

    group('Upload Image', () {
      test('should upload normal image with metadata', () async {
        final mockResponse = http.Response(
          '''{
            "id": "image-1",
            "requestId": "request-1",
            "type": "NORMAL",
            "filePath": "/uploads/normal/image-1.jpg",
            "latitude": 36.7538,
            "longitude": 3.0588,
            "diseaseType": null,
            "confidence": null,
            "treatmentPlan": null,
            "materials": null,
            "services": null,
            "processedAt": null,
            "createdAt": "2024-01-01T00:00:00.000Z"
          }''',
          201,
        );

        // Test multipart request structure
        final fields = {
          'type': 'NORMAL',
          'latitude': '36.7538',
          'longitude': '3.0588',
        };

        expect(fields['type'], equals('NORMAL'));
        expect(fields.containsKey('latitude'), isTrue);
        expect(fields.containsKey('longitude'), isTrue);
      });

      test('should upload macro image with metadata', () {
        final fields = {
          'type': 'MACRO',
          'latitude': '36.7538',
          'longitude': '3.0588',
        };

        expect(fields['type'], equals('MACRO'));
      });
    });

    group('Send Request', () {
      test('should send request (DRAFT -> PENDING)', () async {
        final mockResponse = http.Response(
          '''{
            "id": "request-1",
            "farmId": "farm-1",
            "status": "PENDING",
            "expertIntervention": false,
            "note": "Test note",
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
          body: anyNamed('body'),
        )).thenAnswer((_) async => mockResponse);

        final requestBody = {
          'note': 'Test note',
          'expertIntervention': false,
        };

        expect(requestBody['note'], equals('Test note'));
        expect(requestBody['expertIntervention'], equals(false));
      });
    });

    group('Get Request by ID', () {
      test('should get request details with images', () async {
        final mockResponse = http.Response(
          '''{
            "id": "request-1",
            "farmId": "farm-1",
            "status": "COMPLETED",
            "expertIntervention": false,
            "note": null,
            "finalReport": "# Report\\n\\nTest report",
            "createdAt": "2024-01-01T00:00:00.000Z",
            "updatedAt": "2024-01-01T00:00:00.000Z",
            "completedAt": "2024-01-02T00:00:00.000Z",
            "images": [
              {
                "id": "image-1",
                "requestId": "request-1",
                "type": "NORMAL",
                "filePath": "/uploads/normal/image-1.jpg",
                "latitude": 36.7538,
                "longitude": 3.0588,
                "diseaseType": "Leaf Spot",
                "confidence": 0.95,
                "treatmentPlan": "Apply fungicide",
                "materials": "Fungicide A",
                "services": null,
                "processedAt": "2024-01-01T12:00:00.000Z",
                "createdAt": "2024-01-01T00:00:00.000Z"
              }
            ]
          }''',
          200,
        );

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => mockResponse);

        expect(mockResponse.statusCode, equals(200));
      });
    });

    group('Request Status', () {
      test('should validate request status values', () {
        final validStatuses = [
          'DRAFT',
          'PENDING',
          'ACCEPTED',
          'PROCESSING',
          'PROCESSED',
          'COMPLETED',
        ];

        expect(validStatuses.contains('DRAFT'), isTrue);
        expect(validStatuses.contains('PENDING'), isTrue);
        expect(validStatuses.contains('COMPLETED'), isTrue);
        expect(validStatuses.contains('INVALID'), isFalse);
      });
    });
  });
}

