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
/// - Full-size: 280px height, full domain names
/// - Compact: 180px height, abbreviated names (for home screen)
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
          height: 280,
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

    final chartContent = Column(
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
          height: 280,
          child: _buildRadarChart(context, scores),
        ),
      ],
    );

    // Only wrap in HydraCard when not in compact mode
    // (compact mode is used in home screen which already has a card)
    if (isCompact) {
      return chartContent;
    }

    return HydraCard(child: chartContent);
  }

  /// Builds the radar chart.
  Widget _buildRadarChart(
    BuildContext context,
    Map<String, double?> scores,
  ) {
    final l10n = context.l10n;

    // Use full domain names with line breaks for multi-word labels
    final domainLabels = QolDomain.all.map((domain) {
      return _getDomainFullNameWithLineBreaks(l10n, domain);
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
            // Use angle: 0 to make all labels horizontal for better readability
            return RadarChartTitle(
              text: domainLabels[index],
              // Increased offset for multi-line text
              positionPercentageOffset: 0.2,
            );
          },
          titleTextStyle: AppTextStyles.small.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            height: 1.2, // Line height for multi-line labels
          ),
          // Position labels further from chart
          titlePositionPercentageOffset: 0.2,
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

  /// Gets the full domain name with line breaks for multi-word labels.
  /// Used for radar chart labels to improve readability.
  String _getDomainFullNameWithLineBreaks(
    AppLocalizations l10n,
    String domain,
  ) {
    switch (domain) {
      case QolDomain.vitality:
        return l10n.qolDomainVitality;
      case QolDomain.comfort:
        return l10n.qolDomainComfort;
      case QolDomain.emotional:
        // Split "Emotional Wellbeing" into two lines
        return 'Emotional\nWellbeing';
      case QolDomain.appetite:
        return l10n.qolDomainAppetite;
      case QolDomain.treatmentBurden:
        // Split "Treatment Burden" into two lines
        return 'Treatment\nBurden';
      default:
        return domain;
    }
  }
}
