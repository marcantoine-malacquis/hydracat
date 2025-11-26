import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/shared/widgets/inputs/hydra_sliding_segmented_control.dart';

/// Enum input widget using segmented control.
///
/// NOTE: This widget is kept for backward compatibility and potential
/// future reuse, but the main symptoms entry flow now uses `SymptomSlider`
/// for a more compact slider-based UX.
///
/// Used for diarrhea, constipation, appetite, injection site, and energy.
/// Supports an N/A toggle to indicate the symptom is not applicable.
class SymptomEnumInput<T extends Enum> extends StatelessWidget {
  /// Creates a [SymptomEnumInput]
  const SymptomEnumInput({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.getLabel,
    this.enabled = true,
    super.key,
  });

  /// Label text displayed above the input
  final String label;

  /// Current value (null means N/A)
  final T? value;

  /// Available enum options
  final List<T> options;

  /// Called when the value changes (null means N/A)
  final ValueChanged<T?> onChanged;

  /// Function to get display label for each enum value
  final String Function(T) getLabel;

  /// Whether the input is enabled
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTextStyles.body),
            const SizedBox(width: AppSpacing.sm),
            Checkbox(
              value: value != null,
              onChanged: enabled
                  ? (checked) => onChanged(
                      (checked ?? false) ? options.first : null,
                    )
                  : null,
            ),
            const Text(
              'N/A',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        if (value != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AbsorbPointer(
            absorbing: !enabled,
            child: Opacity(
              opacity: enabled ? 1.0 : 0.5,
              child: HydraSlidingSegmentedControl<T>(
                value: value!,
                segments: Map.fromEntries(
                  options.map(
                    (option) => MapEntry(
                      option,
                      Text(
                        getLabel(option),
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ),
                ),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
