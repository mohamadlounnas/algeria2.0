import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:dowa/features/farms/data/repositories/farm_repository_impl.dart';
import 'package:dowa/features/farms/domain/entities/farm.dart';
import 'package:dowa/features/farms/domain/dto/create_farm_request.dart';
import 'package:dowa/core/constants/api_constants.dart';
import 'farm_repository_impl_error_handling_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late FarmRepositoryImpl farmRepository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    farmRepository = FarmRepositoryImpl(dio: mockDio);
  });

  group('FarmRepositoryImpl - Error Handling', () {
    test('should throw exception when polygon has less than 3 points', () async {
      final request = CreateFarmRequest(
        name: 'Test Farm',
        type: FarmType.grapes,
        polygon: [
          LatLng(latitude: 36.7538, longitude: 3.0588),
          LatLng(latitude: 36.7540, longitude: 3.0590),
        ],
      );

      expect(
        () => farmRepository.createFarm(request),
        throwsException,
      );
    });

    test('should handle 500 server error with detailed message', () async {
      final polygon = [
        LatLng(latitude: 36.7538, longitude: 3.0588),
        LatLng(latitude: 36.7540, longitude: 3.0590),
        LatLng(latitude: 36.7542, longitude: 3.0592),
      ];

      final request = CreateFarmRequest(
        name: 'Test Farm',
        type: FarmType.grapes,
        polygon: polygon,
      );

      when(mockDio.post(
        any,
        data: anyNamed('data'),
      )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.farms),
          response: Response(
            statusCode: 500,
            data: {'message': 'Internal server error', 'error': 'Database connection failed'},
            requestOptions: RequestOptions(path: ApiConstants.farms),
          ),
        ),
      );

      expect(
        () => farmRepository.createFarm(request),
        throwsException,
      );
    });

    test('should handle network errors', () async {
      final polygon = [
        LatLng(latitude: 36.7538, longitude: 3.0588),
        LatLng(latitude: 36.7540, longitude: 3.0590),
        LatLng(latitude: 36.7542, longitude: 3.0592),
      ];

      final request = CreateFarmRequest(
        name: 'Test Farm',
        type: FarmType.grapes,
        polygon: polygon,
      );

      when(mockDio.post(
        any,
        data: anyNamed('data'),
      )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.farms),
          message: 'Connection timeout',
        ),
      );

      expect(
        () => farmRepository.createFarm(request),
        throwsException,
      );
    });
  });
}

