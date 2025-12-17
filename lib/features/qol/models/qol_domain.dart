/// Quality of Life domain constants and helpers.
///
/// This class provides immutable domain identifiers for the QoL assessment
/// feature, following the same pattern as SymptomType for consistency.
class QolDomain {
  /// Private constructor to prevent instantiation.
  const QolDomain._();

  // Domain string constants (Firestore-compatible)

  /// Vitality domain - measures energy and activity levels.
  static const String vitality = 'vitality';

  /// Comfort domain - measures physical comfort and mobility.
  static const String comfort = 'comfort';

  /// Emotional domain - measures mood and social behavior.
  static const String emotional = 'emotional';

  /// Appetite domain - measures interest in food and eating.
  static const String appetite = 'appetite';

  /// Treatment Burden domain - measures stress from CKD care.
  static const String treatmentBurden = 'treatmentBurden';

  /// All domains in canonical order.
  static const List<String> all = [
    vitality,
    comfort,
    emotional,
    appetite,
    treatmentBurden,
  ];

  /// Map of domain IDs to their display name localization keys.
  static const Map<String, String> displayNameKeys = {
    vitality: 'qolDomainVitality',
    comfort: 'qolDomainComfort',
    emotional: 'qolDomainEmotional',
    appetite: 'qolDomainAppetite',
    treatmentBurden: 'qolDomainTreatmentBurden',
  };

  /// Map of domain IDs to their description localization keys.
  static const Map<String, String> descriptionKeys = {
    vitality: 'qolDomainVitalityDesc',
    comfort: 'qolDomainComfortDesc',
    emotional: 'qolDomainEmotionalDesc',
    appetite: 'qolDomainAppetiteDesc',
    treatmentBurden: 'qolDomainTreatmentBurdenDesc',
  };

  /// Map of domain IDs to their question counts.
  ///
  /// Total: 14 questions across 5 domains
  /// Note: comfort_4 (coat condition) is deferred to V2
  static const Map<String, int> questionCounts = {
    vitality: 3,
    comfort: 3,
    emotional: 3,
    appetite: 3,
    treatmentBurden: 2,
  };

  /// Validates if a given domain string is a valid domain identifier.
  ///
  /// Returns true if [domain] is one of the defined domain constants.
  static bool isValid(String? domain) {
    if (domain == null) return false;
    return all.contains(domain);
  }

  /// Gets the display name localization key for a domain.
  ///
  /// Returns null if the domain is invalid.
  static String? getDisplayNameKey(String? domain) {
    if (domain == null) return null;
    return displayNameKeys[domain];
  }

  /// Gets the description localization key for a domain.
  ///
  /// Returns null if the domain is invalid.
  static String? getDescriptionKey(String? domain) {
    if (domain == null) return null;
    return descriptionKeys[domain];
  }

  /// Gets the number of questions for a domain.
  ///
  /// Returns 0 if the domain is invalid.
  static int getQuestionCount(String domain) {
    return questionCounts[domain] ?? 0;
  }
}
