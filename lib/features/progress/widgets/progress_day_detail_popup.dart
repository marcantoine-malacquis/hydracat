import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/logging/widgets/injection_site_selector.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/features/logging/widgets/stress_level_selector.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/profile/models/schedule_history_entry.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/progress_edit_provider.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:hydracat/providers/schedule_history_provider.dart';
import 'package:hydracat/shared/widgets/fluid/fluid_daily_summary_card.dart';
import 'package:hydracat/shared/widgets/inputs/volume_input_adjuster.dart';
import 'package:hydracat/shared/widgets/widgets.dart';
import 'package:intl/intl.dart';

/// Popup content mode for transitioning between views
enum _PopupMode {
  /// Showing day detail with list of treatments
  dayView,

  /// Editing a medication session
  editMedication,

  /// Editing a fluid session
  editFluid,
}

/// Bottom sheet popup showing treatment details for a specific day.
///
/// Displays either:
/// - Logged sessions (past/today): actual treatment data from Firestore
/// - Planned schedules (future): expected treatments based on schedules
///
/// Uses [showHydraBottomSheet] with standard bottom sheet animation.
class ProgressDayDetailPopup extends ConsumerStatefulWidget {
  /// Creates a progress day detail popup.
  const ProgressDayDetailPopup({
    required this.date,
    super.key,
  });

  /// The date to display details for.
  final DateTime date;

  @override
  ConsumerState<ProgressDayDetailPopup> createState() =>
      _ProgressDayDetailPopupState();
}

