import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/core/utils/number_input_utils.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Bottom sheet for editing fluid schedule volume per session
class VolumeEditBottomSheet extends StatefulWidget {
  /// Creates a [VolumeEditBottomSheet]
  const VolumeEditBottomSheet({
    this.initialValue,
    super.key,
  });

  /// Initial volume value in mL (null if not set)
  final double? initialValue;

  @override
  State<VolumeEditBottomSheet> createState() => _VolumeEditBottomSheetState();
}

class _VolumeEditBottomSheetState extends State<VolumeEditBottomSheet> {
  late final TextEditingController _volumeController;
  String? _errorMessage;

  String _formatVolume(double? value) {
    if (value == null) return '';
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  void initState() {
    super.initState();
    _volumeController = TextEditingController(
      text: _formatVolume(widget.initialValue),
    );
  }

  @override
  void dispose() {
    _volumeController.dispose();
    super.dispose();
  }

  bool _validate() {
    final text = _volumeController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Volume is required';
      });
      return false;
    }

    final value = double.tryParse(text);
    if (value == null || value <= 0) {
      setState(() {
        _errorMessage = 'Volume must be greater than 0';
      });
      return false;
    }

    setState(() {
      _errorMessage = null;
    });
    return true;
  }

  void _save() {
    if (!_validate()) return;

    final value = double.parse(_volumeController.text.trim());
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final isCupertino = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return LoggingPopupWrapper(
      title: 'Edit Volume',
      leading: HydraBackButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      trailing: TextButton(
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
      ),
      showCloseButton: false,
      onDismiss: () {
        // No special cleanup needed
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          HydraTextField(
            controller: _volumeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },
            onSubmitted: (_) => _save(),
            inputFormatters: NumberInputUtils.getDecimalFormatters(),
            decoration: InputDecoration(
              labelText: 'Volume per session',
              hintText: '200',
              suffixIcon: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: AppSpacing.md,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    widthFactor: 1,
                    child: Text(
                      'mL',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
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
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
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
            ),
          ],
        ],
      ),
    );
  }
}
