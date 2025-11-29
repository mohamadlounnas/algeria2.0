import '../entities/farm.dart';

class UpdateFarmRequest {
  final String? name;
  final FarmType? type;
  final List<LatLng>? polygon;

  const UpdateFarmRequest({
    this.name,
    this.type,
    this.polygon,
  });

  bool get isEmpty => name == null && type == null && polygon == null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateFarmRequest &&
        other.name == name &&
        other.type == type &&
        _listEquals(other.polygon, polygon);
  }

  @override
  int get hashCode => name.hashCode ^ type.hashCode ^ (polygon?.hashCode ?? 0);

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

