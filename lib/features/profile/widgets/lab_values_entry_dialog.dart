import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_animations.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/constants/lab_reference_ranges.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/core/utils/number_input_utils.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/features/profile/models/lab_result.dart';
import 'package:hydracat/shared/widgets/widgets.dart';
import 'package:intl/intl.dart';

/// Dialog for adding or editing lab values
///
/// Supports:
/// - Add mode (existingResult == null) - opens with today's date, empty values
/// - Edit mode (existingResult != null) - opens pre-filled with existing values
/// - Unit system toggle (US/SI) for Creatinine and BUN
/// - Date selection (backdate allowed up to 3 years, future dates blocked)
/// - Lab value inputs (Creatinine, BUN, SDMA) with unit-aware labels
/// - Optional vet notes field (max 500 chars, expands when focused)
/// - Validation: date required, at least one value required
class LabValuesEntryDialog extends ConsumerStatefulWidget {
  /// Creates a [LabValuesEntryDialog]
  const LabValuesEntryDialog({
    this.existingResult,
    super.key,
  });

  /// Existing lab result for edit mode (null for add mode)
  final LabResult? existingResult;

  @override
  ConsumerState<LabValuesEntryDialog> createState() =>
      _LabValuesEntryDialogState();
}

class _LabValuesEntryDialogState extends ConsumerState<LabValuesEntryDialog> {
  late final TextEditingController _creatinineController;
  late final TextEditingController _bunController;
  late final TextEditingController _sdmaController;
  late final TextEditingController _vetNotesController;
  late final FocusNode _notesFocusNode;

  late DateTime _selectedDate;
  String _unitSystem = 'us'; // 'us' or 'si'
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.existingResult?.testDate ?? DateTime.now();
    _notesFocusNode = FocusNode();

    // Initialize controllers
    _creatinineController = TextEditingController();
    _bunController = TextEditingController();
    _sdmaController = TextEditingController();
    _vetNotesController = TextEditingController();

    // Pre-fill if editing
    if (widget.existingResult != null) {
      final result = widget.existingResult!;

      // Pre-fill creatinine
      if (result.creatinine != null) {
        _creatinineController.text = result.creatinine!.value.toString();
        // Detect unit system from stored unit
        if (result.creatinine!.unit == 'µmol/L') {
          _unitSystem = 'si';
        }
      }

      // Pre-fill BUN
      if (result.bun != null) {
        _bunController.text = result.bun!.value.toString();
      }

      // Pre-fill SDMA
      if (result.sdma != null) {
        _sdmaController.text = result.sdma!.value.toString();
      }

      // Pre-fill vet notes
      if (result.metadata?.vetNotes != null) {
        _vetNotesController.text = result.metadata!.vetNotes!;
      }
    }

