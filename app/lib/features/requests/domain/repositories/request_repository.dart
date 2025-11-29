import '../entities/request.dart';
import '../dto/create_request_request.dart';
import '../dto/update_request_request.dart';
import '../dto/upload_image_request.dart';

abstract class RequestRepository {
  Future<List<Request>> getRequests({String? farmId});
  Future<Request> getRequestById(String id);
  Future<Request> createRequest(CreateRequestRequest request);
  Future<Request> updateRequest(String id, UpdateRequestRequest request);
  Future<Request> sendRequest(String id);
  Future<RequestImage> uploadImage(String requestId, UploadImageRequest request);
  Future<List<RequestImage>> bulkUploadImages(
    String requestId,
    List<UploadImageRequest> images,
  );
  Future<String?> getReport(String id);
  Future<RequestImage> reanalyseImage(String imageId);
  Future<void> deleteImage(String imageId);
}

