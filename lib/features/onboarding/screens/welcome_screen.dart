import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/app/router.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step.dart';
import 'package:hydracat/features/onboarding/widgets/onboarding_screen_wrapper.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/onboarding_provider.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_button.dart';

/// The welcome screen that introduces users to the onboarding flow.
/// This is the entry point for new users to set up their CKD management.
class OnboardingWelcomeScreen extends ConsumerWidget {
  /// Creates an [OnboardingWelcomeScreen].
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return OnboardingScreenWrapper(
      currentStep: 0,
      totalSteps: OnboardingStepType.totalSteps,
      title: l10n.welcomeTitle,
      subtitle: l10n.welcomeSubtitle,
      showBackButton: false,
      showNextButton: false,
      showProgressInAppBar: true,
      stepType: OnboardingStepType.welcome,
      appBarActions: [
        Container(
          height: 20, // Match progress indicator height
          alignment: Alignment.center,
          margin: const EdgeInsets.only(right: 16),
          child: TextButton(
            onPressed: () => _handleSkip(context, ref),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero, // Remove default minimums
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 17, // Slightly larger than progress dots
                fontWeight: FontWeight.w500,
              ),
            ),
            child: Text(l10n.skip),
          ),
        ),
      ],
      child: _buildWelcomeContent(context, ref),
    );
  }

  Widget _buildWelcomeContent(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),

        // Main illustration placeholder
        _buildIllustration(),

        const SizedBox(height: AppSpacing.xl),

        // Additional welcome message (now that subtitle is in wrapper)
        Text(
          l10n.yourCkdJourneyStartsHere,
          style: AppTextStyles.h2.copyWith(
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.xl),

        // Get Started button
        HydraButton(
          onPressed: () => _handleGetStarted(context, ref),
          isFullWidth: true,
          size: HydraButtonSize.large,
          child: Text(l10n.getStarted),
        ),

        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: 200,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.pets,
        size: 80,
        color: AppColors.primary.withValues(alpha: 0.6),
      ),
    );
  }

  Future<void> _handleGetStarted(BuildContext context, WidgetRef ref) async {
    // Get current user for analytics
    final currentUser = ref.read(currentUserProvider);
    final userId = currentUser?.id;

    if (userId == null) {
      debugPrint('[OnboardingWelcome] Error: No current user found');
      if (context.mounted) {
        _showErrorSnackBar(
          context, 
          'Authentication error. Please try logging in again.',
        );
      }
      return;
    }

    debugPrint('[OnboardingWelcome] Starting onboarding for user: $userId');

    // Track onboarding started
    unawaited(
      ref
          .read(analyticsServiceDirectProvider)
          .trackOnboardingStarted(
            userId: userId,
            timestamp: DateTime.now().toIso8601String(),
          ),
    );

    // Try to initialize onboarding session
    final onboardingNotifier = ref.read(onboardingProvider.notifier);
    
    // First, check if user has incomplete onboarding and try to resume
    debugPrint('[OnboardingWelcome] Checking for incomplete onboarding...');
    final hasIncomplete = await onboardingNotifier
        .hasIncompleteOnboarding(userId);
    
    final sessionSuccess = hasIncomplete
        ? await _resumeOnboarding(onboardingNotifier, userId)
        : await _startNewOnboarding(onboardingNotifier, userId);

    if (!sessionSuccess) {
      debugPrint('[OnboardingWelcome] Failed to initialize onboarding session');
      if (context.mounted) {
        // Check if there's a specific error in state
        final error = ref.read(onboardingErrorProvider);
        final errorMessage = error != null
            ? onboardingNotifier.getErrorMessage(error)
            : 'Failed to start onboarding. Please try again.';
        _showErrorSnackBar(context, errorMessage);
      }
      return;
    }

    debugPrint(
      '[OnboardingWelcome] Onboarding session initialized successfully',
    );

    if (!context.mounted) return;

    final route = ModalRoute.of(context);
    if (route is PopupRoute) {
      Navigator.of(context).pop('start');
    } else {
      // Normal routing path (no dialog)
      debugPrint('[OnboardingWelcome] Navigating to next step');
      final nextRoute = await onboardingNotifier.navigateNext();
      if (nextRoute != null && context.mounted) {
        context.go(nextRoute);
      }
    }
  }

  Future<bool> _resumeOnboarding(
    OnboardingNotifier notifier, 
    String userId,
  ) async {
    debugPrint('[OnboardingWelcome] Found incomplete onboarding, resuming...');
    return notifier.resumeOnboarding(userId);
  }

  Future<bool> _startNewOnboarding(
    OnboardingNotifier notifier, 
    String userId,
  ) async {
    debugPrint('[OnboardingWelcome] Starting new onboarding session...');
    return notifier.startOnboarding(userId);
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _handleSkip(BuildContext context, WidgetRef ref) async {
    // Get current user for analytics
    final currentUser = ref.read(currentUserProvider);

    // Track onboarding skipped/abandoned
    unawaited(
      ref
          .read(analyticsServiceDirectProvider)
          .trackOnboardingAbandoned(
            userId: currentUser?.id ?? 'unknown',
            lastStep: 'welcome',
            progressPercentage: 0,
            timeSpentSeconds: 0,
          ),
    );

    // Mark onboarding as skipped in auth state
    final success = await ref
        .read(authProvider.notifier)
        .markOnboardingSkipped();

    if (success) {
      // Manually trigger router refresh to ensure state changes are detected
      ref.read(routerRefreshStreamProvider).refresh();

      if (context.mounted) {
        // Navigate to home first (updates underlying route)
        context.goNamed('home');
        // Give router a moment, then close any dev modal/dialog if present
        final rootNavigator = Navigator.of(context, rootNavigator: true);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await rootNavigator.maybePop();
      }
    } else {
      // Handle error case
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.failedToSkipOnboarding),
          ),
        );
      }
    }
  }
}
