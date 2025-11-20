import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';

/// Standardized card styling constants for consistent UI/UX across the app.
///
/// These constants ensure all cards follow the same design language,
/// making the interface more cohesive and professional.
class CardConstants {
  // Prevent instantiation
  const CardConstants._();

  /// Standard border radius for all cards
  static const double borderRadius = 12;

  /// Border radius for card corners
  static BorderRadius get cardBorderRadius =>
      BorderRadius.circular(borderRadius);

  // Icon Container Styling

  /// Size of the outer background circle
  static const double iconCircleSize = 56;

  /// Size of the inner icon container
  static const double iconContainerSize = 40;

  /// Size of the icon itself
  static const double iconSize = 20;

  /// Border radius for the inner icon container
  static const double iconContainerRadius = 8;

  /// Border radius for the icon container
  static BorderRadius get iconContainerBorderRadius =>
      BorderRadius.circular(iconContainerRadius);

  // Card Spacing

  /// Horizontal margin for cards
  static const double cardMarginHorizontal = AppSpacing.md;

  /// Vertical margin for cards
  static const double cardMarginVertical = AppSpacing.xs;

  /// Standard card margin
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(
    horizontal: cardMarginHorizontal,
    vertical: cardMarginVertical,
  );

  /// Horizontal padding inside cards
  static const double cardPaddingHorizontal = AppSpacing.md;

  /// Vertical padding inside cards
  static const double cardPaddingVertical = AppSpacing.sm;

  /// Standard card padding
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: cardPaddingHorizontal,
    vertical: cardPaddingVertical,
  );

  /// Content padding for ListTile-like cards
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.sm,
  );

  // Colors

  /// Background color for icon containers
  static Color iconBackgroundColor(Color baseColor) =>
      baseColor.withValues(alpha: 0.1);

  /// Outer circle gradient start color
  static Color iconCircleGradientStart(Color baseColor) =>
      baseColor.withValues(alpha: 0.05);

  /// Outer circle gradient end color (transparent)
  static Color iconCircleGradientEnd(Color baseColor) =>
      baseColor.withValues(alpha: 0);

  /// Card border color
  static Color cardBorderColor(BuildContext context) => Theme.of(context)
      .colorScheme
      .outline
      .withValues(alpha: 0.2);

  // Elevation & Shadows

  /// Standard card elevation (flat design)
  static const double cardElevation = 0;

  /// Card shadow for subtle depth (when needed)
  static BoxShadow cardShadow(BuildContext context) => const BoxShadow(
        color: Color(0x0A000000), // Black with 0.04 alpha
        blurRadius: 4,
        offset: Offset(0, 1),
      );
}
