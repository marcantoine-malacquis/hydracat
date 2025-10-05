/// Enumeration of treatment types for logging selection
///
/// Used when users with combined treatment personas (medication + fluid
/// therapy) need to choose which type to log. This is a UI-level choice
/// that doesn't persist beyond the immediate logging flow.
///
/// Users with single-treatment personas (medication-only or fluid-only)
/// skip this selection entirely.
enum TreatmentChoice {
  /// Log a medication session
  ///
  /// User will be directed to medication logging form with fields for:
  /// medication name, dosage, unit, time, notes, etc.
  medication,

  /// Log a fluid therapy session
  ///
  /// User will be directed to fluid therapy logging form with fields for:
  /// volume, injection site, stress level, time, notes, etc.
  fluid;

  /// User-friendly display name for the treatment choice
  String get displayName => switch (this) {
        TreatmentChoice.medication => 'Medication',
        TreatmentChoice.fluid => 'Fluid Therapy',
      };

  /// Icon name for visual representation
  ///
  /// These correspond to Flutter Icons or custom asset icons.
  /// Used in the treatment choice dialog/selector UI.
  String get iconName => switch (this) {
        TreatmentChoice.medication => 'medication',
        TreatmentChoice.fluid => 'fluid_therapy',
      };

  /// Short description for the choice card/button
  String get description => switch (this) {
        TreatmentChoice.medication => 'Log medication dose',
        TreatmentChoice.fluid => 'Log fluid administration',
      };

  /// Creates a TreatmentChoice from a string value
  ///
  /// Returns the matching enum value or null if not found.
  /// Useful for deserializing from JSON or storage (though this choice
  /// typically doesn't persist beyond the immediate UI flow).
  static TreatmentChoice? fromString(String value) {
    return TreatmentChoice.values
        .where((choice) => choice.name == value)
        .firstOrNull;
  }
}
