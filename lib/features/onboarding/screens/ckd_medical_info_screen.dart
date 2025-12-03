import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step.dart';
import 'package:hydracat/features/onboarding/widgets/iris_stage_selector.dart';
import 'package:hydracat/features/onboarding/widgets/lab_values_input.dart';
import 'package:hydracat/features/onboarding/widgets/onboarding_screen_wrapper.dart';
import 'package:hydracat/features/profile/models/medical_info.dart';
import 'package:hydracat/providers/onboarding_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// CKD Medical Information collection screen - Step 4 of onboarding flow
class CkdMedicalInfoScreen extends ConsumerStatefulWidget {
  /// Creates a [CkdMedicalInfoScreen]
  const CkdMedicalInfoScreen({super.key});

  @override
  ConsumerState<CkdMedicalInfoScreen> createState() =>
      _CkdMedicalInfoScreenState();
}

class _CkdMedicalInfoScreenState extends ConsumerState<CkdMedicalInfoScreen> {
  // Form state
  IrisStage? _selectedIrisStage;
  bool _hasSelectedIrisStage = true; // Default to Unknown selected
  LabValueData _labValues = const LabValueData();
  DateTime? _lastCheckupDate;
  String _notes = '';

  // Error states
  String? _irisStageError;
  String? _creatinineError;
  String? _bunError;
  String? _sdmaError;
  String? _bloodworkDateError;
  String? _lastCheckupError;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  /// Load any previously saved medical data
  Future<void> _loadSavedData() async {
    final onboardingData = ref.read(onboardingDataProvider);
    if (onboardingData != null) {
      setState(() {
        _selectedIrisStage = onboardingData.irisStage;
        // Only override default if a specific stage was saved
        if (onboardingData.irisStage != null) {
          _hasSelectedIrisStage = true;
        }
        _labValues = LabValueData(
          creatinine: onboardingData.creatinineMgDl,
          bun: onboardingData.bunMgDl,
          sdma: onboardingData.sdmaMcgDl,
          bloodworkDate: onboardingData.bloodworkDate,
          vetNotes: onboardingData.vetNotes,
        );
        _notes = onboardingData.notes ?? '';
      });
    }
  }

  /// Validate form data
  bool _validateForm() {
    setState(() {
      _irisStageError = null;
      _creatinineError = null;
      _bunError = null;
      _sdmaError = null;
      _bloodworkDateError = null;
      _lastCheckupError = null;
    });

    var isValid = true;

    // Lab values validation if any are provided
    if (_labValues.hasValues || _labValues.bloodworkDate != null) {
      // Validate bloodwork date is required if lab values provided
      if (_labValues.hasValues && _labValues.bloodworkDate == null) {
        setState(() {
          _bloodworkDateError =
              'Bloodwork date is required when lab values '
              'are provided';
        });
        isValid = false;
      }

      // Validate individual lab values (structural only)
      if (_labValues.creatinine != null && _labValues.creatinine! <= 0) {
        setState(() {
          _creatinineError = 'Creatinine must be a positive number';
        });
        isValid = false;
      }

      if (_labValues.bun != null && _labValues.bun! <= 0) {
        setState(() {
          _bunError = 'BUN must be a positive number';
        });
        isValid = false;
      }

      if (_labValues.sdma != null && _labValues.sdma! <= 0) {
        setState(() {
          _sdmaError = 'SDMA must be a positive number';
        });
        isValid = false;
      }

      // Validate bloodwork date not in future
      if (_labValues.bloodworkDate != null &&
          _labValues.bloodworkDate!.isAfter(DateTime.now())) {
        setState(() {
          _bloodworkDateError = 'Bloodwork date cannot be in the future';
        });
        isValid = false;
      }
    }

    // Validate last checkup date
    if (_lastCheckupDate != null && _lastCheckupDate!.isAfter(DateTime.now())) {
      setState(() {
        _lastCheckupError = 'Last checkup date cannot be in the future';
      });
      isValid = false;
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
      // Create updated onboarding data
      final currentData =
          ref.read(onboardingDataProvider) ?? const OnboardingData.empty();

      final updatedData = currentData.copyWith(
        irisStage: _selectedIrisStage,
        creatinineMgDl: _labValues.creatinine,
        bunMgDl: _labValues.bun,
        sdmaMcgDl: _labValues.sdma,
        bloodworkDate: _labValues.bloodworkDate,
        vetNotes: _labValues.vetNotes,
        notes: _notes.trim().isEmpty ? null : _notes.trim(),
      );

      // Update onboarding data
      await ref.read(onboardingProvider.notifier).updateData(updatedData);

      // Navigate to next step (treatment setup)
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
      if (mounted) {
        final errorMessage = ref
            .read(onboardingProvider.notifier)
            .getErrorMessage(e);
        HydraSnackBar.showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Skip this step with caring message
  Future<void> _skipStep() async {
    final l10n = context.l10n;

    // Show empathetic dialog
    final shouldSkip = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => HydraAlertDialog(
        title: Text(l10n.skipMedicalInfoTitle),
        content: Text(l10n.skipMedicalInfoMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.goBack),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.skipForNow),
          ),
        ],
      ),
    );

