import 'dart:math' as math;

import 'package:flutter/material.dart' hide Colors, Chip;
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../domain/entities/request.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';

class DiseaseEntry {
  final String name;
  final Map<String, dynamic>? detail;

  const DiseaseEntry({required this.name, this.detail});
}

class DiseaseOverview extends StatelessWidget {
  const DiseaseOverview({super.key, required this.entries});

  final Iterable<DiseaseEntry> entries;

  List<DiseaseAggregate> get _aggregates {
    final map = <String, DiseaseAggregate>{};
    for (final entry in entries) {
      final aggregate = map.putIfAbsent(entry.name, () => DiseaseAggregate(entry.name));
      aggregate.add(entry.detail);
    }
    final list = map.values.toList();
    list.sort((a, b) => b.maxPercentage.compareTo(a.maxPercentage));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final aggregates = _aggregates;
    if (aggregates.isEmpty) {
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
            children: aggregates.map((aggregate) {
              final label = aggregate.maxPercentage > 0
                  ? '${aggregate.name} • ${aggregate.maxPercentage.toStringAsFixed(1)}%'
                  : aggregate.name;
              return Chip(
                child: Text(label),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: aggregates
                .map((aggregate) => DiseaseDetailCard(aggregate: aggregate))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class DiseaseAggregate {
  DiseaseAggregate(this.name);

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

class DiseaseDetailCard extends StatelessWidget {
  const DiseaseDetailCard({super.key, required this.aggregate});

  final DiseaseAggregate aggregate;

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

Iterable<DiseaseEntry> diseaseEntriesFromLeafs(Iterable<LeafData> leafs) {
  return leafs.expand((leaf) {
    return leaf.diseases.entries.map((entry) {
      final detail = entry.value is Map<String, dynamic>
          ? entry.value as Map<String, dynamic>
          : null;
      return DiseaseEntry(name: entry.key, detail: detail);
    });
  });
}
