import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydracat/core/theme/theme.dart';

/// A consistent icon container widget with optional background circle.
///
/// Provides a unified look for icons across all card types in the app,
/// with support for subtle background circles (Option B design).
///
/// The container consists of:
/// - Optional outer circle with radial gradient (subtle background)
/// - Inner square container with rounded corners
/// - Icon centered in the container
///
/// Example usage:
/// ```dart
/// IconContainer(
///   icon: Icons.medication,
///   color: AppColors.primary,
///   showBackgroundCircle: true,
/// )
/// ```
///
/// For custom SVG icons:
/// ```dart
/// IconContainer(
///   customIconAsset: 'assets/fonts/icons/SF_Symboles/weight.svg',
///   color: AppColors.primary,
///   showBackgroundCircle: true,
/// )
/// ```
class IconContainer extends StatelessWidget {
  /// Creates an [IconContainer].
  const IconContainer({
    this.icon,
    this.customIconAsset,
    super.key,
    this.color,
    this.size,
    this.containerSize,
    this.circleSize,
    this.showBackgroundCircle = true,
    this.semanticLabel,
  }) : assert(
         icon != null || customIconAsset != null,
         'Either icon or customIconAsset must be provided',
       );

  /// The icon to display (for IconData icons)
  final IconData? icon;

  /// The asset path for custom SVG icons
  final String? customIconAsset;

  /// The color of the icon and container accent
  /// Defaults to theme's primary color
  final Color? color;

  /// Size of the icon
  /// Defaults to [CardConstants.iconSize] (20px)
  final double? size;

  /// Size of the inner icon container
  /// Defaults to [CardConstants.iconContainerSize] (40px)
  final double? containerSize;

  /// Size of the outer background circle
  /// Defaults to [CardConstants.iconCircleSize] (56px)
  final double? circleSize;

  /// Whether to show the subtle background circle
  /// Defaults to true (Option B design)
  final bool showBackgroundCircle;

  /// Semantic label for accessibility
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.primary;
    final iconSizeValue = size ?? CardConstants.iconSize;
    final containerSizeValue = containerSize ?? CardConstants.iconContainerSize;
    final circleSizeValue = circleSize ?? CardConstants.iconCircleSize;

    final iconWidget = Container(
      width: containerSizeValue,
      height: containerSizeValue,
      decoration: BoxDecoration(
        color: CardConstants.iconBackgroundColor(iconColor),
        borderRadius: CardConstants.iconContainerBorderRadius,
      ),
      child: Center(
        child: customIconAsset != null
            ? SizedBox(
                width: iconSizeValue,
                height: iconSizeValue,
                child: SvgPicture.asset(
                  customIconAsset!,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
              )
            : Icon(
                icon,
                size: iconSizeValue,
                color: iconColor,
                semanticLabel: semanticLabel,
              ),
      ),
    );

    if (showBackgroundCircle) {
      return SizedBox(
        width: circleSizeValue,
        height: circleSizeValue,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                CardConstants.iconCircleGradientStart(iconColor),
                CardConstants.iconCircleGradientEnd(iconColor),
              ],
            ),
          ),
          child: Center(
            child: iconWidget,
          ),
        ),
      );
    }

    return iconWidget;
  }
}
