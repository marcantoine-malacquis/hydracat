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
import 'package:hydracat/features/profile/models/medical_info.dart';
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
/// - Delete button (edit mode only) with confirmation dialog
class LabValuesEntryDialog extends ConsumerStatefulWidget {
  /// Creates a [LabValuesEntryDialog]
  const LabValuesEntryDialog({
    this.existingResult,
    this.showBackButton = false,
    this.onDelete,
    super.key,
  });

  /// Existing lab result for edit mode (null for add mode)
  final LabResult? existingResult;

  /// Whether to show a back button in the header
  final bool showBackButton;

  /// Callback when the delete button is pressed (edit mode only)
  final VoidCallback? onDelete;

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
  IrisStage? _selectedIrisStage;
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

      // Pre-fill IRIS stage
      _selectedIrisStage = result.metadata?.irisStage;
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
      'irisStage': _selectedIrisStage,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              DateFormat('MMM dd, yyyy').format(_selectedDate),
              style: AppTextStyles.body,
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderDateSelector() {
    return Align(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
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

  Widget _buildIrisStageSelector() {
    final selectedSegment = _segmentFromStage(_selectedIrisStage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IRIS Stage',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: HydraSlidingSegmentedControl<_IrisStageSegment>(
            value: selectedSegment,
            onChanged: (segment) {
              setState(() {
                _selectedIrisStage = _stageFromSegment(segment);
              });
            },
            segments: const {
              _IrisStageSegment.stage1: Text('1'),
              _IrisStageSegment.stage2: Text('2'),
              _IrisStageSegment.stage3: Text('3'),
              _IrisStageSegment.stage4: Text('4'),
              _IrisStageSegment.unknown: Text('N/A'),
            },
          ),
        ),
      ],
    );
  }

  _IrisStageSegment _segmentFromStage(IrisStage? stage) {
    return switch (stage) {
      IrisStage.stage1 => _IrisStageSegment.stage1,
      IrisStage.stage2 => _IrisStageSegment.stage2,
      IrisStage.stage3 => _IrisStageSegment.stage3,
      IrisStage.stage4 => _IrisStageSegment.stage4,
      null => _IrisStageSegment.unknown,
    };
  }

  IrisStage? _stageFromSegment(_IrisStageSegment segment) {
    return switch (segment) {
      _IrisStageSegment.stage1 => IrisStage.stage1,
      _IrisStageSegment.stage2 => IrisStage.stage2,
      _IrisStageSegment.stage3 => IrisStage.stage3,
      _IrisStageSegment.stage4 => IrisStage.stage4,
      _IrisStageSegment.unknown => null,
    };
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
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
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
              child: Padding(
                padding: const EdgeInsets.only(
                  right: AppSpacing.md,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: 1,
                  child: Text(
                    unit,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.right,
                  ),
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

  /// Show confirmation dialog before deleting
  Future<bool?> _showDeleteConfirmation() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => HydraAlertDialog(
        title: const Text('Delete Lab Result?'),
        content: Text(
          'This will permanently delete the lab result from '
          '${_formatDate(_selectedDate)}. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Handle delete button press
  Future<void> _handleDelete() async {
    final confirmed = await _showDeleteConfirmation();
    if (confirmed ?? false) {
      widget.onDelete?.call();
      if (mounted) {
        Navigator.of(context).pop(); // Close the edit dialog
      }
    }
  }

  /// Format date as "MMM d, yyyy" (e.g., "Jan 15, 2024")
  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
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
      leading: widget.showBackButton
          ? HydraBackButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          : null,
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

          // IRIS Stage selector
          _buildIrisStageSelector(),

          const SizedBox(height: AppSpacing.md),

          // Unit system toggle
          _buildUnitSystemToggle(),

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
            'Veterinarian Notes',
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
              hintText: 'e.g., "Checkup in 6 months"',
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
            minLines: 1,
            onChanged: (_) {
              setState(() {}); // Update counter
            },
          ),

          const SizedBox(height: AppSpacing.sm),

          // Error message
          _buildErrorMessage(),

          // Delete button (only in edit mode)
          if (isEditMode && widget.onDelete != null) ...[
            const SizedBox(height: AppSpacing.lg),
            HydraButton(
              onPressed: _handleDelete,
              variant: HydraButtonVariant.secondary,
              borderColor: AppColors.error,
              isFullWidth: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Delete Lab Result',
                    style: AppTextStyles.buttonPrimary.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Internal enum for IRIS stage segmented control
enum _IrisStageSegment {
  stage1,
  stage2,
  stage3,
  stage4,
  unknown,
}
