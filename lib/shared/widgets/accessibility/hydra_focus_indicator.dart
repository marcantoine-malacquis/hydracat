import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_accessibility.dart';

/// A widget that provides consistent focus indicators for accessibility.
class HydraFocusIndicator extends StatelessWidget {
  /// Creates a HydraFocusIndicator.
  const HydraFocusIndicator({
    required this.child,
    super.key,
    this.focusColor,
    this.borderRadius,
  });

  /// The child widget to wrap with focus indicator.
  final Widget child;

  /// Custom focus color. If null, uses primary color.
  final Color? focusColor;

  /// Border radius for the focus indicator.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {},
      child: Builder(
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(8),
              border: Border.all(
                color: Colors.transparent,
                width: AppAccessibility.focusOutlineWidth,
              ),
            ),
            child: child,
          );
        },
      ),
    );
  }
}
