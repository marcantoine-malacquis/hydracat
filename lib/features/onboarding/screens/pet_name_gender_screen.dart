import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/extensions/string_extensions.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/core/validation/models/validation_result.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';
import 'package:hydracat/features/onboarding/services/onboarding_validation_service.dart';
import 'package:hydracat/features/onboarding/widgets/gender_selector.dart';
import 'package:hydracat/features/onboarding/widgets/onboarding_screen_wrapper.dart';
import 'package:hydracat/features/onboarding/widgets/pet_info_screen_layout.dart';
import 'package:hydracat/providers/onboarding_provider.dart';
import 'package:hydracat/shared/widgets/validation_error_display.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Pet name and gender collection screen - First step of pet information
class PetNameGenderScreen extends ConsumerStatefulWidget {
  /// Creates a [PetNameGenderScreen]
  const PetNameGenderScreen({super.key});

  @override
  ConsumerState<PetNameGenderScreen> createState() =>
      _PetNameGenderScreenState();
}

class _PetNameGenderScreenState extends ConsumerState<PetNameGenderScreen> {
  final _nameController = TextEditingController();
  String? _selectedGender;
  ValidationResult? _validationResult;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Load any previously saved pet name and gender
  Future<void> _loadSavedData() async {
    final onboardingData = ref.read(onboardingDataProvider);
    if (onboardingData == null) return;

    if (onboardingData.petName != null && onboardingData.petName!.isNotEmpty) {
      _nameController.text = onboardingData.petName!;
    }

    if (onboardingData.petGender != null &&
        onboardingData.petGender!.isNotEmpty) {
      setState(() {
        _selectedGender = onboardingData.petGender;
      });
    }
  }

  /// Save form data and proceed to next step
  Future<void> _saveAndContinue() async {
    setState(() {
      _isLoading = true;
      _validationResult = null;
    });

    try {
      final currentData =
          ref.read(onboardingDataProvider) ?? const OnboardingData.empty();

      final updatedData = currentData.copyWith(
        petName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.capitalize,
        petGender: _selectedGender,
      );

      // Perform validation
      final validationResult = OnboardingValidationService.validateCurrentStep(
        updatedData,
        OnboardingSteps.petNameGender,
      );

      if (!validationResult.isValid) {
        setState(() {
          _validationResult = validationResult;
          _isLoading = false;
        });
        return;
      }

      // Validation passed, update onboarding data
      await ref.read(onboardingProvider.notifier).updateData(updatedData);

      // Navigate to next step
      if (mounted) {
        final nextRoute =
            await ref.read(onboardingProvider.notifier).navigateNext();

        if (nextRoute != null && mounted && context.mounted) {
          context.go(nextRoute);
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        HydraSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Navigate back to previous step
  Future<void> _goBack() async {
    final previousRoute =
        await ref.read(onboardingProvider.notifier).navigatePrevious();

    if (previousRoute != null && mounted && context.mounted) {
      context.go(previousRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return OnboardingScreenWrapper(
      currentStep:
          OnboardingSteps.all.indexOf(OnboardingSteps.petNameGender),
      totalSteps: OnboardingSteps.all.length,
      title: l10n.petNameGenderTitle,
      onBackPressed: _goBack,
      showNextButton: false,
      stepId: OnboardingSteps.petNameGender,
      showProgressInAppBar: true,
      child: PetInfoScreenLayout(
        illustration: const Icon(
          Icons.pets,
          size: 80,
          color: AppColors.primary,
        ),
        title: l10n.petNameGenderQuestion,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pet Name
            const SizedBox(height: AppSpacing.sm),
            HydraTextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: l10n.petNameHint,
                border: OutlineInputBorder(
                  borderRadius: AppBorderRadius.inputRadius,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.inputRadius,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.inputRadius,
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
              onChanged: (_) {
                if (_validationResult != null) {
                  setState(() {
                    _validationResult = null;
                  });
                }
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // Gender
            GenderSelector(
              selectedGender: _selectedGender,
              maleLabel: l10n.genderMale,
              femaleLabel: l10n.genderFemale,
              onGenderChanged: (gender) {
                setState(() {
                  _selectedGender = gender;
                  _validationResult = null;
                });
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // Validation error display
            if (_validationResult != null && !_validationResult!.isValid) ...[
              ValidationErrorDisplay(
                validationResult: _validationResult!,
                compact: true,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Save & Continue Button
            HydraButton(
              onPressed: _isLoading ? null : _saveAndContinue,
              isFullWidth: true,
              size: HydraButtonSize.large,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.surface,
                        ),
                      ),
                    )
                  : Text(l10n.saveAndContinue),
            ),
          ],
        ),
      ),
    );
  }
}
