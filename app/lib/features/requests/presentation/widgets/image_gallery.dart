import 'package:dowa/core/di/dio_client.dart';
import 'package:dowa/core/routing/app_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../domain/entities/request.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/constants/api_constants.dart';

class ImageGallery extends StatelessWidget {
  final List<RequestImage> images;
  final RequestStatus requestStatus;

  const ImageGallery({super.key, required this.images, required this.requestStatus});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uploaded Images (${images.length})',
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: images.length,
          separatorBuilder: (context, _) =>
              const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final image = images[index];
            final imageUrl = image.getImageUrl(DioClient.getBaseUrl());
            final statusLabel = _getStatusText(image.status);
            final statusColor = _getStatusColor(image.status);

            return Clickable(
              onPressed: () {

                Navigator.of(context).pushNamed(
                  AppRoutes.requestImageDetail,
                  arguments: RequestImageDetailArgs(
                    requestId: image.requestId,
                    image: image,
                    requestStatus: requestStatus,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 92,
                      height: 92,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _PlaceholderPreview(type: image.type),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppColors.border,
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Image ${index + 1}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              _buildInfoChip(
                                label: image.type == ImageType.normal
                                    ? 'Normal'
                                    : 'Macro',
                              ),
                              _buildInfoChip(
                                label:
                                    'Captured ${_formatDate(image.createdAt)}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lat ${image.latitude.toStringAsFixed(4)} • Lng ${image.longitude.toStringAsFixed(4)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (image.diseaseType != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.xs,
                              ),
                              child: Text(
                                'Disease: ${image.diseaseType} • Confidence ${(image.confidence ?? 0).toStringAsFixed(2)}',
                                style: AppTextStyles.bodySmall,
                              ),
                            ),
                          if (image.treatmentPlan != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.xs,
                              ),
                              child: Text(
                                'Plan: ${image.treatmentPlan}',
                                style: AppTextStyles.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getStatusText(ImageStatus status) {
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

  Color _getStatusColor(ImageStatus status) {
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

  Widget _buildInfoChip({required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: AppTextStyles.labelSmall),
    );
  }

  String _formatDate(DateTime dateTime) {
    return dateTime.toLocal().toString().split('.').first;
  }
}

class _PlaceholderPreview extends StatelessWidget {
  final ImageType type;

  const _PlaceholderPreview({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.border,
      child: Icon(
        type == ImageType.normal ? Icons.image_outlined : Icons.zoom_in,
        color: AppColors.textSecondary,
      ),
    );
  }
}
