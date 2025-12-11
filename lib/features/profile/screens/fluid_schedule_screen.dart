import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/profile/widgets/editable_medical_field.dart';
import 'package:hydracat/features/profile/widgets/fluid_schedule/frequency_edit_bottom_sheet.dart';
import 'package:hydracat/features/profile/widgets/fluid_schedule/location_edit_bottom_sheet.dart';
import 'package:hydracat/features/profile/widgets/fluid_schedule/needle_gauge_edit_bottom_sheet.dart';
import 'package:hydracat/features/profile/widgets/fluid_schedule/volume_edit_bottom_sheet.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Screen for viewing and editing fluid therapy schedule
class FluidScheduleScreen extends ConsumerStatefulWidget {
  /// Creates a [FluidScheduleScreen]
  const FluidScheduleScreen({super.key});

  @override
  ConsumerState<FluidScheduleScreen> createState() =>
      _FluidScheduleScreenState();
}

class _FluidScheduleScreenState extends ConsumerState<FluidScheduleScreen> {
  // Local editing state
  TreatmentFrequency? _editingFrequency;
  double? _editingVolume;
  FluidLocation? _editingLocation;
  NeedleGauge? _editingNeedleGauge;
  DateTime? _editingReminderTime;

  // Track what's been modified
  bool _hasChanges = false;
  bool _isSaving = false;

