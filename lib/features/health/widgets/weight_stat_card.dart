import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';

/// Stat card widget for displaying current weight
///
/// Shows the current weight value and optionally a change indicator
/// with trend arrow (up/down/flat) when comparing to previous measurement.
class WeightStatCard extends StatelessWidget {
  /// Creates a [WeightStatCard]
  const WeightStatCard({
    required this.weight,
    required this.unit,
    this.change,
    super.key,
  }) : isEmpty = false;

  /// Creates an empty placeholder [WeightStatCard] for consistent layout
  const WeightStatCard.empty({super.key})
      : weight = 0,
        unit = '',
        change = null,
        isEmpty = true;

  /// Weight value in the display unit
  final double weight;

  /// Unit to display (kg or lbs)
  final String unit;

  /// Weight change from previous measurement (optional)
  final double? change;

  /// Whether this is an empty placeholder card
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    // Return empty placeholder if isEmpty is true
    if (isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '–',
              style: AppTextStyles.h1.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      );
    }

    // Determine trend based on change
    String? trend;
    if (change != null) {
      if (change! > 0.1) {
        trend = 'increasing';
      } else if (change! < -0.1) {
        trend = 'decreasing';
      } else {
        trend = 'stable';
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '${weight.toStringAsFixed(2)} $unit',
            style: AppTextStyles.h1.copyWith(
              color: AppColors.primary,
            ),
          ),
          if (change != null && trend != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(
              trend == 'increasing'
                  ? Icons.trending_up
                  : trend == 'decreasing'
                      ? Icons.trending_down
                      : Icons.trending_flat,
              color: trend == 'increasing'
                  ? Colors.orange
                  : trend == 'decreasing'
                      ? Colors.blue
                      : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${change! >= 0 ? "+" : ""}${change!.toStringAsFixed(2)}',
              style: AppTextStyles.body.copyWith(
                color: trend == 'increasing'
                    ? Colors.orange
                    : trend == 'decreasing'
                        ? Colors.blue
                        : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
