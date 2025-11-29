import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../providers/request_provider.dart';
import '../../domain/entities/request.dart';
import '../../domain/dto/update_request_request.dart';
import '../../../../shared/widgets/authenticated_app_bar.dart';
import '../../../../shared/widgets/bordered_card.dart';
import '../../../../shared/widgets/standard_button.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/routing/app_router.dart';

class RequestSummaryScreen extends StatefulWidget {
  final String requestId;

  const RequestSummaryScreen({super.key, required this.requestId});

  @override
  State<RequestSummaryScreen> createState() => _RequestSummaryScreenState();
}

class _RequestSummaryScreenState extends State<RequestSummaryScreen> {
  final _noteController = TextEditingController();
  bool _expertIntervention = false;
  bool _isLoading = false;
  bool _isRequestLoading = false;
  bool _didInitializeForm = false;
  Request? _request;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureRequestLoaded();
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _ensureRequestLoaded() async {
    final provider = RequestProvider.of(context);
    Request? existing;
    if (provider != null) {
      try {
        existing = provider.requests.firstWhere(
          (r) => r.id == widget.requestId,
        );
      } catch (_) {
        existing = null;
      }
    }

    if (existing != null && existing.images.isNotEmpty) {
      _captureRequest(existing);
      return;
    }

    setState(() => _isRequestLoading = true);
    try {
      Request? fetched;
      if (provider?.fetchRequest != null) {
        fetched = await provider!.fetchRequest!(widget.requestId);
      }
      _captureRequest(fetched ?? existing);
    } catch (e) {
      debugPrint('Error ensuring request summary data: $e');
    } finally {
      if (mounted) {
        setState(() => _isRequestLoading = false);
      }
    }
  }

  void _captureRequest(Request? request) {
    if (!mounted || request == null) return;
    setState(() {
      _request = request;
      if (!_didInitializeForm) {
        _noteController.text = request.note ?? '';
        _expertIntervention = request.expertIntervention;
        _didInitializeForm = true;
      }
    });
  }

  Future<void> _sendRequest() async {
    final provider = RequestProvider.of(context);
    if (provider == null) return;

    setState(() => _isLoading = true);
    try {
      // Update request with note and expert intervention
      final updateRequest = UpdateRequestRequest(
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        expertIntervention: _expertIntervention,
      );

      await provider.updateRequest?.call(widget.requestId, updateRequest);

      // Send request
      await provider.sendRequest?.call(widget.requestId);

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.farms, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) => Alert.destructive(
            title: const Text('Error'),
            content: Text('Error: ${e.toString()}'),
            trailing: IconButton.ghost(
              icon: const Icon(LucideIcons.x),
              onPressed: overlay.close,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = RequestProvider.of(context);
    Request? request = _request;
    if (request == null && provider != null) {
      try {
        request = provider.requests.firstWhere((r) => r.id == widget.requestId);
      } catch (_) {
        request = null;
      }
    }

    if ((_isRequestLoading || _isLoading) && request == null) {
      return Scaffold(child: Center(child: CircularProgressIndicator()));
    }

    if (request == null) {
      return Scaffold(child: Center(child: Text('Request not found')));
    }

    final totalImages = request.images.length;
    final normalCount = request.images
        .where((img) => img.type == ImageType.normal)
        .length;
    final macroCount = request.images
        .where((img) => img.type == ImageType.macro)
        .length;
    final processedCount = request.images
        .where((img) => img.status == ImageStatus.processed)
        .length;

    return Scaffold(
      headers: const [AuthenticatedAppBar(title: 'Request Summary')],
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              140,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryHeaderCard(request: request, totalImages: totalImages),
                const SizedBox(height: AppSpacing.md),
                _StatGrid(
                  totalImages: totalImages,
                  normalCount: normalCount,
                  macroCount: macroCount,
                  processedCount: processedCount,
                ),
                const SizedBox(height: AppSpacing.md),
                _ActionToggleCard(
                  value: _expertIntervention,
                  onChanged: (value) =>
                      setState(() => _expertIntervention = value),
                  isBusy: _isLoading,
                ),
                const SizedBox(height: AppSpacing.md),
                _NotesCard(controller: _noteController),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: StandardButton(
                  text: _isLoading ? 'Sending request...' : 'Send request',
                  onPressed: _isLoading ? null : _sendRequest,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryHeaderCard extends StatelessWidget {
  const _SummaryHeaderCard({required this.request, required this.totalImages});

  final Request request;
  final int totalImages;

  @override
  Widget build(BuildContext context) {
    final statusLabel = _statusText(request.status);
    final statusColor = _statusColor(request.status);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: BorderedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request #${request.id}',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Created ${_formatDate(request.createdAt)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                _TinyStat(label: 'Images', value: '$totalImages'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  static String _statusText(RequestStatus status) {
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

  static Color _statusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.draft:
        return AppColors.draft;
      case RequestStatus.pending:
        return AppColors.pending;
      case RequestStatus.accepted:
        return AppColors.accepted;
      case RequestStatus.processing:
        return AppColors.processing;
      case RequestStatus.processed:
        return AppColors.processed;
      case RequestStatus.completed:
        return AppColors.completed;
    }
  }
}

class _TinyStat extends StatelessWidget {
  const _TinyStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.totalImages,
    required this.normalCount,
    required this.macroCount,
    required this.processedCount,
  });

  final int totalImages;
  final int normalCount;
  final int macroCount;
  final int processedCount;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      childAspectRatio: 2.8,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      children: [
        _StatCard(
          label: 'Total images',
          value: '$totalImages',
          icon: Icons.layers,
        ),
        _StatCard(
          label: 'Normal shots',
          value: '$normalCount',
          icon: Icons.photo_outlined,
        ),
        _StatCard(
          label: 'Macro shots',
          value: '$macroCount',
          icon: Icons.zoom_in_outlined,
        ),
        _StatCard(
          label: 'Processed',
          value: '$processedCount',
          icon: Icons.verified_outlined,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionToggleCard extends StatelessWidget {
  const _ActionToggleCard({
    required this.value,
    required this.onChanged,
    required this.isBusy,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: BorderedCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expert review',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recommended for severe outbreaks. Additional cost may apply.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: isBusy ? null : onChanged),
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: BorderedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes for agronomist',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: controller, maxLines: 5),
          ],
        ),
      ),
    );
  }
}
