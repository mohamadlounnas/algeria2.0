import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;
import '../../../requests/domain/entities/request.dart' as req_domain;
import '../providers/farm_provider.dart';
import '../../../requests/presentation/providers/request_provider.dart';
import '../widgets/polygon_map_editor.dart';
import '../../domain/entities/farm.dart' as domain;

class FarmMapView extends StatefulWidget {
  final String farmId;

  const FarmMapView({super.key, required this.farmId});

  @override
  State<FarmMapView> createState() => _FarmMapViewState();
}

class _FarmMapViewState extends State<FarmMapView> {
  List<Map<String, double>>? _editedPolygon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reqProvider = RequestProvider.of(context);
      reqProvider?.loadRequests?.call(widget.farmId);

      final farmProvider = FarmProvider.of(context);
      if (farmProvider != null && farmProvider.farms.isEmpty) {
        farmProvider.loadFarms?.call();
      }
    });
  }

  void _onPolygonUpdated(List<Map<String, double>> polygon) {
    setState(() {
      _editedPolygon = polygon;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: _FarmMapBody(
              farmId: widget.farmId,
              editedPolygon: _editedPolygon,
              onPolygonUpdated: _onPolygonUpdated,
            ),
          ),
          const SizedBox(height: 12),
          _FarmMapStats(
            farmId: widget.farmId,
            editedPolygon: _editedPolygon,
          ),
        ],
      ),
    );
  }
}

class _FarmMapBody extends StatelessWidget {
  final String farmId;
  final List<Map<String, double>>? editedPolygon;
  final ValueChanged<List<Map<String, double>>> onPolygonUpdated;

  const _FarmMapBody({
    required this.farmId,
    required this.editedPolygon,
    required this.onPolygonUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final farmProvider = FarmProvider.of(context);
    final requestProvider = RequestProvider.of(context);
    final domain.Farm? farm = farmProvider?.farms.firstWhereOrNull((f) => f.id == farmId);
    final requests = requestProvider?.requests ?? const <req_domain.Request>[];
    final highlightMarkers = requests
      .expand((r) => r.images)
      .map((image) => latlng.LatLng(image.latitude, image.longitude))
      .toList();
    final initialPoints = editedPolygon != null
      ? (editedPolygon ?? [])!
        .map((point) => latlng.LatLng(
            point['latitude'] ?? 0,
            point['longitude'] ?? 0,
          ))
        .toList()
      : farm?.polygon
          .map((p) => latlng.LatLng(p.latitude, p.longitude))
          .toList() ??
        const <latlng.LatLng>[];
    return PolygonMapEditor(
      onPolygonUpdated: onPolygonUpdated,
      initialPoints: initialPoints,
      highlightMarkers: highlightMarkers,
    );
  }
}

class _FarmMapStats extends StatelessWidget {
  final String farmId;
  final List<Map<String, double>>? editedPolygon;

  const _FarmMapStats({
    required this.farmId,
    required this.editedPolygon,
  });

  @override
  Widget build(BuildContext context) {
    final farmProvider = FarmProvider.of(context);
    final requestProvider = RequestProvider.of(context);
    final domain.Farm? farm = farmProvider?.farms.firstWhereOrNull((f) => f.id == farmId);
    final polygon = editedPolygon ?? farm?.polygon.map((point) => {
          'latitude': point.latitude,
          'longitude': point.longitude,
        }).toList() ??
        const <Map<String, double>>[];
    final markerCount = requestProvider
            ?.requests
            .expand((r) => r.images)
            .length ??
        0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Boundary points: ${polygon.length}'),
        if (markerCount > 0) Text('$markerCount request markers shown'),
      ],
    );
  }
}
