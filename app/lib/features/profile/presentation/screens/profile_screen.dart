import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../../core/routing/app_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.farmer:
        return 'Farmer';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context);
    final user = authProvider?.user;

    if (user == null) {
      return Scaffold(
      backgroundColor: Colors.transparent,
        child: const Center(child: Text('No profile information available')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      headers: [
        AppBar(
          title: const Text('Profile').h3(),
          leading: [
            OutlineButton(
              density: ButtonDensity.icon,
              onPressed: () => Navigator.of(context).pop(),
              child: Icon(RadixIcons.arrowLeft),
            ),
          ],
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Avatar(
                  initials: user.name.isNotEmpty
                      ? user.name[0].toUpperCase()
                      : 'U',
                  size: 80,
                ),
                const Gap(16),
                Text(user.name).h3().textCenter(),
                const Gap(8),
                PrimaryBadge(child: Text(_roleLabel(user.role))),
                const Gap(32),
                Card(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Account Details').h4(),
                      const Gap(16),
                      Row(
                        children: [
                          Icon(RadixIcons.envelopeClosed),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Email').muted(),
                                const Gap(4),
                                Text(user.email),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                      Row(
                        children: [
                          Icon(RadixIcons.idCard),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Role').muted(),
                                const Gap(4),
                                Text(_roleLabel(user.role)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                      Row(
                        children: [
                          Icon(RadixIcons.person),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('User ID').muted(),
                                const Gap(4),
                                Text(user.id).small(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(32),
                PrimaryButton(
                  onPressed: authProvider?.isLoading == true
                      ? null
                      : () async {
                          await authProvider?.signOut?.call();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.login,
                              (route) => false,
                            );
                          }
                        },
                  child: authProvider?.isLoading == true
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(size: 20),
                            ),
                            const Gap(8),
                            const Text('Signing out...'),
                          ],
                        )
                      : const Text('Sign Out'),
                ),
                const Gap(16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  leading: Icon(RadixIcons.arrowLeft),
                  child: const Text('Back to Farms'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