    _notesFocusNode.addListener(() {
      setState(() {}); // Rebuild to show/hide counter
    });
  }

  @override
  void dispose() {
    _creatinineController.dispose();
    _bunController.dispose();
    _sdmaController.dispose();
    _vetNotesController.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  /// Validates the form and returns lab values data (or null if invalid)
  Map<String, dynamic>? _validateAndGetData() {
    // Validate date
    if (_selectedDate.isAfter(DateTime.now())) {
      setState(() {
        _errorMessage = 'Bloodwork date cannot be in the future';
      });
      return null;
    }

    // Parse values
    final creatinineText = _creatinineController.text.trim();
    final bunText = _bunController.text.trim();
    final sdmaText = _sdmaController.text.trim();

    final creatinine = creatinineText.isNotEmpty
        ? double.tryParse(creatinineText.replaceAll(',', '.'))
        : null;
    final bun = bunText.isNotEmpty
        ? double.tryParse(bunText.replaceAll(',', '.'))
        : null;
    final sdma = sdmaText.isNotEmpty
        ? double.tryParse(sdmaText.replaceAll(',', '.'))
        : null;

    // Validate at least one value
    if (creatinine == null && bun == null && sdma == null) {
      setState(() {
        _errorMessage = 'Please enter at least one lab value';
      });
      return null;
    }

    // Validate positive values
    if (creatinine != null && creatinine <= 0) {
      setState(() {
        _errorMessage = 'Creatinine must be greater than 0';
      });
      return null;
    }
    if (bun != null && bun <= 0) {
      setState(() {
        _errorMessage = 'BUN must be greater than 0';
      });
      return null;
    }
    if (sdma != null && sdma <= 0) {
      setState(() {
        _errorMessage = 'SDMA must be greater than 0';
      });
      return null;
    }

    // Validate vet notes length
    final vetNotes = _vetNotesController.text.trim();
    if (vetNotes.length > 500) {
      setState(() {
        _errorMessage = 'Vet notes must be 500 characters or less';
      });
      return null;
    }

    // Get units based on unit system
    final creatinineUnit = getDefaultUnit('creatinine', _unitSystem);
    final bunUnit = getDefaultUnit('bun', _unitSystem);
    final sdmaUnit = getDefaultUnit('sdma', _unitSystem);

    return {
      'testDate': _selectedDate,
      'creatinine': creatinine,
      'creatinineUnit': creatinineUnit,
      'bun': bun,
      'bunUnit': bunUnit,
      'sdma': sdma,
      'sdmaUnit': sdmaUnit,
      'vetNotes': vetNotes.isEmpty ? null : vetNotes,
      'unitSystem': _unitSystem,
    };
  }

  Future<void> _selectDate() async {
    final picked = await HydraDatePicker.show(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
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

  Widget _buildHeaderDateSelector() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: _buildDateSelector(),
      ),
    );
  }

  Widget _buildHeaderAction() {
    final isCupertino =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return TextButton(
      onPressed: _save,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Save',
        style: AppTextStyles.buttonPrimary.copyWith(
          fontWeight: isCupertino ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  void _save() {
    final data = _validateAndGetData();
    if (data == null) return;

    Navigator.of(context).pop(data);
  }

  Widget _buildUnitSystemToggle() {
    return Row(
      children: [
        Text(
          'Unit System:',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: HydraSlidingSegmentedControl<String>(
            value: _unitSystem,
            segments: const {
              'us': Text('US Units'),
              'si': Text('SI Units'),
            },
            onChanged: (newSystem) {
              setState(() {
                _unitSystem = newSystem;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLabValueField({
    required TextEditingController controller,
    required String label,
    required String unit,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: ' ($unit)',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        HydraTextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.only(
                  right: AppSpacing.md,
                ),
                alignment: Alignment.centerRight,
                width: 60,
                child: Text(
                  unit,
                  style: Theme.of(context).textTheme.bodyMedium,
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
          inputFormatters: NumberInputUtils.getDecimalFormatters(),
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() {
                _errorMessage = null;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
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
              _errorMessage!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingResult != null;

    // Get units based on current unit system
    final creatinineUnit = getDefaultUnit('creatinine', _unitSystem);
    final bunUnit = getDefaultUnit('bun', _unitSystem);
    final sdmaUnit = getDefaultUnit('sdma', _unitSystem);

    return LoggingPopupWrapper(
      title: isEditMode ? 'Edit Lab Values' : 'Add Lab Values',
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
          const SizedBox(height: AppSpacing.sm),

          // Unit system toggle
          _buildUnitSystemToggle(),

          const SizedBox(height: AppSpacing.md),

          // Info text
          Text(
            'Enter any values you have available. All fields are optional.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Creatinine
          _buildLabValueField(
            controller: _creatinineController,
            label: 'Creatinine',
            unit: creatinineUnit,
            hintText: '0.00',
          ),

          const SizedBox(height: AppSpacing.md),

          // BUN
          _buildLabValueField(
            controller: _bunController,
            label: 'BUN (Blood Urea Nitrogen)',
            unit: bunUnit,
            hintText: '0.00',
          ),

          const SizedBox(height: AppSpacing.md),

          // SDMA
          _buildLabValueField(
            controller: _sdmaController,
            label: 'SDMA',
            unit: sdmaUnit,
            hintText: '0.00',
          ),

          const SizedBox(height: AppSpacing.md),

          // Vet notes
          Text(
            'Veterinarian Notes (Optional)',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          HydraTextField(
            controller: _vetNotesController,
            focusNode: _notesFocusNode,
            maxLength: 500,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'e.g., "Vet recommends monitoring hydration levels"',
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
                child: Text('${_vetNotesController.text.length}/500'),
              ),
            ),
            minLines: _vetNotesController.text.isNotEmpty ? 3 : 1,
            maxLines: 5,
            onChanged: (_) {
              setState(() {}); // Update counter and line count
            },
          ),

          const SizedBox(height: AppSpacing.sm),

          // Error message
          _buildErrorMessage(),
        ],
      ),
    );
  }
}
