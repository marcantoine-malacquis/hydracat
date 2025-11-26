import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/theme/app_layout.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/utils/snackbar_layout_utils.dart';

void main() {
  group('SnackbarLayoutUtils', () {
    group('calculateBottomOffset', () {
      const navBarHeight = AppLayout.bottomNavHeight; // 84px
      const gap = AppSpacing.sm; // 8px
      const expectedNavBarOffset = navBarHeight + gap; // 92px

      test('calculates correct offset with no safe area or keyboard', () {
        final offset = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: 0,
          keyboardInset: 0,
          isNavigationBarVisible: true,
        );

        expect(offset, equals(expectedNavBarOffset));
        expect(offset, equals(92.0));
      });

      test('includes safe area padding in calculation', () {
        const safeAreaBottom = 34.0; // iPhone with notch
        final offset = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: safeAreaBottom,
          keyboardInset: 0,
          isNavigationBarVisible: true,
        );

        expect(offset, equals(safeAreaBottom + expectedNavBarOffset));
        expect(offset, equals(126.0)); // 34 + 92
      });

      test('includes keyboard inset in calculation', () {
        const keyboardInset = 300.0;
        final offset = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: 0,
          keyboardInset: keyboardInset,
          isNavigationBarVisible: true,
        );

        expect(offset, equals(keyboardInset + expectedNavBarOffset));
        expect(offset, equals(392.0)); // 300 + 92
      });

      test('includes both safe area and keyboard in calculation', () {
        const safeAreaBottom = 34.0;
        const keyboardInset = 300.0;
        final offset = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: safeAreaBottom,
          keyboardInset: keyboardInset,
          isNavigationBarVisible: true,
        );

        expect(
          offset,
          equals(safeAreaBottom + keyboardInset + expectedNavBarOffset),
        );
        expect(offset, equals(426.0)); // 34 + 300 + 92
      });

      test(
          'maintains same position when nav bar is hidden '
          '(isNavigationBarVisible: false)', () {
        // When nav bar is hidden, we still use the same offset to maintain
        // consistent visual position from screen bottom
        final offsetVisible = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: 0,
          keyboardInset: 0,
          isNavigationBarVisible: true,
        );

        final offsetHidden = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: 0,
          keyboardInset: 0,
          isNavigationBarVisible: false,
        );

        expect(offsetVisible, equals(offsetHidden));
        expect(offsetHidden, equals(92.0));
      });

      test(
          'maintains same position when nav bar is hidden '
          'with safe area and keyboard', () {
        const safeAreaBottom = 34.0;
        const keyboardInset = 300.0;

        final offsetVisible = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: safeAreaBottom,
          keyboardInset: keyboardInset,
          isNavigationBarVisible: true,
        );

        final offsetHidden = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: safeAreaBottom,
          keyboardInset: keyboardInset,
          isNavigationBarVisible: false,
        );

        expect(offsetVisible, equals(offsetHidden));
        expect(offsetHidden, equals(426.0)); // 34 + 300 + 92
      });

      test('handles zero safe area (older iPhones)', () {
        final offset = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: 0,
          keyboardInset: 0,
          isNavigationBarVisible: true,
        );

        expect(offset, equals(92.0));
      });

      test('handles large safe area (iPhone with notch)', () {
        const safeAreaBottom = 34.0;
        final offset = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: safeAreaBottom,
          keyboardInset: 0,
          isNavigationBarVisible: true,
        );

        expect(offset, equals(126.0)); // 34 + 92
      });

      test('calculates offset with all parameters non-zero', () {
        const safeAreaBottom = 20.0;
        const keyboardInset = 250.0;

        final offset = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: safeAreaBottom,
          keyboardInset: keyboardInset,
          isNavigationBarVisible: true,
        );

        expect(offset, equals(362.0)); // 20 + 250 + 92
      });

      test('offset is always at least nav bar height + gap when no keyboard',
          () {
        // Even with zero safe area, offset should be at least nav bar + gap
        final offset = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: 0,
          keyboardInset: 0,
          isNavigationBarVisible: true,
        );

        expect(offset, greaterThanOrEqualTo(expectedNavBarOffset));
      });
    });
  });
}
