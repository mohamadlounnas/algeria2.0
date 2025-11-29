import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/entities/request.dart';

/// Widget to display a single leaf analysis result
class LeafCard extends StatefulWidget {
  final LeafData leaf;
  final int index;
  final VoidCallback? onDelete;

  const LeafCard({
    super.key,
    required this.leaf,
    required this.index,
    this.onDelete,
  });

  @override
  State<LeafCard> createState() => _LeafCardState();
}

class _LeafCardState extends State<LeafCard> {
  // Tap toggles between normal and heatmap
  bool _showHeat = false;

  @override
  Widget build(BuildContext context) {
    final hasHeatmap = widget.leaf.heatmap != null;
    final currentUrl = _showHeat && hasHeatmap
        ? widget.leaf.heatmap
        : widget.leaf.image;

    final diseaseDetails = _collectDiseaseDetails();

    return Clickable(
      onPressed: () {
        if (hasHeatmap) setState(() => _showHeat = !_showHeat);
      },
      onLongPress: () => _showDetails(context, diseaseDetails),
      child: AspectRatio(
        aspectRatio: 1,
        child: SurfaceCard(
          padding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Leaf image (normal or heatmap)
              if (currentUrl != null)
                Image.network(
                  currentUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                )
              else
                Container(color: Colors.black),

              // Score label (integer part) in top-left
              Positioned(
                left: 6,
                top: 6,
                child: PrimaryBadge(
                  child: Text(
                    widget.leaf.anomalyScore.floor().toString(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // Visible delete icon in top-right
              Positioned(
                right: 6,
                top: 6,
                child: Clickable(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) {
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: SurfaceCard(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Delete Image?',
                                      style: AppTextStyles.h3.copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'This action will remove this leaf image from the request.',
                                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GhostButton(
                                            onPressed: () => Navigator.of(ctx).pop(),
                                            child: const Text('Cancel'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: PrimaryButton(
                                            leading: const Icon(Icons.delete_outline),
                                            onPressed: () {
                                              Navigator.of(ctx).pop();
                                              if (widget.onDelete != null) widget.onDelete!();
                                            },
                                            child: const Text('Delete'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, List<_LeafDiseaseInfo> diseaseDetails) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SurfaceCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Leaf Details',
                              style: AppTextStyles.h3.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              widget.leaf.isDiseased ? 'Diseased' : 'Healthy',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: widget.leaf.isDiseased
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _chip('Score', widget.leaf.anomalyScore.toStringAsFixed(2)),
                            _chip('Health', widget.leaf.isDiseased ? 'Diseased' : 'Healthy'),
                            if (diseaseDetails.isNotEmpty)
                              _chip('Diseases', diseaseDetails.map((d) => d.name).join(', ')),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (diseaseDetails.isNotEmpty)
                          Column(
                            children: diseaseDetails
                                .map((detail) => _LeafDiseaseDetailTile(info: detail))
                                .toList(),
                          )
                        else
                          Text(
                            'No additional disease insights available.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: GhostButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Close'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PrimaryButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              if (widget.onDelete != null) widget.onDelete!();
                            },
                            leading: const Icon(Icons.delete_outline),
                            child: const Text('Delete Image'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
          ),
          Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  List<_LeafDiseaseInfo> _collectDiseaseDetails() {
    return widget.leaf.diseases.entries.map((entry) {
      final detail = entry.value as Map<String, dynamic>?;
      return _LeafDiseaseInfo(
        name: entry.key,
        confidence: _asDouble(detail?['confidence']),
        percentage: _asDouble(detail?['percentage']),
        severity: detail?['severity'] as String?,
        description: detail?['description'] as String?,
        treatment: detail?['treatment'] as String?,
      );
    }).toList();
  }
}

class _LeafDiseaseInfo {
  const _LeafDiseaseInfo({
    required this.name,
    this.confidence,
    this.percentage,
    this.severity,
    this.description,
    this.treatment,
  });

  final String name;
  final double? confidence;
  final double? percentage;
  final String? severity;
  final String? description;
  final String? treatment;
}

class _LeafDiseaseDetailTile extends StatelessWidget {
  const _LeafDiseaseDetailTile({required this.info});

  final _LeafDiseaseInfo info;

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColorFromString(info.severity);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  info.name,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  info.severity?.toUpperCase() ?? 'UNKNOWN',
                  style: AppTextStyles.labelSmall.copyWith(color: severityColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (info.percentage != null)
                _chipLabel('Coverage', '${info.percentage!.toStringAsFixed(1)}%'),
              if (info.confidence != null)
                _chipLabel('Confidence', '${(info.confidence! * 100).toStringAsFixed(1)}%'),
            ],
          ),
          if (info.description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              info.description!,
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.8)),
            ),
          ],
          if (info.treatment != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Treatment: ${info.treatment!}',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chipLabel(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
      ),
    );
  }
}

Color _severityColorFromString(String? severity) {
  switch (severity?.toLowerCase()) {
    case 'critical':
    case 'high':
      return Colors.red;
    case 'medium':
      return AppColors.warning;
    case 'low':
      return AppColors.imageProcessed;
    default:
      return Colors.white;
  }
}

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
