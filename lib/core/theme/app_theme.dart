import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_border_radius.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';

/// App bar style variant configuration.
///
/// Defines background color for the default app bar style.
class _AppBarStyleTokens {
  _AppBarStyleTokens._();

  /// Default variant: subtle tonal surface (6% primary blend)
  static Color get defaultBackground => Color.alphaBlend(
    AppColors.primary.withValues(alpha: 0.06),
    AppColors.background,
  );
}

/// Main theme configuration for the HydraCat application.
/// Implements the water-themed design system from the UI guidelines.
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Light theme for the application
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.textPrimary,

        secondary: AppColors.success,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.successLight,
        onSecondaryContainer: AppColors.textPrimary,

        tertiary: AppColors.warning,
        onTertiary: AppColors.onPrimary,
        tertiaryContainer: AppColors.warningLight,
        onTertiaryContainer: AppColors.textPrimary,

        error: AppColors.error,
        errorContainer: AppColors.errorLight,
        onErrorContainer: AppColors.textPrimary,

        surfaceContainerHighest: AppColors.border,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.divider,

        shadow: AppColors.textTertiary,
        scrim: AppColors.textTertiary,
        inverseSurface: AppColors.textPrimary,
        onInverseSurface: AppColors.surface,
        inversePrimary: AppColors.primaryLight,
      ),

      // Typography
      textTheme: _buildTextTheme(),

      // Component Themes
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      floatingActionButtonTheme: _buildFloatingActionButtonTheme(),
      cardTheme: _buildCardTheme(),
      appBarTheme: _buildAppBarTheme(),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      chipTheme: _buildChipTheme(),
      switchTheme: _buildSwitchTheme(),
      dialogTheme: _buildDialogTheme(),

      // Layout
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  /// Dark theme for the application (future implementation)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryDark,
        onPrimaryContainer: AppColors.darkOnBackground,

        secondary: AppColors.success,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.successDark,
        onSecondaryContainer: AppColors.darkOnBackground,

        tertiary: AppColors.warning,
        onTertiary: AppColors.onPrimary,
        tertiaryContainer: AppColors.warningDark,
        onTertiaryContainer: AppColors.darkOnBackground,

        error: AppColors.error,
        onError: AppColors.onPrimary,
        errorContainer: AppColors.errorDark,
        onErrorContainer: AppColors.darkOnBackground,

        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,

        surfaceContainerHighest: AppColors.border,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.divider,

        shadow: AppColors.textTertiary,
        scrim: AppColors.textTertiary,
        inverseSurface: AppColors.darkOnBackground,
        onInverseSurface: AppColors.darkBackground,
        inversePrimary: AppColors.primaryDark,
      ),

      // Typography
      textTheme: _buildTextTheme(),

      // Component Themes
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      floatingActionButtonTheme: _buildFloatingActionButtonTheme(),
      cardTheme: _buildCardTheme(),
      appBarTheme: _buildAppBarTheme(),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      chipTheme: _buildChipTheme(),
      switchTheme: _buildSwitchTheme(),

      // Layout
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  // Private helper methods for building component themes

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      displayLarge: AppTextStyles.display,
      displayMedium: AppTextStyles.h1,
      displaySmall: AppTextStyles.h2,

      headlineLarge: AppTextStyles.h1,
      headlineMedium: AppTextStyles.h2,
      headlineSmall: AppTextStyles.h3,

      titleLarge: AppTextStyles.h2,
      titleMedium: AppTextStyles.h3,
      titleSmall: AppTextStyles.body,

      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,

      labelLarge: AppTextStyles.buttonPrimary,
      labelMedium: AppTextStyles.caption,
      labelSmall: AppTextStyles.small,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        shadowColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.buttonRadius,
        ),
        textStyle: AppTextStyles.buttonPrimary,
        minimumSize: const Size(
          AppSpacing.minTouchTarget,
          AppSpacing.minTouchTarget,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.buttonRadius,
        ),
        textStyle: AppTextStyles.buttonSecondary,
        minimumSize: const Size(
          AppSpacing.minTouchTarget,
          AppSpacing.minTouchTarget,
        ),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        textStyle: AppTextStyles.buttonSecondary,
        minimumSize: const Size(
          AppSpacing.minTouchTarget,
          AppSpacing.minTouchTarget,
        ),
      ),
    );
  }

  static FloatingActionButtonThemeData _buildFloatingActionButtonTheme() {
    return const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      // Don't set shape - let Flutter use default shapes:
      // CircleBorder for regular FAB, StadiumBorder for extended FAB
    );
  }

  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shadowColor: AppColors.textTertiary,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.cardRadius,
        side: const BorderSide(
          color: AppColors.border,
        ),
      ),
      margin: const EdgeInsets.all(AppSpacing.sm),
    );
  }

  static AppBarTheme _buildAppBarTheme() {
    return AppBarTheme(
      // Default variant: subtle tonal surface (6% primary blend)
      backgroundColor: _AppBarStyleTokens.defaultBackground,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: const Border(
        bottom: BorderSide(
          color: AppColors.border,
        ),
      ),
      centerTitle: true,
      toolbarHeight: AppSpacing.appBarHeight,
      titleTextStyle: AppTextStyles.h2.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavigationBarTheme() {
    return const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: AppTextStyles.navigationLabel,
      unselectedLabelStyle: AppTextStyles.navigationLabel,
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: AppBorderRadius.inputRadius,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.inputRadius,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.inputRadius,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.inputRadius,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.all(AppSpacing.md),
      labelStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
    );
  }

  static ChipThemeData _buildChipTheme() {
    return ChipThemeData(
      backgroundColor: AppColors.primaryLight,
      selectedColor: AppColors.primary,
      disabledColor: AppColors.disabled,
      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.chipRadius,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    );
  }

  static SwitchThemeData _buildSwitchTheme() {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textTertiary;
          }
          return AppColors.onPrimary;
        },
      ),
      trackColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.disabled;
          }
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.border;
        },
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textTertiary.withValues(alpha: 0.2);
          }
          return Colors.transparent;
        },
      ),
    );
  }

  static DialogThemeData _buildDialogTheme() {
    return DialogThemeData(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.dialogRadius,
      ),
    );
  }
}
