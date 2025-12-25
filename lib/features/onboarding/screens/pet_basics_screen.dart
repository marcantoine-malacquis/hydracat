import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/extensions/string_extensions.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/core/utils/weight_utils.dart';
import 'package:hydracat/core/validation/models/validation_result.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';
import 'package:hydracat/features/onboarding/services/onboarding_validation_service.dart';
import 'package:hydracat/features/onboarding/widgets/gender_selector.dart';
import 'package:hydracat/features/onboarding/widgets/onboarding_screen_wrapper.dart';
import 'package:hydracat/features/onboarding/widgets/weight_unit_selector.dart';
import 'package:hydracat/providers/onboarding_provider.dart';
import 'package:hydracat/providers/weight_unit_provider.dart';
import 'package:hydracat/shared/widgets/validation_error_display.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Pet basics collection screen - Step 3 of onboarding flow
class PetBasicsScreen extends ConsumerStatefulWidget {
  /// Creates a [PetBasicsScreen]
  const PetBasicsScreen({super.key});

  @override
  ConsumerState<PetBasicsScreen> createState() => _PetBasicsScreenState();
}

class _PetBasicsScreenState extends ConsumerState<PetBasicsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  double? _weightValue;
  String _weightUnit = 'kg';

  // Error states
  String? _nameError;
  String? _dateOfBirthError;
  String? _genderError;
  String? _weightError;
  ValidationResult? _validationResult;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _loadWeightUnitPreference();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  /// Load any previously saved pet basics data
  Future<void> _loadSavedData() async {
    final onboardingData = ref.read(onboardingDataProvider);
    if (onboardingData == null) return;

    // Load pet name
    if (onboardingData.petName != null && onboardingData.petName!.isNotEmpty) {
      _nameController.text = onboardingData.petName!;
    }

    // Load date of birth (prefer date of birth over age)
    if (onboardingData.petDateOfBirth != null) {
      setState(() {
        _selectedDateOfBirth = onboardingData.petDateOfBirth;
      });
    }

    // Load gender
    if (onboardingData.petGender != null &&
        onboardingData.petGender!.isNotEmpty) {
      setState(() {
        _selectedGender = onboardingData.petGender;
      });
    }

    // Load breed
    if (onboardingData.petBreed != null &&
        onboardingData.petBreed!.isNotEmpty) {
      _breedController.text = onboardingData.petBreed!;
    }

    // Load weight
    if (onboardingData.petWeightKg != null && onboardingData.petWeightKg! > 0) {
      setState(() {
        _weightValue = onboardingData.petWeightKg;
      });
    }
  }

  /// Load user's preferred weight unit
  Future<void> _loadWeightUnitPreference() async {
    final preferredUnit = ref.read(weightUnitProvider);
    if (mounted) {
      setState(() {
        _weightUnit = preferredUnit;
      });
    }
  }

  /// Save weight unit preference
  Future<void> _saveWeightUnitPreference(String unit) async {
    await ref.read(weightUnitProvider.notifier).setWeightUnit(unit);
    if (mounted) {
      setState(() {
        _weightUnit = unit;
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
        _dateOfBirthError = null;
      });
    }
  }

  /// Save form data and proceed to next step
  Future<void> _saveAndContinue() async {
    setState(() {
      _isLoading = true;
      _validationResult = null; // Clear previous validation errors
    });

    try {
      // Convert weight to kg if needed
      final weightInKg = _weightValue != null && _weightUnit == 'lbs'
          ? WeightUtils.convertLbsToKg(_weightValue!)
          : _weightValue;

      // Calculate age from date of birth
      final ageYears = _selectedDateOfBirth != null
          ? AppDateUtils.calculateAge(_selectedDateOfBirth!)
          : null;

      // Create updated onboarding data with available fields
      final currentData =
          ref.read(onboardingDataProvider) ?? const OnboardingData.empty();

      final updatedData = currentData.copyWith(
        petName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.capitalize,
        petAge: ageYears,
        petDateOfBirth: _selectedDateOfBirth,
        petGender: _selectedGender,
        petBreed: _breedController.text.trim().isEmpty
            ? null
            : _breedController.text.trim(),
        petWeightKg: weightInKg,
      );

      // Perform validation using the unified service
      final validationResult = OnboardingValidationService.validateCurrentStep(
        updatedData,
        OnboardingSteps.petBasics,
      );

      if (!validationResult.isValid) {
        // Show validation errors and stop progression
        setState(() {
          _validationResult = validationResult;
          _isLoading = false;
        });
        return;
      }

      // Validation passed, update onboarding data
      await ref.read(onboardingProvider.notifier).updateData(updatedData);

      // Debug logging to confirm data is stored correctly
      debugPrint('Pet Basics - Data stored successfully:');
      debugPrint('  Pet Name: ${_nameController.text.capitalize}');
      debugPrint('  Date of Birth: $_selectedDateOfBirth');
      debugPrint('  Age: $ageYears years');
      debugPrint('  Gender: $_selectedGender');
      final breedText = _breedController.text.trim().isEmpty
          ? 'Not specified'
          : _breedController.text.trim();
      debugPrint('  Breed: $breedText');
      if (weightInKg != null) {
        debugPrint('  Weight: ${weightInKg.toStringAsFixed(1)} kg');
      }

      // Navigate to next step (medical information)
      if (mounted) {
        final nextRoute = await ref
            .read(onboardingProvider.notifier)
            .navigateNext();

        if (nextRoute != null && mounted && context.mounted) {
          // Navigate to next screen
          context.go(nextRoute);
        }
      }
    } on Exception catch (e) {
      _showGenericError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showGenericError(String message) {
    if (!mounted) return;

    HydraSnackBar.showError(context, message);
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return OnboardingScreenWrapper(
      currentStep: OnboardingSteps.all.indexOf(OnboardingSteps.petBasics),
      totalSteps: OnboardingSteps.all.length,
      title: l10n.petBasicsTitle,
      onBackPressed: _goBack,
      showNextButton: false,
      stepId: OnboardingSteps.petBasics,
      showProgressInAppBar: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pet Name (Required)
            _buildSectionLabel(l10n.petNameLabel, isRequired: true),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: l10n.petNameHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
              ),
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() {
                    _nameError = null;
                  });
                }
              },
            ),
            if (_nameError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _nameError!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Date of Birth (Required)
            _buildSectionLabel(l10n.petDateOfBirthLabel, isRequired: true),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _selectDateOfBirth,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _dateOfBirthError != null
                        ? AppColors.error
                        : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(8),
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
            if (_dateOfBirthError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _dateOfBirthError!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Gender (Required)
            _buildSectionLabel(l10n.petGenderLabel, isRequired: true),
            const SizedBox(height: AppSpacing.sm),
            GenderSelector(
              selectedGender: _selectedGender,
              onGenderChanged: (gender) {
                setState(() {
                  _selectedGender = gender;
                  _genderError = null;
                });
              },
              errorText: _genderError,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Breed (Optional)
            _buildSectionLabel(l10n.petBreedLabel, isRequired: false),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _breedController,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                // The library directive may trigger
                // deprecated_member_use warnings
                // in some Dart versions.
                // ignore: deprecated_member_use
                FilteringTextInputFormatter.deny(RegExp(r'\d')),
              ],
              decoration: InputDecoration(
                hintText: l10n.petBreedHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Weight (Optional)
            _buildSectionLabel('Weight', isRequired: false),
            const SizedBox(height: AppSpacing.sm),
            WeightUnitSelector(
              weight: _weightValue,
              unit: _weightUnit,
              onWeightChanged: (weight) {
                setState(() {
                  _weightValue = weight;
                  _weightError = null;
                });
              },
              onUnitChanged: (unit) async {
                setState(() {
                  _weightUnit = unit;
                });
                await _saveWeightUnitPreference(unit);
              },
              errorText: _weightError,
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

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// Build section label with required indicator
  Widget _buildSectionLabel(String label, {required bool isRequired}) {
    return Text(
      label,
      style: AppTextStyles.h3.copyWith(
        color: AppColors.textPrimary,
      ),
    );
  }
}
