import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_animations.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/health/exceptions/health_exceptions.dart';
import 'package:hydracat/features/health/models/health_parameter.dart';
import 'package:hydracat/features/health/models/symptom_entry.dart';
import 'package:hydracat/features/health/models/symptom_raw_value.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';
import 'package:hydracat/features/health/services/symptom_severity_converter.dart';
import 'package:hydracat/features/health/services/symptoms_service.dart';
import 'package:hydracat/features/health/widgets/symptom_slider.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:hydracat/providers/symptoms_chart_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';
import 'package:intl/intl.dart';

/// Full-screen popup dialog for logging symptoms using hybrid tracking system
///
/// Uses symptom-specific inputs that capture medically accurate raw values:
/// - Vomiting: Number of episodes (SymptomNumberInput)
/// - Diarrhea: Stool quality enum (SymptomEnumInput)
/// - Constipation: Straining level enum (SymptomEnumInput)
/// - Energy: Energy level enum (SymptomEnumInput)
/// - Suppressed Appetite: Fraction eaten enum (SymptomEnumInput)
/// - Injection Site: Reaction severity enum (SymptomEnumInput)
///
/// Raw values are converted to 0-3 severity scores via SymptomSeverityConverter
/// for consistent analytics and visualization.
///
/// Supports:
/// - Add mode (existingEntry == null)
/// - Edit mode (existingEntry != null)
/// - Date selection (backdate allowed, future dates blocked)
/// - Optional notes field (max 500 chars, expands when used)
/// - Validation and save via SymptomsService
class SymptomsEntryDialog extends ConsumerStatefulWidget {
  /// Creates a [SymptomsEntryDialog]
  const SymptomsEntryDialog({
    this.existingEntry,
    super.key,
  });

  /// Existing entry for edit mode (null for add mode)
  final HealthParameter? existingEntry;

  @override
  ConsumerState<SymptomsEntryDialog> createState() =>
      _SymptomsEntryDialogState();
}

class _SymptomsEntryDialogState extends ConsumerState<SymptomsEntryDialog> {
  late final TextEditingController _notesController;
  late final FocusNode _notesFocusNode;

  late DateTime _selectedDate;

  // Raw values for each symptom (null = N/A)
  int? _vomitingEpisodes;
  DiarrheaQuality? _diarrheaQuality;
  ConstipationLevel? _constipationLevel;
  EnergyLevel? _energyLevel;
  AppetiteFraction? _appetiteFraction;
  InjectionSiteReaction? _injectionSiteReaction;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.existingEntry?.date ?? DateTime.now();
    _notesFocusNode = FocusNode();

    // Pre-fill from existing entry
    // (extracting raw values from SymptomEntry objects)
    final existingSymptoms = widget.existingEntry?.symptoms;

    // Vomiting: int (clamped to 0-10 for slider 0-10+ UX)
    final vomitingRaw = existingSymptoms?[SymptomType.vomiting]?.rawValue;
    if (vomitingRaw is int) {
      _vomitingEpisodes = math.max(0, math.min(10, vomitingRaw));
    } else {
      _vomitingEpisodes = null;
    }

    // Diarrhea: enum (deserialize from string)
    final diarrheaRaw = existingSymptoms?[SymptomType.diarrhea]?.rawValue;
    _diarrheaQuality = diarrheaRaw != null
        ? (diarrheaRaw is String
              ? DiarrheaQuality.fromString(diarrheaRaw)
              : diarrheaRaw as DiarrheaQuality)
        : null;

    // Constipation: enum (deserialize from string)
    final constipationRaw =
        existingSymptoms?[SymptomType.constipation]?.rawValue;
    _constipationLevel = constipationRaw != null
        ? (constipationRaw is String
              ? ConstipationLevel.fromString(constipationRaw)
              : constipationRaw as ConstipationLevel)
        : null;

    // Energy: enum (deserialize from string)
    final energyRaw = existingSymptoms?[SymptomType.energy]?.rawValue;
    _energyLevel = energyRaw != null
        ? (energyRaw is String
              ? EnergyLevel.fromString(energyRaw)
              : energyRaw as EnergyLevel)
        : null;

    // Suppressed Appetite: enum (deserialize from string)
    final appetiteRaw =
        existingSymptoms?[SymptomType.suppressedAppetite]?.rawValue;
    _appetiteFraction = appetiteRaw != null
        ? (appetiteRaw is String
              ? AppetiteFraction.fromString(appetiteRaw)
              : appetiteRaw as AppetiteFraction)
        : null;

    // Injection Site: enum (deserialize from string)
    final injectionRaw =
        existingSymptoms?[SymptomType.injectionSiteReaction]?.rawValue;
    _injectionSiteReaction = injectionRaw != null
        ? (injectionRaw is String
              ? InjectionSiteReaction.fromString(injectionRaw)
              : injectionRaw as InjectionSiteReaction)
        : null;

