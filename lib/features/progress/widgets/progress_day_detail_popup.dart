import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';
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

/// State for [ProgressDayDetailPopup] with lazy content loading.
class _ProgressDayDetailPopupState extends ConsumerState<ProgressDayDetailPopup>
    with SingleTickerProviderStateMixin {
  /// Whether to show the popup content.
  /// Starts false and becomes true after animation completes.
  bool _showContent = false;

  // Drag tracking state
  double _dragOffset = 0; // Current drag distance in pixels
  late AnimationController _dragAnimationController;
  late Animation<double> _dragAnimation;

  // Constants
  static const double _dismissThreshold = 150; // Minimum drag to dismiss
  static const double _velocityThreshold = 300; // Minimum velocity to dismiss

  @override
  void initState() {
    super.initState();

    // Setup drag animation controller for spring-back
    _dragAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _dragAnimation =
        Tween<double>(
            begin: 0,
            end: 0,
          ).animate(
            CurvedAnimation(
              parent: _dragAnimationController,
              curve: Curves.easeOutCubic,
            ),
          )
          ..addListener(() {
            setState(() {
              _dragOffset = _dragAnimation.value;
            });
          });

    // Wait for animation to complete (200ms slideUp + 50ms buffer)
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _showContent = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _dragAnimationController.dispose();
    super.dispose();
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      // Only allow downward drag (positive delta)
      final newOffset = _dragOffset + details.delta.dy;
      _dragOffset = newOffset.clamp(0, double.infinity);
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;

    // Dismiss if: dragged past threshold OR high velocity downward
    if (_dragOffset > _dismissThreshold || velocity > _velocityThreshold) {
      _animateDismiss();
    } else {
      // Spring back to original position
      _animateSpringBack();
    }
  }

  Future<void> _animateDismiss() async {
    // Animate remaining distance to full screen height
    final screenHeight = MediaQuery.of(context).size.height;
    _dragAnimation =
        Tween<double>(
            begin: _dragOffset,
            end: screenHeight,
          ).animate(
            CurvedAnimation(
              parent: _dragAnimationController,
              curve: Curves.easeInCubic,
            ),
          )
          ..addListener(() {
            setState(() {
              _dragOffset = _dragAnimation.value;
            });
          });

    _dragAnimationController.reset();
    await _dragAnimationController.forward();

    if (mounted) {
      OverlayService.hide();
    }
  }

  void _animateSpringBack() {
    _dragAnimation =
        Tween<double>(
            begin: _dragOffset,
            end: 0,
          ).animate(
            CurvedAnimation(
              parent: _dragAnimationController,
              curve: Curves.easeOutCubic,
            ),
          )
          ..addListener(() {
            setState(() {
              _dragOffset = _dragAnimation.value;
            });
          });

    _dragAnimationController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    // Compare by normalized day so "today" is not misclassified as future
    final day = AppDateUtils.startOfDay(widget.date);
    final today = AppDateUtils.startOfDay(DateTime.now());
    final isFuture = day.isAfter(today);
    final mediaQuery = MediaQuery.of(context);

    // Check reduce motion preference
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final effectiveDragOffset = reduceMotion ? 0.0 : _dragOffset;

    return GestureDetector(
      onVerticalDragUpdate: _handleVerticalDragUpdate,
      onVerticalDragEnd: _handleVerticalDragEnd,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Transform.translate(
          offset: Offset(0, effectiveDragOffset), // Apply drag offset
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Industry-standard drag handle indicator at very top
                    _buildDragHandle(context),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context),
                            const SizedBox(height: AppSpacing.md),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Lazy load content after animation completes
                            if (_showContent)
                              _buildContent(context, ref, isFuture)
                            else
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.xl),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the industry-standard drag handle indicator.
  Widget _buildDragHandle(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  /// Builds the header with date and close button.
  Widget _buildHeader(BuildContext context) {
    final formattedDate = DateFormat('EEEE, MMMM d').format(widget.date);

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
              ..._buildFluidSessionsList(fluidSessions),
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

  /// Builds list tiles for actual fluid sessions on the selected day.
  List<Widget> _buildFluidSessionsList(List<FluidSession> sessions) {
    if (sessions.isEmpty) return const [];

    final sorted = [...sessions]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return sorted.map((s) {
      final timeStr = DateFormat.jm().format(s.dateTime);
      final volumeStr = '${s.volumeGiven.toStringAsFixed(0)}ml';

      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(
          Icons.water_drop,
          color: AppColors.textSecondary,
          size: 24,
        ),
        title: Text(volumeStr, style: AppTextStyles.body),
        subtitle: Text(timeStr, style: AppTextStyles.caption),
      );
    }).toList();
  }

  /// Builds the fluid summary card when data is available.
  Widget _maybeSummaryCard(BuildContext context, WidgetRef ref) {
    final view = ref.watch(
      fluidDailySummaryViewProvider(AppDateUtils.startOfDay(widget.date)),
    );

    if (view == null) return const SizedBox.shrink();

    return FluidDailySummaryCard(summary: view);
  }

  /// Builds the semantic label for accessibility.
  String _buildSemanticLabel() {
    final formattedDate = DateFormat('EEEE, MMMM d').format(widget.date);
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
