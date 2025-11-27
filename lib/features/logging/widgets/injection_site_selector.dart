import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/shared/widgets/inputs/hydra_dropdown.dart';

/// A platform-adaptive selector for fluid injection sites.
///
/// Uses [HydraDropdown] to provide a platform-adaptive dropdown with all
/// FluidLocation enum values. Used in fluid logging to specify where the
/// treatment was administered.
///
/// Features:
/// - All FluidLocation enum options
/// - User-friendly localized display names
/// - Pre-filled from schedule's preferredLocation
/// - Defaults to shoulderBladeMiddle when no schedule
/// - Platform-adaptive (Material dropdown on Android, Cupertino bottom sheet on iOS/macOS)
///
/// Example:
/// ```dart
/// InjectionSiteSelector(
///   value: _selectedInjectionSite,
///   onChanged: (FluidLocation newValue) {
///     setState(() {
///       _selectedInjectionSite = newValue;
///     });
///   },
/// )
/// ```
class InjectionSiteSelector extends StatelessWidget {
  /// Creates an [InjectionSiteSelector].
  const InjectionSiteSelector({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// Currently selected injection site
  final FluidLocation value;

  /// Callback when selection changes
  final ValueChanged<FluidLocation> onChanged;

  /// Whether the selector is enabled
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.injectionSiteSelectorSemantic,
      hint: l10n.injectionSiteCurrentSelection(
        value.getLocalizedName(context),
      ),
      child: HydraDropdown<FluidLocation>(
        value: value,
        items: FluidLocation.values,
        onChanged: enabled
            ? (FluidLocation? newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              }
            : (_) {},
        itemBuilder: (FluidLocation location) => Text(
          location.getLocalizedName(context),
          style: const TextStyle(
            color: AppColors.textPrimary,
            decoration: TextDecoration.none,
          ),
        ),
        enabled: enabled,
      ),
    );
  }
}
