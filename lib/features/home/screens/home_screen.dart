import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/widgets/empty_states/onboarding_cta_empty_state.dart';
import 'package:hydracat/shared/widgets/selection_card.dart';
import 'package:hydracat/shared/widgets/status/connection_status_widget.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// A screen that displays the main home interface for the HydraCat app.
class HomeScreen extends ConsumerWidget {
  /// Creates a home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);

    return DevBanner(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('HydraCat'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: const [
            ConnectionStatusWidget(),
          ],
        ),
        body: hasCompletedOnboarding
            ? _buildMainContent(context)
            : OnboardingEmptyStates.home(
                onGetStarted: () => context.go('/onboarding/welcome'),
              ),
      ),
    );
  }

  /// Builds the main home content for users who have completed onboarding
  Widget _buildMainContent(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final profileState = ref.watch(profileProvider);
        final hasFluid = profileState.hasFluidSchedule;
        final hasMedication = profileState.hasMedicationSchedules;

        // Show empty state with setup options if no schedules
        if (!hasFluid && !hasMedication) {
          return _buildEmptyState(context);
        }

        // Show main dashboard with progressive disclosure
        return _buildDashboard(context, hasFluid, hasMedication);
      },
    );
  }

  /// Builds empty state when no schedules are set up
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pets,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              "Let's Get Started!",
              style: AppTextStyles.h1.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              "Set up tracking for your cat's treatment",
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Medication tracking option
            SizedBox(
              width: double.infinity,
              height: 140,
              child: SelectionCard(
                icon: Icons.medication_outlined,
                title: 'Track Medications',
                subtitle: 'Set up medication schedules and reminders',
                layout: CardLayout.rectangle,
                onTap: () => context.push('/profile/medication'),
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
                onTap: () => context.push('/profile/fluid/create'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds dashboard with treatment widgets and progressive disclosure
  Widget _buildDashboard(
    BuildContext context,
    bool hasFluid,
    bool hasMedication,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back',
            style: AppTextStyles.h1.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Placeholder for treatment widgets (will be implemented later)
          if (hasMedication)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.medication, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text('Medication tracking is active'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () => context.push('/profile/medication'),
                    ),
                  ],
                ),
              ),
            ),

          if (hasFluid)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.water_drop, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text('Fluid therapy tracking is active'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () => context.push('/profile/fluid'),
                    ),
                  ],
                ),
              ),
            ),

          // Progressive disclosure CTAs
          const SizedBox(height: AppSpacing.xl),

          if (!hasMedication || !hasFluid) ...[
            Text(
              'Add More Tracking',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          if (!hasMedication)
            SizedBox(
              width: double.infinity,
              height: 140,
              child: SelectionCard(
                icon: Icons.medication_outlined,
                title: 'Track Medications',
                subtitle: 'Set up medication schedules',
                layout: CardLayout.rectangle,
                onTap: () => context.push('/profile/medication'),
              ),
            ),

          if (!hasFluid) ...[
            if (!hasMedication) const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 140,
              child: SelectionCard(
                icon: Icons.water_drop_outlined,
                title: 'Track Fluid Therapy',
                subtitle: 'Set up subcutaneous fluid tracking',
                layout: CardLayout.rectangle,
                onTap: () => context.push('/profile/fluid/create'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
