import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/core/validation/models/validation_result.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';
import 'package:hydracat/features/onboarding/services/onboarding_validation_service.dart';
import 'package:hydracat/features/onboarding/widgets/onboarding_screen_wrapper.dart';
import 'package:hydracat/features/onboarding/widgets/pet_info_screen_layout.dart';
import 'package:hydracat/providers/onboarding_provider.dart';
import 'package:hydracat/shared/widgets/validation_error_display.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Pet date of birth collection screen
class PetDateOfBirthScreen extends ConsumerStatefulWidget {
  /// Creates a [PetDateOfBirthScreen]
  const PetDateOfBirthScreen({super.key});

  @override
  ConsumerState<PetDateOfBirthScreen> createState() =>
      _PetDateOfBirthScreenState();
}

class _PetDateOfBirthScreenState extends ConsumerState<PetDateOfBirthScreen> {
  DateTime? _selectedDateOfBirth;
  ValidationResult? _validationResult;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  /// Load any previously saved date of birth
  Future<void> _loadSavedData() async {
    final onboardingData = ref.read(onboardingDataProvider);
    if (onboardingData == null) return;

    if (onboardingData.petDateOfBirth != null) {
      setState(() {
        _selectedDateOfBirth = onboardingData.petDateOfBirth;
      });
    }
  }

  /// Show date picker for date of birth
  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 25, now.month, now.day);

    final selectedDate = await HydraDatePicker.show(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(now.year - 2),
      firstDate: firstDate,
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDateOfBirth = selectedDate;
        _validationResult = null;
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

      // Calculate age from date of birth
      final ageYears = _selectedDateOfBirth != null
          ? AppDateUtils.calculateAge(_selectedDateOfBirth!)
          : null;

      final updatedData = currentData.copyWith(
        petDateOfBirth: _selectedDateOfBirth,
        petAge: ageYears,
      );

      // Perform validation
      final validationResult = OnboardingValidationService.validateCurrentStep(
        updatedData,
        OnboardingSteps.petDateOfBirth,
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
          OnboardingSteps.all.indexOf(OnboardingSteps.petDateOfBirth),
      totalSteps: OnboardingSteps.all.length,
      title: l10n.petDateOfBirthTitle,
      onBackPressed: _goBack,
      showNextButton: false,
      stepId: OnboardingSteps.petDateOfBirth,
      showProgressInAppBar: true,
      child: PetInfoScreenLayout(
        illustration: const Icon(
          Icons.cake,
          size: 80,
          color: AppColors.primary,
        ),
        title: l10n.petDateOfBirthQuestion,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date of Birth
            GestureDetector(
              onTap: _selectDateOfBirth,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.border,
                  ),
                  borderRadius: AppBorderRadius.inputRadius,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _selectedDateOfBirth != null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      _selectedDateOfBirth != null
                          ? AppDateUtils.formatDate(_selectedDateOfBirth!)
                          : l10n.selectDateOfBirth,
                      style: AppTextStyles.body.copyWith(
                        color: _selectedDateOfBirth != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
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
