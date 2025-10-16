import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/shared/models/fluid_daily_summary_view.dart';

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
    final reached = summary.reached;
    final missed = !summary.isToday && !reached && summary.goalMl > 0;

    final statusColor = reached
        ? AppColors.primary
        : (summary.isToday
              ? AppColors
                    .success // gold per palette semantics
              : (missed ? AppColors.error : AppColors.textSecondary));

    final statusChip = _buildStatusChip(
      statusColor,
      remaining,
      reached,
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
          border: Border.all(color: AppColors.border),
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
            const SizedBox(height: 6),
            _helperText(remaining, reached, summary.isToday, missed),
          ],
        ),
      ),
    );
  }

  Widget _helperText(int remaining, bool reached, bool isToday, bool missed) {
    if (summary.goalMl <= 0) {
      return const Text('No goal set', style: AppTextStyles.caption);
    }
    if (reached) {
      final over = -remaining;
      return Text(
        over > 0 ? '+${_formatMl(over)} over' : 'Goal reached',
        style: AppTextStyles.caption,
      );
    }
    if (isToday) {
      return Text('${_formatMl(remaining)} left', style: AppTextStyles.caption);
    }
    if (missed) {
      return Text(
        'Missed by ${_formatMl(remaining)}',
        style: AppTextStyles.caption.copyWith(color: AppColors.error),
      );
    }
    return const SizedBox.shrink();
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
    if (summary.goalMl <= 0) {
      icon = Icons.info_outline;
      label = 'No goal';
    } else if (reached) {
      icon = Icons.check_circle;
      label = 'Goal reached';
    } else if (isToday) {
      icon = Icons.schedule;
      label = '${_formatMl(remaining)} left';
    } else if (missed) {
      icon = Icons.cancel;
      label = 'Missed';
    } else {
      icon = Icons.info_outline;
      label = 'Pending';
    }

    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      side: BorderSide(color: color.withValues(alpha: 0.25)),
    );
  }

  String _formatMl(int ml) {
    if (ml >= 1000) {
      final liters = ml / 1000.0;
      return '${liters.toStringAsFixed(liters >= 10 ? 0 : 1)} L';
    }
    return '$ml ml';
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
        final width = constraints.maxWidth;
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                builder: (context, val, _) => LinearProgressIndicator(
                  value: val.isNaN ? 0 : math.max(0, math.min(1, val)),
                  minHeight: 8,
                  backgroundColor: AppColors.textSecondary.withValues(
                    alpha: 0.12,
                  ),
                  color: color,
                ),
              ),
            ),
            Positioned(
              left: width - 2,
              top: 0,
              bottom: 0,
              child: Container(width: 2, color: AppColors.border),
            ),
          ],
        );
      },
    );
  }
}
