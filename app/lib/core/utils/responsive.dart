import 'package:flutter/material.dart';

/// Responsive breakpoints
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Responsive utility class
class Responsive {
  final BuildContext context;
  final double width;
  final double height;

  Responsive._(this.context, this.width, this.height);

  factory Responsive.of(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Responsive._(context, mediaQuery.size.width, mediaQuery.size.height);
  }

  /// Check if current screen is mobile
  bool get isMobile => width < Breakpoints.mobile;

  /// Check if current screen is tablet
  bool get isTablet => width >= Breakpoints.mobile && width < Breakpoints.desktop;

  /// Check if current screen is desktop
  bool get isDesktop => width >= Breakpoints.desktop;

  /// Get responsive value based on screen size
  T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  /// Get number of columns for grid
  int get gridColumns => value<int>(
        mobile: 1,
        tablet: 2,
        desktop: 3,
      );

  /// Get padding based on screen size
  EdgeInsets get padding => value<EdgeInsets>(
        mobile: const EdgeInsets.all(16),
        tablet: const EdgeInsets.all(24),
        desktop: const EdgeInsets.all(32),
      );

  /// Get max content width
  double get maxContentWidth => value<double>(
        mobile: double.infinity,
        tablet: 800,
        desktop: 1200,
      );
}
