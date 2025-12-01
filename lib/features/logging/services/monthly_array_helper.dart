/// Helper utilities for safely updating monthly summary daily arrays
///
/// Provides pure-Dart, unit-testable functions for manipulating per-day
/// arrays in monthly summaries without Firestore dependencies.
class MonthlyArrayHelper {
  /// Updates a specific day's value in a monthly array
  ///
  /// Handles initialization, resizing, and bounds clamping to ensure
  /// monthly summary arrays are always valid and properly sized.
  ///
  /// **Parameters**:
  /// - [currentArray]: Existing array from Firestore (may be null/wrong length)
  /// - [dayOfMonth]: Day number (1-31), will be clamped to 1-monthLength
  /// - [monthLength]: Expected array length (28-31 days)
  /// - [newValue]: Value to set for this day, will be clamped to 0-5000
  ///
  /// **Returns**: New array with value updated at index [dayOfMonth - 1]
  ///
  /// **Handles**:
  /// - Null/missing arrays → initialize with zeros
  /// - Short arrays → pad with zeros to monthLength
  /// - Long arrays → truncate to monthLength
  /// - Day bounds → clamp dayOfMonth to 1-monthLength
  /// - Value bounds → clamp newValue to 0-5000
  ///
  /// **Example**:
  /// ```dart
  /// final array = MonthlyArrayHelper.updateDailyArrayValue(
  ///   currentArray: null,
  ///   dayOfMonth: 5,
  ///   monthLength: 31,
  ///   newValue: 250,
  /// );
  /// // Returns: [0, 0, 0, 0, 250, 0, ..., 0] (31 elements)
  /// ```
  static List<int> updateDailyArrayValue({
    required List<int>? currentArray,
    required int dayOfMonth,
    required int monthLength,
    required int newValue,
  }) {
    // Clamp day to valid range (1-based day number)
    final clampedDay = dayOfMonth.clamp(1, monthLength);

    // Convert to 0-based index
    final dayIndex = clampedDay - 1;

    // Clamp value to valid range (0-5000 ml)
    final clampedValue = newValue.clamp(0, 5000);

    // Initialize or resize array
    List<int> array;
    if (currentArray == null || currentArray.isEmpty) {
      // Null or empty → create zero-filled array
      array = List.filled(monthLength, 0);
    } else if (currentArray.length < monthLength) {
      // Short array → pad with zeros
      array = [
        ...currentArray,
        ...List.filled(monthLength - currentArray.length, 0),
      ];
    } else if (currentArray.length > monthLength) {
      // Long array → truncate
      array = currentArray.sublist(0, monthLength);
    } else {
      // Correct length → copy to avoid mutation
      array = List.from(currentArray);
    }

    // Update the value for this day
    array[dayIndex] = clampedValue;

    return array;
  }
}
