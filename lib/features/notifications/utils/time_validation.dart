/// Validates a time string in "HH:mm" format (24-hour time).
///
/// Returns true if the time is valid (00:00 to 23:59), false otherwise.
///
/// **Format requirements:**
/// - Exactly 5 characters
/// - Pattern: "HH:mm" where H and m are digits
/// - Hour: 00-23 (zero-padded)
/// - Minute: 00-59 (zero-padded)
///
/// **Example:**
/// ```dart
/// isValidTimeString('08:00'); // true - valid morning time
/// isValidTimeString('23:59'); // true - valid end of day
/// isValidTimeString('24:00'); // false - hour out of range
/// isValidTimeString('12:60'); // false - minute out of range
/// isValidTimeString('9:00');  // false - missing zero-padding
/// isValidTimeString('08:0');  // false - missing zero-padding
/// isValidTimeString('08:00:00'); // false - seconds not allowed
/// isValidTimeString('invalid'); // false - invalid format
/// ```
bool isValidTimeString(String time) {
  // Check format: exactly 5 characters, format "HH:mm"
  final regex = RegExp(r'^\d{2}:\d{2}$');
  if (!regex.hasMatch(time)) {
    return false;
  }

  // Parse hour and minute
  final parts = time.split(':');
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);

  // Validate ranges: 00-23 for hours, 00-59 for minutes
  if (hour == null || minute == null) {
    return false;
  }

  return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
}

/// Parses a validated time string into hour and minute components.
///
/// Validates the time string format and range, then returns a record
/// with hour and minute values.
///
/// **Returns:** A record `(int hour, int minute)` with parsed values.
///
/// **Throws:** [FormatException] if the time string is invalid.
///
/// **Example:**
/// ```dart
/// final (hour, minute) = parseTimeString('08:30');
/// // hour = 8, minute = 30
///
/// final (h, m) = parseTimeString('23:59');
/// // h = 23, m = 59
///
/// parseTimeString('25:00'); // throws FormatException
/// parseTimeString('invalid'); // throws FormatException
/// ```
///
/// **Usage in scheduling:**
/// ```dart
/// final (hour, minute) = parseTimeString('14:30');
/// final scheduledTime = DateTime(2024, 1, 15, hour, minute);
/// ```
(int hour, int minute) parseTimeString(String time) {
  if (!isValidTimeString(time)) {
    throw FormatException(
      'Invalid time format: $time. Expected "HH:mm" (00:00 to 23:59)',
    );
  }

  final parts = time.split(':');
  return (int.parse(parts[0]), int.parse(parts[1]));
}
