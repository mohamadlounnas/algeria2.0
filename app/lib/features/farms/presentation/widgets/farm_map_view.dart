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

  List<latlng.LatLng> _getEditorPoints(domain.Farm? farm) {
    return farm?.polygon
            .map((p) => latlng.LatLng(p.latitude, p.longitude))
            .toList() ??
        <latlng.LatLng>[];
  }

  List<latlng.LatLng> _getRequestPoints(List<req_domain.RequestImage> images) {
    return images
        .map((image) => latlng.LatLng(image.latitude, image.longitude))
        .toList();
  }

  List<Map<String, double>> _getFarmPolygon(domain.Farm? farm) {
    return farm?.polygon
            .map((point) => {
                  'latitude': point.latitude,
                  'longitude': point.longitude,
                })
            .toList() ??
        <Map<String, double>>[];
  }

  @override
  Widget build(BuildContext context) {
    final requestProvider = RequestProvider.of(context);
    final farmProvider = FarmProvider.of(context);
    final requests = requestProvider?.requests ?? const <req_domain.Request>[];
    final farmIndex =
        farmProvider?.farms.indexWhere((f) => f.id == widget.farmId) ?? -1;
    final farm = farmIndex != -1 ? farmProvider!.farms[farmIndex] : null;
    final polygonData = _getFarmPolygon(farm);
    final highlightMarkers = _getRequestPoints(requests.expand((r) => r.images).toList());

    final activePolygon = _editedPolygon ?? polygonData;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: PolygonMapEditor(
              onPolygonUpdated: _onPolygonUpdated,
              initialPoints: _getEditorPoints(farm),
              highlightMarkers: highlightMarkers,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Boundary points: ${activePolygon.length}'),
              if (highlightMarkers.isNotEmpty)
                Text('${highlightMarkers.length} request markers shown'),
            ],
          ),
        ],
      ),
    );
  }
}
