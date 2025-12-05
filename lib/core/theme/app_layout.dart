import 'package:hydracat/core/theme/app_spacing.dart';

/// Layout constants and helpers for consistent UI structure
/// throughout HydraCat.
/// Defines standard layout dimensions, breakpoints, and responsive behavior.
class AppLayout {
  // Private constructor to prevent instantiation
  AppLayout._();

  // Screen breakpoints
  /// Mobile breakpoint - 600px
  static const double mobileBreakpoint = 600;

  /// Tablet breakpoint - 900px
  static const double tabletBreakpoint = 900;

  /// Desktop breakpoint - 1200px
  static const double desktopBreakpoint = 1200;

  // Layout dimensions
  /// Maximum content width for larger screens
  static const double maxContentWidth = 1200;

  /// Sidebar width for tablet/desktop layouts
  static const double sidebarWidth = 280;

  /// Bottom navigation bar height - 84px (reduced height)
  static const double bottomNavHeight = 84;

  /// Top app bar height - 56px
  static const double topAppBarHeight = 56;

  /// @deprecated Use AppBorderRadius.card instead
  static const double cardRadius = 12;

  /// @deprecated Use AppBorderRadius.button instead
  static const double buttonRadius = 8;

  /// @deprecated Use AppBorderRadius.input instead
  static const double inputRadius = 8;

  // Responsive helpers
  /// Check if current width is mobile
  static bool isMobile(double width) => width < mobileBreakpoint;

  /// Check if current width is tablet
  static bool isTablet(double width) =>
      width >= mobileBreakpoint && width < tabletBreakpoint;

  /// Check if current width is desktop
  static bool isDesktop(double width) => width >= tabletBreakpoint;

  /// Get responsive padding based on screen width
  static double getResponsivePadding(double width) {
    if (isMobile(width)) return AppSpacing.md;
    if (isTablet(width)) return AppSpacing.lg;
    return AppSpacing.xl;
  }

  /// Get responsive card padding based on screen width
  static double getResponsiveCardPadding(double width) {
    if (isMobile(width)) return AppSpacing.sm;
    if (isTablet(width)) return AppSpacing.md;
    return AppSpacing.lg;
  }
}
