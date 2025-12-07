import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/profile/models/lab_result.dart';
import 'package:hydracat/features/profile/widgets/lab_history_card.dart';
import 'package:hydracat/features/profile/widgets/lab_result_detail_popup.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// A section widget for displaying lab results history
///
/// Shows a list of past lab results with the most recent at the top.
/// Handles empty state when no lab results are available.
class LabHistorySection extends ConsumerWidget {
  /// Creates a [LabHistorySection]
  const LabHistorySection({
    this.onUpdateLabResult,
    this.onDeleteLabResult,
    super.key,
  });

  /// Callback when a lab result is updated (receives the updated LabResult)
  final void Function(LabResult)? onUpdateLabResult;

  /// Callback when a lab result is deleted (receives the deleted LabResult)
  final void Function(LabResult)? onDeleteLabResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labResults = ref.watch(labResultsHistoryProvider);
    final isLoading = ref.watch(labResultsIsLoadingProvider);
    final hasLabResults = ref.watch(hasLabResultsHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with title
        Text(
          'Lab Results History',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Loading state
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: CircularProgressIndicator(),
            ),
          )
        // Empty state
        else if (!hasLabResults)
          _buildEmptyState(context)
        // Lab results list
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: labResults!.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final labResult = labResults[index];
              return LabHistoryCard(
                labResult: labResult,
                onTap: () => _showLabResultDetail(context, labResult, ref),
              );
            },
          ),
      ],
    );
  }

  /// Show detailed lab result view with gauges
  Future<void> _showLabResultDetail(
    BuildContext context,
    LabResult labResult,
    WidgetRef ref,
  ) async {
    await showHydraBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => HydraBottomSheet(
        child: LabResultDetailPopup(
          labResult: labResult,
          onUpdate: onUpdateLabResult,
          onDelete: onDeleteLabResult,
        ),
      ),
    );
  }

  /// Build the empty state when no lab results are available
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.science_outlined,
            size: 48,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No Previous Lab Results',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Previous lab results will appear here as you add more '
            'bloodwork data over time to track your '
            "cat's kidney health progress",
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
