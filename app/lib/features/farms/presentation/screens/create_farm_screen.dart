import 'package:shadcn_flutter/shadcn_flutter.dart';
// Widget uses shadcn_flutter components and built-in layout, no direct material import

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
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildStepIndicatorVertical() {
    final steps = ['Name', 'Type', 'Location'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final active = _currentStep == i;
        return GestureDetector(
          onTap: () => setState(() => _currentStep = i),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: active ? Theme.of(context).colorScheme.primary.withOpacity(0.08) : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    border: Border.all(color: Theme.of(context).colorScheme.primary),
                    shape: BoxShape.circle,
                  ),
                  child: Text('${i + 1}'),
                ),
                const Gap(12),
                Text(steps[i]).h4(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Farm Name').h4(),
            const Gap(12),
            TextField(controller: _nameController, placeholder: const Text('Farm Name')),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Farm Type').h4(),
            const Gap(12),
            FarmTypeSelector(
              selectedType: _farmTypeToString(_selectedType),
              onTypeSelected: (type) => setState(() => _selectedType = _stringToFarmType(type)),
            ),
          ],
        );
      case 2:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Farm Boundary').h4(),
            const Gap(12),
            Expanded(child: PolygonMapEditor(onPolygonUpdated: _onPolygonUpdated)),
            const Gap(8),
            Text('Points: ${_polygon.length}'),
          ],
        );
    }
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            // Two-column layout for wide screens, stacked layout for narrow screens.
            if (isWide) {
              return Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Left side: step overview + small forms
                        Flexible(
                          flex: 3,
                          child: Card(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStepIndicatorVertical(),
                                const Gap(12),
                                // Show active step content
                                Expanded(child: _buildStepContent()),
                              ],
                            ),
                          ),
                        ),
                        const Gap(16),
                        // Right side: Map / preview
                        Flexible(
                          flex: 7,
                          child: Card(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('Farm Boundary').h4(),
                                const Gap(12),
                                Expanded(
                                  child: PolygonMapEditor(
                                    onPolygonUpdated: _onPolygonUpdated,
                                  ),
                                ),
                                const Gap(8),
                                Text('Points: ${_polygon.length}'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom: controls
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlineButton(
                            onPressed: () {
                              if (_currentStep == 0) return Navigator.of(context).pop();
                              setState(() => _currentStep -= 1);
                            },
                            child: Text(_currentStep == 0 ? 'Cancel' : 'Prev'),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: PrimaryButton(
                            onPressed: () async {
                              final lastStep = 2;
                              final valid = _validateStep(_currentStep);
                              if (!valid) return;
                              if (_currentStep < lastStep) {
                                setState(() => _currentStep += 1);
                                return;
                              }
                              await _saveFarm();
                            },
                            child: Text(_currentStep == 2 ? 'Save Farm' : 'Next'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // Narrow layout: stacked with content taking full width and map filling space
            return Column(
              children: [
                Expanded(child: Card(padding: const EdgeInsets.all(16), child: _buildStepContent())),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlineButton(
                          onPressed: () {
                            if (_currentStep == 0) return Navigator.of(context).pop();
                            setState(() => _currentStep -= 1);
                          },
                          child: Text(_currentStep == 0 ? 'Cancel' : 'Prev'),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: PrimaryButton(
                          onPressed: () async {
                            final lastStep = 2;
                            final valid = _validateStep(_currentStep);
                            if (!valid) return;
                            if (_currentStep < lastStep) {
                              setState(() => _currentStep += 1);
                              return;
                            }
                            await _saveFarm();
                          },
                          child: Text(_currentStep == 2 ? 'Save Farm' : 'Next'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_nameController.text.trim().isEmpty) {
          _showError('Please enter a farm name');
          return false;
        }
        return true;
      case 1:
        // For now, type always has a default; add extra validation if needed
        return true;
      case 2:
        if (_polygon.length < 3) {
          _showError('Please draw a polygon with at least 3 points on the map');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  // No local _stepState helper needed anymore since we're using full-screen steps.
}
