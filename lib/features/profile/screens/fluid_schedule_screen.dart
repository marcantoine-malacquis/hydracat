import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/onboarding/widgets/rotating_wheel_picker.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/profile/widgets/editable_medical_field.dart';
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
  String _editingNeedleGauge = '';
  DateTime? _editingReminderTime;

  // Track what's been modified
  bool _hasChanges = false;
  bool _isSaving = false;

  // Error state
  String? _saveError;

  // Edit mode tracking
  bool _isEditingFrequency = false;
  bool _isEditingVolume = false;
  bool _isEditingLocation = false;
  bool _isEditingNeedleGauge = false;
  bool _isEditingReminderTime = false;

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
      _editingNeedleGauge = schedule.needleGauge ?? '';
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
        needleGauge: _editingNeedleGauge.trim().isEmpty
            ? currentSchedule.needleGauge
            : _editingNeedleGauge.trim(),
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
        // Reset edit mode states
        setState(() {
          _hasChanges = false;
          _isEditingFrequency = false;
          _isEditingVolume = false;
          _isEditingLocation = false;
          _isEditingNeedleGauge = false;
          _isEditingReminderTime = false;
        });

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fluid schedule updated successfully'),
              backgroundColor: AppColors.primary,
            ),
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
          appBar: AppBar(
            title: Text("$petName's Fluid Schedule"),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            leading: IconButton(
              onPressed: () {
                if (_hasChanges) {
                  _showUnsavedChangesDialog();
                } else {
                  context.pop();
                }
              },
              icon: const Icon(Icons.arrow_back_ios),
              iconSize: 20,
              color: AppColors.textSecondary,
              tooltip: 'Back',
            ),
          ),
          body: RefreshIndicator(
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

                      const SizedBox(height: AppSpacing.xl),

                      // Volume Section
                      _buildVolumeSection(),

                      const SizedBox(height: AppSpacing.xl),

                      // Location Section
                      _buildLocationSection(),

                      const SizedBox(height: AppSpacing.xl),

                      // Needle Gauge Section
                      _buildNeedleGaugeSection(),

                      const SizedBox(height: AppSpacing.xl),

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Administration Frequency',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (_isEditingFrequency) ...[
          // Editing mode
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: RotatingWheelPicker<TreatmentFrequency>(
              items: TreatmentFrequency.values,
              initialIndex: TreatmentFrequency.values.indexOf(
                _editingFrequency ?? TreatmentFrequency.onceDaily,
              ),
              onSelectedItemChanged: (index) {
                setState(() {
                  _editingFrequency = TreatmentFrequency.values[index];
                  _markAsChanged();
                });
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingFrequency = false;
                      // Reset to original value
                      final schedule = ref.read(fluidScheduleProvider);
                      if (schedule != null) {
                        _editingFrequency = schedule.frequency;
                      }
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingFrequency = false;
                    });
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ] else ...[
          // Display mode
          EditableMedicalField(
            label: 'Frequency',
            value: _editingFrequency?.displayName ?? 'No information',
            isEmpty: _editingFrequency == null,
            icon: Icons.schedule,
            onEdit: () {
              setState(() {
                _isEditingFrequency = true;
              });
            },
          ),
        ],
      ],
    );
  }

  /// Build volume section
  Widget _buildVolumeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Volume per Administration',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (_isEditingVolume) ...[
          // Editing mode
          TextFormField(
            initialValue: _editingVolume?.toString() ?? '',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              setState(() {
                _editingVolume = double.tryParse(value) ?? 0;
                _markAsChanged();
              });
            },
            decoration: InputDecoration(
              labelText: 'Volume (ml)',
              hintText: '100.0',
              suffixText: 'ml',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.local_drink),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingVolume = false;
                      // Reset to original value
                      final schedule = ref.read(fluidScheduleProvider);
                      if (schedule != null) {
                        _editingVolume = schedule.targetVolume;
                      }
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingVolume = false;
                    });
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ] else ...[
          // Display mode
          EditableMedicalField(
            label: 'Volume per Administration',
            value: _editingVolume != null
                ? '${_editingVolume!.toInt()}ml'
                : 'No information',
            isEmpty: _editingVolume == null,
            icon: Icons.local_drink,
            onEdit: () {
              setState(() {
                _isEditingVolume = true;
              });
            },
          ),
        ],
      ],
    );
  }

  /// Build location section
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred Administration Location',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (_isEditingLocation) ...[
          // Editing mode
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: RotatingWheelPicker<FluidLocation>(
              items: FluidLocation.values,
              initialIndex: FluidLocation.values.indexOf(
                _editingLocation ?? FluidLocation.shoulderBladeLeft,
              ),
              onSelectedItemChanged: (index) {
                setState(() {
                  _editingLocation = FluidLocation.values[index];
                  _markAsChanged();
                });
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingLocation = false;
                      // Reset to original value
                      final schedule = ref.read(fluidScheduleProvider);
                      if (schedule != null) {
                        _editingLocation = schedule.preferredLocation;
                      }
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingLocation = false;
                    });
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ] else ...[
          // Display mode
          EditableMedicalField(
            label: 'Preferred Location',
            value: _editingLocation?.displayName ?? 'No information',
            isEmpty: _editingLocation == null,
            icon: Icons.place,
            onEdit: () {
              setState(() {
                _isEditingLocation = true;
              });
            },
          ),
        ],
      ],
    );
  }

  /// Build needle gauge section
  Widget _buildNeedleGaugeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Needle Gauge',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (_isEditingNeedleGauge) ...[
          // Editing mode
          TextFormField(
            initialValue: _editingNeedleGauge,
            onChanged: (value) {
              setState(() {
                _editingNeedleGauge = value.trim();
                _markAsChanged();
              });
            },
            decoration: InputDecoration(
              labelText: 'Needle Gauge',
              hintText: '20G, 22G, 25G',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.colorize),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              '18G',
              '20G',
              '22G',
              '25G',
            ].map(_buildGaugeChip).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingNeedleGauge = false;
                      // Reset to original value
                      final schedule = ref.read(fluidScheduleProvider);
                      if (schedule != null) {
                        _editingNeedleGauge = schedule.needleGauge ?? '';
                      }
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingNeedleGauge = false;
                    });
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ] else ...[
          // Display mode
          EditableMedicalField(
            label: 'Needle Gauge',
            value: _editingNeedleGauge.isNotEmpty
                ? _editingNeedleGauge
                : 'No information',
            isEmpty: _editingNeedleGauge.isEmpty,
            icon: Icons.colorize,
            onEdit: () {
              setState(() {
                _isEditingNeedleGauge = true;
              });
            },
          ),
        ],
      ],
    );
  }

  /// Build reminder time section
  Widget _buildReminderTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder Time',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (_isEditingReminderTime) ...[
          // Editing mode
          GestureDetector(
            onTap: () async {
              final selectedTime = await showTimePicker(
                context: context,
                initialTime: _editingReminderTime != null
                    ? TimeOfDay.fromDateTime(_editingReminderTime!)
                    : const TimeOfDay(hour: 9, minute: 0),
              );

              if (selectedTime != null) {
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
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    _editingReminderTime != null
                        ? _formatTime(_editingReminderTime!)
                        : 'Select reminder time',
                    style: AppTextStyles.body.copyWith(
                      color: _editingReminderTime != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingReminderTime = false;
                      // Reset to original value
                      final schedule = ref.read(fluidScheduleProvider);
                      if (schedule != null &&
                          schedule.reminderTimes.isNotEmpty) {
                        _editingReminderTime = schedule.reminderTimes.first;
                      }
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingReminderTime = false;
                    });
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ] else ...[
          // Display mode
          EditableMedicalField(
            label: 'Reminder Time',
            value: _editingReminderTime != null
                ? _formatTime(_editingReminderTime!)
                : 'No information',
            isEmpty: _editingReminderTime == null,
            icon: Icons.access_time,
            onEdit: () {
              setState(() {
                _isEditingReminderTime = true;
              });
            },
          ),
        ],
      ],
    );
  }

  /// Build gauge chip for quick selection
  Widget _buildGaugeChip(String gauge) {
    final isSelected = _editingNeedleGauge == gauge;

    return GestureDetector(
      onTap: () {
        setState(() {
          _editingNeedleGauge = gauge;
          _markAsChanged();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          gauge,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
