import 'package:flutter/material.dart' as material hide ThemeData, Theme;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData get shadcnTheme {
    return ThemeData(
      colorScheme: ColorScheme(
        brightness: material.Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        background: AppColors.background,
        foreground: AppColors.textPrimary,
        muted: AppColors.textSecondary,
        mutedForeground: AppColors.textSecondary,
        card: AppColors.surface,
        cardForeground: AppColors.textPrimary,
        popover: AppColors.surface,
        popoverForeground: AppColors.textPrimary,
        border: AppColors.border,
        input: AppColors.border,
        primaryForeground: material.Colors.white,
        secondaryForeground: material.Colors.white,
        destructive: AppColors.error,
        destructiveForeground: material.Colors.white,
        accent: AppColors.primaryLight.withValues(alpha: 0.1),
        accentForeground: AppColors.primary,
        ring: AppColors.primary,
        // Sidebar colors
        sidebar: AppColors.surface,
        sidebarForeground: AppColors.textPrimary,
        sidebarPrimary: AppColors.primary,
        sidebarPrimaryForeground: material.Colors.white,
        sidebarAccent: AppColors.primaryLight.withValues(alpha: 0.1),
        sidebarAccentForeground: AppColors.primary,
        sidebarBorder: AppColors.border,
        sidebarRing: AppColors.primary,
        // Chart colors
        chart1: AppColors.primary,
        chart2: AppColors.primaryLight,
        chart3: const material.Color(0xFF10B981), // Green
        chart4: const material.Color(0xFFF59E0B), // Amber
        chart5: const material.Color(0xFFEF4444), // Red
      ),
      radius:
          1.0, // Using 1.0 as base, which gives us 12px at radiusMd (1.0 * 12)
      scaling: 1.0,
      surfaceOpacity: 1.0,
      surfaceBlur: 0.0,
    );
  }
}
