import 'package:flutter/material.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/qol/models/qol_assessment.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/shared/widgets/cards/hydra_card.dart';
import 'package:hydracat/shared/widgets/dialogs/hydra_alert_dialog.dart';

/// Displays a summary card with the overall QoL score.
///
/// Shows:
/// - Large circular score display (100px diameter)
/// - Score band label (Very Good, Good, Fair, Low)
/// - Low confidence badge if any domain has <50% answered
/// - Assessment date
/// - Completion indicator (X/14 questions answered)
class QolScoreSummaryCard extends StatelessWidget {
  /// Creates a QoL score summary card.
  const QolScoreSummaryCard({
    required this.assessment,
    super.key,
  });

  /// The assessment to display.
  final QolAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final overallScore = assessment.overallScore;
    final scoreBand = assessment.scoreBand;
    final hasLowConfidence = assessment.hasLowConfidenceDomain;
    final validDomainCount = assessment.domainScores.values
        .where((score) => score != null)
        .length;

    return HydraCard(
      child: Column(
        children: [
          // Large score circle
          _buildScoreCircle(overallScore, scoreBand),
          const SizedBox(height: AppSpacing.md),

          // Score band label
          if (scoreBand != null)
            Text(
              _getScoreBandLabel(l10n, scoreBand),
              style: AppTextStyles.h2.copyWith(
                color: _getScoreBandColor(scoreBand),
              ),
            ),

          // Low confidence badge
          if (hasLowConfidence) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildLowConfidenceBadge(context, validDomainCount),
          ],

          const SizedBox(height: AppSpacing.md),

          // Assessment date
          Text(
            l10n.qolAssessedOn(AppDateUtils.formatDate(assessment.date)),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          // Completion indicator
          if (!assessment.isComplete) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.qolQuestionsAnswered(
                assessment.answeredCount,
                14,
              ),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the large circular score display.
  Widget _buildScoreCircle(double? score, String? scoreBand) {
    final displayScore = score?.round() ?? 0;
    final color = _getScoreBandColor(scoreBand);

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(
          color: color,
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          displayScore.toString(),
          style: AppTextStyles.display.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 40,
          ),
        ),
      ),
    );
  }

  /// Builds the low confidence badge with tap handler.
  Widget _buildLowConfidenceBadge(BuildContext context, int validDomainCount) {
    final l10n = context.l10n;

    return InkWell(
      onTap: () => _showLowConfidenceExplanation(context),
      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          border: Border.all(
            color: AppColors.warning,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline,
              size: 16,
              color: AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              l10n.qolBasedOnDomains(validDomainCount),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows explanation dialog for low confidence score.
  void _showLowConfidenceExplanation(BuildContext context) {
    final l10n = context.l10n;

    showDialog<void>(
      context: context,
      builder: (context) => HydraAlertDialog(
        title: Text(l10n.info),
        content: Text(l10n.qolLowConfidenceExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  /// Gets the localized score band label.
  String _getScoreBandLabel(AppLocalizations l10n, String band) {
    switch (band) {
      case 'veryGood':
        return l10n.qolScoreBandVeryGood;
      case 'good':
        return l10n.qolScoreBandGood;
      case 'fair':
        return l10n.qolScoreBandFair;
      case 'low':
        return l10n.qolScoreBandLow;
      default:
        return band;
    }
  }

  /// Gets the color based on score band.
  Color _getScoreBandColor(String? band) {
    switch (band) {
      case 'veryGood':
        return AppColors.primary;
      case 'good':
        return AppColors.primary;
      case 'fair':
        return AppColors.warning;
      case 'low':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
