import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/profile/models/medical_info.dart';
import 'package:hydracat/shared/widgets/inputs/hydra_sliding_segmented_control.dart';

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
    final selectedSegment = _segmentFromStage(selectedStage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: HydraSlidingSegmentedControl<_IrisStageSegment>(
            value: selectedSegment,
            onChanged: (segment) => onStageChanged(_stageFromSegment(segment)),
            segments: const {
              _IrisStageSegment.stage1: Text('1'),
              _IrisStageSegment.stage2: Text('2'),
              _IrisStageSegment.stage3: Text('3'),
              _IrisStageSegment.stage4: Text('4'),
              _IrisStageSegment.unknown: Text('N/A'),
            },
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

  _IrisStageSegment _segmentFromStage(IrisStage? stage) {
    return switch (stage) {
      IrisStage.stage1 => _IrisStageSegment.stage1,
      IrisStage.stage2 => _IrisStageSegment.stage2,
      IrisStage.stage3 => _IrisStageSegment.stage3,
      IrisStage.stage4 => _IrisStageSegment.stage4,
      null => _IrisStageSegment.unknown,
    };
  }

  IrisStage? _stageFromSegment(_IrisStageSegment segment) {
    return switch (segment) {
      _IrisStageSegment.stage1 => IrisStage.stage1,
      _IrisStageSegment.stage2 => IrisStage.stage2,
      _IrisStageSegment.stage3 => IrisStage.stage3,
      _IrisStageSegment.stage4 => IrisStage.stage4,
      _IrisStageSegment.unknown => null,
    };
  }
}

enum _IrisStageSegment {
  stage1,
  stage2,
  stage3,
  stage4,
  unknown,
}
