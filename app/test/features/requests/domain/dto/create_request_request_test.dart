import 'package:flutter_test/flutter_test.dart';
import 'package:dowa/features/requests/domain/dto/create_request_request.dart';

void main() {
  group('CreateRequestRequest', () {
    test('should create request with farmId', () {
      const request = CreateRequestRequest(farmId: 'farm123');

      expect(request.farmId, 'farm123');
    });

    test('should be equal when farmId matches', () {
      const request1 = CreateRequestRequest(farmId: 'farm123');
      const request2 = CreateRequestRequest(farmId: 'farm123');

      expect(request1, request2);
    });

    test('should not be equal when farmId differs', () {
      const request1 = CreateRequestRequest(farmId: 'farm123');
      const request2 = CreateRequestRequest(farmId: 'farm456');

      expect(request1, isNot(request2));
    });
  });
}

