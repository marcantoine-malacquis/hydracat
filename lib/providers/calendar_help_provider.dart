import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key used in SharedPreferences to track whether the user has already
/// seen the calendar help popup on the Progress screen.
const _kHasSeenCalendarHelpKey = 'has_seen_calendar_help';

/// Read-only provider exposing whether the user has already seen the
/// calendar help popup.
///
/// Backed by [sharedPreferencesProvider] which is overridden at app startup.
final calendarHelpSeenProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool(_kHasSeenCalendarHelpKey) ?? false;
});

/// A simple notifier that can mark the calendar help popup as seen.
///
/// Use [CalendarHelpSeenNotifier.markSeen] after successfully showing the
/// help popup so it is not auto-opened again.
final calendarHelpSeenNotifierProvider = Provider<CalendarHelpSeenNotifier>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CalendarHelpSeenNotifier(prefs);
});

/// Helper class that persists the \"calendar help seen\" flag.
///
/// Used by [calendarHelpSeenNotifierProvider] to update SharedPreferences
/// after the CalendarHelpPopup has been shown once.
class CalendarHelpSeenNotifier {
  /// Creates a [CalendarHelpSeenNotifier] backed by the given preferences.
  CalendarHelpSeenNotifier(this._prefs);

  final SharedPreferences _prefs;

  /// Persists that the calendar help popup has been shown at least once.
  ///
  /// After calling this, [calendarHelpSeenProvider] will return `true`,
  /// preventing the help popup from auto-opening again on future visits.
  Future<void> markSeen() async {
    await _prefs.setBool(_kHasSeenCalendarHelpKey, true);
  }
}
