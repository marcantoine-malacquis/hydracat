import 'package:hydracat/core/constants/app_accessibility.dart';

/// Spacing constants for consistent layout throughout the HydraCat application.
/// Based on the UI guidelines spacing scale.
class AppSpacing {
  // Private constructor to prevent instantiation
  AppSpacing._();

  // Spacing scale (4px base unit)
  /// Extra small spacing - 4px
  static const double xs = 4;

  /// Small spacing - 8px
  static const double sm = 8;

  /// Medium spacing - 16px (standard spacing)
  static const double md = 16;

  /// Large spacing - 24px (section separation)
  static const double lg = 24;

  /// Extra large spacing - 32px (major sections)
  static const double xl = 32;

  /// Double extra large spacing - 48px (screen separation)
  static const double xxl = 48;

  // Touch target minimums
  // (references AppAccessibility for single source of truth)
  /// Minimum touch target size - 44px
  ///
  /// References [AppAccessibility.minTouchTarget] to maintain consistency
  /// with accessibility standards.
  static const double minTouchTarget = AppAccessibility.minTouchTarget;

  /// FAB button size - 56px
  ///
  /// References [AppAccessibility.fabTouchTarget] to maintain consistency
  /// with accessibility standards.
  static const double fabSize = AppAccessibility.fabTouchTarget;

  // Layout specific spacing
  /// Screen padding minimum - 24px
  static const double screenPadding = lg;

  /// Card internal padding - 16px
  static const double cardPadding = md;

  /// Section spacing - 32px
  static const double sectionSpacing = xl;

  /// Button spacing - 16px (prevents accidental taps)
  static const double buttonSpacing = md;
}
