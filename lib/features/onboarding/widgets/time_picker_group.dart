import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_accessibility.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/shared/widgets/accessibility/hydra_touch_target.dart';
import 'package:hydracat/shared/widgets/pickers/hydra_time_picker.dart';

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

  String _getTimeLabel(BuildContext context, int index, int total) {
    final l10n = context.l10n;

    switch (total) {
      case 1:
        return l10n.dailyTime;
      case 2:
        return index == 0 ? l10n.firstIntake : l10n.secondIntake;
      case 3:
        return [l10n.firstIntake, l10n.secondIntake, l10n.thirdIntake][index];
      default:
        return l10n.timeNumber(index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final count = widget.frequency.administrationsPerDay;

    if (count == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.reminderTimesLabel,
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
        label: _getTimeLabel(context, index, _selectedTimes.length),
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

    return HydraTouchTarget(
      semanticLabel: label != null ? 'Select $label' : 'Select time',
      child: GestureDetector(
        onTap: () => _showTimePicker(context),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: AppAccessibility.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.surface,
          ),
          child: Row(
            children: [
              if (label != null) ...[
                SizedBox(
                  width: 120,
                  child: Text(
                    label!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Push the icon+time group to the right while
                // keeping them tight
                const Spacer(),
              ],

              Icon(
                Icons.access_time,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),

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
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final result = await HydraTimePicker.show(
      context: context,
      initialTime: time,
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
      padding: const EdgeInsets.all(AppSpacing.md),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
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
