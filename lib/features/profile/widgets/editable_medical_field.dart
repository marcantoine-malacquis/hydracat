import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/shared/widgets/icons/hydra_icon.dart';

/// A reusable widget for displaying and editing medical information fields
/// Provides consistent styling and behavior across all medical data editing
class EditableMedicalField extends StatelessWidget {
  /// Creates an [EditableMedicalField]
  const EditableMedicalField({
    required this.label,
    required this.value,
    required this.onEdit,
    super.key,
    this.icon,
    this.isEmpty = false,
  });

  /// The field label (e.g., "IRIS Stage", "Creatinine")
  final String label;

  /// The current value to display (or "No information" if empty)
  final String value;

  /// Whether this field has no information
  final bool isEmpty;

  /// Optional icon name for the field (from AppIcons)
  final String? icon;

  /// Callback when the edit button is pressed
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Leading icon (optional)
          if (icon != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isEmpty
                    ? AppColors.textTertiary.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: HydraIcon(
                  icon: icon!,
                  size: 16,
                  color: isEmpty ? AppColors.textTertiary : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],

          // Field content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    color: isEmpty
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),

          // Edit button
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              onPressed: onEdit,
              icon: const HydraIcon(
                icon: AppIcons.edit,
                size: 16,
                color: AppColors.primary,
              ),
              tooltip: 'Edit $label',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A specialized editable field for date values
class EditableDateField extends StatelessWidget {
  /// Creates an [EditableDateField]
  const EditableDateField({
    required this.label,
    required this.date,
    required this.onEdit,
    super.key,
    this.icon,
  });

  /// The field label
  final String label;

  /// The current date value (null if empty)
  final DateTime? date;

  /// Optional icon name for the field (from AppIcons)
  final String? icon;

  /// Callback when the edit button is pressed
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isEmpty = date == null;
    final displayValue = isEmpty
        ? 'No information'
        : '${date!.day}/${date!.month}/${date!.year}';

    return EditableMedicalField(
      label: label,
      value: displayValue,
      isEmpty: isEmpty,
      icon: icon,
      onEdit: onEdit,
    );
  }
}

/// A specialized editable field for lab values with units
class EditableLabValueField extends StatelessWidget {
  /// Creates an [EditableLabValueField]
  const EditableLabValueField({
    required this.label,
    required this.value,
    required this.unit,
    required this.onEdit,
    super.key,
    this.icon,
  });

  /// The field label
  final String label;

  /// The numeric value (null if empty)
  final double? value;

  /// The unit of measurement
  final String unit;

  /// Optional icon name for the field (from AppIcons)
  final String? icon;

  /// Callback when the edit button is pressed
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == null;
    final displayValue = isEmpty
        ? 'No information'
        : '${value!.toStringAsFixed(1)} $unit';

    return EditableMedicalField(
      label: label,
      value: displayValue,
      isEmpty: isEmpty,
      icon: icon,
      onEdit: onEdit,
    );
  }
}
