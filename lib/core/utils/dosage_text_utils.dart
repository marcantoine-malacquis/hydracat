import 'package:flutter/widgets.dart';
import 'package:hydracat/l10n/app_localizations.dart';

/// Utility class for converting numeric dosages to natural language text.
///
/// Provides user-friendly display of medication dosages with proper
/// pluralization using ICU message format for internationalization.
class DosageTextUtils {
  /// Private constructor to prevent instantiation
  const DosageTextUtils._();

  /// Formats a dosage value with its unit using localized plural forms.
  ///
  /// When [l10n] is provided, uses ICU plural format for proper
  /// internationalization:
  /// - 1 + "pill" → "1 pill"
  /// - 2 + "pill" → "2 pills"
  /// - 0.5 + "pill" → "0.5 pills"
  /// - 1 + "sachet" → "1 Sachet"
  /// - 2 + "sachet" → "2 Sachets"
  ///
  /// When [l10n] is null, falls back to legacy English-only pluralization.
  ///
  /// The [unitShortForm] parameter should be the normalized unit name
  /// from [MedicationUnitUtils.shortForm()]:
  /// - "pill", "sachet", "capsule", "tablet", "drop", "ampoule",
  ///   "injection", "portion"
  /// - "mg", "ml", "mcg", "tbsp", "tsp" (non-countable)
  ///
  /// Example with localization:
  /// ```dart
  /// final l10n = AppLocalizations.of(context)!;
  /// DosageTextUtils.formatDosageWithUnit(1, "sachet", l10n: l10n);
  /// // Returns: "1 Sachet"
  ///
  /// DosageTextUtils.formatDosageWithUnit(2, "sachet", l10n: l10n);
  /// // Returns: "2 Sachets"
  /// ```
  ///
  /// Example without localization (legacy fallback):
  /// ```dart
  /// DosageTextUtils.formatDosageWithUnit(1, "pill");
  /// // Returns: "1 pill"
  /// ```
  static String formatDosageWithUnit(
    double dosage,
    String unitShortForm, {
    AppLocalizations? l10n,
  }) {
    // Format the numeric value, removing trailing zeros
    final formatted = dosage
        .toStringAsFixed(2)
        .replaceAll(
          // The library directive may trigger deprecated_member_use warnings
          // in some Dart versions.
          // ignore: deprecated_member_use
          RegExp(r'\.?0*$'),
          '',
        );

    // Use localized plural forms if available
    if (l10n != null) {
      final localizedUnit = _getLocalizedUnit(unitShortForm, dosage, l10n);
      return '$formatted $localizedUnit';
    }

    // Fallback to legacy pluralization for backward compatibility
    final unit = dosage == 1.0
        ? _getSingularUnit(unitShortForm)
        : _getPluralUnit(unitShortForm);

    return '$formatted $unit';
  }

  /// Returns localized unit text using ICU plural format.
  ///
  /// Maps normalized unit short forms to their corresponding localization keys.
  static String _getLocalizedUnit(
    String unitShortForm,
    double count,
    AppLocalizations l10n,
  ) {
    return switch (unitShortForm.toLowerCase()) {
      'pill' => l10n.medicationUnitPill(count),
      'sachet' => l10n.medicationUnitSachet(count),
      'capsule' => l10n.medicationUnitCapsule(count),
      'tablet' => l10n.medicationUnitTablet(count),
      'drop' => l10n.medicationUnitDrop(count),
      'ampoule' => l10n.medicationUnitAmpoule(count),
      'injection' => l10n.medicationUnitInjection(count),
      'portion' => l10n.medicationUnitPortion(count),
      'mg' => l10n.medicationUnitMg,
      'ml' => l10n.medicationUnitMl,
      'mcg' => l10n.medicationUnitMcg,
      'tbsp' => l10n.medicationUnitTbsp,
      'tsp' => l10n.medicationUnitTsp,
      // Unknown unit: fall back to legacy behavior
      _ => count == 1.0
          ? _getSingularUnit(unitShortForm)
          : _getPluralUnit(unitShortForm),
    };
  }

  /// Returns the singular form of a unit (handles special cases)
  static String _getSingularUnit(String unitShortForm) {
    // Most units are already singular in shortForm
    return unitShortForm;
  }

  /// Returns the plural form of a unit (legacy English-only fallback)
  static String _getPluralUnit(String unitShortForm) {
    // Countable units that get pluralized
    return switch (unitShortForm.toLowerCase()) {
      'pill' => 'pills',
      'capsule' => 'capsules',
      'tablet' => 'tablets',
      'drop' => 'drops',
      'ampoule' => 'ampoules',
      'injection' => 'injections',
      'portion' => 'portions',
      'sachet' => 'sachets',
      // Non-countable units don't change
      'mcg' || 'mg' || 'ml' || 'tbsp' || 'tsp' => unitShortForm,
      // Default: assume it's already plural or doesn't need pluralization
      _ => unitShortForm,
    };
  }

  /// Convenience method to format dosage with unit using BuildContext.
  ///
  /// Automatically extracts localization from context.
  ///
  /// Example:
  /// ```dart
  /// DosageTextUtils.formatDosageWithContext(
  ///   context,
  ///   1.5,
  ///   "pill",
  /// );
  /// // Returns: "1.5 pills"
  /// ```
  static String formatDosageWithContext(
    BuildContext context,
    double dosage,
    String unitShortForm,
  ) {
    final l10n = AppLocalizations.of(context);
    return formatDosageWithUnit(dosage, unitShortForm, l10n: l10n);
  }
}
