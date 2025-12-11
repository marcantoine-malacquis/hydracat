import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/constants.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/features/profile/models/lab_measurement.dart';
import 'package:hydracat/features/profile/models/lab_result.dart';
import 'package:hydracat/features/profile/widgets/lab_value_display_with_gauge.dart';
import 'package:hydracat/features/profile/widgets/lab_values_entry_dialog.dart';
import 'package:hydracat/shared/widgets/widgets.dart';
import 'package:intl/intl.dart';

/// Bottom sheet popup showing detailed lab result with gauges.
///
/// Displays:
/// - Lab result date in header
/// - Gauges for each lab value (Creatinine, BUN, SDMA)
/// - Edit button to modify values
///
/// Uses slide animation to transition between view and edit modes.
class LabResultDetailPopup extends ConsumerStatefulWidget {
  /// Creates a lab result detail popup.
  const LabResultDetailPopup({
    required this.labResult,
    this.onUpdate,
    this.onDelete,
    super.key,
  });

  /// The lab result to display.
  final LabResult labResult;

  /// Callback when the lab result is updated.
  final void Function(LabResult)? onUpdate;

  /// Callback when the lab result is deleted.
  final void Function(LabResult)? onDelete;

  @override
  ConsumerState<LabResultDetailPopup> createState() =>
      _LabResultDetailPopupState();
}

class _LabResultDetailPopupState extends ConsumerState<LabResultDetailPopup> {
  late LabResult _currentLabResult;

  @override
  void initState() {
    super.initState();
    _currentLabResult = widget.labResult;
  }

  /// Format date as "MMM d, yyyy" (e.g., "Jan 15, 2024")
  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Handle delete button press from edit dialog
  Future<void> _handleDelete() async {
    // Close the detail popup
    if (mounted) {
      Navigator.of(context).pop();
    }

    // Notify parent to delete
    widget.onDelete?.call(_currentLabResult);
  }

  Future<void> _onEdit() async {
    // Show edit dialog with slide animation
    final result = await showHydraBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => HydraBottomSheet(
        child: LabValuesEntryDialog(
          existingResult: _currentLabResult,
          showBackButton: true,
          onDelete: _handleDelete,
        ),
      ),
    );

    if (result != null && mounted) {
      // Build updated values map
      final updatedValues = <String, LabMeasurement>{};

      if (result['creatinine'] != null) {
        updatedValues['creatinine'] = LabMeasurement(
          value: result['creatinine'] as double,
          unit: result['creatinineUnit'] as String,
        );
      }

      if (result['bun'] != null) {
        updatedValues['bun'] = LabMeasurement(
          value: result['bun'] as double,
          unit: result['bunUnit'] as String,
        );
      }

      if (result['sdma'] != null) {
        updatedValues['sdma'] = LabMeasurement(
          value: result['sdma'] as double,
          unit: result['sdmaUnit'] as String,
        );
      }

      // Update the lab result
      final updatedLabResult = _currentLabResult.copyWith(
        testDate: result['testDate'] as DateTime,
        values: updatedValues,
        metadata: result['vetNotes'] != null
            ? _currentLabResult.metadata?.copyWith(
                    vetNotes: result['vetNotes'] as String,
                  ) ??
                  LabResultMetadata(
                    vetNotes: result['vetNotes'] as String,
                  )
            : _currentLabResult.metadata,
        updatedAt: DateTime.now(),
      );

      setState(() {
        _currentLabResult = updatedLabResult;
      });

      // Notify parent
      widget.onUpdate?.call(updatedLabResult);
    }
  }

  Widget _buildDateSelector() {
    return Align(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  _formatDate(_currentLabResult.testDate),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditButton() {
    final isCupertino =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return TextButton(
      onPressed: _onEdit,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Edit',
        style: AppTextStyles.buttonPrimary.copyWith(
          fontWeight: isCupertino ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoggingPopupWrapper(
      title: 'Lab Result Detail',
      headerContent: _buildDateSelector(),
      trailing: _buildEditButton(),
      showCloseButton: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),

          // Creatinine gauge
          if (_currentLabResult.creatinine != null) ...[
            LabValueDisplayWithGauge(
              label: 'Creatinine',
              value: _currentLabResult.creatinine!.value,
              referenceRange: getLabReferenceRange(
                'creatinine',
                _currentLabResult.creatinine!.unit,
              ),
              unit: _currentLabResult.creatinine!.unit,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // BUN gauge
          if (_currentLabResult.bun != null) ...[
            LabValueDisplayWithGauge(
              label: 'BUN (Blood Urea Nitrogen)',
              value: _currentLabResult.bun!.value,
              referenceRange: getLabReferenceRange(
                'bun',
                _currentLabResult.bun!.unit,
              ),
              unit: _currentLabResult.bun!.unit,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // SDMA gauge
          if (_currentLabResult.sdma != null) ...[
            LabValueDisplayWithGauge(
              label: 'SDMA',
              value: _currentLabResult.sdma!.value,
              referenceRange: getLabReferenceRange(
                'sdma',
                _currentLabResult.sdma!.unit,
              ),
              unit: _currentLabResult.sdma!.unit,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Vet notes if available
          if (_currentLabResult.metadata?.vetNotes != null &&
              _currentLabResult.metadata!.vetNotes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notes,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Veterinarian Notes',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _currentLabResult.metadata!.vetNotes!,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
