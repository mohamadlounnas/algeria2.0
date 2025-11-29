import 'package:shadcn_flutter/shadcn_flutter.dart';
// Avoid importing Material; use shadcn Button only

class StandardButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const StandardButton({super.key, required this.text, this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Button.primary(
      child: Text(isLoading ? 'Saving...' : text),
      onPressed: onPressed,
    );
  }
}
