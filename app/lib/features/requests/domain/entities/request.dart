enum RequestStatus {
  draft,
  pending,
  accepted,
  processing,
  processed,
  completed,
}

class Request {
  final String id;
  final String farmId;
  final RequestStatus status;
  final bool expertIntervention;
  final String? note;
  final String? finalReport;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<RequestImage> images;

  const Request({
    required this.id,
    required this.farmId,
    required this.status,
    this.expertIntervention = false,
    this.note,
    this.finalReport,
    required this.createdAt,
    this.completedAt,
    this.images = const [],
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Request &&
        other.id == id &&
        other.farmId == farmId &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(id, farmId, status);
}

enum ImageType {
  normal,
  macro,
}

enum ImageStatus {
  pending,
  uploaded,
  processing,
  processed,
  failed,
}

class RequestImage {
  final String id;
  final String requestId;
  final ImageType type;
  final ImageStatus status;
  final String filePath;
  final double latitude;
  final double longitude;
  final String? diseaseType;
  final double? confidence;
  final String? treatmentPlan;
  final String? materials;
  final String? services;
  final DateTime? processedAt;
  final DateTime createdAt;

  const RequestImage({
    required this.id,
    required this.requestId,
    required this.type,
    required this.status,
    required this.filePath,
    required this.latitude,
    required this.longitude,
    this.diseaseType,
    this.confidence,
    this.treatmentPlan,
    this.materials,
    this.services,
    this.processedAt,
    required this.createdAt,
  });

  /// Get full URL for the image
  String getImageUrl(String baseUrl) {
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }
    // Remove leading slash if present
    final path = filePath.startsWith('/') ? filePath.substring(1) : filePath;
    return '$baseUrl/$path';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RequestImage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

