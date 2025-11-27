import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/shared/widgets/inputs/hydra_sliding_segmented_control.dart';

/// A platform-adaptive segmented control selector for stress levels.
///
/// Provides three options: low, medium, high.
/// Used in fluid logging to track the pet's stress during treatment.
///
/// Features:
/// - Platform-adaptive HydraSlidingSegmentedControl (Cupertino on iOS/macOS, Material on Android)
/// - Always has a selected value (defaults to 'low')
/// - Haptic feedback on selection
/// - Full accessibility support
///
/// Example:
/// ```dart
/// StressLevelSelector(
///   value: _selectedStressLevel,
///   onChanged: (String newValue) {
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

  /// Currently selected stress level ('low', 'medium', or 'high')
  final String value;

  /// Callback when selection changes
  final ValueChanged<String> onChanged;

  /// Whether the selector is enabled
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.stressLevelSelectorSemantic,
      hint: l10n.stressLevelCurrentSelection(value),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Center(
          child: HydraSlidingSegmentedControl<String>(
            segments: {
              'low': Text(
                l10n.stressLevelLow,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
              'medium': Text(
                l10n.stressLevelMedium,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
              'high': Text(
                l10n.stressLevelHigh,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
            },
            value: value,
            onChanged: enabled
                ? (String newValue) {
                    // Haptic feedback on selection
                    HapticFeedback.selectionClick();
                    onChanged(newValue);
                  }
                : (_) {},
          ),
        ),
      ),
    );
  }
}
