import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/shared/widgets/icons/hydra_icon.dart';

/// A Material 3 segmented button selector for stress levels.
///
/// Provides three options: low, medium, high with icon indicators.
/// Used in fluid logging to track the pet's stress during treatment.
///
/// Features:
/// - Material 3 SegmentedButton for single selection
/// - Icons from AppIcons (stressLow, stressMedium, stressHigh)
/// - Optional field (can be null/unselected)
/// - Haptic feedback on selection
/// - Full accessibility support
///
/// Example:
/// ```dart
/// StressLevelSelector(
///   value: _selectedStressLevel,
///   onChanged: (String? newValue) {
///     setState(() {
///       _selectedStressLevel = newValue;
///     });
///   },
/// )
/// ```
class StressLevelSelector extends StatelessWidget {
  /// Creates a [StressLevelSelector].
  const StressLevelSelector({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// Currently selected stress level ('low', 'medium', 'high', or null)
  final String? value;

  /// Callback when selection changes
  final ValueChanged<String?> onChanged;

  /// Whether the selector is enabled
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.stressLevelSelectorSemantic,
      hint: value != null
          ? l10n.stressLevelCurrentSelection(value!)
          : l10n.stressLevelNoSelection,
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          segments: [
            ButtonSegment<String>(
              value: 'low',
              label: Text(l10n.stressLevelLow),
              icon: HydraIcon(
                icon: AppIcons.stressLow,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: l10n.stressLevelLowTooltip,
            ),
            ButtonSegment<String>(
              value: 'medium',
              label: Text(l10n.stressLevelMedium),
              icon: HydraIcon(
                icon: AppIcons.stressMedium,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: l10n.stressLevelMediumTooltip,
            ),
            ButtonSegment<String>(
              value: 'high',
              label: Text(l10n.stressLevelHigh),
              icon: HydraIcon(
                icon: AppIcons.stressHigh,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: l10n.stressLevelHighTooltip,
            ),
          ],
          selected: value != null ? {value!} : {},
          onSelectionChanged: enabled
              ? (Set<String> newSelection) {
                  // Haptic feedback on selection
                  HapticFeedback.selectionClick();

                  // Handle selection (allow deselection by tapping same button)
                  if (newSelection.isEmpty) {
                    onChanged(null);
                  } else {
                    onChanged(newSelection.first);
                  }
                }
              : null,
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          style: ButtonStyle(
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: WidgetStateProperty.all(
              theme.textTheme.labelMedium?.copyWith(
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
