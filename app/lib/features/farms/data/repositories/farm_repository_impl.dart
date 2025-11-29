import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/farm.dart';
import '../../domain/repositories/farm_repository.dart';
import '../../domain/dto/create_farm_request.dart';
import '../../domain/dto/update_farm_request.dart';
import '../models/farm_model.dart';
import '../../../../core/constants/api_constants.dart';

class FarmRepositoryImpl implements FarmRepository {
  final Dio dio;

  FarmRepositoryImpl({required this.dio});

  /// Safely extract error message from response data (handles both String and Map)
  String _extractErrorMessage(dynamic responseData, String defaultMessage) {
    if (responseData is String) {
      return responseData;
    } else if (responseData is Map) {
      return responseData['message'] ?? 
             responseData['error'] ?? 
             defaultMessage;
    }
    return defaultMessage;
  }

  @override
  Future<List<Farm>> getFarms() async {
    try {
      debugPrint('🌾 FarmRepositoryImpl.getFarms() - Starting request');
      debugPrint('🌾 Request URL: ${ApiConstants.farms}');
      try {
        debugPrint('🌾 Dio base URL: ${dio.options.baseUrl}');
        debugPrint('🌾 Dio headers keys: ${dio.options.headers.keys.toList()}');
        debugPrint('🌾 Authorization header: ${dio.options.headers['Authorization'] ?? 'NOT SET'}');
        debugPrint('🌾 Full headers: ${dio.options.headers}');
      } catch (e) {
        // Ignore errors when accessing options in test mocks
        debugPrint('🌾 Could not access Dio options (likely in test): $e');
      }
      
      final response = await dio.get(ApiConstants.farms);
      
      debugPrint('🌾 FarmRepositoryImpl.getFarms() - Response received');
      debugPrint('🌾 Status code: ${response.statusCode}');
      debugPrint('🌾 Response data type: ${response.data.runtimeType}');
      
      final data = response.data;
      final farmsList = data is List ? data : (data['data'] ?? []);
      debugPrint('🌾 Parsed farms count: ${farmsList.length}');
      
      final farms = (farmsList as List)
          .map((f) => FarmModel.fromJson(f as Map<String, dynamic>))
          .toList();
      
      debugPrint('🌾 FarmRepositoryImpl.getFarms() - Success: ${farms.length} farms');
      return farms;
    } on DioException catch (e) {
      debugPrint('❌ FarmRepositoryImpl.getFarms() - DioException');
      debugPrint('❌ Error type: ${e.type}');
      debugPrint('❌ Error message: ${e.message}');
      if (e.response != null) {
        debugPrint('❌ Response status: ${e.response?.statusCode}');
        debugPrint('❌ Response data: ${e.response?.data}');
        debugPrint('❌ Response headers: ${e.response?.headers}');
        throw Exception(_extractErrorMessage(e.response?.data, 'Failed to get farms'));
      }
      debugPrint('❌ Network error: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ FarmRepositoryImpl.getFarms() - Unexpected error: $e');
      rethrow;
    }
  }

  @override
  Future<Farm> getFarmById(String id) async {
    try {
      final response = await dio.get('${ApiConstants.farms}/$id');
      return FarmModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(_extractErrorMessage(e.response?.data, 'Farm not found'));
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<Farm> createFarm(CreateFarmRequest request) async {
    try {
      // Validate polygon has at least 3 points
      if (request.polygon.length < 3) {
        throw Exception('Polygon must have at least 3 points');
      }

      // Convert polygon to the format expected by the backend
      final polygonData = request.polygon.map((p) => <String, dynamic>{
        'latitude': p.latitude,
        'longitude': p.longitude,
      }).toList();

      // Prepare request data
      final requestData = <String, dynamic>{
        'name': request.name,
        'type': _typeToString(request.type),
        'polygon': polygonData,
      };

      debugPrint('Creating farm with data: ${requestData.toString()}');
      debugPrint('Polygon points: ${polygonData.length}');

      final response = await dio.post(
        ApiConstants.farms,
        data: requestData,
      );
      return FarmModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final errorMessage = _extractErrorMessage(e.response?.data, 'Failed to create farm');
        debugPrint('Server error: $statusCode');
        debugPrint('Error message: $errorMessage');
        debugPrint('Response data: ${e.response?.data}');
        debugPrint('Request data sent: ${e.requestOptions.data}');
        throw Exception('Server error ($statusCode): $errorMessage');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error creating farm: $e');
      rethrow;
    }
  }

  @override
  Future<Farm> updateFarm(String id, UpdateFarmRequest request) async {
    try {
      if (request.isEmpty) {
        throw Exception('UpdateFarmRequest must have at least one field to update');
      }

      final data = <String, dynamic>{};
      if (request.name != null) data['name'] = request.name;
      if (request.type != null) data['type'] = _typeToString(request.type!);
      if (request.polygon != null) {
        data['polygon'] = request.polygon!.map((p) => <String, dynamic>{
          'latitude': p.latitude,
          'longitude': p.longitude,
        }).toList();
      }

      final response = await dio.put('${ApiConstants.farms}/$id', data: data);
      return FarmModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(_extractErrorMessage(e.response?.data, 'Failed to update farm'));
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<void> deleteFarm(String id) async {
    try {
      await dio.delete('${ApiConstants.farms}/$id');
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(_extractErrorMessage(e.response?.data, 'Failed to delete farm'));
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  String _typeToString(FarmType type) {
    switch (type) {
      case FarmType.grapes:
        return 'GRAPES';
      case FarmType.wheat:
        return 'WHEAT';
      case FarmType.corn:
        return 'CORN';
      case FarmType.tomatoes:
        return 'TOMATOES';
      case FarmType.olives:
        return 'OLIVES';
      case FarmType.dates:
        return 'DATES';
    }
  }
}

