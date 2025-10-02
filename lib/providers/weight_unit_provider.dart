import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/shared/services/weight_unit_service.dart';

/// Notifier for managing weight unit preference state with persistence.
class WeightUnitNotifier extends StateNotifier<String> {
  /// Creates a weight unit notifier with 'kg' as default.
  WeightUnitNotifier() : super('kg') {
    _loadWeightUnit();
  }

  /// Loads the saved weight unit preference from storage.
  Future<void> _loadWeightUnit() async {
    final weightUnit = await WeightUnitService.loadWeightUnit();
    state = weightUnit;
  }

  /// Sets a specific weight unit preference.
  Future<void> setWeightUnit(String unit) async {
    state = unit;
    await WeightUnitService.saveWeightUnit(unit);
  }

  /// Resets weight unit to 'kg' and clears saved preference.
  Future<void> resetToKg() async {
    state = 'kg';
    await WeightUnitService.clearWeightUnit();
  }
}

/// Provider for weight unit preference state management.
final weightUnitProvider = StateNotifierProvider<WeightUnitNotifier, String>(
  (ref) => WeightUnitNotifier(),
);
