import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../screens/farm_settings_screen.dart';
import '../../../requests/presentation/screens/requests_list_screen.dart';

class FarmScaffold extends StatefulWidget {
  final String farmId;
  final int initialTab;

  const FarmScaffold({super.key, required this.farmId, this.initialTab = 0});

  @override
  State<FarmScaffold> createState() => _FarmScaffoldState();
}

class _FarmScaffoldState extends State<FarmScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      RequestsListScreen(farmId: widget.farmId),
      FarmSettingsScreen(farmId: widget.farmId),
    ];

    return Scaffold(
      footers: [
        const Divider(height: 1),
        NavigationBar(
          index: _currentIndex,
          onSelected: (index) => setState(() => _currentIndex = index),
          labelType: NavigationLabelType.selected,
          children: [
            NavigationItem(
              label: const Text('Requests'),
              child: const Icon(RadixIcons.listBullet),
            ),
            NavigationItem(
              label: const Text('Settings'),
              child: const Icon(RadixIcons.gear),
            ),
          ],
        ),
      ],
      child: IndexedStack(index: _currentIndex, children: pages),
    );
  }
}
