import 'dart:io';
import 'package:dio/dio.dart';

/// Simple integration test using only Dio (no Flutter dependencies)
/// 
/// Run with: dart run test_integration_simple.dart
/// 
/// Prerequisites:
/// 1. Server must be running on localhost:3000
/// 2. Set TEST_AUTH_TOKEN environment variable or it will try to sign in
void main() async {
  print('🚀 Starting integration test...\n');
  
  const baseUrl = 'http://localhost:3000';
  String? testToken;
  
  // Try environment variable first
  testToken = Platform.environment['TEST_AUTH_TOKEN'];
  
  // If no token, try to sign in
  if (testToken == null || testToken.isEmpty) {
    print('⚠️ No token found, attempting to sign in...');
    try {
      final signInDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {'Content-Type': 'application/json'},
      ));
      
      final signInResponse = await signInDio.post(
        '/api/auth/sign-in',
        data: {
          'email': 'farmer@test.com',
          'password': 'password123',
        },
      );
      
      if (signInResponse.data['token'] != null) {
        testToken = signInResponse.data['token'] as String;
        print('✅ Signed in successfully!');
      }
    } catch (e) {
      print('❌ Failed to sign in: $e');
      print('💡 Make sure the server is running and test user exists');
      exit(1);
    }
  }
  
  if (testToken == null || testToken.isEmpty) {
    print('❌ No auth token available!');
    exit(1);
  }
  
  print('✅ Token found: ${testToken.substring(0, 20)}...\n');
  
  // Setup DioClient with interceptor
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $testToken',
    },
  ));
  
  // Verify headers
  print('📋 Verifying Dio headers...');
  final headers = dio.options.headers;
  final headerKeys = headers.keys.toList();
  print('   Header keys: $headerKeys');
  print('   Content-Type: ${headers['Content-Type']}');
  print('   Authorization: ${headers['Authorization']?.substring(0, 30)}...');
  print('');
  
  if (!headerKeys.contains('Authorization')) {
    print('❌ ERROR: Authorization header not found!');
    exit(1);
  }
  
  // Test 1: Get Farms
  print('🧪 Test 1: GET /api/farms');
  print('   URL: $baseUrl/api/farms');
  print('   Headers: $headers');
  print('');
  
  try {
    final response = await dio.get('/api/farms');
    print('✅ SUCCESS! Status: ${response.statusCode}');
    final farms = response.data;
    final farmsList = farms is List ? farms : (farms['data'] ?? []);
    print('   Retrieved ${farmsList.length} farms');
    for (var i = 0; i < farmsList.length && i < 5; i++) {
      final farm = farmsList[i];
      print('   Farm ${i + 1}: ${farm['name']} (${farm['type']}) - ID: ${farm['id']}');
    }
    if (farmsList.length > 5) {
      print('   ... and ${farmsList.length - 5} more');
    }
    print('');
  } catch (e) {
    print('❌ FAILED: $e');
    if (e is DioException) {
      print('   Status: ${e.response?.statusCode}');
      print('   Response: ${e.response?.data}');
    }
    print('');
    exit(1);
  }
  
  // Test 2: Create Farm
  print('🧪 Test 2: POST /api/farms');
  final farmData = {
    'name': 'Integration Test Farm ${DateTime.now().millisecondsSinceEpoch}',
    'type': 'GRAPES',
    'polygon': [
      {'latitude': 36.7538, 'longitude': 3.0588},
      {'latitude': 36.7548, 'longitude': 3.0598},
      {'latitude': 36.7558, 'longitude': 3.0588},
      {'latitude': 36.7548, 'longitude': 3.0578},
    ],
  };
  
  print('   Farm name: ${farmData['name']}');
  print('   Farm type: ${farmData['type']}');
  print('   Polygon points: ${(farmData['polygon'] as List).length}');
  print('');
  
  try {
    final response = await dio.post('/api/farms', data: farmData);
    print('✅ SUCCESS! Status: ${response.statusCode}');
    final farm = response.data;
    print('   Created farm:');
    print('   ID: ${farm['id']}');
    print('   Name: ${farm['name']}');
    print('   Type: ${farm['type']}');
    print('   Area: ${farm['area']} m²');
    print('   Polygon points: ${(farm['polygon'] as List).length}');
    print('');
  } catch (e) {
    print('❌ FAILED: $e');
    if (e is DioException) {
      print('   Status: ${e.response?.statusCode}');
      print('   Response: ${e.response?.data}');
    }
    print('');
    exit(1);
  }
  
  print('🎉 All tests passed!');
}

