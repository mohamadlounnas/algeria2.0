import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/colors.dart';

class ImageCaptureButtons extends StatelessWidget {
  final VoidCallback onNormalImage;
  final VoidCallback onMacroImage;
  final VoidCallback onNormalFromGallery;
  final VoidCallback onMacroFromGallery;
  final bool isBusy;
  final int pendingCount;

  const ImageCaptureButtons({
    super.key,
    required this.onNormalImage,
    required this.onMacroImage,
    required this.onNormalFromGallery,
    required this.onMacroFromGallery,
    this.isBusy = false,
    this.pendingCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Capture Images',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 100,
                child: PrimaryButton(
                  onPressed: isBusy ? null : onNormalImage,
                  size: ButtonSize.large,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.camera_alt, size: 40),
                      Text('Normal Image', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SizedBox(
                height: 100,
                child: PrimaryButton(
                  onPressed: isBusy ? null : onMacroImage,
                  size: ButtonSize.large,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.zoom_in, size: 40),
                      Text(
                        'Macro Image',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: GhostButton(
                onPressed: isBusy ? null : onNormalFromGallery,
                size: ButtonSize.small,
                leading: const Icon(Icons.photo_library_outlined),
                child: const Text('Import Normal'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GhostButton(
                onPressed: isBusy ? null : onMacroFromGallery,
                size: ButtonSize.small,
                leading: const Icon(Icons.collections_outlined),
                child: const Text('Import Macro'),
              ),
            ),
          ],
        ),
        if (pendingCount > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$pendingCount image(s) ready to send',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Tip: Ensure GPS is enabled before capturing so agronomists receive location context.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
