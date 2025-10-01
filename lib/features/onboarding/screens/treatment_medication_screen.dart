import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/onboarding/screens/add_medication_screen.dart';
import 'package:hydracat/features/onboarding/widgets/medication_summary_card.dart';
import 'package:hydracat/features/onboarding/widgets/onboarding_screen_wrapper.dart';
import 'package:hydracat/features/onboarding/widgets/treatment_popup_wrapper.dart';
import 'package:hydracat/providers/onboarding_provider.dart';

/// Screen for setting up medication treatments
class TreatmentMedicationScreen extends ConsumerStatefulWidget {
  /// Creates a [TreatmentMedicationScreen]
  const TreatmentMedicationScreen({
    super.key,
    this.onBack,
  });

  /// Optional callback for back navigation
  final VoidCallback? onBack;

  @override
  ConsumerState<TreatmentMedicationScreen> createState() =>
      _TreatmentMedicationScreenState();
}

class _TreatmentMedicationScreenState
    extends ConsumerState<TreatmentMedicationScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final onboardingData = ref.watch(onboardingDataProvider);
    final medications = onboardingData?.medications ?? [];

    return OnboardingScreenWrapper(
      currentStep: 5,
      totalSteps: 6,
      title: l10n.medicationSetupTitle,
      onBackPressed: _onBackPressed,
      showNextButton: false,
      showProgressInAppBar: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          _buildHeader(context, theme),

          // Content sections
          if (medications.isEmpty)
            EmptyMedicationState(
              onAddMedication: _onAddMedication,
            )
          else
            _buildMedicationList(medications),

          const SizedBox(height: 32),

          // Footer with add button and navigation
          _buildFooter(context, theme, medications.isNotEmpty),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add the medications your cat currently takes. '
            'This helps us create personalized reminders and tracking.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You can update your schedules anytime in the Profile '
                    'section',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
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

  Widget _buildMedicationList(List<MedicationData> medications) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final medication = medications[index];
        return MedicationSummaryCard(
          medication: medication,
          onTap: () => _onEditMedication(index, medication),
          onEdit: () => _onEditMedication(index, medication),
          onDelete: () => _onDeleteMedication(index, medication),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme, bool hasItems) {
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add medication button (large outlined) appears only
          //when there are items
          if (hasItems)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _onAddMedication,
                icon: const Icon(Icons.add),
                label: Text(l10n.addMedication),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),

          if (hasItems) const SizedBox(height: 16),

          // Next button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _onNext,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _onBackPressed() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onAddMedication() async {
    final result = await Navigator.of(context).push<MedicationData>(
      MaterialPageRoute(
        builder: (context) => const AddMedicationScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
      final currentData = ref.read(onboardingDataProvider);
      if (currentData != null) {
        await ref
            .read(onboardingProvider.notifier)
            .updateData(
              currentData.addMedication(result),
            );
      }
    }
  }

  Future<void> _onEditMedication(int index, MedicationData medication) async {
    final result = await Navigator.of(context).push<MedicationData>(
      MaterialPageRoute(
        builder: (context) => AddMedicationScreen(
          initialMedication: medication,
          isEditing: true,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
      final currentData = ref.read(onboardingDataProvider);
      if (currentData != null) {
        await ref
            .read(onboardingProvider.notifier)
            .updateData(
              currentData.updateMedication(index, result),
            );
      }
    }
  }

  Future<void> _onDeleteMedication(int index, MedicationData medication) async {
    final confirmed = await TreatmentConfirmationDialog.show(
      context,
      title: 'Delete Medication',
      content: Text(
        'Are you sure you want to delete "${medication.name}"? '
        'This action cannot be undone.',
      ),
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed ?? false) {
      final currentData = ref.read(onboardingDataProvider);
      if (currentData != null) {
        await ref
            .read(onboardingProvider.notifier)
            .updateData(
              currentData.removeMedication(index),
            );
      }
    }
  }

  Future<void> _onNext() async {
    setState(() => _isLoading = true);

    try {
      // Move to next step
      final moveSuccess = await ref
          .read(onboardingProvider.notifier)
          .moveToNextStep();

      if (moveSuccess && mounted) {
        // Navigate to completion screen
        context.go(OnboardingStepType.completion.routeName);
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.failedToSaveProgress(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally{
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
