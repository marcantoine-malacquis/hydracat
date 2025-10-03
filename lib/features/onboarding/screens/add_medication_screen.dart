import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/onboarding/widgets/rotating_wheel_picker.dart';
import 'package:hydracat/features/onboarding/widgets/time_picker_group.dart';
import 'package:hydracat/features/onboarding/widgets/treatment_popup_wrapper.dart';
import 'package:hydracat/l10n/app_localizations.dart';

/// Multi-step screen for adding/editing medications
class AddMedicationScreen extends StatefulWidget {
  /// Creates an [AddMedicationScreen]
  const AddMedicationScreen({
    this.initialMedication,
    this.isEditing = false,
    super.key,
  });

  /// Initial medication data for editing
  final MedicationData? initialMedication;

  /// Whether this is editing an existing medication
  final bool isEditing;

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
      _dosage = medication.dosage ?? '1';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: MedicationStepPopup(
          title: _getStepTitle(l10n),
          currentStep: _currentStep,
          totalSteps: _totalSteps,
          onPrevious: _currentStep > 1 ? _onPrevious : null,
          onNext: _currentStep < _totalSteps ? _onNext : null,
          onSave: _currentStep == _totalSteps ? _onSave : null,
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
        ),
      ),
    );
  }

  String _getStepTitle(AppLocalizations l10n) {
    return switch (_currentStep) {
      1 => widget.isEditing
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
                      RegExp('[0-9./,]'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<MedicationStrengthUnit>(
                  initialValue: _strengthUnit,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  isExpanded: true,
                  items: MedicationStrengthUnit.values
                      .map((unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(
                              unit.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: _strengthAmount.isNotEmpty
                      ? (value) {
                          setState(() {
                            _strengthUnit = value;
                          });
                        }
                      : null,
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
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Dosage *',
                    hintText: 'e.g., 1, 1/2, 2.5',
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
                      RegExp('[0-9./,]'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<MedicationUnit>(
                  initialValue: _selectedUnit,
                  decoration: InputDecoration(
                    labelText: 'Unit *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  isExpanded: true,
                  items: MedicationUnit.values
                      .map((unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(
                              unit.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedUnit = value;
                      });
                    }
                  },
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

          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: RotatingWheelPicker<TreatmentFrequency>(
              items: TreatmentFrequency.values,
              initialIndex: TreatmentFrequency.values.indexOf(
                _selectedFrequency,
              ),
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedFrequency = TreatmentFrequency.values[index];
                  // Update reminder times when frequency changes
                  _reminderTimes = AppDateUtils.generateDefaultReminderTimes(
                    _selectedFrequency.administrationsPerDay,
                  );
                });
              },
            ),
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
        dosage: _dosage.isEmpty ? null : _dosage,
        strengthAmount: _strengthAmount.isEmpty ? null : _strengthAmount,
        strengthUnit: _strengthUnit,
        customStrengthUnit:
            _customStrengthUnit.isEmpty ? null : _customStrengthUnit,
      );

      // Return the medication to the previous screen
      if (mounted) {
        Navigator.of(context).pop(medication);
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to save medication. '
              'Please check all fields and try again.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
