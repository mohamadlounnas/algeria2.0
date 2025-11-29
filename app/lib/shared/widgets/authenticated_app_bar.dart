import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/colors.dart';
import '../../../core/routing/app_router.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/auth/domain/entities/user.dart';

class AuthenticatedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showSignOut;

  const AuthenticatedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showSignOut = true,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context);
    final isAdmin = authProvider?.user?.role == UserRole.admin;

    final appBarActions = <Widget>[
      if (isAdmin)
        IconButton.ghost(
          icon: const Icon(LucideIcons.settings),
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.adminRequests);
          },
        ),
      if (showSignOut)
        IconButton.ghost(
          icon: const Icon(LucideIcons.logOut),
          onPressed: () async {
            await authProvider?.signOut?.call();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            }
          },
        ),
      if (actions != null) ...actions!,
    ];

    return AppBar(
      title: Text(title, style: AppTextStyles.h4),
      trailing: appBarActions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}

