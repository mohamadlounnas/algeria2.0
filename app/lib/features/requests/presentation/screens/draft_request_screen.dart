import 'dart:io';

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
import '../../../../shared/services/location_service.dart';

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
        _showToastMessage('Request sent successfully.');
        Navigator.of(context).pop();
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
      return const Scaffold(child: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
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
          title: const Text('Draft Request'),
          trailing: [
            GhostButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              size: ButtonSize.small,
              child: const Text('Save draft'),
            ),
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
                  onNormalFromGallery: () =>
                      _addImage(ImageType.normal, source: ImageSource.gallery),
                  onMacroFromGallery: () =>
                      _addImage(ImageType.macro, source: ImageSource.gallery),
                  pendingCount: _pendingImages.length,
                  isBusy: _isBulkUploading,
                ),
              ),
            ),
            const SizedBox(height: 16),
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
            if (request.images.isNotEmpty)
              ImageGallery(images: request.images, requestStatus: request.status),
            if (request.images.isEmpty)
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
