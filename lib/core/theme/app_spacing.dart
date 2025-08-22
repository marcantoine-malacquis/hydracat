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
  /// Minimum touch target size - 44px
  static const double minTouchTarget = 44;

  /// FAB button size - 56px
  static const double fabSize = 56;

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
