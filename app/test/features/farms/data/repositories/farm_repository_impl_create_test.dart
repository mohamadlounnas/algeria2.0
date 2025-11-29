import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:dowa/features/farms/data/repositories/farm_repository_impl.dart';
import 'package:dowa/features/farms/domain/entities/farm.dart';
import 'package:dowa/features/farms/domain/dto/create_farm_request.dart';
import 'package:dowa/features/farms/data/models/farm_model.dart';
import 'package:dowa/core/constants/api_constants.dart';
import 'farm_repository_impl_create_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late FarmRepositoryImpl farmRepository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    farmRepository = FarmRepositoryImpl(dio: mockDio);
  });

  group('FarmRepositoryImpl - createFarm', () {
    test('should create farm with polygon successfully', () async {
      final polygon = [
        LatLng(latitude: 36.7538, longitude: 3.0588),
        LatLng(latitude: 36.7540, longitude: 3.0590),
        LatLng(latitude: 36.7542, longitude: 3.0592),
      ];

      final mockResponseData = {
        'id': 'newFarmId',
        'userId': 'user1',
        'name': 'New Farm',
        'type': 'GRAPES',
        'polygon': [
          {'latitude': 36.7538, 'longitude': 3.0588},
          {'latitude': 36.7540, 'longitude': 3.0590},
          {'latitude': 36.7542, 'longitude': 3.0592},
        ],
        'area': 75.0
      };

      when(mockDio.post(
        any,
        data: anyNamed('data'),
      )).thenAnswer(
        (_) async => Response(
          data: mockResponseData,
          statusCode: 201,
          requestOptions: RequestOptions(path: ApiConstants.farms),
        ),
      );

      final request = CreateFarmRequest(
        name: 'New Farm',
        type: FarmType.grapes,
        polygon: polygon,
      );

      final createdFarm = await farmRepository.createFarm(request);

      expect(createdFarm.id, 'newFarmId');
      expect(createdFarm.name, 'New Farm');
      expect(createdFarm.type, FarmType.grapes);
      expect(createdFarm.polygon.length, 3);
      expect(createdFarm.polygon[0].latitude, 36.7538);
      expect(createdFarm.polygon[0].longitude, 3.0588);
      expect(createdFarm.area, 75.0);
      expect(createdFarm, isA<Farm>());

      // Verify the request was made with correct polygon format
      verify(mockDio.post(
        any,
        data: argThat(
          predicate<Map<String, dynamic>>((data) {
            expect(data['name'], 'New Farm');
            expect(data['type'], 'GRAPES');
            expect(data['polygon'], isA<List>());
            expect(data['polygon'].length, 3);
            expect(data['polygon'][0]['latitude'], 36.7538);
            expect(data['polygon'][0]['longitude'], 3.0588);
            return true;
          }),
        ),
      )).called(1);
    });

    test('should handle empty polygon', () async {
      final mockResponseData = {
        'id': 'newFarmId',
        'userId': 'user1',
        'name': 'New Farm',
        'type': 'GRAPES',
        'polygon': [],
        'area': 0.0
      };

      when(mockDio.post(
        any,
        data: anyNamed('data'),
      )).thenAnswer(
        (_) async => Response(
          data: mockResponseData,
          statusCode: 201,
          requestOptions: RequestOptions(path: ApiConstants.farms),
        ),
      );

      final request = CreateFarmRequest(
        name: 'New Farm',
        type: FarmType.grapes,
        polygon: [],
      );

      final createdFarm = await farmRepository.createFarm(request);

      expect(createdFarm.polygon.length, 0);
    });

    test('should throw exception on network error', () async {
      final polygon = [
        LatLng(latitude: 36.7538, longitude: 3.0588),
      ];

      when(mockDio.post(
        any,
        data: anyNamed('data'),
      )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.farms),
          response: Response(
            statusCode: 400,
            data: {'message': 'Invalid polygon'},
            requestOptions: RequestOptions(path: ApiConstants.farms),
          ),
        ),
      );

      final request = CreateFarmRequest(
        name: 'New Farm',
        type: FarmType.grapes,
        polygon: polygon,
      );

      expect(
        () => farmRepository.createFarm(request),
        throwsException,
      );
    });

    test('should handle large polygon arrays', () async {
      final largePolygon = List.generate(100, (i) => LatLng(
        latitude: 36.7538 + (i * 0.0001),
        longitude: 3.0588 + (i * 0.0001),
      ));

      final mockResponseData = {
        'id': 'newFarmId',
        'userId': 'user1',
        'name': 'Large Farm',
        'type': 'GRAPES',
        'polygon': largePolygon.map((p) => {
          'latitude': p.latitude,
          'longitude': p.longitude,
        }).toList(),
        'area': 1000.0
      };

      when(mockDio.post(
        any,
        data: anyNamed('data'),
      )).thenAnswer(
        (_) async => Response(
          data: mockResponseData,
          statusCode: 201,
          requestOptions: RequestOptions(path: ApiConstants.farms),
        ),
      );

      final request = CreateFarmRequest(
        name: 'Large Farm',
        type: FarmType.grapes,
        polygon: largePolygon,
      );

      final createdFarm = await farmRepository.createFarm(request);

      expect(createdFarm.polygon.length, 100);
    });
  });
}

