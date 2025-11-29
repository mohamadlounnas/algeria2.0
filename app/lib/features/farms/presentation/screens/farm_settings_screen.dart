import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../providers/farm_provider.dart';
import '../../domain/entities/farm.dart' as domain;
import '../../domain/dto/update_farm_request.dart';
import '../widgets/farm_type_selector.dart';
import '../widgets/polygon_map_editor.dart';
import '../../../../core/routing/app_router.dart';

class FarmSettingsScreen extends StatefulWidget {
  final String farmId;

  const FarmSettingsScreen({super.key, required this.farmId});

  @override
  State<FarmSettingsScreen> createState() => _FarmSettingsScreenState();
}

class _FarmSettingsScreenState extends State<FarmSettingsScreen> {
  final _nameController = TextEditingController();
  domain.FarmType _selectedType = domain.FarmType.grapes;
  List<Map<String, double>> _polygon = [];
  bool _isEditingPolygon = false;
  bool _isLoading = false;
  bool _initialized = false;

  bool _polygonsEqual(List<Map<String, double>> other) {
    if (_polygon.length != other.length) return false;
    for (var i = 0; i < _polygon.length; i++) {
      final current = _polygon[i];
      final next = other[i];
      if ((current['latitude'] ?? 0) != (next['latitude'] ?? 0) ||
          (current['longitude'] ?? 0) != (next['longitude'] ?? 0)) {
        return false;
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromProvider();
    });
  }

  void _initializeFromProvider() {
    final provider = FarmProvider.of(context);
    if (provider == null) {
      return;
    }

    final farmIndex = provider.farms.indexWhere((f) => f.id == widget.farmId);
    if (farmIndex == -1) {
      provider.loadFarms?.call();
      return;
    }

    final farm = provider.farms[farmIndex];
    final polygonPoints = farm.polygon
        .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
        .toList();

    if (_initialized &&
        _nameController.text == farm.name &&
        _selectedType == farm.type &&
        _polygonsEqual(polygonPoints)) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _nameController.text = farm.name;
      _selectedType = farm.type;
      _polygon = polygonPoints;
      _initialized = true;
    });
  }

  // Convert Map to latlong.LatLng for the editor
  List<latlong.LatLng> _getEditorPoints() {
    return _polygon
        .map(
          (p) => latlong.LatLng(
            p['latitude']?.toDouble() ?? 0.0,
            p['longitude']?.toDouble() ?? 0.0,
          ),
        )
        .toList();
  }

  // Convert Map to domain.LatLng for the API
  List<domain.LatLng> _getDomainPoints() {
    return _polygon
        .map(
          (p) => domain.LatLng(
            latitude: p['latitude']?.toDouble() ?? 0.0,
            longitude: p['longitude']?.toDouble() ?? 0.0,
          ),
        )
        .toList();
  }

  void _onPolygonUpdated(List<Map<String, double>> polygon) {
    setState(() {
      _polygon = polygon;
    });
  }

  String _farmTypeToString(domain.FarmType type) {
    switch (type) {
      case domain.FarmType.grapes:
        return 'GRAPES';
      case domain.FarmType.wheat:
        return 'WHEAT';
      case domain.FarmType.corn:
        return 'CORN';
      case domain.FarmType.tomatoes:
        return 'TOMATOES';
      case domain.FarmType.olives:
        return 'OLIVES';
      case domain.FarmType.dates:
        return 'DATES';
    }
  }

  domain.FarmType _stringToFarmType(String type) {
    switch (type.toUpperCase()) {
      case 'GRAPES':
        return domain.FarmType.grapes;
      case 'WHEAT':
        return domain.FarmType.wheat;
      case 'CORN':
        return domain.FarmType.corn;
      case 'TOMATOES':
        return domain.FarmType.tomatoes;
      case 'OLIVES':
        return domain.FarmType.olives;
      case 'DATES':
        return domain.FarmType.dates;
      default:
        return domain.FarmType.grapes;
    }
  }

  void _showToast(String title, String message, {bool isError = false}) {
    showToast(
      context: context,
      builder: (context, overlay) => SurfaceCard(
        child: Basic(
          title: Text(title),
          subtitle: Text(message),
          leading: Icon(
            isError ? RadixIcons.exclamationTriangle : RadixIcons.check,
            color: isError ? Colors.red : Colors.green,
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

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      _showToast('Error', 'Please enter a farm name', isError: true);
      return;
    }

    if (_polygon.length < 3) {
      _showToast('Error', 'Polygon must have at least 3 points', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final provider = FarmProvider.of(context);
      final request = UpdateFarmRequest(
        name: _nameController.text.trim(),
        type: _selectedType,
        polygon: _getDomainPoints(),
      );

      await provider?.updateFarm?.call(widget.farmId, request);

      if (mounted) {
        _showToast('Success', 'Farm updated successfully');
        setState(() => _isEditingPolygon = false);
      }
    } catch (e) {
      if (mounted) {
        _showToast('Error', e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteFarm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Farm'),
        content: const Text(
          'Are you sure you want to delete this farm? This action cannot be undone.',
        ),
        actions: [
          OutlineButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          DestructiveButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final provider = FarmProvider.of(context);
        await provider?.deleteFarm?.call(widget.farmId);

        if (mounted) {
          Navigator.of(context).popUntil(
            (route) => route.settings.name == AppRoutes.farms || route.isFirst,
          );
        }
      } catch (e) {
        if (mounted) {
          _showToast('Error', e.toString(), isError: true);
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = FarmProvider.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_initialized) {
      if (provider?.isLoading == true) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Center(child: Text('Loading farm details...'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Farm Settings').h2(),
          const Gap(24),

          // General Info Section
          const Text('General Information').h4(),
          const Gap(8),
          Card(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  placeholder: const Text('Farm Name'),
                ),
                const Gap(16),
                FarmTypeSelector(
                  selectedType: _farmTypeToString(_selectedType),
                  onTypeSelected: (type) {
                    setState(() {
                      _selectedType = _stringToFarmType(type);
                    });
                  },
                ),
              ],
            ),
          ),
          const Gap(24),

          // Location Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Farm Boundary').h4(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditingPolygon = !_isEditingPolygon;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      _isEditingPolygon ? RadixIcons.check : RadixIcons.pencil1,
                    ),
                    const Gap(8),
                    Text(_isEditingPolygon ? 'Done' : 'Edit Map'),
                  ],
                ),
              ),
            ],
          ),
          const Gap(8),
          Card(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 400,
              child: PolygonMapEditor(
                onPolygonUpdated: _onPolygonUpdated,
                initialPoints: _getEditorPoints(),
              ),
            ),
          ),

          const Gap(32),

          // Actions
          PrimaryButton(
            onPressed: _saveChanges,
            child: const Text('Save Changes'),
          ),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            child: DestructiveButton(
              onPressed: _deleteFarm,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(RadixIcons.trash), Gap(8), Text('Delete Farm')],
              ),
            ),
          ),
          const Gap(32),
        ],
      ),
    );
  }
}
