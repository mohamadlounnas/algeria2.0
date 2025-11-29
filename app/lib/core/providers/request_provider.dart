import 'package:flutter/material.dart';
import '../../shared/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';

enum RequestStatus {
  draft,
  pending,
  accepted,
  processing,
  processed,
  completed,
}

class Request {
  final String id;
  final String farmId;
  final RequestStatus status;
  final bool expertIntervention;
  final String? note;
  final String? finalReport;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<RequestImage> images;

  Request({
    required this.id,
    required this.farmId,
    required this.status,
    this.expertIntervention = false,
    this.note,
    this.finalReport,
    required this.createdAt,
    this.completedAt,
    this.images = const [],
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      id: json['id'] as String,
      farmId: json['farmId'] as String,
      status: _statusFromString(json['status'] as String),
      expertIntervention: json['expertIntervention'] as bool? ?? false,
      note: json['note'] as String?,
      finalReport: json['finalReport'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      images: (json['images'] as List<dynamic>?)
              ?.map((i) => RequestImage.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static RequestStatus _statusFromString(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return RequestStatus.draft;
      case 'PENDING':
        return RequestStatus.pending;
      case 'ACCEPTED':
        return RequestStatus.accepted;
      case 'PROCESSING':
        return RequestStatus.processing;
      case 'PROCESSED':
        return RequestStatus.processed;
      case 'COMPLETED':
        return RequestStatus.completed;
      default:
        return RequestStatus.draft;
    }
  }
}

class RequestImage {
  final String id;
  final String requestId;
  final String type; // NORMAL or MACRO
  final String filePath;
  final double latitude;
  final double longitude;
  final String? diseaseType;
  final double? confidence;
  final String? treatmentPlan;
  final String? materials;
  final String? services;
  final DateTime? processedAt;
  final DateTime createdAt;

  RequestImage({
    required this.id,
    required this.requestId,
    required this.type,
    required this.filePath,
    required this.latitude,
    required this.longitude,
    this.diseaseType,
    this.confidence,
    this.treatmentPlan,
    this.materials,
    this.services,
    this.processedAt,
    required this.createdAt,
  });

  factory RequestImage.fromJson(Map<String, dynamic> json) {
    return RequestImage(
      id: json['id'] as String,
      requestId: json['requestId'] as String,
      type: json['type'] as String,
      filePath: json['filePath'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      diseaseType: json['diseaseType'] as String?,
      confidence: json['confidence'] != null
          ? (json['confidence'] as num).toDouble()
          : null,
      treatmentPlan: json['treatmentPlan'] as String?,
      materials: json['materials'] as String?,
      services: json['services'] as String?,
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class RequestProvider extends InheritedWidget {
  final List<Request> requests;
  final bool isLoading;
  final Function(String)? loadRequests;
  final Future<String?> Function(String)? createRequest;
  final Function(String, RequestImage)? addImage;
  final Function(String)? sendRequest;
  final Future<void> Function(String, {String? note, bool? expertIntervention})? updateRequest;

  const RequestProvider({
    super.key,
    required super.child,
    this.requests = const [],
    this.isLoading = false,
    this.loadRequests,
    this.createRequest,
    this.addImage,
    this.sendRequest,
    this.updateRequest,
  });

  static RequestProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RequestProvider>();
  }

  @override
  bool updateShouldNotify(RequestProvider oldWidget) {
    return requests != oldWidget.requests || isLoading != oldWidget.isLoading;
  }
}

class RequestProviderState extends StatefulWidget {
  final Widget child;

  const RequestProviderState({super.key, required this.child});

  @override
  State<RequestProviderState> createState() => _RequestProviderStateState();
}

class _RequestProviderStateState extends State<RequestProviderState> {
  List<Request> _requests = [];
  bool _isLoading = false;
  late final ApiService _apiService;
  
  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    // Load token from storage initially
    _apiService.loadToken();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync token from AuthProvider when dependencies change
    final authProvider = AuthProvider.of(context);
    if (authProvider?.token != null && _apiService.token != authProvider!.token) {
      _apiService.setToken(authProvider.token!);
    }
  }
  
  Future<void> _ensureTokenLoaded() async {
    // Get token from AuthProvider
    final authProvider = AuthProvider.of(context);
    if (authProvider?.token != null && _apiService.token != authProvider!.token) {
      _apiService.setToken(authProvider.token!);
    } else if (_apiService.token == null) {
      // Try to load from storage
      await _apiService.loadToken();
    }
  }

  Future<void> _loadRequests(String farmId) async {
    setState(() => _isLoading = true);
    try {
      await _ensureTokenLoaded();
      final response = await _apiService.get('${ApiConstants.requests}?farmId=$farmId');
      final requestsList = response is List ? response : (response['data'] ?? []);
      if (requestsList is List) {
        _requests = requestsList.map((r) => Request.fromJson(r as Map<String, dynamic>)).toList();
      } else {
        _requests = [];
      }
    } catch (e) {
      debugPrint('Error loading requests: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _createRequest(String farmId) async {
    setState(() => _isLoading = true);
    try {
      await _ensureTokenLoaded();
      final response = await _apiService.post(
        ApiConstants.requests,
        {
          'farmId': farmId,
        },
      );
      final request = Request.fromJson(response as Map<String, dynamic>);
      _requests.add(request);
      return request.id;
    } catch (e) {
      debugPrint('Error creating request: $e');
      return null;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addImage(String requestId, RequestImage image) async {
    setState(() => _isLoading = true);
    try {
      // Image upload is handled by ImageService, this just refreshes the request
      await _updateRequest(requestId);
    } catch (e) {
      debugPrint('Error adding image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendRequest(String requestId) async {
    setState(() => _isLoading = true);
    try {
      await _ensureTokenLoaded();
      await _apiService.post(
        '${ApiConstants.requests}/$requestId/send',
        null,
      );
      await _updateRequest(requestId);
    } catch (e) {
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRequest(String requestId, {String? note, bool? expertIntervention}) async {
    setState(() => _isLoading = true);
    try {
      await _ensureTokenLoaded();
      final updateData = <String, dynamic>{};
      if (note != null) updateData['note'] = note;
      if (expertIntervention != null) updateData['expertIntervention'] = expertIntervention;
      
      await _apiService.put(
        '${ApiConstants.requests}/$requestId',
        updateData.isEmpty ? null : updateData,
      );
      
      // Refresh request (token already ensured above)
      final response = await _apiService.get('${ApiConstants.requests}/$requestId');
      final request = Request.fromJson(response as Map<String, dynamic>);
      final index = _requests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        _requests[index] = request;
      } else {
        _requests.add(request);
      }
    } catch (e) {
      debugPrint('Error updating request: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RequestProvider(
      requests: _requests,
      isLoading: _isLoading,
      loadRequests: _loadRequests,
      createRequest: _createRequest,
      addImage: _addImage,
      sendRequest: _sendRequest,
      updateRequest: _updateRequest,
      child: widget.child,
    );
  }
}

