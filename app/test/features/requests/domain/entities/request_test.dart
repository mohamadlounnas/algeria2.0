import 'package:flutter_test/flutter_test.dart';
import 'package:dowa/features/requests/domain/entities/request.dart';

void main() {
  group('Request Entity', () {
    test('should create a request with all properties', () {
      final request = Request(
        id: 'request-1',
        farmId: 'farm-1',
        status: RequestStatus.draft,
        expertIntervention: false,
        note: 'Test note',
        createdAt: DateTime.now(),
        images: [],
      );

      expect(request.id, equals('request-1'));
      expect(request.farmId, equals('farm-1'));
      expect(request.status, equals(RequestStatus.draft));
      expect(request.expertIntervention, isFalse);
      expect(request.note, equals('Test note'));
    });

    test('should support all request statuses', () {
      final statuses = [
        RequestStatus.draft,
        RequestStatus.pending,
        RequestStatus.accepted,
        RequestStatus.processing,
        RequestStatus.processed,
        RequestStatus.completed,
      ];

      for (final status in statuses) {
        final request = Request(
          id: 'request-1',
          farmId: 'farm-1',
          status: status,
          createdAt: DateTime.now(),
        );
        expect(request.status, equals(status));
      }
    });
  });

  group('RequestImage Entity', () {
    test('should create RequestImage with all properties', () {
      final image = RequestImage(
        id: 'image-1',
        requestId: 'request-1',
        type: ImageType.normal,
        status: ImageStatus.pending,
        filePath: '/path/to/image.jpg',
        latitude: 36.7538,
        longitude: 3.0588,
        diseaseType: 'Leaf Spot',
        confidence: 0.85,
        createdAt: DateTime.now(),
      );

      expect(image.id, equals('image-1'));
      expect(image.type, equals(ImageType.normal));
      expect(image.diseaseType, equals('Leaf Spot'));
      expect(image.confidence, equals(0.85));
    });

    test('should support both image types', () {
      final normalImage = RequestImage(
        id: 'image-1',
        requestId: 'request-1',
        type: ImageType.normal,
        status: ImageStatus.pending,
        filePath: '/path/to/image.jpg',
        latitude: 36.7538,
        longitude: 3.0588,
        createdAt: DateTime.now(),
      );

      final macroImage = RequestImage(
        id: 'image-2',
        requestId: 'request-1',
        type: ImageType.macro,
        status: ImageStatus.pending,
        filePath: '/path/to/image.jpg',
        latitude: 36.7538,
        longitude: 3.0588,
        createdAt: DateTime.now(),
      );

      expect(normalImage.type, equals(ImageType.normal));
      expect(macroImage.type, equals(ImageType.macro));
    });
  });
}

