/// Granularity options for symptoms chart visualization
///
/// Determines the time range and detail level for symptoms trend display:
/// - Week: Shows daily symptom counts for a 7-day period (Mon-Sun)
/// - Month: Shows weekly symptom counts for a calendar month
/// - Year: Shows monthly symptom counts for a 12-month period
///
/// This enum is intentionally decoupled from the weight domain to allow
/// independent evolution of symptoms chart features.
enum SymptomGranularity {
  /// Week view - shows daily symptom counts for 7 days (Monday to Sunday)
  week,

  /// Month view - shows weekly symptom counts for calendar month
  month,

  /// Year view - shows monthly symptom counts for 12 months
  year;

  /// Display label for this granularity
  String get label => switch (this) {
    SymptomGranularity.week => 'Week',
    SymptomGranularity.month => 'Month',
    SymptomGranularity.year => 'Year',
  };
}
