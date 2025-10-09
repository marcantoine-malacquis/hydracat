import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';

/// A universal iOS-style time picker that works on both iOS and Android.
/// Provides a wheel-style picker with digital display and app theme
/// integration.
class HydraTimePicker {
  /// Shows an iOS-style time picker with wheel interface and digital display.
  ///
  /// Returns the selected [TimeOfDay] or null if cancelled.
  static Future<TimeOfDay?> show({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) async {
    return showCupertinoModalPopup<TimeOfDay>(
      context: context,
      builder: (BuildContext context) => _HydraTimePickerContent(
        initialTime: initialTime,
      ),
    );
  }
}

/// Internal widget that handles the time picker content and state.
class _HydraTimePickerContent extends StatefulWidget {
  const _HydraTimePickerContent({
    required this.initialTime,
  });

  final TimeOfDay initialTime;

  @override
  State<_HydraTimePickerContent> createState() =>
      _HydraTimePickerContentState();
}

class _HydraTimePickerContentState extends State<_HydraTimePickerContent> {
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
  }

  /// Convert TimeOfDay to DateTime for the picker
  DateTime _dateTimeFromTimeOfDay(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
  }

  /// Format time for display
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Format time with AM/PM for 12-hour format
  String _formatTime12Hour(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final use24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;

    return Container(
      height: 350,
      padding: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      child: CupertinoTheme(
        data: const CupertinoThemeData(
          primaryColor: AppColors.primary,
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: TextStyle(fontSize: 21),
          ),
        ),
        child: Column(
          children: [
            // Header with Cancel/Done buttons and digital display
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  // Digital display showing selected time
                  Text(
                    use24HourFormat
                        ? _formatTime(_selectedTime)
                        : _formatTime12Hour(_selectedTime),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(_selectedTime),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Wheel picker
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: use24HourFormat,
                initialDateTime: _dateTimeFromTimeOfDay(_selectedTime),
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() {
                    _selectedTime = TimeOfDay.fromDateTime(newDateTime);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
