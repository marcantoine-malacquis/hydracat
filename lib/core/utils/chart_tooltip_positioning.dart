import 'package:flutter/widgets.dart';

/// Utility class for calculating optimal tooltip positions in bar charts
///
/// Handles smart positioning that:
/// - Uses correct coordinate systems (container-relative)
/// - Avoids finger overlap during touch interactions
/// - Prevents overflow beyond container bounds
/// - Adapts to bar position (left/right side logic)
///
/// Example:
/// ```dart
/// final position = ChartTooltipPositioner.calculate(
///   touchPosition: event.localPosition,
///   containerWidth: chartWidth,
///   containerHeight: chartHeight,
///   barIndex: 3,
///   totalBars: 7,
/// );
///
/// return Positioned(
///   left: position.left,
///   right: position.right,
///   top: position.top,
///   child: Transform.scale(
///     alignment: position.scaleAlignment,
///     child: tooltip,
///   ),
/// );
/// ```
class ChartTooltipPositioner {
  /// Radius of typical finger touch zone (30px radius = ~60px diameter)
  ///
  /// iOS Human Interface Guidelines recommend 44pt minimum touch target
  /// Material Design recommends 48dp minimum touch target
  /// We use 30px radius (60px diameter) to provide comfortable clearance
  static const double fingerRadius = 30;

  /// Horizontal spacing between tooltip and touch point
  static const double horizontalSpacing = 8;

  /// Vertical clearance above finger touch zone
  ///
  /// Positions tooltip above the finger with comfortable reading distance
  static const double verticalClearance = 16;

  /// Minimum padding from top edge of container
  static const double minTopPadding = 8;

  /// Minimum padding from left/right edges of container
  static const double minSidePadding = 8;

  /// Maximum estimated tooltip width (used when actual size unknown)
  ///
  /// Prevents overflow on narrow screens. Actual tooltip may be smaller.
  static const double estimatedMaxTooltipWidth = 240;

  /// Estimated tooltip height for vertical positioning calculations
  static const double estimatedTooltipHeight = 120;

  /// Calculates optimal tooltip position within a chart container
  ///
  /// Parameters:
  /// - [touchPosition]: Touch coordinates relative to chart container (from
  ///   fl_chart's event.localPosition)
  /// - [containerWidth]: Width of the chart container (from LayoutBuilder
  ///   constraints)
  /// - [containerHeight]: Height of the chart container
  /// - [barIndex]: Index of the tapped bar (0-based)
  /// - [totalBars]: Total number of bars in the chart
  /// - [tooltipSize]: Optional actual tooltip size for precise positioning
  ///
  /// Returns [TooltipPosition] with left/right/top values and scale alignment
  static TooltipPosition calculate({
    required Offset touchPosition,
    required double containerWidth,
    required double containerHeight,
    required int barIndex,
    required int totalBars,
    Size? tooltipSize,
  }) {
    // Use actual tooltip size if provided, otherwise use estimates
    final tooltipWidth = tooltipSize?.width ?? estimatedMaxTooltipWidth;
    final tooltipHeight = tooltipSize?.height ?? estimatedTooltipHeight;

    // Determine horizontal positioning strategy based on bar position
    // Left half of bars → tooltip on right side
    // Right half of bars → tooltip on left side
    final showOnRight = barIndex < (totalBars / 2);

    // Calculate horizontal position with overflow protection
    final horizontalPosition = _calculateHorizontalPosition(
      touchPosition: touchPosition,
      containerWidth: containerWidth,
      tooltipWidth: tooltipWidth,
      showOnRight: showOnRight,
    );

    // Calculate vertical position with finger clearance and overflow protection
    final topPosition = _calculateVerticalPosition(
      touchPosition: touchPosition,
      containerHeight: containerHeight,
      tooltipHeight: tooltipHeight,
    );

    // Determine scale alignment for entrance animation
    final scaleAlignment = showOnRight
        ? Alignment.centerLeft // Grow from left edge when on right side
        : Alignment.centerRight; // Grow from right edge when on left side

    return TooltipPosition(
      top: topPosition,
      scaleAlignment: scaleAlignment,
      pointsLeft: showOnRight, // Arrow points toward bar
      left: horizontalPosition.left,
      right: horizontalPosition.right,
    );
  }

