import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/shared/widgets/accessibility/hydra_touch_target.dart';

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
              child: TextFormField(
                initialValue: weight?.toStringAsFixed(2),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: isRequired ? null : 'Optional',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                onChanged: (value) {
                  if (value.isEmpty) {
                    onWeightChanged(null);
                  } else {
                    final parsedValue = double.tryParse(value);
                    onWeightChanged(parsedValue);
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Unit selector
            Expanded(
              flex: 2,
              child: _UnitToggle(
                selectedUnit: unit,
                onUnitChanged: onUnitChanged,
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

/// Internal unit toggle widget
class _UnitToggle extends StatelessWidget {
  const _UnitToggle({
    required this.selectedUnit,
    required this.onUnitChanged,
  });

  final String selectedUnit;
  final ValueChanged<String> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _UnitButton(
              label: 'kg',
              isSelected: selectedUnit == 'kg',
              onTap: () => onUnitChanged('kg'),
              isFirst: true,
            ),
          ),
          Expanded(
            child: _UnitButton(
              label: 'lbs',
              isSelected: selectedUnit == 'lbs',
              onTap: () => onUnitChanged('lbs'),
              isLast: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal unit button widget
class _UnitButton extends StatelessWidget {
  const _UnitButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return HydraTouchTarget(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(7) : Radius.zero,
              right: isLast ? const Radius.circular(7) : Radius.zero,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
