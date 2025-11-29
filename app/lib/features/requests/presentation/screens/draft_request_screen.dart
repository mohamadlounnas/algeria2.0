import 'dart:io';

import 'package:dowa/features/requests/presentation/widgets/disease_map_view.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../providers/request_provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/entities/request.dart';
import '../../domain/dto/upload_image_request.dart';
import '../../data/repositories/request_repository_impl.dart';
import '../../../../core/di/di_provider.dart';
import '../widgets/image_capture_buttons.dart';
import '../widgets/image_gallery.dart';
import '../widgets/disease_overview.dart';
import '../../../../shared/services/location_service.dart';
import 'dart:typed_data';

class DraftRequestScreen extends StatefulWidget {
  final String requestId;

  const DraftRequestScreen({super.key, required this.requestId});

  @override
  State<DraftRequestScreen> createState() => _DraftRequestScreenState();
}

class _DraftRequestScreenState extends State<DraftRequestScreen> {
  RequestRepositoryImpl? _requestRepository;
  Dio? _dio;
  bool _isLoading = false;
  bool _hasLoadedRequest = false;
  bool _isFetchingRequest = false;
  bool _isBulkUploading = false;
  Request? _detailedRequest;
  final List<_PendingImage> _pendingImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  // Add-from-URL state (shadcn-only UI)
  bool _showAddUrl = false;
  final TextEditingController _addUrlController = TextEditingController();
  ImageType _addUrlType = ImageType.normal;
  bool _addUrlBusy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestRepository == null) {
      final dioClient = DiProvider.getDioClient(context);
      _dio = dioClient.dio;
      _requestRepository = RequestRepositoryImpl(dio: _dio!);
      if (!_hasLoadedRequest) {
        _hasLoadedRequest = true;
        _loadRequest(showLoader: true);
      }
    }
  }

  Future<void> _loadRequest({bool showLoader = false}) async {
    if (_isFetchingRequest) return;

    final provider = RequestProvider.of(context);
    final canUseProviderFetch = provider?.fetchRequest != null;
    if (_requestRepository == null && !canUseProviderFetch) return;

    _isFetchingRequest = true;
    if (showLoader) {
      setState(() => _isLoading = true);
    }

    try {
      Request? request;
      if (canUseProviderFetch) {
        request = await provider!.fetchRequest!(widget.requestId);
      }
      if (request == null) {
        if (_requestRepository == null) {
          throw Exception('Request repository not available');
        }
        request = await _requestRepository!.getRequestById(widget.requestId);
      }
      if (!mounted) return;
      setState(() => _detailedRequest = request);
    } catch (e) {
      debugPrint('Error loading request: $e');
      if (showLoader) {
        _showToastMessage(
          'Failed to load request details. Please try again.',
          isError: true,
        );
      }
    } finally {
      _isFetchingRequest = false;
      if (showLoader && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addImage(ImageType type, {required ImageSource source}) async {
    if (_requestRepository == null) return;

    try {
      final hasPermission = await LocationService.ensureServiceAndPermission();
      if (!hasPermission) {
        _showToastMessage(
          'Location permission is required to tag your photos.',
          isError: true,
        );
        return;
      }

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: source == ImageSource.camera ? 85 : 90,
      );

      if (pickedFile == null) return;

      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        _showToastMessage(
          'Unable to get your location. Please try again.',
          isError: true,
        );
        return;
      }

      final uploadRequest = UploadImageRequest(
        filePath: pickedFile.path,
        type: type,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        _pendingImages.add(_PendingImage(request: uploadRequest));
      });

      _showToastMessage('Image ready to send. Tap "Send all" to upload.');
    } catch (e) {
      _showToastMessage('Error: $e', isError: true);
    }
  }

  void _openAddFromUrl() {
    setState(() {
      _showAddUrl = true;
      _addUrlBusy = false;
      // keep previous text if user toggles open/close
    });
  }

  void _cancelAddFromUrl() {
    setState(() {
      _showAddUrl = false;
      _addUrlBusy = false;
    });
  }

  Future<void> _confirmAddFromUrl() async {
    if (_requestRepository == null || _dio == null) return;
    final url = _addUrlController.text.trim();
    if (url.isEmpty || !url.startsWith('http')) {
      _showToastMessage('Please enter a valid URL', isError: true);
      return;
    }
    setState(() => _addUrlBusy = true);
    try {
      final hasPermission = await LocationService.ensureServiceAndPermission();
      if (!hasPermission) {
        _showToastMessage(
          'Location permission is required to tag your photos.',
          isError: true,
        );
        setState(() => _addUrlBusy = false);
        return;
      }

      final response = await _dio!.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null) {
        _showToastMessage('Failed to download image.', isError: true);
        setState(() => _addUrlBusy = false);
        return;
      }

      final ext = url.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final file = File(
        '${Directory.systemTemp.path}/dowa_${DateTime.now().microsecondsSinceEpoch}.$ext',
      );
      await file.writeAsBytes(bytes);

      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        _showToastMessage(
          'Unable to get your location. Please try again.',
          isError: true,
        );
        setState(() => _addUrlBusy = false);
        return;
      }

      final uploadRequest = UploadImageRequest(
        filePath: file.path,
        type: _addUrlType,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        _pendingImages.add(_PendingImage(request: uploadRequest));
        _addUrlBusy = false;
        _showAddUrl = false;
        _addUrlController.clear();
        _addUrlType = ImageType.normal;
      });
      _showToastMessage('Image ready to send. Tap "Send all" to upload.');
    } catch (e) {
      _showToastMessage('Failed to add image from URL: $e', isError: true);
      setState(() => _addUrlBusy = false);
    }
  }

  Future<bool> _uploadPendingImage(_PendingImage pending) async {
    final provider = RequestProvider.of(context);
    if (provider?.uploadImage == null) {
      _showToastMessage(
        'Unable to upload right now. Please try again later.',
        isError: true,
      );
      return false;
    }

    setState(() => pending.isUploading = true);
    try {
      await provider!.uploadImage!(widget.requestId, pending.request);
      setState(() {
        _pendingImages.removeWhere((p) => p.id == pending.id);
      });
      await _loadRequest(showLoader: false);
      return true;
    } catch (e) {
      _showToastMessage('Failed to upload image: $e', isError: true);
      setState(() => pending.isUploading = false);
      return false;
    }
  }

  Future<void> _sendAllPending() async {
    if (_pendingImages.isEmpty || _isBulkUploading) return;
    setState(() => _isBulkUploading = true);

    for (final pending in List<_PendingImage>.from(_pendingImages)) {
      await _uploadPendingImage(pending);
    }

    if (mounted) {
      setState(() => _isBulkUploading = false);
    }

    if (_pendingImages.isEmpty) {
      _showToastMessage('All images uploaded successfully.');
      await _loadRequest(showLoader: false);
    }
  }

  void _removePendingImage(_PendingImage pending) {
    if (pending.isUploading) return;
    setState(() {
      _pendingImages.removeWhere((p) => p.id == pending.id);
    });
  }

  void _showToastMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showToast(
        context: context,
        location: ToastLocation.bottomCenter,
        builder: (context, overlay) => Alert(
          destructive: isError,
          title: Text(message),
          trailing: IconButton.ghost(
            icon: const Icon(Icons.close),
            onPressed: overlay.close,
          ),
        ),
      );
    });
  }

  Future<void> _sendRequest() async {
    final provider = RequestProvider.of(context);
    try {
      await provider?.sendRequest?.call(widget.requestId);
      if (mounted) {
        // إعادة تحميل الطلب لتحديث حالته
        await _loadRequest(showLoader: false);
        _showToastMessage('Request sent successfully.');
      }
    } catch (e) {
      if (mounted) {
        _showToastMessage('Error sending request: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = RequestProvider.of(context);
    final requests = provider?.requests ?? <Request>[];
    Request? existing;
    for (final req in requests) {
      if (req.id == widget.requestId) {
        existing = req;
        break;
      }
    }

    final request =
        _detailedRequest ??
        existing ??
        Request(
          id: widget.requestId,
          farmId: '',
          status: RequestStatus.draft,
          createdAt: DateTime.now(),
          images: [],
        );

    final hasAnyRequestData = _detailedRequest != null || existing != null;
    final shouldBlockUi = _isLoading && !hasAnyRequestData;

    if (shouldBlockUi) {
      return const Scaffold(
      backgroundColor: Colors.transparent,child: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDraft = request.status == RequestStatus.draft;
    final requestLeafs = request.images.expand((image) => image.leafs ?? []).toList();
    final requestDiseaseEntries = diseaseEntriesFromLeafs(List<LeafData>.from([...requestLeafs])).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      headers: [
        AppBar(
          leading: [
            IconButton.ghost(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).maybePop();
              },
            ),
          ],
          title: Text(isDraft ? 'Draft Request' : 'Request Report'),
          trailing: [
            GhostButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              size: ButtonSize.small,
              child: Text(isDraft ? 'Save draft' : 'Close'),
            ),
            if (isDraft)
              PrimaryButton(
                onPressed: request.images.isNotEmpty
                    ? () {
                        _sendRequest();
                      }
                    : null,
                size: ButtonSize.small,
                child: const Text('Send'),
              ),
          ],
          trailingGap: 8,
        ),
      ],
      loadingProgressIndeterminate: _isLoading,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isDraft) ...[
              // تقرير الأمراض والمواقع والخريطة
              const SizedBox(height: 16),
              OutlinedContainer(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: DiseaseMapView(images: request.images),
                ),
              ),
              const SizedBox(height: 16),
              if (requestDiseaseEntries.isNotEmpty) ...[
                DiseaseOverview(entries: requestDiseaseEntries),
                const SizedBox(height: 16),
              ],
              // report of diseases summary
            ],
            if (isDraft)
              Card(
                padding: EdgeInsets.zero,
                filled: true,
                borderColor: colorScheme.border,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ImageCaptureButtons(
                    onNormalImage: () =>
                        _addImage(ImageType.normal, source: ImageSource.camera),
                    onMacroImage: () =>
                        _addImage(ImageType.macro, source: ImageSource.camera),
                    onNormalFromGallery: () => _addImage(
                      ImageType.normal,
                      source: ImageSource.gallery,
                    ),
                    onMacroFromGallery: () =>
                        _addImage(ImageType.macro, source: ImageSource.gallery),
                    onAddFromUrl: _openAddFromUrl,
                    pendingCount: _pendingImages.length,
                    isBusy: _isBulkUploading,
                  ),
                ),
              ),
            if (_showAddUrl) ...[
              const SizedBox(height: 12),
              Card(
                padding: const EdgeInsets.all(16),
                filled: true,
                borderColor: colorScheme.border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add image from URL',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addUrlController,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _addUrlType == ImageType.normal
                              ? PrimaryButton(
                                  onPressed: _addUrlBusy
                                      ? null
                                      : () => setState(
                                          () => _addUrlType = ImageType.normal,
                                        ),
                                  size: ButtonSize.small,
                                  child: const Text('Normal'),
                                )
                              : OutlineButton(
                                  onPressed: _addUrlBusy
                                      ? null
                                      : () => setState(
                                          () => _addUrlType = ImageType.normal,
                                        ),
                                  size: ButtonSize.small,
                                  child: const Text('Normal'),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _addUrlType == ImageType.macro
                              ? PrimaryButton(
                                  onPressed: _addUrlBusy
                                      ? null
                                      : () => setState(
                                          () => _addUrlType = ImageType.macro,
                                        ),
                                  size: ButtonSize.small,
                                  child: const Text('Macro'),
                                )
                              : OutlineButton(
                                  onPressed: _addUrlBusy
                                      ? null
                                      : () => setState(
                                          () => _addUrlType = ImageType.macro,
                                        ),
                                  size: ButtonSize.small,
                                  child: const Text('Macro'),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Spacer(),
                        GhostButton(
                          onPressed: _addUrlBusy ? null : _cancelAddFromUrl,
                          size: ButtonSize.small,
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        PrimaryButton(
                          onPressed: _addUrlBusy ? null : _confirmAddFromUrl,
                          size: ButtonSize.small,
                          leading: _addUrlBusy
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(LucideIcons.link),
                          child: Text(_addUrlBusy ? 'Adding...' : 'Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_pendingImages.isNotEmpty)
              Card(
                padding: EdgeInsets.zero,
                filled: true,
                borderColor: colorScheme.border,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _PendingImagesList(
                    images: _pendingImages,
                    onRemove: _removePendingImage,
                    onSendSingle: _uploadPendingImage,
                    onSendAll: _sendAllPending,
                    isUploadingAll: _isBulkUploading,
                  ),
                ),
              ),
            if (_pendingImages.isNotEmpty) const SizedBox(height: 16),
            const SizedBox(height: 16),
            if (request.images.isNotEmpty)
              ImageGallery(
                images: request.images,
                requestStatus: request.status,
              )
            else
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Take photos of the affected plants to analyze the disease.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PendingImage {
  _PendingImage({required this.request})
    : id = DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  final UploadImageRequest request;
  bool isUploading = false;
}

class _PendingImagesList extends StatelessWidget {
  const _PendingImagesList({
    required this.images,
    required this.onRemove,
    required this.onSendSingle,
    required this.onSendAll,
    required this.isUploadingAll,
  });

  final List<_PendingImage> images;
  final void Function(_PendingImage) onRemove;
  final Future<bool> Function(_PendingImage) onSendSingle;
  final Future<void> Function() onSendAll;
  final bool isUploadingAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;
            final actionButton = PrimaryButton(
              onPressed: isUploadingAll
                  ? null
                  : () async {
                      await onSendAll();
                    },
              size: ButtonSize.small,
              leading: isUploadingAll
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.cloudUpload, size: 18),
              child: Text(isUploadingAll ? 'Uploading...' : 'Send all'),
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Images ready to send (${images.length})',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: actionButton),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: Text(
                    'Images ready to send (${images.length})',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                actionButton,
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final pending = images[index];
            final request = pending.request;
            return Card(
              padding: const EdgeInsets.all(12),
              filled: true,
              borderColor: AppColors.border,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(request.filePath),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 72,
                        height: 72,
                        color: AppColors.border,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.type == ImageType.normal
                              ? 'Normal image'
                              : 'Macro image',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Lat ${request.latitude.toStringAsFixed(4)} • Lng ${request.longitude.toStringAsFixed(4)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      IconButton.ghost(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: pending.isUploading
                            ? null
                            : () => onRemove(pending),
                      ),
                      SecondaryButton(
                        onPressed: pending.isUploading
                            ? null
                            : () async {
                                await onSendSingle(pending);
                              },
                        size: ButtonSize.small,
                        leading: pending.isUploading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_outlined, size: 16),
                        child: Text(pending.isUploading ? 'Sending' : 'Send'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (context, _) => const SizedBox(height: 12),
          itemCount: images.length,
        ),
      ],
    );
  }
}
