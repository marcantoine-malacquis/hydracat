import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/onboarding/widgets/rotating_wheel_picker.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Bottom sheet for editing fluid schedule preferred administration location
class LocationEditBottomSheet extends StatefulWidget {
  /// Creates a [LocationEditBottomSheet]
  const LocationEditBottomSheet({
    this.initialValue,
    super.key,
  });

  /// Initial location value (null if not set)
  final FluidLocation? initialValue;

  @override
  State<LocationEditBottomSheet> createState() =>
      _LocationEditBottomSheetState();
}

class _LocationEditBottomSheetState extends State<LocationEditBottomSheet> {
  late FluidLocation _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation =
        widget.initialValue ?? FluidLocation.shoulderBladeMiddle;
  }

  void _save() {
    Navigator.of(context).pop(_selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    final isCupertino = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return LoggingPopupWrapper(
      title: 'Edit Location',
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
            child: RotatingWheelPicker<FluidLocation>(
              items: FluidLocation.values,
              initialIndex: FluidLocation.values.indexOf(
                _selectedLocation,
              ),
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedLocation = FluidLocation.values[index];
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
