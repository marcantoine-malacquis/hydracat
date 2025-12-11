import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/onboarding/widgets/rotating_wheel_picker.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Bottom sheet for editing fluid schedule administration frequency
class FrequencyEditBottomSheet extends StatefulWidget {
  /// Creates a [FrequencyEditBottomSheet]
  const FrequencyEditBottomSheet({
    this.initialValue,
    super.key,
  });

  /// Initial frequency value (null if not set)
  final TreatmentFrequency? initialValue;

  @override
  State<FrequencyEditBottomSheet> createState() =>
      _FrequencyEditBottomSheetState();
}

class _FrequencyEditBottomSheetState extends State<FrequencyEditBottomSheet> {
  late TreatmentFrequency _selectedFrequency;

  @override
  void initState() {
    super.initState();
    _selectedFrequency =
        widget.initialValue ?? TreatmentFrequency.onceDaily;
  }

  void _save() {
    Navigator.of(context).pop(_selectedFrequency);
  }

  @override
  Widget build(BuildContext context) {
    final isCupertino = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return LoggingPopupWrapper(
      title: 'Edit Frequency',
      leading: HydraBackButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      trailing: TextButton(
        onPressed: _save,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Save',
          style: AppTextStyles.buttonPrimary.copyWith(
            fontWeight: isCupertino ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
      showCloseButton: false,
      onDismiss: () {
        // No special cleanup needed
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: RotatingWheelPicker<TreatmentFrequency>(
              items: TreatmentFrequency.values,
              initialIndex: TreatmentFrequency.values.indexOf(
                _selectedFrequency,
              ),
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedFrequency = TreatmentFrequency.values[index];
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