/// State for [ProgressDayDetailPopup].
class _ProgressDayDetailPopupState
    extends ConsumerState<ProgressDayDetailPopup> {
  // Popup mode state
  _PopupMode _mode = _PopupMode.dayView;
  MedicationSession? _editingMedicationSession;
  Schedule? _editingSchedule;
  FluidSession? _editingFluidSession;

  @override
  Widget build(BuildContext context) {
    // Compare by normalized day so "today" is not misclassified as future
    final day = AppDateUtils.startOfDay(widget.date);
    final today = AppDateUtils.startOfDay(DateTime.now());
    final isFuture = day.isAfter(today);

    final formattedDate = DateFormat('EEEE, MMMM d').format(widget.date);
    final isEditMode = _mode != _PopupMode.dayView;

    return Semantics(
      liveRegion: true,
      label: _buildSemanticLabel(),
      child: LoggingPopupWrapper(
        title: isEditMode ? 'Edit Treatment' : formattedDate,
        headerContent: isEditMode
            ? null
            : _buildCenteredDateHeader(context, formattedDate),
        leading: isEditMode
            ? HydraBackButton(
                onPressed: _handleEditCancel,
              )
            : null,
        showCloseButton: !isEditMode,
        onDismiss: () {
          // No special cleanup needed
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _buildCurrentContent(context, ref, isFuture),
        ),
      ),
    );
  }

  /// Builds a centered date header that accounts for the close button.
  Widget _buildCenteredDateHeader(BuildContext context, String formattedDate) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        formattedDate,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  /// Builds a section header with title and count badge.
  Widget _buildSectionHeader(String title, String count) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.h3),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  /// Build content based on current mode
  Widget _buildCurrentContent(
    BuildContext context,
    WidgetRef ref,
    bool isFuture,
  ) {
    return switch (_mode) {
      _PopupMode.dayView => Column(
        key: const ValueKey('dayView'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
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
      _PopupMode.editMedication => _buildMedicationEditContent(context),
      _PopupMode.editFluid => _buildFluidEditContent(context),
    };
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
      for (final time in schedule.reminderTimesOnDate(widget.date)) {
        medReminders.add((schedule, time));
      }
    }

    final fluidReminders = fluidSchedule != null
        ? fluidSchedule.reminderTimesOnDate(widget.date)
        : <DateTime>[];

    if (medReminders.isEmpty && fluidReminders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Text('No treatments scheduled for this day'),
      );
    }

    final showFluidSection = fluidReminders.isNotEmpty;

    // Calculate counts for headers (future dates have 0 actual, show as 0 of X)
    final scheduledFluidCount = fluidReminders.length;
    final scheduledMedCount = medReminders.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showFluidSection) ...[
          _buildSectionHeader(
            'Fluid therapy',
            '0 of $scheduledFluidCount sessions',
          ),
          const SizedBox(height: AppSpacing.xs),
          _maybeSummaryCard(context, ref),
          if (fluidReminders.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            ...fluidReminders.map(
              (time) => _buildPlannedFluidTile(fluidSchedule!, time),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
        ],

        if (medReminders.isNotEmpty) ...[
          _buildSectionHeader(
            'Medications',
            '0 of $scheduledMedCount doses',
          ),
          const SizedBox(height: AppSpacing.xs),
          ...medReminders.map((r) => _buildPlannedMedicationTile(r.$1, r.$2)),
        ],
      ],
    );
  }

  /// Builds the planned view but enriched with completion state for past/today.
  ///
  /// Uses cached week sessions from [weekSessionsProvider] for instant loading.
  /// Falls back to on-demand fetch if cache unavailable.
  Widget _buildPlannedWithStatus(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final pet = ref.watch(primaryPetProvider);

    if (user == null || pet == null) {
      return const Text('User or pet not found');
    }

    final day = AppDateUtils.startOfDay(widget.date);
    final today = AppDateUtils.startOfDay(DateTime.now());
    final isFutureOrToday = day.isAfter(today) || day.isAtSameMomentAs(today);

    // For today and future: use current schedules
    if (isFutureOrToday) {
      return _buildWithCurrentSchedules(context, ref);
    }

    // For past dates: use historical schedules
    final historicalSchedulesAsync = ref.watch(
      scheduleHistoryForDateProvider(widget.date),
    );

    return historicalSchedulesAsync.when(
      data: (historicalMap) {
        // If no history found, fall back to current schedules (backward compat)
        if (historicalMap.isEmpty) {
          return _buildWithCurrentSchedules(context, ref);
        }

        return _buildWithHistoricalData(context, ref, historicalMap);
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) {
        // On error, fall back to current schedules
        return _buildWithCurrentSchedules(context, ref);
      },
    );
  }

  /// Build day view with current schedules (for today and future dates)
  Widget _buildWithCurrentSchedules(BuildContext context, WidgetRef ref) {
    final medSchedules = ref.watch(medicationSchedulesProvider) ?? [];
    final fluidSchedule = ref.watch(fluidScheduleProvider);

    // Filter medication schedules only
    final medicationSchedules = medSchedules
        .where((s) => s.treatmentType == TreatmentType.medication)
        .toList();

    final medReminders = <(Schedule, DateTime)>[];
    for (final schedule in medicationSchedules) {
      for (final time in schedule.reminderTimesOnDate(widget.date)) {
        medReminders.add((schedule, time));
      }
    }

    final fluidReminders = fluidSchedule != null
        ? fluidSchedule.reminderTimesOnDate(widget.date).toList()
        : <DateTime>[];

    if (medReminders.isEmpty && fluidReminders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Text('No treatments scheduled for this day'),
      );
    }

    // Fetch from week cache
    final weekStart = AppDateUtils.startOfWeekMonday(widget.date);
    final weekSessionsAsync = ref.watch(weekSessionsProvider(weekStart));

    return weekSessionsAsync.when(
      data: (weekSessions) {
        // Normalize date to match map keys (which are always start-of-day)
        final normalizedDate = AppDateUtils.startOfDay(widget.date);
        final (medSessions, fluidSessions) =
            weekSessions[normalizedDate] ??
            (<MedicationSession>[], <FluidSession>[]);

        // Greedy match: scheduleId-first, then name-based within the day.
        final completedReminderTimes = _matchMedicationRemindersToSessions(
          reminders: medReminders,
          sessions: medSessions,
        );

        // Build map of reminder times to actual sessions
        final reminderToSession = _mapRemindersToSessions(
          reminders: medReminders,
          sessions: medSessions,
        );

        final hasAnyFluid = fluidSessions.isNotEmpty;

        final showFluidSection = hasAnyFluid || fluidReminders.isNotEmpty;

        // Calculate counts for headers
        final scheduledFluidCount = fluidReminders.length;
        // Count as 1 if any fluid given
        final actualFluidCount = hasAnyFluid ? 1 : 0;
        final scheduledMedCount = medReminders.length;
        final actualMedCount = completedReminderTimes.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showFluidSection) ...[
              _buildSectionHeader(
                'Fluid therapy',
                '$actualFluidCount of $scheduledFluidCount sessions',
              ),
              const SizedBox(height: AppSpacing.xs),
              _maybeSummaryCard(context, ref),
              const SizedBox(height: AppSpacing.sm),
              // Show logged sessions
              ..._buildFluidSessionsList(fluidSessions),
              // Show scheduled but unlogged reminders
              if (fluidSessions.isEmpty && fluidReminders.isNotEmpty)
                ...fluidReminders.map(
                  (time) => _buildUnloggedFluidTile(fluidSchedule!, time),
                ),
              const SizedBox(height: AppSpacing.md),
            ],

            if (medReminders.isNotEmpty) ...[
              _buildSectionHeader(
                'Medications',
                '$actualMedCount of $scheduledMedCount doses',
              ),
              const SizedBox(height: AppSpacing.xs),
              ...medReminders.map(
                (r) => _buildPlannedMedicationTile(
                  r.$1,
                  r.$2,
                  completed: completedReminderTimes.contains(r.$2),
                  session: reminderToSession[r.$2],
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Error loading sessions: $error',
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () {
                // Retry by invalidating the provider
                ref.invalidate(weekSessionsProvider(weekStart));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
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

    final day = AppDateUtils.startOfDay(widget.date);
    final nextDay = AppDateUtils.endOfDay(widget.date);

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

  /// Build day view with historical schedules (for past dates)
  Widget _buildWithHistoricalData(
    BuildContext context,
    WidgetRef ref,
    Map<String, ScheduleHistoryEntry> historicalMap,
  ) {
    final user = ref.watch(currentUserProvider);
    final pet = ref.watch(primaryPetProvider);

    if (user == null || pet == null) {
      return const Text('User or pet not found');
    }

    // Build reminders from historical entries
    final medReminders = <(ScheduleHistoryEntry, DateTime)>[];
    ScheduleHistoryEntry? fluidHistoricalSchedule;

    for (final entry in historicalMap.values) {
      final reminderTimes = entry.getReminderTimesForDate(widget.date);

      if (entry.treatmentType == TreatmentType.medication) {
        for (final time in reminderTimes) {
          medReminders.add((entry, time));
        }
      } else if (entry.treatmentType == TreatmentType.fluid) {
        fluidHistoricalSchedule = entry;
      }
    }

    final fluidReminders = fluidHistoricalSchedule != null
        ? fluidHistoricalSchedule.getReminderTimesForDate(widget.date)
        : <DateTime>[];

    if (medReminders.isEmpty && fluidReminders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Text('No treatments scheduled for this day'),
      );
    }

    // Fetch sessions for completion status
    final weekStart = AppDateUtils.startOfWeekMonday(widget.date);
    final weekSessionsAsync = ref.watch(weekSessionsProvider(weekStart));

    return weekSessionsAsync.when(
      data: (weekSessions) {
        final normalizedDate = AppDateUtils.startOfDay(widget.date);
        final (medSessions, fluidSessions) =
            weekSessions[normalizedDate] ??
            (<MedicationSession>[], <FluidSession>[]);

        // Match sessions to historical reminders
        final completedReminderTimes = _matchHistoricalMedicationReminders(
          reminders: medReminders,
          sessions: medSessions,
        );

        final hasAnyFluid = fluidSessions.isNotEmpty;
        final showFluidSection = hasAnyFluid || fluidReminders.isNotEmpty;

        final scheduledFluidCount = fluidReminders.length;
        final actualFluidCount = hasAnyFluid ? 1 : 0;
        final scheduledMedCount = medReminders.length;
        final actualMedCount = completedReminderTimes.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showFluidSection) ...[
              _buildSectionHeader(
                'Fluid therapy',
                '$actualFluidCount of $scheduledFluidCount sessions',
              ),
              const SizedBox(height: AppSpacing.xs),
              _maybeSummaryCard(context, ref),
              if (fluidReminders.isNotEmpty &&
                  fluidHistoricalSchedule != null) ...[
                const SizedBox(height: AppSpacing.xs),
                ...fluidReminders.map(
                  (time) => _buildHistoricalFluidTile(
                    fluidHistoricalSchedule!,
                    time,
                    completed: hasAnyFluid,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
            ],
            if (medReminders.isNotEmpty) ...[
              _buildSectionHeader(
                'Medications',
                '$actualMedCount of $scheduledMedCount doses',
              ),
              const SizedBox(height: AppSpacing.xs),
              ...medReminders.map(
                (r) => _buildHistoricalMedicationTile(
                  r.$1,
                  r.$2,
                  completed: completedReminderTimes.contains(r.$2),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          'Error loading sessions: $error',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  /// Matcher for historical medication reminders
  Set<DateTime> _matchHistoricalMedicationReminders({
    required List<(ScheduleHistoryEntry, DateTime)> reminders,
    required List<MedicationSession> sessions,
  }) {
    if (reminders.isEmpty || sessions.isEmpty) return <DateTime>{};

    final day = AppDateUtils.startOfDay(widget.date);
    final nextDay = AppDateUtils.endOfDay(widget.date);

    // Group by medication name
    final byMedName = <String, List<MedicationSession>>{};

    for (final s in sessions.where((s) => s.completed)) {
      final key = s.medicationName.trim().toLowerCase();
      byMedName.putIfAbsent(key, () => []).add(s);
    }

    for (final list in byMedName.values) {
      list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    }

    final completed = <DateTime>{};

    for (final (entry, plannedTime) in reminders) {
      final medName = entry.medicationName?.trim().toLowerCase();
      if (medName == null) continue;

      final list = byMedName[medName];
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

  /// Builds a tile for historical medication data
  Widget _buildHistoricalMedicationTile(
    ScheduleHistoryEntry entry,
    DateTime time, {
    bool completed = false,
  }) {
    final timeStr = DateFormat.jm().format(time);
    final day = AppDateUtils.startOfDay(widget.date);
    final today = AppDateUtils.startOfDay(DateTime.now());
    final isFuture = day.isAfter(today);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.medication,
        color: AppColors.textSecondary,
        size: 24,
      ),
      title: Text(
        entry.medicationName ?? 'Medication',
        style: AppTextStyles.body,
      ),
      subtitle: Text(
        '$timeStr • ${entry.targetDosage} ${entry.medicationUnit}',
        style: AppTextStyles.caption,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (completed)
            const Icon(
              Icons.check_circle,
              color: AppColors.primary,
              size: 28,
            )
          else if (!isFuture)
            const Icon(
              Icons.cancel,
              color: AppColors.textSecondary,
              size: 28,
            ),
        ],
      ),
    );
  }

  /// Builds a tile for historical fluid data
  Widget _buildHistoricalFluidTile(
    ScheduleHistoryEntry entry,
    DateTime time, {
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
        '${entry.targetVolume}ml',
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
                size: 24,
              ),
            )
          : null,
    );
  }

  /// Builds a tile for a planned medication.
  Widget _buildPlannedMedicationTile(
    Schedule schedule,
    DateTime time, {
    bool completed = false,
    MedicationSession? session,
  }) {
    final timeStr = DateFormat.jm().format(time);
    final day = AppDateUtils.startOfDay(widget.date);
    final today = AppDateUtils.startOfDay(DateTime.now());
    final isFuture = day.isAfter(today);
    final canEdit = !isFuture; // Show edit for all past dates

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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (completed)
            const Icon(
              Icons.check_circle,
              color: AppColors.primary,
              size: 28,
            )
          else if (!isFuture)
            const Icon(
              Icons.cancel,
              color: AppColors.textSecondary,
              size: 28,
            ),
          if (canEdit) ...[
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _handleEditMedication(
                session ?? _createTempMedicationSession(schedule, time),
                schedule,
              ),
              tooltip: 'Edit',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),
          ],
        ],
      ),
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

  /// Builds list tiles for actual fluid sessions on the selected day.
  List<Widget> _buildFluidSessionsList(List<FluidSession> sessions) {
    if (sessions.isEmpty) return const [];

    final sorted = [...sessions]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final day = AppDateUtils.startOfDay(widget.date);
    final today = AppDateUtils.startOfDay(DateTime.now());
    final isFuture = day.isAfter(today);

    return sorted.map((session) {
      final timeStr = DateFormat.jm().format(session.dateTime);
      final volumeStr = '${session.volumeGiven.toStringAsFixed(0)}ml';

      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(
          Icons.water_drop,
          color: AppColors.textSecondary,
          size: 24,
        ),
        title: Text(volumeStr, style: AppTextStyles.body),
        subtitle: Text(timeStr, style: AppTextStyles.caption),
        trailing: !isFuture
            ? IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _handleEditFluid(session),
                tooltip: 'Edit',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              )
            : null,
      );
    }).toList();
  }

  /// Build tile for scheduled but unlogged fluid session
  Widget _buildUnloggedFluidTile(Schedule schedule, DateTime time) {
    final timeStr = DateFormat.jm().format(time);
    final volumeStr = '${schedule.targetVolume}ml (scheduled)';

    final day = AppDateUtils.startOfDay(widget.date);
    final today = AppDateUtils.startOfDay(DateTime.now());
    final isFuture = day.isAfter(today);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.water_drop,
        color: AppColors.textSecondary,
        size: 24,
      ),
      title: Text(
        volumeStr,
        style: AppTextStyles.body.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      subtitle: Text(timeStr, style: AppTextStyles.caption),
      trailing: !isFuture
          ? IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _handleEditFluid(
                _createTempFluidSession(schedule, time),
              ),
              tooltip: 'Log',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            )
          : null,
    );
  }

  /// Builds the fluid summary card when data is available.
  Widget _maybeSummaryCard(BuildContext context, WidgetRef ref) {
    final view = ref.watch(
      fluidDailySummaryViewProvider(AppDateUtils.startOfDay(widget.date)),
    );

    if (view == null) return const SizedBox.shrink();

    return FluidDailySummaryCard(summary: view);
  }

  /// Map reminder times to their actual sessions for edit button access.
  ///
  /// Uses the same greedy matching logic as
  /// [_matchMedicationRemindersToSessions] but returns a map of reminder
  /// DateTime → MedicationSession for passing to the tile builder.
  Map<DateTime, MedicationSession> _mapRemindersToSessions({
    required List<(Schedule, DateTime)> reminders,
    required List<MedicationSession> sessions,
  }) {
    if (reminders.isEmpty || sessions.isEmpty) return {};

    final day = AppDateUtils.startOfDay(widget.date);
    final nextDay = AppDateUtils.endOfDay(widget.date);

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

    final map = <DateTime, MedicationSession>{};

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
        map[plannedTime] = best;
        list.remove(best); // consume session
      }
    }

    // 2) Fallback: name-based match for remaining
    for (final (schedule, plannedTime) in reminders) {
      if (map.containsKey(plannedTime)) continue;
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
        map[plannedTime] = best;
        list.remove(best);
      }
    }

    return map;
  }

  /// Build medication edit content (inline version)
  Widget _buildMedicationEditContent(BuildContext context) {
    if (_editingMedicationSession == null || _editingSchedule == null) {
      return const SizedBox.shrink();
    }

    return _MedicationEditInlineForm(
      session: _editingMedicationSession!,
      schedule: _editingSchedule!,
      onSave: _handleMedicationEditSave,
      onCancel: _handleEditCancel,
    );
  }

  /// Build fluid edit content (inline version)
  Widget _buildFluidEditContent(BuildContext context) {
    if (_editingFluidSession == null) {
      return const SizedBox.shrink();
    }

    return _FluidEditInlineForm(
      session: _editingFluidSession!,
      onSave: _handleFluidEditSave,
      onCancel: _handleEditCancel,
    );
  }

  /// Create temporary medication session for unlogged past treatments
  MedicationSession _createTempMedicationSession(
    Schedule schedule,
    DateTime scheduledTime,
  ) {
    final user = ref.read(currentUserProvider);
    final pet = ref.read(primaryPetProvider);

    return MedicationSession.create(
      petId: pet!.id,
      userId: user!.id,
      dateTime: scheduledTime,
      medicationName: schedule.medicationName!,
      dosageGiven: 0,
      dosageScheduled: schedule.targetDosage!,
      medicationUnit: schedule.medicationUnit!,
      completed: false,
      medicationStrengthAmount: schedule.medicationStrengthAmount,
      medicationStrengthUnit: schedule.medicationStrengthUnit,
      customMedicationStrengthUnit: schedule.customMedicationStrengthUnit,
      scheduleId: schedule.id,
      scheduledTime: scheduledTime,
    );
  }

  /// Create temporary fluid session for unlogged past treatments
  FluidSession _createTempFluidSession(
    Schedule schedule,
    DateTime scheduledTime,
  ) {
    final user = ref.read(currentUserProvider);
    final pet = ref.read(primaryPetProvider);

    return FluidSession.create(
      petId: pet!.id,
      userId: user!.id,
      dateTime: scheduledTime,
      volumeGiven: 0,
      injectionSite:
          schedule.preferredLocation ?? FluidLocation.shoulderBladeLeft,
      scheduleId: schedule.id,
      scheduledTime: scheduledTime,
      dailyGoalMl: schedule.targetVolume,
    );
  }

  /// Handle medication edit (transition to edit mode)
  void _handleEditMedication(
    MedicationSession session,
    Schedule schedule,
  ) {
    setState(() {
      _mode = _PopupMode.editMedication;
      _editingMedicationSession = session;
      _editingSchedule = schedule;
    });
  }

  /// Handle cancel edit (back to day view)
  void _handleEditCancel() {
    setState(() {
      _mode = _PopupMode.dayView;
      _editingMedicationSession = null;
      _editingSchedule = null;
      _editingFluidSession = null;
    });
  }

  /// Handle medication save from inline form
  Future<void> _handleMedicationEditSave(MedicationSession result) async {
    if (!mounted) return;

    final session = _editingMedicationSession;
    final schedule = _editingSchedule;
    if (session == null || schedule == null) return;

    // Detect if new session by checking weekSessions
    final weekStart = AppDateUtils.startOfWeekMonday(widget.date);
    final weekSessionsAsync = ref.read(weekSessionsProvider(weekStart));
    final isNewSession =
        weekSessionsAsync.whenOrNull(
          data: (weekSessions) {
            final normalizedDate = AppDateUtils.startOfDay(widget.date);
            final (medSessions, _) =
                weekSessions[normalizedDate] ??
                (<MedicationSession>[], <FluidSession>[]);
            return !medSessions.any((s) => s.id == session.id);
          },
        ) ??
        true;

    final success = isNewSession
        ? await _createMedicationSession(result, schedule)
        : await _updateMedicationSession(session, result);

    if (success && mounted) {
      // Show success message
      HydraSnackBar.showSuccess(
        context,
        isNewSession ? 'Treatment logged' : 'Medication updated',
        duration: const Duration(seconds: 2),
      );

      // Explicit refresh: Wait for Firestore refetch to complete
      final weekStart = AppDateUtils.startOfWeekMonday(widget.date);
      final _ = await ref.refresh(weekSummariesProvider(weekStart).future);

      if (!mounted) return;

      // Transition back to day view
      setState(() {
        _mode = _PopupMode.dayView;
        _editingMedicationSession = null;
        _editingSchedule = null;
      });
    }
  }

  /// Create new medication session (retroactive logging)
  Future<bool> _createMedicationSession(
    MedicationSession session,
    Schedule schedule,
  ) async {
    final user = ref.read(currentUserProvider);
    final pet = ref.read(primaryPetProvider);

    if (user == null || pet == null) return false;

    final profileState = ref.read(profileProvider);
    final sessionDate = session.dateTime;

    // Filter schedules that had reminders on the SESSION DATE
    final schedulesForDate =
        profileState.medicationSchedules
            ?.where(
              (s) =>
                  s.isActive && s.reminderTimesOnDate(sessionDate).isNotEmpty,
            )
            .toList() ??
        <Schedule>[];

    return ref
        .read(loggingProvider.notifier)
        .logMedicationSession(
          session: session,
          todaysSchedules: schedulesForDate,
        );
  }

  /// Update existing medication session
  Future<bool> _updateMedicationSession(
    MedicationSession oldSession,
    MedicationSession newSession,
  ) async {
    return ref
        .read(progressEditProvider.notifier)
        .updateMedicationSession(
          oldSession: oldSession,
          newSession: newSession,
        );
  }

  /// Handle fluid edit (transition to edit mode)
  void _handleEditFluid(FluidSession session) {
    setState(() {
      _mode = _PopupMode.editFluid;
      _editingFluidSession = session;
    });
  }

  /// Handle fluid save from inline form
  Future<void> _handleFluidEditSave(FluidSession result) async {
    if (!mounted) return;

    final session = _editingFluidSession;
    if (session == null) return;

    final weekStart = AppDateUtils.startOfWeekMonday(widget.date);
    final weekSessionsAsync = ref.read(weekSessionsProvider(weekStart));
    final isNewSession =
        weekSessionsAsync.whenOrNull(
          data: (weekSessions) {
            final normalizedDate = AppDateUtils.startOfDay(widget.date);
            final (_, fluidSessions) =
                weekSessions[normalizedDate] ??
                (<MedicationSession>[], <FluidSession>[]);
            return !fluidSessions.any((s) => s.id == session.id);
          },
        ) ??
        true;

    final success = isNewSession
        ? await _createFluidSession(result)
        : await _updateFluidSession(session, result);

    if (success && mounted) {
      // Show success message
      HydraSnackBar.showSuccess(
        context,
        isNewSession ? 'Fluid therapy logged' : 'Fluid therapy updated',
        duration: const Duration(seconds: 2),
      );

      // Explicit refresh: Wait for Firestore refetch to complete
      final weekStart = AppDateUtils.startOfWeekMonday(widget.date);
      final _ = await ref.refresh(weekSummariesProvider(weekStart).future);

      if (!mounted) return;

      // Transition back to day view
      setState(() {
        _mode = _PopupMode.dayView;
        _editingFluidSession = null;
      });
    }
  }

  /// Create new fluid session (retroactive logging)
  Future<bool> _createFluidSession(FluidSession session) async {
    final user = ref.read(currentUserProvider);
    final pet = ref.read(primaryPetProvider);

    if (user == null || pet == null) return false;

    final fluidSchedule = ref.read(fluidScheduleProvider);

    // Verify schedule had reminders on session date
    final sessionDate = session.dateTime;
    final scheduleValidForDate =
        fluidSchedule != null &&
        fluidSchedule.isActive &&
        fluidSchedule.reminderTimesOnDate(sessionDate).isNotEmpty;

    return ref
        .read(loggingProvider.notifier)
        .logFluidSession(
          session: session,
          fluidSchedule: scheduleValidForDate ? fluidSchedule : null,
        );
  }

  /// Update existing fluid session
  Future<bool> _updateFluidSession(
    FluidSession oldSession,
    FluidSession newSession,
  ) async {
    return ref
        .read(progressEditProvider.notifier)
        .updateFluidSession(
          oldSession: oldSession,
          newSession: newSession,
        );
  }

  /// Builds the semantic label for accessibility.
  String _buildSemanticLabel() {
    final formattedDate = DateFormat('EEEE, MMMM d').format(widget.date);
    return 'Treatment details for $formattedDate';
  }
}

