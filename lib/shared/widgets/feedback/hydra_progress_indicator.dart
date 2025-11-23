import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Type of progress indicator to display.
enum HydraProgressIndicatorType {
  /// Circular progress indicator (spinner).
  circular,

  /// Linear progress indicator (progress bar).
  linear,
}

/// Platform-adaptive progress indicator for HydraCat.
///
/// Wraps [CircularProgressIndicator] and [LinearProgressIndicator] on Material
/// platforms, and [CupertinoActivityIndicator] on iOS/macOS.
///
/// On iOS/macOS, both circular and linear types display as
/// [CupertinoActivityIndicator] since there is no native linear equivalent.
/// Note: [CupertinoActivityIndicator] doesn't support determinate progress,
/// so the [value] parameter is ignored on iOS/macOS and the indicator
/// always displays as indeterminate.
///
/// Example:
/// ```dart
/// // Indeterminate circular indicator
/// HydraProgressIndicator()
///
/// // Determinate circular indicator
/// HydraProgressIndicator(
///   type: HydraProgressIndicatorType.circular,
///   value: 0.5,
/// )
///
/// // Linear progress bar
/// HydraProgressIndicator(
///   type: HydraProgressIndicatorType.linear,
///   value: 0.75,
///   minHeight: 8,
/// )
/// ```
class HydraProgressIndicator extends StatelessWidget {
  /// Creates a platform-adaptive progress indicator.
  ///
  /// The [type] defaults to [HydraProgressIndicatorType.circular].
  /// If [value] is null, the indicator is indeterminate (spinning/animating).
  /// If [value] is provided (0.0 to 1.0), the indicator shows
  /// determinate progress.
  const HydraProgressIndicator({
    this.type = HydraProgressIndicatorType.circular,
    this.value,
    this.backgroundColor,
    this.color,
    this.strokeWidth,
    this.minHeight,
    this.semanticsLabel,
    this.semanticsValue,
    super.key,
  });

  /// Type of progress indicator to display.
  final HydraProgressIndicatorType type;

  /// Progress value between 0.0 and 1.0, or null for indeterminate.
  final double? value;

  /// Background color of the progress indicator.
  ///
  /// For circular indicators, this is the color of the track.
  /// For linear indicators, this is the background color of the progress bar.
  /// Ignored on iOS/macOS (CupertinoActivityIndicator doesn't support it).
  final Color? backgroundColor;

  /// Color of the progress indicator.
  ///
  /// For circular indicators, this is the color of the progress arc.
  /// For linear indicators, this is the color of the progress bar.
  /// On iOS/macOS, this maps to the [CupertinoActivityIndicator] color.
  final Color? color;

  /// Width of the stroke for circular indicators.
  ///
  /// Only applies to circular indicators. Ignored for linear indicators
  /// and on iOS/macOS.
  final double? strokeWidth;

  /// Minimum height for linear indicators.
  ///
  /// Only applies to linear indicators. Ignored for circular indicators
  /// and on iOS/macOS.
  final double? minHeight;

  /// Semantic label for accessibility.
  final String? semanticsLabel;

  /// Semantic value for accessibility.
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return _buildCupertinoIndicator(context);
    }

    return _buildMaterialIndicator(context);
  }

  Widget _buildMaterialIndicator(BuildContext context) {
    switch (type) {
      case HydraProgressIndicatorType.circular:
        return CircularProgressIndicator(
          value: value,
          backgroundColor: backgroundColor,
          color: color,
          strokeWidth: strokeWidth ?? 4.0,
          semanticsLabel: semanticsLabel,
          semanticsValue: semanticsValue,
        );
      case HydraProgressIndicatorType.linear:
        return LinearProgressIndicator(
          value: value,
          backgroundColor: backgroundColor,
          color: color,
          minHeight: minHeight,
          semanticsLabel: semanticsLabel,
          semanticsValue: semanticsValue,
        );
    }
  }

  Widget _buildCupertinoIndicator(BuildContext context) {
    // CupertinoActivityIndicator only supports circular indicators.
    // For linear type, we still show a circular indicator for
    // API compatibility.
    // Note: CupertinoActivityIndicator doesn't support determinate progress
    // (value parameter), so we always show an indeterminate spinner.
    // Properties like backgroundColor, strokeWidth, and minHeight are ignored.
    final resolvedColor = color ?? CupertinoTheme.of(context).primaryColor;

    return CupertinoActivityIndicator(
      color: resolvedColor,
    );
  }
}
