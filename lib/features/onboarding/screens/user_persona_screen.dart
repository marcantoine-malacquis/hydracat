import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/app_colors.dart';
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
    // Load existing selection if resuming onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existingData = ref.read(onboardingDataProvider);
      if (existingData?.treatmentApproach != null) {
        setState(() {
          _selectedPersona = existingData!.treatmentApproach;
        });
      }
    });
  }

  Future<void> _handlePersonaSelection(UserPersona persona) async {
    if (_isProcessingSelection) return;

    setState(() {
      _selectedPersona = persona;
      _isProcessingSelection = true;
    });

    // Track selection in analytics
    await ref.read(analyticsServiceDirectProvider).trackFeatureUsed(
      featureName: 'persona_selected',
      additionalParams: {
        'persona': persona.name,
        'display_name': persona.displayName,
      },
    );

    // Update onboarding data with selected persona
    final currentData = ref.read(onboardingDataProvider) ??
        const OnboardingData.empty();
    final userId = ref.read(currentUserProvider)?.id;

    final updatedData = currentData.copyWith(
      userId: userId,
      treatmentApproach: persona,
    );

    // Save the data and move to next step
    final success = await ref
        .read(onboardingProvider.notifier)
        .updateData(updatedData);

    if (success && mounted) {
      // Move to next step
      final moveSuccess = await ref
          .read(onboardingProvider.notifier)
          .moveToNextStep();

      if (moveSuccess && mounted) {
        // Navigate to pet basics screen
        if (context.mounted) {
          context.go('/onboarding/basics');
        }
      } else {
        // Handle error moving to next step
        setState(() {
          _isProcessingSelection = false;
        });

        if (mounted) {
          _showErrorSnackBar(
              'Unable to proceed to next step. Please try again.');
        }
      }
    } else {
      // Handle error updating data
      setState(() {
        _selectedPersona = null;
        _isProcessingSelection = false;
      });

      if (mounted) {
        _showErrorSnackBar(
            'Unable to save your selection. Please try again.');
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
    // Navigate back to welcome screen
    if (context.mounted) {
      context.go('/onboarding/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScreenWrapper(
      currentStep: 1, // Step 2 of 5 (0-indexed)
      totalSteps: OnboardingStepType.totalSteps,
      title: "How do you manage your pet's CKD?",
      subtitle: 'Choose the approach that best matches your current '
          'treatment plan',
      stepName: 'user_persona',
      onBackPressed: _handleBackNavigation,
      showNextButton: false, // We handle navigation automatically
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
    return Column(
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
                  isSelected:
                      _selectedPersona == UserPersona.medicationOnly,
                  isLoading: _isProcessingSelection &&
                      _selectedPersona == UserPersona.medicationOnly,
                  onTap: () => _handlePersonaSelection(
                      UserPersona.medicationOnly),
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
                  isLoading: _isProcessingSelection &&
                      _selectedPersona == UserPersona.fluidTherapyOnly,
                  onTap: () => _handlePersonaSelection(
                      UserPersona.fluidTherapyOnly),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Bottom: Full-width rectangle card
        SizedBox(
          height: 100, // Fixed height for rectangle card
          child: PersonaSelectionCard(
            persona: UserPersona.medicationAndFluidTherapy,
            layout: CardLayout.rectangle,
            isSelected: _selectedPersona ==
                UserPersona.medicationAndFluidTherapy,
            isLoading: _isProcessingSelection &&
                _selectedPersona == UserPersona.medicationAndFluidTherapy,
            onTap: () => _handlePersonaSelection(
                UserPersona.medicationAndFluidTherapy),
          ),
        ),
      ],
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
