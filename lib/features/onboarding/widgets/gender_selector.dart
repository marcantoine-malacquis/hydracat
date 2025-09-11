import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/shared/widgets/accessibility/hydra_touch_target.dart';

/// A gender selection widget with toggle buttons for male/female selection
class GenderSelector extends StatelessWidget {
  /// Creates a [GenderSelector]
  const GenderSelector({
    required this.selectedGender,
    required this.onGenderChanged,
    super.key,
    this.errorText,
  });

  /// Currently selected gender
  final String? selectedGender;

  /// Callback when gender selection changes
  final ValueChanged<String> onGenderChanged;

  /// Error text to display
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _GenderButton(
                label: 'Male',
                value: 'male',
                isSelected: selectedGender == 'male',
                onTap: () => onGenderChanged('male'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _GenderButton(
                label: 'Female',
                value: 'female',
                isSelected: selectedGender == 'female',
                onTap: () => onGenderChanged('female'),
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

/// Internal gender button widget
class _GenderButton extends StatelessWidget {
  const _GenderButton({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HydraTouchTarget(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          height: AppSpacing.minTouchTarget,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
