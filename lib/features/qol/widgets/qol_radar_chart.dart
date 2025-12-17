import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/qol/models/qol_assessment.dart';
import 'package:hydracat/features/qol/models/qol_domain.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/shared/widgets/cards/hydra_card.dart';

/// Displays a radar chart visualization of QoL assessment domain scores.
///
/// Shows 5 domains (Vitality, Comfort, Emotional, Appetite, Treatment Burden)
/// on a 0-100 scale with visual indicators for low-confidence domains.
///
/// Low-confidence domains (<50% questions answered) are:
/// - Displayed as 0 on the chart
/// - Marked as "Insufficient data" in the legend
/// - Shown with gray color indicators
///
/// Note: fl_chart's RadarChart doesn't support per-point border styling,
/// so dotted lines for low-confidence domains aren't implementable without
/// custom painting.
///
/// Supports two variants:
/// - Full-size: 280px height, full domain names, legend
/// - Compact: 180px height, abbreviated names, no legend (for home screen)
class QolRadarChart extends StatelessWidget {
  /// Creates a QoL radar chart.
  const QolRadarChart({
    required this.assessment,
    super.key,
    this.isCompact = false,
  });

  /// The assessment to visualize.
  final QolAssessment assessment;

  /// Whether to use compact variant (for home screen).
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scores = assessment.domainScores;

    // Check if all scores are null (all "Not sure")
    final allNull = scores.values.every((score) => score == null);

    if (allNull) {
      return HydraCard(
        child: SizedBox(
          height: isCompact ? 180 : 280,
          child: Center(
            child: Text(
              l10n.qolInsufficientData,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return HydraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title (only for full-size)
          if (!isCompact) ...[
            Text(
              l10n.qolRadarChartTitle,
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Radar chart
          SizedBox(
            height: isCompact ? 180 : 280,
            child: _buildRadarChart(context, scores),
          ),

          // Legend (only for full-size)
          if (!isCompact) ...[
            const SizedBox(height: AppSpacing.md),
            _buildLegend(context, scores),
          ],
        ],
      ),
    );
  }

  /// Builds the radar chart.
  Widget _buildRadarChart(
    BuildContext context,
    Map<String, double?> scores,
  ) {
    final l10n = context.l10n;

    // Get domain names
    final domainLabels = QolDomain.all.map((domain) {
      if (isCompact) {
        return _getDomainShortName(l10n, domain);
      }
      return _getDomainFullName(l10n, domain);
    }).toList();

    // Convert scores to radar data (replace null with 0 for visualization)
    final dataEntries = QolDomain.all.map((domain) {
      final score = scores[domain] ?? 0.0;
      return score;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          radarBorderData: const BorderSide(
            color: AppColors.border,
          ),
          gridBorderData: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
          ),
          tickCount: 5, // 0, 25, 50, 75, 100
          ticksTextStyle: AppTextStyles.small.copyWith(
            color: AppColors.textTertiary,
          ),
          tickBorderData: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
          ),
          getTitle: (index, angle) {
            if (index >= domainLabels.length) {
              return const RadarChartTitle(text: '');
            }
            return RadarChartTitle(
              text: domainLabels[index],
              angle: angle,
            );
          },
          titleTextStyle: AppTextStyles.small.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          dataSets: [
            RadarDataSet(
              fillColor: AppColors.primary.withValues(alpha: 0.2),
              borderColor: AppColors.primary,
              borderWidth: 2,
              entryRadius: 3,
              dataEntries: dataEntries.map((value) {
                return RadarEntry(value: value);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the legend showing domain names and scores.
  Widget _buildLegend(
    BuildContext context,
    Map<String, double?> scores,
  ) {
    final l10n = context.l10n;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: QolDomain.all.map((domain) {
        final score = scores[domain];
        final displayName = _getDomainFullName(l10n, domain);
        final isLowConfidence = score == null;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLowConfidence
                    ? AppColors.textTertiary
                    : AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Domain name and score
            Text(
              isLowConfidence
                  ? '$displayName: ${l10n.qolInsufficientData}'
                  : '$displayName: ${score.round()}',
              style: AppTextStyles.caption.copyWith(
                color: isLowConfidence
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  /// Gets the full domain name from localization.
  String _getDomainFullName(AppLocalizations l10n, String domain) {
    switch (domain) {
      case QolDomain.vitality:
        return l10n.qolDomainVitality;
      case QolDomain.comfort:
        return l10n.qolDomainComfort;
      case QolDomain.emotional:
        return l10n.qolDomainEmotional;
      case QolDomain.appetite:
        return l10n.qolDomainAppetite;
      case QolDomain.treatmentBurden:
        return l10n.qolDomainTreatmentBurden;
      default:
        return domain;
    }
  }

  /// Gets the abbreviated domain name from localization.
  String _getDomainShortName(AppLocalizations l10n, String domain) {
    switch (domain) {
      case QolDomain.vitality:
        return l10n.qolDomainVitalityShort;
      case QolDomain.comfort:
        return l10n.qolDomainComfortShort;
      case QolDomain.emotional:
        return l10n.qolDomainEmotionalShort;
      case QolDomain.appetite:
        return l10n.qolDomainAppetiteShort;
      case QolDomain.treatmentBurden:
        return l10n.qolDomainTreatmentBurdenShort;
      default:
        return domain;
    }
  }
}
