import 'package:flutter/foundation.dart';

/// Lightweight summary of a QoL assessment for trend visualization.
///
/// This model is computed on-demand from QolAssessment objects and is
/// NOT stored in Firestore. Used by charts to display trends over time.
@immutable
class QolTrendSummary {
  /// Creates a QoL trend summary.
  const QolTrendSummary({
    required this.date,
    required this.domainScores,
    required this.overallScore,
    this.assessmentId,
  });

  /// Date of the assessment.
  final DateTime date;

  /// Domain scores (0-100 scale).
  ///
  /// Only includes domains with valid scores (≥50% questions answered).
  /// Map keys are domain IDs, values are scores.
  final Map<String, double> domainScores;

  /// Overall QoL score (0-100 scale).
  final double overallScore;

  /// Optional reference to the original assessment ID.
  final String? assessmentId;

  /// Calculates the difference in overall score compared to another summary.
  ///
  /// Returns positive value if this summary has higher score than [other],
  /// negative if lower. Useful for showing trend direction.
  double deltaOverall(QolTrendSummary other) {
    return overallScore - other.overallScore;
  }

  /// Calculates the difference in a specific domain score.
  ///
  /// Returns null if either summary is missing the domain score.
  /// Returns positive value if this summary has higher score,
  /// negative if lower.
  double? deltaDomain(String domain, QolTrendSummary other) {
    final thisScore = domainScores[domain];
    final otherScore = other.domainScores[domain];

    if (thisScore == null || otherScore == null) {
      return null;
    }

    return thisScore - otherScore;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QolTrendSummary &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          _mapEquals(domainScores, other.domainScores) &&
          overallScore == other.overallScore &&
          assessmentId == other.assessmentId;

  @override
  int get hashCode =>
      date.hashCode ^
      _mapHashCode(domainScores) ^
      overallScore.hashCode ^
      assessmentId.hashCode;

  @override
  String toString() => 'QolTrendSummary('
      'date: $date, '
      'overallScore: $overallScore, '
      'domains: ${domainScores.length}'
      ')';

  // Helper methods for map equality
  bool _mapEquals(Map<String, double> a, Map<String, double> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  int _mapHashCode(Map<String, double> map) {
    return Object.hashAll(
      map.entries.map((e) => e.key.hashCode ^ e.value.hashCode),
    );
  }
}
