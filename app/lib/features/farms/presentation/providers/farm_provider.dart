import 'package:flutter/material.dart';
import '../../domain/entities/farm.dart';
import '../../domain/repositories/farm_repository.dart';
import '../../domain/dto/create_farm_request.dart';
import '../../domain/dto/update_farm_request.dart';
import '../../data/repositories/farm_repository_impl.dart';
import '../../../../core/di/di_provider.dart';

class FarmProvider extends InheritedWidget {
  final List<Farm> farms;
  final bool isLoading;
  final Future<void> Function()? loadFarms;
  final Future<void> Function(CreateFarmRequest)? createFarm;
  final Future<void> Function(String, UpdateFarmRequest)? updateFarm;
  final Future<void> Function(String)? deleteFarm;

  const FarmProvider({
    super.key,
    required super.child,
    this.farms = const [],
    this.isLoading = false,
    this.loadFarms,
    this.createFarm,
    this.updateFarm,
    this.deleteFarm,
  });

  static FarmProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FarmProvider>();
  }

  @override
  bool updateShouldNotify(FarmProvider oldWidget) {
    return farms != oldWidget.farms || isLoading != oldWidget.isLoading;
  }
}

class FarmProviderState extends StatefulWidget {
  final Widget child;

  const FarmProviderState({super.key, required this.child});

  @override
  State<FarmProviderState> createState() => _FarmProviderStateState();
}

class _FarmProviderStateState extends State<FarmProviderState> {
  List<Farm> _farms = [];
  bool _isLoading = false;
  FarmRepository? _farmRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_farmRepository == null) {
      final dioClient = DiProvider.getDioClient(context);
      // Ensure token is loaded from SharedPreferences (fire and forget)
      dioClient.loadToken().catchError((e) {
        debugPrint('⚠️ Failed to load token in FarmProvider: $e');
      });
      _farmRepository = FarmRepositoryImpl(dio: dioClient.dio);
    }
  }

  Future<void> _loadFarms() async {
    if (_farmRepository == null) return;
    
    setState(() => _isLoading = true);
    try {
      final farms = await _farmRepository!.getFarms();
      setState(() => _farms = farms);
    } catch (e) {
      debugPrint('Error loading farms: $e');
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createFarm(CreateFarmRequest request) async {
    if (_farmRepository == null) return;
    
    setState(() => _isLoading = true);
    try {
      final newFarm = await _farmRepository!.createFarm(request);
      setState(() => _farms.add(newFarm));
    } catch (e) {
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateFarm(String id, UpdateFarmRequest request) async {
    if (_farmRepository == null) return;
    
    setState(() => _isLoading = true);
    try {
      final updatedFarm = await _farmRepository!.updateFarm(id, request);
      final index = _farms.indexWhere((f) => f.id == id);
      if (index != -1) {
        setState(() => _farms[index] = updatedFarm);
      } else {
        setState(() => _farms.add(updatedFarm));
      }
    } catch (e) {
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFarm(String id) async {
    if (_farmRepository == null) return;
    
    setState(() => _isLoading = true);
    try {
      await _farmRepository!.deleteFarm(id);
      setState(() => _farms.removeWhere((f) => f.id == id));
    } catch (e) {
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FarmProvider(
      farms: _farms,
      isLoading: _isLoading,
      loadFarms: _loadFarms,
      createFarm: _createFarm,
      updateFarm: _updateFarm,
      deleteFarm: _deleteFarm,
      child: widget.child,
    );
  }
}

