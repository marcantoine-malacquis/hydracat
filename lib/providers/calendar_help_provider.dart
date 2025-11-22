import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key used in SharedPreferences to track whether the user has already
/// seen the calendar help popup on the Progress screen.
const _kHasSeenCalendarHelpKey = 'has_seen_calendar_help';

/// StateNotifier provider that manages the "calendar help seen" state.
///
/// This provider exposes a boolean indicating whether the user has already
/// seen the calendar help popup. Use [CalendarHelpSeenNotifier.markSeen] to
/// mark it as seen, which will immediately update the state and persist to
/// SharedPreferences.
///
/// Backed by [sharedPreferencesProvider] which is overridden at app startup.
final calendarHelpSeenProvider = StateNotifierProvider<
    CalendarHelpSeenNotifier,
    bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CalendarHelpSeenNotifier(prefs);
});

/// StateNotifier that manages the "calendar help seen" flag.
///
/// Initializes state from SharedPreferences and provides a [markSeen] method
/// to update both the runtime state and persisted value.
class CalendarHelpSeenNotifier extends StateNotifier<bool> {
  /// Creates a [CalendarHelpSeenNotifier] backed by the given preferences.
  ///
  /// Initializes the state by reading from SharedPreferences.
  CalendarHelpSeenNotifier(this._prefs)
      : super(_prefs.getBool(_kHasSeenCalendarHelpKey) ?? false);

  final SharedPreferences _prefs;

  /// Marks the calendar help popup as seen.
  ///
  /// Immediately updates the state to `true` and persists to SharedPreferences.
  /// After calling this, the provider will return `true`, preventing the help
  /// popup from auto-opening again on future visits.
  Future<void> markSeen() async {
    state = true;
    await _prefs.setBool(_kHasSeenCalendarHelpKey, true);
  }
}
