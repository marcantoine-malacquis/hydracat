import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/core/validation/models/validation_result.dart';
import 'package:hydracat/features/onboarding/exceptions/onboarding_exceptions.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step.dart';
import 'package:hydracat/features/onboarding/services/onboarding_validation_service.dart';
import 'package:hydracat/features/onboarding/widgets/onboarding_screen_wrapper.dart';
import 'package:hydracat/providers/onboarding_provider.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_button.dart';
import 'package:hydracat/shared/widgets/validation_error_display.dart';

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
  ValidationResult? _validationResult;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onboardingData = ref.watch(onboardingDataProvider);
    final petName = onboardingData?.petName ?? 'your cat';

    return OnboardingScreenWrapper(
      currentStep: OnboardingStepType.completion.index,
      totalSteps: OnboardingStepType.totalSteps,
      title: l10n.onboardingCompleteTitle,
      subtitle: l10n.readyToStartTracking(petName),
      onBackPressed: _goBack,
      showNextButton: false,
      stepType: OnboardingStepType.completion,
      showProgressInAppBar: true,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Main celebratory content
          _buildCelebratoryContent(petName),

          const SizedBox(height: AppSpacing.xxl),

          // Error display if completion failed
          if (_completionError != null || _validationResult != null) ...[
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
    // Use validation result if available, otherwise fall back to completion
    // error
    if (_validationResult != null && !_validationResult!.isValid) {
      return ValidationErrorDisplay(
        validationResult: _validationResult!,
        onActionPressed: (actionRoute) {
          context.go(actionRoute);
        },
      );
    }

    // Fallback for non-validation errors
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
            _completionError != null
                ? ref
                      .read(onboardingProvider.notifier)
                      .getErrorMessage(_completionError!)
                : 'An unexpected error occurred',
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
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: HydraButton(
        onPressed: _isCompleting ? null : _handleFinishPressed,
        child: _isCompleting
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.surface,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l10n.finishingSetup),
                ],
              )
            : Text(
                _completionError != null ||
                        (_validationResult != null &&
                            !_validationResult!.isValid)
                    ? l10n.retry
                    : 'Finish',
              ),
      ),
    );
  }

  Future<void> _handleFinishPressed() async {
    // Clear any previous errors
    setState(() {
      _completionError = null;
      _validationResult = null;
      _isCompleting = true;
    });

    try {
      // First, validate the current data before attempting completion
      final onboardingData = ref.read(onboardingDataProvider);
      if (onboardingData == null) {
        setState(() {
          _completionError = const OnboardingServiceException(
            'No onboarding data found. Please start over.',
          );
          _isCompleting = false;
        });
        return;
      }

      // Perform comprehensive validation
      final validationResult = OnboardingValidationService.validateCurrentStep(
        onboardingData,
        OnboardingStepType.completion,
      );

      if (!validationResult.isValid) {
        // Show validation errors instead of attempting completion
        setState(() {
          _validationResult = validationResult;
          _isCompleting = false;
        });
        return;
      }

      // Validation passed, proceed with completion
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
    final previousRoute = await ref
        .read(onboardingProvider.notifier)
        .navigatePrevious();

    if (previousRoute != null && mounted && context.mounted) {
      // Navigate to previous screen
      context.go(previousRoute);
    }
  }
}
