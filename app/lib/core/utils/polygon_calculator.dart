import 'dart:math';

class LatLng {
  final double latitude;
  final double longitude;

  LatLng({required this.latitude, required this.longitude});
}

class PolygonCalculator {
  /// Calculate area of polygon in square meters using shoelace formula
  static double calculateArea(List<LatLng> polygon) {
    if (polygon.length < 3) return 0.0;

    const double earthRadiusM = 6371000.0; // Earth radius in meters

    double area = 0.0;
    for (int i = 0; i < polygon.length; i++) {
      int j = (i + 1) % polygon.length;
      
      double lat1 = polygon[i].latitude * pi / 180;
      double lat2 = polygon[j].latitude * pi / 180;
      double lon1 = polygon[i].longitude * pi / 180;
      double lon2 = polygon[j].longitude * pi / 180;

      area += (lon2 - lon1) * (2 + sin(lat1) + sin(lat2)) * earthRadiusM * earthRadiusM;
    }

    return (area.abs() / 2.0);
  }
}

