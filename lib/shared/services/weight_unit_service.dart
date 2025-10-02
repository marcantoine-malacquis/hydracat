import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing weight unit preference using SharedPreferences.
class WeightUnitService {
  static const String _weightUnitKey = 'app_weight_unit';
  static const String _defaultWeightUnit = 'kg';

  /// Saves the weight unit preference to local storage.
  static Future<void> saveWeightUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weightUnitKey, unit);
  }

  /// Loads the weight unit preference from local storage.
  /// Returns 'kg' as default if no preference is saved.
  static Future<String> loadWeightUnit() async {
    final prefs = await SharedPreferences.getInstance();
    final weightUnit = prefs.getString(_weightUnitKey);

    if (weightUnit == null) {
      return _defaultWeightUnit; // Default to kg
    }

    // Validate the stored value
    if (weightUnit == 'kg' || weightUnit == 'lbs') {
      return weightUnit;
    }

    return _defaultWeightUnit; // Return default if invalid value
  }

  /// Clears the saved weight unit preference.
  static Future<void> clearWeightUnit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_weightUnitKey);
  }
}
