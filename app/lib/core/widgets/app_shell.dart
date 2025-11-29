import 'package:flutter/material.dart';
import '../routing/app_router.dart';
import '../utils/responsive.dart';
import '../../shared/widgets/authenticated_app_bar.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/domain/entities/user.dart';

/// Main app shell with responsive navigation
class AppShell extends StatefulWidget {
  final Widget child;
  final String? title;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  const AppShell({
    super.key,
    required this.child,
    this.title,
    this.floatingActionButton,
    this.actions,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final authProvider = AuthProvider.of(context);
    final user = authProvider?.user;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    // Calculate selected index based on current route
    int selectedIndex = 0;
    if (currentRoute.startsWith('/farms')) {
      selectedIndex = 0;
    } else if (currentRoute.startsWith('/admin')) {
      selectedIndex = user?.role == UserRole.admin ? 1 : 0;
    }

    void navigateTo(String route) {
      Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
    }

    // Build navigation drawer for mobile
    Widget? buildDrawer() {
      if (user == null) return null;

      return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.bodyLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              dense: true,
              leading: const Icon(Icons.agriculture_outlined),
              title: const Text('Farms'),
              selected: currentRoute.startsWith('/farms'),
              onTap: () {
                navigateTo(AppRoutes.farms);
                Navigator.of(context).pop();
              },
            ),
            if (user.role == UserRole.admin)
              ListTile(
                dense: true,
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin'),
                selected: currentRoute.startsWith('/admin'),
                onTap: () {
                  navigateTo(AppRoutes.adminRequests);
                  Navigator.of(context).pop();
                },
              ),
            // Logout is handled by AuthenticatedAppBar, no need to duplicate here
          ],
        ),
      );
    }

    // Build navigation rail for tablet/desktop
    Widget? buildNavigationRail() {
      if (user == null) return null;

      return NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 0) {
            navigateTo(AppRoutes.farms);
          } else if (index == 1 && user.role == UserRole.admin) {
            navigateTo(AppRoutes.adminRequests);
          }
        },
        labelType: responsive.isDesktop
            ? NavigationRailLabelType.all
            : NavigationRailLabelType.selected,
        extended: responsive.isDesktop,
        destinations: [
          const NavigationRailDestination(
            icon: Icon(Icons.agriculture_outlined),
            selectedIcon: Icon(Icons.agriculture),
            label: Text('Farms'),
          ),
          if (user.role == UserRole.admin)
            const NavigationRailDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings),
              label: Text('Admin'),
            ),
        ],
        trailing: Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: responsive.isDesktop ? 24 : 20,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: responsive.isDesktop ? 18 : 16,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  if (responsive.isDesktop) ...[
                    const SizedBox(height: 8),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Logout is handled by AuthenticatedAppBar, no need to duplicate here
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Mobile layout: Standard scaffold with drawer
    if (responsive.isMobile) {
      return Scaffold(
      backgroundColor: Colors.transparent,
        appBar: widget.title != null
            ? AuthenticatedAppBar(
                title: widget.title!,
                actions: widget.actions,
              )
            : null,
        drawer: buildDrawer(),
        body: SafeArea(
          child: Padding(
            padding: responsive.padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
              child: widget.child,
            ),
          ),
        ),
        floatingActionButton: widget.floatingActionButton,
      );
    }

    // Tablet/Desktop layout: Navigation rail + content
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: widget.title != null
          ? AuthenticatedAppBar(
              title: widget.title!,
              actions: widget.actions,
            )
          : null,
      body: Row(
        children: [
          // Navigation rail
          if (buildNavigationRail() != null) buildNavigationRail()!,
          // Main content
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: responsive.padding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: responsive.maxContentWidth,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
