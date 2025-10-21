import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/progress/models/day_dot_status.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:table_calendar/table_calendar.dart';

/// A weekly calendar widget for the Progress screen that displays treatment
/// adherence status for each day.
///
/// Shows a single row (Monday-Sunday) with status dots:
/// - Teal dot: All scheduled treatments completed
/// - Soft coral dot: At least one scheduled treatment missed
/// - Amber dot: Today (until all scheduled treatments are completed)
/// - No dot: Future days or past days with zero schedules
class ProgressWeekCalendar extends ConsumerWidget {
  /// Creates a progress week calendar.
  const ProgressWeekCalendar({
    required this.onDaySelected,
    super.key,
  });

  /// Callback fired when a day is tapped.
  final void Function(DateTime day) onDaySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedDay = ref.watch(focusedDayProvider);
    final weekStart = ref.watch(focusedWeekStartProvider);

    return Column(
      children: [
        _buildCustomHeader(context, focusedDay, ref),
        TableCalendar<void>(
          firstDay: DateTime.utc(2010),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: focusedDay,
          calendarFormat: CalendarFormat.week,
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerVisible: false,
          availableGestures: AvailableGestures.horizontalSwipe,
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: Theme.of(context).textTheme.labelMedium!,
            weekendStyle: Theme.of(context).textTheme.labelMedium!,
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            todayTextStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            selectedDecoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            selectedTextStyle:
                Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            outsideDaysVisible: false,
            cellMargin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          ),
          onPageChanged: (newFocusedDay) {
            ref.read(focusedDayProvider.notifier).state = newFocusedDay;
          },
          selectedDayPredicate: (day) {
            final selectedDay = ref.watch(selectedDayProvider);
            return selectedDay != null &&
                AppDateUtils.isSameDay(day, selectedDay);
          },
          onDaySelected: (selected, focused) {
            HapticFeedback.selectionClick();
            ref.read(selectedDayProvider.notifier).state = selected;
            onDaySelected(selected);
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              return _WeekDotMarker(
                day: day,
                weekStart: weekStart,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds a custom header with navigation chevrons close together and
  /// a "Today" button on the right (when not viewing current week).
  Widget _buildCustomHeader(
    BuildContext context,
    DateTime day,
    WidgetRef ref,
  ) {
    final focusedDay = ref.watch(focusedDayProvider);
    final monthYearFormat = DateFormat('MMMM yyyy');
    final monthYearText = monthYearFormat.format(day);

    // Determine if we're viewing the current week
    final focusedWeekStart = AppDateUtils.startOfWeekMonday(focusedDay);
    final currentWeekStart = AppDateUtils.startOfWeekMonday(DateTime.now());
    final isOnCurrentWeek = focusedWeekStart == currentWeekStart;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Left chevron
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final previousWeek = focusedDay.subtract(const Duration(days: 7));
              ref.read(focusedDayProvider.notifier).state = previousWeek;
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Previous week',
          ),
          const SizedBox(width: 8),
          // Month and year
          Text(
            monthYearText,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(width: 8),
          // Right chevron
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final nextWeek = focusedDay.add(const Duration(days: 7));
              ref.read(focusedDayProvider.notifier).state = nextWeek;
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Next week',
          ),
          const Spacer(),
          // "Today" button - only show when not on current week
          if (!isOnCurrentWeek)
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                final today = DateTime.now();
                ref.read(focusedDayProvider.notifier).state = today;
                ref.read(selectedDayProvider.notifier).state = today;
                onDaySelected(today);
              },
              child: Text(
                'Today',
                style: AppTextStyles.buttonSecondary.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget that renders the status dot for a single day in the calendar.
class _WeekDotMarker extends ConsumerWidget {
  const _WeekDotMarker({
    required this.day,
    required this.weekStart,
  });

  final DateTime day;
  final DateTime weekStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if schedules are loaded yet - same pattern as dashboard
    final schedules = ref.watch(medicationSchedulesProvider);

    // Show skeleton if schedules haven't loaded yet
    // null = never loaded, [] = loaded but empty
    if (schedules == null) {
      return const _DotSkeleton();
    }

    final weekStatusAsync = ref.watch(weekStatusProvider(weekStart));

    return weekStatusAsync.when(
      data: (statuses) {
        final normalizedDay = AppDateUtils.startOfDay(day);
        final status = statuses[normalizedDay] ?? DayDotStatus.none;
        return _buildStatusDot(status);
      },
      loading: () => const _DotSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatusDot(DayDotStatus status) {
    final Color? color;
    final String semanticLabel;

    switch (status) {
      case DayDotStatus.complete:
        // Teal - all scheduled treatments completed
        color = AppColors.primary;
        semanticLabel = 'Completed day';
      case DayDotStatus.missed:
        // Soft coral - at least one treatment missed
        color = AppColors.warning;
        semanticLabel = 'Missed day';
      case DayDotStatus.today:
        // Gold - current day indicator (until complete)
        color = Colors.amber[600];
        semanticLabel = 'Today';
      case DayDotStatus.none:
        return const SizedBox.shrink();
    }

    return Semantics(
      label: semanticLabel,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Loading skeleton with shimmer animation for calendar dot status.
///
/// Uses warm neutral colors from the design system:
/// - Base: #DDD6CE (border color - warm, soft)
/// - Highlight: #F6F4F2 (background color - warm off-white)
class _DotSkeleton extends StatelessWidget {
  const _DotSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading status',
      child: Shimmer(
        duration: const Duration(milliseconds: 1500),
        interval: const Duration(milliseconds: 1500),
        color: const Color(0xFFF6F4F2), // Highlight: warm background
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFDDD6CE), // Base: warm border color
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
