import 'dart:math' as math;

import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/entities/request.dart';
import '../providers/request_provider.dart';
import '../widgets/annotated_image_viewer.dart';
import '../widgets/leaf_card.dart';

class RequestImageDetailScreen extends StatefulWidget {
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
  State<RequestImageDetailScreen> createState() =>
      _RequestImageDetailScreenState();
}

class _RequestImageDetailScreenState extends State<RequestImageDetailScreen> {
  bool _isBusy = false;
  late RequestImage _image;

  @override
  void initState() {
    super.initState();
    _image = widget.image;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _image.getImageUrl(ApiConstants.baseUrl);
    final statusLabel = _statusText(_image.status);
    final statusColor = _statusColor(_image.status);

    // Debug logging
    print('🔍 Image Detail Debug:');
    print('   - Image ID: ${_image.id}');
    print('   - Status: ${_image.status}');
    print('   - Has leafs: ${_image.leafs != null}');
    print('   - Leafs count: ${_image.leafs?.length ?? 0}');
    print(
      '   - Leafs with bbox: ${_image.leafs?.where((l) => l.bbox != null).length ?? 0}',
    );
    print('   - Has summary: ${_image.summary != null}');
    if (_image.summary != null) {
      print(
        '   - Summary: ${_image.summary!.totalLeafs} total, ${_image.summary!.diseasedLeafs} diseased',
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      headers: [
        AppBar(
          leading: [
            IconButton.ghost(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
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
            // Show annotated viewer if leafs with bboxes are available
            if (_image.leafs != null &&
                _image.leafs!.isNotEmpty &&
                _image.leafs!.any((leaf) => leaf.bbox != null))
              AnnotatedImageViewer(imageUrl: imageUrl, leafs: _image.leafs!)
            else
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
                        _image.type == ImageType.normal
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
                    _image.type == ImageType.normal ? 'Normal' : 'Macro',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ButtonStyle.ghost(),
                ),
                Chip(child: Text('Captured ${_formatDate(_image.createdAt)}')),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _InfoSection(
              title: 'Location',
              rows: [
                _InfoRow(
                  icon: Icons.place_outlined,
                  label: 'Latitude',
                  value: _image.latitude.toStringAsFixed(5),
                ),
                _InfoRow(
                  icon: Icons.place_outlined,
                  label: 'Longitude',
                  value: _image.longitude.toStringAsFixed(5),
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
                if (_image.processedAt != null)
                  _InfoRow(
                    icon: Icons.event_available_outlined,
                    label: 'Processed At',
                    value: _formatDate(_image.processedAt!),
                  ),
              ],
            ),
            // Summary section
            if (_image.summary != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.imageProcessed.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.summarize_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Analysis Summary', style: AppTextStyles.h4),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryCard(
                          icon: Icons.eco_outlined,
                          label: 'Total Leafs',
                          value: _image.summary!.totalLeafs.toString(),
                          color: AppColors.primary,
                        ),
                        _SummaryCard(
                          icon: Icons.warning_amber_outlined,
                          label: 'Diseased',
                          value: _image.summary!.diseasedLeafs.toString(),
                          color: AppColors.warning,
                        ),
                        _SummaryCard(
                          icon: Icons.check_circle_outline,
                          label: 'Healthy',
                          value: _image.summary!.healthyLeafs.toString(),
                          color: AppColors.imageProcessed,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (_image.leafs != null && _image.leafs!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _DiseaseOverview(leafs: _image.leafs!),
            ],

            // Leafs grid
            if (_image.leafs != null && _image.leafs!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Detected Leafs (${_image.leafs!.length})',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: AppSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate item width for 3 columns
                  const spacing = AppSpacing.md;
                  final itemWidth = (constraints.maxWidth - (2 * spacing)) / 3;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: _image.leafs!.asMap().entries.map((entry) {
                      return SizedBox(
                        width: itemWidth,
                        child: LeafCard(
                          leaf: entry.value,
                          index: entry.key,
                          onDelete: () => _deleteImage(context),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Legacy single-leaf analysis (fallback if no leafs array)
            if ((_image.leafs == null || _image.leafs!.isEmpty) &&
                (_image.diseaseType != null ||
                    _image.treatmentPlan != null ||
                    _image.anomalyScore != null ||
                    _image.isDiseased != null)) ...[
              const SizedBox(height: AppSpacing.md),
              _InfoSection(
                title: 'Analysis',
                rows: [
                  if (_image.isDiseased != null)
                    _InfoRow(
                      icon: _image.isDiseased!
                          ? Icons.warning_amber_outlined
                          : Icons.check_circle_outline,
                      label: 'Health Status',
                      value: _image.isDiseased! ? 'Diseased' : 'Healthy',
                    ),
                  if (_image.anomalyScore != null)
                    _InfoRow(
                      icon: Icons.analytics_outlined,
                      label: 'Anomaly Score',
                      value: _image.anomalyScore!.toStringAsFixed(2),
                    ),
                  if (_image.diseaseType != null)
                    _InfoRow(
                      icon: Icons.biotech_outlined,
                      label: 'Disease',
                      value: _image.diseaseType!,
                    ),
                  if (_image.confidence != null)
                    _InfoRow(
                      icon: Icons.insights_outlined,
                      label: 'Confidence',
                      value:
                          '${(_image.confidence! * 100).toStringAsFixed(1)}%',
                    ),
                  if (_image.treatmentPlan != null)
                    _InfoRow(
                      icon: Icons.assignment_turned_in_outlined,
                      label: 'Plan',
                      value: _image.treatmentPlan!,
                    ),
                  if (_image.materials != null)
                    _InfoRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Materials',
                      value: _image.materials!,
                    ),
                  if (_image.services != null)
                    _InfoRow(
                      icon: Icons.handyman_outlined,
                      label: 'Services',
                      value: _image.services!,
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PrimaryButton(
                      onPressed: _isBusy ? null : () => _reanalyze(context),
                      size: ButtonSize.normal,
                      leading: const Icon(Icons.refresh),
                      child: Text(_isBusy ? 'Reanalysing...' : 'Reanalyse'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    GhostButton(
                      onPressed: () => _openParentRequest(context),
                      size: ButtonSize.normal,
                      leading: const Icon(Icons.open_in_new),
                      child: const Text('Open Request'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Delete image action under Reanalyse
                PrimaryButton(
                  onPressed: _isBusy
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            barrierDismissible: true,
                            builder: (ctx) => Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 420),
                                child: SurfaceCard(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Delete Image?', style: AppTextStyles.h3),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          'This will remove this image from the request.',
                                          style: AppTextStyles.bodySmall,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: GhostButton(
                                                onPressed: () => Navigator.of(ctx).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                            Expanded(
                                              child: PrimaryButton(
                                                leading: const Icon(Icons.delete_outline),
                                                onPressed: () => Navigator.of(ctx).pop(true),
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
                            ),
                          );
                          if (confirmed == true) {
                            await _deleteImage(context);
                          }
                        },
                  size: ButtonSize.normal,
                  leading: const Icon(Icons.delete_outline),
                  child: const Text('Delete Image'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openParentRequest(BuildContext context) {
    final route = widget.requestStatus == RequestStatus.completed
        ? AppRoutes.requestResults
        : AppRoutes.requestDraft;
    Navigator.of(
      context,
    ).pushNamed(route, arguments: RequestArgs(widget.requestId));
  }

  Future<void> _reanalyze(BuildContext context) async {
    final provider = RequestProvider.of(context);
    if (provider == null || provider.reanalyseImage == null) return;
    setState(() => _isBusy = true);
    try {
      await provider.reanalyseImage!.call(_image.id, widget.requestId);
      // Refresh request to update this image locally
      final updated = await provider.fetchRequest?.call(widget.requestId);
      if (updated != null) {
        try {
          final found = updated.images.firstWhere((img) => img.id == _image.id);
          setState(() => _image = found);
        } catch (e) {
          // Image not found in updated list, keep current
        }
      }
      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) => const SurfaceCard(
            child: Basic(title: Text('Reanalysis started/updated')),
          ),
          location: ToastLocation.bottomRight,
        );
      }
    } catch (e) {
      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) => SurfaceCard(
            child: Basic(
              title: const Text('Error'),
              subtitle: Text(e.toString()),
            ),
          ),
          location: ToastLocation.bottomRight,
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _formatDate(DateTime dateTime) {
    return dateTime.toLocal().toString().split('.').first;
  }

  Future<void> _deleteImage(BuildContext context) async {
    final provider = RequestProvider.of(context);
    if (provider == null || provider.deleteImage == null) return;
    setState(() => _isBusy = true);
    try {
      await provider.deleteImage!.call(_image.id, widget.requestId);
      // After delete, navigate back to the parent request and refresh
      final updated = await provider.fetchRequest?.call(widget.requestId);
      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) =>
              const SurfaceCard(child: Basic(title: Text('Image deleted'))),
          location: ToastLocation.bottomRight,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) => SurfaceCard(
            child: Basic(
              title: const Text('Delete failed'),
              subtitle: Text(e.toString()),
            ),
          ),
          location: ToastLocation.bottomRight,
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DiseaseOverview extends StatelessWidget {
  const _DiseaseOverview({required this.leafs});

  final List<LeafData> leafs;

  List<_DiseaseAggregate> get _aggregates {
    final map = <String, _DiseaseAggregate>{};
    for (final leaf in leafs) {
      leaf.diseases.forEach((name, detail) {
        final detailMap = detail as Map<String, dynamic>?;
        final aggregate = map.putIfAbsent(name, () => _DiseaseAggregate(name));
        aggregate.add(detailMap);
      });
    }
    final entries = map.values.toList();
    entries.sort((a, b) => b.maxPercentage.compareTo(a.maxPercentage));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _aggregates;
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
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
          Text('Diseases & Treatment', style: AppTextStyles.h4),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: entries.map((entry) {
              final label = entry.maxPercentage > 0
                  ? '${entry.name} • ${entry.maxPercentage.toStringAsFixed(1)}%'
                  : entry.name;
              return Chip(
                child: Text(label),
                style: ButtonStyle.secondary(),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: entries
                .map((entry) => _DiseaseDetailCard(aggregate: entry))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _DiseaseAggregate {
  _DiseaseAggregate(this.name);

  final String name;
  int occurrences = 0;
  double totalConfidence = 0;
  double maxPercentage = 0;
  String? description;
  String? severity;
  String? treatment;

  double get averageConfidence => occurrences > 0 ? totalConfidence / occurrences : 0;

  void add(Map<String, dynamic>? detail) {
    occurrences += 1;
    final confidence = _asDouble(detail?['confidence']);
    if (confidence != null) totalConfidence += confidence;
    final percentage = _asDouble(detail?['percentage']);
    if (percentage != null) {
      maxPercentage = math.max(maxPercentage, percentage);
    }
    if (description == null && detail?['description'] is String) {
      description = detail!['description'] as String;
    }
    if (severity == null && detail?['severity'] is String) {
      severity = detail!['severity'] as String;
    }
    if (treatment == null && detail?['treatment'] is String) {
      treatment = detail!['treatment'] as String;
    }
  }
}

class _DiseaseDetailCard extends StatelessWidget {
  const _DiseaseDetailCard({required this.aggregate});

  final _DiseaseAggregate aggregate;

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColorFromString(aggregate.severity);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  aggregate.name,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  aggregate.severity?.toUpperCase() ?? 'UNKNOWN',
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
              if (aggregate.maxPercentage > 0)
                _smallLabel('Coverage', '${aggregate.maxPercentage.toStringAsFixed(1)}%'),
              if (aggregate.occurrences > 0)
                _smallLabel('Samples', aggregate.occurrences.toString()),
              if (aggregate.averageConfidence > 0)
                _smallLabel('Confidence', '${(aggregate.averageConfidence * 100).toStringAsFixed(1)}%'),
            ],
          ),
          if (aggregate.description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              aggregate.description!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (aggregate.treatment != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Treatment: ${aggregate.treatment!}',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _smallLabel(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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
      return AppColors.textSecondary;
  }
}

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
