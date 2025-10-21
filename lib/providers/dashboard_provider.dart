import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/home/models/dashboard_state.dart';
import 'package:hydracat/features/home/models/pending_fluid_treatment.dart';
import 'package:hydracat/features/home/models/pending_treatment.dart';
import 'package:hydracat/features/logging/models/daily_summary_cache.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';

/// Notifier class for managing dashboard state
///
/// Aggregates schedule data from ProfileProvider and logged session data
/// from DailySummaryCache to compute pending treatments for today's dashboard.
/// This enables zero-read dashboard display by performing all calculations
/// client-side.
class DashboardNotifier extends StateNotifier<DashboardState> {
  /// Creates a [DashboardNotifier] with the provided ref
  DashboardNotifier(this._ref)
    : super(const DashboardState(pendingMedications: [], isLoading: true)) {
    // Watch dependencies and rebuild state when they change
    _ref
      ..listen<ProfileState>(profileProvider, (_, _) => _rebuildState())
      ..listen<DailySummaryCache?>(
        dailyCacheProvider,
        (_, _) => _rebuildState(),
      );

    // Build initial state
    _rebuildState();
  }

  final Ref _ref;

  /// Rebuild the dashboard state from current provider data
  void _rebuildState() {
    try {
      final profileState = _ref.read(profileProvider);
      final cache = _ref.read(dailyCacheProvider);
      final now = DateTime.now();

      // Collect all active schedules for today
      final activeSchedules = <Schedule>[];

      // Add fluid schedule if active and has reminder today
      if (profileState.fluidSchedule != null &&
          profileState.fluidSchedule!.isActive &&
          profileState.fluidSchedule!.hasReminderTimeToday(now)) {
        activeSchedules.add(profileState.fluidSchedule!);
      }

      // Add medication schedules if active and have reminder today
      if (profileState.medicationSchedules != null) {
        for (final schedule in profileState.medicationSchedules!) {
          if (schedule.isActive && schedule.hasReminderTimeToday(now)) {
            activeSchedules.add(schedule);
          }
        }
      }

      // Calculate pending medications
      final pendingMeds = <PendingTreatment>[];
      for (final schedule in activeSchedules) {
        if (schedule.isMedication) {
          // For each medication, check each reminder time for today
          for (final reminderTime in schedule.todaysReminderTimes(now)) {
            if (!_isMedicationCompleted(schedule, reminderTime, cache)) {
              pendingMeds.add(
                PendingTreatment(
                  schedule: schedule,
                  scheduledTime: reminderTime,
                  isOverdue: _isOverdue(reminderTime, now),
                ),
              );
            }
          }
        }
      }

      // Calculate pending fluid
      PendingFluidTreatment? pendingFluid;
      final fluidSchedule = activeSchedules
          .where((s) => s.isFluidTherapy)
          .firstOrNull;
      if (fluidSchedule != null) {
        final remaining = _calculateRemainingVolume(fluidSchedule, cache, now);
        if (remaining > 0) {
          final todaysTimes = fluidSchedule.todaysReminderTimes(now).toList();
          pendingFluid = PendingFluidTreatment(
            schedule: fluidSchedule,
            remainingVolume: remaining,
            scheduledTimes: todaysTimes,
            hasOverdueTimes: todaysTimes.any((t) => _isOverdue(t, now)),
          );
        }
      }

      // Update state with calculated pending treatments
      state = DashboardState(
        pendingMedications: pendingMeds,
        pendingFluid: pendingFluid,
      );
    } on Object catch (e, stackTrace) {
      // Log error and set error state
      debugPrint('Error rebuilding dashboard state: $e');
      debugPrint('Stack trace: $stackTrace');
      state = DashboardState(
        pendingMedications: const [],
        errorMessage: 'Failed to load dashboard: $e',
      );
    }
  }

