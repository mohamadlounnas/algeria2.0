import 'dart:async';

import 'package:dowa/core/di/dio_client.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../domain/entities/request.dart';
import '../providers/request_provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/routing/app_router.dart';

class RequestsListScreen extends StatefulWidget {
  final String farmId;

  const RequestsListScreen({super.key, required this.farmId});

  @override
  State<RequestsListScreen> createState() => _RequestsListScreenState();
}

class _RequestsListScreenState extends State<RequestsListScreen> {
  bool _hasLoaded = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasLoaded) return;
      final provider = RequestProvider.of(context);
      provider?.loadRequests?.call(widget.farmId);
      _hasLoaded = true;
      // Start periodic refresh every 5 seconds
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        final p = RequestProvider.of(context);
        p?.loadRequests?.call(widget.farmId);
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = RequestProvider.of(context);
    final isLoading = provider?.isLoading == true;
    final requests = provider?.requests ?? const <Request>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      headers: [
        AppBar(
          title: const Text('Requests').h3(),
          leading: [
            OutlineButton(
              density: ButtonDensity.icon,
              onPressed: () {
                final navigator = Navigator.of(context);
                if (navigator.canPop()) {
                  navigator.pop();
                } else {
                  navigator.pushNamedAndRemoveUntil(
                    AppRoutes.farms,
                    (route) => false,
                  );
                }
              },
              child: const Icon(RadixIcons.arrowLeft),
            ),
          ],
          trailing: [
            if (requests.isNotEmpty)
              PrimaryButton(
                density: ButtonDensity.icon,
                onPressed: () => _createRequest(provider),
                child: const Icon(RadixIcons.plus),
              ),
          ],
        ),
      ],
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(RadixIcons.clipboard, size: 64).muted(),
                  const Gap(16),
                  const Text('No requests yet').muted(),
                  const Gap(16),
                  PrimaryButton(
                    onPressed: () => _createRequest(provider),
                    child: const Text('Create Request'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) =>
                  _RequestCard(request: requests[index]),
              separatorBuilder: (context, _) => const Gap(16),
              itemCount: requests.length,
            ),
    );
  }

  void _showToast(String message, {bool isError = false}) {
    showToast(
      context: context,
      builder: (context, overlay) => SurfaceCard(
        child: Basic(
          title: Text(isError ? 'Error' : 'Info'),
          subtitle: Text(message),
          leading: Icon(
            isError ? RadixIcons.exclamationTriangle : RadixIcons.infoCircled,
            color: isError ? const Color(0xFFEF4444) : null,
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

  Future<void> _createRequest(RequestProvider? provider) async {
    if (provider == null) {
      _showToast('Error: Provider not found', isError: true);
      return;
    }

    final createRequest = provider.createRequest;
    if (createRequest == null) {
      _showToast('Create request action is unavailable.', isError: true);
      return;
    }

    try {
      final requestId = await createRequest(widget.farmId);
      if (!mounted) return;

      if (requestId == null) {
        _showToast(
          'Unable to create request. Please try again.',
          isError: true,
        );
        return;
      }

      Navigator.of(
        context,
      ).pushNamed(AppRoutes.requestDraft, arguments: RequestArgs(requestId));
    } catch (error) {
      if (!mounted) return;
      _showToast('Failed to create request: $error', isError: true);
    }
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final Request request;

  @override
  Widget build(BuildContext context) {
    final statusColor = _requestStatusColor(request.status);
    final statusText = _requestStatusText(request.status);

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _requestStatusIcon(request.status),
                                size: 14,
                                color: statusColor,
                              ),
                              const Gap(6),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(8),
                        Expanded(
                          child: Text('Request #${request.id}').h4().ellipsis(),
                        ),
                        const Gap(8),
                        Text(_formatDate(request.createdAt)).muted().small(),
                      ],
                    ),
                    if (request.note != null && request.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          request.note!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ).muted().small(),
                      ),
                    const Gap(8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _InfoBadge(
                          icon: RadixIcons.image,
                          label: '${request.images.length} images',
                        ),
                        if (request.expertIntervention)
                          const _InfoBadge(
                            icon: RadixIcons.person,
                            label: 'Expert review',
                            color: Colors.purple,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Tooltip(
                tooltip: (context) =>
                    TooltipContainer(child: Text('Open request')),
                child: GhostButton(
                  density: ButtonDensity.icon,
                  onPressed: () => _openRequest(context),
                  child: const Icon(RadixIcons.openInNewWindow),
                ),
              ),
            ],
          ),
          const Gap(16),
          if (request.images.isEmpty)
            _EmptyImagesState(statusText: statusText)
          else
            _RequestImageStrip(request: request),
        ],
      ),
    );
  }

  void _openRequest(BuildContext context) {
    final route = request.status == RequestStatus.completed
        ? AppRoutes.requestResults
        : AppRoutes.requestDraft;
    Navigator.of(context).pushNamed(route, arguments: RequestArgs(request.id));
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _requestStatusText(RequestStatus status) {
    switch (status) {
      case RequestStatus.draft:
        return 'Draft';
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.accepted:
        return 'Accepted';
      case RequestStatus.processing:
        return 'Processing';
      case RequestStatus.processed:
        return 'Processed';
      case RequestStatus.completed:
        return 'Completed';
    }
  }

  Color _requestStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.draft:
        return const Color(0xFF9E9E9E); // Grey
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.accepted:
        return Colors.blue;
      case RequestStatus.processing:
        return Colors.purple;
      case RequestStatus.processed:
        return Colors.teal;
      case RequestStatus.completed:
        return Colors.green;
    }
  }

  IconData _requestStatusIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.draft:
        return RadixIcons.pencil1;
      case RequestStatus.pending:
        return RadixIcons.timer;
      case RequestStatus.accepted:
        return RadixIcons.checkCircled;
      case RequestStatus.processing:
        return RadixIcons.gear;
      case RequestStatus.processed:
        return RadixIcons.check;
      case RequestStatus.completed:
        return RadixIcons.check;
    }
  }
}

