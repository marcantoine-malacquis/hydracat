import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/progress/models/day_dot_status.dart';
import 'package:hydracat/features/progress/widgets/fluid_volume_bar_chart.dart';
import 'package:hydracat/features/progress/widgets/fluid_volume_month_chart.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:intl/intl.dart';
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
    final rangeStart = ref.watch(focusedRangeStartProvider);
    final format = ref.watch(calendarFormatProvider);

    return Column(
      children: [
        _buildCustomHeader(context, focusedDay, ref),
        TableCalendar<void>(
          firstDay: DateTime.utc(2010),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: focusedDay,
          calendarFormat: format,
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerVisible: false,
          availableGestures: AvailableGestures.horizontalSwipe,
          rowHeight: format == CalendarFormat.month ? 48 : 68,
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: Theme.of(context).textTheme.labelMedium!,
            weekendStyle: Theme.of(context).textTheme.labelMedium!,
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: format == CalendarFormat.month ? 1.5 : 2,
              ),
            ),
            todayTextStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            outsideDaysVisible: false,
            cellMargin: EdgeInsets.symmetric(
              vertical: format == CalendarFormat.month ? 8 : 10,
              horizontal: 4,
            ),
          ),
          onPageChanged: (newFocusedDay) {
            ref.read(focusedDayProvider.notifier).state = newFocusedDay;
          },
          onDaySelected: (selected, focused) {
            HapticFeedback.selectionClick();
            onDaySelected(selected);
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              return _WeekDotMarker(
                day: day,
                rangeStart: rangeStart,
              );
            },
          ),
        ),
        // Fluid volume bar chart (format-conditional)
        if (format == CalendarFormat.week) ...[
          const SizedBox(height: 8),
          const FluidVolumeBarChart(), // 7-bar week chart
        ] else if (format == CalendarFormat.month) ...[
          const SizedBox(height: 8),
          const FluidVolumeMonthChart(), // 28-31 bar month chart
        ],
      ],
    );
  }

  /// Builds a custom header with navigation chevrons close together and
  /// a "Today" button on the right (when not viewing current period).
  Widget _buildCustomHeader(
    BuildContext context,
    DateTime day,
    WidgetRef ref,
  ) {
    final focusedDay = ref.watch(focusedDayProvider);
    final format = ref.watch(calendarFormatProvider);
    final isMonth = format == CalendarFormat.month;
    final monthYearFormat = DateFormat('MMMM yyyy');
    final monthYearText = monthYearFormat.format(day);

    // Determine if we're viewing the current period (week or month)
    final now = DateTime.now();
    final isOnCurrentPeriod = isMonth
        ? focusedDay.year == now.year && focusedDay.month == now.month
        : AppDateUtils.startOfWeekMonday(focusedDay) ==
              AppDateUtils.startOfWeekMonday(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left chevron - jumps by week or month based on format
          IconButton(
            icon: const Icon(Icons.chevron_left),
            iconSize: 22,
            onPressed: () {
              final previous = isMonth
                  ? _getPreviousMonth(focusedDay)
                  : focusedDay.subtract(const Duration(days: 7));
              ref.read(focusedDayProvider.notifier).state = previous;
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: isMonth ? 'Previous month' : 'Previous week',
          ),
          // Month and year - centered in available space
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                monthYearText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Right section: chevron + optional Today button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Right chevron - jumps by week or month based on format
              // Disabled when on current period to prevent future navigation
              IconButton(
                icon: const Icon(Icons.chevron_right),
                iconSize: 22,
                onPressed: isOnCurrentPeriod
                    ? null
                    : () {
                        final next = isMonth
                            ? _getNextMonth(focusedDay)
                            : focusedDay.add(const Duration(days: 7));
                        ref.read(focusedDayProvider.notifier).state = next;
                      },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: isOnCurrentPeriod
                    ? 'Cannot view future'
                    : (isMonth ? 'Next month' : 'Next week'),
              ),
              // "Today" button - only show when not on current period
              if (!isOnCurrentPeriod)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      final today = DateTime.now();
                      ref.read(focusedDayProvider.notifier).state = today;
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Today',
                      style: AppTextStyles.buttonSecondary.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Gets the previous month while maintaining the day number when possible.
  /// Falls back to last valid day if the day doesn't exist in target month.
  DateTime _getPreviousMonth(DateTime date) {
    final targetMonth = DateTime(date.year, date.month - 1);
    final lastDayOfTargetMonth = DateTime(
      targetMonth.year,
      targetMonth.month + 1,
      0,
    ).day;
    final targetDay = min(date.day, lastDayOfTargetMonth);
    return DateTime(targetMonth.year, targetMonth.month, targetDay);
  }

  /// Gets the next month while maintaining the day number when possible.
  /// Falls back to last valid day if the day doesn't exist in target month.
  DateTime _getNextMonth(DateTime date) {
    final targetMonth = DateTime(date.year, date.month + 1);
    final lastDayOfTargetMonth = DateTime(
      targetMonth.year,
      targetMonth.month + 1,
      0,
    ).day;
    final targetDay = min(date.day, lastDayOfTargetMonth);
    return DateTime(targetMonth.year, targetMonth.month, targetDay);
  }
}

/// Widget that renders the status dot for a single day in the calendar.
class _WeekDotMarker extends ConsumerWidget {
  const _WeekDotMarker({
    required this.day,
    required this.rangeStart,
  });

  final DateTime day;
  final DateTime rangeStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if schedules are loaded yet - same pattern as dashboard
    final schedules = ref.watch(medicationSchedulesProvider);

    // Show skeleton if schedules haven't loaded yet
    // null = never loaded, [] = loaded but empty
    if (schedules == null) {
      return const _DotSkeleton();
    }

    final rangeStatusAsync = ref.watch(dateRangeStatusProvider(rangeStart));

    return rangeStatusAsync.when(
      data: (statuses) {
        final normalizedDay = AppDateUtils.startOfDay(day);
        final status = statuses[normalizedDay] ?? DayDotStatus.none;
        return _buildStatusDot(status, ref);
      },
      loading: () => const _DotSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatusDot(DayDotStatus status, WidgetRef ref) {
    final Color? color;
    final String semanticLabel;

    // Get format-aware dot size: 6px for month, 8px for week
    final format = ref.watch(calendarFormatProvider);
    final dotSize = format == CalendarFormat.month ? 6.0 : 8.0;

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
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Loading skeleton for calendar dot status.
///
/// Returns an invisible placeholder that maintains
/// the same space as a visible dot
/// to prevent layout shifts during loading.
///
/// Size adapts based on calendar format: 6px for month, 8px for week.
class _DotSkeleton extends ConsumerWidget {
  const _DotSkeleton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get format-aware dot size: 6px for month, 8px for week
    final format = ref.watch(calendarFormatProvider);
    final dotSize = format == CalendarFormat.month ? 6.0 : 8.0;

    return Semantics(
      label: 'Loading status',
      child: SizedBox(
        width: dotSize,
        height: dotSize,
      ),
    );
  }
}
