import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';

/// Platform-adaptive switch for HydraCat.
///
/// Wraps [Switch] on Material platforms and [CupertinoSwitch] on iOS/macOS,
/// while mirroring the core [Switch] API used in the app.
class HydraSwitch extends StatelessWidget {
  /// Creates a platform-adaptive switch.
  ///
  /// The [value] parameter is required and indicates whether the switch is
  /// on or off.
  /// The [onChanged] callback is called when the user toggles the switch.
  const HydraSwitch({
    required this.value,
    this.onChanged,
    this.activeColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.thumbColor,
    this.trackColor,
    this.trackOutlineColor,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Whether the switch is on or off.
  final bool value;

  /// Called when the user toggles the switch.
  final ValueChanged<bool>? onChanged;

  /// Color of the switch when it is on.
  final Color? activeColor;

  /// Color of the thumb when the switch is off (Material only).
  final Color? inactiveThumbColor;

  /// Color of the track when the switch is off (Material only).
  final Color? inactiveTrackColor;

  /// Color of the switch thumb.
  final Color? thumbColor;

  /// Color of the switch track when it is on (Material only).
  final Color? trackColor;

  /// Color of the switch track outline (Material only).
  final Color? trackOutlineColor;

  /// Optional focus node.
  final FocusNode? focusNode;

  /// Whether this switch should be focused initially.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return _buildCupertinoSwitch(context);
    }

    return _buildMaterialSwitch(context);
  }

  Widget _buildMaterialSwitch(BuildContext context) {
    // Use app-specific colors for Material design to match iOS color coherence
    // ON state: teal background (AppColors.primary) with white thumb
    // OFF state: light gray background (AppColors.disabled) with white thumb
    final resolvedActiveColor = activeColor ?? AppColors.primary;
    final resolvedThumbColor = thumbColor ?? AppColors.surface;

    // Build track color: teal when ON, light gray when OFF
    final resolvedTrackColor = trackColor != null
        ? WidgetStateProperty.all(trackColor)
        : WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return AppColors.disabled;
              }
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary;
              }
              return AppColors.disabled; // OFF state - matches iOS intent
            },
          );

    return Switch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: resolvedActiveColor,
      activeThumbColor: resolvedThumbColor,
      inactiveThumbColor: inactiveThumbColor ?? resolvedThumbColor,
      inactiveTrackColor: inactiveTrackColor ?? AppColors.disabled,
      thumbColor: thumbColor != null
          ? WidgetStateProperty.all(thumbColor)
          : WidgetStateProperty.all(resolvedThumbColor),
      trackColor: resolvedTrackColor,
      trackOutlineColor: trackOutlineColor != null
          ? WidgetStateProperty.all(trackOutlineColor)
          : null,
      focusNode: focusNode,
      autofocus: autofocus,
    );
  }

  Widget _buildCupertinoSwitch(BuildContext context) {
    // CupertinoSwitch does not support inactiveThumbColor, inactiveTrackColor,
    // trackColor, trackOutlineColor, focusNode, or autofocus. We pass through
    // what is supported and use app-specific colors for iOS design.
    // ON state: light teal background (AppColors.primary) with white thumb
    // OFF state: light gray background (AppColors.disabled) with white thumb
    final resolvedActiveColor = activeColor ?? AppColors.primary;
    final resolvedThumbColor = thumbColor ?? AppColors.surface;

    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: resolvedActiveColor,
      thumbColor: resolvedThumbColor,
    );
  }
}
