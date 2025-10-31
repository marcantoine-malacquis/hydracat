/// Enumeration of logging interaction modes
///
/// Defines how the user enters and interacts with the logging flow.
/// This affects UI presentation, validation requirements, and navigation.
enum LoggingMode {
  /// Manual logging mode - full form with all fields
  ///
  /// User accesses logging through the main "Log Treatment" action.
  /// Shows complete form with all optional fields (notes, time adjustment,
  /// etc.). Allows logging any treatment type at any time.
  ///
  /// Use case: User wants to log a missed treatment from earlier, add
  /// detailed notes, or manually enter all treatment details.
  manual,

  /// Quick-log mode - streamlined single-tap logging
  ///
  /// User accesses logging through the quick-log button on home screen.
  /// Pre-fills data from schedule, shows minimal form, uses current time.
  /// Only available when schedule data exists and hasn't been logged today.
  ///
  /// Use case: User wants to quickly confirm they just administered the
  /// scheduled treatment exactly as prescribed. One tap = "I did it now".
  quickLog;

  /// User-friendly display name for the logging mode
  String get displayName => switch (this) {
        LoggingMode.manual => 'Manual Entry',
        LoggingMode.quickLog => 'Quick Log',
      };

  /// Short description of what this mode does
  String get description => switch (this) {
        LoggingMode.manual =>
          'Enter complete treatment details with all options',
        LoggingMode.quickLog =>
          'One-tap logging using scheduled treatment defaults',
      };

  /// Whether this mode allows time adjustment
  ///
  /// Quick-log always uses current time, manual allows time selection.
  bool get canAdjustTime => this == LoggingMode.manual;

  /// Whether this mode shows optional fields (notes, variations, etc.)
  ///
  /// Quick-log hides optional fields for speed, manual shows everything.
  bool get shouldShowOptionalFields => this == LoggingMode.manual;

  /// Whether this mode requires schedule data to function
  ///
  /// Quick-log requires a schedule to pre-fill data, manual doesn't.
  bool get isScheduleRequired => this == LoggingMode.quickLog;

  /// Creates a LoggingMode from a string value
  ///
  /// Returns the matching enum value or null if not found.
  /// Useful for deserializing from JSON or storage.
  static LoggingMode? fromString(String value) {
    return LoggingMode.values.where((mode) => mode.name == value).firstOrNull;
  }
}
