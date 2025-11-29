import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../core/theme/text_styles.dart';
// Use shadcn_flutter only

class StandardListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onPressed;

  const StandardListTile({super.key, required this.title, this.subtitle, this.trailing, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Clickable(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle.merge(style: AppTextStyles.bodyLarge, child: title),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    DefaultTextStyle.merge(style: AppTextStyles.bodyMedium, child: subtitle!),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
