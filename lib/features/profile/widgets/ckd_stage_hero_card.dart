import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/profile/models/medical_info.dart';

/// A hero card displaying the CKD/IRIS stage with a subtle teal gradient.
///
/// This card displays the current IRIS stage, which is automatically
/// updated when lab results are saved with an IRIS stage.
class CkdStageHeroCard extends StatelessWidget {
  /// Creates a [CkdStageHeroCard].
  const CkdStageHeroCard({
    required this.stage,
    super.key,
  });

  /// The current IRIS stage (null if not set)
  final IrisStage? stage;

  @override
  Widget build(BuildContext context) {
    final isEmpty = stage == null;
    final displayText = isEmpty ? 'No information' : stage!.displayName;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withValues(alpha: 0.06),
            AppColors.surface,
          ],
        ),
        borderRadius: CardConstants.cardBorderRadius,
        border: Border.all(
          color: CardConstants.cardBorderColor(context),
        ),
      ),
      child: Center(
        child: Text(
          displayText,
          textAlign: TextAlign.center,
          style: AppTextStyles.h3.copyWith(
            color: isEmpty ? AppColors.textTertiary : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }
}
