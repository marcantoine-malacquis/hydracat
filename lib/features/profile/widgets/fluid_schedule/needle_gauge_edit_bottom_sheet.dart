import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Bottom sheet for editing fluid schedule needle gauge
class NeedleGaugeEditBottomSheet extends StatefulWidget {
  /// Creates a [NeedleGaugeEditBottomSheet]
  const NeedleGaugeEditBottomSheet({
    this.initialValue,
    super.key,
  });

  /// Initial needle gauge value (null if not set)
  final NeedleGauge? initialValue;

  @override
  State<NeedleGaugeEditBottomSheet> createState() =>
      _NeedleGaugeEditBottomSheetState();
}

class _NeedleGaugeEditBottomSheetState
    extends State<NeedleGaugeEditBottomSheet> {
  late NeedleGauge _selectedGauge;

  @override
  void initState() {
    super.initState();
    _selectedGauge = widget.initialValue ?? NeedleGauge.gauge20;
  }

  void _save() {
    Navigator.of(context).pop(_selectedGauge);
  }

  @override
  Widget build(BuildContext context) {
    final isCupertino =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return LoggingPopupWrapper(
      title: 'Edit Needle Gauge',
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: HydraSlidingSegmentedControl<NeedleGauge>(
          value: _selectedGauge,
          onChanged: (value) {
            setState(() {
              _selectedGauge = value;
            });
          },
          segments: {
            NeedleGauge.gauge18: Text(NeedleGauge.gauge18.displayName),
            NeedleGauge.gauge20: Text(NeedleGauge.gauge20.displayName),
            NeedleGauge.gauge22: Text(NeedleGauge.gauge22.displayName),
            NeedleGauge.gauge25: Text(NeedleGauge.gauge25.displayName),
          },
        ),
      ),
    );
  }
}
