import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/features/profile/models/schedule.dart';

/// A text field for entering medication dosage with validation.
///
/// Displays the medication name, allows decimal input, and shows
/// inline validation errors. Pre-filled with the scheduled target dosage.
class MedicationDosageInput extends StatefulWidget {
  /// Creates a [MedicationDosageInput].
  const MedicationDosageInput({
    required this.medication,
    required this.initialDosage,
    required this.onDosageChanged,
    this.errorText,
    super.key,
  });

  /// The medication schedule this input is for
  final Schedule medication;

  /// Initial dosage value (typically from schedule.targetDosage)
  final double initialDosage;

  /// Callback when dosage value changes
  final ValueChanged<double?> onDosageChanged;

  /// Error message to display (null if no error)
  final String? errorText;

  @override
  State<MedicationDosageInput> createState() => _MedicationDosageInputState();
}

class _MedicationDosageInputState extends State<MedicationDosageInput> {
  late final TextEditingController _controller;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _formatDosageForInput(widget.initialDosage),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Format dosage for input field (remove trailing zeros)
  String _formatDosageForInput(double dosage) {
    return dosage.toStringAsFixed(2).replaceAll(RegExp(r'\.?0*$'), '');
  }

  /// Get short form of medication unit for display
  String _getShortUnit() {
    final unit = widget.medication.medicationUnit;
    if (unit == null) return '';

    return switch (unit) {
      'pills' => 'pill',
      'capsules' => 'capsule',
      'drops' => 'drop',
      'injections' => 'injection',
      'micrograms' => 'mcg',
      'milligrams' => 'mg',
      'milliliters' => 'ml',
      'portions' => 'portion',
      'sachets' => 'sachet',
      'ampoules' => 'ampoule',
      'tablespoon' => 'tbsp',
      'teaspoon' => 'tsp',
      _ => unit,
    };
  }

  void _onTextChanged(String text) {
    if (text.isEmpty) {
      setState(() => _localError = 'Dosage is required');
      widget.onDosageChanged(null);
      return;
    }

    final dosage = double.tryParse(text);

    if (dosage == null) {
      setState(() => _localError = 'Please enter a valid number');
      widget.onDosageChanged(null);
      return;
    }

    if (dosage <= 0) {
      setState(() => _localError = 'Dosage must be greater than 0');
      widget.onDosageChanged(null);
      return;
    }

    if (dosage > 100) {
      setState(
        () => _localError = 'Dosage seems unrealistically high (over 100)',
      );
      widget.onDosageChanged(null);
      return;
    }

    // Valid dosage
    setState(() => _localError = null);
    widget.onDosageChanged(dosage);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveError = widget.errorText ?? _localError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Medication name label
        Text(
          '${widget.medication.medicationName}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Dosage input field
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            // Allow numbers and decimal point only
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          onChanged: _onTextChanged,
          decoration: InputDecoration(
            labelText: 'Dosage',
            hintText: 'Enter dosage',
            suffixText: _getShortUnit(),
            errorText: effectiveError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}
