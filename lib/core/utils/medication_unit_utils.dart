/// Shared helper utilities for medication unit display short forms.
///
/// Centralizes mapping so UI and models consistently render
/// user-friendly unit labels (e.g., "pills" → "pill", "milligrams" → "mg").
///
/// Handles legacy data formats including "Unit(s)" pattern for backward
/// compatibility with existing schedules.
class MedicationUnitUtils {
  const MedicationUnitUtils._();

  /// Returns a short, user-friendly form for a given medication unit.
  ///
  /// Handles legacy data formats:
  /// - "Sachet(s)" → "sachet"
  /// - "Pills" → "pill"
  /// - "sachets" → "sachet"
  ///
  /// The returned value is suitable for use with localization plural forms.
  static String shortForm(String unit) {
    // Normalize legacy "(s)" pattern (e.g., "Sachet(s)" → "Sachet")
    final normalized = unit.replaceAll(RegExp(r'\(s\)$'), '').trim();

    switch (normalized.toLowerCase()) {
      case 'ampoules':
      case 'ampoule':
        return 'ampoule';
      case 'capsules':
      case 'capsule':
        return 'capsule';
      case 'drops':
      case 'drop':
        return 'drop';
      case 'injections':
      case 'injection':
        return 'injection';
      case 'micrograms':
      case 'microgram':
        return 'mcg';
      case 'milligrams':
      case 'milligram':
        return 'mg';
      case 'milliliters':
      case 'milliliter':
        return 'ml';
      case 'pills':
      case 'pill':
        return 'pill';
      case 'portions':
      case 'portion':
        return 'portion';
      case 'sachets':
      case 'sachet':
        return 'sachet';
      case 'tablets':
      case 'tablet':
        return 'tablet';
      case 'tablespoon':
      case 'tablespoons':
        return 'tbsp';
      case 'teaspoon':
      case 'teaspoons':
        return 'tsp';
      default:
        return unit;
    }
  }
}
