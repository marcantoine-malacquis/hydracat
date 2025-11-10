import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/profile/models/schedule_history_entry.dart';
import 'package:hydracat/features/profile/services/schedule_history_service.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';

/// Provider for the ScheduleHistoryService instance
final scheduleHistoryServiceProvider = Provider<ScheduleHistoryService>((ref) {
  return ScheduleHistoryService();
});

/// Provider to get all schedules as they were on a specific date
///
/// Returns a map of schedule ID to historical entry for the given date.
/// Uses auto-dispose to prevent memory leaks from cached history queries.
final AutoDisposeFutureProviderFamily<
  Map<String, ScheduleHistoryEntry>,
  DateTime
>
scheduleHistoryForDateProvider = FutureProvider.autoDispose
    .family<Map<String, ScheduleHistoryEntry>, DateTime>((ref, date) async {
      final user = ref.watch(currentUserProvider);
      final pet = ref.watch(primaryPetProvider);

      if (user == null || pet == null) {
        return {};
      }

      final service = ref.watch(scheduleHistoryServiceProvider);
      final allSchedules = ref.watch(allSchedulesProvider);

      final historicalSchedules = <String, ScheduleHistoryEntry>{};

      // For each current schedule, get its historical state at the date
      for (final schedule in allSchedules) {
        final historicalEntry = await service.getScheduleAtDate(
          userId: user.id,
          petId: pet.id,
          scheduleId: schedule.id,
          date: date,
        );

        if (historicalEntry != null) {
          historicalSchedules[schedule.id] = historicalEntry;
        }
      }

      return historicalSchedules;
    });

/// Helper provider to get all current schedules (medication + fluid)
///
/// Combines medication schedules and fluid schedule into a single list
/// for easier iteration when querying historical data.
final allSchedulesProvider = Provider<List<Schedule>>((ref) {
  final medSchedules = ref.watch(medicationSchedulesProvider) ?? [];
  final fluidSchedule = ref.watch(fluidScheduleProvider);

  return [
    ...medSchedules,
    if (fluidSchedule != null) fluidSchedule,
  ];
});
