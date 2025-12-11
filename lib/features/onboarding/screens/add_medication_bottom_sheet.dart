import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_accessibility.dart';
import 'package:hydracat/core/constants/app_animations.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/core/utils/dosage_utils.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/onboarding/widgets/time_picker_group.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/shared/widgets/accessibility/touch_target_icon_button.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Shows the add/edit medication bottom sheet
///
/// Returns the [MedicationData] if saved, null if cancelled.
Future<MedicationData?> showAddMedicationBottomSheet({
  required BuildContext context,
  MedicationData? initialMedication,
  bool isEditing = false,
}) {
  return showHydraBottomSheet<MedicationData>(
    context: context,
    isScrollControlled: true,
    isDismissible: false, // Handle dismissal manually for unsaved changes
    builder: (context) => AddMedicationBottomSheet(
      initialMedication: initialMedication,
      isEditing: isEditing,
    ),
  );
}

/// Multi-step bottom sheet for adding/editing medications
///
/// Displays a 4-step flow:
/// 1. Medication name and strength
/// 2. Dosage and unit
/// 3. Frequency
/// 4. Reminder times
class AddMedicationBottomSheet extends StatefulWidget {
  /// Creates an [AddMedicationBottomSheet]
  const AddMedicationBottomSheet({
    this.initialMedication,
    this.isEditing = false,
    super.key,
  });

  /// Initial medication data for editing
  final MedicationData? initialMedication;

  /// Whether this is editing an existing medication
  final bool isEditing;

  @override
  State<AddMedicationBottomSheet> createState() =>
      _AddMedicationBottomSheetState();
}

class _AddMedicationBottomSheetState extends State<AddMedicationBottomSheet> {
  // Controllers
  late final PageController _pageController;
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _strengthAmountController;
  late final TextEditingController _customStrengthUnitController;
  final ScrollController _strengthUnitScrollController = ScrollController();
  final ScrollController _dosageUnitScrollController = ScrollController();

  // Step tracking
  int _currentStep = 0;
  static const int _totalSteps = 4;
  bool _isAnimating = false;
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  // Form data
  String _medicationName = '';
  // Start empty so validation blocks progression until user enters a value
  String _dosage = '';
  double? _dosageValue;
  MedicationUnit _selectedUnit = MedicationUnit.pills;
  TreatmentFrequency _selectedFrequency = TreatmentFrequency.onceDaily;
  List<TimeOfDay> _reminderTimes = [];
  String _strengthAmount = '';
  MedicationStrengthUnit _strengthUnit = MedicationStrengthUnit.mg;
  String _customStrengthUnit = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _nameController = TextEditingController();
    _dosageController = TextEditingController();
    _strengthAmountController = TextEditingController();
    _customStrengthUnitController = TextEditingController();

