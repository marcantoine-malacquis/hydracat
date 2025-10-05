import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/onboarding/screens/add_medication_screen.dart';
import 'package:hydracat/features/onboarding/widgets/medication_summary_card.dart';
import 'package:hydracat/features/onboarding/widgets/treatment_popup_wrapper.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Screen for viewing and editing medication schedules
class MedicationScheduleScreen extends ConsumerStatefulWidget {
  /// Creates a [MedicationScheduleScreen]
  const MedicationScheduleScreen({super.key});

  @override
  ConsumerState<MedicationScheduleScreen> createState() =>
      _MedicationScheduleScreenState();
}

class _MedicationScheduleScreenState
    extends ConsumerState<MedicationScheduleScreen> {
  bool _isLoading = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    // Auto-load medication schedules if conditions are met
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final primaryPet = ref.read(primaryPetProvider);
      final medicationSchedules = ref.read(medicationSchedulesProvider);
      final isScheduleLoading = ref.read(scheduleIsLoadingProvider);

      if (primaryPet != null &&
          medicationSchedules == null &&
          !isScheduleLoading) {
        ref.read(profileProvider.notifier).loadMedicationSchedules();
      }
    });
  }

  /// Convert Schedule to MedicationData for editing
  MedicationData _scheduleToMedicationData(Schedule schedule) {
    return MedicationData(
      name: schedule.medicationName ?? '',
      unit:
          MedicationUnit.fromString(schedule.medicationUnit ?? 'pills') ??
          MedicationUnit.pills,
      frequency: schedule.frequency,
      reminderTimes: schedule.reminderTimes,
      dosage: schedule.targetDosage,
      strengthAmount: schedule.medicationStrengthAmount,
      strengthUnit: schedule.medicationStrengthUnit != null
          ? MedicationStrengthUnit.fromString(
              schedule.medicationStrengthUnit!,
            )
          : null,
      customStrengthUnit: schedule.customMedicationStrengthUnit,
    );
  }

  /// Convert MedicationData to Schedule for saving
  Schedule _medicationDataToSchedule(
    MedicationData medication,
    String scheduleId,
  ) {
    final now = DateTime.now();
    return Schedule(
      id: scheduleId,
      treatmentType: TreatmentType.medication,
      frequency: medication.frequency,
      reminderTimes: medication.reminderTimes,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      medicationName: medication.name,
      targetDosage: medication.dosage ?? 1,
      medicationUnit: medication.unit.name,
      medicationStrengthAmount: medication.strengthAmount,
      medicationStrengthUnit: medication.strengthUnit?.name,
      customMedicationStrengthUnit: medication.customStrengthUnit,
    );
  }

  /// Add a new medication
  Future<void> _onAddMedication() async {
    final result = await Navigator.of(context).push<MedicationData>(
      MaterialPageRoute(
        builder: (context) => const AddMedicationScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
        _saveError = null;
      });

      try {
        // Generate a temporary ID (will be replaced by Firestore)
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final schedule = _medicationDataToSchedule(result, tempId);

        final success = await ref
            .read(profileProvider.notifier)
            .addMedicationSchedule(schedule);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medication added successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (mounted) {
          setState(() {
            _saveError = 'Failed to add medication. Please try again.';
          });
        }
      } on Exception catch (e) {
        if (mounted) {
          setState(() {
            _saveError = 'Failed to add medication: $e';
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  /// Edit an existing medication
  Future<void> _onEditMedication(Schedule schedule) async {
    final medicationData = _scheduleToMedicationData(schedule);

    final result = await Navigator.of(context).push<MedicationData>(
      MaterialPageRoute(
        builder: (context) => AddMedicationScreen(
          initialMedication: medicationData,
          isEditing: true,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
        _saveError = null;
      });

      try {
        final updatedSchedule = _medicationDataToSchedule(result, schedule.id);

        final success = await ref
            .read(profileProvider.notifier)
            .updateMedicationSchedule(updatedSchedule);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medication updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (mounted) {
          setState(() {
            _saveError = 'Failed to update medication. Please try again.';
          });
        }
      } on Exception catch (e) {
        if (mounted) {
          setState(() {
            _saveError = 'Failed to update medication: $e';
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  /// Delete a medication
  Future<void> _onDeleteMedication(Schedule schedule) async {
    final confirmed = await TreatmentConfirmationDialog.show(
      context,
      title: 'Delete Medication',
      content: Text(
        'Are you sure you want to delete "${schedule.medicationName}"? '
        'This action cannot be undone.',
      ),
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed ?? false) {
      setState(() {
        _isLoading = true;
        _saveError = null;
      });

      try {
        final success = await ref
            .read(profileProvider.notifier)
            .deleteMedicationSchedule(schedule.id);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medication deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (mounted) {
          setState(() {
            _saveError = 'Failed to delete medication. Please try again.';
          });
        }
      } on Exception catch (e) {
        if (mounted) {
          setState(() {
            _saveError = 'Failed to delete medication: $e';
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryPet = ref.watch(primaryPetProvider);
    final petName = primaryPet?.name ?? 'Your Cat';
    final medicationSchedules = ref.watch(medicationSchedulesProvider);
    final isScheduleLoading = ref.watch(scheduleIsLoadingProvider);

    return DevBanner(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text("$petName's Medication Schedule"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios),
            iconSize: 20,
            color: AppColors.textSecondary,
            tooltip: 'Back',
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(profileProvider.notifier)
                .refreshMedicationSchedules();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header section
                  _buildHeader(context),

                  const SizedBox(height: AppSpacing.xl),

                  // Content sections
                  if (isScheduleLoading && medicationSchedules == null) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ] else if (medicationSchedules == null ||
                      medicationSchedules.isEmpty) ...[
                    _buildNoMedicationsState(),
                  ] else ...[
                    _buildMedicationList(medicationSchedules),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // Error message
                  if (_saveError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.errorLight),
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
                              _saveError!,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Add medication button (always show at bottom)
                  if (medicationSchedules != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _onAddMedication,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: const Text('Add Medication'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build header section
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage your medications and reminder schedules. '
            'Tap any medication to edit its details.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
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
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Changes are automatically saved to your profile',
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

  /// Build state when no medications are available
  Widget _buildNoMedicationsState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No Medications Found',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "You haven't set up any medication schedules yet. "
            'Add your first medication to get started with reminders and '
            'tracking.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _onAddMedication,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: const Text('Add First Medication'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build medication list
  Widget _buildMedicationList(List<Schedule> schedules) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        final medicationData = _scheduleToMedicationData(schedule);

        return MedicationSummaryCard(
          medication: medicationData,
          onTap: () => _onEditMedication(schedule),
          onEdit: () => _onEditMedication(schedule),
          onDelete: () => _onDeleteMedication(schedule),
        );
      },
    );
  }
}
