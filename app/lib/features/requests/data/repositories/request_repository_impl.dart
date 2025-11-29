import 'dart:convert';
import 'package:dio/dio.dart';
import '../../domain/entities/request.dart';
import '../../domain/repositories/request_repository.dart';
import '../../domain/dto/create_request_request.dart';
import '../../domain/dto/update_request_request.dart';
import '../../domain/dto/upload_image_request.dart';
import '../models/request_model.dart';
import '../../../../core/constants/api_constants.dart';

class RequestRepositoryImpl implements RequestRepository {
  final Dio dio;

  RequestRepositoryImpl({required this.dio});

  @override
  Future<List<Request>> getRequests({String? farmId}) async {
    try {
      final queryParams = farmId != null ? '?farmId=$farmId' : '';
      final response = await dio.get('${ApiConstants.requests}$queryParams');
      final data = response.data;
      final requestsList = data is List ? data : (data['data'] ?? []);
      return (requestsList as List)
          .map((r) => RequestModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get requests');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<Request> getRequestById(String id) async {
    try {
      final response = await dio.get('${ApiConstants.requests}/$id');
      return RequestModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Request not found');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<Request> createRequest(CreateRequestRequest request) async {
    try {
      final response = await dio.post(
        ApiConstants.requests,
        data: {'farmId': request.farmId},
      );
      return RequestModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to create request');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<Request> updateRequest(String id, UpdateRequestRequest request) async {
    try {
      if (request.isEmpty) {
        throw Exception('UpdateRequestRequest must have at least one field to update');
      }

      final data = <String, dynamic>{};
      if (request.note != null) data['note'] = request.note;
      if (request.expertIntervention != null) data['expertIntervention'] = request.expertIntervention;

      final response = await dio.put(
        '${ApiConstants.requests}/$id',
        data: data,
      );
      return RequestModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to update request');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<Request> sendRequest(String id) async {
    try {
      final response = await dio.post('${ApiConstants.requests}/$id/send');
      return RequestModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to send request');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<RequestImage> uploadImage(String requestId, UploadImageRequest request) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(request.filePath),
        'type': request.type == ImageType.normal ? 'NORMAL' : 'MACRO',
        'latitude': request.latitude.toString(),
        'longitude': request.longitude.toString(),
      });

      final response = await dio.post(
        '${ApiConstants.requests}/$requestId/images',
        data: formData,
      );

      return RequestImageModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to upload image');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<List<RequestImage>> bulkUploadImages(
    String requestId,
    List<UploadImageRequest> images,
  ) async {
    try {
      if (images.isEmpty) {
        throw Exception('At least one image is required for bulk upload');
      }

      // Prepare form data with multiple files
      final formData = FormData();

      // Add all files
      for (var image in images) {
        formData.files.add(
          MapEntry(
            'files[]',
            await MultipartFile.fromFile(image.filePath),
          ),
        );
      }

      // Add metadata as JSON string
      final imagesMetadata = images.map((img) => {
        'type': img.type == ImageType.normal ? 'NORMAL' : 'MACRO',
        'latitude': img.latitude,
        'longitude': img.longitude,
      }).toList();

      formData.fields.add(
        MapEntry('images', jsonEncode(imagesMetadata)),
      );

      final response = await dio.post(
        '${ApiConstants.requests}/$requestId/images/bulk',
        data: formData,
      );

      // Parse response
      final responseData = response.data as Map<String, dynamic>;
      final imagesList = responseData['images'] as List<dynamic>;

      return imagesList
          .map((img) => RequestImageModel.fromJson(img as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Failed to upload images';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  @override
  Future<String?> getReport(String id) async {
    try {
      final response = await dio.get('${ApiConstants.requests}/$id/report');
      return response.data['report'] as String?;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get report');
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}

