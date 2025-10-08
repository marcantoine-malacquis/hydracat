/// Accessibility constants and helpers for HydraCat application.
/// Based on PRD requirements and UI guidelines.
class AppAccessibility {
  // Private constructor to prevent instantiation
  AppAccessibility._();

  // Minimum contrast ratios (WCAG AA standard)
  /// Minimum contrast ratio for normal text
  static const double minContrastRatio = 4.5;

  /// Minimum contrast ratio for large text
  static const double minLargeTextContrastRatio = 3;

  // Touch target minimums (from UI guidelines)
  /// Minimum touch target size - 44px
  static const double minTouchTarget = 44;

  /// FAB touch target size - 56px
  static const double fabTouchTarget = 56;

  // Focus indicators
  /// Focus outline width
  static const double focusOutlineWidth = 2;

  /// Focus outline offset
  static const double focusOutlineOffset = 2;

  // Typography accessibility
  /// Minimum body text size
  static const double minBodyTextSize = 16;

  /// Minimum line height ratio
  static const double minLineHeightRatio = 1.4;

  // Screen reader support
  /// Default semantic label for buttons
  static const String defaultButtonLabel = 'Button';

  /// Default semantic label for icons
  static const String defaultIconLabel = 'Icon';

  /// Default semantic label for cards
  static const String defaultCardLabel = 'Card';

  /// Default semantic label for navigation items
  static const String defaultNavigationLabel = 'Navigation item';

  // Haptic feedback patterns
  // Note: Use Flutter's HapticFeedback class directly
  // These guidelines document when to use each type

  /// Selection haptic: Use HapticFeedback.selectionClick()
  /// For toggles, radio buttons, checkbox selections, multi-select items
  static const String selectionFeedbackGuideline =
      'HapticFeedback.selectionClick()';

  /// Success haptic: Use HapticFeedback.lightImpact()
  /// For successful form submission, completed actions, success transitions
  static const String successFeedbackGuideline = 'HapticFeedback.lightImpact()';

  /// Primary action haptic: Use HapticFeedback.mediumImpact()
  /// For FAB press, critical actions, long-press triggers
  static const String primaryActionFeedbackGuideline =
      'HapticFeedback.mediumImpact()';

  // Screen reader announcements
  // Note: Use TextDirection.ltr for SemanticsService.announce() calls
}
