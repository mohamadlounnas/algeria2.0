import 'package:flutter_test/flutter_test.dart';
import 'package:dowa/features/requests/domain/dto/update_request_request.dart';

void main() {
  group('UpdateRequestRequest', () {
    test('should create request with all fields null', () {
      const request = UpdateRequestRequest();

      expect(request.note, null);
      expect(request.expertIntervention, null);
      expect(request.isEmpty, true);
    });

    test('should create request with note only', () {
      const request = UpdateRequestRequest(note: 'Test note');

      expect(request.note, 'Test note');
      expect(request.expertIntervention, null);
      expect(request.isEmpty, false);
    });

    test('should create request with expertIntervention only', () {
      const request = UpdateRequestRequest(expertIntervention: true);

      expect(request.note, null);
      expect(request.expertIntervention, true);
      expect(request.isEmpty, false);
    });

    test('should create request with all fields', () {
      const request = UpdateRequestRequest(
        note: 'Test note',
        expertIntervention: true,
      );

      expect(request.note, 'Test note');
      expect(request.expertIntervention, true);
      expect(request.isEmpty, false);
    });

    test('should be equal when all properties match', () {
      const request1 = UpdateRequestRequest(
        note: 'Test',
        expertIntervention: true,
      );
      const request2 = UpdateRequestRequest(
        note: 'Test',
        expertIntervention: true,
      );

      expect(request1, request2);
    });

    test('should not be equal when properties differ', () {
      const request1 = UpdateRequestRequest(note: 'Note 1');
      const request2 = UpdateRequestRequest(note: 'Note 2');

      expect(request1, isNot(request2));
    });
  });
}