  /// Check if a medication has been completed for the given reminder time
  ///
  /// Uses the DailySummaryCache with ±2h time window matching to determine
  /// if this medication has been logged near the scheduled time.
  bool _isMedicationCompleted(
    Schedule schedule,
    DateTime reminderTime,
    DailySummaryCache? cache,
  ) {
    if (cache == null) return false;

    // Use cache's built-in time-window matching (±2h)
    return cache.hasMedicationLoggedNear(
      schedule.medicationName!,
      reminderTime,
    );
  }

  /// Calculate remaining fluid volume for today
  ///
  /// Aggregates today's scheduled volume across all reminder times,
  /// then subtracts total logged volume from cache.
  double _calculateRemainingVolume(
    Schedule schedule,
    DailySummaryCache? cache,
    DateTime now,
  ) {
    // Count today's sessions using Schedule extension
    final sessionsToday = schedule.todaysReminderTimes(now).length;

    // Calculate total scheduled volume for today
    final perSession = schedule.targetVolume ?? 0.0;
    final totalScheduled = perSession * sessionsToday;

    // Get total logged volume from cache
    final totalLogged = cache?.totalFluidVolumeGiven ?? 0.0;

    // Calculate remaining (never negative)
    final remaining = totalScheduled - totalLogged;
    return remaining > 0 ? remaining : 0;
  }

  /// Check if a scheduled time is overdue
  ///
  /// Returns true if the scheduled time is more than 2 hours in the past.
  /// This matches the time window used for completion detection.
  bool _isOverdue(DateTime scheduledTime, DateTime now) {
    final difference = now.difference(scheduledTime);
    return difference.inHours > 2;
  }

  /// Confirm a medication treatment
  ///
  /// Optimistically removes from pending list, logs the session with scheduled
  /// values, and tracks analytics. Reverts on error.
  Future<void> confirmMedicationTreatment(PendingTreatment treatment) async {
    try {
      // Get current user and pet
      final user = _ref.read(currentUserProvider);
      final pet = _ref.read(primaryPetProvider);

      if (user == null || pet == null) {
        throw Exception('User or pet not found');
      }

      // Get active medication schedules for today
      final profileState = _ref.read(profileProvider);
      final now = DateTime.now();
      final todaysSchedules =
          profileState.medicationSchedules
              ?.where((s) => s.isActive && s.hasReminderTimeToday(now))
              .toList() ??
          [];

      // 1. Optimistic update - remove from pending list
      state = state.copyWith(
        pendingMedications: state.pendingMedications
            .where((t) => t != treatment)
            .toList(),
      );

      // 2. Create medication session
      final session = MedicationSession.create(
        petId: pet.id,
        userId: user.id,
        dateTime: DateTime.now(), // Current time, not scheduled time
        medicationName: treatment.schedule.medicationName!,
        dosageGiven: treatment.schedule.targetDosage!,
        dosageScheduled: treatment.schedule.targetDosage!,
        medicationUnit: treatment.schedule.medicationUnit!,
        completed: true,
        medicationStrengthAmount: treatment.schedule.medicationStrengthAmount,
        medicationStrengthUnit: treatment.schedule.medicationStrengthUnit,
        customMedicationStrengthUnit:
            treatment.schedule.customMedicationStrengthUnit,
        scheduleId: treatment.schedule.id,
        scheduledTime: treatment.scheduledTime,
      );

      // 3. Log via LoggingProvider
      await _ref
          .read(loggingProvider.notifier)
          .logMedicationSession(
            session: session,
            todaysSchedules: todaysSchedules,
          );

      // 4. Track analytics
      await _ref
          .read(analyticsServiceDirectProvider)
          .trackSessionLogged(
            treatmentType: 'medication',
            sessionCount: 1,
            isQuickLog: false,
            adherenceStatus: 'on_time',
            medicationName: treatment.schedule.medicationName,
            source: 'dashboard',
          );
    } catch (e) {
      // Revert optimistic update on error
      debugPrint('Error confirming medication treatment: $e');
      _rebuildState();
      rethrow;
    }
  }

