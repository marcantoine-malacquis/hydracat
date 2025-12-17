import 'package:hydracat/features/qol/models/qol_assessment.dart';
import 'package:hydracat/features/qol/models/qol_domain.dart';
import 'package:hydracat/features/qol/models/qol_question.dart';
import 'package:hydracat/features/qol/models/qol_response.dart';
import 'package:hydracat/features/qol/models/qol_trend_summary.dart';

/// Trend stability classification for QoL scores over time.
enum TrendStability {
  /// Trend is stable (slope between -5 and +5 points/month).
  stable,

  /// Trend is improving (slope > +5 points/month).
  improving,

  /// Trend is declining (slope < -5 points/month).
  declining,
}

/// Pure business logic service for QoL scoring and trend analysis.
///
/// Contains no Firebase dependencies - all methods are stateless
/// calculations that operate on QoL data models.
class QolScoringService {
  /// Creates a QoL scoring service.
  const QolScoringService();

  /// Calculates score for a specific domain (0-100 scale).
  ///
  /// Returns null if less than 50% of domain questions are answered
  /// (low confidence). All questions use semantic scaling where
  /// higher score = better QoL (no reverse scoring needed).
  ///
  /// Example:
  /// ```dart
  /// final score = service.calculateDomainScore(
  ///   QolDomain.vitality,
  ///   assessment.responses,
  /// );
  /// // Returns 75.0 if vitality score is good
  /// ```
  double? calculateDomainScore(String domain, List<QolResponse> responses) {
    if (!QolDomain.isValid(domain)) return null;

    final domainQuestions = QolQuestion.getByDomain(domain);
    final totalQuestions = domainQuestions.length;

    // Get answered responses for this domain
    final domainResponses = responses.where((r) {
      final question = QolQuestion.getById(r.questionId);
      return question?.domain == domain && r.isAnswered;
    }).toList();

    final answeredCount = domainResponses.length;

    // Require at least 50% answered for confidence
    if (answeredCount < (totalQuestions * 0.5)) {
      return null;
    }

    // Calculate mean of answered scores (0-4 scale)
    final sum = domainResponses.fold<int>(
      0,
      (sum, r) => sum + (r.score ?? 0),
    );
    final mean = sum / answeredCount;

    // Convert to 0-100 scale
    return (mean / 4.0) * 100.0;
  }

  /// Calculates overall QoL score from an assessment (0-100 scale).
  ///
  /// Returns null if any domain has low confidence (missing score).
  /// Calculated as mean of all 5 domain scores.
  ///
  /// Example:
  /// ```dart
  /// final overall = service.calculateOverallScore(assessment);
  /// // Returns 77.5 if all domains average to that score
  /// ```
  double? calculateOverallScore(QolAssessment assessment) {
    final scores = assessment.domainScores;

    // Check if any domain is null (low confidence)
    if (scores.values.any((score) => score == null)) {
      return null;
    }

    // Calculate mean of valid domain scores
    final validScores = scores.values.whereType<double>().toList();
    if (validScores.isEmpty) return null;

    final sum = validScores.reduce((a, b) => a + b);
    return sum / validScores.length;
  }

  /// Calculates trend stability from recent QoL summaries.
  ///
  /// Requires at least 3 trend points. Uses simple linear regression
  /// to determine if scores are improving, declining, or stable.
  ///
  /// Thresholds:
  /// - Slope > +5 points/month = improving
  /// - Slope < -5 points/month = declining
  /// - Otherwise = stable
  ///
  /// Example:
  /// ```dart
  /// final stability = service.calculateTrendStability(recentTrends);
  /// if (stability == TrendStability.improving) {
  ///   print('QoL is getting better!');
  /// }
  /// ```
  TrendStability calculateTrendStability(List<QolTrendSummary> recentTrends) {
    if (recentTrends.length < 3) {
      return TrendStability.stable;
    }

    // Use simple linear regression to calculate slope
    // Convert dates to numeric values (days since first assessment)
    final firstDate = recentTrends.last.date;
    final dataPoints = recentTrends.map((trend) {
      final daysSinceFirst = trend.date.difference(firstDate).inDays;
      return (x: daysSinceFirst.toDouble(), y: trend.overallScore);
    }).toList();

    // Calculate slope using least squares regression
    final n = dataPoints.length;
    final sumX = dataPoints.fold<double>(0, (sum, p) => sum + p.x);
    final sumY = dataPoints.fold<double>(0, (sum, p) => sum + p.y);
    final sumXY = dataPoints.fold<double>(0, (sum, p) => sum + (p.x * p.y));
    final sumXX = dataPoints.fold<double>(0, (sum, p) => sum + (p.x * p.x));

    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);