    _notesController = TextEditingController(
      text: widget.existingEntry?.notes ?? '',
    );

    _notesFocusNode.addListener(() {
      setState(() {}); // Rebuild to show/hide counter
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await HydraDatePicker.show(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    // Validate notes length
    final notes = _notesController.text.trim();
    if (notes.length > 500) {
      setState(() {
        _errorMessage = 'Notes must be 500 characters or less';
      });
      return;
    }

    // Get user and pet
    final currentUser = ref.read(currentUserProvider);
    final primaryPet = ref.read(primaryPetProvider);

    if (currentUser == null || primaryPet == null) {
      setState(() {
        _errorMessage = 'User or pet data not available';
      });
      return;
    }

    // Build SymptomEntry map from raw values
    final symptomEntries = <String, SymptomEntry>{};

    // Vomiting (int)
    if (_vomitingEpisodes != null) {
      symptomEntries[SymptomType.vomiting] =
          SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.vomiting,
            rawValue: _vomitingEpisodes,
          );
    }

    // Diarrhea (enum -> stored as enum.name string)
    if (_diarrheaQuality != null) {
      symptomEntries[SymptomType.diarrhea] =
          SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.diarrhea,
            rawValue: _diarrheaQuality!.name,
          );
    }

    // Constipation (enum -> stored as enum.name string)
    if (_constipationLevel != null) {
      symptomEntries[SymptomType.constipation] =
          SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.constipation,
            rawValue: _constipationLevel!.name,
          );
    }

    // Energy (enum -> stored as enum.name string)
    if (_energyLevel != null) {
      symptomEntries[SymptomType.energy] = SymptomSeverityConverter.createEntry(
        symptomType: SymptomType.energy,
        rawValue: _energyLevel!.name,
      );
    }