  /// Skip a medication treatment
  ///
  /// Optimistically removes from pending list, logs as skipped (dosageGiven: 0,
  /// completed: false), and tracks analytics. Reverts on error.
  Future<void> skipMedicationTreatment(PendingTreatment treatment) async {
    try {
      // Get current user and pet
      final user = _ref.read(currentUserProvider);
      final pet = _ref.read(primaryPetProvider);

      if (user == null || pet == null) {
        throw Exception('User or pet not found');
      }

      // Get active medication schedules for today
      final profileState = _ref.read(profileProvider);
      final now = DateTime.now();
      final todaysSchedules =
          profileState.medicationSchedules
              ?.where((s) => s.isActive && s.hasReminderTimeToday(now))
              .toList() ??
          [];

      // 1. Optimistic update
      state = state.copyWith(
        pendingMedications: state.pendingMedications
            .where((t) => t != treatment)
            .toList(),
      );

      // 2. Create skipped medication session (dosageGiven: 0, completed: false)
      final session = MedicationSession.create(
        petId: pet.id,
        userId: user.id,
        dateTime: DateTime.now(),
        medicationName: treatment.schedule.medicationName!,
        dosageGiven: 0,
        dosageScheduled: treatment.schedule.targetDosage!,
        medicationUnit: treatment.schedule.medicationUnit!,
        completed: false,
        medicationStrengthAmount: treatment.schedule.medicationStrengthAmount,
        medicationStrengthUnit: treatment.schedule.medicationStrengthUnit,
        customMedicationStrengthUnit:
            treatment.schedule.customMedicationStrengthUnit,
        scheduleId: treatment.schedule.id,
        scheduledTime: treatment.scheduledTime,
      );

      // 3. Log via LoggingProvider
      await _ref
          .read(loggingProvider.notifier)
          .logMedicationSession(
            session: session,
            todaysSchedules: todaysSchedules,
          );

      // 4. Track analytics
      await _ref
          .read(analyticsServiceDirectProvider)
          .trackSessionLogged(
            treatmentType: 'medication',
            sessionCount: 1,
            isQuickLog: false,
            adherenceStatus: 'skipped',
            medicationName: treatment.schedule.medicationName,
            source: 'dashboard',
          );
    } catch (e) {
      debugPrint('Error skipping medication treatment: $e');
      _rebuildState();
      rethrow;
    }
  }

  /// Confirm fluid therapy
  ///
  /// Optimistically removes from pending, logs the entire remaining volume,
  /// and tracks analytics. Reverts on error.
  Future<void> confirmFluidTreatment(PendingFluidTreatment fluid) async {
    try {
      // Get current user and pet
      final user = _ref.read(currentUserProvider);
      final pet = _ref.read(primaryPetProvider);

      if (user == null || pet == null) {
        throw Exception('User or pet not found');
      }

      // 1. Optimistic update - clear pending fluid
      // Note: We need to rebuild entire state to set pendingFluid to null
      state = DashboardState(
        pendingMedications: state.pendingMedications,
        errorMessage: state.errorMessage,
      );

      // 2. Create fluid session with entire remaining volume
      final session = FluidSession.create(
        petId: pet.id,
        userId: user.id,
        dateTime: DateTime.now(),
        volumeGiven: fluid.remainingVolume,
      );

      // 3. Log via LoggingProvider
      await _ref
          .read(loggingProvider.notifier)
          .logFluidSession(
            session: session,
            fluidSchedule: fluid.schedule,
          );

      // 4. Track analytics
      await _ref
          .read(analyticsServiceDirectProvider)
          .trackSessionLogged(
            treatmentType: 'fluid',
            sessionCount: 1,
            isQuickLog: false,
            adherenceStatus: 'on_time',
            volumeGiven: fluid.remainingVolume,
            source: 'dashboard',
          );
    } catch (e) {
      debugPrint('Error confirming fluid treatment: $e');
      _rebuildState();
      rethrow;
    }
  }

  /// Force refresh the dashboard state
  ///
  /// Can be called from UI to manually refresh after operations.
  void refresh() {
    _rebuildState();
  }
}

/// Provider for dashboard state
///
/// Exposes pending treatments for today's dashboard display.
/// Automatically rebuilds when schedules or daily cache change.
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      return DashboardNotifier(ref);
    });
