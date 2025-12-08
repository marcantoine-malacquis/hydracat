import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/lab_reference_ranges.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/profile/models/lab_measurement.dart';
import 'package:hydracat/features/profile/models/lab_result.dart';
import 'package:hydracat/features/profile/models/latest_lab_summary.dart';
import 'package:hydracat/features/profile/models/medical_info.dart';
import 'package:hydracat/features/profile/widgets/ckd_stage_hero_card.dart';
import 'package:hydracat/features/profile/widgets/lab_history_section.dart';
import 'package:hydracat/features/profile/widgets/lab_value_display_with_gauge.dart';
import 'package:hydracat/features/profile/widgets/lab_values_entry_dialog.dart';
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

  // Track what's been modified
  bool _hasChanges = false;
  bool _isSaving = false;

  // Error state
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _initializeFromProfile();
    // Load lab results after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).loadLabResults();

      // Listen to changes in primaryPet.medicalInfo.irisStage
      // This will react when lab results update the IRIS stage
      ref.listenManual(
        primaryPetProvider,
        (previous, next) {
          final previousStage = previous?.medicalInfo.irisStage;
          final nextStage = next?.medicalInfo.irisStage;
          if (previousStage != nextStage) {
            // IRIS stage changed externally (e.g., from lab result save)
            _syncWithProvider();
          }
        },
      );
    });
  }

  /// Initialize editing state from current profile data
  void _initializeFromProfile() {
    final primaryPet = ref.read(primaryPetProvider);
    if (primaryPet?.medicalInfo != null) {
      final medicalInfo = primaryPet!.medicalInfo;
      setState(() {
        _editingIrisStage = medicalInfo.irisStage;
        // Lab values removed - now using labResults subcollection
      });
    }
  }

  /// Sync local editing state with provider data
  /// Called when provider data changes externally (e.g., lab result save)
  /// Only updates if there are no unsaved changes to avoid
  /// overwriting user edits
  void _syncWithProvider() {
    if (!_hasChanges) {
      final primaryPet = ref.read(primaryPetProvider);
      if (primaryPet?.medicalInfo != null) {
        final medicalInfo = primaryPet!.medicalInfo;
        final newIrisStage = medicalInfo.irisStage;

        // Only update if the value actually changed externally
        if (_editingIrisStage != newIrisStage) {
          setState(() {
            _editingIrisStage = newIrisStage;
          });
        }
      }
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

      // Create updated medical info (lab values removed)
      final updatedMedicalInfo = primaryPet.medicalInfo.copyWith(
        irisStage: _editingIrisStage,
        // labValues removed - now using labResults subcollection
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

  /// Show dialog to add new lab values
  Future<void> _showAddLabValuesDialog() async {
    final result = await showHydraBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.background,
      builder: (sheetContext) => const HydraBottomSheet(
        backgroundColor: AppColors.background,
        child: LabValuesEntryDialog(),
      ),
    );

    if (result != null && mounted) {
      await _saveLabResult(result);
    }
  }

  /// Show dialog to edit lab values
  ///
  /// If [labResult] is provided, edits that specific result.
  /// Otherwise, edits the latest lab result.
  Future<void> _showEditLabValuesDialog([LabResult? labResult]) async {
    final primaryPet = ref.read(primaryPetProvider);
    if (primaryPet == null) return;

    LabResult? fullResult;

    if (labResult != null) {
      // Use the provided lab result directly
      fullResult = labResult;
    } else {
      // Get the full latest lab result to pre-fill the dialog
      final latestSummary = primaryPet.medicalInfo.latestLabResult;
      if (latestSummary == null) return;

      // Fetch the full lab result from the subcollection
      fullResult = await ref
          .read(profileProvider.notifier)
          .getLabResult(latestSummary.labResultId);

      if (fullResult == null) {
        if (mounted) {
          HydraSnackBar.showError(
            context,
            'Could not load lab result details',
          );
        }
        return;
      }
    }

    if (!mounted) return;

    final result = await showHydraBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.background,
      builder: (sheetContext) => HydraBottomSheet(
        backgroundColor: AppColors.background,
        child: LabValuesEntryDialog(existingResult: fullResult),
      ),
    );

    if (result != null && mounted) {
      await _saveLabResult(result);
    }
  }

  /// Update an existing lab result (called from detail popup after editing)
  Future<void> _updateLabResult(LabResult updatedLabResult) async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      // Save the updated lab result using createLabResult
      // (which upserts based on ID)
      final success = await ref
          .read(profileProvider.notifier)
          .createLabResult(
            labResult: updatedLabResult,
            preferredUnitSystem: updatedLabResult.creatinine?.unit == 'µmol/L'
                ? 'si'
                : 'us',
          );

      if (success && mounted) {
        HydraSnackBar.showSuccess(context, 'Lab values updated successfully');
      } else if (mounted) {
        setState(() {
          _saveError = 'Failed to update lab values';
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _saveError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Delete a lab result (called from detail popup)
  Future<void> _deleteLabResult(LabResult labResult) async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final success = await ref
          .read(profileProvider.notifier)
          .deleteLabResult(labResult.id);

      if (success && mounted) {
        HydraSnackBar.showSuccess(
          context,
          'Lab result deleted successfully',
        );
      } else if (mounted) {
        setState(() {
          _saveError = 'Failed to delete lab result';
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _saveError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Save lab result from dialog data (used when adding new results)
  Future<void> _saveLabResult(Map<String, dynamic> data) async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final primaryPet = ref.read(primaryPetProvider);
      if (primaryPet == null) {
        throw Exception('No pet profile found');
      }

      // Build the values map with LabMeasurement objects
      final values = <String, LabMeasurement>{};

      if (data['creatinine'] != null) {
        values['creatinine'] = LabMeasurement(
          value: data['creatinine'] as double,
          unit: data['creatinineUnit'] as String,
        );
      }

      if (data['bun'] != null) {
        values['bun'] = LabMeasurement(
          value: data['bun'] as double,
          unit: data['bunUnit'] as String,
        );
      }

      if (data['sdma'] != null) {
        values['sdma'] = LabMeasurement(
          value: data['sdma'] as double,
          unit: data['sdmaUnit'] as String,
        );
      }

      // Create metadata if we have vet notes or IRIS stage
      LabResultMetadata? metadata;
      if (data['vetNotes'] != null || data['irisStage'] != null) {
        metadata = LabResultMetadata(
          vetNotes: data['vetNotes'] as String?,
          irisStage: data['irisStage'] as IrisStage?,
          source: 'manual',
        );
      }

      // Create the lab result
      final labResult = LabResult.create(
        petId: primaryPet.id,
        testDate: data['testDate'] as DateTime,
        values: values,
        metadata: metadata,
      );

      // Save via provider
      final success = await ref
          .read(profileProvider.notifier)
          .createLabResult(
            labResult: labResult,
            preferredUnitSystem: data['unitSystem'] as String,
          );

      if (success && mounted) {
        // Sync local state with updated provider data
        // (IRIS stage may have changed)
        _syncWithProvider();
        HydraSnackBar.showSuccess(context, 'Lab values saved successfully');
      } else if (mounted) {
        setState(() {
          _saveError = 'Failed to save lab values';
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _saveError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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

                    // Lab Results History Section
                    LabHistorySection(
                      onUpdateLabResult: _updateLabResult,
                      onDeleteLabResult: _deleteLabResult,
                    ),

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
    return CkdStageHeroCard(
      stage: _editingIrisStage,
    );
  }

  /// Build Lab Values section with card display
  Widget _buildLabValuesSection() {
    final primaryPet = ref.watch(primaryPetProvider);
    final latestFromSubcollection = ref.watch(latestLabResultProvider);

    // Prefer denormalized field for instant load, but fallback to subcollection
    var latestResult = primaryPet?.medicalInfo.latestLabResult;

    // If denormalized field is missing
    // but we have a result in subcollection, derive it
    if (latestResult == null && latestFromSubcollection != null) {
      latestResult = _buildSummaryFromLabResult(latestFromSubcollection);
      // Trigger backfill to persist this for future loads
      _triggerBackfillIfNeeded(latestResult);
    }

    // Get the full lab result for vet notes
    // Use latestFromSubcollection if it matches, otherwise fetch it
    LabResult? fullLabResult;
    if (latestResult != null) {
      if (latestFromSubcollection?.id == latestResult.labResultId) {
        fullLabResult = latestFromSubcollection;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lab Values',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            HydraButton(
              onPressed: _showAddLabValuesDialog,
              variant: HydraButtonVariant.text,
              size: HydraButtonSize.small,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 4),
                  Text('Add'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Lab values card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bloodwork date at top
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      latestResult?.testDate != null
                          ? 'Latest: ${_formatDate(latestResult!.testDate)}'
                          : 'No bloodwork recorded',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (latestResult != null)
                    TextButton(
                      onPressed: _showEditLabValuesDialog,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.primary,
                      ),
                      child: Text(
                        'Edit',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                ],
              ),

              // Veterinarian notes if available
              if (latestResult != null)
                FutureBuilder<LabResult?>(
                  future: fullLabResult != null
                      ? Future.value(fullLabResult)
                      : ref
                            .read(profileProvider.notifier)
                            .getLabResult(latestResult.labResultId),
                  builder: (context, snapshot) {
                    final labResult = snapshot.data;
                    final vetNotes = labResult?.metadata?.vetNotes;

                    if (vetNotes != null && vetNotes.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.notes,
                                size: 14,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  vetNotes,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.md),

              // Lab values with gauges
              LabValueDisplayWithGauge(
                label: 'Creatinine',
                value: latestResult?.creatinine,
                unit: latestResult != null
                    ? _getCreatinineUnit(latestResult)
                    : 'mg/dL',
                referenceRange: latestResult != null
                    ? getLabReferenceRange(
                        'creatinine',
                        _getCreatinineUnit(latestResult),
                      )
                    : creatinineRange,
              ),
              const SizedBox(height: AppSpacing.sm),
              LabValueDisplayWithGauge(
                label: 'BUN',
                value: latestResult?.bun,
                unit: latestResult != null
                    ? _getBunUnit(latestResult)
                    : 'mg/dL',
                referenceRange: latestResult != null
                    ? getLabReferenceRange('bun', _getBunUnit(latestResult))
                    : bunRange,
              ),
              const SizedBox(height: AppSpacing.sm),
              LabValueDisplayWithGauge(
                label: 'SDMA',
                value: latestResult?.sdma,
                unit: 'µg/dL',
                referenceRange: sdmaRange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build a LatestLabSummary from a LabResult
  /// (fallback when denormalized field is missing)
  LatestLabSummary _buildSummaryFromLabResult(LabResult labResult) {
    // Extract values from the LabResult
    final creatinineValue = labResult.creatinine?.value;
    final bunValue = labResult.bun?.value;
    final sdmaValue = labResult.sdma?.value;
    final phosphorusValue = labResult.phosphorus?.value;

    // Infer preferredUnitSystem from stored analyte units
    var preferredUnitSystem = 'us'; // default

    // Check creatinine unit
    if (labResult.creatinine?.unit == 'µmol/L') {
      preferredUnitSystem = 'si';
    }
    // Check BUN unit as secondary indicator
    else if (labResult.bun?.unit == 'mmol/L') {
      preferredUnitSystem = 'si';
    }

    return LatestLabSummary(
      testDate: labResult.testDate,
      labResultId: labResult.id,
      creatinine: creatinineValue,
      bun: bunValue,
      sdma: sdmaValue,
      phosphorus: phosphorusValue,
      preferredUnitSystem: preferredUnitSystem,
    );
  }

  /// Trigger backfill to persist derived summary to Firestore
  ///
  /// This gradually backfills all pets so future loads don't need the fallback.
  /// Runs asynchronously without blocking the UI.
  void _triggerBackfillIfNeeded(LatestLabSummary derivedSummary) {
    final primaryPet = ref.read(primaryPetProvider);
    if (primaryPet == null) return;

    // Only backfill if the denormalized field is actually missing
    if (primaryPet.medicalInfo.latestLabResult != null) return;

    // Update the pet with the derived summary (fire and forget)
    Future.microtask(() async {
      try {
        final updatedMedicalInfo = primaryPet.medicalInfo.copyWith(
          latestLabResult: derivedSummary,
        );

        final updatedPet = primaryPet.copyWith(
          medicalInfo: updatedMedicalInfo,
          updatedAt: DateTime.now(),
        );

        await ref.read(profileProvider.notifier).updatePet(updatedPet);
      } on Exception {
        // Silently fail - this is an optimization, not critical
        // The UI will continue to work via the fallback path
      }
    });
  }

  /// Get creatinine unit from latest result (with fallback)
  String _getCreatinineUnit(LatestLabSummary? result) {
    return result?.preferredUnitSystem == 'si' ? 'µmol/L' : 'mg/dL';
  }

  /// Get BUN unit from latest result (with fallback)
  String _getBunUnit(LatestLabSummary? result) {
    return result?.preferredUnitSystem == 'si' ? 'mmol/L' : 'mg/dL';
  }
}
