import '../entities/request.dart';

class UploadImageRequest {
  final String filePath;
  final ImageType type;
  final double latitude;
  final double longitude;

  const UploadImageRequest({
    required this.filePath,
    required this.type,
    required this.latitude,
    required this.longitude,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UploadImageRequest &&
        other.filePath == filePath &&
        other.type == type &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode =>
      filePath.hashCode ^
      type.hashCode ^
      latitude.hashCode ^
      longitude.hashCode;
}