    // Convert slope from points/day to points/month (× 30)
    final slopePerMonth = slope * 30;

    // Classify based on threshold
    if (slopePerMonth > 5) {
      return TrendStability.improving;
    } else if (slopePerMonth < -5) {
      return TrendStability.declining;
    } else {
      return TrendStability.stable;
    }
  }

  /// Detects notable change in a specific domain.
  ///
  /// Returns true if there's a ≥15 point drop in domain score
  /// sustained across ≥2 consecutive assessments.
  ///
  /// Returns false if less than 3 trend points available.
  ///
  /// Example:
  /// ```dart
  /// final hasChange = service.hasNotableChange(
  ///   recentTrends,
  ///   QolDomain.comfort,
  /// );
  /// if (hasChange) {
  ///   print('Comfort scores have dropped significantly');
  /// }
  /// ```
  bool hasNotableChange(List<QolTrendSummary> recentTrends, String domain) {
    if (recentTrends.length < 3) return false;

    // Get domain scores from trends (most recent first)
    final domainScores = recentTrends
        .map((trend) => trend.domainScores[domain])
        .whereType<double>()
        .toList();

    if (domainScores.length < 3) return false;

    // Check for sustained drop (≥15 points) across 2+ consecutive assessments
    for (var i = 0; i < domainScores.length - 1; i++) {
      final current = domainScores[i];
      final previous = domainScores[i + 1];
      final drop = previous - current;

      // If we found a significant drop (≥15 points)
      if (drop >= 15) {
        // Check if it's sustained in the next assessment too
        if (i < domainScores.length - 2) {
          final nextPrevious = domainScores[i + 2];
          final nextDrop = nextPrevious - current;
          if (nextDrop >= 15) {
            return true; // Sustained drop confirmed
          }
        } else {
          // Only 2 points available, still consider it notable
          return true;
        }
      }
    }

    return false;
  }

  /// Generates interpretation message for QoL trends.
  ///
  /// Returns localized interpretation key based on:
  /// - Overall score delta (previous → current)
  /// - Notable changes in specific domains
  /// - Trend stability
  ///
  /// Returns null if no previous assessment (first assessment case).
  ///
  /// Example return values:
  /// - 'qolInterpretationStable'
  /// - 'qolInterpretationImproving'
  /// - 'qolInterpretationDeclining'
  /// - 'qolInterpretationNotableDropComfort'
  ///
  /// Example:
  /// ```dart
  /// final key = service.generateInterpretationMessage(
  ///   currentTrend,
  ///   previousTrend,
  /// );
  /// final message = context.l10n.translate(key);
  /// ```
  String? generateInterpretationMessage(
    QolTrendSummary current,
    QolTrendSummary? previous,
  ) {
    // No interpretation for first assessment
    if (previous == null) return null;

    // Calculate overall delta
    final delta = current.deltaOverall(previous);

    // Check for notable domain-specific changes (≥15 point drop)
    final comfortDelta = current.deltaDomain(QolDomain.comfort, previous);
    if (comfortDelta != null && comfortDelta <= -15) {
      return 'qolInterpretationNotableDropComfort';
    }

    final appetiteDelta = current.deltaDomain(QolDomain.appetite, previous);
    if (appetiteDelta != null && appetiteDelta <= -15) {
      return 'qolInterpretationNotableDropAppetite';
    }

    final vitalityDelta = current.deltaDomain(QolDomain.vitality, previous);
    if (vitalityDelta != null && vitalityDelta <= -15) {
      return 'qolInterpretationNotableDropVitality';
    }

    final emotionalDelta = current.deltaDomain(QolDomain.emotional, previous);
    if (emotionalDelta != null && emotionalDelta <= -15) {
      return 'qolInterpretationNotableDropEmotional';
    }

    final treatmentDelta = current.deltaDomain(
      QolDomain.treatmentBurden,
      previous,
    );
    if (treatmentDelta != null && treatmentDelta <= -15) {
      return 'qolInterpretationNotableDropTreatmentBurden';
    }

    // General trend interpretation based on delta
    if (delta > 10) {
      return 'qolInterpretationImproving';
    } else if (delta < -10) {
      return 'qolInterpretationDeclining';
    } else {
      return 'qolInterpretationStable';
    }
  }
}
