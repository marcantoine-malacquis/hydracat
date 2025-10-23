import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/notifications/services/reminder_plugin.dart';

/// Provider for the ReminderPlugin singleton instance.
///
/// This provides access to the notification plugin throughout the app
/// via Riverpod dependency injection. The plugin should be initialized
/// during app startup before this provider is used.
///
/// Example usage:
/// ```dart
/// final plugin = ref.read(reminderPluginProvider);
/// await plugin.showZoned(...);
/// ```
final reminderPluginProvider = Provider<ReminderPlugin>((ref) {
  return ReminderPlugin();
});
