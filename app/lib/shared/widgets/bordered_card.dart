import 'package:shadcn_flutter/shadcn_flutter.dart';
// Avoid importing material; use shadcn_flutter components only

class BorderedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const BorderedCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      borderColor: theme.colorScheme.border,
      borderWidth: 1,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
