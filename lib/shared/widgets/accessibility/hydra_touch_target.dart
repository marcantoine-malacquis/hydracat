import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_accessibility.dart';

/// A widget that ensures minimum touch target size for accessibility.
///
/// This widget guarantees that interactive elements meet the minimum
/// touch target size of 44×44px as recommended by Apple HIG and
/// Material Design guidelines.
///
/// Example usage:
/// ```dart
/// HydraTouchTarget(
///   semanticLabel: 'Delete item',
///   child: IconButton(
///     icon: Icon(Icons.delete),
///     onPressed: () => deleteItem(),
///   ),
/// )
/// ```
class HydraTouchTarget extends StatelessWidget {
  /// Creates a HydraTouchTarget.
  const HydraTouchTarget({
    required this.child,
    super.key,
    this.minSize = AppAccessibility.minTouchTarget,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.excludeSemantics = false,
  });

  /// The child widget to wrap with touch target.
  final Widget child;

  /// Minimum size for the touch target.
  ///
  /// Defaults to [AppAccessibility.minTouchTarget] (44px).
  final double minSize;

  /// Alignment of the child within the touch target.
  final AlignmentGeometry alignment;

  /// Optional semantic label for screen readers.
  ///
  /// If provided, this will be used by assistive technologies
  /// to describe the purpose of the interactive element.
  final String? semanticLabel;

  /// Whether to exclude the child's semantics and only use [semanticLabel].
  ///
  /// Set to true if the child already has semantic labels that you want
  /// to override with [semanticLabel].
  final bool excludeSemantics;

  @override
  Widget build(BuildContext context) {
    Widget touchTarget = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: Align(
        alignment: alignment,
        child: child,
      ),
    );

    // Add semantic labeling if provided
    if (semanticLabel != null) {
      touchTarget = Semantics(
        label: semanticLabel,
        button: true,
        excludeSemantics: excludeSemantics,
        child: touchTarget,
      );
    }

    return touchTarget;
  }
}
