/// Shared helper utilities for medication unit display short forms.
///
/// Centralizes mapping so UI and models consistently render
/// user-friendly unit labels (e.g., "pills" → "pill", "milligrams" → "mg").
class MedicationUnitUtils {
  const MedicationUnitUtils._();

  /// Returns a short, user-friendly form for a given medication unit.
  static String shortForm(String unit) {
    switch (unit.toLowerCase()) {
      case 'ampoules':
        return 'ampoule';
      case 'capsules':
        return 'capsule';
      case 'drops':
        return 'drop';
      case 'injections':
        return 'injection';
      case 'micrograms':
        return 'mcg';
      case 'milligrams':
        return 'mg';
      case 'milliliters':
        return 'ml';
      case 'pills':
        return 'pill';
      case 'portions':
        return 'portion';
      case 'sachets':
        return 'sachet';
      case 'tablespoon':
        return 'tbsp';
      case 'teaspoon':
        return 'tsp';
      default:
        return unit;
    }
  }
}
