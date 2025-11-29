import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart' as material;

class PolygonMapEditor extends StatefulWidget {
  final Function(List<Map<String, double>>) onPolygonUpdated;
  final List<LatLng>? initialPoints;

  const PolygonMapEditor({
    super.key,
    required this.onPolygonUpdated,
    this.initialPoints,
  });

  @override
  State<PolygonMapEditor> createState() => _PolygonMapEditorState();
}

class _PolygonMapEditorState extends State<PolygonMapEditor> {
  final MapController _mapController = MapController();
  List<LatLng> _points = [];
  LatLng? _previewPoint;
  bool _editingComplete = false;

  void _onTap(LatLng point) {
    setState(() {
      _points.add(point);
      _updatePolygon();
    });
  }

  void _updatePolygon() {
    final polygon = _points
        .map((p) => <String, double>{'latitude': p.latitude, 'longitude': p.longitude})
        .toList();
    widget.onPolygonUpdated(polygon);
  }

  void _clearPolygon() {
    setState(() {
      _points.clear();
      _updatePolygon();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.of(context).size.width < 600;

    final map = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(36.7538, 3.0588), // Algeria center
        initialZoom: 13.0,
        onTap: (tapPosition, point) => _onTap(point),
        onPositionChanged: (mapPosition, hasGesture) {
          setState(() {
            _previewPoint = mapPosition.center;
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.dowa',
        ),
        if (_points.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(points: _points, strokeWidth: 2.0, color: theme.colorScheme.primary),
            ],
          ),
        if (_points.length > 1) ..._closingDotMarkers(_points, theme.colorScheme.primary),
        if (_points.isNotEmpty)
          MarkerLayer(
            markers: _points
                .map((point) => Marker(
                      point: point,
                      width: isNarrow ? 10 : 12,
                      height: isNarrow ? 10 : 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.destructive,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: isNarrow ? 1.5 : 2),
                        ),
                      ),
                    ))
                .toList(),
          ),
        if (_previewPoint != null && !_editingComplete)
          MarkerLayer(
            markers: [
              Marker(
                point: _previewPoint!,
                width: isNarrow ? 10 : 12,
                height: isNarrow ? 10 : 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.destructive.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: material.Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        if (_previewPoint != null && _points.isNotEmpty && !_editingComplete)
          ..._previewDotMarkers(_previewPoint!, _points, theme.colorScheme.primary),
      ],
    );

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              map,
              if (!_editingComplete)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Column(
                    mainAxisSize: material.MainAxisSize.min,
                    children: [
                      _floatingIconButton(
                        icon: material.Icons.add_location_alt,
                        tooltip: 'Pin',
                        onPressed: () {
                          if (_previewPoint != null) {
                            setState(() {
                              _points.add(_previewPoint!);
                              _updatePolygon();
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _floatingIconButton(
                        icon: material.Icons.undo,
                        tooltip: 'Undo',
                        onPressed: () {
                          setState(() {
                            if (_points.isNotEmpty) {
                              _points.removeLast();
                              _updatePolygon();
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _floatingIconButton(icon: material.Icons.clear, tooltip: 'Clear', onPressed: _clearPolygon),
                      const SizedBox(height: 8),
                      _floatingIconButton(
                        icon: material.Icons.check,
                        tooltip: 'Done',
                        onPressed: () {
                          setState(() {
                            _editingComplete = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: material.Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${_points.length} points', style: TextStyle(color: material.Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _floatingIconButton({required IconData icon, required String tooltip, required VoidCallback onPressed}) {
    final isNarrow = MediaQuery.of(context).size.width < 600;
    return material.GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isNarrow ? 40 : 46,
        height: isNarrow ? 40 : 46,
        decoration: BoxDecoration(
          color: material.Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [BoxShadow(color: material.Colors.black.withOpacity(0.12), blurRadius: 6)],
        ),
        child: Icon(icon, size: isNarrow ? 18 : 20),
      ),
    );
  }

  List<MarkerLayer> _closingDotMarkers(List<LatLng> points, Color color) {
    final layers = <MarkerLayer>[];
    if (points.length < 2) return layers;
    final start = points.first;
    final end = points.last;
    final dots = _computeDotsBetween(start, end, color);
    layers.add(MarkerLayer(markers: dots));
    return layers;
  }

  List<MarkerLayer> _previewDotMarkers(LatLng preview, List<LatLng> points, Color color) {
    final layers = <MarkerLayer>[];
    if (points.isEmpty) return layers;
    final first = points.first;
    final last = points.last;
    final dotsToFirst = _computeDotsBetween(preview, first, color);
    final dotsToLast = _computeDotsBetween(preview, last, color);
    layers.add(MarkerLayer(markers: dotsToFirst));
    layers.add(MarkerLayer(markers: dotsToLast));
    return layers;
  }

  List<Marker> _computeDotsBetween(LatLng a, LatLng b, Color color) {
    final meters = _distanceMeters(a, b);
    final desiredSpacing = 40.0;
    int numDots = (meters / desiredSpacing).floor();
    if (numDots < 1) numDots = 1;
    if (numDots > 40) numDots = 40;
    final markers = <Marker>[];
    for (var i = 1; i <= numDots; i++) {
      final t = i / (numDots + 1);
      final lat = a.latitude + (b.latitude - a.latitude) * t;
      final lng = a.longitude + (b.longitude - a.longitude) * t;
      markers.add(Marker(
        point: LatLng(lat, lng),
        width: 6,
        height: 6,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
      ));
    }
    return markers;
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const R = 6371000; // meters
    double toRad(double deg) => deg * 3.141592653589793 / 180.0;
    final dLat = toRad(b.latitude - a.latitude);
    final dLon = toRad(b.longitude - a.longitude);
    final lat1 = toRad(a.latitude);
    final lat2 = toRad(b.latitude);
    final sinDlat = math.sin(dLat / 2);
    final sinDlon = math.sin(dLon / 2);
    final h = sinDlat * sinDlat + math.cos(lat1) * math.cos(lat2) * sinDlon * sinDlon;
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return R * c;
  }
}
