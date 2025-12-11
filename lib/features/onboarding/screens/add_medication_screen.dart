import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/core/utils/dosage_utils.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/onboarding/widgets/time_picker_group.dart';
import 'package:hydracat/features/onboarding/widgets/treatment_popup_wrapper.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Multi-step screen for adding/editing medications
class AddMedicationScreen extends StatefulWidget {
  /// Creates an [AddMedicationScreen]
  const AddMedicationScreen({
    this.initialMedication,
    this.isEditing = false,
    this.onSave,
    this.onCancel,
    this.onFormChanged,
    super.key,
  });

  /// Initial medication data for editing
  final MedicationData? initialMedication;

  /// Whether this is editing an existing medication
  final bool isEditing;

  /// Callback when medication is saved
  final void Function(MedicationData)? onSave;

  /// Callback when medication editing is cancelled
  final VoidCallback? onCancel;

  /// Callback when form data changes (for unsaved changes tracking)
  final VoidCallback? onFormChanged;

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _strengthAmountController =
      TextEditingController();
  final TextEditingController _customStrengthUnitController =
      TextEditingController();

  int _currentStep = 1;
  static const int _totalSteps = 4;

  // Form data
  String _medicationName = '';
  String _dosage = '1';
  double? _dosageValue = 1;
  String? _dosageError;
  MedicationUnit _selectedUnit = MedicationUnit.pills;
  TreatmentFrequency _selectedFrequency = TreatmentFrequency.onceDaily;
  List<TimeOfDay> _reminderTimes = [];
  String _strengthAmount = '';
  MedicationStrengthUnit? _strengthUnit;
  String _customStrengthUnit = '';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFromExisting();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _dosageController.dispose();
    _strengthAmountController.dispose();
    _customStrengthUnitController.dispose();
    super.dispose();
  }

  void _initializeFromExisting() {
    if (widget.initialMedication != null) {
      final medication = widget.initialMedication!;
      _nameController.text = medication.name;
      _medicationName = medication.name;
      _dosageValue = medication.dosage ?? 1.0;
      _dosage = DosageUtils.formatDosageForDisplay(_dosageValue!);
      _dosageController.text = _dosage;
      _selectedUnit = medication.unit;
      _selectedFrequency = medication.frequency;
      _reminderTimes = medication.reminderTimes
          .map(TimeOfDay.fromDateTime)
          .toList();
      _strengthAmount = medication.strengthAmount ?? '';
      _strengthAmountController.text = _strengthAmount;
      _strengthUnit = medication.strengthUnit;
      _customStrengthUnit = medication.customStrengthUnit ?? '';
      _customStrengthUnitController.text = _customStrengthUnit;
    } else {
      _reminderTimes = AppDateUtils.generateDefaultReminderTimes(
        _selectedFrequency.administrationsPerDay,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MedicationStepPopup(
      title: _getStepTitle(l10n),
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      onPrevious: _currentStep > 1 ? _onPrevious : null,
      onNext: _currentStep < _totalSteps ? _onNext : null,
      onSave: _currentStep == _totalSteps ? _onSave : null,
      onCancel: widget.onCancel,
      isNextEnabled: _isCurrentStepValid(),
      isLoading: _isLoading,
      child: SizedBox(
        height: 400,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildNameAndUnitStep(),
            _buildDosageStep(),
            _buildFrequencyStep(),
            _buildReminderTimesStep(),
          ],
        ),
      ),
    );
  }

  String _getStepTitle(AppLocalizations l10n) {
    return switch (_currentStep) {
      1 =>
        widget.isEditing
            ? l10n.editMedicationDetails
            : l10n.addMedicationDetails,
      2 => l10n.setDosage,
      3 => l10n.setFrequency,
      4 => l10n.setReminderTimes,
      _ => l10n.addMedication,
    };
  }

  Widget _buildNameAndUnitStep() {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.medicationInformation,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            l10n.medicationInformationDesc,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),

          // Medication name
          TextFormField(
            controller: _nameController,
            onChanged: (value) {
              setState(() {
                _medicationName = value.trim();
              });
              widget.onFormChanged?.call();
            },
            decoration: InputDecoration(
              labelText: l10n.medicationNameLabel,
              hintText: l10n.medicationNameHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.medication),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),

          // Medication strength section
          Text(
            'Medication Strength (optional)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Enter the concentration or strength of the medication',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _strengthAmountController,
                  onChanged: (value) {
                    setState(() {
                      _strengthAmount = value.trim();
                    });
                    widget.onFormChanged?.call();
                  },
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText: 'e.g., 2.5, 1/2, 10',
                    helperText: 'e.g., 2.5 mg, 5 mg/mL',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.science_outlined),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      // The library directive may trigger
                      // deprecated_member_use warnings
                      // in some Dart versions.
                      // ignore: deprecated_member_use
                      RegExp('[0-9./,]'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: HydraDropdown<MedicationStrengthUnit>(
                  value: _strengthUnit,
                  items: MedicationStrengthUnit.values,
                  onChanged: (value) {
                    if (_strengthAmount.isNotEmpty) {
                      setState(() {
                        _strengthUnit = value;
                      });
                      widget.onFormChanged?.call();
                    }
                  },
                  itemBuilder: (unit) => Text(
                    unit.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                  labelText: 'Unit',
                  enabled: _strengthAmount.isNotEmpty,
                ),
              ),
            ],
          ),

          // Custom unit field (shown when "Other" is selected)
          if (_strengthUnit == MedicationStrengthUnit.other) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _customStrengthUnitController,
              onChanged: (value) {
                setState(() {
                  _customStrengthUnit = value.trim();
                });
                widget.onFormChanged?.call();
              },
              decoration: InputDecoration(
                labelText: 'Custom Unit',
                hintText: 'e.g., mg/kg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.edit),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDosageStep() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dosage',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              children: const [
                TextSpan(text: 'Enter the '),
                TextSpan(
                  text: 'amount per administration',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' and select the medication unit.'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _dosageController,
                  onChanged: (value) {
                    setState(() {
                      _dosage = value.trim();
                      // Validate and convert to double
                      final error = DosageUtils.validateDosageString(_dosage);
                      if (error != null) {
                        _dosageError = error;
                        _dosageValue = null;
                      } else {
                        _dosageError = null;
                        _dosageValue = DosageUtils.parseDosageString(_dosage);
                      }
                    });
                    widget.onFormChanged?.call();
                  },
                  decoration: InputDecoration(
                    labelText: 'Dosage *',
                    hintText: 'e.g., 1, 1/2, 2.5',
                    errorText: _dosageError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.straighten),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      // The library directive may trigger
                      // deprecated_member_use warnings
                      // in some Dart versions.
                      // ignore: deprecated_member_use
                      RegExp('[0-9./,]'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: HydraDropdown<MedicationUnit>(
                  value: _selectedUnit,
                  items: MedicationUnit.values,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedUnit = value;
                      });
                      widget.onFormChanged?.call();
                    }
                  },
                  itemBuilder: (unit) => Text(
                    unit.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                  labelText: 'Unit *',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyStep() {
    final theme = Theme.of(context);
    const frequencies = TreatmentFrequency.values;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Administration Frequency',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'How often should this medication be given?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),

          HydraList(
            padding: EdgeInsets.zero,
            items: frequencies.map((frequency) {
              final isSelected = frequency == _selectedFrequency;
              return HydraListItem(
                title: Text(
                  frequency.displayName,
                  textAlign: TextAlign.center,
                  style:
                      theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.9,
                        ),
                      ) ??
                      TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.9,
                        ),
                      ),
                ),
                isSelected: isSelected,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                onTap: () {
                  setState(() {
                    _selectedFrequency = frequency;
                    // Update reminder times when frequency changes
                    _reminderTimes = AppDateUtils.generateDefaultReminderTimes(
                      _selectedFrequency.administrationsPerDay,
                    );
                  });
                  widget.onFormChanged?.call();
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Frequency description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected: ${_selectedFrequency.displayName}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getFrequencyDescription(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFrequencyDescription() {
    return switch (_selectedFrequency) {
      TreatmentFrequency.onceDaily =>
        "One administration per day. You'll set 1 reminder time.",
      TreatmentFrequency.twiceDaily =>
        "Two administrations per day. You'll set 2 reminder times.",
      TreatmentFrequency.thriceDaily =>
        "Three administrations per day. You'll set 3 reminder times.",
      TreatmentFrequency.everyOtherDay =>
        "One administration every other day. You'll set 1 reminder time.",
      TreatmentFrequency.every3Days =>
        "One administration every 3 days. You'll set 1 reminder time.",
    };
  }

  Widget _buildReminderTimesStep() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reminder Times',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Set reminder times for '
            '${_selectedFrequency.displayName.toLowerCase()}.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),

          TimePickerGroup(
            frequency: _selectedFrequency,
            initialTimes: _reminderTimes,
            onTimesChanged: (times) {
              setState(() {
                _reminderTimes = times;
              });
              widget.onFormChanged?.call();
            },
          ),
        ],
      ),
    );
  }

  bool _isCurrentStepValid() {
    return switch (_currentStep) {
      1 => _medicationName.isNotEmpty,
      2 => _dosage.trim().isNotEmpty,
      3 => true,
      4 => _reminderTimes.length == _selectedFrequency.administrationsPerDay,
      _ => false,
    };
  }

  void _onPrevious() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onNext() {
    if (_currentStep < _totalSteps && _isCurrentStepValid()) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _onSave() async {
    if (!_isCurrentStepValid()) return;

    setState(() => _isLoading = true);

    try {
      // Convert TimeOfDay to DateTime (using today as base)
      final now = DateTime.now();
      final reminderDateTimes = _reminderTimes.map((time) {
        return DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );
      }).toList();

      final medication = MedicationData(
        name: _medicationName,
        unit: _selectedUnit,
        frequency: _selectedFrequency,
        reminderTimes: reminderDateTimes,
        dosage: _dosageValue,
        strengthAmount: _strengthAmount.isEmpty ? null : _strengthAmount,
        strengthUnit: _strengthUnit,
        customStrengthUnit: _customStrengthUnit.isEmpty
            ? null
            : _customStrengthUnit,
      );

      // Return the medication via callback
      if (mounted) {
        widget.onSave?.call(medication);
      }
    } on Exception {
      if (mounted) {
        HydraSnackBar.showError(
          context,
          'Failed to save medication. '
          'Please check all fields and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
