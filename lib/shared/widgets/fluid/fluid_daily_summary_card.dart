import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/shared/models/fluid_daily_summary_view.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Compact progress bar card for daily fluid summary (Option 1)
class FluidDailySummaryCard extends StatelessWidget {
  /// Creates a compact fluid daily summary card.
  const FluidDailySummaryCard({
    required this.summary,
    this.padding,
    super.key,
  });

  /// Daily fluid data to render.
  final FluidDailySummaryView summary;

  /// Optional padding for the outer container.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final givenStr = _formatMl(summary.givenMl);
    final goalStr = _formatMl(summary.goalMl);

    final progress = summary.goalMl <= 0
        ? 0.0
        : (summary.givenMl / summary.goalMl).clamp(0.0, 1.0);

    final remaining = summary.deltaMl; // positive => left, negative => over
    final hasReachedGoal = summary.hasReachedGoal;
    final missed = !summary.isToday && !hasReachedGoal && summary.goalMl > 0;

    final statusColor = hasReachedGoal
        ? AppColors.primary
        : (summary.isToday
              ? AppColors
                    .success // gold per palette semantics
              : (missed ? AppColors.error : AppColors.textSecondary));

    final statusChip = _buildStatusChip(
      statusColor,
      remaining,
      hasReachedGoal,
      summary.isToday,
      missed,
    );

    return Semantics(
      label: 'Fluid summary: $givenStr of $goalStr',
      child: Container(
        padding: padding ?? const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(givenStr, style: AppTextStyles.h3),
                const SizedBox(width: 6),
                Text('/ $goalStr', style: AppTextStyles.caption),
                const Spacer(),
                statusChip,
              ],
            ),
            const SizedBox(height: 8),
            _ProgressBarWithTick(value: progress, color: statusColor),
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

    if (summary.goalMl <= 0) {
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
      label = '${_formatMl(remaining)} left';
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

  String _formatMl(int ml) {
    return '$ml mL';
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
