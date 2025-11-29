import '../entities/farm.dart';

class CreateFarmRequest {
  final String name;
  final FarmType type;
  final List<LatLng> polygon;

  const CreateFarmRequest({
    required this.name,
    required this.type,
    required this.polygon,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateFarmRequest &&
        other.name == name &&
        other.type == type &&
        _listEquals(other.polygon, polygon);
  }

  @override
  int get hashCode => name.hashCode ^ type.hashCode ^ Object.hashAll(polygon);

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

