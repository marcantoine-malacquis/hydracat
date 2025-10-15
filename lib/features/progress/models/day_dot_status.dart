/// Status of a day in the progress calendar.
///
/// Used to determine the marker/dot color displayed for each day:
/// - [none]: No dot (future days or past days with zero schedules)
/// - [today]: Gold dot (current day until all scheduled treatments completed)
/// - [complete]: Green dot (all scheduled treatments completed)
/// - [missed]: Red dot (at least one scheduled treatment not completed)
enum DayDotStatus {
  /// No status marker displayed
  none,

  /// Current day (gold) - shown until all scheduled items are completed
  today,

  /// All scheduled treatments completed (green)
  complete,

  /// At least one scheduled treatment missed or incomplete (red)
  missed,
}
