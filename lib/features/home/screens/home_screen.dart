import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/config/flavor_config.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/onboarding/screens/welcome_screen.dart';
import 'package:hydracat/shared/widgets/status/connection_status_widget.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// A screen that displays the main home interface for the HydraCat app.
class HomeScreen extends ConsumerWidget {
  /// Creates a home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: Padding(
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
                'Hydration tracking for cats with kidney disease',
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
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// Shows the onboarding flow in a modal dialog (development only).
  void _showOnboardingModal(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing during onboarding
      builder: (BuildContext context) {
        return const Dialog.fullscreen(
          child: OnboardingWelcomeScreen(),
        );
      },
    );
  }
}
