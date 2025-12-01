import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/theme/app_layout.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/utils/snackbar_layout_utils.dart';

void main() {
  group('SnackbarLayoutUtils', () {
    group('calculateBottomOffset', () {
      const navBarHeight = AppLayout.bottomNavHeight; // 84px
      const gap = AppSpacing.xs; // 4px (updated from 8px)
      const expectedNavBarOffset =
          navBarHeight + gap; // 88px (updated from 92px)

      test(
        'calculates correct offset with nav visible, no safe area or keyboard',
        () {
          final offset = SnackbarLayoutUtils.calculateBottomOffset(
            safeAreaBottom: 0,
            keyboardInset: 0,
            isNavigationBarVisible: true,
          );

          expect(offset, equals(expectedNavBarOffset));
          expect(offset, equals(88.0)); // 84 + 4
        },
      );

      test(
        'calculates correct offset with nav hidden, no safe area or keyboard',
        () {
          final offset = SnackbarLayoutUtils.calculateBottomOffset(
            safeAreaBottom: 0,
            keyboardInset: 0,
            isNavigationBarVisible: false,
          );

          // When nav is hidden, only gap is added (no nav height)
          expect(offset, equals(gap));
          expect(offset, equals(4.0));
        },
      );

      test('includes safe area padding when nav is hidden', () {
        const safeAreaBottom = 34.0; // iPhone with notch
        final offset = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: safeAreaBottom,
          keyboardInset: 0,
          isNavigationBarVisible: false,
        );

        // When nav is hidden: safeArea + gap (no nav height)
        expect(offset, equals(safeAreaBottom + gap));
        expect(offset, equals(38.0)); // 34 + 4
      });

      test('ignores safe area padding when nav is visible', () {
        const safeAreaBottom = 34.0; // iPhone with notch
        final offset = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: safeAreaBottom,
          keyboardInset: 0,
          isNavigationBarVisible: true,
        );

        // When nav is visible: navHeight + gap only
        // (no safe area double-counting)
        expect(offset, equals(expectedNavBarOffset));
        expect(offset, equals(88.0)); // 84 + 4
      });

      test(
        'uses keyboard inset when keyboard is visible '
        '(ignores safe area and nav)',
        () {
          const keyboardInset = 300.0;
          final offset = SnackbarLayoutUtils.calculateBottomOffset(
            safeAreaBottom: 34,
            keyboardInset: keyboardInset,
            isNavigationBarVisible: true,
          );

          // When keyboard is visible, use keyboard inset + gap only
          // (nav is typically hidden when keyboard is visible)
          expect(offset, equals(keyboardInset + gap));
          expect(offset, equals(304.0)); // 300 + 4
        },
      );

      test('uses keyboard inset when keyboard visible and nav hidden', () {
        const keyboardInset = 300.0;
        final offset = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: 34,
          keyboardInset: keyboardInset,
          isNavigationBarVisible: false,
        );

        // When keyboard visible and nav hidden: keyboard + gap only
        expect(offset, equals(keyboardInset + gap));
        expect(offset, equals(304.0)); // 300 + 4
      });

      test('handles zero safe area (older iPhones) with nav visible', () {
        final offset = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: 0,
          keyboardInset: 0,
          isNavigationBarVisible: true,
        );

        expect(offset, equals(88.0)); // 84 + 4
      });

      test('handles zero safe area (older iPhones) with nav hidden', () {
        final offset = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: 0,
          keyboardInset: 0,
          isNavigationBarVisible: false,
        );

        expect(offset, equals(4.0)); // gap only
      });

      test('handles large safe area (iPhone with notch) with nav visible', () {
        const safeAreaBottom = 34.0;
        final offset = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: safeAreaBottom,
          keyboardInset: 0,
          isNavigationBarVisible: true,
        );

        // Nav visible: navHeight + gap only (safe area ignored)
        expect(offset, equals(88.0)); // 84 + 4
      });

      test('handles large safe area (iPhone with notch) with nav hidden', () {
        const safeAreaBottom = 34.0;
        final offset = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: safeAreaBottom,
          keyboardInset: 0,
          isNavigationBarVisible: false,
        );

        expect(offset, equals(38.0)); // 34 + 4
      });

      test('calculates offset with all parameters non-zero, nav visible', () {
        const safeAreaBottom = 20.0;
        const keyboardInset = 250.0;

        final offset = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: safeAreaBottom,
          keyboardInset: keyboardInset,
          isNavigationBarVisible: true,
        );

        // Keyboard takes precedence over safe area and nav
        expect(offset, equals(254.0)); // 250 + 4
      });

      test('calculates offset with all parameters non-zero, nav hidden', () {
        const safeAreaBottom = 20.0;
        const keyboardInset = 250.0;

        final offset = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: safeAreaBottom,
          keyboardInset: keyboardInset,
          isNavigationBarVisible: false,
        );

        // Keyboard takes precedence over safe area, no nav height
        expect(offset, equals(254.0)); // 250 + 4
      });

      test('offset is always at least gap when nav hidden and no keyboard', () {
        final offset = SnackbarLayoutUtils.calculateBottomOffset(
          safeAreaBottom: 0,
          keyboardInset: 0,
          isNavigationBarVisible: false,
        );

        expect(offset, greaterThanOrEqualTo(gap));
        expect(offset, equals(4.0));
      });

      test(
        'offset is always at least nav bar height + gap when nav visible '
        'and no keyboard',
        () {
          final offset = SnackbarLayoutUtils.calculateBottomOffset(
            safeAreaBottom: 0,
            keyboardInset: 0,
            isNavigationBarVisible: true,
          );

          expect(offset, greaterThanOrEqualTo(expectedNavBarOffset));
          expect(offset, equals(88.0));
        },
      );
    });
  });
}
