import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/entities/request.dart';

class RequestImageDetailScreen extends StatelessWidget {
  final String requestId;
  final RequestImage image;
  final RequestStatus requestStatus;

  const RequestImageDetailScreen({
    super.key,
    required this.requestId,
    required this.image,
    required this.requestStatus,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = image.getImageUrl(ApiConstants.baseUrl);
    final statusLabel = _statusText(image.status);
    final statusColor = _statusColor(image.status);

    return Scaffold(
      headers: [
        AppBar(
          title: const Text('Image Details'),
          trailing: [
            GhostButton(
              onPressed: () => _openParentRequest(context),
              size: ButtonSize.small,
              leading: const Icon(Icons.assignment_outlined),
              child: const Text('Request'),
            ),
          ],
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.border,
                    alignment: Alignment.center,
                    child: Icon(
                      image.type == ImageType.normal
                          ? Icons.broken_image_outlined
                          : Icons.zoom_in_map,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                Chip(
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ButtonStyle.secondary(),
                ),
                Chip(
                  child: Text(
                    image.type == ImageType.normal ? 'Normal' : 'Macro',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ButtonStyle.ghost(),
                ),
                Chip(child: Text('Captured ${_formatDate(image.createdAt)}')),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _InfoSection(
              title: 'Location',
              rows: [
                _InfoRow(
                  icon: Icons.place_outlined,
                  label: 'Latitude',
                  value: image.latitude.toStringAsFixed(5),
                ),
                _InfoRow(
                  icon: Icons.place_outlined,
                  label: 'Longitude',
                  value: image.longitude.toStringAsFixed(5),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoSection(
              title: 'Status',
              rows: [
                _InfoRow(
                  icon: Icons.layers,
                  label: 'State',
                  value: statusLabel,
                ),
                if (image.processedAt != null)
                  _InfoRow(
                    icon: Icons.event_available_outlined,
                    label: 'Processed At',
                    value: _formatDate(image.processedAt!),
                  ),
              ],
            ),
            if (image.diseaseType != null || image.treatmentPlan != null) ...[
              const SizedBox(height: AppSpacing.md),
              _InfoSection(
                title: 'Analysis',
                rows: [
                  if (image.diseaseType != null)
                    _InfoRow(
                      icon: Icons.biotech_outlined,
                      label: 'Disease',
                      value: image.diseaseType!,
                    ),
                  if (image.confidence != null)
                    _InfoRow(
                      icon: Icons.insights_outlined,
                      label: 'Confidence',
                      value: '${(image.confidence! * 100).toStringAsFixed(1)}%',
                    ),
                  if (image.treatmentPlan != null)
                    _InfoRow(
                      icon: Icons.assignment_turned_in_outlined,
                      label: 'Plan',
                      value: image.treatmentPlan!,
                    ),
                  if (image.materials != null)
                    _InfoRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Materials',
                      value: image.materials!,
                    ),
                  if (image.services != null)
                    _InfoRow(
                      icon: Icons.handyman_outlined,
                      label: 'Services',
                      value: image.services!,
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              onPressed: () => _openParentRequest(context),
              size: ButtonSize.normal,
              leading: const Icon(Icons.open_in_new),
              child: const Text('Open Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _openParentRequest(BuildContext context) {
    final route = requestStatus == RequestStatus.completed
        ? AppRoutes.requestResults
        : AppRoutes.requestDraft;
    Navigator.of(context).pushNamed(route, arguments: RequestArgs(requestId));
  }

  String _formatDate(DateTime dateTime) {
    return dateTime.toLocal().toString().split('.').first;
  }

  String _statusText(ImageStatus status) {
    switch (status) {
      case ImageStatus.pending:
        return 'Pending';
      case ImageStatus.uploaded:
        return 'Uploaded';
      case ImageStatus.processing:
        return 'Processing';
      case ImageStatus.processed:
        return 'Processed';
      case ImageStatus.failed:
        return 'Failed';
    }
  }

  Color _statusColor(ImageStatus status) {
    switch (status) {
      case ImageStatus.pending:
        return AppColors.imagePending;
      case ImageStatus.uploaded:
        return AppColors.imageUploaded;
      case ImageStatus.processing:
        return AppColors.warning;
      case ImageStatus.processed:
        return AppColors.imageProcessed;
      case ImageStatus.failed:
        return AppColors.imageFailed;
    }
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h4),
          const SizedBox(height: AppSpacing.sm),
          for (final row in rows) ...[
            row,
            if (row != rows.last) const Divider(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
