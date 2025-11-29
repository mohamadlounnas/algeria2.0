import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import 'location_service.dart';

class ImageService {
  final ApiService apiService;
  final ImagePicker _picker = ImagePicker();

  ImageService(this.apiService);

  Future<Map<String, dynamic>> captureAndUploadImage({
    required String requestId,
    required String type, // 'NORMAL' or 'MACRO'
    required ImageSource source,
  }) async {
    // Capture image
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null) {
      throw Exception('No image selected');
    }

    // Get location
    final position = await LocationService.getCurrentLocation();
    if (position == null) {
      throw Exception('Location not available');
    }

    // Upload image
    final response = await apiService.postMultipart(
      '/api/requests/$requestId/images',
      image.path,
      {
        'type': type,
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
      },
    );

    return response;
  }
}

