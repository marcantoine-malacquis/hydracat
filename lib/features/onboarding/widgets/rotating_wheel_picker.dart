import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A reusable iOS-style rotating wheel picker component
class RotatingWheelPicker<T> extends StatefulWidget {
  /// Creates a [RotatingWheelPicker]
  const RotatingWheelPicker({
    required this.items,
    required this.onSelectedItemChanged,
    this.initialIndex = 0,
    this.itemHeight = 32.0,
    this.diameterRatio = 1.07,
    this.useMagnifier = true,
    this.magnification = 1.0,
    super.key,
  });

  /// List of items to display in the picker
  final List<T> items;

  /// Callback when selected item changes
  final ValueChanged<int> onSelectedItemChanged;

  /// Initial selected index
  final int initialIndex;

  /// Height of each item in the picker
  final double itemHeight;

  /// Diameter ratio of the picker cylinder
  final double diameterRatio;

  /// Whether to use magnification effect
  final bool useMagnifier;

  /// Magnification factor for selected item
  final double magnification;

  @override
  State<RotatingWheelPicker<T>> createState() => _RotatingWheelPickerState<T>();
}

class _RotatingWheelPickerState<T> extends State<RotatingWheelPicker<T>> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: widget.itemHeight * 5, // Show ~5 items at once
      child: CupertinoPicker(
        scrollController: _controller,
        itemExtent: widget.itemHeight,
        diameterRatio: widget.diameterRatio,
        useMagnifier: widget.useMagnifier,
        magnification: widget.magnification,
        onSelectedItemChanged: widget.onSelectedItemChanged,
        selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
          background: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        children: widget.items
            .map((item) => _buildPickerItem(context, item))
            .toList(),
      ),
    );
  }

  Widget _buildPickerItem(BuildContext context, T item) {
    final theme = Theme.of(context);

    String displayText;
    if (item is Enum) {
      // Handle enum types - try to get displayName property
      try {
        displayText = (item as dynamic).displayName as String;
      } on Exception {
        // Fallback to name property for simple enums
        displayText = (item as dynamic).name as String;
      }
    } else {
      displayText = item.toString();
    }

    return Center(
      child: Text(
        displayText,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// A specialized time picker component using rotating wheels
class TimePicker extends StatefulWidget {
  /// Creates a [TimePicker]
  const TimePicker({
    required this.onTimeChanged,
    this.initialTime,
    this.use24HourFormat = false,
    super.key,
  });

  /// Callback when selected time changes
  final ValueChanged<TimeOfDay> onTimeChanged;

  /// Initial time to display
  final TimeOfDay? initialTime;

  /// Whether to use 24-hour format
  final bool use24HourFormat;

  @override
  State<TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime ?? TimeOfDay.now();
  }

  void _updateTime({int? hour, int? minute}) {
    setState(() {
      _selectedTime = TimeOfDay(
        hour: hour ?? _selectedTime.hour,
        minute: minute ?? _selectedTime.minute,
      );
    });
    widget.onTimeChanged(_selectedTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Hour picker
          Expanded(
            child: RotatingWheelPicker<int>(
              items: widget.use24HourFormat
                  ? List.generate(24, (index) => index)
                  : List.generate(12, (index) => index + 1),
              initialIndex: widget.use24HourFormat
                  ? _selectedTime.hour
                  : (_selectedTime.hour % 12 == 0
                        ? 11
                        : (_selectedTime.hour % 12) - 1),
              onSelectedItemChanged: (index) {
                final hour = widget.use24HourFormat
                    ? index
                    : (index + 1) % 12 + (_selectedTime.hour >= 12 ? 12 : 0);
                _updateTime(hour: hour);
              },
            ),
          ),

          // Separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              ':',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),

          // Minute picker
          Expanded(
            child: RotatingWheelPicker<int>(
              items: List.generate(60, (index) => index),
              initialIndex: _selectedTime.minute,
              onSelectedItemChanged: (index) => _updateTime(minute: index),
            ),
          ),

          // AM/PM picker for 12-hour format
          if (!widget.use24HourFormat) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 0,
              child: RotatingWheelPicker<String>(
                items: const ['AM', 'PM'],
                initialIndex: _selectedTime.hour >= 12 ? 1 : 0,
                onSelectedItemChanged: (index) {
                  final isPM = index == 1;
                  final currentHour12 = _selectedTime.hour % 12;
                  final newHour = isPM ? currentHour12 + 12 : currentHour12;
                  _updateTime(hour: newHour);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom picker item widget for special formatting
class PickerItem extends StatelessWidget {
  /// Creates a [PickerItem]
  const PickerItem({
    required this.text,
    this.subtitle,
    this.isSelected = false,
    super.key,
  });

  /// Main text to display
  final String text;

  /// Optional subtitle text
  final String? subtitle;

  /// Whether this item is currently selected
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.8)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
