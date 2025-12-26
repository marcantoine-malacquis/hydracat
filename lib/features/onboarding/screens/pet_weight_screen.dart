import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/core/utils/weight_utils.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';
import 'package:hydracat/features/onboarding/widgets/onboarding_screen_wrapper.dart';
import 'package:hydracat/features/onboarding/widgets/pet_info_screen_layout.dart';
import 'package:hydracat/features/onboarding/widgets/weight_unit_selector.dart';
import 'package:hydracat/providers/onboarding_provider.dart';
import 'package:hydracat/providers/weight_unit_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Pet weight collection screen (optional field)
class PetWeightScreen extends ConsumerStatefulWidget {
  /// Creates a [PetWeightScreen]
  const PetWeightScreen({super.key});

  @override
  ConsumerState<PetWeightScreen> createState() => _PetWeightScreenState();
}

class _PetWeightScreenState extends ConsumerState<PetWeightScreen> {
  double? _weightValue;
  String _weightUnit = 'kg';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _loadWeightUnitPreference();
  }

  /// Load any previously saved weight
  Future<void> _loadSavedData() async {
    final onboardingData = ref.read(onboardingDataProvider);
    if (onboardingData == null) return;

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

  /// Save form data and proceed to next step
  Future<void> _saveAndContinue() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentData =
          ref.read(onboardingDataProvider) ?? const OnboardingData.empty();

      // Convert weight to kg if needed
      final weightInKg = _weightValue != null && _weightUnit == 'lbs'
          ? WeightUtils.convertLbsToKg(_weightValue!)
          : _weightValue;

      final updatedData = currentData.copyWith(
        petWeightKg: weightInKg,
      );

      // Update onboarding data (no validation needed - optional field)
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

  /// Skip this step
  Future<void> _skip() async {
    // Clear weight field and continue
    final currentData =
        ref.read(onboardingDataProvider) ?? const OnboardingData.empty();

    final updatedData = currentData.copyWith(
      petWeightKg: null,
    );

    await ref.read(onboardingProvider.notifier).updateData(updatedData);

    if (mounted) {
      final nextRoute =
          await ref.read(onboardingProvider.notifier).navigateNext();

      if (nextRoute != null && mounted && context.mounted) {
        context.go(nextRoute);
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
      currentStep: OnboardingSteps.all.indexOf(OnboardingSteps.petWeight),
      totalSteps: OnboardingSteps.all.length,
      title: l10n.petWeightTitle,
      onBackPressed: _goBack,
      showNextButton: false,
      stepId: OnboardingSteps.petWeight,
      showProgressInAppBar: true,
      appBarActions: [
        HydraButton(
          onPressed: _isLoading ? null : _skip,
          variant: HydraButtonVariant.text,
          child: Text(l10n.skip),
        ),
      ],
      child: PetInfoScreenLayout(
        illustration: const Icon(
          Icons.monitor_weight,
          size: 80,
          color: AppColors.primary,
        ),
        title: l10n.petWeightQuestion,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Weight
            WeightUnitSelector(
              weight: _weightValue,
              unit: _weightUnit,
              onWeightChanged: (weight) {
                setState(() {
                  _weightValue = weight;
                });
              },
              onUnitChanged: (unit) async {
                setState(() {
                  _weightUnit = unit;
                });
                await _saveWeightUnitPreference(unit);
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
                  : Text(l10n.continueButton),
            ),
          ],
        ),
      ),
    );
  }
}
