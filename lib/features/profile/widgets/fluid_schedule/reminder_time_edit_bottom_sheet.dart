import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Bottom sheet for editing fluid schedule reminder time
class ReminderTimeEditBottomSheet extends StatefulWidget {
  /// Creates a [ReminderTimeEditBottomSheet]
  const ReminderTimeEditBottomSheet({
    this.initialValue,
    super.key,
  });

  /// Initial reminder time value (null if not set)
  final DateTime? initialValue;

  @override
  State<ReminderTimeEditBottomSheet> createState() =>
      _ReminderTimeEditBottomSheetState();
}

class _ReminderTimeEditBottomSheetState
    extends State<ReminderTimeEditBottomSheet> {
  DateTime? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialValue;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime() async {
    final selectedTime = await HydraTimePicker.show(
      context: context,
      initialTime: _selectedTime != null
          ? TimeOfDay.fromDateTime(_selectedTime!)
          : const TimeOfDay(hour: 9, minute: 0),
    );

    if (selectedTime != null && mounted) {
      final now = DateTime.now();
      final newTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      setState(() {
        _selectedTime = newTime;
      });
    }
  }

  void _save() {
    Navigator.of(context).pop(_selectedTime);
  }

  @override
  Widget build(BuildContext context) {
    final isCupertino =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return LoggingPopupWrapper(
      title: 'Edit Reminder Time',
      leading: HydraBackButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      trailing: TextButton(
        onPressed: _save,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Save',
          style: AppTextStyles.buttonPrimary.copyWith(
            fontWeight: isCupertino ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
      showCloseButton: false,
      onDismiss: () {
        // No special cleanup needed
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: _selectTime,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const HydraIcon(
                    icon: AppIcons.reminderTime,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reminder Time',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _selectedTime != null
                              ? _formatTime(_selectedTime!)
                              : 'Tap to select time',
                          style: AppTextStyles.body.copyWith(
                            color: _selectedTime != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const HydraIcon(
                    icon: AppIcons.chevronRight,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
