import 'package:flutter/material.dart';
import '../../domain/entities/request.dart';
import '../../domain/repositories/request_repository.dart';
import '../../domain/dto/create_request_request.dart';
import '../../domain/dto/update_request_request.dart';
import '../../domain/dto/upload_image_request.dart';
import '../../data/repositories/request_repository_impl.dart';
import '../../../../core/di/di_provider.dart';

class RequestProvider extends InheritedWidget {
  final List<Request> requests;
  final bool isLoading;
  final Future<void> Function(String)? loadRequests;
  final Future<String?> Function(String)? createRequest;
  final Future<void> Function(String, RequestImage)? addImage;
  final Future<void> Function(String)? sendRequest;
  final Future<void> Function(String, UpdateRequestRequest)? updateRequest;
  final Future<String?> Function(String)? generateAiReport;
  final Future<void> Function(String, UploadImageRequest)? uploadImage;
  final Future<void> Function(String, List<UploadImageRequest>)? bulkUploadImages;
  final Future<Request?> Function(String)? fetchRequest;
  final Future<void> Function(String imageId, String requestId)? reanalyseImage;
  final Future<void> Function(String imageId, String requestId)? deleteImage;

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
    this.generateAiReport,
    this.uploadImage,
    this.bulkUploadImages,
    this.fetchRequest,
    this.reanalyseImage,
    this.deleteImage,
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
  RequestRepository? _requestRepository;
  final Set<String> _hydratingRequestIds = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestRepository == null) {
      final dioClient = DiProvider.getDioClient(context);
      _requestRepository = RequestRepositoryImpl(dio: dioClient.dio);
    }
  }

  Future<void> _loadRequests(String farmId) async {
    if (_requestRepository == null) return;
    
    setState(() => _isLoading = true);
    try {
      final requests = await _requestRepository!.getRequests(farmId: farmId);
      setState(() => _requests = requests);
      await _hydrateRequestImages(requests);
    } catch (e) {
      debugPrint('Error loading requests: $e');
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _hydrateRequestImages(List<Request> requests) async {
    if (_requestRepository == null) return;
    final idsToHydrate = requests
        .where((request) => request.images.isEmpty)
        .map((request) => request.id)
        .where((id) => !_hydratingRequestIds.contains(id))
        .toList();

    for (final requestId in idsToHydrate) {
      _hydratingRequestIds.add(requestId);
      try {
        final detailedRequest = await _requestRepository!.getRequestById(requestId);
        _replaceRequestInState(detailedRequest, addIfMissing: true);
      } catch (e) {
        debugPrint('Error hydrating request $requestId: $e');
      } finally {
        _hydratingRequestIds.remove(requestId);
      }
    }
  }

  Future<String?> _createRequest(String farmId) async {
    if (_requestRepository == null) return null;
    
    setState(() => _isLoading = true);
    try {
      final requestDto = CreateRequestRequest(farmId: farmId);
      final request = await _requestRepository!.createRequest(requestDto);
      setState(() => _requests = [..._requests, request]);
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
      // Refresh request to get updated images
      final request = await _requestRepository!.getRequestById(requestId);
      _replaceRequestInState(request);
    } catch (e) {
      debugPrint('Error adding image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendRequest(String requestId) async {
    if (_requestRepository == null) return;

    setState(() => _isLoading = true);
    try {
      await _requestRepository!.sendRequest(requestId);
      // Refresh request to pick up images + latest metadata after status change
      final refreshed = await _requestRepository!.getRequestById(requestId);
      _replaceRequestInState(refreshed, addIfMissing: true);
    } catch (e) {
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _generateAiReport(String requestId) async {
    if (_requestRepository == null) return null;

    setState(() => _isLoading = true);
    try {
      final report = await _requestRepository!.generateAiReport(requestId);
      final refreshed = await _requestRepository!.getRequestById(requestId);
      _replaceRequestInState(refreshed, addIfMissing: true);
      return report;
    } catch (e) {
      debugPrint('Error generating AI report: $e');
      return null;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRequest(String requestId, UpdateRequestRequest request) async {
    if (_requestRepository == null) return;
    
    setState(() => _isLoading = true);
    try {
      final updatedRequest = await _requestRepository!.updateRequest(requestId, request);
      _replaceRequestInState(updatedRequest, addIfMissing: true);
    } catch (e) {
      debugPrint('Error updating request: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadImage(String requestId, UploadImageRequest request) async {
    if (_requestRepository == null) return;
    
    setState(() => _isLoading = true);
    try {
      await _requestRepository!.uploadImage(requestId, request);
      // Refresh request to get updated images
      final updatedRequest = await _requestRepository!.getRequestById(requestId);
      _replaceRequestInState(updatedRequest);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _bulkUploadImages(
    String requestId,
    List<UploadImageRequest> images,
  ) async {
    if (_requestRepository == null) return;
    
    setState(() => _isLoading = true);
    try {
      await _requestRepository!.bulkUploadImages(requestId, images);
      // Refresh request to get updated images
      final updatedRequest = await _requestRepository!.getRequestById(requestId);
      _replaceRequestInState(updatedRequest);
    } catch (e) {
      debugPrint('Error bulk uploading images: $e');
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Request?> _fetchRequest(String requestId) async {
    if (_requestRepository == null) return null;

    _hydratingRequestIds.add(requestId);
    try {
      final request = await _requestRepository!.getRequestById(requestId);
      _replaceRequestInState(request, addIfMissing: true);
      return request;
    } catch (e) {
      debugPrint('Error fetching request $requestId: $e');
      return null;
    } finally {
      _hydratingRequestIds.remove(requestId);
    }
  }

  Future<void> _reanalyseImage(String imageId, String requestId) async {
    if (_requestRepository == null) return;
    setState(() => _isLoading = true);
    try {
      await _requestRepository!.reanalyseImage(imageId);
      // Refresh parent request to update image status/details
      final updatedRequest = await _requestRepository!.getRequestById(requestId);
      _replaceRequestInState(updatedRequest, addIfMissing: true);
    } catch (e) {
      debugPrint('Error reanalysing image $imageId: $e');
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteImage(String imageId, String requestId) async {
    if (_requestRepository == null) return;
    setState(() => _isLoading = true);
    try {
      await _requestRepository!.deleteImage(imageId);
      final updatedRequest = await _requestRepository!.getRequestById(requestId);
      _replaceRequestInState(updatedRequest, addIfMissing: true);
    } catch (e) {
      debugPrint('Error deleting image $imageId: $e');
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _replaceRequestInState(Request request, {bool addIfMissing = false}) {
    setState(() {
      final updated = List<Request>.from(_requests);
      final index = updated.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        updated[index] = request;
      } else if (addIfMissing) {
        updated.add(request);
      }
      _requests = updated;
    });
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
      generateAiReport: _generateAiReport,
      uploadImage: _uploadImage,
      bulkUploadImages: _bulkUploadImages,
      fetchRequest: _fetchRequest,
      reanalyseImage: _reanalyseImage,
      deleteImage: _deleteImage,
      child: widget.child,
    );
  }
}

