import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/utils/dosage_text_utils.dart';
import 'package:hydracat/features/profile/models/schedule.dart';

/// A selectable card displaying medication name, strength, and dosage.
///
/// Used in the medication logging popup to allow users to select which
/// medications they want to log. Provides visual feedback for selection
/// state with animated border and background changes.
///
/// Design follows a single-line horizontal layout:
/// - Left: Icon + Medication name + Strength (e.g., "Dede, 2 mg")
/// - Right: Dosage (e.g., "1 pill")
class MedicationSelectionCard extends StatelessWidget {
  /// Creates a [MedicationSelectionCard].
  const MedicationSelectionCard({
    required this.medication,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  /// The medication schedule to display
  final Schedule medication;

  /// Whether this medication is currently selected
  final bool isSelected;

  /// Callback when the card is tapped
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dosageText = _getFormattedDosage();
    final strengthText = medication.formattedStrength;
    final dosageSuffix = dosageText != null ? ', $dosageText' : '';
    final strengthSuffix = strengthText != null ? ', $strengthText' : '';

    return Semantics(
      label: '${medication.medicationName}$strengthSuffix$dosageSuffix',
      hint: isSelected
          ? 'Selected for logging. Double tap to deselect.'
          : 'Not selected. Double tap to select for logging.',
      selected: isSelected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        constraints: const BoxConstraints(
          minHeight: 56, // Single line height
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Medication icon
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.2)
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getMedicationIcon(),
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Left side: Medication name and strength
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      children: [
                        // Medication name
                        TextSpan(text: medication.medicationName ?? ''),
                        // Strength (if available)
                        if (medication.formattedStrength != null)
                          TextSpan(
                            text: ', ${medication.formattedStrength}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.normal,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Right side: Dosage
                if (dosageText != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    dosageText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],

                // Selection indicator
                const SizedBox(width: AppSpacing.sm),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 24,
                  )
                else
                  Icon(
                    Icons.radio_button_unchecked,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get formatted dosage text (e.g., "half a pill", "1 portion")
  String? _getFormattedDosage() {
    final dosage = medication.targetDosage;
    final unit = medication.medicationUnit;

    if (dosage == null || unit == null) return null;

    final shortUnit = _getShortUnit(unit);
    return DosageTextUtils.formatDosageWithUnit(dosage, shortUnit);
  }

  /// Get short form of medication unit
  String _getShortUnit(String unit) {
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

  /// Get appropriate icon based on medication unit
  IconData _getMedicationIcon() {
    if (medication.medicationUnit == null) return Icons.medication;

    return switch (medication.medicationUnit) {
      'pills' => Icons.medication,
      'capsules' => Icons.medication,
      'drops' => Icons.water_drop,
      'injections' => Icons.colorize,
      'milliliters' => Icons.local_drink,
      'tablespoon' => Icons.restaurant,
      'teaspoon' => Icons.restaurant,
      'portions' => Icons.restaurant,
      'sachets' => Icons.inventory_2,
      'ampoules' => Icons.science,
      _ => Icons.medication,
    };
  }
}
