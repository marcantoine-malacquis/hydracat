import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/profile/models/lab_result.dart';
import 'package:hydracat/features/profile/widgets/lab_history_card.dart';
import 'package:hydracat/providers/profile_provider.dart';

/// A section widget for displaying lab results history
///
/// Shows a list of past lab results with the most recent at the top.
/// Handles empty state when no lab results are available.
class LabHistorySection extends ConsumerWidget {
  /// Creates a [LabHistorySection]
  const LabHistorySection({
    this.onEditLabResult,
    super.key,
  });

  /// Callback when a lab result is edited (receives the LabResult to edit)
  final void Function(LabResult)? onEditLabResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labResults = ref.watch(labResultsProvider);
    final isLoading = ref.watch(labResultsIsLoadingProvider);
    final hasLabResults = ref.watch(hasLabResultsProvider);

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
                onTap: () {
                  // TODO(lab-detail): Navigate to detailed lab result view
                  // For now, we'll just display it in the card
                },
                onEdit: onEditLabResult != null
                    ? () => onEditLabResult!(labResult)
                    : null,
              );
            },
          ),
      ],
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
            'No Lab Results Yet',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Add your first lab result using the '+ Add' button above "
            "to track your cat's kidney health over time",
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
