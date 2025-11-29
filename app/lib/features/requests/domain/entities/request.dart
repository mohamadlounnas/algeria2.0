enum RequestStatus {
  draft,
  pending,
  accepted,
  processing,
  processed,
  completed,
}

/// Bounding box coordinates
class BoundingBox {
  final int x1;
  final int y1;
  final int x2;
  final int y2;

  const BoundingBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x1: json['x1'] as int,
      y1: json['y1'] as int,
      x2: json['x2'] as int,
      y2: json['y2'] as int,
    );
  }
}

/// Single leaf analysis data from AI
class LeafData {
  final String? image;
  final String? heatmap;
  final String? overlay;
  final BoundingBox? bbox;
  final Map<String, dynamic> diseases;
  final double anomalyScore;
  final bool isDiseased;

  const LeafData({
    this.image,
    this.heatmap,
    this.overlay,
    this.bbox,
    required this.diseases,
    required this.anomalyScore,
    required this.isDiseased,
  });

  factory LeafData.fromJson(Map<String, dynamic> json) {
    BoundingBox? bbox;
    final bboxJson = json['bbox'];
    if (bboxJson is Map<String, dynamic>) {
      try {
        bbox = BoundingBox.fromJson(bboxJson);
      } catch (e) {
        // Ignore bbox parse errors
      }
    }

    return LeafData(
      image: json['image'] as String?,
      heatmap: json['heatmap'] as String?,
      overlay: json['overlay'] as String?,
      bbox: bbox,
      diseases: json['diseases'] as Map<String, dynamic>? ?? {},
      anomalyScore: (json['anomaly_score'] as num?)?.toDouble() ?? 0.0,
      isDiseased: json['is_diseased'] == true,
    );
  }
}

/// Summary statistics from AI analysis
class SummaryData {
  final int totalLeafs;
  final int diseasedLeafs;
  final int healthyLeafs;

  const SummaryData({
    required this.totalLeafs,
    required this.diseasedLeafs,
    required this.healthyLeafs,
  });

  factory SummaryData.fromJson(Map<String, dynamic> json) {
    return SummaryData(
      totalLeafs: json['total_leafs'] as int? ?? 0,
      diseasedLeafs: json['diseased_leafs'] as int? ?? 0,
      healthyLeafs: json['healthy_leafs'] as int? ?? 0,
    );
  }
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
  final String? imageUrl;
  final String? heatmapUrl;
  final String? overlayUrl;
  final double? anomalyScore;
  final bool? isDiseased;
  final String? diseasesJson;
  final List<LeafData>? leafs;
  final SummaryData? summary;
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
    this.imageUrl,
    this.heatmapUrl,
    this.overlayUrl,
    this.anomalyScore,
    this.isDiseased,
    this.diseasesJson,
    this.leafs,
    this.summary,
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

