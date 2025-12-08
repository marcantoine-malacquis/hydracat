import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/shared/widgets/bottom_sheets/bottom_sheets.dart';

/// Bottom sheet showing calendar help information and legend.
///
/// Currently displays:
/// - Status color legend explaining dot meanings
///
/// Uses [LoggingPopupWrapper] for consistent bottom sheet presentation.
class CalendarHelpPopup extends StatelessWidget {
  /// Creates a calendar help popup.
  const CalendarHelpPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return LoggingPopupWrapper(
      title: 'Calendar Legend',
      child: _buildContent(context),
    );
  }

  /// Builds the content with help sections.
  Widget _buildContent(BuildContext context) {
    return const _HelpSection(
      title: 'Status Colors',
      children: [
        _LegendItem(
          color: AppColors.primary,
          label: 'Complete',
          description: 'All scheduled treatments completed',
        ),
        SizedBox(height: AppSpacing.md),
        _LegendItem(
          color: Color(0xFFFFB300),
          label: 'Today',
          description: 'Current day (until all treatments complete)',
        ),
        SizedBox(height: AppSpacing.md),
        _LegendItem(
          color: AppColors.warning,
          label: 'Missed',
          description: 'At least one treatment missed',
        ),
        SizedBox(height: AppSpacing.md),
        _LegendItem(
          color: null,
          label: 'No dot',
          description: 'Future days or days with no schedules',
        ),
      ],
    );
  }
}

/// A help section widget that can contain multiple pieces of help content.
///
/// Designed for future expandability to add more help sections beyond
/// the status legend.
class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.children,
    this.title,
  });

  /// Section content widgets
  final List<Widget> children;

  /// Optional section title
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        ...children,
      ],
    );
  }
}

/// A legend item showing a colored dot with label and description.
class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.description,
  });

  /// The color of the dot (null for "no dot" item)
  final Color? color;

  /// The status label
  final String label;

  /// The description text
  final String description;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $description',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot indicator (or empty space for "no dot")
          SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: color != null
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    )
                  : const SizedBox(
                      width: 8,
                      height: 8,
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Label and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the calendar help popup as a bottom sheet.
///
/// Displays calendar legend and help information.
/// Uses platform-adaptive bottom sheet presentation and is dismissible by
/// dragging down, tapping background, or close button.
///
/// Example:
/// ```dart
/// showCalendarHelpPopup(context);
/// ```
void showCalendarHelpPopup(BuildContext context) {
  showHydraBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    builder: (sheetContext) => const HydraBottomSheet(
      backgroundColor: AppColors.background,
      child: CalendarHelpPopup(),
    ),
  );
}
