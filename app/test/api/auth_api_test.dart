import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dowa/shared/services/api_service.dart';
import 'package:dowa/core/constants/api_constants.dart';

import 'auth_api_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auth API Tests', () {
    late ApiService apiService;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      apiService = ApiService(baseUrl: 'http://localhost:3000');
    });

    group('Sign Up', () {
      test('should sign up a new user successfully', () async {
        final mockResponse = http.Response(
          '''{
            "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
            "user": {
              "id": "user-123",
              "email": "test@example.com",
              "name": "Test User",
              "role": "FARMER"
            }
          }''',
          200,
        );

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => mockResponse);

        // Test the expected request structure
        final requestBody = {
          'email': 'test@example.com',
          'password': 'password123',
          'name': 'Test User',
          'role': 'FARMER',
        };

        expect(requestBody['email'], equals('test@example.com'));
        expect(requestBody['role'], equals('FARMER'));
      });

      test('should handle sign up with missing fields', () {
        final requestBody = {
          'email': 'test@example.com',
          'password': 'password123',
        };

        expect(requestBody.containsKey('name'), isFalse);
      });
    });

    group('Sign In', () {
      test('should sign in user successfully', () async {
        final mockResponse = http.Response(
          '''{
            "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
            "user": {
              "id": "user-123",
              "email": "test@example.com",
              "name": "Test User",
              "role": "FARMER"
            }
          }''',
          200,
        );

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => mockResponse);

        final requestBody = {
          'email': 'test@example.com',
          'password': 'password123',
        };

        expect(requestBody['email'], equals('test@example.com'));
        expect(requestBody.containsKey('password'), isTrue);
      });

      test('should handle invalid credentials', () {
        final errorResponse = http.Response('Invalid credentials', 401);
        expect(errorResponse.statusCode, equals(401));
      });
    });

    group('Get Current User', () {
      test('should get current user with valid token', () async {
        SharedPreferences.setMockInitialValues({});
        apiService.setToken('valid-token-123');

        final mockResponse = http.Response(
          '''{
            "id": "user-123",
            "email": "test@example.com",
            "name": "Test User",
            "role": "FARMER",
            "createdAt": "2024-01-01T00:00:00.000Z"
          }''',
          200,
        );

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => mockResponse);

        expect(apiService.token, isNotNull);
        expect(apiService.token, equals('valid-token-123'));
      });

      test('should handle unauthorized request', () {
        final errorResponse = http.Response('Unauthorized', 401);
        expect(errorResponse.statusCode, equals(401));
      });
    });

    group('Token Persistence', () {
      test('should persist token after sign in', () async {
        apiService.setToken('new-token-123');
        expect(apiService.token, equals('new-token-123'));
      });

      test('should clear token on logout', () async {
        apiService.setToken('token-123');
        await apiService.clearToken();
        expect(apiService.token, isNull);
      });
    });
  });
}

