import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_accessibility.dart';
import 'package:hydracat/shared/widgets/accessibility/hydra_touch_target.dart';

/// An IconButton wrapper that guarantees touch target compliance.
///
/// This widget ensures that IconButtons meet the minimum 44×44px
/// touch target size requirement, regardless of icon size or styling.
///
/// Example usage:
/// ```dart
/// TouchTargetIconButton(
///   icon: Icon(Icons.delete),
///   onPressed: () => deleteItem(),
///   tooltip: 'Delete item',
/// )
/// ```
///
/// For custom styling:
/// ```dart
/// TouchTargetIconButton(
///   icon: Icon(Icons.edit, size: 20, color: Colors.blue),
///   onPressed: () => editItem(),
///   tooltip: 'Edit item',
///   semanticLabel: 'Edit medication details',
/// )
/// ```
class TouchTargetIconButton extends StatelessWidget {
  /// Creates a [TouchTargetIconButton].
  const TouchTargetIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.tooltip,
    this.color,
    this.iconSize,
    this.semanticLabel,
    this.visualDensity = VisualDensity.standard,
    this.padding,
    this.splashRadius,
  });

  /// The icon to display in the button.
  final Widget icon;

  /// Callback when the button is pressed.
  ///
  /// Set to null to disable the button.
  final VoidCallback? onPressed;

  /// Tooltip to display on long press (also used for accessibility).
  final String? tooltip;

  /// Color of the icon.
  final Color? color;

  /// Size of the icon (does not affect touch target size).
  final double? iconSize;

  /// Optional semantic label for screen readers.
  ///
  /// If not provided, [tooltip] will be used instead.
  final String? semanticLabel;

  /// Visual density for the button.
  ///
  /// Defaults to [VisualDensity.standard]. Change to [VisualDensity.compact]
  /// for tighter spacing, but note that touch target will still be maintained.
  final VisualDensity visualDensity;

  /// Internal padding for the button.
  ///
  /// If not specified, defaults to zero since [HydraTouchTarget]
  /// handles the minimum size constraint.
  final EdgeInsetsGeometry? padding;

  /// Splash radius for the ripple effect.
  final double? splashRadius;

  @override
  Widget build(BuildContext context) {
    return HydraTouchTarget(
      semanticLabel: semanticLabel ?? tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        tooltip: tooltip,
        color: color,
        iconSize: iconSize,
        constraints: const BoxConstraints(
          minWidth: AppAccessibility.minTouchTarget,
          minHeight: AppAccessibility.minTouchTarget,
        ),
        padding: padding ?? EdgeInsets.zero,
        visualDensity: visualDensity,
        splashRadius: splashRadius,
      ),
    );
  }
}
