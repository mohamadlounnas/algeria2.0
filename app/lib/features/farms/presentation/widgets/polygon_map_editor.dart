import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.initialPoints != null) {
      _points = List.from(widget.initialPoints!);
    }
  }

  void _onTap(LatLng point) {
    setState(() {
      _points.add(point);
      _updatePolygon();
    });
  }

  void _updatePolygon() {
    final polygon = _points
        .map(
          (p) => <String, double>{
            'latitude': p.latitude,
            'longitude': p.longitude,
          },
        )
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
    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(36.7538, 3.0588), // Algeria center
              initialZoom: 13.0,
              onTap: (tapPosition, point) => _onTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dowa',
              ),
              if (_points.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _points,
                      strokeWidth: 2.0,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              if (_points.isNotEmpty)
                MarkerLayer(
                  markers: _points
                      .map(
                        (point) => Marker(
                          point: point,
                          child: Icon(
                            RadixIcons.drawingPinFilled,
                            color: theme.colorScheme.destructive,
                            size: 30,
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
        if (_points.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('${_points.length} points').muted(),
                GhostButton(
                  onPressed: _clearPolygon,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
