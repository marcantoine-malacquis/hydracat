import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/shared/widgets/bottom_sheets/hydra_bottom_sheet.dart';

/// A platform-adaptive selector for fluid injection sites.
///
/// Provides a tappable field that opens a bottom sheet with all FluidLocation
/// enum values. Used in fluid logging to specify where the treatment was
/// administered.
///
/// Features:
/// - All FluidLocation enum options
/// - User-friendly display names
/// - Pre-filled from schedule's preferredLocation
/// - Defaults to shoulderBladeLeft when no schedule
/// - Platform-adaptive bottom sheet (Material on Android, Cupertino on iOS/macOS)
/// - Works correctly within overlay popups by using host context
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

  void _showSelectionSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final platform = Theme.of(context).platform;
    final isCupertino =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    // Use host context from OverlayService if available (for overlay popups),
    // otherwise use the widget's context
    final hostContext = OverlayService.hostContext ?? context;

    showHydraBottomSheet<FluidLocation>(
      context: hostContext,
      useRootNavigator: true,
      builder: (sheetContext) => HydraBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l10n.injectionSiteLabel,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Options list
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: FluidLocation.values.map((location) {
                  final isSelected = value == location;
                  final locationName = location.getLocalizedName(sheetContext);

                  if (isCupertino) {
                    return CupertinoListTile(
                      title: Text(locationName),
                      trailing: isSelected
                          ? Icon(
                              CupertinoIcons.check_mark,
                              color: theme.colorScheme.primary,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        onChanged(location);
                        Navigator.of(sheetContext).pop();
                      },
                    );
                  } else {
                    return ListTile(
                      title: Text(locationName),
                      trailing: isSelected
                          ? Icon(
                              Icons.check,
                              color: theme.colorScheme.primary,
                              size: 24,
                            )
                          : null,
                      selected: isSelected,
                      onTap: () {
                        onChanged(location);
                        Navigator.of(sheetContext).pop();
                      },
                    );
                  }
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.injectionSiteSelectorSemantic,
      hint: l10n.injectionSiteCurrentSelection(
        value.getLocalizedName(context),
      ),
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () => _showSelectionSheet(context) : null,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.injectionSiteLabel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              suffixIcon: Icon(
                Icons.arrow_drop_down,
                color: enabled
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface.withValues(alpha: 0.38),
              ),
            ),
            child: Text(
              value.getLocalizedName(context),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