    if (shouldSkip ?? false) {
      // Clear any medical data and continue
      final currentData =
          ref.read(onboardingDataProvider) ?? const OnboardingData.empty();

      final clearedData = currentData.clearMedicalInfo();
      await ref.read(onboardingProvider.notifier).updateData(clearedData);

      // Move to next step
      if (mounted) {
        await ref.read(onboardingProvider.notifier).moveToNextStep();
      }
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

  /// Select last checkup date
  Future<void> _selectLastCheckupDate() async {
    final selectedDate = await HydraDatePicker.show(
      context: context,
      initialDate: _lastCheckupDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
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
        _lastCheckupDate = selectedDate;
        _lastCheckupError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return OnboardingScreenWrapper(
      currentStep: OnboardingStepType.ckdMedicalInfo.stepIndex,
      totalSteps: OnboardingStepType.totalSteps,
      title: l10n.lastBloodworkResults,
      onBackPressed: _goBack,
      showNextButton: false,
      stepType: OnboardingStepType.ckdMedicalInfo,
      showProgressInAppBar: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Empathetic introduction
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'We understand this can be overwhelming',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'All fields below are optional. Share what you have '
                  "available, and don't worry if some information is "
                  'missing. You can always add or update this later.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // IRIS Stage Section
          Text(
            'IRIS Stage',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "If you know your cat's current IRIS stage from your vet:",
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          IrisStageSelector(
            selectedStage: _selectedIrisStage,
            hasUserSelected: _hasSelectedIrisStage,
            onStageChanged: (stage) {
              setState(() {
                _selectedIrisStage = stage;
                _hasSelectedIrisStage = true;
                _irisStageError = null;
              });
            },
            errorText: _irisStageError,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Lab Values Section
          LabValuesInput(
            labValues: _labValues,
            onValuesChanged: (newLabValues) {
              setState(() {
                _labValues = newLabValues;
                _creatinineError = null;
                _bunError = null;
                _sdmaError = null;
                _bloodworkDateError = null;
              });
            },
            creatinineError: _creatinineError,
            bunError: _bunError,
            sdmaError: _sdmaError,
            bloodworkDateError: _bloodworkDateError,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Last Checkup Section
          Text(
            'Last Vet Checkup',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: _selectLastCheckupDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _lastCheckupError != null
                      ? AppColors.error
                      : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    color: _lastCheckupDate != null
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    _lastCheckupDate != null
                        ? _formatDate(_lastCheckupDate!)
                        : 'Select last checkup date (optional)',
                    style: AppTextStyles.body.copyWith(
                      color: _lastCheckupDate != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_lastCheckupError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _lastCheckupError!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Additional Notes Section
          Text(
            'Additional Notes',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: _notes,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText:
                  'Any other relevant medical information or notes '
                  'from your vet (optional)...',
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
            onChanged: (value) {
              _notes = value;
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // Continue Button
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
                : Text(l10n.continue_),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Skip option
          Center(
            child: TextButton.icon(
              onPressed: _skipStep,
              icon: const Icon(
                Icons.skip_next_outlined,
                color: AppColors.textTertiary,
              ),
              label: Text(
                'Skip this step for now',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textTertiary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
