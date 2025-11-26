import 'package:hydracat/features/health/models/symptom_entry.dart';
import 'package:hydracat/features/health/models/symptom_raw_value.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';

/// Pure functions for converting raw symptom values to 0-3 severity scores
///
/// Each symptom type has a dedicated conversion function following the
/// medical guidelines in the spec. All symptoms are normalized to a unified
/// 0-3 severity scale for consistent analytics and visualization.
///
/// The converter supports creating [SymptomEntry] instances from raw values,
/// automatically computing the appropriate severity score.
class SymptomSeverityConverter {
  /// Private constructor to prevent instantiation
  SymptomSeverityConverter._();

  /// Convert vomiting episodes to severity (0-3)
  ///
  /// Conversion table:
  /// - 0 episodes → 0 (none)
  /// - 1 episode → 1 (mild)
  /// - 2 episodes → 2 (moderate)
  /// - 3+ episodes → 3 (severe)
  static int vomitingToSeverity(int episodes) {
    if (episodes <= 0) return 0;
    if (episodes == 1) return 1;
    if (episodes == 2) return 2;
    return 3; // 3 or more
  }

  /// Convert diarrhea quality to severity (0-3)
  ///
  /// Conversion table:
  /// - normal → 0
  /// - soft → 1
  /// - loose → 2
  /// - watery → 3
  static int diarrheaToSeverity(DiarrheaQuality quality) {
    return switch (quality) {
      DiarrheaQuality.normal => 0,
      DiarrheaQuality.soft => 1,
      DiarrheaQuality.loose => 2,
      DiarrheaQuality.watery => 3,
    };
  }

  /// Convert constipation level to severity (0-3)
  ///
  /// Conversion table:
  /// - normal → 0
  /// - mildStraining → 1
  /// - noStool → 2
  /// - painful → 3
  static int constipationToSeverity(ConstipationLevel level) {
    return switch (level) {
      ConstipationLevel.normal => 0,
      ConstipationLevel.mildStraining => 1,
      ConstipationLevel.noStool => 2,
      ConstipationLevel.painful => 3,
    };
  }

  /// Convert appetite fraction to severity (0-3)
  ///
  /// Conversion table:
  /// - all → 0
  /// - ¾ → 1
  /// - ½ → 2
  /// - ¼ or nothing → 3
  static int appetiteToSeverity(AppetiteFraction fraction) {
    return switch (fraction) {
      AppetiteFraction.all => 0,
      AppetiteFraction.threeQuarters => 1,
      AppetiteFraction.half => 2,
      AppetiteFraction.quarter => 3,
      AppetiteFraction.nothing => 3,
    };
  }

  /// Convert injection site reaction to severity (0-3)
  ///
  /// Conversion table:
  /// - none → 0
  /// - mildSwelling → 1
  /// - visibleSwelling → 2
  /// - redPainful → 3
  static int injectionSiteToSeverity(InjectionSiteReaction reaction) {
    return switch (reaction) {
      InjectionSiteReaction.none => 0,
      InjectionSiteReaction.mildSwelling => 1,
      InjectionSiteReaction.visibleSwelling => 2,
      InjectionSiteReaction.redPainful => 3,
    };
  }

  /// Convert energy level to severity (0-3)
  ///
  /// Conversion table:
  /// - normal → 0
  /// - slightlyReduced → 1
  /// - low → 2
  /// - veryLow → 3
  static int energyToSeverity(EnergyLevel level) {
    return switch (level) {
      EnergyLevel.normal => 0,
      EnergyLevel.slightlyReduced => 1,
      EnergyLevel.low => 2,
      EnergyLevel.veryLow => 3,
    };
  }

  /// Create a [SymptomEntry] from raw value, automatically computing severity
  ///
  /// This is the main public API for creating symptom entries. It accepts
  /// either enum values or their string names (for enum-based symptoms) and
  /// automatically converts them to the appropriate severity score.
  ///
  /// Parameters:
  /// - [symptomType]: The symptom type key (e.g., [SymptomType.vomiting])
  /// - [rawValue]: The raw user-entered value
  ///   - For vomiting: int (number of episodes)
  ///   - For enum-based symptoms: enum value or string name
  ///
  /// Returns a [SymptomEntry] with the computed severity score.
  ///
  /// Throws [ArgumentError] if [symptomType] is unknown.
  ///
  /// Example:
  /// ```dart
  /// // Vomiting (int)
  /// final entry = SymptomSeverityConverter.createEntry(
  ///   symptomType: SymptomType.vomiting,
  ///   rawValue: 2,
  /// );
  ///
  /// // Diarrhea (enum)
  /// final entry = SymptomSeverityConverter.createEntry(
  ///   symptomType: SymptomType.diarrhea,
  ///   rawValue: DiarrheaQuality.soft,
  /// );
  ///
  /// // Diarrhea (string)
  /// final entry = SymptomSeverityConverter.createEntry(
  ///   symptomType: SymptomType.diarrhea,
  ///   rawValue: 'soft',
  /// );
  /// ```
  static SymptomEntry createEntry({
    required String symptomType,
    required dynamic rawValue,
  }) {
    final severity = _computeSeverity(symptomType, rawValue);
    return SymptomEntry(
      symptomType: symptomType,
      rawValue: rawValue,
      severityScore: severity,
    );
  }

  /// Internal: Compute severity from raw value based on symptom type
  ///
  /// Handles conversion from enum values or string names to severity scores.
  /// Supports both enum instances and their string representations for
  /// flexibility in deserialization scenarios.
  static int _computeSeverity(String symptomType, dynamic rawValue) {
    switch (symptomType) {
      case SymptomType.vomiting:
        return vomitingToSeverity(rawValue as int);
      case SymptomType.diarrhea:
        final quality = rawValue is String
            ? DiarrheaQuality.fromString(rawValue)
            : rawValue as DiarrheaQuality;
        return diarrheaToSeverity(quality);
      case SymptomType.constipation:
        final level = rawValue is String
            ? ConstipationLevel.fromString(rawValue)
            : rawValue as ConstipationLevel;
        return constipationToSeverity(level);
      case SymptomType.suppressedAppetite:
        final fraction = rawValue is String
            ? AppetiteFraction.fromString(rawValue)
            : rawValue as AppetiteFraction;
        return appetiteToSeverity(fraction);
      case SymptomType.injectionSiteReaction:
        final reaction = rawValue is String
            ? InjectionSiteReaction.fromString(rawValue)
            : rawValue as InjectionSiteReaction;
        return injectionSiteToSeverity(reaction);
      case SymptomType.energy:
        final level = rawValue is String
            ? EnergyLevel.fromString(rawValue)
            : rawValue as EnergyLevel;
        return energyToSeverity(level);
      default:
        throw ArgumentError('Unknown symptom type: $symptomType');
    }
  }
}
