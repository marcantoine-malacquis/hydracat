import 'package:hydracat/features/health/models/health_parameter.dart';

/// Constants for symptom type keys used in symptom tracking
///
/// These constants define the valid symptom keys that can be used in the
/// `symptoms` map of [HealthParameter]. Each symptom is tracked with a
/// numeric score from 0-10.
class SymptomType {
  /// Private constructor to prevent instantiation
  SymptomType._();

  /// Vomiting symptom
  static const String vomiting = 'vomiting';

  /// Diarrhea symptom
  static const String diarrhea = 'diarrhea';

  /// Constipation symptom
  static const String constipation = 'constipation';

  /// Lethargy symptom
  static const String lethargy = 'lethargy';

  /// Suppressed appetite symptom
  static const String suppressedAppetite = 'suppressedAppetite';

  /// Injection site reaction symptom
  static const String injectionSiteReaction = 'injectionSiteReaction';

  /// List of all valid symptom type keys
  static const List<String> all = [
    vomiting,
    diarrhea,
    constipation,
    lethargy,
    suppressedAppetite,
    injectionSiteReaction,
  ];

  /// Checks if a string is a valid symptom type key
  static bool isValid(String value) {
    return all.contains(value);
  }
}
