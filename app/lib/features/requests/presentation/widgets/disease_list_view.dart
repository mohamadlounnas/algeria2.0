import 'package:flutter/material.dart';
import '../../domain/entities/request.dart';
import '../../../../core/theme/spacing.dart';

class DiseaseListView extends StatelessWidget {
  final List<RequestImage> images;

  const DiseaseListView({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    final diseasedImages = images
        .where((img) => img.diseaseType != null)
        .toList();

    if (diseasedImages.isEmpty) {
      return const Center(child: Text('No diseases detected'));
    }

    // Group by disease type
    final diseaseGroups = <String, List<RequestImage>>{};
    for (final image in diseasedImages) {
      final diseaseType = image.diseaseType!;
      diseaseGroups.putIfAbsent(diseaseType, () => []).add(image);
    }

    return ListView.builder(
      itemCount: diseaseGroups.length,
      itemBuilder: (context, index) {
        final entry = diseaseGroups.entries.elementAt(index);
        final diseaseType = entry.key;
        final diseaseImages = entry.value;
        final firstImage = diseaseImages.first;

        return Card.outlined(
          child: ExpansionTile(
            title: Text(diseaseType),
            subtitle: Text('${diseaseImages.length} locations'),
            children: [
              if (firstImage.treatmentPlan != null)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Treatment Plan:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(firstImage.treatmentPlan!),
                    ],
                  ),
                ),
              if (firstImage.materials != null)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Materials:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(firstImage.materials!),
                    ],
                  ),
                ),
              if (firstImage.services != null)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Services:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(firstImage.services!),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
