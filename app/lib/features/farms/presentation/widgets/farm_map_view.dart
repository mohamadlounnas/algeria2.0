import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import '../../../requests/domain/entities/request.dart' as req_domain;
import '../providers/farm_provider.dart';
import '../../../requests/presentation/providers/request_provider.dart';

class FarmMapView extends StatefulWidget {
  final String farmId;

  const FarmMapView({super.key, required this.farmId});

  @override
  State<FarmMapView> createState() => _FarmMapViewState();
}

class _FarmMapViewState extends State<FarmMapView> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Load requests for the farm
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reqProvider = RequestProvider.of(context);
      reqProvider?.loadRequests?.call(widget.farmId);

      final farmProvider = FarmProvider.of(context);
      if (farmProvider != null && farmProvider.farms.isEmpty) {
        farmProvider.loadFarms?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final requestProvider = RequestProvider.of(context);
    final farmProvider = FarmProvider.of(context);
    final requests = requestProvider?.requests ?? const <req_domain.Request>[];
    final farmIndex = farmProvider?.farms.indexWhere((f) => f.id == widget.farmId) ?? -1;
    final farm = farmIndex != -1 ? farmProvider!.farms[farmIndex] : null;

    final images = requests.expand((r) => r.images).toList();

    // Convert farm polygon to latlong2
    final polygonPoints = farm?.polygon
            .map((p) => latlng.LatLng(p.latitude, p.longitude))
            .toList() ??
        <latlng.LatLng>[];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _attemptFitBounds(polygonPoints, images);
      } catch (_) {
        // Ignore, some map controller operations may fail early depending on the map package version
      }
    });

    if (images.isEmpty && polygonPoints.isEmpty) {
      return const Center(child: Text('No map data for this farm'));
    }

    final initialCenter = polygonPoints.isNotEmpty
        ? polygonPoints.first
        : (images.isNotEmpty
            ? latlng.LatLng(images.first.latitude, images.first.longitude)
            : latlng.LatLng(36.7538, 3.0588));

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.dowa',
        ),
        if (polygonPoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: polygonPoints,
                strokeWidth: 3.0,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          // Draw small dots between the last and first polygon points to indicate
          // that the polygon is closed (a visual dotted closing segment).
          if (polygonPoints.length > 1)
            MarkerLayer(
              markers: _closingDotMarkers(polygonPoints, Theme.of(context).colorScheme.primary),
            ),
        MarkerLayer(
          markers: images.asMap().entries.map((entry) {
            final idx = entry.key;
            final img = entry.value;
            final isLast = idx == images.length - 1;

            // All markers except the last one should be just red dots with a white 2px border.
            final color = isLast ? _imageStatusColor(img.status) : Colors.red;
            final borderWidth = isLast ? 1.5 : 2.0;
            return Marker(
              point: latlng.LatLng(img.latitude, img.longitude),
              width: 16,
              height: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: borderWidth),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Compute a list of small markers (dots) to render along the closing
  /// segment between the polygon's last and first points to visually
  /// indicate the polygon is closed. We distribute dots evenly along the
  /// line between the two points. The spacing is adjusted based on the
  /// geographic distance to avoid too many or too few dots.
  List<Marker> _closingDotMarkers(List<latlng.LatLng> polygonPoints, Color color) {
    if (polygonPoints.length < 2) return [];
    final start = polygonPoints.last;
    final end = polygonPoints.first;

    // Compute approximate geographic distance between start and end using
    // haversine formula so dot spacing can be reasonable in meters.
    double distanceMeters(latlng.LatLng a, latlng.LatLng b) {
      const R = 6371000; // Earth radius in meters
      double toRad(double deg) => deg * math.pi / 180.0;
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

    final meters = distanceMeters(start, end);

    // Choose spacing and number of dots based on length. Aim for ~30-60 meters
    // between dots but clamp the number to avoid overloading the map.
    final desiredSpacing = 40.0; // meters between dots
    int numDots = (meters / desiredSpacing).floor();
    if (numDots < 2) numDots = 2;
    if (numDots > 40) numDots = 40; // cap for performance

    final markers = <Marker>[];
    for (var i = 1; i <= numDots; i++) {
      final t = i / (numDots + 1);
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      markers.add(Marker(
        point: latlng.LatLng(lat, lng),
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

  void _attemptFitBounds(List<latlng.LatLng> polygonPoints, List<req_domain.RequestImage> images) {
    final points = <latlng.LatLng>[];
    points.addAll(polygonPoints);
    points.addAll(images.map((i) => latlng.LatLng(i.latitude, i.longitude)));
    if (points.isEmpty) return;

    final minLat = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    final maxLat = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    final minLng = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    final maxLng = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

    final center = latlng.LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    // Estimate zoom using a simple heuristic based on bounding box size
    final latDiff = (maxLat - minLat).abs();
    final lonDiff = (maxLng - minLng).abs();
    final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;
    double zoom = 14.0;
    if (maxDiff > 5) zoom = 6.0;
    else if (maxDiff > 1) zoom = 10.0;
    else if (maxDiff > 0.2) zoom = 12.0;
    else if (maxDiff > 0.05) zoom = 14.0;
    else zoom = 16.0;

    try {
      _mapController.move(center, zoom);
    } catch (_) {
      // ignore errors (map not ready or API different)
    }
  }

  Color _imageStatusColor(req_domain.ImageStatus status) {
    switch (status) {
      case req_domain.ImageStatus.pending:
        return const Color(0xFF9E9E9E);
      case req_domain.ImageStatus.uploaded:
        return Colors.blue;
      case req_domain.ImageStatus.processing:
        return Colors.orange;
      case req_domain.ImageStatus.processed:
        return Colors.green;
      case req_domain.ImageStatus.failed:
        return Colors.red;
    }
  }
}
