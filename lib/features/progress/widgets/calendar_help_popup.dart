import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';

/// Full-screen popup showing calendar help information and legend.
///
/// Currently displays:
/// - Status color legend explaining dot meanings
///
/// Uses [OverlayService.showFullScreenPopup] with slideUp animation.
class CalendarHelpPopup extends StatelessWidget {
  /// Creates a calendar help popup.
  const CalendarHelpPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          liveRegion: true,
          label: 'Calendar legend help',
          child: Container(
            margin: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: mediaQuery.padding.bottom + AppSpacing.sm,
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            constraints: BoxConstraints(
              maxHeight: mediaQuery.size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: AppSpacing.md),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildContent(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the header with title and close button.
  Widget _buildHeader(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'Calendar Legend',
            style: AppTextStyles.h2,
          ),
        ),
        SizedBox(
          width: AppSpacing.minTouchTarget,
          height: AppSpacing.minTouchTarget,
          child: IconButton(
            icon: Icon(Icons.close),
            onPressed: OverlayService.hide,
            tooltip: 'Close',
            iconSize: 24,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
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
        SizedBox(height: AppSpacing.sm),
        _LegendItem(
          color: Color(0xFFFFB300),
          label: 'Today',
          description: 'Current day (until all treatments complete)',
        ),
        SizedBox(height: AppSpacing.sm),
        _LegendItem(
          color: AppColors.warning,
          label: 'Missed',
          description: 'At least one treatment missed',
        ),
        SizedBox(height: AppSpacing.sm),
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

/// Shows the calendar help popup with blur background.
///
/// Displays calendar legend and help information.
/// Uses slideUp animation and is dismissible by tapping background or close
/// button.
///
/// Example:
/// ```dart
/// showCalendarHelpPopup(context);
/// ```
void showCalendarHelpPopup(BuildContext context) {
  OverlayService.showFullScreenPopup(
    context: context,
    child: const CalendarHelpPopup(),
  );
}
