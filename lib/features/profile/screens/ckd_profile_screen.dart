import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/lab_reference_ranges.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/onboarding/widgets/iris_stage_selector.dart';
import 'package:hydracat/features/onboarding/widgets/lab_values_input.dart';
import 'package:hydracat/features/profile/models/medical_info.dart';
import 'package:hydracat/features/profile/widgets/editable_medical_field.dart';
import 'package:hydracat/features/profile/widgets/lab_value_display_with_gauge.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Screen for viewing and editing CKD medical information
class CkdProfileScreen extends ConsumerStatefulWidget {
  /// Creates a [CkdProfileScreen]
  const CkdProfileScreen({super.key});

  @override
  ConsumerState<CkdProfileScreen> createState() => _CkdProfileScreenState();
}

class _CkdProfileScreenState extends ConsumerState<CkdProfileScreen> {
  // Local editing state
  IrisStage? _editingIrisStage;
  LabValueData _editingLabValues = const LabValueData();
  DateTime? _editingLastCheckupDate;
  String _editingNotes = '';

  // Track what's been modified
  bool _hasChanges = false;
  bool _isSaving = false;

  // Error state
  String? _saveError;

  // Edit mode tracking
  bool _isEditingIrisStage = false;
  bool _isEditingLabValues = false;
  bool _isEditingLastCheckup = false;
  bool _isEditingNotes = false;

  @override
  void initState() {
    super.initState();
    _initializeFromProfile();
  }

