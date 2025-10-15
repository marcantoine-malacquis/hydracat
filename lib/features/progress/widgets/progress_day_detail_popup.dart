import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';
import 'package:hydracat/features/logging/services/session_read_service.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/progress_provider.dart';
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
    final isFuture = date.isAfter(AppDateUtils.startOfDay(DateTime.now()));
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
      return _buildLoggedView(context, ref);
    }
  }

  /// Builds the logged view showing actual sessions from Firestore.
  Widget _buildLoggedView(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final pet = ref.watch(primaryPetProvider);

    if (user == null || pet == null) {
      return const Text('User or pet not found');
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

        if (medSessions.isEmpty && fluidSessions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Text('No treatments logged for this day'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (medSessions.isNotEmpty) ...[
              const Text('Medications', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.xs),
              ...medSessions.map(_buildMedicationSessionTile),
            ],
            if (medSessions.isNotEmpty && fluidSessions.isNotEmpty)
              const SizedBox(height: AppSpacing.md),
            if (fluidSessions.isNotEmpty) ...[
              const Text('Fluid Therapy', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.xs),
              ...fluidSessions.map(_buildFluidSessionTile),
            ],
          ],
        );
      },
    );
  }

  /// Builds a tile for a medication session.
  Widget _buildMedicationSessionTile(MedicationSession session) {
    final timeStr = DateFormat.jm().format(session.dateTime);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        session.completed ? Icons.check_circle : Icons.cancel,
        color: session.completed ? AppColors.primary : AppColors.warning,
        size: 24,
      ),
      title: Text(
        session.medicationName,
        style: AppTextStyles.body,
      ),
      subtitle: Text(
        '$timeStr • ${session.dosageGiven} ${session.medicationUnit}',
        style: AppTextStyles.caption,
      ),
    );
  }

  /// Builds a tile for a fluid session.
  Widget _buildFluidSessionTile(FluidSession session) {
    final timeStr = DateFormat.jm().format(session.dateTime);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.water_drop,
        color: AppColors.primary,
        size: 24,
      ),
      title: Text(
        '${session.volumeGiven}ml',
        style: AppTextStyles.body,
      ),
      subtitle: Text(
        timeStr,
        style: AppTextStyles.caption,
      ),
    );
  }

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

  /// Builds a tile for a planned medication.
  Widget _buildPlannedMedicationTile(Schedule schedule, DateTime time) {
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
    );
  }

  /// Builds a tile for planned fluid therapy.
  Widget _buildPlannedFluidTile(Schedule schedule, DateTime time) {
    final timeStr = DateFormat.jm().format(time);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.water_drop,
        color: AppColors.textSecondary,
        size: 24,
      ),
      title: Text(
        '${schedule.targetVolume}ml',
        style: AppTextStyles.body,
      ),
      subtitle: Text(
        timeStr,
        style: AppTextStyles.caption,
      ),
    );
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
