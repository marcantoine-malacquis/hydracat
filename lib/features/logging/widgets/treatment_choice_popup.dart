import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/features/logging/models/treatment_choice.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/shared/widgets/icons/hydra_icon.dart';

/// A small action-sheet-style popup for combined persona users to choose
/// between logging medication or fluid therapy.
///
/// Features:
/// - Two large, tappable buttons (medication/fluid)
/// - Slide-up animation (300ms)
/// - Immediate dismiss on selection
/// - Stores choice in state via `setTreatmentChoice()`
/// - Respects UI guidelines (primary teal colors, rounded corners)
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => TreatmentChoicePopup(
///     onMedicationSelected: () {
///       Navigator.pop(context);
///       context.push('/logging/medication');
///     },
///     onFluidSelected: () {
///       Navigator.pop(context);
///       context.push('/logging/fluid');
///     },
///   ),
/// );
/// ```
class TreatmentChoicePopup extends ConsumerWidget {
  /// Creates a [TreatmentChoicePopup].
  const TreatmentChoicePopup({
    required this.onMedicationSelected,
    required this.onFluidSelected,
    super.key,
  });

  /// Callback when user selects "Log Medication".
  final VoidCallback onMedicationSelected;

  /// Callback when user selects "Log Fluid Therapy".
  final VoidCallback onFluidSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Reset state on dismissal
          ref.read(loggingProvider.notifier).reset();
        }
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          type: MaterialType.transparency,
          child: Semantics(
            label: l10n.treatmentChoiceSemanticLabel,
            child: Container(
              margin: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom:
                    mediaQuery.padding.bottom +
                    AppSpacing.sm, // Reduced from md to sm
              ),
              padding: const EdgeInsets.only(
                bottom: AppSpacing.sm, // Reduced from lg to sm
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with teal background
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                      top: AppSpacing.lg,
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.md,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      l10n.treatmentChoiceTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),

                  // Buttons section with horizontal padding
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Medication button
                        Semantics(
                          label: l10n.treatmentChoiceMedicationLabel,
                          hint: l10n.treatmentChoiceMedicationHint,
                          button: true,
                          child: _TreatmentChoiceButton(
                            icon: AppIcons.medication,
                            label: TreatmentChoice.medication.displayName,
                            onTap: () {
                              ref
                                  .read(loggingProvider.notifier)
                                  .setTreatmentChoice(
                                    TreatmentChoice.medication,
                                  );

                              // Track choice selection
                              ref
                                  .read(analyticsServiceDirectProvider)
                                  .trackTreatmentChoiceSelected(
                                    choice: 'medication',
                                  );

                              onMedicationSelected();
                            },
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),

                        // Fluid therapy button
                        Semantics(
                          label: l10n.treatmentChoiceFluidLabel,
                          hint: l10n.treatmentChoiceFluidHint,
                          button: true,
                          child: _TreatmentChoiceButton(
                            icon: AppIcons.fluidTherapy,
                            label: TreatmentChoice.fluid.displayName,
                            onTap: () {
                              ref
                                  .read(loggingProvider.notifier)
                                  .setTreatmentChoice(TreatmentChoice.fluid);

                              // Track choice selection
                              ref
                                  .read(analyticsServiceDirectProvider)
                                  .trackTreatmentChoiceSelected(
                                    choice: 'fluid',
                                  );

                              onFluidSelected();
                            },
                          ),
                        ),

                        // Visual separation
                        const SizedBox(height: AppSpacing.md),

                        // Cancel button
                        Semantics(
                          label: l10n.cancel,
                          hint: l10n.treatmentChoiceCancelSemantic,
                          button: true,
                          child: _CancelButton(
                            onTap: () {
                              ref.read(loggingProvider.notifier).reset();
                              OverlayService.hide();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A flat list-style button for treatment choice selection.
class _TreatmentChoiceButton extends StatelessWidget {
  const _TreatmentChoiceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      splashColor: theme.colorScheme.primary.withValues(alpha: 0.12),
      highlightColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      splashFactory: InkRipple.splashFactory,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: AppSpacing.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Icon
            HydraIcon(
              icon: icon,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),

            // Label
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

/// A cancel button with subtle background styling.
class _CancelButton extends StatelessWidget {
  const _CancelButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: onTap,
      splashColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
      highlightColor: theme.colorScheme.onSurfaceVariant.withValues(
        alpha: 0.08,
      ),
      borderRadius: BorderRadius.circular(12),
      splashFactory: InkRipple.splashFactory,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: AppSpacing.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Text(
            l10n.cancel,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
