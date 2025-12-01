import 'package:hydracat/features/health/models/symptom_raw_value.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';

/// Utility class for formatting symptom descriptors consistently across the app
class SymptomDescriptorUtils {
  SymptomDescriptorUtils._();

  /// Returns the user-facing label for a symptom type key
  ///
  /// Example: SymptomType.vomiting → "Vomiting"
  static String getSymptomLabel(String symptomKey) {
    switch (symptomKey) {
      case SymptomType.vomiting:
        return 'Vomiting';
      case SymptomType.diarrhea:
        return 'Diarrhea';
      case SymptomType.constipation:
        return 'Constipation';
      case SymptomType.energy:
        return 'Energy';
      case SymptomType.suppressedAppetite:
        return 'Suppressed Appetite';
      case SymptomType.injectionSiteReaction:
        return 'Injection Site Reaction';
      default:
        return symptomKey; // Fallback to key if unknown
    }
  }

  /// Formats a raw symptom value into a human-readable descriptor
  ///
  /// Returns the formatted descriptor (e.g., "2 episodes", "Soft",
  /// "Visible swelling") or null if the raw value is not available or invalid.
  ///
  /// Examples:
  /// - formatRawValueDescriptor(SymptomType.vomiting, 3) → "3 episodes"
  /// - formatRawValueDescriptor(SymptomType.diarrhea, "soft") → "Soft"
  /// - formatRawValueDescriptor(SymptomType.energy, "low") → "Low energy"
  static String? formatRawValueDescriptor(String symptomKey, dynamic rawValue) {
    if (rawValue == null) return null;

    switch (symptomKey) {
      case SymptomType.vomiting:
        if (rawValue is int) {
          final episodeLabel = rawValue == 1 ? 'episode' : 'episodes';
          return '$rawValue $episodeLabel';
        }
        return null;

      case SymptomType.diarrhea:
        if (rawValue is String) {
          final quality = DiarrheaQuality.fromString(rawValue);
          return quality.label;
        }
        return null;

      case SymptomType.constipation:
        if (rawValue is String) {
          final level = ConstipationLevel.fromString(rawValue);
          return level.label;
        }
        return null;

      case SymptomType.suppressedAppetite:
        if (rawValue is String) {
          final fraction = AppetiteFraction.fromString(rawValue);
          return fraction.label;
        }
        return null;

      case SymptomType.injectionSiteReaction:
        if (rawValue is String) {
          final reaction = InjectionSiteReaction.fromString(rawValue);
          return reaction.label;
        }
        return null;

      case SymptomType.energy:
        if (rawValue is String) {
          final level = EnergyLevel.fromString(rawValue);
          return level.label;
        }
        return null;

      default:
        return null;
    }
  }
}
