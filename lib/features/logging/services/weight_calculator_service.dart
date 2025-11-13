import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Service for calculating fluid volume from weight measurements
///
/// Provides:
/// - Volume calculation from weight difference (1g Ringer's ≈ 1mL)
/// - Weight validation (bounds, negative difference, volume range)
/// - Last bag weight persistence (SharedPreferences, user+pet scoped)
/// - 14-day expiry for stored weights
class WeightCalculatorService {
  /// Creates a [WeightCalculatorService] with SharedPreferences dependency
  WeightCalculatorService(this._prefs);

  final SharedPreferences _prefs;

  /// Generate versioned, user+pet-scoped key for SharedPreferences
  ///
  /// Format: `last_bag_weight_v1_{userId}_{petId}`
  /// - Versioned (v1): Allows painless future schema changes
  /// - User-scoped: Prevents cross-account clashes on shared devices
  /// - Pet-specific: Each pet tracks its own bag weight
  String _key(String userId, String petId) =>
      'last_bag_weight_v1_${userId}_$petId';

  /// Save last bag weight (user+pet scoped)
  ///
  /// Stores the final weight from a fluid session to enable "continue from
  /// same bag" feature on next session (within 14 days).
  ///
  /// Parameters:
  /// - [userId]: Current user ID (for multi-user device support)
  /// - [petId]: Pet ID (for multi-pet support)
  /// - [finalWeightG]: Final weight in grams after fluid administration
  Future<void> saveLastBagWeight({
    required String userId,
    required String petId,
    required double finalWeightG,
  }) async {
    final data = LastBagWeight(
      finalWeightG: finalWeightG,
      lastUsedDate: DateTime.now(),
      usedWeightCalculator: true,
    );
    await _prefs.setString(_key(userId, petId), jsonEncode(data.toJson()));
  }

  /// Get last bag weight (returns null if >14 days or doesn't exist)
  ///
  /// Returns the stored weight from the last session that used the weight
  /// calculator, if it was within the last 14 days. This enables the
  /// "continue from same bag" feature.
  ///
  /// Returns null if:
  /// - No previous data exists
  /// - Data is older than 14 days
  /// - Data is malformed/corrupt
  LastBagWeight? getLastBagWeight({
    required String userId,
    required String petId,
  }) {
    final raw = _prefs.getString(_key(userId, petId));
    if (raw == null) return null;

    try {
      final data = LastBagWeight.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (data == null) return null;

      // Check 14-day expiry
      if (DateTime.now().difference(data.lastUsedDate).inDays > 14) {
        return null;
      }
      return data;
    } on Exception {
      // Return null if data is malformed
      return null;
    }
  }

  /// Calculate volume (clamped to non-negative)
  ///
  /// Formula: Volume (mL) ≈ Initial Weight (g) - Final Weight (g)
  /// Assumption: Ringer-Lactate density ≈ 1g/mL
  ///
  /// Returns volume in mL, clamped to non-negative values.
  double calculateVolumeMl(double initialG, double finalG) =>
      (initialG - finalG).clamp(0, double.infinity);

  /// Validate weights and enforce session constraints
  ///
  /// Validates:
  /// - Both weights are provided
  /// - Both weights are within reasonable bounds (10-10,000g)
  /// - Final weight is not greater than initial weight
  /// - Calculated volume is within FluidSession constraints (1-500 mL)
  ///
  /// Returns [WeightValidationResult] with isValid flag and optional
  /// error message.
  WeightValidationResult validate({
    required double? initialG,
    required double? finalG,
  }) {
    const min = 10.0;
    const max = 10000.0;

    if (initialG == null || finalG == null) {
      return const WeightValidationResult(
        isValid: false,
        errorMessage: 'Please enter both weights',
      );
    }

    if (initialG < min ||
        initialG > max ||
        finalG < min ||
        finalG > max) {
      return const WeightValidationResult(
        isValid: false,
        errorMessage: 'Please enter a weight between 10g and 10,000g',
      );
    }

    if (finalG > initialG) {
      return const WeightValidationResult(
        isValid: false,
        errorMessage: 'Final weight cannot be greater than initial weight. '
            'Did you swap the measurements?',
      );
    }

    final vol = initialG - finalG;
    if (vol < 1 || vol > 500) {
      return const WeightValidationResult(
        isValid: false,
        errorMessage: 'Calculated volume must be between 1 and 500 mL',
      );
    }

    return const WeightValidationResult(isValid: true);
  }
}

/// Data class for last bag weight persistence
///
/// Stored in SharedPreferences with 14-day expiry for "continue from same bag"
/// feature.
class LastBagWeight {
  /// Creates a [LastBagWeight] instance
  const LastBagWeight({
    required this.finalWeightG,
    required this.lastUsedDate,
    required this.usedWeightCalculator,
  });

  /// Final weight in grams (after fluid administration)
  final double finalWeightG;

  /// Date when this weight was recorded
  final DateTime lastUsedDate;

  /// Whether this session used the weight calculator
  final bool usedWeightCalculator;

  /// Converts to JSON for SharedPreferences storage
  Map<String, dynamic> toJson() => {
        'finalWeightG': finalWeightG,
        'lastUsedDate': lastUsedDate.toIso8601String(),
        'usedWeightCalculator': usedWeightCalculator,
      };

  /// Creates from JSON (returns null if malformed)
  static LastBagWeight? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      return LastBagWeight(
        finalWeightG: (json['finalWeightG'] as num).toDouble(),
        lastUsedDate: DateTime.parse(json['lastUsedDate'] as String),
        usedWeightCalculator: json['usedWeightCalculator'] == true,
      );
    } on Exception {
      return null;
    }
  }
}

/// Result of weight validation
///
/// Contains validation status and optional error message for user display.
class WeightValidationResult {
  /// Creates a [WeightValidationResult]
  const WeightValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  /// Whether the weights are valid
  final bool isValid;

  /// Error message if validation failed (null if valid)
  final String? errorMessage;
}

/// Result returned from WeightCalculatorDialog
///
/// Contains calculated volume and weight measurements for persistence.
class WeightCalculatorResult {
  /// Creates a [WeightCalculatorResult]
  const WeightCalculatorResult({
    required this.volumeMl,
    required this.initialWeightG,
    required this.finalWeightG,
  });

  /// Calculated volume in milliliters
  final double volumeMl;

  /// Initial weight in grams (before fluid administration)
  final double initialWeightG;

  /// Final weight in grams (after fluid administration)
  final double finalWeightG;
}
