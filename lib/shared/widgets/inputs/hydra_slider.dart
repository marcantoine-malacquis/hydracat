import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Platform-adaptive slider for HydraCat.
///
/// Wraps [Slider] on Material platforms and [CupertinoSlider] on iOS/macOS,
/// while mirroring the core [Slider] API used in the app.
class HydraSlider extends StatelessWidget {
  /// Creates a platform-adaptive slider.
  ///
  /// The [value] parameter is required and must be between [min] and [max].
  /// The [onChanged] callback is called when the user drags the slider.
  const HydraSlider({
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.onChangeStart,
    this.onChangeEnd,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Current slider value.
  final double value;

  /// Minimum slider value.
  final double min;

  /// Maximum slider value.
  final double max;

  /// Number of discrete divisions.
  final int? divisions;

  /// Called when the user drags the slider.
  final ValueChanged<double> onChanged;

  /// Color of the active portion of the slider track.
  final Color? activeColor;

  /// Color of the inactive portion of the slider track.
  final Color? inactiveColor;

  /// Color of the slider thumb.
  final Color? thumbColor;

  /// Called when the user starts interacting with the slider.
  final ValueChanged<double>? onChangeStart;

  /// Called when the user stops interacting with the slider.
  final ValueChanged<double>? onChangeEnd;

  /// Optional focus node.
  final FocusNode? focusNode;

  /// Whether this slider should be focused initially.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return _buildCupertinoSlider(context);
    }

    return _buildMaterialSlider(context);
  }

  Widget _buildMaterialSlider(BuildContext context) {
    return Slider(
      value: value.clamp(min, max),
      min: min,
      max: max,
      divisions: divisions,
      onChanged: onChanged,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      thumbColor: thumbColor,
      focusNode: focusNode,
      autofocus: autofocus,
    );
  }

  Widget _buildCupertinoSlider(BuildContext context) {
    // CupertinoSlider does not support inactiveColor, thumbColor, or callbacks
    // for onChangeStart/onChangeEnd. We pass through what is supported and let
    // CupertinoTheme handle the rest.
    final resolvedActiveColor =
        activeColor ?? CupertinoTheme.of(context).primaryColor;
    final resolvedThumbColor = thumbColor ?? resolvedActiveColor;

    return CupertinoSlider(
      value: value.clamp(min, max),
      min: min,
      max: max,
      divisions: divisions,
      onChanged: onChanged,
      activeColor: resolvedActiveColor,
      thumbColor: resolvedThumbColor,
    );
  }
}
