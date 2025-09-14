import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/profile/models/medical_info.dart';

/// Widget for selecting IRIS stage with horizontal button layout
class IrisStageSelector extends StatelessWidget {
  /// Creates an [IrisStageSelector]
  const IrisStageSelector({
    required this.selectedStage,
    required this.onStageChanged,
    super.key,
    this.errorText,
    this.hasUserSelected = false,
  });

  /// Currently selected IRIS stage
  final IrisStage? selectedStage;

  /// Callback when stage selection changes
  final ValueChanged<IrisStage?> onStageChanged;

  /// Optional error text to display
  final String? errorText;

  /// Whether the user has made any selection (to distinguish between
  /// no selection and Unknown selected)
  final bool hasUserSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stage selection buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStageButton(
                context,
                stage: IrisStage.stage1,
                label: '1',
                isFirst: true,
              ),
              _buildStageButton(
                context,
                stage: IrisStage.stage2,
                label: '2',
              ),
              _buildStageButton(
                context,
                stage: IrisStage.stage3,
                label: '3',
              ),
              _buildStageButton(
                context,
                stage: IrisStage.stage4,
                label: '4',
              ),
              _buildStageButton(
                context,
                stage: null,
                label: 'Unknown',
                isUnknown: true,
                isLast: true,
              ),
            ],
          ),
        ),

        // Selected stage description
        if (selectedStage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedStage!.displayName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  selectedStage!.description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ] else if (selectedStage == null && hasUserSelected) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              "That's okay! You can add this information later when "
              "you have your pet's most recent results.",
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],

        // Error text
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

  /// Build individual stage selection button
  Widget _buildStageButton(
    BuildContext context, {
    required IrisStage? stage,
    required String label,
    bool isFirst = false,
    bool isLast = false,
    bool isUnknown = false,
  }) {
    // Only select the button if it matches the selectedStage exactly
    // For the "Unknown" button (stage == null), only select if user
    //has made a selection
    final isSelected =
        stage == selectedStage && (stage != null || hasUserSelected);

    return Padding(
      padding: EdgeInsets.only(
        right: isLast ? 0 : AppSpacing.sm,
      ),
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: () => onStageChanged(stage),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? (isUnknown ? AppColors.textSecondary : AppColors.primary)
                : AppColors.surface,
            foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
            elevation: isSelected ? 2 : 0,
            side: BorderSide(
              color: isSelected
                  ? (isUnknown ? AppColors.textSecondary : AppColors.primary)
                  : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isUnknown ? AppSpacing.lg : AppSpacing.md,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
