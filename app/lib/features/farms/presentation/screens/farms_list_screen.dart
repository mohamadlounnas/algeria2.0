import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../providers/farm_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/farm.dart';
import '../../../../core/routing/app_router.dart';

class FarmsListScreen extends StatefulWidget {
  const FarmsListScreen({super.key});

  @override
  State<FarmsListScreen> createState() => _FarmsListScreenState();
}

class _FarmsListScreenState extends State<FarmsListScreen> {
  bool _hasLoaded = false;

  String _farmTypeToString(FarmType type) {
    switch (type) {
      case FarmType.grapes:
        return 'GRAPES';
      case FarmType.wheat:
        return 'WHEAT';
      case FarmType.corn:
        return 'CORN';
      case FarmType.tomatoes:
        return 'TOMATOES';
      case FarmType.olives:
        return 'OLIVES';
      case FarmType.dates:
        return 'DATES';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      // Defer the call until after the build phase is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = FarmProvider.of(context);
        provider?.loadFarms?.call();
      });
      _hasLoaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = FarmProvider.of(context);
    final authProvider = AuthProvider.of(context);
    final user = authProvider?.user;

    return Scaffold(
      backgroundColor: Colors.transparent,
      headers: [
        AppBar(
          title: Text('Welcome, ${user?.name ?? 'User'}').h3(),
          trailing: [
            Tooltip(
              tooltip: (context) =>
                  const TooltipContainer(child: Text('Create Farm')),
              child: OutlineButton(
                density: ButtonDensity.icon,
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.createFarm);
                },
                child: const Icon(RadixIcons.plus),
              ),
            ),
            Tooltip(
              tooltip: (context) =>
                  const TooltipContainer(child: Text('Profile')),
              child: OutlineButton(
                density: ButtonDensity.icon,
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.profile);
                },
                child: const Icon(RadixIcons.person),
              ),
            ),
            Tooltip(
              tooltip: (context) =>
                  const TooltipContainer(child: Text('Sign Out')),
              child: OutlineButton(
                density: ButtonDensity.icon,
                onPressed: () async {
                  await authProvider?.signOut?.call();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                    );
                  }
                },
                child: const Icon(RadixIcons.exit),
              ),
            ),
          ],
        ),
      ],
      child: provider?.isLoading == true
          ? const Center(child: CircularProgressIndicator())
          : provider?.farms.isEmpty == true
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No farms yet').muted(),
                  const Gap(16),
                  PrimaryButton(
                    child: const Text('Create Your First Farm'),
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.createFarm);
                    },
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider?.farms.length ?? 0,
              itemBuilder: (context, index) {
                final farm = provider!.farms[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.farmDetail,
                        arguments: FarmDetailArgs(farmId: farm.id),
                      );
                    },
                    child: Card(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              RadixIcons.home,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(farm.name).h4(),
                                const Gap(4),
                                Text(
                                  '${_farmTypeToString(farm.type)} • ${farm.area.toStringAsFixed(2)} ha',
                                ).muted().small(),
                              ],
                            ),
                          ),
                          Icon(
                            RadixIcons.chevronRight,
                            color: Theme.of(
                              context,
                            ).colorScheme.mutedForeground,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
