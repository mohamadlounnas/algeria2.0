import '../entities/farm.dart';
import '../dto/create_farm_request.dart';
import '../dto/update_farm_request.dart';

abstract class FarmRepository {
  Future<List<Farm>> getFarms();
  Future<Farm> getFarmById(String id);
  Future<Farm> createFarm(CreateFarmRequest request);
  Future<Farm> updateFarm(String id, UpdateFarmRequest request);
  Future<void> deleteFarm(String id);
}

