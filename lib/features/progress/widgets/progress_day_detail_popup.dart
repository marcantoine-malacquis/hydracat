import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';
import 'package:hydracat/features/logging/services/session_read_service.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:hydracat/shared/widgets/fluid/fluid_daily_summary_card.dart';
import 'package:intl/intl.dart';

/// Full-screen popup showing treatment details for a specific day.
///
/// Displays either:
/// - Logged sessions (past/today): actual treatment data from Firestore
/// - Planned schedules (future): expected treatments based on schedules
///
/// Uses [OverlayService.showFullScreenPopup] with slideUp animation.
class ProgressDayDetailPopup extends ConsumerWidget {
  /// Creates a progress day detail popup.
  const ProgressDayDetailPopup({
    required this.date,
    super.key,
  });

  /// The date to display details for.
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Compare by normalized day so "today" is not misclassified as future
    final day = AppDateUtils.startOfDay(date);
    final today = AppDateUtils.startOfDay(DateTime.now());
    final isFuture = day.isAfter(today);
    final mediaQuery = MediaQuery.of(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          liveRegion: true,
          label: _buildSemanticLabel(),
          child: Container(
            margin: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: mediaQuery.padding.bottom + AppSpacing.sm,
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            constraints: BoxConstraints(
              maxHeight: mediaQuery.size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: AppSpacing.md),
                  _buildSummaryPills(context, ref),
                  const SizedBox(height: AppSpacing.md),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildContent(context, ref, isFuture),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the header with date and close button.
  Widget _buildHeader(BuildContext context) {
    final formattedDate = DateFormat('EEEE, MMMM d').format(date);

    return Row(
      children: [
        Expanded(
          child: Text(
            formattedDate,
            style: AppTextStyles.h2,
          ),
        ),
        const SizedBox(
          width: AppSpacing.minTouchTarget,
          height: AppSpacing.minTouchTarget,
          child: IconButton(
            icon: Icon(Icons.close),
            onPressed: OverlayService.hide,
            tooltip: 'Close',
            iconSize: 24,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  /// Builds summary pills showing treatment completion status.
  Widget _buildSummaryPills(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final pet = ref.watch(primaryPetProvider);

    if (user == null || pet == null) return const SizedBox.shrink();

    // Get schedules to compute expected counts
    final medSchedules = ref.watch(medicationSchedulesProvider) ?? [];
    final fluidSchedule = ref.watch(fluidScheduleProvider);

    // Filter medication schedules only
    final medicationSchedules = medSchedules
        .where((s) => s.treatmentType == TreatmentType.medication)
        .toList();

    final scheduledMedCount = medicationSchedules.fold<int>(
      0,
      (sum, s) => sum + s.reminderTimesOnDate(date).length,
    );
    final scheduledFluidCount =
        fluidSchedule?.reminderTimesOnDate(date).length ?? 0;

    // Get summary for actual counts (past/today only)
    final summaryAsync = ref.watch(
      weekSummariesProvider(AppDateUtils.startOfWeekMonday(date)),
    );

    return summaryAsync.when(
      data: (summaries) {
        final summary = summaries[AppDateUtils.startOfDay(date)];
        return _buildPills(
          scheduledMedCount,
          scheduledFluidCount,
          summary?.medicationTotalDoses ?? 0,
          summary?.fluidSessionCount ?? 0,
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  /// Builds the pill widgets for summary display.
  Widget _buildPills(
    int scheduledMed,
    int scheduledFluid,
    int actualMed,
    int actualFluid,
  ) {
    if (scheduledMed == 0 && scheduledFluid == 0) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        if (scheduledMed > 0)
          _buildPill('Medication: $actualMed of $scheduledMed doses'),
        if (scheduledFluid > 0)
          _buildPill('Fluid: $actualFluid of $scheduledFluid sessions'),
      ],
    );
  }

  /// Builds a single pill widget.
  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: AppTextStyles.caption),
    );
  }

  /// Builds the content section based on date (logged vs planned).
  Widget _buildContent(BuildContext context, WidgetRef ref, bool isFuture) {
    if (isFuture) {
      return _buildPlannedView(context, ref);
    } else {
      // For past/today, render planned view enriched with completion status
      return _buildPlannedWithStatus(context, ref);
    }
  }

  // Old logged view kept for reference behind dev flag if needed.

  // Session tiles for the legacy logged view were removed.

  /// Builds the planned view showing expected treatments.
  Widget _buildPlannedView(BuildContext context, WidgetRef ref) {
    final medSchedules = ref.watch(medicationSchedulesProvider) ?? [];
    final fluidSchedule = ref.watch(fluidScheduleProvider);

    // Filter medication schedules only
    final medicationSchedules = medSchedules
        .where((s) => s.treatmentType == TreatmentType.medication)
        .toList();

    final medReminders = <(Schedule, DateTime)>[];
    for (final schedule in medicationSchedules) {
      for (final time in schedule.reminderTimesOnDate(date)) {
        medReminders.add((schedule, time));
      }
    }

    final fluidReminders = fluidSchedule != null
        ? fluidSchedule.reminderTimesOnDate(date)
        : <DateTime>[];

    if (medReminders.isEmpty && fluidReminders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Text('No treatments scheduled for this day'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _maybeSummaryCard(context, ref),
        if (medReminders.isNotEmpty || fluidReminders.isNotEmpty)
          const SizedBox(height: AppSpacing.md),
        if (medReminders.isNotEmpty) ...[
          const Text('Planned Medications', style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.xs),
          ...medReminders.map((r) => _buildPlannedMedicationTile(r.$1, r.$2)),
        ],
        if (medReminders.isNotEmpty && fluidReminders.isNotEmpty)
          const SizedBox(height: AppSpacing.md),
        if (fluidReminders.isNotEmpty) ...[
          const Text('Planned Fluid Therapy', style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.xs),
          ...fluidReminders.map(
            (time) => _buildPlannedFluidTile(fluidSchedule!, time),
          ),
        ],
      ],
    );
  }

  /// Builds the planned view but enriched with completion state for past/today.
  ///
  /// Fetches the day's sessions once (meds + fluids in parallel) and marks
  /// planned reminders as completed when matching sessions exist. Also computes
  /// the total fluid administered that day and shows it as the fluid title.
  Widget _buildPlannedWithStatus(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final pet = ref.watch(primaryPetProvider);

    if (user == null || pet == null) {
      return const Text('User or pet not found');
    }

    final medSchedules = ref.watch(medicationSchedulesProvider) ?? [];
    final fluidSchedule = ref.watch(fluidScheduleProvider);

    // Filter medication schedules only
    final medicationSchedules = medSchedules
        .where((s) => s.treatmentType == TreatmentType.medication)
        .toList();

    final medReminders = <(Schedule, DateTime)>[];
    for (final schedule in medicationSchedules) {
      for (final time in schedule.reminderTimesOnDate(date)) {
        medReminders.add((schedule, time));
      }
    }

    final fluidReminders = fluidSchedule != null
        ? fluidSchedule.reminderTimesOnDate(date).toList()
        : <DateTime>[];

    if (medReminders.isEmpty && fluidReminders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Text('No treatments scheduled for this day'),
      );
    }

    final service = ref.read(sessionReadServiceProvider);

    return FutureBuilder(
      future: service.getAllSessionsForDate(
        userId: user.id,
        petId: pet.id,
        date: date,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Error loading sessions: ${snapshot.error}',
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }

        final (medSessions, fluidSessions) = snapshot.data!;

        // Greedy match: scheduleId-first, then name-based within the day.
        final completedReminderTimes = _matchMedicationRemindersToSessions(
          reminders: medReminders,
          sessions: medSessions,
        );

        final totalFluidMl = fluidSessions.fold<double>(
          0,
          (sum, s) => sum + s.volumeGiven,
        );
        final hasAnyFluid = fluidSessions.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _maybeSummaryCard(context, ref),
            const SizedBox(height: AppSpacing.md),
            if (medReminders.isNotEmpty) ...[
              const Text('Planned Medications', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.xs),
              ...medReminders.map(
                (r) => _buildPlannedMedicationTile(
                  r.$1,
                  r.$2,
                  completed: completedReminderTimes.contains(r.$2),
                ),
              ),
            ],
            if (medReminders.isNotEmpty && fluidReminders.isNotEmpty)
              const SizedBox(height: AppSpacing.md),
            if (fluidReminders.isNotEmpty) ...[
              const Text('Planned Fluid Therapy', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.xs),
              ...fluidReminders.map(
                (time) => _buildPlannedFluidTile(
                  fluidSchedule!,
                  time,
                  totalFluidMl: totalFluidMl,
                  completed: hasAnyFluid,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // Legacy schedule key helper removed with new greedy matcher.

  /// Greedy matcher to determine which medication reminder times are completed
  /// by sessions for the selected day. Prefers scheduleId matches and consumes
  /// sessions so each can satisfy at most one reminder.
  Set<DateTime> _matchMedicationRemindersToSessions({
    required List<(Schedule, DateTime)> reminders,
    required List<MedicationSession> sessions,
  }) {
    if (reminders.isEmpty || sessions.isEmpty) return <DateTime>{};

    final day = AppDateUtils.startOfDay(date);
    final nextDay = AppDateUtils.endOfDay(date);

    // Split sessions by having scheduleId (preferred) vs not
    final byScheduleId = <String, List<MedicationSession>>{};
    final unnamedByMed = <String, List<MedicationSession>>{};

    for (final s in sessions.where((s) => s.completed)) {
      if (s.scheduleId != null) {
        byScheduleId.putIfAbsent(s.scheduleId!, () => []).add(s);
      } else {
        final key = s.medicationName.trim().toLowerCase();
        unnamedByMed.putIfAbsent(key, () => []).add(s);
      }
    }

    // Sort each list by proximity to planned time to improve greedy match
    for (final list in byScheduleId.values) {
      list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    }
    for (final list in unnamedByMed.values) {
      list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    }

    final completed = <DateTime>{};

    // 1) scheduleId-first greedy match
    for (final (schedule, plannedTime) in reminders) {
      final list = byScheduleId[schedule.id];
      if (list == null || list.isEmpty) continue;

      // pick nearest unused session on the same day
      MedicationSession? best;
      var bestDelta = 1 << 30;
      for (final s in list) {
        if (s.dateTime.isBefore(day) || s.dateTime.isAfter(nextDay)) continue;
        final delta = s.dateTime.difference(plannedTime).inSeconds.abs();
        if (delta < bestDelta) {
          best = s;
          bestDelta = delta;
        }
      }
      if (best != null) {
        completed.add(plannedTime);
        list.remove(best); // consume session
      }
    }

    // 2) Fallback: name-based match for remaining
    for (final (schedule, plannedTime) in reminders) {
      if (completed.contains(plannedTime)) continue;
      final key = (schedule.medicationName ?? '').trim().toLowerCase();
      final list = unnamedByMed[key];
      if (list == null || list.isEmpty) continue;

      MedicationSession? best;
      var bestDelta = 1 << 30;
      for (final s in list) {
        if (s.dateTime.isBefore(day) || s.dateTime.isAfter(nextDay)) continue;
        final delta = s.dateTime.difference(plannedTime).inSeconds.abs();
        if (delta < bestDelta) {
          best = s;
          bestDelta = delta;
        }
      }
      if (best != null) {
        completed.add(plannedTime);
        list.remove(best);
      }
    }

    return completed;
  }

  /// Builds a tile for a planned medication.
  Widget _buildPlannedMedicationTile(
    Schedule schedule,
    DateTime time, {
    bool completed = false,
  }) {
    final timeStr = DateFormat.jm().format(time);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.medication,
        color: AppColors.textSecondary,
        size: 24,
      ),
      title: Text(
        schedule.medicationName!,
        style: AppTextStyles.body,
      ),
      subtitle: Text(
        '$timeStr • ${schedule.targetDosage} ${schedule.medicationUnit}',
        style: AppTextStyles.caption,
      ),
      trailing: completed
          ? Semantics(
              label: 'Completed',
              child: const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 28,
              ),
            )
          : null,
    );
  }

  /// Builds a tile for planned fluid therapy.
  Widget _buildPlannedFluidTile(
    Schedule schedule,
    DateTime time, {
    double? totalFluidMl,
    bool completed = false,
  }) {
    final timeStr = DateFormat.jm().format(time);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.water_drop,
        color: AppColors.textSecondary,
        size: 24,
      ),
      title: Text(
        totalFluidMl != null
            ? '${totalFluidMl.toStringAsFixed(1)}ml'
            : '${schedule.targetVolume}ml',
        style: AppTextStyles.body,
      ),
      subtitle: Text(
        timeStr,
        style: AppTextStyles.caption,
      ),
      trailing: completed
          ? Semantics(
              label: 'Completed',
              child: const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 28,
              ),
            )
          : null,
    );
  }

  /// Builds the fluid summary card when data is available.
  Widget _maybeSummaryCard(BuildContext context, WidgetRef ref) {
    final view = ref.watch(
      fluidDailySummaryViewProvider(AppDateUtils.startOfDay(date)),
    );

    if (view == null) return const SizedBox.shrink();

    return FluidDailySummaryCard(summary: view);
  }

  /// Builds the semantic label for accessibility.
  String _buildSemanticLabel() {
    final formattedDate = DateFormat('EEEE, MMMM d').format(date);
    return 'Treatment details for $formattedDate';
  }
}

/// Shows the progress day detail popup with blur background.
///
/// Displays treatment details for the specified [date].
/// Uses slideUp animation and is dismissible by tapping background or close
/// button.
///
/// Example:
/// ```dart
/// showProgressDayDetailPopup(context, DateTime(2025, 10, 15));
/// ```
void showProgressDayDetailPopup(BuildContext context, DateTime date) {
  OverlayService.showFullScreenPopup(
    context: context,
    child: ProgressDayDetailPopup(date: date),
  );
}
