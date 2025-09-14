import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/extensions/string_extensions.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step.dart';
import 'package:hydracat/features/onboarding/widgets/gender_selector.dart';
import 'package:hydracat/features/onboarding/widgets/onboarding_screen_wrapper.dart';
import 'package:hydracat/features/onboarding/widgets/weight_unit_selector.dart';
import 'package:hydracat/features/profile/services/profile_validation_service.dart';
import 'package:hydracat/providers/onboarding_provider.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_button.dart';

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
  final _validationService = const ProfileValidationService();

  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  double? _weightValue;
  String _weightUnit = 'kg';

  // Error states
  String? _nameError;
  String? _dateOfBirthError;
  String? _genderError;
  String? _weightError;

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
    if (onboardingData.petName != null &&
        onboardingData.petName!.isNotEmpty) {
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
    if (onboardingData.petWeightKg != null &&
        onboardingData.petWeightKg! > 0) {
      setState(() {
        _weightValue = onboardingData.petWeightKg;
      });
    }
  }

  /// Load user's preferred weight unit
  Future<void> _loadWeightUnitPreference() async {
    // For now, use default kg unit
    // TODO(dev): Implement proper preferences when available
    if (mounted) {
      setState(() {
        _weightUnit = 'kg';
      });
    }
  }

  /// Save weight unit preference
  Future<void> _saveWeightUnitPreference(String unit) async {
    // For now, just update local state
    // TODO(dev): Implement proper preferences when available
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

    final selectedDate = await showDatePicker(
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

  /// Validate all form fields
  bool _validateForm() {
    setState(() {
      _nameError = null;
      _dateOfBirthError = null;
      _genderError = null;
      _weightError = null;
    });

    var isValid = true;

    // Validate name (required)
    final nameResult = _validationService.validatePetName(_nameController.text);
    if (!nameResult.isValid) {
      setState(() {
        _nameError = nameResult.errorMessage;
      });
      isValid = false;
    }

    // Validate date of birth (required)
    if (_selectedDateOfBirth == null) {
      setState(() {
        _dateOfBirthError = 'Date of birth is required';
      });
      isValid = false;
    } else {
      // Validate age range
      final ageYears = AppDateUtils.calculateAge(_selectedDateOfBirth!);
      final ageResult = _validationService.validateAge(ageYears);
      if (!ageResult.isValid) {
        setState(() {
          _dateOfBirthError = ageResult.errorMessage;
        });
        isValid = false;
      }
    }

    // Validate gender (required)
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      setState(() {
        _genderError = 'Gender selection is required';
      });
      isValid = false;
    }

    // Validate weight (optional, but validate if provided)
    if (_weightValue != null) {
      final weightInKg = _weightUnit == 'lbs'
          ? _weightValue! / 2.20462
          : _weightValue!;

      final weightResult = _validationService.validateWeight(weightInKg);
      if (!weightResult.isValid) {
        setState(() {
          _weightError = weightResult.errorMessage;
        });
        isValid = false;
      }
    }

    return isValid;
  }

  /// Save form data and proceed to next step
  Future<void> _saveAndContinue() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert weight to kg if needed
      final weightInKg = _weightValue != null && _weightUnit == 'lbs'
          ? _weightValue! / 2.20462
          : _weightValue;

      // Calculate age from date of birth
      final ageYears = AppDateUtils.calculateAge(_selectedDateOfBirth!);

      // Create updated onboarding data with available fields
      final currentData =
          ref.read(onboardingDataProvider) ?? const OnboardingData.empty();

      final updatedData = currentData.copyWith(
        petName: _nameController.text.capitalize,
        petAge: ageYears, // Keep for backwards compatibility
        petDateOfBirth: _selectedDateOfBirth, // Store original date of birth
        petGender: _selectedGender,
        petBreed: _breedController.text.trim().isEmpty
            ? null
            : _breedController.text.trim(),
        petWeightKg: weightInKg,
      );

      // Update onboarding data
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
        final moveSuccess = await ref
            .read(onboardingProvider.notifier)
            .moveToNextStep();

        if (moveSuccess && mounted) {
          // Navigate to medical information screen
          context.go('/onboarding/medical');
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving pet information: $e'),
            backgroundColor: AppColors.error,
          ),
        );
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
    await ref.read(onboardingProvider.notifier).moveToPreviousStep();
    if (mounted) {
      // Navigate to previous screen (user persona)
      context.go('/onboarding/persona');
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScreenWrapper(
      currentStep: 2,
      totalSteps: OnboardingStepType.totalSteps,
      title: 'Tell us about your cat',
      onBackPressed: _goBack,
      showNextButton: false,
      stepName: 'pet_basics',
      showProgressInAppBar: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pet Name (Required)
            _buildSectionLabel('Pet Name', isRequired: true),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: "Enter your cat's name",
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
            _buildSectionLabel('Date of Birth', isRequired: true),
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
                          : 'Select date of birth',
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
            _buildSectionLabel('Gender', isRequired: true),
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

            const SizedBox(height: AppSpacing.lg),

            // Breed (Optional)
            _buildSectionLabel('Breed', isRequired: false),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _breedController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Enter breed (optional)',
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

            const SizedBox(height: AppSpacing.xl),

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
                  : const Text('Save & Continue'),
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// Build section label with required indicator
  Widget _buildSectionLabel(String label, {required bool isRequired}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: AppTextStyles.h3.copyWith(
          color: AppColors.textPrimary,
        ),
        children: isRequired
            ? [
                TextSpan(
                  text: ' *',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ]
            : null,
      ),
    );
  }
}
