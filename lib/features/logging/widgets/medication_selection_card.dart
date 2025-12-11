import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/icons/icon_provider.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/core/utils/dosage_text_utils.dart';
import 'package:hydracat/features/logging/widgets/dosage_adjuster.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/l10n/app_localizations.dart';

/// A selectable card displaying medication name, strength, and dosage.
///
/// Used in the medication logging popup to allow users to select which
/// medications they want to log. Provides visual feedback for selection
/// state with animated border and background changes.
///
/// Design follows a single-line horizontal layout when collapsed:
/// - Left: Icon + Medication name + Strength (e.g., "Dede, 2 mg")
/// - Right: Dosage (e.g., "1 pill")
///
/// When selected and expanded, shows inline dosage adjustment controls.
class MedicationSelectionCard extends StatelessWidget {
  /// Creates a [MedicationSelectionCard].
  const MedicationSelectionCard({
    required this.medication,
    required this.isSelected,
    required this.isExpanded,
    required this.currentDosage,
    required this.onTap,
    required this.onExpandToggle,
    required this.onDosageChanged,
    super.key,
  });

  /// The medication schedule to display
  final Schedule medication;

  /// Whether this medication is currently selected
  final bool isSelected;

  /// Whether the dosage adjuster is expanded
  final bool isExpanded;

  /// Current custom dosage (may differ from scheduled)
  final double currentDosage;

  /// Callback when the card is tapped
  final VoidCallback onTap;

  /// Callback when expand/collapse is toggled
  final VoidCallback onExpandToggle;

  /// Callback when dosage is adjusted
  final ValueChanged<double> onDosageChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isCupertino =
        theme.platform == TargetPlatform.iOS ||
        theme.platform == TargetPlatform.macOS;
    final medIcon = IconProvider.resolveIconData(
      AppIcons.medication,
      isCupertino: isCupertino,
    );
    final medIconAsset = IconProvider.resolveCustomAsset(AppIcons.medication);
    final dosageText = _getFormattedDosage(currentDosage);
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
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main card content
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      // Medication icon (platform-specific)
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(
                          child: medIconAsset != null
                              ? SvgPicture.asset(
                                  medIconAsset,
                                  width: 32,
                                  height: 32,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.primary,
                                    BlendMode.srcIn,
                                  ),
                                )
                              : Icon(
                                  medIcon ?? Icons.medication,
                                  size: 32,
                                  color: AppColors.primary,
                                ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Left side: Medication name and strength
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              // Medication name (same style as home screen)
                              TextSpan(
                                text: medication.medicationName ?? '',
                                style: AppTextStyles.h2.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              // Strength (same style as home screen)
                              if (medication.formattedStrength != null)
                                TextSpan(
                                  text: ' ${medication.formattedStrength}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Right side: Dosage (hidden when expanded)
                      if (!isExpanded && dosageText != null) ...[
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
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.3,
                          ),
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),

              // "Adjust dose" link (only when selected and not expanded)
              if (isSelected && !isExpanded) ...[
                InkWell(
                  onTap: onExpandToggle,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      bottom: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.tune,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          l10n.dosageAdjustLink,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Dosage adjuster (when expanded)
              if (isExpanded) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                  ),
                  child: DosageAdjuster(
                    currentDosage: currentDosage,
                    scheduledDosage: medication.targetDosage ?? 1.0,
                    unit: _getShortUnit(medication.medicationUnit ?? 'pills'),
                    onDosageChanged: onDosageChanged,
                  ),
                ),
                // Collapse button
                InkWell(
                  onTap: onExpandToggle,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.expand_less,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          l10n.dosageCollapseLink,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Get formatted dosage text (e.g., "half a pill", "1 portion")
  String? _getFormattedDosage(double dosage) {
    final unit = medication.medicationUnit;

    if (unit == null) return null;

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
}
