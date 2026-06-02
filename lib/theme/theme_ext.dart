import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Provides theme-aware semantic colors from any BuildContext.
/// Use these instead of hardcoded AppColors wherever dark mode must work.
extension ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Primary text — white in dark, near-black in light.
  Color get colorText => Theme.of(this).colorScheme.onSurface;

  /// Secondary / muted text — visible in both modes.
  Color get colorTextMuted => Theme.of(this).colorScheme.onSurfaceVariant;

  /// Scaffold / page background.
  Color get colorBackground => Theme.of(this).scaffoldBackgroundColor;

  /// Card / elevated surface background.
  Color get colorCard =>
      isDark ? const Color(0xFF1E1E35) : AppColors.white;

  /// Input field fill background.
  Color get colorInput =>
      isDark ? const Color(0xFF252545) : const Color(0xFFF3F4F6);

  /// Thin border / divider.
  Color get colorBorder =>
      isDark ? Colors.white12 : const Color(0xFFE5E7EB);

  /// Icon container background inside sheet cards.
  Color get colorIconBg =>
      isDark ? const Color(0xFF2E2E50) : AppColors.white;
}