    _initializeFromExisting();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _dosageController.dispose();
    _strengthAmountController.dispose();
    _customStrengthUnitController.dispose();
    _strengthUnitScrollController.dispose();
    _dosageUnitScrollController.dispose();
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
      _strengthUnit = medication.strengthUnit ?? MedicationStrengthUnit.mg;
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
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasUnsavedChanges) {
          final shouldPop = await _showUnsavedChangesDialog() ?? false;
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: HydraBottomSheet(
        heightFraction: 0.85,
        child: Column(
          children: [
            _buildHeader(context),
            _buildProgressBar(context),
            const SizedBox(height: AppSpacing.xl),
            Expanded(child: _buildContent(context)),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // Header title (always same)
  String _getHeaderTitle(BuildContext context) {
    final l10n = context.l10n;
    return widget.isEditing ? l10n.editMedication : l10n.addMedication;
  }

  /// Handles close button press in header
  Future<void> _handleClosePressed() async {
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }

    final shouldClose = await _showUnsavedChangesDialog() ?? false;
    if (shouldClose && mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Shows dialog asking user to confirm discarding unsaved changes
  Future<bool?> _showUnsavedChangesDialog() {
    final l10n = context.l10n;

    return showDialog<bool>(
      context: context,
      builder: (context) => HydraAlertDialog(
        title: Text(l10n.discardChanges),
        content: Text(l10n.discardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.cancel,
              style: AppTextStyles.buttonSecondary,
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(
              l10n.discard,
              style: AppTextStyles.buttonPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button (only after first step) to replace footer "Previous"
          if (_currentStep > 0)
            HydraBackButton(onPressed: _goToPreviousStep)
          else
            const SizedBox(width: AppAccessibility.minTouchTarget),
          // Centered title
          Expanded(
            child: Text(
              _getHeaderTitle(context),
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
          ),
          // Close button on the right
          TouchTargetIconButton(
            icon: const HydraIcon(
              icon: AppIcons.close,
            ),
            onPressed: _handleClosePressed,
            semanticLabel: l10n.close,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final progress = (_currentStep + 1) / _totalSteps;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: AppAnimations.pageSlideDuration,
          curve: Curves.easeOut,
          builder: (context, value, _) => HydraProgressIndicator(
            type: HydraProgressIndicatorType.linear,
            value: value,
            minHeight: 8,
            backgroundColor: AppColors.textSecondary.withValues(
              alpha: 0.12,
            ),
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _totalSteps,
      onPageChanged: (index) {
        setState(() => _currentStep = index);
      },
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double value = 0;
            if (_pageController.position.haveDimensions) {
              value = (_pageController.page ?? 0) - index;
            }

            return _buildPageTransition(
              child: child!,
              position: value,
            );
          },
          child: _buildStepContent(index),
        );
      },
    );
  }

  /// Builds slide transition animation for page changes
  Widget _buildPageTransition({
    required Widget child,
    required double position,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate slide offset (full screen width)
    final offset = Offset(position, 0);

    // Calculate opacity for fade effect
    // Fade out: 1.0 → 0.0 (when swiping away)
    // Fade in: 0.0 → 1.0 (when entering)
    double opacity;
    if (position.abs() <= 1.0) {
      // Within one page distance
      opacity = 1.0 - position.abs().clamp(0.0, 0.25) * 4;
    } else {
      opacity = 0.0;
    }

    return Transform.translate(
      offset: offset * screenWidth,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: child,
      ),
    );
  }

  /// Builds the content for each step
  Widget _buildStepContent(int step) {
    return _StepWrapper(
      child: switch (step) {
        0 => _buildNameAndStrengthStep(),
        1 => _buildDosageStep(),
        2 => _buildFrequencyStep(),
        3 => _buildReminderTimesStep(),
        _ => const SizedBox.shrink(),
      },
    );
  }

  // Step content builders
  Widget _buildNameAndStrengthStep() {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: HydraIcon(
            icon: AppIcons.medication,
            size: 72,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.whatMedicationToAdd,
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Medication Name Field with inline label
        HydraTextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: l10n.medicationNameHint,
            contentPadding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.md,
            ),
            prefixIconConstraints: const BoxConstraints(),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.sm,
              ),
              child: Text(
                'Name',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (value) {
            setState(() {
              _medicationName = value.trim();
              _hasUnsavedChanges = true;
            });
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        HydraTextFormField(
          controller: _strengthAmountController,
          decoration: InputDecoration(
            hintText: l10n.strengthAmountHint,
            contentPadding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.md,
            ),
            prefixIconConstraints: const BoxConstraints(),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.sm,
              ),
              child: Text(
                'Strenght',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            suffixIcon: _buildUnitSelector(context),
          ),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          onChanged: (value) {
            setState(() {
              _strengthAmount = value.trim();
              _hasUnsavedChanges = true;
            });
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'You can find the strength on the medication packaging',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),

        // Custom unit field (if "Other" selected)
        if (_strengthUnit == MedicationStrengthUnit.other) ...[
          const SizedBox(height: AppSpacing.md),
          HydraTextFormField(
            controller: _customStrengthUnitController,
            decoration: InputDecoration(
              labelText: l10n.customStrengthUnitLabel,
              hintText: l10n.customStrengthUnitHint,
              contentPadding: const EdgeInsets.all(AppSpacing.md),
            ),
            onChanged: (value) {
              setState(() {
                _customStrengthUnit = value.trim();
                _hasUnsavedChanges = true;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDosageStep() {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.setDosage,
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: AppSpacing.sm),

        RichText(
          text: TextSpan(
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            children: [
              TextSpan(text: l10n.dosageDescriptionPart1),
              TextSpan(
                text: l10n.dosageDescriptionPart2,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(text: l10n.dosageDescriptionPart3),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        HydraTextFormField(
          controller: _dosageController,
          decoration: InputDecoration(
            labelText: l10n.dosageLabel,
            hintText: l10n.dosageHint,
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            suffixIcon: _buildDosageUnitSelector(context),
          ),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          onChanged: (value) {
            setState(() {
              _dosage = value.trim();
              _hasUnsavedChanges = true;

              // Validate dosage
              final error = DosageUtils.validateDosageString(_dosage);
              if (error != null) {
                _dosageValue = null;
              } else {
                _dosageValue = DosageUtils.parseDosageString(_dosage);
              }
            });
          },
        ),

        // (Error text intentionally removed per request)
      ],
    );
  }

  Widget _buildFrequencyStep() {
    final l10n = context.l10n;
    const frequencies = TreatmentFrequency.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.setFrequency,
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.frequencyDescription,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Frequency selector
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: HydraList(
              padding: EdgeInsets.zero,
              items: frequencies.map((frequency) {
                final isSelected = frequency == _selectedFrequency;
                return HydraListItem(
                  title: Text(
                    frequency.displayName,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  isSelected: isSelected,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.lg,
                  ),
                  onTap: () {
                    final newFrequency = frequency;
                    setState(() {
                      _selectedFrequency = newFrequency;
                      _hasUnsavedChanges = true;
                      _reminderTimes =
                          AppDateUtils.generateDefaultReminderTimes(
                            newFrequency.administrationsPerDay,
                          );
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderTimesStep() {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.setReminderTimes,
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.reminderTimesDescription,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Time picker group
        TimePickerGroup(
          frequency: _selectedFrequency,
          initialTimes: _reminderTimes,
          onTimesChanged: (times) {
            setState(() {
              _reminderTimes = times;
              _hasUnsavedChanges = true;
            });
          },
        ),
      ],
    );
  }

  /// Builds the unit selector suffix widget for the strength field
  Widget _buildUnitSelector(BuildContext context) {
    return GestureDetector(
      onTap: () => _showUnitPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _strengthUnit.displayName,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.expand_more,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the unit picker bottom sheet
  Future<void> _showUnitPicker(BuildContext context) async {
    final l10n = context.l10n;

    final selectedUnit = await showHydraBottomSheet<MedicationStrengthUnit>(
      context: context,
      builder: (context) => HydraBottomSheet(
        heightFraction: 0.5,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: AppAccessibility.minTouchTarget),
                  Expanded(
                    child: Text(
                      l10n.strengthUnitLabel,
                      style: AppTextStyles.h2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TouchTargetIconButton(
                    icon: const HydraIcon(
                      icon: AppIcons.close,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    semanticLabel: l10n.close,
                  ),
                ],
              ),
            ),
            // Unit list
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                controller: _strengthUnitScrollController,
                child: ListView.builder(
                  controller: _strengthUnitScrollController,
                  itemCount: MedicationStrengthUnit.values.length,
                  itemBuilder: (context, index) {
                    final unit = MedicationStrengthUnit.values[index];
                    final isSelected = unit == _strengthUnit;

                    return ListTile(
                      title: Text(
                        unit.displayName,
                        style: AppTextStyles.body.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: AppColors.primary,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(unit),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedUnit != null && selectedUnit != _strengthUnit) {
      setState(() {
        _strengthUnit = selectedUnit;
        _hasUnsavedChanges = true;
      });
    }
  }

  /// Builds the dosage unit selector suffix widget
  Widget _buildDosageUnitSelector(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDosageUnitPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedUnit.displayName,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.expand_more,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the dosage unit picker bottom sheet
  Future<void> _showDosageUnitPicker(BuildContext context) async {
    final l10n = context.l10n;

    final selectedUnit = await showHydraBottomSheet<MedicationUnit>(
      context: context,
      builder: (context) => HydraBottomSheet(
        heightFraction: 0.5,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: AppAccessibility.minTouchTarget),
                  Expanded(
                    child: Text(
                      l10n.unitTypeLabel,
                      style: AppTextStyles.h2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TouchTargetIconButton(
                    icon: const HydraIcon(
                      icon: AppIcons.close,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    semanticLabel: l10n.close,
                  ),
                ],
              ),
            ),
            // Unit list
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                controller: _dosageUnitScrollController,
                child: ListView.builder(
                  controller: _dosageUnitScrollController,
                  itemCount: MedicationUnit.values.length,
                  itemBuilder: (context, index) {
                    final unit = MedicationUnit.values[index];
                    final isSelected = unit == _selectedUnit;

                    return ListTile(
                      title: Text(
                        unit.displayName,
                        style: AppTextStyles.body.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: AppColors.primary,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(unit),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedUnit != null && selectedUnit != _selectedUnit) {
      setState(() {
        _selectedUnit = selectedUnit;
        _hasUnsavedChanges = true;
      });
    }
  }

  // Validation methods
  String? _validateCurrentStep() {
    final l10n = context.l10n;

    return switch (_currentStep) {
      0 => _validateStepOne(l10n),
      1 => _validateStepTwo(l10n),
      2 => _validateStepThree(l10n),
      3 => _validateStepFour(l10n),
      _ => null,
    };
  }

  String? _validateStepOne(AppLocalizations l10n) {
    if (_medicationName.trim().isEmpty) {
      return l10n.medicationNameRequired;
    }

    // If "Other" unit selected, custom unit must be provided
    if (_strengthUnit == MedicationStrengthUnit.other &&
        _customStrengthUnit.trim().isEmpty) {
      return l10n.customStrengthUnitRequired;
    }

    return null;
  }

  String? _validateStepTwo(AppLocalizations l10n) {
    if (_dosage.trim().isEmpty) {
      return l10n.dosageRequired;
    }

    final error = DosageUtils.validateDosageString(_dosage);
    if (error != null) {
      return error;
    }

    return null;
  }

  String? _validateStepThree(AppLocalizations l10n) {
    // Frequency is always valid (pre-selected via picker)
    return null;
  }

  String? _validateStepFour(AppLocalizations l10n) {
    final expectedCount = _selectedFrequency.administrationsPerDay;
    if (_reminderTimes.length != expectedCount) {
      return l10n.reminderTimesIncomplete(expectedCount);
    }

    return null;
  }

  // Navigation methods
  Future<void> _goToNextStep() async {
    // Prevent double-tap
    if (_isAnimating) return;

    // Validate current step
    final error = _validateCurrentStep();
    if (error != null) {
      // Show error snackbar
      if (mounted) {
        HydraSnackBar.showError(context, error);
      }
      return;
    }

    setState(() => _isAnimating = true);

    try {
      await _pageController.animateToPage(
        _currentStep + 1,
        duration: AppAnimations.pageSlideDuration,
        curve: AppAnimations.pageSlideCurve,
      );
    } finally {
      if (mounted) {
        setState(() => _isAnimating = false);
      }
    }
  }

  Future<void> _goToPreviousStep() async {
    // Prevent double-tap
    if (_isAnimating) return;

    setState(() => _isAnimating = true);

    try {
      await _pageController.animateToPage(
        _currentStep - 1,
        duration: AppAnimations.pageSlideDuration,
        curve: AppAnimations.pageSlideCurve,
      );
    } finally {
      if (mounted) {
        setState(() => _isAnimating = false);
      }
    }
  }

  Future<void> _handleSave() async {
    if (_isAnimating || _isLoading) return;

    // Final validation
    final error = _validateCurrentStep();
    if (error != null) {
      if (mounted) {
        HydraSnackBar.showError(context, error);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convert TimeOfDay to DateTime
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

      // Return medication data
      if (mounted) {
        Navigator.of(context).pop(medication);
      }
    } on Exception catch (_) {
      if (mounted) {
        HydraSnackBar.showError(
          context,
          context.l10n.errorSavingMedication,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildFooter(BuildContext context) {
    final l10n = context.l10n;
    final isLastStep = _currentStep == _totalSteps - 1;
    final isNameMissing = _currentStep == 0 && _medicationName.trim().isEmpty;
    final isDosageMissing =
        _currentStep == 1 && (_dosage.trim().isEmpty || _dosageValue == null);
    final isNextDisabled =
        _isAnimating || _isLoading || isNameMissing || isDosageMissing;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Next/Save button
            Expanded(
              child: HydraButton(
                onPressed: isNextDisabled
                    ? null
                    : (isLastStep ? _handleSave : _goToNextStep),
                isLoading: _isLoading,
                isFullWidth: true,
                child: Text(isLastStep ? l10n.save : l10n.next),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper widget for consistent step styling and scrolling
class _StepWrapper extends StatelessWidget {
  const _StepWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: child,
    );
  }
}