// ============================================
// Inline Edit Form Widgets
// ============================================

/// Inline medication edit form (content only, no Dialog wrapper)
class _MedicationEditInlineForm extends StatefulWidget {
  const _MedicationEditInlineForm({
    required this.session,
    required this.schedule,
    required this.onSave,
    required this.onCancel,
  });

  final MedicationSession session;
  final Schedule schedule;
  final void Function(MedicationSession) onSave;
  final VoidCallback onCancel;

  @override
  State<_MedicationEditInlineForm> createState() =>
      _MedicationEditInlineFormState();
}

class _MedicationEditInlineFormState extends State<_MedicationEditInlineForm> {
  late bool _completed;
  late double _dosageGiven;
  double? _previousDosage; // Store dosage when switching to missed
  late TextEditingController _notesController;
  bool _notesExpanded = false;
  final FocusNode _notesFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _completed = widget.session.completed;
    _dosageGiven = widget.session.dosageGiven;
    _notesController = TextEditingController(text: widget.session.notes ?? '');

    // Expand notes if already has content
    _notesExpanded = widget.session.notes?.isNotEmpty ?? false;

    // Expand on focus, collapse on unfocus if empty
    _notesFocusNode.addListener(() {
      if (_notesFocusNode.hasFocus && !_notesExpanded) {
        setState(() {
          _notesExpanded = true;
        });
      } else if (!_notesFocusNode.hasFocus &&
          _notesExpanded &&
          _notesController.text.isEmpty) {
        setState(() {
          _notesExpanded = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _notesFocusNode.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      _completed != widget.session.completed ||
      _dosageGiven != widget.session.dosageGiven ||
      _notesController.text != (widget.session.notes ?? '');

  void _incrementDosage() {
    setState(() {
      if (_dosageGiven < 100) {
        _dosageGiven += 0.5;
      }
    });
  }

  void _decrementDosage() {
    setState(() {
      if (_dosageGiven > 0) {
        _dosageGiven = (_dosageGiven - 0.5).clamp(0, 100);
      }
    });
  }

  void _handleSave() {
    if (!_hasChanges) {
      widget.onCancel();
      return;
    }

    final updatedSession = widget.session.copyWith(
      completed: _completed,
      dosageGiven: _dosageGiven,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      updatedAt: DateTime.now(),
    );

    widget.onSave(updatedSession);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with medication info
        _buildHeader(theme),
        const SizedBox(height: AppSpacing.md),
        const Divider(height: 1, thickness: 1),
        const SizedBox(height: AppSpacing.lg),

        // Completion status toggle
        _buildCompletionToggle(theme),
        const SizedBox(height: AppSpacing.lg),

        // Dosage adjuster
        _buildDosageAdjuster(theme),
        const SizedBox(height: AppSpacing.lg),

        // Notes field
        _buildNotesField(theme),
        const SizedBox(height: AppSpacing.xl),

        // Action buttons
        _buildActionButtons(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final medicationName = widget.schedule.medicationName ?? 'Medication';
    final strengthAmount = widget.schedule.medicationStrengthAmount;
    final strengthUnit = widget.schedule.medicationStrengthUnit ?? '';
    final strengthText = strengthAmount != null
        ? ' $strengthAmount$strengthUnit'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          medicationName,
          style: AppTextStyles.h3.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (strengthText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            strengthText.trim(),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletionToggle(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildStatusButton(
                label: 'Completed',
                icon: Icons.check_circle,
                isSelected: _completed,
                onTap: () {
                  setState(() {
                    _completed = true;
                    // Restore previous dosage if available,
                    // otherwise use scheduled dosage
                    if (_previousDosage != null) {
                      _dosageGiven = _previousDosage!;
                      _previousDosage = null;
                    } else if (_dosageGiven == 0) {
                      _dosageGiven = widget.schedule.targetDosage ?? 1;
                    }
                  });
                },
                theme: theme,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatusButton(
                label: 'Missed',
                icon: Icons.cancel,
                isSelected: !_completed,
                onTap: () {
                  setState(() {
                    _completed = false;
                    // Store current dosage and set to 0
                    if (_dosageGiven > 0) {
                      _previousDosage = _dosageGiven;
                      _dosageGiven = 0;
                    }
                  });
                },
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight.withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDosageAdjuster(ThemeData theme) {
    final unit = widget.schedule.medicationUnit ?? 'dose';
    final displayDosage = _dosageGiven == _dosageGiven.toInt()
        ? _dosageGiven.toInt().toString()
        : _dosageGiven.toStringAsFixed(1);
    final isDisabled = !_completed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dosage',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircularButton(
                  icon: Icons.remove,
                  onPressed: _decrementDosage,
                  enabled: !isDisabled && _dosageGiven > 0,
                ),
                const SizedBox(width: AppSpacing.lg),
                Column(
                  children: [
                    Text(
                      displayDosage,
                      style: AppTextStyles.display.copyWith(
                        color: isDisabled
                            ? AppColors.textSecondary
                            : theme.colorScheme.onSurface,
                        fontSize: 40,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unit,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.lg),
                _buildCircularButton(
                  icon: Icons.add,
                  onPressed: _incrementDosage,
                  enabled: !isDisabled && _dosageGiven < 100,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool enabled,
  }) {
    return Material(
      color: enabled
          ? AppColors.primaryLight.withValues(alpha: 0.3)
          : AppColors.disabled,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: enabled ? AppColors.primaryDark : AppColors.textTertiary,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildNotesField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (optional)',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        HydraTextField(
          controller: _notesController,
          focusNode: _notesFocusNode,
          maxLength: _notesExpanded ? 500 : null,
          maxLines: _notesExpanded ? 3 : 1,
          decoration: InputDecoration(
            hintText: _notesExpanded
                ? 'Add any notes about this dose...'
                : 'Tap to add notes...',
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.textTertiary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            counterStyle: _notesExpanded
                ? AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  )
                : null,
          ),
          style: AppTextStyles.body,
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HydraButton(
          isFullWidth: true,
          onPressed: _handleSave,
          child: const Text('Save'),
        ),
        const SizedBox(height: AppSpacing.sm),
        HydraButton(
          variant: HydraButtonVariant.secondary,
          isFullWidth: true,
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Inline fluid edit form (content only, no Dialog wrapper)
class _FluidEditInlineForm extends StatefulWidget {
  const _FluidEditInlineForm({
    required this.session,
    required this.onSave,
    required this.onCancel,
  });

  final FluidSession session;
  final void Function(FluidSession) onSave;
  final VoidCallback onCancel;

  @override
  State<_FluidEditInlineForm> createState() => _FluidEditInlineFormState();
}

class _FluidEditInlineFormState extends State<_FluidEditInlineForm> {
  late double _volumeGiven;
  late FluidLocation _injectionSite;
  late String _stressLevel;
  late TextEditingController _notesController;
  bool _notesExpanded = false;
  final FocusNode _notesFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _volumeGiven = widget.session.volumeGiven;
    _injectionSite = widget.session.injectionSite;
    _stressLevel = widget.session.stressLevel ?? 'medium';

    _notesController = TextEditingController(text: widget.session.notes ?? '');

    // Expand notes if already has content
    _notesExpanded = widget.session.notes?.isNotEmpty ?? false;

    // Expand on focus, collapse on unfocus if empty
    _notesFocusNode.addListener(() {
      if (_notesFocusNode.hasFocus && !_notesExpanded) {
        setState(() {
          _notesExpanded = true;
        });
      } else if (!_notesFocusNode.hasFocus &&
          _notesExpanded &&
          _notesController.text.isEmpty) {
        setState(() {
          _notesExpanded = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _notesFocusNode.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      _volumeGiven != widget.session.volumeGiven ||
      _injectionSite != widget.session.injectionSite ||
      _stressLevel != (widget.session.stressLevel ?? 'medium') ||
      _notesController.text != (widget.session.notes ?? '');

  void _handleSave() {
    if (!_hasChanges) {
      widget.onCancel();
      return;
    }

    if (_volumeGiven < 0 || _volumeGiven > 500) {
      return;
    }

    final updatedSession = widget.session.copyWith(
      volumeGiven: _volumeGiven,
      injectionSite: _injectionSite,
      stressLevel: _stressLevel, // Now always non-null
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      updatedAt: DateTime.now(),
    );

    widget.onSave(updatedSession);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Fluid Therapy',
          style: AppTextStyles.h3.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Divider(height: 1, thickness: 1),
        const SizedBox(height: AppSpacing.lg),

        // Volume adjuster
        VolumeInputAdjuster(
          initialValue: _volumeGiven,
          onChanged: (value) {
            setState(() {
              _volumeGiven = value;
            });
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Injection site selector
        _buildInjectionSiteSelector(theme),
        const SizedBox(height: AppSpacing.lg),

        // Stress level selector
        _buildStressLevelSelector(theme),
        const SizedBox(height: AppSpacing.lg),

        // Notes field
        _buildNotesField(theme),
        const SizedBox(height: AppSpacing.xl),

        // Action buttons
        _buildActionButtons(theme),
      ],
    );
  }

  Widget _buildInjectionSiteSelector(ThemeData theme) {
    return InjectionSiteSelector(
      value: _injectionSite,
      onChanged: (FluidLocation value) {
        setState(() {
          _injectionSite = value;
        });
      },
    );
  }

  Widget _buildStressLevelSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stress Level',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        StressLevelSelector(
          value: _stressLevel,
          onChanged: (String value) {
            setState(() {
              _stressLevel = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNotesField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (optional)',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        HydraTextField(
          controller: _notesController,
          focusNode: _notesFocusNode,
          maxLength: _notesExpanded ? 500 : null,
          maxLines: _notesExpanded ? 3 : 1,
          decoration: InputDecoration(
            hintText: _notesExpanded
                ? 'Add any notes about this session...'
                : 'Tap to add notes...',
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.textTertiary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            counterStyle: _notesExpanded
                ? AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  )
                : null,
          ),
          style: AppTextStyles.body,
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HydraButton(
          isFullWidth: true,
          onPressed: _handleSave,
          child: const Text('Save'),
        ),
        const SizedBox(height: AppSpacing.sm),
        HydraButton(
          variant: HydraButtonVariant.secondary,
          isFullWidth: true,
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Shows the progress day detail popup as a bottom sheet.
///
/// Displays treatment details for the specified [date].
/// Uses standard bottom sheet animation and is dismissible by dragging or
/// tapping the close button.
///
/// Example:
/// ```dart
/// showProgressDayDetailPopup(context, DateTime(2025, 10, 15));
/// ```
void showProgressDayDetailPopup(BuildContext context, DateTime date) {
  showHydraBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: AppColors.background,
    builder: (sheetContext) => HydraBottomSheet(
      heightFraction: 0.85,
      backgroundColor: AppColors.background,
      child: ProgressDayDetailPopup(date: date),
    ),
  );
}
