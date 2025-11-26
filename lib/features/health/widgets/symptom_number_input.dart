import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';

/// Number input widget for vomiting episodes.
///
/// NOTE: This widget is kept for backward compatibility and potential
/// future reuse, but the main symptoms entry flow now uses [SymptomSlider]
/// for a more compact slider-based UX.
///
/// Allows users to enter 0-10+ episodes with +/- buttons and direct input.
/// Supports an N/A toggle to indicate the symptom is not applicable.
class SymptomNumberInput extends StatelessWidget {
  /// Creates a [SymptomNumberInput]
  const SymptomNumberInput({
    required this.label,
    required this.value,
    required this.onChanged,
    this.minValue = 0,
    this.maxValue = 99,
    this.enabled = true,
    super.key,
  });

  /// Label text displayed above the input
  final String label;

  /// Current value (null means N/A)
  final int? value;

  /// Called when the value changes (null means N/A)
  final ValueChanged<int?> onChanged;

  /// Minimum allowed value (default: 0)
  final int minValue;

  /// Maximum allowed value (default: 99)
  final int maxValue;

  /// Whether the input is enabled
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            // N/A checkbox
            Checkbox(
              value: value != null,
              onChanged: enabled
                  ? (checked) => onChanged((checked ?? false) ? 0 : null)
                  : null,
            ),
            const Text(
              'N/A',
              style: AppTextStyles.caption,
            ),
            const SizedBox(width: AppSpacing.md),
            if (value != null) ...[
              // Decrement button
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: enabled && value! > minValue
                    ? () => onChanged(value! - 1)
                    : null,
                tooltip: 'Decrease',
              ),
              // Value display and input
              SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: value.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  enabled: enabled,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                  ),
                  style: AppTextStyles.body,
                  onChanged: (text) {
                    final parsed = int.tryParse(text);
                    if (parsed != null &&
                        parsed >= minValue &&
                        parsed <= maxValue) {
                      onChanged(parsed);
                    }
                  },
                ),
              ),
              // Increment button
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: enabled && value! < maxValue
                    ? () => onChanged(value! + 1)
                    : null,
                tooltip: 'Increase',
              ),
              const SizedBox(width: AppSpacing.xs),
              const Text(
                'episodes',
                style: AppTextStyles.caption,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
