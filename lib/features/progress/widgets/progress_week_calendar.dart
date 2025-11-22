import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/progress/models/day_dot_status.dart';
import 'package:hydracat/features/progress/widgets/fluid_volume_bar_chart.dart';
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
    final rangeStart = ref.watch(focusedRangeStartProvider);
    final format = ref.watch(calendarFormatProvider);

    return Column(
      children: [
        _buildFormatBar(context, ref),
        _buildCustomHeader(context, focusedDay, ref),
        TableCalendar<void>(
          firstDay: DateTime.utc(2010),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: focusedDay,
          calendarFormat: format,
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerVisible: false,
          availableGestures: AvailableGestures.horizontalSwipe,
          sixWeekMonthsEnforced: true,
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
        // Fluid volume bar chart (week view only)
        if (format == CalendarFormat.week) ...[
          const SizedBox(height: 8),
          const FluidVolumeBarChart(),
        ],
      ],
    );
  }

  /// Builds the format bar with Week/Month toggle and Jump to date button.
  Widget _buildFormatBar(BuildContext context, WidgetRef ref) {
    final format = ref.watch(calendarFormatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Week/Month segmented control - centered
          Center(
            child: _SlidingSegmentedControl(
              selected: format,
              isDark: isDark,
              onChanged: (CalendarFormat newFormat) {
                HapticFeedback.selectionClick();
                ref.read(calendarFormatProvider.notifier).state = newFormat;
              },
            ),
          ),
          // Jump to date button - positioned on right with reduced padding
          Positioned(
            right: -8,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Jump to date',
              icon: const Icon(Icons.calendar_month, size: 24),
              onPressed: () async {
                final theme = Theme.of(context);
                final focused = ref.read(focusedDayProvider);
                final picked = await showDatePicker(
                  context: context,
                  initialDate: focused,
                  firstDate: DateTime(2010),
                  lastDate: DateTime.now(),
                  builder: (context, child) => Theme(
                    data: theme.copyWith(colorScheme: theme.colorScheme),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  ref.read(focusedDayProvider.notifier).state = picked;
                }
              },
            ),
          ),
        ],
      ),
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
    final monthYearText = monthYearFormat.format(day).toUpperCase();

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
              IconButton(
                icon: const Icon(Icons.chevron_right),
                iconSize: 22,
                onPressed: () {
                  final next = isMonth
                      ? _getNextMonth(focusedDay)
                      : focusedDay.add(const Duration(days: 7));
                  ref.read(focusedDayProvider.notifier).state = next;
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: isMonth ? 'Next month' : 'Next week',
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

/// Loading skeleton with shimmer animation for calendar dot status.
///
/// Uses warm neutral colors from the design system:
/// - Base: #DDD6CE (border color - warm, soft)
/// - Highlight: #F6F4F2 (background color - warm off-white)
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
      child: Shimmer(
        duration: const Duration(milliseconds: 1500),
        interval: const Duration(milliseconds: 1500),
        color: const Color(0xFFF6F4F2), // Highlight: warm background
        child: Container(
          width: dotSize,
          height: dotSize,
          decoration: const BoxDecoration(
            color: Color(0xFFDDD6CE), // Base: warm border color
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Custom segmented control with animated sliding marker.
///
/// Features:
/// - Compact size with teal sliding marker that animates between Week/Month
/// - Premium design with shadows and proper spacing
/// - Smooth 250ms animation with easeInOut curve
/// - Supports both light and dark themes
/// - Intrinsic width based on content (not stretched)
class _SlidingSegmentedControl extends StatelessWidget {
  const _SlidingSegmentedControl({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  final CalendarFormat selected;
  final bool isDark;
  final ValueChanged<CalendarFormat> onChanged;

  // Segment width - increased for better visual presence
  static const double _segmentWidth = 90;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = selected == CalendarFormat.week ? 0 : 1;

    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated sliding marker (teal background)
          AnimatedPositioned(
            left: selectedIndex == 0 ? 0 : _segmentWidth,
            top: 0,
            bottom: 0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Container(
              width: _segmentWidth,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(7),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Labels on top of the marker
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => onChanged(CalendarFormat.week),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: _segmentWidth,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      style: AppTextStyles.buttonSecondary.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: selectedIndex == 0
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      child: const Text('Week'),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onChanged(CalendarFormat.month),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: _segmentWidth,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      style: AppTextStyles.buttonSecondary.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: selectedIndex == 1
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      child: const Text('Month'),
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
}
