import 'package:hydracat/features/onboarding/models/treatment_data.dart';

/// Static utility class for mapping medication database fields to app enums
///
/// Converts medication form strings (from JSON database) to
/// MedicationUnit enums and medication unit strings to
/// MedicationStrengthUnit enums.
///
/// Returns null for unknown values to allow graceful degradation
/// to manual entry.
class MedicationFormMapper {
  const MedicationFormMapper._();

  /// Maps medication form string to MedicationUnit enum
  ///
  /// Maps database form values to appropriate dosage units:
  /// - tablet/capsule → pills/capsules (counted by piece)
  /// - powder/gel/transdermal → portions (measured by application amount)
  /// - liquid/oral_solution → milliliters (measured by volume)
  ///
  /// Returns null for unknown forms to allow manual selection.
  ///
  /// Example:
  /// ```dart
  /// final unit = MedicationFormMapper.mapFormToUnit('tablet');
  /// // Returns: MedicationUnit.pills
  /// ```
  static MedicationUnit? mapFormToUnit(String form) {
    return switch (form.toLowerCase().trim()) {
      'tablet' => MedicationUnit.pills,
      'capsule' => MedicationUnit.capsules,
      'powder' => MedicationUnit.portions,
      'liquid' => MedicationUnit.milliliters,
      'oral_solution' => MedicationUnit.milliliters,
      'gel' => MedicationUnit.portions,
      'transdermal' => MedicationUnit.portions,
      _ => null, // Unknown form, let user select
    };
  }

  /// Maps medication unit string to MedicationStrengthUnit enum
  ///
  /// Converts database unit values to strength unit enums. Note that "ml" in
  /// the database indicates the form is liquid, but strength is still measured
  /// in mg, so it maps to MedicationStrengthUnit.mg.
  ///
  /// Returns null for unknown units to allow manual selection or custom input.
  ///
  /// Example:
  /// ```dart
  /// final strengthUnit = MedicationFormMapper.mapUnitToStrengthUnit('mg');
  /// // Returns: MedicationStrengthUnit.mg
  ///
  /// final complexUnit = MedicationFormMapper.mapUnitToStrengthUnit('mg/mL');
  /// // Returns: MedicationStrengthUnit.mgPerMl
  /// ```
  static MedicationStrengthUnit? mapUnitToStrengthUnit(String unit) {
    return switch (unit.toLowerCase().trim()) {
      'mg' => MedicationStrengthUnit.mg,
      // Note: ml in JSON means the form is liquid, but strength is in mg
      'ml' => MedicationStrengthUnit.mg,
      'g' => MedicationStrengthUnit.g,
      'mg/ml' => MedicationStrengthUnit.mgPerMl,
      'mcg' => MedicationStrengthUnit.mcg,
      'mcg/ml' => MedicationStrengthUnit.mcgPerMl,
      'mg/g' => MedicationStrengthUnit.mgPerG,
      'mcg/g' => MedicationStrengthUnit.mcgPerG,
      'iu' => MedicationStrengthUnit.iu,
      'iu/ml' => MedicationStrengthUnit.iuPerMl,
      '%' => MedicationStrengthUnit.percent,
      _ => null, // Unknown unit, let user select or type custom
    };
  }
}
