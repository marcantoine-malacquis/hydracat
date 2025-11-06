import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';

/// Stat card widget for displaying a single weight entry
///
/// Used when there's only one weight data point available.
/// Shows the weight value, date, and encourages more logging.
class WeightStatCard extends StatelessWidget {
  /// Creates a [WeightStatCard]
  const WeightStatCard({
    required this.weight,
    required this.date,
    required this.unit,
    super.key,
  });

  /// Weight value in the display unit
  final double weight;

  /// Date of the weight measurement
  final DateTime date;

  /// Unit to display (kg or lbs)
  final String unit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${weight.toStringAsFixed(2)} $unit',
              style: AppTextStyles.display.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              DateFormat('MMM dd, yyyy').format(date),
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Log more weights to see trends',
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
