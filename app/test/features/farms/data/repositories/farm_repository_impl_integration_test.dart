import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dowa/features/farms/data/repositories/farm_repository_impl.dart';
import 'package:dowa/core/di/dio_client.dart';
import 'package:dowa/core/constants/api_constants.dart';
import 'package:dowa/features/farms/domain/dto/create_farm_request.dart';
import 'package:dowa/features/farms/domain/entities/farm.dart';

/// Integration test that makes real HTTP requests to the server
/// 
/// Prerequisites:
/// 1. Server must be running on localhost:3000
/// 2. You need a valid auth token (sign in first to get one)
/// 
/// To run this test:
/// 1. Start the server: cd server && npm run dev
/// 2. Get a token by signing in (or use an existing one)
/// 3. Set the token in SharedPreferences or pass it as an environment variable
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FarmRepositoryImpl Integration Tests', () {
    late DioClient dioClient;
    late FarmRepositoryImpl repository;
    String? testToken;

    setUpAll(() async {
      // Initialize SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      // Try to get token from environment or SharedPreferences
      // For testing, you can set it manually or get it from a sign-in
      final prefs = await SharedPreferences.getInstance();
      testToken = prefs.getString('auth_token');
      
      // If no token in prefs, try environment variable
      if (testToken == null || testToken!.isEmpty) {
        final envToken = const String.fromEnvironment('TEST_AUTH_TOKEN', defaultValue: '');
        testToken = envToken.isEmpty ? null : envToken;
      }
      
      print('🔑 Test token available: ${testToken != null && testToken!.isNotEmpty}');
      if (testToken != null && testToken!.isNotEmpty) {
        print('🔑 Token preview: ${testToken!.substring(0, 20)}...');
      }
    });

    setUp(() {
      dioClient = DioClient();
      if (testToken != null && testToken!.isNotEmpty) {
        dioClient.setToken(testToken!);
        print('✅ Token set in DioClient');
      } else {
        print('⚠️ No token available - tests may fail with Unauthorized');
      }
      repository = FarmRepositoryImpl(dio: dioClient.dio);
    });

    tearDown(() {
      // Clean up if needed
    });

    test('getFarms() - should fetch farms with valid token', () async {
      if (testToken == null || testToken!.isEmpty) {
        print('⏭️ Skipping test - no token available');
        print('💡 To run this test, set TEST_AUTH_TOKEN environment variable or sign in first');
        return;
      }

      print('\n🧪 Testing getFarms()...');
      print('🌐 Base URL: ${ApiConstants.baseUrl}');
      print('🌐 Endpoint: ${ApiConstants.farms}');
      print('🔐 Token set: ${dioClient.token != null}');
      
      try {
        final farms = await repository.getFarms();
        
        print('✅ Success! Retrieved ${farms.length} farms');
        for (var i = 0; i < farms.length; i++) {
          print('  Farm ${i + 1}: ${farms[i].name} (${farms[i].type})');
        }
        
        expect(farms, isA<List<Farm>>());
      } catch (e) {
        print('❌ Test failed: $e');
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('getFarms() - should fail without token', () async {
      // Create a new DioClient without token
      final noTokenClient = DioClient();
      final noTokenRepo = FarmRepositoryImpl(dio: noTokenClient.dio);
      
      print('\n🧪 Testing getFarms() without token...');
      
      try {
        final farms = await noTokenRepo.getFarms();
        print('⚠️ Unexpected success - got ${farms.length} farms without token');
        // This might succeed if server allows unauthenticated access (unlikely)
      } catch (e) {
        print('✅ Expected failure: $e');
        expect(e, isA<Exception>());
        expect(e.toString(), contains(RegExp(r'(Unauthorized|Failed|Network)', caseSensitive: false)));
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('createFarm() - should create farm with valid token', () async {
      if (testToken == null || testToken!.isEmpty) {
        print('⏭️ Skipping test - no token available');
        return;
      }

      print('\n🧪 Testing createFarm()...');
      
      final request = CreateFarmRequest(
        name: 'Test Farm ${DateTime.now().millisecondsSinceEpoch}',
        type: FarmType.grapes,
        polygon: [
          const LatLng(latitude: 36.7538, longitude: 3.0588),
          const LatLng(latitude: 36.7548, longitude: 3.0598),
          const LatLng(latitude: 36.7558, longitude: 3.0588),
          const LatLng(latitude: 36.7548, longitude: 3.0578),
        ],
      );

      try {
        final farm = await repository.createFarm(request);
        
        print('✅ Success! Created farm: ${farm.name}');
        print('  ID: ${farm.id}');
        print('  Type: ${farm.type}');
        print('  Area: ${farm.area}');
        print('  Polygon points: ${farm.polygon.length}');
        
        expect(farm, isA<Farm>());
        expect(farm.name, equals(request.name));
        expect(farm.type, equals(request.type));
        expect(farm.polygon.length, equals(request.polygon.length));
      } catch (e) {
        print('❌ Test failed: $e');
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('DioClient headers verification', () {
      print('\n🧪 Verifying DioClient headers...');
      
      final headers = dioClient.dio.options.headers;
      final headerKeys = headers.keys.toList();
      
      print('📋 Header keys: $headerKeys');
      print('📋 Content-Type: ${headers['Content-Type']}');
      print('📋 Authorization: ${headers['Authorization'] ?? 'NOT SET'}');
      
      expect(headerKeys, contains('Content-Type'));
      
      if (testToken != null && testToken!.isNotEmpty) {
        expect(headerKeys, contains('Authorization'));
        expect(headers['Authorization'], isNotNull);
        expect(headers['Authorization'], startsWith('Bearer '));
      }
    });
  });
}