    // Suppressed Appetite (enum -> stored as enum.name string)
    if (_appetiteFraction != null) {
      symptomEntries[SymptomType.suppressedAppetite] =
          SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.suppressedAppetite,
            rawValue: _appetiteFraction!.name,
          );
    }

    // Injection Site (enum -> stored as enum.name string)
    if (_injectionSiteReaction != null) {
      symptomEntries[SymptomType.injectionSiteReaction] =
          SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.injectionSiteReaction,
            rawValue: _injectionSiteReaction!.name,
          );
    }

    // If no symptoms, pass null
    final symptomsToSave = symptomEntries.isEmpty ? null : symptomEntries;

    setState(() {
      _isSaving = true;
    });

    try {
      final service = SymptomsService();
      await service.saveSymptoms(
        userId: currentUser.id,
        petId: primaryPet.id,
        date: _selectedDate,
        symptoms: symptomsToSave, // Now Map<String, SymptomEntry>?
        notes: notes.isEmpty ? null : notes,
      );

      if (mounted) {
        // Targeted cache invalidation for the logged date
        final summaryService = ref.read(summaryServiceProvider);
        final weekStart = AppDateUtils.startOfWeekMonday(_selectedDate);
        final monthStart = DateTime(_selectedDate.year, _selectedDate.month);

        // Invalidate daily cache for the logged date
        summaryService
          ..invalidateCacheForDate(
            currentUser.id,
            primaryPet.id,
            _selectedDate,
          )
          // Invalidate weekly cache for the week containing the date
          ..clearWeeklyCacheForWeek(
            userId: currentUser.id,
            petId: primaryPet.id,
            date: _selectedDate,
          )
          // Invalidate monthly cache for the month containing the date
          ..clearMonthlyCacheForMonth(
            userId: currentUser.id,
            petId: primaryPet.id,
            date: _selectedDate,
          );

        // Invalidate Riverpod providers
        // Invalidate week summaries for the logged date's week
        ref
          ..invalidate(weekSummariesProvider(weekStart))
          // Invalidate symptom chart providers
          // (cascades from weekSummariesProvider, but explicit for clarity)
          ..invalidate(weeklySymptomBucketsProvider(weekStart))
          ..invalidate(symptomsChartDataProvider)
          // Invalidate monthly/year providers if viewing those granularities
          ..invalidate(monthlySymptomBucketsProvider(monthStart))
          ..invalidate(
            yearlySymptomBucketsProvider(DateTime(_selectedDate.year)),
          )
          ..invalidate(currentMonthSymptomsSummaryProvider);

        // Increment version provider (triggers automatic refetch)
        ref.read(symptomLogVersionProvider.notifier).state++;

        // Dismiss popup
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Show success snackbar
        HydraSnackBar.showSuccess(context, 'Symptoms saved successfully');
      }
    } on SymptomValidationException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isSaving = false;
        });
      }
    } on SymptomServiceException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isSaving = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save symptoms: $e';
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              DateFormat('MMM dd, yyyy').format(_selectedDate),
              style: AppTextStyles.body,
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  /// Compact date selector used in the popup header.
  Widget _buildHeaderDateSelector() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: _buildDateSelector(),
      ),
    );
  }

  Widget _buildNotesField() {
    return HydraTextField(
      controller: _notesController,
      focusNode: _notesFocusNode,
      maxLength: 500,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Notes (optional)',
        hintText: 'e.g., "After vet visit", "Before fluids"',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        counter: AnimatedOpacity(
          opacity: _notesFocusNode.hasFocus ? 1.0 : 0.0,
          duration: AppAnimations.getDuration(
            context,
            const Duration(milliseconds: 200),
          ),
          child: Text('${_notesController.text.length}/500'),
        ),
      ),
      minLines: _notesController.text.isNotEmpty ? 3 : 1,
      maxLines: 5,
      onChanged: (_) {
        setState(() {}); // Update counter
      },
    );
  }

  Widget _buildErrorMessage() {
    final theme = Theme.of(context);

    if (_errorMessage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        _errorMessage!,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }

  /// Platform-adaptive header action for saving.
  Widget _buildHeaderAction() {
    final isCupertino =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final label = isCupertino ? 'Done' : 'Save';

    if (_isSaving) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return TextButton(
      onPressed: _save,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: AppTextStyles.buttonPrimary.copyWith(
          fontWeight: isCupertino ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingEntry != null;

    return LoggingPopupWrapper(
      title: isEditMode ? 'Edit Symptoms' : 'Log Symptoms',
      headerContent: _buildHeaderDateSelector(),
      trailing: _buildHeaderAction(),
      showCloseButton: false,
      onDismiss: () {
        // No special cleanup needed
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Symptom inputs (symptom-specific widgets)
          const SizedBox(height: AppSpacing.xs),

          // 1. Vomiting - Slider (0-10+, index 0 = N/A)
          HydraCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: SymptomSlider<int>(
              label: 'Vomiting',
              value: _vomitingEpisodes,
              options: List<int>.generate(11, (index) => index),
              getLabel: (episodes) {
                if (episodes >= 10) return '10+ episodes';
                if (episodes == 0) return '0 episodes';
                if (episodes == 1) return '1 episode';
                return '$episodes episodes';
              },
              onChanged: (value) {
                setState(() {
                  _vomitingEpisodes = value;
                  if (_errorMessage != null) _errorMessage = null;
                });
              },
            ),
          ),

          // 2. Diarrhea - Slider
          HydraCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: SymptomSlider<DiarrheaQuality>(
              label: 'Diarrhea',
              value: _diarrheaQuality,
              options: DiarrheaQuality.values,
              getLabel: (quality) => quality.label,
              onChanged: (value) {
                setState(() {
                  _diarrheaQuality = value;
                  if (_errorMessage != null) _errorMessage = null;
                });
              },
            ),
          ),

          // 3. Constipation - Slider
          HydraCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: SymptomSlider<ConstipationLevel>(
              label: 'Constipation',
              value: _constipationLevel,
              options: ConstipationLevel.values,
              getLabel: (level) => level.label,
              onChanged: (value) {
                setState(() {
                  _constipationLevel = value;
                  if (_errorMessage != null) _errorMessage = null;
                });
              },
            ),
          ),

          // 4. Energy - Slider
          HydraCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: SymptomSlider<EnergyLevel>(
              label: 'Energy',
              value: _energyLevel,
              options: EnergyLevel.values,
              getLabel: (level) => level.label,
              onChanged: (value) {
                setState(() {
                  _energyLevel = value;
                  if (_errorMessage != null) _errorMessage = null;
                });
              },
            ),
          ),

          // 5. Suppressed Appetite - Slider
          HydraCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: SymptomSlider<AppetiteFraction>(
              label: 'Suppressed Appetite',
              value: _appetiteFraction,
              options: AppetiteFraction.values,
              getLabel: (fraction) => fraction.label,
              onChanged: (value) {
                setState(() {
                  _appetiteFraction = value;
                  if (_errorMessage != null) _errorMessage = null;
                });
              },
            ),
          ),

          // 6. Injection Site Reaction - Slider
          HydraCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: SymptomSlider<InjectionSiteReaction>(
              label: 'Injection Site Reaction',
              value: _injectionSiteReaction,
              options: InjectionSiteReaction.values,
              getLabel: (reaction) => reaction.label,
              onChanged: (value) {
                setState(() {
                  _injectionSiteReaction = value;
                  if (_errorMessage != null) _errorMessage = null;
                });
              },
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Notes field
          _buildNotesField(),

          // Error message
          _buildErrorMessage(),
        ],
      ),
    );
  }
}
