import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dowa/features/farms/data/repositories/farm_repository_impl.dart';
import 'package:dowa/features/farms/domain/entities/farm.dart';
import 'package:dowa/features/farms/domain/dto/create_farm_request.dart';
import 'package:dowa/features/farms/data/models/farm_model.dart';

import 'farm_repository_impl_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FarmRepositoryImpl', () {
    late FarmRepositoryImpl repository;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      repository = FarmRepositoryImpl(dio: mockDio);
    });

    group('getFarms', () {
      test('should return list of farms', () async {
        final responseData = [
          {
            'id': 'farm-1',
            'userId': 'user-1',
            'name': 'Test Farm',
            'type': 'GRAPES',
            'polygon': [
              {'latitude': 36.7538, 'longitude': 3.0588},
            ],
            'area': 1000.0,
          }
        ];

        when(mockDio.get(any)).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        final farms = await repository.getFarms();

        expect(farms.length, equals(1));
        expect(farms.first, isA<Farm>());
        expect(farms.first.id, equals('farm-1'));
      });
    });

    group('createFarm', () {
      test('should create farm successfully', () async {
        final responseData = {
          'id': 'farm-new',
          'userId': 'user-1',
          'name': 'New Farm',
          'type': 'GRAPES',
          'polygon': [
            {'latitude': 36.7538, 'longitude': 3.0588},
          ],
          'area': 1500.0,
        };

        when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        final request = CreateFarmRequest(
          name: 'New Farm',
          type: FarmType.grapes,
          polygon: [
            const LatLng(latitude: 36.7538, longitude: 3.0588),
          ],
        );

        final farm = await repository.createFarm(request);

        expect(farm, isA<Farm>());
        expect(farm.name, equals('New Farm'));
        expect(farm.type, equals(FarmType.grapes));
      });
    });
  });
}

