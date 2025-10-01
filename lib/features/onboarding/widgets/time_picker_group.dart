import 'package:flutter/material.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';

/// A group of time pickers based on treatment frequency
class TimePickerGroup extends StatefulWidget {
  /// Creates a [TimePickerGroup]
  const TimePickerGroup({
    required this.frequency,
    required this.onTimesChanged,
    this.initialTimes,
    super.key,
  });

  /// The treatment frequency that determines number of time pickers
  final TreatmentFrequency frequency;

  /// Callback when any time changes
  final ValueChanged<List<TimeOfDay>> onTimesChanged;

  /// Initial times to display (optional)
  final List<TimeOfDay>? initialTimes;

  @override
  State<TimePickerGroup> createState() => _TimePickerGroupState();
}

class _TimePickerGroupState extends State<TimePickerGroup> {
  late List<TimeOfDay> _selectedTimes;

  @override
  void initState() {
    super.initState();
    _initializeTimes();
  }

  @override
  void didUpdateWidget(TimePickerGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinitialize times if frequency changed
    if (oldWidget.frequency != widget.frequency) {
      _initializeTimes();
    }
  }

  void _initializeTimes() {
    final count = widget.frequency.administrationsPerDay;

    if (widget.initialTimes != null && widget.initialTimes!.length == count) {
      _selectedTimes = List<TimeOfDay>.from(widget.initialTimes!);
    } else {
      _selectedTimes = AppDateUtils.generateDefaultReminderTimes(count);
    }
  }

  void _updateTime(int index, TimeOfDay newTime) {
    setState(() {
      _selectedTimes[index] = newTime;
    });
    widget.onTimesChanged(_selectedTimes);
  }

  String _getTimeLabel(int index, int total) {
    switch (total) {
      case 1:
        return 'Daily time';
      case 2:
        return index == 0 ? 'First intake' : 'Second intake';
      case 3:
        return ['First intake', 'Second intake', 'Third intake'][index];
      default:
        return 'Time ${index + 1}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = widget.frequency.administrationsPerDay;

    if (count == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder Times',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),

        Text(
          _getFrequencyDescription(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),

        ...List.generate(count, (index) => _buildTimePicker(index, theme)),
      ],
    );
  }

  String _getFrequencyDescription() {
    return switch (widget.frequency) {
      TreatmentFrequency.onceDaily => 'Set the time for daily administration.',
      TreatmentFrequency.twiceDaily =>
        'Set two times for daily administration.',
      TreatmentFrequency.thriceDaily =>
        'Set three times for daily administration.',
      TreatmentFrequency.everyOtherDay =>
        'Set the time for every-other-day administration.',
      TreatmentFrequency.every3Days =>
        'Set the time for every 3 days administration.',
    };
  }

  Widget _buildTimePicker(int index, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CompactTimePicker(
        time: _selectedTimes[index],
        onTimeChanged: (time) => _updateTime(index, time),
        label: _getTimeLabel(index, _selectedTimes.length),
      ),
    );
  }
}

/// A compact time picker for inline use
class CompactTimePicker extends StatelessWidget {
  /// Creates a [CompactTimePicker]
  const CompactTimePicker({
    required this.time,
    required this.onTimeChanged,
    this.label,
    super.key,
  });

  /// Current selected time
  final TimeOfDay time;

  /// Callback when time changes
  final ValueChanged<TimeOfDay> onTimeChanged;

  /// Optional label for the picker
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showTimePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null) ...[
              Text(
                label!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
            ],

            Icon(
              Icons.access_time,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),

            Text(
              time.format(context),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final result = await showTimePicker(
      context: context,
      initialTime: time,
      builder: (context, child) {
        // Customize time picker appearance
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            timePickerTheme: theme.timePickerTheme.copyWith(
              backgroundColor: theme.colorScheme.surface,
              hourMinuteTextColor: theme.colorScheme.onSurface,
              dayPeriodTextColor: theme.colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      onTimeChanged(result);
    }
  }
}

/// Helper widget for displaying time slots summary
class TimeSlotsSummary extends StatelessWidget {
  /// Creates a [TimeSlotsSummary]
  const TimeSlotsSummary({
    required this.times,
    required this.frequency,
    super.key,
  });

  /// List of times to display
  final List<TimeOfDay> times;

  /// Treatment frequency for context
  final TreatmentFrequency frequency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (times.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Reminder Schedule',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: times
                .asMap()
                .entries
                .map((entry) => _buildTimeChip(context, entry.value, entry.key))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(BuildContext context, TimeOfDay time, int index) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        time.format(context),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
