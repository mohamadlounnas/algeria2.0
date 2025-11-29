import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../requests/domain/entities/request.dart';
import '../../../requests/data/models/request_model.dart';
import '../../../../core/di/di_provider.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/authenticated_app_bar.dart';
import '../../../../shared/widgets/standard_list_tile.dart';
import '../../../../core/theme/spacing.dart';
import '../widgets/request_status_badge.dart';

class AdminRequestDetailScreen extends StatefulWidget {
  final String requestId;

  const AdminRequestDetailScreen({super.key, required this.requestId});

  @override
  State<AdminRequestDetailScreen> createState() =>
      _AdminRequestDetailScreenState();
}

class _AdminRequestDetailScreenState extends State<AdminRequestDetailScreen> {
  Request? _request;
  bool _isLoading = false;
  Dio? _dio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dio == null) {
      final dioClient = DiProvider.getDioClient(context);
      _dio = dioClient.dio;
      _loadRequest();
    }
  }

  Future<void> _loadRequest() async {
    if (_dio == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await _dio!.get(
        '${ApiConstants.admin}/requests/${widget.requestId}',
      );
      setState(() {
        _request = RequestModel.fromJson(response.data as Map<String, dynamic>);
      });
    } catch (e) {
      debugPrint('Error loading request: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptRequest() async {
    if (_dio == null) return;
    try {
      await _dio!.post(
        '${ApiConstants.admin}/requests/${widget.requestId}/accept',
      );
      await _loadRequest();
      if (mounted) {
        // use soner
      }
    } catch (e) {
      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) => Alert.destructive(
            title: const Text('Error'),
            content: Text('Error: $e'),
            trailing: IconButton.ghost(
              icon: const Icon(LucideIcons.x),
              onPressed: overlay.close,
            ),
          ),
        );
      }
    }
  }

  Future<void> _processRequest() async {
    if (_dio == null) return;
    try {
      await _dio!.post(
        '${ApiConstants.admin}/requests/${widget.requestId}/process',
      );
      await _loadRequest();
      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) => const Alert(
            title: Text('Processing'),
            content: Text('Processing started'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) => Alert.destructive(
            title: const Text('Error'),
            content: Text('Error: $e'),
            trailing: IconButton.ghost(
              icon: const Icon(LucideIcons.x),
              onPressed: overlay.close,
            ),
          ),
        );
      }
    }
  }

  Future<void> _completeRequest() async {
    if (_dio == null) return;
    try {
      await _dio!.post(
        '${ApiConstants.admin}/requests/${widget.requestId}/complete',
      );
      await _loadRequest();
      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) => const Alert(
            title: Text('Success'),
            content: Text('Request completed'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) => Alert.destructive(
            title: const Text('Error'),
            content: Text('Error: $e'),
            trailing: IconButton.ghost(
              icon: const Icon(LucideIcons.x),
              onPressed: overlay.close,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context);
    if (authProvider?.user?.role != UserRole.admin) {
      return Scaffold(child: const Center(child: Text('Admin access required')));
    }

    if (_isLoading) {
      return Scaffold(child: const Center(child: CircularProgressIndicator()));
    }

    if (_request == null) {
      return Scaffold(child: const Center(child: Text('Request not found')));
    }

    final status = _request!.status;
    final images = _request!.images;
    final normalImages = images
        .where((img) => img.type == ImageType.normal)
        .length;
    final macroImages = images
        .where((img) => img.type == ImageType.macro)
        .length;

    return Scaffold(
      headers: [const AuthenticatedAppBar(title: 'Request Details')],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              borderColor: Theme.of(context).colorScheme.border,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Request #${_request!.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      RequestStatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Farm: ${_request!.farmId.substring(0, 8)}'),
                  Text('Images: $normalImages normal, $macroImages macro'),
                  if (_request!.note != null) Text('Note: ${_request!.note}'),
                  if (_request!.expertIntervention)
                    const Text('Expert Intervention: Yes'),
                ],
              ),
            ),
            if (status == RequestStatus.pending)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Button.primary(
                  child: const Text('Accept Request'),
                  onPressed: _acceptRequest,
                ),
              ),
            if (status == RequestStatus.accepted)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Button.primary(
                  child: const Text('Process Request'),
                  onPressed: _processRequest,
                ),
              ),
            if (status == RequestStatus.processed ||
                status == RequestStatus.processing)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Button.primary(
                  child: const Text('Edit Report'),
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.reportEditor,
                      arguments: RequestArgs(widget.requestId),
                    );
                  },
                ),
              ),
            if (status == RequestStatus.processed)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Button.primary(
                  child: const Text('Mark as Completed'),
                  onPressed: _completeRequest,
                ),
              ),
            if (images.isNotEmpty)
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Images',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...images.map(
                      (img) => StandardListTile(
                        title: Text(
                          '${img.type == ImageType.normal ? 'NORMAL' : 'MACRO'} Image',
                        ),
                        subtitle: Text(
                          'Lat: ${img.latitude}, Lng: ${img.longitude}',
                        ),
                        trailing: img.diseaseType != null
                            ? Chip(child: Text(img.diseaseType!))
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