  /// Initialize editing state from current profile data
  void _initializeFromProfile() {
    final primaryPet = ref.read(primaryPetProvider);
    if (primaryPet?.medicalInfo != null) {
      final medicalInfo = primaryPet!.medicalInfo;
      setState(() {
        _editingIrisStage = medicalInfo.irisStage;
        _editingLabValues = LabValueData(
          creatinine: medicalInfo.labValues?.creatinineMgDl,
          bun: medicalInfo.labValues?.bunMgDl,
          sdma: medicalInfo.labValues?.sdmaMcgDl,
          bloodworkDate: medicalInfo.labValues?.bloodworkDate,
        );
        _editingLastCheckupDate = medicalInfo.lastCheckupDate;
        _editingNotes = medicalInfo.notes ?? '';
      });
    }
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
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final primaryPet = ref.read(primaryPetProvider);
      if (primaryPet == null) {
        throw Exception('No pet profile found');
      }

      // Create updated medical info
      final updatedLabValues = _editingLabValues.hasValues
          ? LabValues(
              creatinineMgDl: _editingLabValues.creatinine,
              bunMgDl: _editingLabValues.bun,
              sdmaMcgDl: _editingLabValues.sdma,
              bloodworkDate: _editingLabValues.bloodworkDate,
            )
          : null;

      final updatedMedicalInfo = primaryPet.medicalInfo.copyWith(
        irisStage: _editingIrisStage,
        labValues: updatedLabValues,
        lastCheckupDate: _editingLastCheckupDate,
        notes: _editingNotes.trim().isEmpty ? null : _editingNotes.trim(),
      );

      // Validate the updated medical info
      final validationErrors = updatedMedicalInfo.validate();
      if (validationErrors.isNotEmpty) {
        throw Exception(validationErrors.first);
      }

      // Update the profile with new medical info
      final updatedProfile = primaryPet.copyWith(
        medicalInfo: updatedMedicalInfo,
        updatedAt: DateTime.now(),
      );

      // Save to Firebase via provider
      await ref.read(profileProvider.notifier).updatePet(updatedProfile);

      // Reset change tracking
      setState(() {
        _hasChanges = false;
        _isEditingIrisStage = false;
        _isEditingLabValues = false;
        _isEditingLastCheckup = false;
        _isEditingNotes = false;
      });

      // Show success feedback
      if (mounted) {
        HydraSnackBar.showSuccess(context, 'CKD profile updated successfully');
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

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final primaryPet = ref.watch(primaryPetProvider);
    final petName = primaryPet?.name ?? 'Your Cat';

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
            title: Text("$petName's CKD Profile"),
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
              await ref.read(profileProvider.notifier).refreshPrimaryPet();
              _initializeFromProfile();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // IRIS Stage Section
                    _buildIrisStageSection(),

                    const SizedBox(height: AppSpacing.xl),

                    // Lab Values Section
                    _buildLabValuesSection(),

                    const SizedBox(height: AppSpacing.xl),

                    // Last Checkup Section
                    _buildLastCheckupSection(),

                    const SizedBox(height: AppSpacing.xl),

                    // Notes Section
                    _buildNotesSection(),

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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build IRIS Stage section
  Widget _buildIrisStageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IRIS Stage',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (_isEditingIrisStage) ...[
          // Editing mode
          IrisStageSelector(
            selectedStage: _editingIrisStage,
            hasUserSelected: true,
            onStageChanged: (stage) {
              setState(() {
                _editingIrisStage = stage;
                _markAsChanged();
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingIrisStage = false;
                      // Reset to original value
                      _initializeFromProfile();
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
                      _isEditingIrisStage = false;
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
            label: 'IRIS Stage',
            value: _editingIrisStage?.displayName ?? 'No information',
            isEmpty: _editingIrisStage == null,
            icon: Icons.medical_information,
            onEdit: () {
              setState(() {
                _isEditingIrisStage = true;
              });
            },
          ),
        ],
      ],
    );
  }

  /// Build Lab Values section
  Widget _buildLabValuesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lab Values',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (_isEditingLabValues) ...[
          // Editing mode
          LabValuesInput(
            labValues: _editingLabValues,
            onValuesChanged: (newLabValues) {
              setState(() {
                _editingLabValues = newLabValues;
                _markAsChanged();
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingLabValues = false;
                      // Reset to original value
                      _initializeFromProfile();
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
                      _isEditingLabValues = false;
                    });
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ] else ...[
          // Display mode
          Column(
            children: [
              LabValueDisplayWithGauge(
                label: 'Creatinine',
                value: _editingLabValues.creatinine,
                referenceRange: creatinineRange,
                onEdit: () {
                  setState(() {
                    _isEditingLabValues = true;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              LabValueDisplayWithGauge(
                label: 'BUN',
                value: _editingLabValues.bun,
                referenceRange: bunRange,
                onEdit: () {
                  setState(() {
                    _isEditingLabValues = true;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              LabValueDisplayWithGauge(
                label: 'SDMA',
                value: _editingLabValues.sdma,
                referenceRange: sdmaRange,
                onEdit: () {
                  setState(() {
                    _isEditingLabValues = true;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              EditableDateField(
                label: 'Bloodwork Date',
                date: _editingLabValues.bloodworkDate,
                icon: Icons.calendar_month,
                onEdit: () {
                  setState(() {
                    _isEditingLabValues = true;
                  });
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Build Last Checkup section
  Widget _buildLastCheckupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last Vet Checkup',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (_isEditingLastCheckup) ...[
          // Editing mode
          GestureDetector(
            onTap: () async {
              final selectedDate = await HydraDatePicker.show(
                context: context,
                initialDate: _editingLastCheckupDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(
                  const Duration(days: 365 * 3),
                ),
                lastDate: DateTime.now(),
              );

              if (selectedDate != null) {
                setState(() {
                  _editingLastCheckupDate = selectedDate;
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
                    Icons.medical_services_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    _editingLastCheckupDate != null
                        ? _formatDate(_editingLastCheckupDate!)
                        : 'Select last checkup date',
                    style: AppTextStyles.body.copyWith(
                      color: _editingLastCheckupDate != null
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
                      _isEditingLastCheckup = false;
                      // Reset to original value
                      _initializeFromProfile();
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
                      _isEditingLastCheckup = false;
                    });
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ] else ...[
          // Display mode
          EditableDateField(
            label: 'Last Vet Checkup',
            date: _editingLastCheckupDate,
            icon: Icons.medical_services,
            onEdit: () {
              setState(() {
                _isEditingLastCheckup = true;
              });
            },
          ),
        ],
      ],
    );
  }

  /// Build Notes section
  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Notes',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (_isEditingNotes) ...[
          // Editing mode
          TextFormField(
            initialValue: _editingNotes,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Any additional medical information or notes...',
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
              setState(() {
                _editingNotes = value;
                _markAsChanged();
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingNotes = false;
                      // Reset to original value
                      _initializeFromProfile();
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
                      _isEditingNotes = false;
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
            label: 'Additional Notes',
            value: _editingNotes.trim().isEmpty
                ? 'No information'
                : _editingNotes.trim(),
            isEmpty: _editingNotes.trim().isEmpty,
            icon: Icons.notes,
            onEdit: () {
              setState(() {
                _isEditingNotes = true;
              });
            },
          ),
        ],
      ],
    );
  }
}
