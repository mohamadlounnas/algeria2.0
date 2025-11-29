enum FarmType {
  grapes,
  wheat,
  corn,
  tomatoes,
  olives,
  dates,
}

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng({
    required this.latitude,
    required this.longitude,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatLng &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

class Farm {
  final String id;
  final String userId;
  final String name;
  final FarmType type;
  final List<LatLng> polygon;
  final double area;

  const Farm({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.polygon,
    required this.area,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Farm &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.type == type &&
        other.area == area;
  }

  @override
  int get hashCode => Object.hash(id, userId, name, type, area);
}

