import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/onboarding/screens/add_medication_bottom_sheet.dart';
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

  /// Show medication bottom sheet
  Future<MedicationData?> _showMedicationBottomSheet({
    MedicationData? initialMedication,
    bool isEditing = false,
  }) async {
    return showAddMedicationBottomSheet(
      context: context,
      initialMedication: initialMedication,
      isEditing: isEditing,
    );
  }

  /// Add a new medication
  Future<void> _onAddMedication() async {
    final result = await _showMedicationBottomSheet();

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
          HydraSnackBar.showSuccess(context, 'Medication added successfully');
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

    final result = await _showMedicationBottomSheet(
      initialMedication: medicationData,
      isEditing: true,
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
          HydraSnackBar.showSuccess(
            context,
            'Medication updated successfully',
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
          HydraSnackBar.showSuccess(
            context,
            'Medication deleted successfully',
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
        appBar: HydraAppBar(
          title: Text("$petName's Medication Schedule"),
          leading: HydraBackButton(
            onPressed: () => context.pop(),
          ),
        ),
        body: HydraRefreshIndicator(
          onRefresh: () async {
            await ref
                .read(profileProvider.notifier)
                .refreshMedicationSchedules();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Add medication button (top CTA)
                  HydraButton(
                    onPressed: _isLoading ? null : _onAddMedication,
                    isFullWidth: true,
                    size: HydraButtonSize.large,
                    isLoading: _isLoading,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: AppSpacing.xs),
                        Text('Add Medication'),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.mdLg),

                  // Content sections
                  if (isScheduleLoading && medicationSchedules == null) ...[
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: HydraProgressIndicator(),
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
                    HydraInfoCard(
                      type: HydraInfoType.error,
                      message: _saveError!,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build state when no medications are available
  Widget _buildNoMedicationsState() {
    return HydraCard(
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
          HydraButton(
            onPressed: _isLoading ? null : _onAddMedication,
            isFullWidth: true,
            isLoading: _isLoading,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add),
                SizedBox(width: AppSpacing.xs),
                Text('Add First Medication'),
              ],
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
      padding: EdgeInsets.zero,
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
