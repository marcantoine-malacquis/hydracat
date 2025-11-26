// Enum definitions for symptom raw values
//
// These enums represent the user-facing input values for different symptom
// types in the hybrid symptom tracking system. Each symptom type has its own
// enum with medically accurate descriptors that will be converted to a 0-3
// severity scale internally.

/// Diarrhea stool quality descriptor
///
/// Used to track stool consistency, from normal to liquid.
/// Converted to 0-3 severity scale: normal(0), soft(1), loose(2), watery(3)
enum DiarrheaQuality {
  /// Normal stool consistency
  normal('Normal'),

  /// Soft but formed stool
  soft('Soft'),

  /// Loose, poorly formed stool
  loose('Loose'),

  /// Watery or liquid stool
  watery('Watery / liquid');

  /// Create a DiarrheaQuality with a display label
  const DiarrheaQuality(this.label);

  /// User-facing label for this quality level
  final String label;

  /// Convert from string representation (enum name)
  ///
  /// Returns the matching enum value, or [normal] if not found.
  /// Used for Firestore deserialization.
  static DiarrheaQuality fromString(String value) {
    return DiarrheaQuality.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DiarrheaQuality.normal,
    );
  }
}

/// Constipation straining level descriptor
///
/// Used to track difficulty with bowel movements.
/// Converted to 0-3 severity scale:
/// normal(0), mildStraining(1), noStool(2), painful(3)
enum ConstipationLevel {
  /// Normal, comfortable bowel movements
  normal('Normal stooling'),

  /// Some straining required
  mildStraining('Mild straining'),

  /// No bowel movement
  noStool('No stool'),

  /// Painful defecation or crying
  painful('Painful/crying');

  /// Create a ConstipationLevel with a display label
  const ConstipationLevel(this.label);

  /// User-facing label for this level
  final String label;

  /// Convert from string representation (enum name)
  ///
  /// Returns the matching enum value, or [normal] if not found.
  /// Used for Firestore deserialization.
  static ConstipationLevel fromString(String value) {
    return ConstipationLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ConstipationLevel.normal,
    );
  }
}

/// Appetite fraction consumed
///
/// Used to track how much of the regular meal was consumed.
/// Converted to 0-3 severity scale: all(0), ¾(1), ½(2), ¼/nothing(3)
enum AppetiteFraction {
  /// Consumed entire meal
  all('All'),

  /// Consumed three-quarters of meal
  threeQuarters('¾'),

  /// Consumed half of meal
  half('½'),

  /// Consumed quarter of meal
  quarter('¼'),

  /// Consumed nothing
  nothing('Nothing');

  /// Create an AppetiteFraction with a display label
  const AppetiteFraction(this.label);

  /// User-facing label for this fraction
  final String label;

  /// Convert from string representation (enum name)
  ///
  /// Returns the matching enum value, or [all] if not found.
  /// Used for Firestore deserialization.
  static AppetiteFraction fromString(String value) {
    return AppetiteFraction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppetiteFraction.all,
    );
  }
}

/// Injection site reaction severity
///
/// Used to track reaction at subcutaneous fluid injection site.
/// Converted to 0-3 severity scale:
/// none(0), mildSwelling(1), visibleSwelling(2), redPainful(3)
enum InjectionSiteReaction {
  /// No visible reaction
  none('None'),

  /// Slight swelling, not concerning
  mildSwelling('Mild swelling'),

  /// Clearly visible swelling
  visibleSwelling('Visible swelling'),

  /// Red, warm, or painful reaction
  redPainful('Red & painful');

  /// Create an InjectionSiteReaction with a display label
  const InjectionSiteReaction(this.label);

  /// User-facing label for this reaction level
  final String label;

  /// Convert from string representation (enum name)
  ///
  /// Returns the matching enum value, or [none] if not found.
  /// Used for Firestore deserialization.
  static InjectionSiteReaction fromString(String value) {
    return InjectionSiteReaction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InjectionSiteReaction.none,
    );
  }
}

/// Energy level descriptor
///
/// Used to track pet's activity and alertness level.
/// Replaces the previous "lethargy" symptom (renamed to energy)
/// (higher score = lower energy = worse condition).
/// Converted to 0-3 severity scale:
/// normal(0), slightlyReduced(1), low(2), veryLow(3)
enum EnergyLevel {
  /// Normal energy and activity
  normal('Normal energy'),

  /// Slightly less active than usual
  slightlyReduced('Slightly reduced energy'),

  /// Noticeably low energy
  low('Low energy'),

  /// Very lethargic, minimal activity
  veryLow('Very low energy');

  /// Create an EnergyLevel with a display label
  const EnergyLevel(this.label);

  /// User-facing label for this energy level
  final String label;

  /// Convert from string representation (enum name)
  ///
  /// Returns the matching enum value, or [normal] if not found.
  /// Used for Firestore deserialization.
  static EnergyLevel fromString(String value) {
    return EnergyLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EnergyLevel.normal,
    );
  }
}
