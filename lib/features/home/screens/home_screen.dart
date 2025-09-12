import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/config/flavor_config.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/onboarding/screens/user_persona_screen.dart';
import 'package:hydracat/features/onboarding/screens/welcome_screen.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/shared/widgets/empty_states/onboarding_cta_empty_state.dart';
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
              'Welcome to HydraCat',
              style: AppTextStyles.h1.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Your CKD management dashboard',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.xl),
            HydraButton(
              onPressed: () {
                context.push('/demo');
              },
              isFullWidth: true,
              child: const Text('View Component Demo'),
            ),

            // Development-only onboarding test button
            if (FlavorConfig.isDevelopment) ...[
              const SizedBox(height: AppSpacing.md),
              HydraButton(
                onPressed: () => _showOnboardingModal(context),
                variant: HydraButtonVariant.secondary,
                isFullWidth: true,
                child: const Text('🧪 Test Onboarding'),
              ),
              const SizedBox(height: AppSpacing.md),
              HydraButton(
                onPressed: () => _showPersonaModal(context),
                variant: HydraButtonVariant.secondary,
                isFullWidth: true,
                child: const Text('🧪 Test Persona Screen'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Shows the onboarding flow in a modal dialog (development only).
  Future<void> _showOnboardingModal(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false, // Prevent dismissing during onboarding
      builder: (BuildContext context) {
        return const Dialog.fullscreen(
          child: OnboardingWelcomeScreen(),
        );
      },
    );

    if (context.mounted && result == 'start') {
      context.goNamed('onboarding-persona');
    }
  }

  /// Shows the persona screen in a modal dialog (development only).
  void _showPersonaModal(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return const Dialog.fullscreen(
          child: UserPersonaScreen(),
        );
      },
    );
  }
}