  /// Calculates horizontal position (left or right) with overflow prevention
  ///
  /// Returns either left OR right position (never both)
  static _HorizontalPosition _calculateHorizontalPosition({
    required Offset touchPosition,
    required double containerWidth,
    required double tooltipWidth,
    required bool showOnRight,
  }) {
    if (showOnRight) {
      // Position tooltip to the right of touch point
      final leftPosition = touchPosition.dx + horizontalSpacing;

      // Check if tooltip would overflow right edge
      final wouldOverflowRight =
          leftPosition + tooltipWidth > containerWidth - minSidePadding;

      if (wouldOverflowRight) {
        // Clamp to prevent overflow, ensuring minimum left padding
        final clampedLeft = (containerWidth - tooltipWidth - minSidePadding)
            .clamp(minSidePadding, containerWidth - minSidePadding);
        return _HorizontalPosition(left: clampedLeft);
      }

      return _HorizontalPosition(left: leftPosition);
    } else {
      // Position tooltip to the left of touch point (use 'right' positioning)
      final rightPosition =
          containerWidth - touchPosition.dx + horizontalSpacing;

      // Check if tooltip would overflow left edge
      final wouldOverflowLeft =
          rightPosition + tooltipWidth > containerWidth - minSidePadding;

      if (wouldOverflowLeft) {
        // Clamp to prevent overflow, ensuring minimum right padding
        final clampedRight = (containerWidth - tooltipWidth - minSidePadding)
            .clamp(minSidePadding, containerWidth - minSidePadding);
        return _HorizontalPosition(right: clampedRight);
      }

      return _HorizontalPosition(right: rightPosition);
    }
  }

  /// Calculates vertical position with finger clearance and overflow prevention
  ///
  /// Positions tooltip above the finger touch zone with comfortable clearance
  static double _calculateVerticalPosition({
    required Offset touchPosition,
    required double containerHeight,
    required double tooltipHeight,
  }) {
    // Position tooltip above finger touch zone with clearance
    // fingerRadius gives bottom of finger, verticalClearance adds space above
    final idealTop = touchPosition.dy - fingerRadius - verticalClearance;

    // Check if tooltip would overflow top edge
    if (idealTop < minTopPadding) {
      // Not enough space above: try positioning below finger
      final belowFingerTop =
          touchPosition.dy + fingerRadius + verticalClearance;

      // Check if tooltip fits below
      if (belowFingerTop + tooltipHeight <=
          containerHeight - minTopPadding) {
        return belowFingerTop;
      }

      // Doesn't fit above or below: clamp to top with minimum padding
      return minTopPadding;
    }

    // Check if tooltip would overflow bottom edge
    if (idealTop + tooltipHeight > containerHeight - minTopPadding) {
      // Shift up to fit within container
      return (containerHeight - tooltipHeight - minTopPadding)
          .clamp(minTopPadding, containerHeight - minTopPadding);
    }

    return idealTop;
  }
}

/// Calculated tooltip position with positioning values and animation alignment
class TooltipPosition {
  /// Creates a [TooltipPosition]
  const TooltipPosition({
    required this.top,
    required this.scaleAlignment,
    required this.pointsLeft,
    this.left,
    this.right,
  }) : assert(
          (left == null) != (right == null),
          'Exactly one of left or right must be non-null',
        );

  /// Left position in pixels (null if using right positioning)
  final double? left;

  /// Right position in pixels (null if using left positioning)
  final double? right;

  /// Top position in pixels
  final double top;

  /// Alignment for scale animation entrance effect
  ///
  /// - Alignment.centerLeft when tooltip is on right side (grows from left)
  /// - Alignment.centerRight when tooltip is on left side (grows from right)
  final Alignment scaleAlignment;

  /// Whether the tooltip arrow points left (tooltip appears on right side)
  final bool pointsLeft;
}

/// Internal helper for horizontal position calculation
class _HorizontalPosition {
  const _HorizontalPosition({this.left, this.right})
      : assert(
          (left == null) != (right == null),
          'Exactly one of left or right must be non-null',
        );

  final double? left;
  final double? right;
}
