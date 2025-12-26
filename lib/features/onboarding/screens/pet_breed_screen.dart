import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step_id.dart';
import 'package:hydracat/features/onboarding/widgets/onboarding_screen_wrapper.dart';
import 'package:hydracat/features/onboarding/widgets/pet_info_screen_layout.dart';
import 'package:hydracat/providers/onboarding_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Pet breed collection screen (optional field)
class PetBreedScreen extends ConsumerStatefulWidget {
  /// Creates a [PetBreedScreen]
  const PetBreedScreen({super.key});

  @override
  ConsumerState<PetBreedScreen> createState() => _PetBreedScreenState();
}

class _PetBreedScreenState extends ConsumerState<PetBreedScreen> {
  final _breedController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _breedController.dispose();
    super.dispose();
  }

  /// Load any previously saved breed
  Future<void> _loadSavedData() async {
    final onboardingData = ref.read(onboardingDataProvider);
    if (onboardingData == null) return;

    if (onboardingData.petBreed != null &&
        onboardingData.petBreed!.isNotEmpty) {
      _breedController.text = onboardingData.petBreed!;
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

      final updatedData = currentData.copyWith(
        petBreed: _breedController.text.trim().isEmpty
            ? null
            : _breedController.text.trim(),
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
    // Clear breed field and continue
    final currentData =
        ref.read(onboardingDataProvider) ?? const OnboardingData.empty();

    final updatedData = currentData.copyWith(
      petBreed: null,
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
      currentStep: OnboardingSteps.all.indexOf(OnboardingSteps.petBreed),
      totalSteps: OnboardingSteps.all.length,
      title: l10n.petBreedTitle,
      onBackPressed: _goBack,
      showNextButton: false,
      stepId: OnboardingSteps.petBreed,
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
          Icons.category,
          size: 80,
          color: AppColors.primary,
        ),
        title: l10n.petBreedQuestion,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Breed
            HydraTextFormField(
              controller: _breedController,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\d')),
              ],
              decoration: InputDecoration(
                hintText: l10n.petBreedHint,
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
