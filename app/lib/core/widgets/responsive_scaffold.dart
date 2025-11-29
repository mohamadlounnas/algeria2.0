import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../../shared/widgets/authenticated_app_bar.dart';

/// Responsive scaffold that adapts to screen size
class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? appBar;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.extendBodyBehindAppBar = false,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);

    // Mobile: Standard scaffold with drawer
    if (responsive.isMobile) {
      return Scaffold(
      backgroundColor: Colors.transparent,
        appBar: appBar ??
            AuthenticatedAppBar(
              title: title,
              actions: actions,
            ),
        drawer: drawer,
        body: SafeArea(
          child: Padding(
            padding: responsive.padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
              child: body,
            ),
          ),
        ),
        floatingActionButton: floatingActionButton,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
      );
    }

    // Tablet/Desktop: Centered content with side navigation
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar ??
          AuthenticatedAppBar(
            title: title,
            actions: actions,
          ),
      body: Row(
        children: [
          // Side navigation for tablet/desktop
          if (drawer != null)
            SizedBox(
              width: responsive.isDesktop ? 280 : 240,
              child: drawer!,
            ),
          // Main content area
          Expanded(
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: responsive.padding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: responsive.maxContentWidth,
                    ),
                    child: body,
                  ),
                ),
              ),
            ),
          ),
          // End drawer (right side)
          if (endDrawer != null)
            SizedBox(
              width: responsive.isDesktop ? 320 : 280,
              child: endDrawer!,
            ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}
