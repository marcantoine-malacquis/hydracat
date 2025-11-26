import 'package:flutter/foundation.dart';

/// Represents a single symptom entry with raw value and computed severity
///
/// The raw value type varies by symptom:
/// - Vomiting: int (number of episodes, 0-10+)
/// - Diarrhea/Constipation/InjectionSite/Energy: String (enum name)
/// - Appetite: String (enum name)
///
/// Severity is always 0-3 for consistent analytics and visualization.
/// This hybrid model allows medically accurate user inputs while maintaining
/// a unified internal severity scale.
@immutable
class SymptomEntry {
  /// Creates a [SymptomEntry] instance
  ///
  /// Parameters:
  /// - [symptomType]: The symptom key (e.g., 'vomiting', 'diarrhea')
  /// - [rawValue]: The user-entered value (int for vomiting, String for others)
  /// - [severityScore]: The computed severity score (0-3)
  const SymptomEntry({
    required this.symptomType,
    required this.rawValue,
    required this.severityScore,
  });

  /// Factory constructor from Firestore JSON
  ///
  /// Deserializes a symptom entry from the Firestore document format:
  /// ```json
  /// {
  ///   "rawValue": 2,  // or "soft" for enum-based symptoms
  ///   "severityScore": 2
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [symptomType]: The symptom key from the parent map
  /// - [json]: The nested map containing rawValue and severityScore
  factory SymptomEntry.fromJson(
    String symptomType,
    Map<String, dynamic> json,
  ) {
    return SymptomEntry(
      symptomType: symptomType,
      rawValue: json['rawValue'],
      severityScore: (json['severityScore'] as num).toInt(),
    );
  }

  /// Symptom type key (vomiting, diarrhea, etc.)
  ///
  /// Should match one of the constants in SymptomType class.
  final String symptomType;

  /// Raw user-entered value
  /// (int for vomiting, String for enum-based symptoms)
  ///
  /// Type varies by symptom:
  /// - Vomiting: int (number of episodes)
  /// - Diarrhea: String (enum name like "soft", "loose", "watery")
  /// - Constipation: String (enum name like "mildStraining", "noStool")
  /// - Energy: String (enum name like "slightlyReduced", "low")
  /// - Appetite: String (enum name like "half", "quarter")
  /// - Injection Site: String (enum name "mildSwelling", "visibleSwelling")
  final dynamic rawValue;

  /// Computed severity score (0-3)
  ///
  /// All symptoms are normalized to this scale for consistent analytics:
  /// - 0: None/normal
  /// - 1: Mild
  /// - 2: Moderate
  /// - 3: Severe
  final int severityScore;

  /// Convert to Firestore JSON
  ///
  /// Returns a map suitable for Firestore storage:
  /// ```dart
  /// {
  ///   'rawValue': rawValue,
  ///   'severityScore': severityScore,
  /// }
  /// ```
  Map<String, dynamic> toJson() {
    return {
      'rawValue': rawValue,
      'severityScore': severityScore,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomEntry &&
          other.symptomType == symptomType &&
          other.rawValue == rawValue &&
          other.severityScore == severityScore;

  @override
  int get hashCode => Object.hash(symptomType, rawValue, severityScore);

  @override
  String toString() {
    return 'SymptomEntry('
        'type: $symptomType, '
        'raw: $rawValue, '
        'severity: $severityScore'
        ')';
  }
}
