/// Granularity options for weight graph visualization
///
/// Determines the time range and detail level for weight trend display:
/// - Week: Shows daily weights for a 7-day period (Mon-Sun)
/// - Month: Shows daily weights for a calendar month
/// - Year: Shows monthly summaries for a 12-month period
enum WeightGranularity {
  /// Week view - shows daily weights for 7 days (Monday to Sunday)
  week,

  /// Month view - shows daily weights for calendar month
  month,

  /// Year view - shows monthly summaries for 12 months
  year;

  /// Display label for this granularity
  String get label => switch (this) {
        WeightGranularity.week => 'Week',
        WeightGranularity.month => 'Month',
        WeightGranularity.year => 'Year',
      };
}
