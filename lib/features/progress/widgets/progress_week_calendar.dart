import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/progress/models/day_dot_status.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:table_calendar/table_calendar.dart';

/// A weekly calendar widget for the Progress screen that displays treatment
/// adherence status for each day.
///
/// Shows a single row (Monday-Sunday) with status dots:
/// - Teal dot: All scheduled treatments completed
/// - Soft coral dot: At least one scheduled treatment missed
/// - Amber dot: Today (until all scheduled treatments are completed)
/// - No dot: Future days or past days with zero schedules
class ProgressWeekCalendar extends ConsumerStatefulWidget {
  /// Creates a progress week calendar.
  const ProgressWeekCalendar({
    required this.onDaySelected,
    super.key,
  });

  /// Callback fired when a day is tapped.
  final void Function(DateTime day) onDaySelected;

  @override
  ConsumerState<ProgressWeekCalendar> createState() =>
      _ProgressWeekCalendarState();
}

class _ProgressWeekCalendarState extends ConsumerState<ProgressWeekCalendar> {
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final focusedDay = ref.watch(focusedDayProvider);
    final weekStart = ref.watch(focusedWeekStartProvider);

    return TableCalendar<void>(
      firstDay: DateTime.utc(2010),
      lastDay: DateTime.utc(2035, 12, 31),
      focusedDay: focusedDay,
      calendarFormat: CalendarFormat.week,
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
      ),
      availableGestures: AvailableGestures.horizontalSwipe,
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: Theme.of(context).textTheme.labelMedium!,
        weekendStyle: Theme.of(context).textTheme.labelMedium!,
      ),
      calendarStyle: const CalendarStyle(
        todayDecoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        outsideDaysVisible: false,
        cellMargin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      ),
      onPageChanged: (newFocusedDay) {
        ref.read(focusedDayProvider.notifier).state = newFocusedDay;
      },
      selectedDayPredicate: (day) =>
          _selectedDay != null && AppDateUtils.isSameDay(day, _selectedDay!),
      onDaySelected: (selected, focused) {
        setState(() {
          _selectedDay = selected;
        });
        widget.onDaySelected(selected);
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          return _WeekDotMarker(
            day: day,
            weekStart: weekStart,
          );
        },
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
    final weekStatusAsync = ref.watch(weekStatusProvider(weekStart));

    return weekStatusAsync.when(
      data: (statuses) {
        final normalizedDay = AppDateUtils.startOfDay(day);
        final status = statuses[normalizedDay] ?? DayDotStatus.none;
        return _buildStatusDot(status);
      },
      loading: () => const SizedBox.shrink(),
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
