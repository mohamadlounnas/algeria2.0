import 'package:shadcn_flutter/shadcn_flutter.dart';
// Do not import material; use shadcn TextField

class StandardTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final int maxLines;

  const StandardTextField({super.key, required this.label, this.controller, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      hintText: label,
    );
  }
}
