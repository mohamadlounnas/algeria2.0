import 'dart:convert';
import '../../domain/entities/farm.dart';

class FarmModel extends Farm {
  const FarmModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.type,
    required super.polygon,
    required super.area,
  });

  factory FarmModel.fromJson(Map<String, dynamic> json) {
    // Parse polygon - handle both List and String (JSON string) formats
    List<LatLng> parsePolygon(dynamic polygonData) {
      if (polygonData is String) {
        // If it's a JSON string, parse it first
        final parsed = jsonDecode(polygonData) as List;
        return parsed.map((p) => _parseLatLng(p)).toList();
      } else if (polygonData is List) {
        return polygonData.map((p) => _parseLatLng(p)).toList();
      } else {
        throw FormatException('Invalid polygon format: $polygonData');
      }
    }

    return FarmModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      type: _typeFromString(json['type'] as String),
      polygon: parsePolygon(json['polygon']),
      area: (json['area'] as num).toDouble(),
    );
  }

  static LatLng _parseLatLng(dynamic p) {
    if (p is Map) {
      // Handle object format: {latitude: x, longitude: y}
      return LatLng(
        latitude: ((p['latitude'] ?? p['lat']) as num).toDouble(),
        longitude: ((p['longitude'] ?? p['lng'] ?? p['lon']) as num).toDouble(),
      );
    } else if (p is List && p.length >= 2) {
      // Handle array format: [lat, lng] or [lng, lat]
      return LatLng(
        latitude: (p[0] as num).toDouble(),
        longitude: (p[1] as num).toDouble(),
      );
    } else {
      throw FormatException('Invalid LatLng format: $p');
    }
  }

  static FarmType _typeFromString(String type) {
    switch (type.toUpperCase()) {
      case 'GRAPES':
        return FarmType.grapes;
      case 'WHEAT':
        return FarmType.wheat;
      case 'CORN':
        return FarmType.corn;
      case 'TOMATOES':
        return FarmType.tomatoes;
      case 'OLIVES':
        return FarmType.olives;
      case 'DATES':
        return FarmType.dates;
      default:
        return FarmType.grapes;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': _typeToString(type),
      'polygon': polygon.map((p) => {
        'latitude': p.latitude,
        'longitude': p.longitude,
      }).toList(),
      'area': area,
    };
  }

  static String _typeToString(FarmType type) {
    switch (type) {
      case FarmType.grapes:
        return 'GRAPES';
      case FarmType.wheat:
        return 'WHEAT';
      case FarmType.corn:
        return 'CORN';
      case FarmType.tomatoes:
        return 'TOMATOES';
      case FarmType.olives:
        return 'OLIVES';
      case FarmType.dates:
        return 'DATES';
    }
  }
}
