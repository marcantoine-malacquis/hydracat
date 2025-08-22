import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/app_layout.dart';

/// A responsive wrapper that provides consistent padding and max width
/// for content across different screen sizes.
class LayoutWrapper extends StatelessWidget {
  /// Creates a layout wrapper with optional customization.
  const LayoutWrapper({
    required this.child,
    super.key,
    this.padding,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  /// The child widget to wrap.
  final Widget child;

  /// Optional custom padding. If null, uses responsive padding.
  final EdgeInsetsGeometry? padding;

  /// Optional maximum width constraint.
  final double? maxWidth;

  /// Alignment of the content within the wrapper.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final responsivePadding = AppLayout.getResponsivePadding(
          constraints.maxWidth,
        );
        final finalPadding = padding ?? EdgeInsets.all(responsivePadding);
        final finalMaxWidth = maxWidth ?? AppLayout.maxContentWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: finalMaxWidth),
            child: Padding(
              padding: finalPadding,
              child: Align(
                alignment: alignment,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
