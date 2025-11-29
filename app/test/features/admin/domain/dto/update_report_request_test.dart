import 'package:flutter_test/flutter_test.dart';
import 'package:dowa/features/admin/domain/dto/update_report_request.dart';

void main() {
  group('UpdateReportRequest', () {
    test('should create request with report', () {
      const request = UpdateReportRequest(report: 'Test report content');

      expect(request.report, 'Test report content');
    });

    test('should handle empty report', () {
      const request = UpdateReportRequest(report: '');

      expect(request.report, '');
    });

    test('should handle long report', () {
      final longReport = 'A' * 1000;
      final request = UpdateReportRequest(report: longReport);

      expect(request.report, longReport);
      expect(request.report.length, 1000);
    });

    test('should be equal when reports match', () {
      const request1 = UpdateReportRequest(report: 'Test report');
      const request2 = UpdateReportRequest(report: 'Test report');

      expect(request1, request2);
    });

    test('should not be equal when reports differ', () {
      const request1 = UpdateReportRequest(report: 'Report 1');
      const request2 = UpdateReportRequest(report: 'Report 2');

      expect(request1, isNot(request2));
    });
  });
}

