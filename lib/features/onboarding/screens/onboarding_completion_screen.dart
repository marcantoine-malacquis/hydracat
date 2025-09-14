import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/onboarding/exceptions/onboarding_exceptions.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step.dart';
import 'package:hydracat/features/onboarding/widgets/onboarding_screen_wrapper.dart';
import 'package:hydracat/providers/onboarding_provider.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_button.dart';

/// Final screen in the onboarding flow that celebrates completion
/// and performs the single Firebase write operation
class OnboardingCompletionScreen extends ConsumerStatefulWidget {
  /// Creates an [OnboardingCompletionScreen]
  const OnboardingCompletionScreen({super.key});

  @override
  ConsumerState<OnboardingCompletionScreen> createState() =>
      _OnboardingCompletionScreenState();
}

class _OnboardingCompletionScreenState
    extends ConsumerState<OnboardingCompletionScreen> {
  bool _isCompleting = false;
  OnboardingException? _completionError;

  @override
  Widget build(BuildContext context) {
    final onboardingData = ref.watch(onboardingDataProvider);
    final petName = onboardingData?.petName ?? 'your cat';

    return OnboardingScreenWrapper(
      currentStep: OnboardingStepType.completion.index,
      totalSteps: OnboardingStepType.totalSteps,
      title: "You're all set!",
      subtitle: "Ready to start tracking $petName's care journey",
      onBackPressed: _goBack,
      showNextButton: false,
      stepName: 'completion',
      showProgressInAppBar: true,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Main celebratory content
          _buildCelebratoryContent(petName),

          const SizedBox(height: AppSpacing.xxl),

          // Error display if completion failed
          if (_completionError != null) ...[
            _buildErrorMessage(),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Finish button
          _buildFinishButton(),

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildCelebratoryContent(String petName) {
    return Column(
      children: [
        // Success icon placeholder (space for future illustration)
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(60),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.pets,
            size: 60,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Main message
        Text(
          "Perfect! You're ready to give $petName the best care possible.",
          style: AppTextStyles.h2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.md),

        // Supporting message
        Text(
          'Start logging treatments, track progress, and stay on top of '
          "$petName's health journey.",
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Setup could not be completed',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          Text(
            _completionError?.message ?? 'An unexpected error occurred',
            style: AppTextStyles.body.copyWith(
              color: AppColors.error,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            "Don't worry - your information has been saved. "
            'Please try again.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: HydraButton(
        onPressed: _isCompleting ? null : _handleFinishPressed,
        child: _isCompleting
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.surface,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text('Finishing setup...'),
                ],
              )
            : Text(_completionError != null ? 'Try Again' : 'Finish'),
      ),
    );
  }

  Future<void> _handleFinishPressed() async {
    // Clear any previous error
    setState(() {
      _completionError = null;
      _isCompleting = true;
    });

    try {
      // Complete onboarding through the provider
      final success = await ref
          .read(onboardingProvider.notifier)
          .completeOnboarding();

      if (success) {
        // Success! Navigation to home screen will happen automatically
        // through the auth state update in the provider
        if (mounted) {
          // Navigate to home screen
          await Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
        }
      } else {
        // Handle failure - error should be in provider state
        final error = ref.read(onboardingErrorProvider);
        setState(() {
          _completionError = error;
          _isCompleting = false;
        });
      }
    } on Exception catch (e) {
      // Handle unexpected errors
      setState(() {
        _completionError = OnboardingServiceException(
          'Unexpected error occurred: $e',
        );
        _isCompleting = false;
      });
    }
  }

  /// Navigate back to previous step
  Future<void> _goBack() async {
    await ref.read(onboardingProvider.notifier).moveToPreviousStep();
    if (mounted) {
      // Navigate to previous screen (treatment setup)
      context.go('/onboarding/treatment');
    }
  }
}
