import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
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

    return Semantics(
      label: 'Stress level selector',
      hint: value != null
          ? 'Current selection: $value stress level'
          : 'No stress level selected',
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          segments: [
            ButtonSegment<String>(
              value: 'low',
              label: const Text('Low'),
              icon: HydraIcon(
                icon: AppIcons.stressLow,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'Low stress level',
            ),
            ButtonSegment<String>(
              value: 'medium',
              label: const Text('Medium'),
              icon: HydraIcon(
                icon: AppIcons.stressMedium,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'Medium stress level',
            ),
            ButtonSegment<String>(
              value: 'high',
              label: const Text('High'),
              icon: HydraIcon(
                icon: AppIcons.stressHigh,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'High stress level',
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
