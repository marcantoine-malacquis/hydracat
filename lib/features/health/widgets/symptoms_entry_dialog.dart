import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_animations.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/health/exceptions/health_exceptions.dart';
import 'package:hydracat/features/health/models/health_parameter.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';
import 'package:hydracat/features/health/services/symptoms_service.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';
import 'package:intl/intl.dart';

/// Full-screen popup dialog for logging symptoms with 0-10 sliders per symptom
///
/// Supports:
/// - Add mode (existingEntry == null)
/// - Edit mode (existingEntry != null)
/// - Date selection (backdate allowed, future dates blocked)
/// - 6 symptom sliders (vomiting, diarrhea, constipation, lethargy,
/// suppressed appetite, injection site reaction)
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
  late Map<String, int?> _symptomScores;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.existingEntry?.date ?? DateTime.now();
    _notesFocusNode = FocusNode();

    // Initialize symptom scores from existing entry or set all to null
    _symptomScores = {};
    for (final symptomKey in SymptomType.all) {
      _symptomScores[symptomKey] = widget.existingEntry?.symptoms?[symptomKey];
    }

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

    // Filter out null values - only include symptoms with scores
    final symptomsToSave = <String, int>{};
    for (final entry in _symptomScores.entries) {
      if (entry.value != null) {
        symptomsToSave[entry.key] = entry.value!;
      }
    }

    // If no symptoms, pass null
    final symptomsMap = symptomsToSave.isEmpty ? null : symptomsToSave;

    setState(() {
      _isSaving = true;
    });

    try {
      final service = SymptomsService();
      await service.saveSymptoms(
        userId: currentUser.id,
        petId: primaryPet.id,
        date: _selectedDate,
        symptoms: symptomsMap,
        notes: notes.isEmpty ? null : notes,
      );

      if (mounted) {
        // Clear SummaryService TTL cache to ensure fresh data
        ref.read(summaryServiceProvider).clearAllCaches();

        // Invalidate monthly symptoms provider to refresh progress card
        ref.invalidate(currentMonthSymptomsSummaryProvider);

        // Dismiss popup
        OverlayService.hide();

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

  Widget _buildSaveButton() {
    final isEditMode = widget.existingEntry != null;

    return FilledButton(
      onPressed: _isSaving ? null : _save,
      child: _isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(isEditMode ? 'Save' : 'Save symptoms'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingEntry != null;

    return LoggingPopupWrapper(
      title: isEditMode ? 'Edit Symptoms' : 'Log Symptoms',
      onDismiss: () {
        // No special cleanup needed
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date selector
          _buildDateSelector(),

          const SizedBox(height: AppSpacing.md),

          // Symptom sliders (one per symptom from SymptomType.all)
          ...SymptomType.all
              .map(
                (symptomKey) => [
                  _SymptomSlider(
                    symptomKey: symptomKey,
                    symptomLabel: _getSymptomLabel(symptomKey),
                    value: _symptomScores[symptomKey],
                    onChanged: (newValue) {
                      setState(() {
                        _symptomScores[symptomKey] = newValue;
                        // Clear error when user makes changes
                        if (_errorMessage != null) {
                          _errorMessage = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              )
              .expand((x) => x),

          // Notes field
          _buildNotesField(),

          // Error message
          _buildErrorMessage(),

          const SizedBox(height: AppSpacing.lg),

          // Save button
          _buildSaveButton(),
        ],
      ),
    );
  }

  String _getSymptomLabel(String symptomKey) {
    switch (symptomKey) {
      case SymptomType.vomiting:
        return 'Vomiting';
      case SymptomType.diarrhea:
        return 'Diarrhea';
      case SymptomType.constipation:
        return 'Constipation';
      case SymptomType.lethargy:
        return 'Lethargy';
      case SymptomType.suppressedAppetite:
        return 'Suppressed Appetite';
      case SymptomType.injectionSiteReaction:
        return 'Injection Site Reaction';
      default:
        return symptomKey;
    }
  }
}

/// Helper widget for a single symptom slider with N/A as first position
class _SymptomSlider extends StatelessWidget {
  const _SymptomSlider({
    required this.symptomKey,
    required this.symptomLabel,
    required this.value,
    required this.onChanged,
  });

  final String symptomKey;
  final String symptomLabel;
  final int? value;
  final ValueChanged<int?> onChanged;

  /// Maps symptom score to slider position
  /// Position 0 = N/A (null), positions 1-11 = scores 0-10
  double _scoreToSliderPosition(int? score) {
    return score == null ? 0.0 : (score + 1).toDouble();
  }

  /// Maps slider position to symptom score
  /// Position 0 = N/A (null), positions 1-11 = scores 0-10
  int? _sliderPositionToScore(double position) {
    final pos = position.round();
    return pos == 0 ? null : (pos - 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNA = value == null;
    final sliderPosition = _scoreToSliderPosition(value);

    return Row(
      children: [
        // Symptom label (left side)
        SizedBox(
          width: 120,
          child: Text(
            symptomLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Slider (middle, takes remaining space)
        Expanded(
          child: HydraSlider(
            value: sliderPosition,
            max: 11,
            divisions: 11,
            onChanged: (double newPosition) {
              HapticFeedback.selectionClick();
              final newScore = _sliderPositionToScore(newPosition);
              onChanged(newScore);
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Value label (right side)
        SizedBox(
          width: 40,
          child: Text(
            isNA ? 'N/A' : value.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isNA
                  ? theme.colorScheme.onSurfaceVariant
                  : AppColors.primary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
