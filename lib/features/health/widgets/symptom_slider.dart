import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/shared/widgets/inputs/hydra_slider.dart';

/// Generic discrete slider for symptom inputs with N/A at the first position.
///
/// This widget wraps [HydraSlider] and provides:
/// - Index 0 => N/A (null value)
/// - Indices 1..N => entries from [options]
/// - A compact label row showing the current descriptor only
/// Creates a platform-adaptive symptom slider with N/A handling and
/// per-option descriptors.
class SymptomSlider<T> extends StatelessWidget {
  /// Creates a [SymptomSlider]
  const SymptomSlider({
    required this.label,
    required this.value,
    required this.options,
    required this.getLabel,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// Label displayed for the symptom (e.g. "Vomiting").
  final String label;

  /// Current value (null means N/A).
  final T? value;

  /// Ordered list of discrete options for indices 1..N.
  final List<T> options;

  /// Returns the user-facing label for a given option.
  final String Function(T) getLabel;

  /// Called when the value changes (null means N/A).
  final ValueChanged<T?> onChanged;

  /// Whether the slider is interactive.
  final bool enabled;

  int get _currentIndex {
    if (value == null) return 0;
    final idx = options.indexOf(value as T);
    if (idx < 0) return 0;
    return idx + 1;
  }

  T? _indexToValue(int index) {
    if (index <= 0) return null;
    if (index > options.length) return options.last;
    return options[index - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final index = _currentIndex;
    final sliderValue = index.toDouble();

    final descriptor = () {
      if (value == null) return 'N/A';
      final label = getLabel(value as T).trim();
      return label.isEmpty ? 'N/A' : label;
    }();

    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.primary.withValues(alpha: 0.2);

    return Row(
      children: [
        // Symptom name on the left, vertically centered
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTextStyles.body,
            softWrap: true,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Stacked descriptor and slider on the right
        Expanded(
          flex: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                descriptor,
                style: AppTextStyles.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                textAlign: TextAlign.center,
              ),
              AbsorbPointer(
                absorbing: !enabled,
                child: Opacity(
                  opacity: enabled ? 1 : 0.5,
                  child: Semantics(
                    label: label,
                    value: descriptor,
                    child: HydraSlider(
                      value: sliderValue,
                      max: options.length.toDouble(),
                      divisions: options.length,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onChanged: (double newValue) {
                        if (!enabled) return;
                        final rounded = newValue.round().clamp(
                          0,
                          options.length,
                        );
                        final newIndex = rounded;
                        final newValueMapped = _indexToValue(newIndex);
                        if (newValueMapped != value) {
                          onChanged(newValueMapped);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
