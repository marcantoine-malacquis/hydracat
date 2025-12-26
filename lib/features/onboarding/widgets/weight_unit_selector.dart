import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/core/utils/number_input_utils.dart';
import 'package:hydracat/shared/widgets/widgets.dart';


/// Weight input widget with unit selection (kg/lbs) and preference storage
class WeightUnitSelector extends StatelessWidget {
  /// Creates a [WeightUnitSelector]
  const WeightUnitSelector({
    required this.weight,
    required this.unit,
    required this.onWeightChanged,
    required this.onUnitChanged,
    super.key,
    this.errorText,
    this.isRequired = false,
  });

  /// Current weight value
  final double? weight;

  /// Current unit ('kg' or 'lbs')
  final String unit;

  /// Callback when weight value changes
  final ValueChanged<double?> onWeightChanged;

  /// Callback when unit selection changes
  final ValueChanged<String> onUnitChanged;

  /// Error text to display
  final String? errorText;

  /// Whether this field is required
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Weight input field
            Expanded(
              flex: 3,
              child: HydraTextFormField(
                initialValue: weight?.toStringAsFixed(2),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: NumberInputUtils.getDecimalFormatters(),
                decoration: InputDecoration(
                  hintText: isRequired ? null : 'Optional',
                  border: OutlineInputBorder(
                    borderRadius: AppBorderRadius.inputRadius,
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppBorderRadius.inputRadius,
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppBorderRadius.inputRadius,
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: AppBorderRadius.inputRadius,
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
                onChanged: (value) {
                  final parsedValue = NumberInputUtils.parseDecimal(value);
                  onWeightChanged(parsedValue);
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Unit selector
            Expanded(
              flex: 2,
              child: HydraSlidingSegmentedControl<String>(
                segments: const {
                  'kg': Text('kg'),
                  'lbs': Text('lbs'),
                },
                value: unit,
                onChanged: onUnitChanged,
                height: 44,
              ),
            ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorText!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}
