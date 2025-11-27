import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/shared/models/medication_daily_summary_view.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Compact status card for daily medication summary
///
/// Displays medication dose completion status with a chip-style indicator.
/// Matches visual hierarchy with 'FluidDailySummaryCard' while being more
/// compact since medication status is simpler (doses vs volume).
class MedicationDailySummaryCard extends StatelessWidget {
  /// Creates a compact medication daily summary card.
  const MedicationDailySummaryCard({
    required this.summary,
    this.padding,
    super.key,
  });

  /// Daily medication data to render.
  final MedicationDailySummaryView summary;

  /// Optional padding for the outer container.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final completedStr = summary.completedDoses.toString();
    final scheduledStr = summary.scheduledDoses.toString();
    final hasReachedGoal = summary.hasReachedGoal;
    final missed =
        !summary.isToday && !hasReachedGoal && summary.scheduledDoses > 0;

    final statusColor = hasReachedGoal
        ? AppColors.primary
        : (summary.isToday
              ? AppColors
                    .success // gold per palette semantics
              : (missed ? AppColors.error : AppColors.textSecondary));

    final statusChip = _buildStatusChip(
      statusColor,
      summary.remainingDoses,
      hasReachedGoal,
      summary.isToday,
      missed,
    );

    final extraDoses = summary.extraDoses;
    final semanticsLabel = extraDoses > 0
        ? 'Medication summary: $completedStr of $scheduledStr doses, '
              'including $extraDoses extra '
              '${extraDoses == 1 ? 'dose' : 'doses'}'
        : 'Medication summary: $completedStr of $scheduledStr doses';

    return Semantics(
      label: semanticsLabel,
      child: Container(
        padding: padding ?? const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(completedStr, style: AppTextStyles.h3),
                const SizedBox(width: 6),
                Text('/ $scheduledStr doses', style: AppTextStyles.caption),
                const Spacer(),
                statusChip,
              ],
            ),
            const SizedBox(height: 8),
            _ProgressBarWithTick(
              value: summary.scheduledDoses <= 0
                  ? 0.0
                  : (summary.completedDoses / summary.scheduledDoses).clamp(
                      0.0,
                      1.0,
                    ),
              color: statusColor,
            ),
            // Show extra doses caption if applicable
            if (extraDoses > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Includes $extraDoses extra '
                '${extraDoses == 1 ? 'logged dose' : 'logged doses'}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    Color color,
    int remaining,
    bool reached,
    bool isToday,
    bool missed,
  ) {
    IconData icon;
    String label;
    Color iconColor;
    Color? backgroundColor;
    Color borderColor;

    if (summary.scheduledDoses <= 0) {
      icon = Icons.info_outline;
      label = 'No goal';
      iconColor = color;
      backgroundColor = Colors.transparent; // Outlined chip
      borderColor = color;
    } else if (reached) {
      icon = Icons.check_circle;
      label = 'Goal reached';
      iconColor = Colors.white;
      backgroundColor = AppColors.primary; // Filled chip for completion
      borderColor = AppColors.primary;
    } else if (isToday) {
      icon = Icons.schedule;
      label = remaining > 0 ? '$remaining left' : 'Pending';
      iconColor = AppColors.successDark; // Darker amber for better contrast
      backgroundColor = Colors.transparent; // Outlined chip for in-progress
      borderColor = AppColors.successDark;
    } else if (missed) {
      icon = Icons.cancel;
      label = 'Missed';
      iconColor = color;
      backgroundColor = Colors.transparent; // Outlined chip
      borderColor = color;
    } else {
      icon = Icons.info_outline;
      label = 'Pending';
      iconColor = color;
      backgroundColor = Colors.transparent; // Outlined chip
      borderColor = color;
    }

    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      visualDensity: VisualDensity.compact,
      backgroundColor: backgroundColor,
      avatar: Icon(icon, size: 18, color: iconColor),
      label: Text(
        label,
        style: TextStyle(
          color: reached ? Colors.white : AppColors.textPrimary,
        ),
      ),
      side: BorderSide(
        color: reached ? borderColor : borderColor.withValues(alpha: 0.5),
      ),
    );
  }
}

class _ProgressBarWithTick extends StatelessWidget {
  const _ProgressBarWithTick({required this.value, required this.color});

  final double value; // 0..1
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                builder: (context, val, _) => HydraProgressIndicator(
                  type: HydraProgressIndicatorType.linear,
                  value: val.isNaN ? 0 : math.max(0, math.min(1, val)),
                  minHeight: 8,
                  backgroundColor: AppColors.textSecondary.withValues(
                    alpha: 0.12,
                  ),
                  color: color,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