  // Error state
  String? _saveError;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize editing state when schedule data becomes available
    final schedule = ref.watch(fluidScheduleProvider);
    if (schedule != null && !_hasChanges) {
      _initializeFromSchedule(schedule);
    }
  }

  /// Initialize editing state from current schedule data
  void _initializeFromSchedule(Schedule? schedule) {
    if (schedule == null) return;

    setState(() {
      _editingFrequency = schedule.frequency;
      _editingVolume = schedule.targetVolume;
      _editingLocation = schedule.preferredLocation;
      _editingNeedleGauge = schedule.needleGauge;
      _editingReminderTime = schedule.reminderTimes.isNotEmpty
          ? schedule.reminderTimes.first
          : null;
    });
  }

  /// Mark that changes have been made
  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  /// Save changes to Firebase
  Future<void> _saveChanges() async {
    final currentSchedule = ref.read(fluidScheduleProvider);
    if (currentSchedule == null) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      // Create updated schedule
      final updatedSchedule = currentSchedule.copyWith(
        frequency: _editingFrequency ?? currentSchedule.frequency,
        targetVolume: _editingVolume ?? currentSchedule.targetVolume,
        preferredLocation:
            _editingLocation ?? currentSchedule.preferredLocation,
        needleGauge: _editingNeedleGauge ?? currentSchedule.needleGauge,
        reminderTimes: _editingReminderTime != null
            ? [_editingReminderTime!]
            : currentSchedule.reminderTimes,
        updatedAt: DateTime.now(),
      );

      // Validate the updated schedule
      if (!updatedSchedule.isValid) {
        throw Exception('Schedule data is invalid');
      }

      // Save to Firebase via provider (also updates cache)
      final success = await ref
          .read(profileProvider.notifier)
          .updateFluidSchedule(updatedSchedule);

      if (success) {
        // Reset changes state
        setState(() {
          _hasChanges = false;
        });

        // Show success feedback
        if (mounted) {
          HydraSnackBar.showSuccess(
            context,
            'Fluid schedule updated successfully',
          );
        }
      } else {
        throw Exception('Failed to save schedule changes');
      }
    } on Exception catch (e) {
      setState(() {
        _saveError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Show frequency edit bottom sheet
  Future<void> _showFrequencyEditBottomSheet() async {
    final currentSchedule = ref.read(fluidScheduleProvider);
    final initialValue = _editingFrequency ?? currentSchedule?.frequency;

    final result = await showHydraBottomSheet<TreatmentFrequency?>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.background,
      builder: (context) => HydraBottomSheet(
        backgroundColor: AppColors.background,
        child: FrequencyEditBottomSheet(initialValue: initialValue),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _editingFrequency = result;
        _markAsChanged();
      });
    }
  }

  /// Show volume edit bottom sheet
  Future<void> _showVolumeEditBottomSheet() async {
    final currentSchedule = ref.read(fluidScheduleProvider);
    final initialValue = _editingVolume ?? currentSchedule?.targetVolume;

    final result = await showHydraBottomSheet<double?>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.background,
      builder: (context) => HydraBottomSheet(
        backgroundColor: AppColors.background,
        child: VolumeEditBottomSheet(initialValue: initialValue),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _editingVolume = result;
        _markAsChanged();
      });
    }
  }

  /// Show location edit bottom sheet
  Future<void> _showLocationEditBottomSheet() async {
    final currentSchedule = ref.read(fluidScheduleProvider);
    final initialValue = _editingLocation ?? currentSchedule?.preferredLocation;

    final result = await showHydraBottomSheet<FluidLocation?>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.background,
      builder: (context) => HydraBottomSheet(
        backgroundColor: AppColors.background,
        child: LocationEditBottomSheet(initialValue: initialValue),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _editingLocation = result;
        _markAsChanged();
      });
    }
  }

  /// Show needle gauge edit bottom sheet
  Future<void> _showNeedleGaugeEditBottomSheet() async {
    final currentSchedule = ref.read(fluidScheduleProvider);
    final initialValue = _editingNeedleGauge ?? currentSchedule?.needleGauge;

    final result = await showHydraBottomSheet<NeedleGauge?>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.background,
      builder: (context) => HydraBottomSheet(
        backgroundColor: AppColors.background,
        child: NeedleGaugeEditBottomSheet(initialValue: initialValue),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _editingNeedleGauge = result;
        _markAsChanged();
      });
    }
  }

  /// Show reminder time picker directly
  Future<void> _showReminderTimeEditBottomSheet() async {
    final currentSchedule = ref.read(fluidScheduleProvider);
    final initialValue =
        _editingReminderTime ??
        (currentSchedule?.reminderTimes.isNotEmpty ?? false
            ? currentSchedule!.reminderTimes.first
            : null);

    final initialTime = initialValue != null
        ? TimeOfDay.fromDateTime(initialValue)
        : const TimeOfDay(hour: 9, minute: 0);

    final selectedTime = await HydraTimePicker.show(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null && mounted) {
      final now = DateTime.now();
      final newTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      setState(() {
        _editingReminderTime = newTime;
        _markAsChanged();
      });
    }
  }

  /// Show unsaved changes dialog when user tries to navigate back
  void _showUnsavedChangesDialog() {
    UnsavedChangesDialog.show(
      context: context,
      onSave: () async {
        await _saveChanges();
        // Only navigate back if save was successful (no error)
        if (mounted && _saveError == null) {
          context.pop();
        }
      },
      onDiscard: () {
        if (mounted) {
          context.pop();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryPet = ref.watch(primaryPetProvider);
    final petName = primaryPet?.name ?? 'Your Cat';
    final currentSchedule = ref.watch(fluidScheduleProvider);
    final isScheduleLoading = ref.watch(scheduleIsLoadingProvider);

    // Auto-load schedule if conditions are met (similar to ProfileScreen)
    if (primaryPet != null && currentSchedule == null && !isScheduleLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(profileProvider.notifier).loadFluidSchedule();
      });
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // Already popped, do nothing

        if (_hasChanges) {
          _showUnsavedChangesDialog();
        }
      },
      child: DevBanner(
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: HydraAppBar(
            title: Text("$petName's Fluid Schedule"),
            leading: HydraBackButton(
              onPressed: () {
                if (_hasChanges) {
                  _showUnsavedChangesDialog();
                } else {
                  context.pop();
                }
              },
            ),
          ),
          body: HydraRefreshIndicator(
            onRefresh: () async {
              await ref.read(profileProvider.notifier).refreshFluidSchedule();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Show loading state
                    if (isScheduleLoading && currentSchedule == null) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ]
                    // Check if we have schedule data
                    else if (currentSchedule == null) ...[
                      _buildNoScheduleState(),
                    ] else ...[
                      // Frequency Section
                      _buildFrequencySection(),

                      const SizedBox(height: AppSpacing.sm),

                      // Volume Section
                      _buildVolumeSection(),

                      const SizedBox(height: AppSpacing.sm),

                      // Location Section
                      _buildLocationSection(),

                      const SizedBox(height: AppSpacing.sm),

                      // Needle Gauge Section
                      _buildNeedleGaugeSection(),

                      const SizedBox(height: AppSpacing.sm),

                      // Reminder Time Section
                      _buildReminderTimeSection(),

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

                      // Save button (only show if changes made)
                      if (_hasChanges) ...[
                        HydraButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          isFullWidth: true,
                          size: HydraButtonSize.large,
                          child: _isSaving
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
                              : const Text('Save Changes'),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build state when no schedule is available
  Widget _buildNoScheduleState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No Fluid Schedule Found',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "It looks like you haven't set up a fluid therapy schedule yet. "
            'Complete the onboarding process to add your fluid therapy '
            'settings.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build frequency section
  Widget _buildFrequencySection() {
    return EditableMedicalField(
      label: 'Fluid session frequency',
      value: _editingFrequency?.displayName ?? 'No information',
      isEmpty: _editingFrequency == null,
      icon: AppIcons.frequency,
      onEdit: _showFrequencyEditBottomSheet,
    );
  }

  /// Build volume section
  Widget _buildVolumeSection() {
    final schedule = ref.watch(fluidScheduleProvider);
    final now = DateTime.now();
    final today = AppDateUtils.startOfDay(now);
    final countToday = (schedule?.reminderTimes ?? [])
        .where((t) => AppDateUtils.startOfDay(t).isAtSameMomentAs(today))
        .length;
    final totalPlannedToday = (countToday > 0 && (_editingVolume ?? 0) > 0)
        ? (countToday * (_editingVolume ?? 0)).toInt()
        : 0;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditableMedicalField(
          label: 'Volume per session',
          value: _editingVolume != null
              ? '${_editingVolume!.toInt()} mL'
              : 'No information',
          isEmpty: _editingVolume == null,
          icon: AppIcons.volume,
          onEdit: _showVolumeEditBottomSheet,
        ),
        if (totalPlannedToday > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.totalPlannedToday(totalPlannedToday),
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  /// Build location section
  Widget _buildLocationSection() {
    return EditableMedicalField(
      label: 'Preferred Location',
      value: _editingLocation?.displayName ?? 'No information',
      isEmpty: _editingLocation == null,
      icon: AppIcons.locationOn,
      onEdit: _showLocationEditBottomSheet,
    );
  }

  /// Build needle gauge section
  Widget _buildNeedleGaugeSection() {
    return EditableMedicalField(
      label: 'Needle Gauge',
      value: _editingNeedleGauge?.displayName ?? 'No information',
      isEmpty: _editingNeedleGauge == null,
      icon: AppIcons.needleGauge,
      onEdit: _showNeedleGaugeEditBottomSheet,
    );
  }

  /// Build reminder time section
  Widget _buildReminderTimeSection() {
    return EditableMedicalField(
      label: 'Reminder Time',
      value: _editingReminderTime != null
          ? _formatTime(_editingReminderTime!)
          : 'No information',
      isEmpty: _editingReminderTime == null,
      icon: AppIcons.reminderTime,
      onEdit: _showReminderTimeEditBottomSheet,
    );
  }
}
