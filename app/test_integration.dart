import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lib/features/farms/data/repositories/farm_repository_impl.dart';
import 'lib/core/di/dio_client.dart';
import 'lib/core/constants/api_constants.dart';
import 'lib/features/farms/domain/dto/create_farm_request.dart';
import 'lib/features/farms/domain/entities/farm.dart';

/// Standalone integration test script
/// 
/// Run with: dart run test_integration.dart
/// 
/// Prerequisites:
/// 1. Server must be running on localhost:3000
/// 2. Set TEST_AUTH_TOKEN environment variable or sign in first
void main() async {
  print('🚀 Starting integration test...\n');
  
  // Get token from environment or SharedPreferences, or sign in
  String? testToken;
  
  // Try environment variable first
  testToken = Platform.environment['TEST_AUTH_TOKEN'];
  
  // If not in environment, try SharedPreferences
  if (testToken == null || testToken.isEmpty) {
    try {
      final prefs = await SharedPreferences.getInstance();
      testToken = prefs.getString('auth_token');
    } catch (e) {
      print('⚠️ Could not access SharedPreferences: $e');
    }
  }
  
  // If still no token, try to sign in with test credentials
  if (testToken == null || testToken.isEmpty) {
    print('⚠️ No token found, attempting to sign in...');
    try {
      final signInDio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
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
        
        // Save to SharedPreferences for future use
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', testToken!);
        } catch (e) {
          print('⚠️ Could not save token to SharedPreferences: $e');
        }
      }
    } catch (e) {
      print('❌ Failed to sign in: $e');
      print('💡 Make sure the server is running and test user exists');
      print('   You can create a test user by running:');
      print('   curl -X POST http://localhost:3000/api/auth/sign-up \\');
      print('     -H "Content-Type: application/json" \\');
      print('     -d \'{"email":"farmer@test.com","password":"password123","name":"Test Farmer"}\'');
      exit(1);
    }
  }
  
  if (testToken == null || testToken.isEmpty) {
    print('❌ No auth token available!');
    exit(1);
  }
  
  print('✅ Token found: ${testToken.substring(0, 20)}...\n');
  
  // Setup DioClient
  final dioClient = DioClient();
  dioClient.setToken(testToken);
  
  // Verify headers
  print('📋 Verifying DioClient headers...');
  final headers = dioClient.dio.options.headers;
  final headerKeys = headers.keys.toList();
  print('   Header keys: $headerKeys');
  print('   Content-Type: ${headers['Content-Type']}');
  print('   Authorization: ${headers['Authorization']?.substring(0, 30)}...');
  print('');
  
  if (!headerKeys.contains('Authorization')) {
    print('❌ ERROR: Authorization header not found in DioClient headers!');
    exit(1);
  }
  
  // Create repository
  final repository = FarmRepositoryImpl(dio: dioClient.dio);
  
  // Test 1: Get Farms
  print('🧪 Test 1: getFarms()');
  print('   URL: ${ApiConstants.baseUrl}${ApiConstants.farms}');
  print('   Headers: ${dioClient.dio.options.headers}');
  print('');
  
  try {
    final farms = await repository.getFarms();
    print('✅ SUCCESS! Retrieved ${farms.length} farms');
    for (var i = 0; i < farms.length && i < 5; i++) {
      print('   Farm ${i + 1}: ${farms[i].name} (${farms[i].type}) - ID: ${farms[i].id}');
    }
    if (farms.length > 5) {
      print('   ... and ${farms.length - 5} more');
    }
    print('');
  } catch (e) {
    print('❌ FAILED: $e');
    print('');
    exit(1);
  }
  
  // Test 2: Create Farm
  print('🧪 Test 2: createFarm()');
  final request = CreateFarmRequest(
    name: 'Integration Test Farm ${DateTime.now().millisecondsSinceEpoch}',
    type: FarmType.grapes,
    polygon: [
      const LatLng(latitude: 36.7538, longitude: 3.0588),
      const LatLng(latitude: 36.7548, longitude: 3.0598),
      const LatLng(latitude: 36.7558, longitude: 3.0588),
      const LatLng(latitude: 36.7548, longitude: 3.0578),
    ],
  );
  
  print('   Farm name: ${request.name}');
  print('   Farm type: ${request.type}');
  print('   Polygon points: ${request.polygon.length}');
  print('');
  
  try {
    final farm = await repository.createFarm(request);
    print('✅ SUCCESS! Created farm:');
    print('   ID: ${farm.id}');
    print('   Name: ${farm.name}');
    print('   Type: ${farm.type}');
    print('   Area: ${farm.area} m²');
    print('   Polygon points: ${farm.polygon.length}');
    print('');
  } catch (e) {
    print('❌ FAILED: $e');
    print('');
    exit(1);
  }
  
  print('🎉 All tests passed!');
}

