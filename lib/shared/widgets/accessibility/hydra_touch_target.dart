import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_accessibility.dart';

/// A widget that ensures minimum touch target size for accessibility.
class HydraTouchTarget extends StatelessWidget {
  /// Creates a HydraTouchTarget.
  const HydraTouchTarget({
    required this.child,
    super.key,
    this.minSize = AppAccessibility.minTouchTarget,
    this.alignment = Alignment.center,
  });

  /// The child widget to wrap with touch target.
  final Widget child;

  /// Minimum size for the touch target.
  final double minSize;

  /// Alignment of the child within the touch target.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: Align(
        alignment: alignment,
        child: child,
      ),
    );
  }
}
