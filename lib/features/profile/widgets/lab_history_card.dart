import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/profile/models/lab_result.dart';
import 'package:intl/intl.dart';

/// A card widget for displaying a single lab result in history
///
/// Shows the test date and key analyte values (creatinine, BUN, SDMA)
/// in a compact, card-based layout with an edit button.
class LabHistoryCard extends StatelessWidget {
  /// Creates a [LabHistoryCard]
  const LabHistoryCard({
    required this.labResult,
    this.onTap,
    this.onEdit,
    super.key,
  });

  /// The lab result to display
  final LabResult labResult;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Callback when the edit button is pressed
  final VoidCallback? onEdit;

  /// Format date as "MMM d, yyyy" (e.g., "Jan 15, 2024")
  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Test date, metadata, and edit button
              Row(
                children: [
                  const Icon(
                    Icons.science_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _formatDate(labResult.testDate),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (labResult.metadata?.irisStage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Stage ${labResult.metadata!.irisStage}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  if (onEdit != null)
                    TextButton(
                      onPressed: onEdit,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.primary,
                      ),
                      child: Text(
                        'Edit',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Lab values grid
              Row(
                children: [
                  if (labResult.creatinine != null)
                    Expanded(
                      child: _buildValueColumn(
                        'Creatinine',
                        labResult.creatinine!.value,
                        labResult.creatinine!.unit,
                      ),
                    ),
                  if (labResult.bun != null)
                    Expanded(
                      child: _buildValueColumn(
                        'BUN',
                        labResult.bun!.value,
                        labResult.bun!.unit,
                      ),
                    ),
                  if (labResult.sdma != null)
                    Expanded(
                      child: _buildValueColumn(
                        'SDMA',
                        labResult.sdma!.value,
                        labResult.sdma!.unit,
                      ),
                    ),
                ],
              ),

              // Vet notes preview if available
              if (labResult.metadata?.vetNotes != null &&
                  labResult.metadata!.vetNotes!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.notes,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        labResult.metadata!.vetNotes!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build a column for displaying a single lab value
  Widget _buildValueColumn(String label, double value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textTertiary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
