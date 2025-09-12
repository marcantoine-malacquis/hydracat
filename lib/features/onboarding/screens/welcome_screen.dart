import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/app/router.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/onboarding/widgets/onboarding_screen_wrapper.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/onboarding_provider.dart';

/// The welcome screen that introduces users to the onboarding flow.
/// This is the entry point for new users to set up their CKD management.
class OnboardingWelcomeScreen extends ConsumerWidget {
  /// Creates an [OnboardingWelcomeScreen].
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingWelcomeWrapper(
      title: 'Welcome to HydraCat',
      subtitle: "Let's set up your CKD management toolkit in just a few steps",
      onGetStarted: () => _handleGetStarted(context, ref),
      onSkip: () => _handleSkip(context, ref),
      child: _buildWelcomeContent(context),
    );
  }

  Widget _buildWelcomeContent(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),

        // Main illustration placeholder
        _buildIllustration(),

        const SizedBox(height: AppSpacing.xl),

        // Welcome message
        _buildWelcomeMessage(),

        const SizedBox(height: AppSpacing.lg),

        // Benefits list
        _buildBenefitsList(),

        const SizedBox(height: AppSpacing.xl),
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

  Widget _buildWelcomeMessage() {
    return Column(
      children: [
        Text(
          'Your CKD Journey Starts Here',
          style: AppTextStyles.h2.copyWith(
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          "Managing chronic kidney disease can feel overwhelming, but you're "
          'not alone. HydraCat helps you track treatments, monitor progress, '
          'and stay connected with your vet.',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBenefitsList() {
    const benefits = [
      'Track fluid therapy and medications',
      "Monitor your cat's progress over time",
      'Generate reports for vet visits',
      'Set reminders and stay organized',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: benefits.map(_buildBenefitItem).toList(),
    );
  }

  Widget _buildBenefitItem(String benefit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(
              top: 8,
              right: AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: Text(
              benefit,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
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
        _showErrorSnackBar(
          context, 
          'Failed to start onboarding. Please try again.',
        );
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
      debugPrint('[OnboardingWelcome] Navigating to persona screen');
      context.go('/onboarding/persona');
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
          const SnackBar(
            content: Text('Failed to skip onboarding. Please try again.'),
          ),
        );
      }
    }
  }
}
