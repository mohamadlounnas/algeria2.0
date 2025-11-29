import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../../../core/constants/app_constants.dart';

class FarmTypeSelector extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeSelected;

  const FarmTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Farm Type').h4(),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.farmTypes.map((type) {
            final isEnabled = AppConstants.enabledFarmTypes.contains(type);
            final isSelected = selectedType == type;

            return isSelected
                ? PrimaryButton(
                    onPressed: isEnabled ? () => onTypeSelected(type) : null,
                    child: Text(type),
                  )
                : OutlineButton(
                    onPressed: isEnabled ? () => onTypeSelected(type) : null,
                    child: Text(type),
                  );
          }).toList(),
        ),
      ],
    );
  }
}
