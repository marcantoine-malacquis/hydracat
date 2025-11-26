import 'package:hydracat/core/theme/app_layout.dart';
import 'package:hydracat/core/theme/app_spacing.dart';

/// Utility class for calculating snackbar/toast positioning.
///
/// Provides centralized positioning logic to ensure snackbars are positioned
/// consistently above the bottom navigation bar with proper spacing.
class SnackbarLayoutUtils {
  // Private constructor to prevent instantiation
  SnackbarLayoutUtils._();

  /// Calculate bottom offset for snackbar positioning.
  ///
  /// Algorithm:
  /// 1. Start with safe area padding (device notches/home indicators)
  /// 2. Add keyboard insets (if keyboard is visible)
  /// 3. Add navigation bar height (84px)
  /// 4. Add gap between snackbar and nav bar (8px)
  ///
  /// Note: The same calculation is used whether the navigation bar is visible
  /// or hidden to maintain consistent visual positioning from screen bottom.
  ///
  /// Returns: Total bottom offset in pixels
  ///
  /// Example:
  /// ```dart
  /// final bottomOffset = SnackbarLayoutUtils.calculateBottomOffset(
  ///   safeAreaBottom: MediaQuery.of(context).padding.bottom,
  ///   keyboardInset: MediaQuery.of(context).viewInsets.bottom,
  ///   isNavigationBarVisible: true,
  /// );
  /// ```
  static double calculateBottomOffset({
    required double safeAreaBottom,
    required double keyboardInset,
    required bool isNavigationBarVisible,
  }) {
    // Base: safe area + keyboard
    var offset = safeAreaBottom + keyboardInset;

    // Always add nav bar height + gap (whether visible or not)
    // This maintains consistent position from screen bottom
    offset += AppLayout.bottomNavHeight; // 84px
    offset += AppSpacing.sm; // 8px gap

    return offset;
  }
}
