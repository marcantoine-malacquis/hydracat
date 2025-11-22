import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';

/// Empty state widget shown when all treatments are completed for today.
///
/// Displays a celebratory success message with completion count.
class DashboardEmptyState extends StatelessWidget {
  /// Creates a [DashboardEmptyState].
  const DashboardEmptyState({
    required this.completedCount,
    super.key,
  });

  /// Number of treatments completed today
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'All treatments completed. '
          '$completedCount ${completedCount == 1 ? "treatment" : "treatments"} '
          'completed today',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              const Icon(
                Icons.check_circle,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Success message
              Text(
                'All Done for Today!',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Completion count
              Text(
                '$completedCount '
                '${completedCount == 1 ? "treatment" : "treatments"} '
                'completed',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
