import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';

/// Platform-adaptive sliding segmented control for HydraCat.
///
/// Wraps [CupertinoSlidingSegmentedControl] on iOS/macOS and uses a custom
/// Material segmented control with a sliding selection pill on other platforms.
///
/// The generic type parameter [T] represents the type of value for
/// each segment.
/// It must be a non-nullable object type.
class HydraSlidingSegmentedControl<T extends Object> extends StatelessWidget {
  /// Creates a platform-adaptive sliding segmented control.
  ///
  /// The [segments] map defines the available options, where keys are the
  /// segment values and values are the label widgets to display.
  /// The [value] parameter indicates the currently selected segment.
  /// The [onChanged] callback is called when the user selects a different
  /// segment.
  const HydraSlidingSegmentedControl({
    required this.segments,
    required this.value,
    required this.onChanged,
    this.height = 36,
    this.segmentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.elevation = 0,
    super.key,
  });

  /// Map of segment values to their label widgets.
  final Map<T, Widget> segments;

  /// Currently selected value.
  final T value;

  /// Called when the selection changes.
  final ValueChanged<T> onChanged;

  /// Overall control height.
  final double height;

  /// Padding applied inside each segment around its label.
  final EdgeInsetsGeometry segmentPadding;

  /// Background color of the control.
  final Color? backgroundColor;

  /// Background color of the selected segment.
  final Color? selectedColor;

  /// Text color for unselected segments (Material only).
  final Color? unselectedColor;

  /// Border radius applied to the control and pill.
  final BorderRadius borderRadius;

  /// Shadow elevation for the Material pill.
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return _buildCupertino(context);
    }

    return _buildMaterial(context);
  }

  Widget _buildCupertino(BuildContext context) {
    final resolvedBackground =
        backgroundColor ?? CupertinoTheme.of(context).barBackgroundColor;
    final resolvedSelectedColor =
        selectedColor ?? AppColors.primaryLight;

    return CupertinoSlidingSegmentedControl<T>(
      groupValue: value,
      backgroundColor: resolvedBackground,
      thumbColor: resolvedSelectedColor,
      children: segments.map(
        (key, child) => MapEntry<T, Widget>(
          key,
          Padding(
            padding: segmentPadding,
            child: DefaultTextStyle.merge(
              style: AppTextStyles.buttonSecondary.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
      onValueChanged: (T? newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }

  Widget _buildMaterial(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keys = segments.keys.toList(growable: false);
    final selectedIndex = keys.indexOf(value);

    final resolvedBackground =
        backgroundColor ?? (isDark ? Colors.grey[900] : Colors.grey[100]);
    final resolvedSelectedColor = selectedColor ?? AppColors.primaryLight;
    final resolvedUnselectedColor = unselectedColor ?? AppColors.textSecondary;

    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / keys.length;

          return Stack(
            children: [
              // Sliding pill
              AnimatedPositioned(
                left: segmentWidth * selectedIndex,
                top: 0,
                bottom: 0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: Container(
                  width: segmentWidth,
                  decoration: BoxDecoration(
                    color: resolvedSelectedColor,
                    borderRadius: borderRadius.subtract(
                      const BorderRadius.all(Radius.circular(3)),
                    ),
                    boxShadow: elevation > 0
                        ? [
                            BoxShadow(
                              color: resolvedSelectedColor.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              // Labels / taps
              Row(
                children: keys.map((key) {
                  final index = keys.indexOf(key);
                  final isSelected = index == selectedIndex;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(key),
                      child: Padding(
                        padding: segmentPadding,
                        child: Center(
                          child: DefaultTextStyle.merge(
                            style: AppTextStyles.buttonSecondary.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : resolvedUnselectedColor,
                            ),
                            child: segments[key]!,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
