import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/features/qol/models/qol_assessment.dart';
import 'package:hydracat/features/qol/models/qol_trend_summary.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/qol_provider.dart';
import 'package:hydracat/shared/widgets/cards/hydra_card.dart';

/// Displays interpretation of QoL trends compared to previous assessment.
///
/// Shows:
/// - Trend interpretation message (stable/improving/declining)
/// - Domain-specific notable changes (if any)
/// - Disclaimer footer
///
/// Requires at least 2 assessments to show trends. If only 1 assessment
/// exists, shows message prompting user to complete another.
class QolInterpretationCard extends ConsumerWidget {
  /// Creates a QoL interpretation card.
  const QolInterpretationCard({
    required this.assessment,
    super.key,
  });

  /// The current assessment to interpret.
  final QolAssessment assessment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final recentAssessments = ref.watch(recentQolAssessmentsProvider);
    final scoringService = ref.read(qolScoringServiceProvider);

    // Need at least 2 assessments for trend analysis
    if (recentAssessments.length < 2) {
      return HydraInfoCard(
        message: l10n.qolNeedMoreAssessments,
      );
    }

    // Get previous assessment (second item in list since list is ordered desc)
    final previousAssessment = recentAssessments.length > 1
        ? recentAssessments[1]
        : null;

    // If current assessment doesn't have overall score, can't interpret
    if (assessment.overallScore == null) {
      return HydraInfoCard(
        message: l10n.qolInsufficientDataForInterpretation,
        type: HydraInfoType.warning,
      );
    }

    // Convert assessments to trend summaries for comparison
    final currentTrend = _convertToTrendSummary(assessment);
    final previousTrend = previousAssessment != null &&
            previousAssessment.overallScore != null
        ? _convertToTrendSummary(previousAssessment)
        : null;

    // Generate interpretation message
    final interpretationKey = scoringService.generateInterpretationMessage(
      currentTrend,
      previousTrend,
    );

    // No interpretation available (shouldn't happen with 2+ assessments)
    if (interpretationKey == null) {
      return HydraInfoCard(
        message: l10n.qolNeedMoreAssessments,
      );
    }

    // Get localized interpretation message
    final interpretationMessage = _getInterpretationMessage(
      l10n,
      interpretationKey,
    );

    // Determine card type based on interpretation
    final cardType = _getCardType(interpretationKey);

    return HydraInfoCard(
      message: '$interpretationMessage\n\n${l10n.qolTrendDisclaimer}',
      type: cardType,
    );
  }

  /// Converts a QolAssessment to QolTrendSummary for trend analysis.
  QolTrendSummary _convertToTrendSummary(QolAssessment assessment) {
    // Filter domain scores to only include valid ones (non-null)
    final validDomainScores = <String, double>{};
    assessment.domainScores.forEach((domain, score) {
      if (score != null) {
        validDomainScores[domain] = score;
      }
    });

    return QolTrendSummary(
      date: assessment.date,
      domainScores: validDomainScores,
      overallScore: assessment.overallScore!,
      assessmentId: assessment.documentId,
    );
  }

  /// Gets the localized interpretation message for the given key.
  String _getInterpretationMessage(
    AppLocalizations l10n,
    String interpretationKey,
  ) {
    // Map interpretation keys to localized messages
    switch (interpretationKey) {
      case 'qolInterpretationStable':
        return l10n.qolInterpretationStable;
      case 'qolInterpretationImproving':
        return l10n.qolInterpretationImproving;
      case 'qolInterpretationDeclining':
        return l10n.qolInterpretationDeclining;
      case 'qolInterpretationNotableDropComfort':
        return l10n.qolInterpretationNotableDropComfort;
      case 'qolInterpretationNotableDropAppetite':
        return l10n.qolInterpretationNotableDropAppetite;
      case 'qolInterpretationNotableDropVitality':
        return l10n.qolInterpretationNotableDropVitality;
      case 'qolInterpretationNotableDropEmotional':
        return l10n.qolInterpretationNotableDropEmotional;
      case 'qolInterpretationNotableDropTreatmentBurden':
        return l10n.qolInterpretationNotableDropTreatmentBurden;
      default:
        return interpretationKey; // Fallback to key if not found
    }
  }

  /// Determines the HydraInfoCard type based on interpretation.
  HydraInfoType _getCardType(String interpretationKey) {
    if (interpretationKey.contains('Improving')) {
      return HydraInfoType.success;
    } else if (interpretationKey.contains('Declining') ||
        interpretationKey.contains('NotableDrop')) {
      return HydraInfoType.warning;
    } else {
      return HydraInfoType.info;
    }
  }
}
