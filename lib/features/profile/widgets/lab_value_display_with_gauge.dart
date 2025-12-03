import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/constants.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// A specialized widget for displaying lab values with a visual gauge.
///
/// This widget matches the layout of veterinary bloodwork reports, showing:
/// - Lab value name (e.g., "Creatinine")
/// - Reference range (e.g., "0.6 - 1.6 mg/dL")
/// - Measured value (e.g., "4.8 mg/dL")
/// - Visual gauge showing value position relative to reference range
/// - Edit button for updating the value
///
/// The gauge provides an at-a-glance visualization of whether the value
/// falls within the normal reference range using color coding:
/// - Dark teal: Value is within normal range
/// - Red: Value is outside normal range
///
/// **Example**:
/// ```dart
/// LabValueDisplayWithGauge(
///   label: 'Creatinine',
///   value: 4.8,
///   referenceRange: creatinineRange,
///   onEdit: () { /* handle edit */ },
/// )
/// ```
class LabValueDisplayWithGauge extends StatelessWidget {
  /// Creates a [LabValueDisplayWithGauge].
  const LabValueDisplayWithGauge({
    required this.label,
    required this.value,
    required this.referenceRange,
    required this.onEdit,
    super.key,
  });

  /// The lab value name (e.g., "Creatinine", "BUN", "SDMA").
  final String label;

  /// The measured value. If null, shows "No information" and no gauge.
  final double? value;

  /// The reference range object containing min, max, and unit.
  final LabReferenceRange referenceRange;

  /// Callback when the edit button is pressed.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First row: Label, reference range, and edit button
          Row(
            children: [
              // Label
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Reference range
              Expanded(
                child: Text(
                  referenceRange.getDisplayRange(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ),

              // Edit button
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  tooltip: 'Edit $label',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Second row: Gauge and actual value
          Row(
            children: [
              // Gauge (only shown when value exists)
              if (hasValue)
                Expanded(
                  child: HydraGauge(
                    value: value!,
                    min: referenceRange.min,
                    max: referenceRange.max,
                    unit: referenceRange.unit,
                  ),
                )
              else
                Expanded(
                  child: Text(
                    'No information',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ),

              const SizedBox(width: AppSpacing.md),

              // Value display
              if (hasValue)
                Text(
                  '${value!.toStringAsFixed(1)} ${referenceRange.unit}',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