class _EmptyImagesState extends StatelessWidget {
  const _EmptyImagesState({required this.statusText});

  final String statusText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.border),
      ),
      child: Column(
        children: [
          const Icon(RadixIcons.camera, color: Color(0xFF9E9E9E)),
          const Gap(8),
          Text(
            statusText == 'Draft'
                ? 'No images yet. Capture photos to help agronomists.'
                : 'No images were attached for this request.',
          ).muted().small().textCenter(),
        ],
      ),
    );
  }
}

class _RequestImageStrip extends StatelessWidget {
  const _RequestImageStrip({required this.request});

  final Request request;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: request.images.length,
        separatorBuilder: (context, _) => const Gap(8),
        itemBuilder: (context, index) {
          final image = request.images[index];
          final statusColor = _imageStatusColor(image.status);
          final imageUrl = image.getImageUrl(DioClient.getBaseUrl());

          return GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.requestImageDetail,
                arguments: RequestImageDetailArgs(
                  requestId: request.id,
                  image: image,
                  requestStatus: request.status,
                ),
              );
            },
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    imageUrl,
                    width: 86,
                    height: 86,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _ImagePlaceholder(image: image),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 86,
                        height: 86,
                        alignment: Alignment.center,
                        color: Theme.of(context).colorScheme.border,
                        child: const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _imageStatusColor(ImageStatus status) {
    switch (status) {
      case ImageStatus.pending:
        return const Color(0xFF9E9E9E);
      case ImageStatus.uploaded:
        return Colors.blue;
      case ImageStatus.processing:
        return Colors.orange;
      case ImageStatus.processed:
        return Colors.green;
      case ImageStatus.failed:
        return Colors.red;
    }
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.image});

  final RequestImage image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.card,
        border: Border.all(color: Theme.of(context).colorScheme.border),
      ),
      child: Icon(
        image.type == ImageType.normal
            ? RadixIcons.image
            : RadixIcons.magnifyingGlass,
        color: Theme.of(context).colorScheme.mutedForeground,
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoBadge({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? Theme.of(context).colorScheme.mutedForeground,
        ),
        const Gap(4),
        Text(
          label,
          style: TextStyle(
            color: color ?? Theme.of(context).colorScheme.mutedForeground,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}


// fixImageServer
String fixImageServer(String url) {
  // https://example.com:3333/path/to/image.jpg
  var tokens = url.split("3333");
  // replace the http://example.com:3333 with base url from dio
  // so it becomes baseurl+/path/to/image.jpg
  return DioClient.getBaseUrl() + tokens[1];
}