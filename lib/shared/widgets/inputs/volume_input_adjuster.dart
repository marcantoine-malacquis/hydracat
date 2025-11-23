import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// A reusable volume input widget with increment/decrement buttons.
///
/// Displays a centered text field with circular +/- buttons on either side
/// for adjusting numeric values (typically volume in ml).
///
/// Features:
/// - Circular increment/decrement buttons
/// - Direct text input via centered TextField
/// - Configurable min/max range and increment step
/// - Visual feedback for enabled/disabled states
/// - Automatic value clamping within valid range
class VolumeInputAdjuster extends StatefulWidget {
  /// Creates a volume input adjuster widget.
  const VolumeInputAdjuster({
    required this.initialValue,
    required this.onChanged,
    this.minValue = 0,
    this.maxValue = 500,
    this.incrementStep = 10,
    this.unit = 'ml',
    this.fontSize = 40,
    super.key,
  });

  /// The initial value to display
  final double initialValue;

  /// Callback when the value changes
  final ValueChanged<double> onChanged;

  /// Minimum allowed value (default: 0)
  final double minValue;

  /// Maximum allowed value (default: 500)
  final double maxValue;

  /// Amount to increment/decrement on button press (default: 10)
  final double incrementStep;

  /// Unit label displayed below the value (default: 'ml')
  final String unit;

  /// Font size for the value display (default: 40)
  final double fontSize;

  @override
  State<VolumeInputAdjuster> createState() => _VolumeInputAdjusterState();
}

class _VolumeInputAdjusterState extends State<VolumeInputAdjuster> {
  late double _currentValue;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue.clamp(widget.minValue, widget.maxValue);

    // Initialize controller with formatted value
    final initialText = _formatValue(_currentValue);
    _controller = TextEditingController(text: initialText);

    // Sync controller changes back to state
    _controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(VolumeInputAdjuster oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update internal state when parent changes initialValue
    if (oldWidget.initialValue != widget.initialValue) {
      final newValue =
          widget.initialValue.clamp(widget.minValue, widget.maxValue);
      setState(() {
        _currentValue = newValue;
        _controller.text = _formatValue(newValue);
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Formats a value for display (removes unnecessary decimals)
  String _formatValue(double value) {
    return value == value.toInt()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  /// Handles text field changes
  void _handleControllerChange() {
    final text = _controller.text;
    if (text.isEmpty) {
      _updateValue(widget.minValue);
      return;
    }

    final value = double.tryParse(text);
    if (value != null) {
      _updateValue(value.clamp(widget.minValue, widget.maxValue));
    }
  }

  /// Updates the current value and notifies parent
  void _updateValue(double newValue) {
    if (_currentValue != newValue) {
      setState(() {
        _currentValue = newValue;
      });
      widget.onChanged(newValue);
    }
  }

  /// Increments the value by the configured step
  void _incrementValue() {
    if (_currentValue < widget.maxValue) {
      final newValue = (_currentValue + widget.incrementStep)
          .clamp(widget.minValue, widget.maxValue);
      setState(() {
        _currentValue = newValue;
        _controller.text = _formatValue(newValue);
      });
      widget.onChanged(newValue);
    }
  }

  /// Decrements the value by the configured step
  void _decrementValue() {
    if (_currentValue > widget.minValue) {
      final newValue = (_currentValue - widget.incrementStep)
          .clamp(widget.minValue, widget.maxValue);
      setState(() {
        _currentValue = newValue;
        _controller.text = _formatValue(newValue);
      });
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCircularButton(
            icon: Icons.remove,
            onPressed: _decrementValue,
            enabled: _currentValue > widget.minValue,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              children: [
                HydraTextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.display.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: widget.fontSize,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.unit,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          _buildCircularButton(
            icon: Icons.add,
            onPressed: _incrementValue,
            enabled: _currentValue < widget.maxValue,
          ),
        ],
      ),
    );
  }

  /// Builds a circular button for increment/decrement
  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool enabled,
  }) {
    return Material(
      color: enabled
          ? AppColors.primaryLight.withValues(alpha: 0.3)
          : AppColors.disabled,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: enabled ? AppColors.primaryDark : AppColors.textTertiary,
            size: 24,
          ),
        ),
      ),
    );
  }
}
