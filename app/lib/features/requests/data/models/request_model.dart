import '../../domain/entities/request.dart';

class RequestModel extends Request {
  const RequestModel({
    required super.id,
    required super.farmId,
    required super.status,
    super.expertIntervention,
    super.note,
    super.finalReport,
    required super.createdAt,
    super.completedAt,
    super.images,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    // Handle expertIntervention - can be bool, int (0/1), or null
    bool expertIntervention = false;
    final expertInterventionValue = json['expertIntervention'];
    if (expertInterventionValue != null) {
      if (expertInterventionValue is bool) {
        expertIntervention = expertInterventionValue;
      } else if (expertInterventionValue is int) {
        expertIntervention = expertInterventionValue != 0;
      } else if (expertInterventionValue is num) {
        expertIntervention = expertInterventionValue != 0;
      }
    }

    return RequestModel(
      id: json['id'] as String,
      farmId: json['farmId'] as String,
      status: _statusFromString(json['status'] as String),
      expertIntervention: expertIntervention,
      note: json['note'] as String?,
      finalReport: json['finalReport'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      images: (json['images'] as List<dynamic>?)
              ?.map((i) => RequestImageModel.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static RequestStatus _statusFromString(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return RequestStatus.draft;
      case 'PENDING':
        return RequestStatus.pending;
      case 'ACCEPTED':
        return RequestStatus.accepted;
      case 'PROCESSING':
        return RequestStatus.processing;
      case 'PROCESSED':
        return RequestStatus.processed;
      case 'COMPLETED':
        return RequestStatus.completed;
      default:
        return RequestStatus.draft;
    }
  }
}

class RequestImageModel extends RequestImage {
  const RequestImageModel({
    required super.id,
    required super.requestId,
    required super.type,
    required super.status,
    required super.filePath,
    required super.latitude,
    required super.longitude,
    super.diseaseType,
    super.confidence,
    super.treatmentPlan,
    super.materials,
    super.services,
    super.processedAt,
    required super.createdAt,
  });

  factory RequestImageModel.fromJson(Map<String, dynamic> json) {
    return RequestImageModel(
      id: json['id'] as String,
      requestId: json['requestId'] as String,
      type: _typeFromString(json['type'] as String),
      status: _statusFromString(json['status'] as String? ?? 'PENDING'),
      filePath: json['filePath'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      diseaseType: json['diseaseType'] as String?,
      confidence: json['confidence'] != null
          ? (json['confidence'] as num).toDouble()
          : null,
      treatmentPlan: json['treatmentPlan'] as String?,
      materials: json['materials'] as String?,
      services: json['services'] as String?,
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static ImageType _typeFromString(String type) {
    switch (type.toUpperCase()) {
      case 'NORMAL':
        return ImageType.normal;
      case 'MACRO':
        return ImageType.macro;
      default:
        return ImageType.normal;
    }
  }

  static ImageStatus _statusFromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return ImageStatus.pending;
      case 'UPLOADED':
        return ImageStatus.uploaded;
      case 'PROCESSING':
        return ImageStatus.processing;
      case 'PROCESSED':
        return ImageStatus.processed;
      case 'FAILED':
        return ImageStatus.failed;
      default:
        return ImageStatus.pending;
    }
  }
}

