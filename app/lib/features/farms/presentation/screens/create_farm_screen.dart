import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../providers/farm_provider.dart';
import '../../domain/entities/farm.dart';
import '../../domain/dto/create_farm_request.dart';
import '../widgets/farm_type_selector.dart';
import '../widgets/polygon_map_editor.dart';

class CreateFarmScreen extends StatefulWidget {
  const CreateFarmScreen({super.key});

  @override
  State<CreateFarmScreen> createState() => _CreateFarmScreenState();
}

class _CreateFarmScreenState extends State<CreateFarmScreen> {
  final _nameController = TextEditingController();
  FarmType _selectedType = FarmType.grapes;
  List<Map<String, double>> _polygon = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onPolygonUpdated(List<Map<String, double>> polygon) {
    setState(() {
      _polygon = polygon;
    });
  }

  List<LatLng> _convertPolygon() {
    return _polygon
        .map(
          (p) => LatLng(
            latitude: p['latitude']?.toDouble() ?? 0.0,
            longitude: p['longitude']?.toDouble() ?? 0.0,
          ),
        )
        .toList();
  }

  FarmType _stringToFarmType(String type) {
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

  String _farmTypeToString(FarmType type) {
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

  void _showError(String message) {
    showToast(
      context: context,
      builder: (context, overlay) => SurfaceCard(
        child: Basic(
          title: const Text('Error'),
          subtitle: Text(message),
          leading: const Icon(
            RadixIcons.exclamationTriangle,
            color: Colors.red,
          ),
          trailing: GhostButton(
            onPressed: () => overlay.close(),
            child: const Icon(RadixIcons.cross1),
          ),
        ),
      ),
      location: ToastLocation.bottomRight,
    );
  }

  Future<void> _saveFarm() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter a farm name');
      return;
    }

    if (_polygon.length < 3) {
      _showError('Please draw a polygon with at least 3 points on the map');
      return;
    }

    final provider = FarmProvider.of(context);
    if (provider == null) return;

    final convertedPolygon = _convertPolygon();

    // Validate polygon points are valid
    for (final point in convertedPolygon) {
      if (point.latitude < -90 || point.latitude > 90) {
        _showError('Invalid latitude. Must be between -90 and 90');
        return;
      }
      if (point.longitude < -180 || point.longitude > 180) {
        _showError('Invalid longitude. Must be between -180 and 180');
        return;
      }
    }

    try {
      final request = CreateFarmRequest(
        name: _nameController.text.trim(),
        type: _selectedType,
        polygon: convertedPolygon,
      );

      await provider.createFarm?.call(request);

      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) => SurfaceCard(
            child: Basic(
              title: const Text('Success'),
              subtitle: const Text('Farm created successfully'),
              leading: const Icon(RadixIcons.check, color: Colors.green),
            ),
          ),
          location: ToastLocation.bottomRight,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text('Create New Farm').h3(),
          leading: [
            OutlineButton(
              density: ButtonDensity.icon,
              onPressed: () => Navigator.of(context).pop(),
              child: const Icon(RadixIcons.arrowLeft),
            ),
          ],
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              padding: const EdgeInsets.all(24),
              child: TextField(
                controller: _nameController,
                placeholder: const Text('Farm Name'),
              ),
            ),
            const Gap(16),
            Card(
              padding: const EdgeInsets.all(24),
              child: FarmTypeSelector(
                selectedType: _farmTypeToString(_selectedType),
                onTypeSelected: (type) {
                  setState(() {
                    _selectedType = _stringToFarmType(type);
                  });
                },
              ),
            ),
            const Gap(16),
            Card(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Farm Boundary').h4(),
                  const Gap(16),
                  SizedBox(
                    height: 400,
                    child: PolygonMapEditor(
                      onPolygonUpdated: _onPolygonUpdated,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(24),
            PrimaryButton(onPressed: _saveFarm, child: const Text('Save Farm')),
          ],
        ),
      ),
    );
  }
}
