import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/core/utils/number_input_utils.dart';

/// Sentinel value for [LabValueData.copyWith] to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

/// Model for lab value input data
class LabValueData {
  /// Creates a [LabValueData]
  const LabValueData({
    this.creatinine,
    this.bun,
    this.sdma,
    this.bloodworkDate,
  });

  /// Creatinine level in mg/dL
  final double? creatinine;

  /// Blood Urea Nitrogen (BUN) level in mg/dL
  final double? bun;

  /// Symmetric Dimethylarginine (SDMA) level in μg/dL
  final double? sdma;

  /// Date when bloodwork was performed
  final DateTime? bloodworkDate;

  /// Creates a copy with updated values
  LabValueData copyWith({
    Object? creatinine = _undefined,
    Object? bun = _undefined,
    Object? sdma = _undefined,
    Object? bloodworkDate = _undefined,
  }) {
    return LabValueData(
      creatinine: creatinine == _undefined 
          ? this.creatinine 
          : creatinine as double?,
      bun: bun == _undefined ? this.bun : bun as double?,
      sdma: sdma == _undefined ? this.sdma : sdma as double?,
      bloodworkDate: bloodworkDate == _undefined 
          ? this.bloodworkDate 
          : bloodworkDate as DateTime?,
    );
  }

  /// Whether any lab values are present
  bool get hasValues => creatinine != null || bun != null || sdma != null;
}

/// Widget for inputting laboratory values with decimal validation
class LabValuesInput extends StatefulWidget {
  /// Creates a [LabValuesInput]
  const LabValuesInput({
    required this.labValues,
    required this.onValuesChanged,
    super.key,
    this.creatinineError,
    this.bunError,
    this.sdmaError,
    this.bloodworkDateError,
  });

  /// Current lab values
  final LabValueData labValues;

  /// Callback when lab values change
  final ValueChanged<LabValueData> onValuesChanged;

  /// Error text for creatinine field
  final String? creatinineError;

  /// Error text for BUN field
  final String? bunError;

  /// Error text for SDMA field
  final String? sdmaError;

  /// Error text for bloodwork date field
  final String? bloodworkDateError;

  @override
  State<LabValuesInput> createState() => _LabValuesInputState();
}

class _LabValuesInputState extends State<LabValuesInput> {
  final _creatinineController = TextEditingController();
  final _bunController = TextEditingController();
  final _sdmaController = TextEditingController();

  // Flag to prevent controller updates during user input
  bool _isUserTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(LabValuesInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controllers if values changed from external source
    // (not during user input)
    if (oldWidget.labValues != widget.labValues && !_isUserTyping) {
      _updateControllers();
    }
  }

  @override
  void dispose() {
    _creatinineController.dispose();
    _bunController.dispose();
    _sdmaController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _creatinineController.text = NumberInputUtils.formatForInput(
      widget.labValues.creatinine,
    );
    _bunController.text = NumberInputUtils.formatForInput(
      widget.labValues.bun,
    );
    _sdmaController.text = NumberInputUtils.formatForInput(
      widget.labValues.sdma,
    );
  }

  void _updateControllers() {
    final creatinineText = NumberInputUtils.formatForInput(
      widget.labValues.creatinine,
    );
    final bunText = NumberInputUtils.formatForInput(widget.labValues.bun);
    final sdmaText = NumberInputUtils.formatForInput(widget.labValues.sdma);

    if (_creatinineController.text != creatinineText) {
      _creatinineController.text = creatinineText;
    }
    if (_bunController.text != bunText) {
      _bunController.text = bunText;
    }
    if (_sdmaController.text != sdmaText) {
      _sdmaController.text = sdmaText;
    }
  }

  void _onCreatinineChanged(String value) {
    _isUserTyping = true;
    final parsedValue = NumberInputUtils.parseDecimal(value);
    widget.onValuesChanged(
      widget.labValues.copyWith(creatinine: parsedValue),
    );
    // Reset typing flag after a brief delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _isUserTyping = false;
      }
    });
  }

  void _onBunChanged(String value) {
    _isUserTyping = true;
    final parsedValue = NumberInputUtils.parseDecimal(value);
    widget.onValuesChanged(widget.labValues.copyWith(bun: parsedValue));
    // Reset typing flag after a brief delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _isUserTyping = false;
      }
    });
  }

  void _onSdmaChanged(String value) {
    _isUserTyping = true;
    final parsedValue = NumberInputUtils.parseDecimal(value);
    widget.onValuesChanged(widget.labValues.copyWith(sdma: parsedValue));
    // Reset typing flag after a brief delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _isUserTyping = false;
      }
    });
  }

  /// Select bloodwork date
  Future<void> _selectBloodworkDate() async {
    final currentDate = widget.labValues.bloodworkDate ?? DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      widget.onValuesChanged(
        widget.labValues.copyWith(bloodworkDate: selectedDate),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bloodwork Date
        _buildSectionTitle('Bloodwork Date'),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: _selectBloodworkDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.bloodworkDateError != null
                    ? AppColors.error
                    : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: widget.labValues.bloodworkDate != null
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  widget.labValues.bloodworkDate != null
                      ? _formatDate(widget.labValues.bloodworkDate!)
                      : 'Select bloodwork date',
                  style: AppTextStyles.body.copyWith(
                    color: widget.labValues.bloodworkDate != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.bloodworkDateError != null)
          _buildErrorText(widget.bloodworkDateError!),

        const SizedBox(height: AppSpacing.lg),

        // Lab Values Section
        _buildSectionTitle('Lab Values'),
        const SizedBox(height: AppSpacing.sm),
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
          unit: 'mg/dL',
          hintText: '0.00',
          onChanged: _onCreatinineChanged,
          errorText: widget.creatinineError,
        ),

        const SizedBox(height: AppSpacing.md),

        // BUN
        _buildLabValueField(
          controller: _bunController,
          label: 'BUN (Blood Urea Nitrogen)',
          unit: 'mg/dL',
          hintText: '0.00',
          onChanged: _onBunChanged,
          errorText: widget.bunError,
        ),

        const SizedBox(height: AppSpacing.md),

        // SDMA
        _buildLabValueField(
          controller: _sdmaController,
          label: 'SDMA',
          unit: 'μg/dL',
          hintText: '0.00',
          onChanged: _onSdmaChanged,
          errorText: widget.sdmaError,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.h3.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildLabValueField({
    required TextEditingController controller,
    required String label,
    required String unit,
    required String hintText,
    required ValueChanged<String> onChanged,
    String? errorText,
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
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          inputFormatters: NumberInputUtils.getDecimalFormatters(),
          decoration: InputDecoration(
            hintText: hintText,
            suffixText: unit,
            suffixStyle: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
          onChanged: onChanged,
        ),
        if (errorText != null) _buildErrorText(errorText),
      ],
    );
  }

  Widget _buildErrorText(String errorText) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        errorText,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.error,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
