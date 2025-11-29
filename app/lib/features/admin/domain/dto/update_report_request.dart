class UpdateReportRequest {
  final String report;

  const UpdateReportRequest({
    required this.report,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateReportRequest && other.report == report;
  }

  @override
  int get hashCode => report.hashCode;
}

