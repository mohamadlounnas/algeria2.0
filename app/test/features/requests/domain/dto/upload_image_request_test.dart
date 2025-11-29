import 'package:flutter_test/flutter_test.dart';
import 'package:dowa/features/requests/domain/dto/upload_image_request.dart';
import 'package:dowa/features/requests/domain/entities/request.dart';

void main() {
  group('UploadImageRequest', () {
    test('should create request with all required fields', () {
      const request = UploadImageRequest(
        filePath: '/path/to/image.jpg',
        type: ImageType.normal,
        latitude: 36.7538,
        longitude: 3.0588,
      );

      expect(request.filePath, '/path/to/image.jpg');
      expect(request.type, ImageType.normal);
      expect(request.latitude, 36.7538);
      expect(request.longitude, 3.0588);
    });

    test('should support both image types', () {
      const normalRequest = UploadImageRequest(
        filePath: '/path/to/image.jpg',
        type: ImageType.normal,
        latitude: 36.7538,
        longitude: 3.0588,
      );
      const macroRequest = UploadImageRequest(
        filePath: '/path/to/image.jpg',
        type: ImageType.macro,
        latitude: 36.7538,
        longitude: 3.0588,
      );

      expect(normalRequest.type, ImageType.normal);
      expect(macroRequest.type, ImageType.macro);
    });

    test('should be equal when all properties match', () {
      const request1 = UploadImageRequest(
        filePath: '/path/to/image.jpg',
        type: ImageType.normal,
        latitude: 36.7538,
        longitude: 3.0588,
      );
      const request2 = UploadImageRequest(
        filePath: '/path/to/image.jpg',
        type: ImageType.normal,
        latitude: 36.7538,
        longitude: 3.0588,
      );

      expect(request1, request2);
    });

    test('should not be equal when properties differ', () {
      const request1 = UploadImageRequest(
        filePath: '/path/to/image1.jpg',
        type: ImageType.normal,
        latitude: 36.7538,
        longitude: 3.0588,
      );
      const request2 = UploadImageRequest(
        filePath: '/path/to/image2.jpg',
        type: ImageType.normal,
        latitude: 36.7538,
        longitude: 3.0588,
      );

      expect(request1, isNot(request2));
    });
  });
}

