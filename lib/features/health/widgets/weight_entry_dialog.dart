import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_animations.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/core/utils/weight_utils.dart';
import 'package:hydracat/features/health/models/health_parameter.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/providers/weight_unit_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';
import 'package:intl/intl.dart';

/// Dialog for adding or editing weight entries
///
/// Supports:
/// - Add mode (existingEntry == null)
/// - Edit mode (existingEntry != null)
/// - Date selection (backdate allowed, future dates blocked)
/// - Weight input with unit conversion (kg/lbs)
/// - Optional notes field (max 500 chars, expands when used)
/// - Validation using ProfileValidationService
class WeightEntryDialog extends ConsumerStatefulWidget {
  /// Creates a [WeightEntryDialog]
  const WeightEntryDialog({
    this.existingEntry,
    super.key,
  });

  /// Existing entry for edit mode (null for add mode)
  final HealthParameter? existingEntry;

  @override
  ConsumerState<WeightEntryDialog> createState() => _WeightEntryDialogState();
}

class _WeightEntryDialogState extends ConsumerState<WeightEntryDialog> {
  late final TextEditingController _weightController;
  late final TextEditingController _notesController;
  late final FocusNode _notesFocusNode;

  late DateTime _selectedDate;
  String? _errorMessage;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.existingEntry?.date ?? DateTime.now();
    _notesFocusNode = FocusNode();

    // Initialize with empty text, will be set in didChangeDependencies
    _weightController = TextEditingController();

    _notesController = TextEditingController(
      text: widget.existingEntry?.notes ?? '',
    );

    _notesFocusNode.addListener(() {
      setState(() {}); // Rebuild to show/hide counter
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize weight controller on first build when ref is available
    if (!_isInitialized) {
      final currentUnit = ref.read(weightUnitProvider);
      final existingWeight = widget.existingEntry?.weight;
      final displayWeight = existingWeight != null
          ? (currentUnit == 'kg'
                ? existingWeight
                : WeightUtils.convertKgToLbs(existingWeight))
          : null;

      _weightController.text = displayWeight != null
          ? displayWeight.toStringAsFixed(2)
          : '';

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  /// Validates and returns weight in kg (or null if invalid)
  double? _getValidatedWeightKg() {
    final text = _weightController.text.trim().replaceAll(',', '.');
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a weight';
      });
      return null;
    }

    final value = double.tryParse(text);
    if (value == null) {
      setState(() {
        _errorMessage = 'Please enter a valid number';
      });
      return null;
    }

    final currentUnit = ref.read(weightUnitProvider);
    final weightKg = currentUnit == 'kg'
        ? value
        : WeightUtils.convertLbsToKg(value);

    // Validate range (0.5-15kg)
    if (weightKg < 0.5 || weightKg > 15) {
      setState(() {
        _errorMessage = 'Weight must be between 0.5 and 15 kg (1.1 - 33 lbs)';
      });
      return null;
    }

    return weightKg;
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

  /// Platform-adaptive header action for saving.
  Widget _buildHeaderAction() {
    final isCupertino =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final label = widget.existingEntry != null ? 'Save' : 'Add';

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

  void _save() {
    final weightKg = _getValidatedWeightKg();
    if (weightKg == null) return;

    final notes = _notesController.text.trim();
    if (notes.length > 500) {
      setState(() {
        _errorMessage = 'Notes must be 500 characters or less';
      });
      return;
    }

    // Return result
    Navigator.of(context).pop({
      'date': _selectedDate,
      'weightKg': weightKg,
      'notes': notes.isEmpty ? null : notes,
    });
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

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingEntry != null;
    final currentUnit = ref.watch(weightUnitProvider);
    final theme = Theme.of(context);

    return LoggingPopupWrapper(
      title: isEditMode ? 'Edit Weight' : 'Add Weight',
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
          const SizedBox(height: AppSpacing.xs),

          // Weight input
          HydraTextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            textInputAction: TextInputAction.next,
            autofocus: !isEditMode,
            decoration: InputDecoration(
              labelText: 'Weight',
              hintText: currentUnit == 'kg' ? 'e.g., 4.2' : 'e.g., 9.3',
              suffixIcon: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.only(
                    right: AppSpacing.md,
                  ),
                  alignment: Alignment.centerRight,
                  width: 40,
                  child: Text(
                    currentUnit,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                // The library directive may trigger
                // deprecated_member_use warnings
                // in some Dart versions.
                // ignore: deprecated_member_use
                RegExp(r'^\d*[.,]?\d{0,2}'),
              ),
            ],
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Notes field
          HydraTextField(
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
              setState(() {}); // Update counter and line count
            },
          ),

          // Error message
          _buildErrorMessage(),
        ],
      ),
    );
  }
}
