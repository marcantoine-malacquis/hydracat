import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/core/utils/dosage_text_utils.dart';
import 'package:hydracat/l10n/app_localizations.dart';

/// Expandable dosage adjustment widget with stepper and quick presets.
///
/// Features:
/// - +/- stepper with 0.25 increments
/// - Quick preset buttons (full, half, skip)
/// - Visual feedback for dosage state (full/partial/missed)
/// - Accessibility support with semantic labels
/// - Smooth animations for expansion/collapse
class DosageAdjuster extends StatelessWidget {
  /// Creates a [DosageAdjuster].
  const DosageAdjuster({
    required this.currentDosage,
    required this.scheduledDosage,
    required this.unit,
    required this.onDosageChanged,
    super.key,
  });

  /// Current dosage value
  final double currentDosage;

  /// Scheduled/target dosage
  final double scheduledDosage;

  /// Medication unit (e.g., "pill", "ml")
  final String unit;

  /// Callback when dosage changes
  final ValueChanged<double> onDosageChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Label
            Text(
              l10n.dosageGivenLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Stepper control
            _buildStepper(context, theme),

            const SizedBox(height: AppSpacing.lg),

            // Quick presets
            _buildPresets(context, theme, l10n),

            // Adherence indicator (if not full dose)
            if (currentDosage != scheduledDosage) ...[
              const SizedBox(height: AppSpacing.md),
              _buildAdherenceIndicator(context, theme, l10n),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the stepper control (+/- buttons with dosage display)
  Widget _buildStepper(BuildContext context, ThemeData theme) {
    final canDecrement = currentDosage > 0;

    return Row(
      children: [
        // Decrement button
        Semantics(
          label: 'Decrease dosage',
          button: true,
          enabled: canDecrement,
          child: Material(
            color: canDecrement
                ? AppColors.primaryLight.withValues(alpha: 0.3)
                : AppColors.disabled,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: canDecrement ? _decrementDosage : null,
              customBorder: const CircleBorder(),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: Icon(
                  Icons.remove,
                  color: canDecrement
                      ? AppColors.primaryDark
                      : AppColors.textTertiary,
                  size: 24,
                ),
              ),
            ),
          ),
        ),

        // Dosage display (localized with proper pluralization)
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
            ),
            alignment: Alignment.center,
            child: Text(
              DosageTextUtils.formatDosageWithContext(
                context,
                currentDosage,
                unit,
              ),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),

        // Increment button (always enabled - no upper limit)
        Semantics(
          label: 'Increase dosage',
          button: true,
          enabled: true,
          child: Material(
            color: AppColors.primaryLight.withValues(alpha: 0.3),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _incrementDosage,
              customBorder: const CircleBorder(),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add,
                  color: AppColors.primaryDark,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds quick preset buttons
  Widget _buildPresets(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        // Full dose preset
        Expanded(
          child: _PresetButton(
            label: l10n.dosagePresetFull,
            isSelected: currentDosage == scheduledDosage,
            onTap: () => _setPreset(scheduledDosage),
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),

        // Half dose preset
        Expanded(
          child: _PresetButton(
            label: l10n.dosagePresetHalf,
            isSelected: currentDosage == scheduledDosage / 2,
            onTap: () => _setPreset(scheduledDosage / 2),
            color: theme.colorScheme.tertiary,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),

        // Skip/missed preset
        Expanded(
          child: _PresetButton(
            label: l10n.dosagePresetSkip,
            isSelected: currentDosage == 0,
            onTap: () => _setPreset(0),
            color: theme.colorScheme.error,
          ),
        ),
      ],
    );
  }

  /// Builds adherence indicator showing percentage
  Widget _buildAdherenceIndicator(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final adherencePercent = scheduledDosage > 0
        ? (currentDosage / scheduledDosage * 100).round()
        : 0;

    final Color badgeColor;
    final IconData badgeIcon;
    final String badgeText;

    if (currentDosage == 0) {
      badgeColor = theme.colorScheme.error;
      badgeIcon = Icons.close;
      badgeText = l10n.dosageBadgeMissed;
    } else if (currentDosage < scheduledDosage) {
      badgeColor = theme.colorScheme.tertiary;
      badgeIcon = Icons.warning_amber_rounded;
      badgeText = l10n.dosageBadgePartial(adherencePercent);
    } else {
      badgeColor = theme.colorScheme.primary;
      badgeIcon = Icons.add_circle_outline;
      badgeText = l10n.dosageBadgeExtra(adherencePercent);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 16,
            color: badgeColor,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            badgeText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Increment dosage by 0.25
  void _incrementDosage() {
    final newDosage = (currentDosage + 0.25).clamp(0.0, double.infinity);
    HapticFeedback.selectionClick();
    onDosageChanged(newDosage);
  }

  /// Decrement dosage by 0.25
  void _decrementDosage() {
    final newDosage = (currentDosage - 0.25).clamp(0.0, double.infinity);
    HapticFeedback.selectionClick();
    onDosageChanged(newDosage);
  }

  /// Set dosage to preset value
  void _setPreset(double value) {
    HapticFeedback.selectionClick();
    onDosageChanged(value);
  }
}

/// Preset button for quick dosage selection
class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected
            ? color.withValues(alpha: 0.2)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? color
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
