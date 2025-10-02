import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step.dart';
import 'package:hydracat/features/onboarding/widgets/onboarding_screen_wrapper.dart';
import 'package:hydracat/features/onboarding/widgets/persona_selection_card.dart';
import 'package:hydracat/features/profile/models/user_persona.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/onboarding_provider.dart';

/// Screen for selecting user treatment persona during onboarding
class UserPersonaScreen extends ConsumerStatefulWidget {
  /// Creates a [UserPersonaScreen]
  const UserPersonaScreen({super.key});

  @override
  ConsumerState<UserPersonaScreen> createState() => _UserPersonaScreenState();
}

class _UserPersonaScreenState extends ConsumerState<UserPersonaScreen> {
  UserPersona? _selectedPersona;
  bool _isProcessingSelection = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[UserPersonaScreen] Screen initialized');

    // Load existing selection if resuming onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existingData = ref.read(onboardingDataProvider);
      debugPrint('[UserPersonaScreen] Existing data: $existingData');

      final existingPersona = existingData?.treatmentApproach;
      if (existingPersona != null) {
        debugPrint(
          '[UserPersonaScreen] Found existing persona: $existingPersona',
        );
        setState(() {
          _selectedPersona = existingPersona;
        });
      }
    });
  }

  Future<void> _handlePersonaSelection(UserPersona persona) async {
    if (_isProcessingSelection) return;

    debugPrint('[UserPersonaScreen] Persona selected: ${persona.name}');

    setState(() {
      _selectedPersona = persona;
      _isProcessingSelection = true;
    });

    // Track selection in analytics
    debugPrint('[UserPersonaScreen] Tracking analytics...');
    await ref
        .read(analyticsServiceDirectProvider)
        .trackFeatureUsed(
          featureName: 'persona_selected',
          additionalParams: {
            'persona': persona.name,
            'display_name': persona.displayName,
          },
        );

    // Update onboarding data with selected persona
    final currentData =
        ref.read(onboardingDataProvider) ?? const OnboardingData.empty();
    final userId = ref.read(currentUserProvider)?.id;

    debugPrint('[UserPersonaScreen] Current data: $currentData');
    debugPrint('[UserPersonaScreen] User ID: $userId');

    final updatedData = currentData.copyWith(
      userId: userId,
      treatmentApproach: persona,
    );

    debugPrint('[UserPersonaScreen] Updated data: $updatedData');
    debugPrint('[UserPersonaScreen] Calling updateData...');

    // Save the data first
    final success = await ref
        .read(onboardingProvider.notifier)
        .updateData(updatedData);

    debugPrint('[UserPersonaScreen] updateData result: $success');

    if (success && mounted) {
      debugPrint('[UserPersonaScreen] Data updated successfully');

      // Check current progress step
      final currentProgress = ref.read(onboardingProgressProvider);
      debugPrint(
        '[UserPersonaScreen] Current progress step: '
        '${currentProgress?.currentStep}',
      );

      // If we're not on userPersona step, fix the progress
      if (currentProgress?.currentStep != OnboardingStepType.userPersona) {
        debugPrint(
          '[UserPersonaScreen] Progress step mismatch! '
          'Fixing by setting to userPersona step...',
        );
        await ref
            .read(onboardingProvider.notifier)
            .setCurrentStep(OnboardingStepType.userPersona);
      }

      // Now move to next step
      debugPrint('[UserPersonaScreen] Navigating to next step...');
      final nextRoute = await ref
          .read(onboardingProvider.notifier)
          .navigateNext();

      debugPrint('[UserPersonaScreen] navigateNext result: $nextRoute');

      if (nextRoute != null && mounted) {
        debugPrint('[UserPersonaScreen] Navigating to $nextRoute');

        // Navigate to next screen
        if (context.mounted) {
          context.go(nextRoute);
        }
      } else {
        // Handle error moving to next step
        debugPrint('[UserPersonaScreen] Failed to get next route');
        setState(() {
          _isProcessingSelection = false;
        });

        if (mounted) {
          // Check if there's a specific error in state
          final error = ref.read(onboardingErrorProvider);
          final errorMessage = error != null
              ? ref.read(onboardingProvider.notifier).getErrorMessage(error)
              : 'Unable to proceed to next step. Please try again.';
          _showErrorSnackBar(errorMessage);
        }
      }
    } else {
      // Handle error updating data
      debugPrint('[UserPersonaScreen] Failed to update data');
      setState(() {
        _selectedPersona = null;
        _isProcessingSelection = false;
      });

      if (mounted) {
        // Check if there's a specific error in state
        final error = ref.read(onboardingErrorProvider);
        final errorMessage = error != null
            ? ref.read(onboardingProvider.notifier).getErrorMessage(error)
            : 'Unable to save your selection. Please try again.';
        _showErrorSnackBar(errorMessage);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _handleBackNavigation() async {
    // Navigate back to previous screen
    final previousRoute = await ref
        .read(onboardingProvider.notifier)
        .navigatePrevious();

    if (previousRoute != null && mounted && context.mounted) {
      context.go(previousRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return OnboardingScreenWrapper(
      currentStep: OnboardingStepType.userPersona.stepIndex,
      totalSteps: OnboardingStepType.totalSteps,
      title: l10n.userPersonaTitle,
      subtitle: l10n.userPersonaSubtitle,
      onBackPressed: _isProcessingSelection ? null : _handleBackNavigation,
      showNextButton: false,
      stepType: OnboardingStepType.userPersona,
      showProgressInAppBar: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),

          // Cards layout
          _buildPersonaCards(),

          const SizedBox(height: AppSpacing.xl),

          // "You can change this anytime" message
          _buildFooterMessage(),

          // Error display
          Consumer(
            builder: (context, ref, child) {
              final error = ref.watch(onboardingErrorProvider);
              if (error != null) {
                return Column(
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    _buildErrorMessage(error.toString()),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // Top row: Two square cards horizontally
          Row(
            children: [
              // Medication Only card
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1, // Square aspect ratio
                  child: PersonaSelectionCard(
                    persona: UserPersona.medicationOnly,
                    isSelected: _selectedPersona == UserPersona.medicationOnly,
                    isLoading:
                        _isProcessingSelection &&
                        _selectedPersona == UserPersona.medicationOnly,
                    onTap: () =>
                        _handlePersonaSelection(UserPersona.medicationOnly),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Fluid Therapy Only card
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1, // Square aspect ratio
                  child: PersonaSelectionCard(
                    persona: UserPersona.fluidTherapyOnly,
                    isSelected:
                        _selectedPersona == UserPersona.fluidTherapyOnly,
                    isLoading:
                        _isProcessingSelection &&
                        _selectedPersona == UserPersona.fluidTherapyOnly,
                    onTap: () =>
                        _handlePersonaSelection(UserPersona.fluidTherapyOnly),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Bottom: Rectangle card with same width as top cards combined
          // Use Expanded to take full available width
          SizedBox(
            height: 160, // Increased height to accommodate full text
            child: Row(
              children: [
                Expanded(
                  child: PersonaSelectionCard(
                    persona: UserPersona.medicationAndFluidTherapy,
                    layout: CardLayout.rectangle,
                    isSelected:
                        _selectedPersona ==
                        UserPersona.medicationAndFluidTherapy,
                    isLoading:
                        _isProcessingSelection &&
                        _selectedPersona ==
                            UserPersona.medicationAndFluidTherapy,
                    onTap: () => _handlePersonaSelection(
                      UserPersona.medicationAndFluidTherapy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'You can change this anytime in Profile',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.errorLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
