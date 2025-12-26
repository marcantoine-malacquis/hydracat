import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// A gender selection widget with segmented control for male/female selection
class GenderSelector extends StatelessWidget {
  /// Creates a [GenderSelector]
  const GenderSelector({
    required this.selectedGender,
    required this.onGenderChanged,
    super.key,
    this.maleLabel = 'Male',
    this.femaleLabel = 'Female',
    this.errorText,
  });

  /// Currently selected gender
  final String? selectedGender;

  /// Callback when gender selection changes
  final ValueChanged<String> onGenderChanged;

  /// Label for male option
  final String maleLabel;

  /// Label for female option
  final String femaleLabel;

  /// Error text to display
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Center the segmented control with reasonable width
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 280, // Reasonable width for two options
            ),
            child: HydraSlidingSegmentedControl<String>(
              segments: {
                'male': Text(maleLabel),
                'female': Text(femaleLabel),
              },
              value: selectedGender ?? 'male',
              onChanged: onGenderChanged,
              height: 44, // Minimum touch target (WCAG AA)
              borderRadius: BorderRadius.circular(
                AppBorderRadius.button,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorText!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
