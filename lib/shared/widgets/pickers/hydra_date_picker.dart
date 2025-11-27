import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';

/// Platform-adaptive date picker for HydraCat.
///
/// Wraps `showDatePicker` on Material platforms and [CupertinoDatePicker]
/// on iOS/macOS, while mirroring the core `showDatePicker` API used in the app.
///
/// On Material platforms, this delegates directly to `showDatePicker` with
/// all parameters passed through, including the `builder` parameter
/// for theming.
///
/// On iOS/macOS, this shows a bottom sheet modal with a [CupertinoDatePicker]
/// and Cancel/Done actions. The `builder` parameter is currently ignored on
/// Cupertino platforms (documented limitation for future enhancement).
class HydraDatePicker {
  /// Shows a platform-adaptive date picker.
  ///
  /// Returns the selected [DateTime] or null if cancelled.
  ///
  /// The [context], [initialDate], [firstDate], and [lastDate] parameters
  /// are required. All other parameters are optional and mirror the
  /// [showDatePicker] API for compatibility.
  ///
  /// **Note**: The [builder] parameter is only used on Material platforms.
  /// On iOS/macOS, it is currently ignored.
  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    Locale? locale,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    TextDirection? textDirection,
    TransitionBuilder? builder,
    DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendarOnly,
    SelectableDayPredicate? selectableDayPredicate,
    DateTime? currentDate,
    DatePickerMode initialDatePickerMode = DatePickerMode.day,
    bool barrierDismissible = true,
  }) async {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return _showCupertino(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        currentDate: currentDate,
        barrierDismissible: barrierDismissible,
      );
    }

    return _showMaterial(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: locale,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      textDirection: textDirection,
      builder: builder,
      initialEntryMode: initialEntryMode,
      selectableDayPredicate: selectableDayPredicate,
      currentDate: currentDate,
      initialDatePickerMode: initialDatePickerMode,
    );
  }

  /// Material platform implementation using [showDatePicker].
  static Future<DateTime?> _showMaterial({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    Locale? locale,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    TextDirection? textDirection,
    TransitionBuilder? builder,
    DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendarOnly,
    SelectableDayPredicate? selectableDayPredicate,
    DateTime? currentDate,
    DatePickerMode initialDatePickerMode = DatePickerMode.day,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: locale,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      textDirection: textDirection,
      builder: builder,
      initialEntryMode: initialEntryMode,
      selectableDayPredicate: selectableDayPredicate,
      currentDate: currentDate,
      initialDatePickerMode: initialDatePickerMode,
    );
  }

  /// Cupertino platform implementation using [CupertinoDatePicker] in a modal.
  static Future<DateTime?> _showCupertino({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    DateTime? currentDate,
    bool barrierDismissible = true,
  }) {
    return showCupertinoModalPopup<DateTime>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) => _HydraCupertinoDatePickerContent(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        currentDate: currentDate,
      ),
    );
  }
}

/// Internal widget that handles the Cupertino date picker content and state.
class _HydraCupertinoDatePickerContent extends StatefulWidget {
  const _HydraCupertinoDatePickerContent({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.currentDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? currentDate;

  @override
  State<_HydraCupertinoDatePickerContent> createState() =>
      _HydraCupertinoDatePickerContentState();
}

class _HydraCupertinoDatePickerContentState
    extends State<_HydraCupertinoDatePickerContent> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    // Clamp initial date to valid range
    var initial = widget.initialDate;
    if (initial.isBefore(widget.firstDate)) {
      initial = widget.firstDate;
    } else if (initial.isAfter(widget.lastDate)) {
      initial = widget.lastDate;
    }
    _selectedDate = initial;
  }

  /// Format date for display in header
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      padding: const EdgeInsets.only(top: 6),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
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
            // Header with Cancel/Done buttons and date display
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
                        color: AppColors.error,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  // Date display showing selected date
                  Text(
                    _formatDate(_selectedDate),
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
                    onPressed: () => Navigator.of(context).pop(_selectedDate),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Wheel picker
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                minimumDate: widget.firstDate,
                maximumDate: widget.lastDate,
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() {
                    _selectedDate = newDateTime;
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
