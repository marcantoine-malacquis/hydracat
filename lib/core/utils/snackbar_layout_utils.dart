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
  /// 1. If keyboard is visible (keyboardInset > 0), base offset on keyboard
  ///    inset
  /// 2. If nav bar is visible (and no keyboard), use nav bar height only
  ///    (nav bar already occupies safe area zone)
  /// 3. If nav bar is hidden (and no keyboard), use safe area padding
  ///    (for home indicator clearance)
  /// 4. Add gap (4px) at the end for spacing from nav bar or bottom edge
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
    final keyboardVisible = keyboardInset > 0;
    double offset;

    if (keyboardVisible) {
      // When keyboard is visible, position above keyboard
      offset = keyboardInset;
    } else if (isNavigationBarVisible) {
      // When nav is visible, use nav height only
      // (nav already occupies safe area)
      offset = AppLayout.bottomNavHeight;
    } else {
      // When nav is hidden, use safe area for home indicator clearance
      offset = safeAreaBottom;
    }

    // Add gap at the end (distance from nav bar or from bottom when nav hidden)
    return offset + AppSpacing.xs; // 4px gap
  }
}
