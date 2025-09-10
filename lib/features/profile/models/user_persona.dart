/// Enumeration of treatment approaches for CKD management
enum UserPersona {
  /// Pet receives only medication-based treatment
  medicationOnly,

  /// Pet receives only fluid therapy treatment
  fluidTherapyOnly,

  /// Pet receives both medication and fluid therapy
  medicationAndFluidTherapy;

  /// User-friendly display name for the persona
  String get displayName => switch (this) {
        UserPersona.medicationOnly => 'Medication Management',
        UserPersona.fluidTherapyOnly => 'Fluid Therapy',
        UserPersona.medicationAndFluidTherapy => 'Medication & Fluid Therapy',
      };

  /// Detailed description of the treatment approach
  String get description => switch (this) {
        UserPersona.medicationOnly =>
          'Focus on oral medications, supplements, and dietary management',
        UserPersona.fluidTherapyOnly =>
          'Primary focus on subcutaneous fluid administration',
        UserPersona.medicationAndFluidTherapy =>
          'Comprehensive care combining medications and fluid therapy',
      };

  /// Whether this persona includes medication management
  bool get includesMedication => switch (this) {
        UserPersona.medicationOnly => true,
        UserPersona.fluidTherapyOnly => false,
        UserPersona.medicationAndFluidTherapy => true,
      };

  /// Whether this persona includes fluid therapy
  bool get includesFluidTherapy => switch (this) {
        UserPersona.medicationOnly => false,
        UserPersona.fluidTherapyOnly => true,
        UserPersona.medicationAndFluidTherapy => true,
      };

  /// Creates a UserPersona from a string value
  static UserPersona? fromString(String value) {
    return UserPersona.values
        .where((persona) => persona.name == value)
        .firstOrNull;
  }
}
