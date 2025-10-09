import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/shared/widgets/selection_card.dart';

/// Dialog shown when user taps FAB but has no schedules set up yet
///
/// Provides two clear options:
/// - Set up medication tracking
/// - Set up fluid therapy tracking
class NoSchedulesDialog extends StatelessWidget {
  /// Creates a [NoSchedulesDialog]
  const NoSchedulesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Icon(
              Icons.pets,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              'Get Started',
              style: AppTextStyles.h2.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Text(
              "Set up tracking for your cat's treatment",
              style: AppTextStyles.body.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Medication option
            SizedBox(
              width: double.infinity,
              height: 140,
              child: SelectionCard(
                icon: Icons.medication_outlined,
                title: 'Track Medications',
                subtitle: 'Set up medication schedules',
                layout: CardLayout.rectangle,
                onTap: () {
                  context
                    ..pop()
                    ..push('/profile/medication');
                },
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Fluid therapy option
            SizedBox(
              width: double.infinity,
              height: 140,
              child: SelectionCard(
                icon: Icons.water_drop_outlined,
                title: 'Track Fluid Therapy',
                subtitle: 'Set up subcutaneous fluid tracking',
                layout: CardLayout.rectangle,
                onTap: () {
                  context
                    ..pop()
                    ..push('/profile/fluid/create');
                },
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Later option
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                "I'll do this later",
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
