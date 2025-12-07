import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/theme/app_border_radius.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/logging/models/treatment_choice.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/shared/widgets/icons/hydra_icon.dart';

/// A bottom-sheet-style popup for combined persona users to choose
/// between logging medication, fluid therapy, or symptoms.
///
/// Features:
/// - Three large, tappable buttons (medication/fluid/symptoms)
/// - Consistent styling with other logging popups via LoggingPopupWrapper
/// - Immediate dismiss on selection
/// - Stores choice in state via `setTreatmentChoice()`
/// - Respects UI guidelines and Hydra design system
///
/// Usage:
/// ```dart
/// showHydraBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   builder: (context) => HydraBottomSheet(
///     child: TreatmentChoicePopup(
///       onMedicationSelected: () {
///         Navigator.pop(context);
///         // Navigate to medication logging
///       },
///       onFluidSelected: () {
///         Navigator.pop(context);
///         // Navigate to fluid logging
///       },
///       onSymptomsSelected: () {
///         Navigator.pop(context);
///         // Navigate to symptoms logging
///       },
///     ),
///   ),
/// );
/// ```
class TreatmentChoicePopup extends ConsumerWidget {
  /// Creates a [TreatmentChoicePopup].
  const TreatmentChoicePopup({
    required this.onMedicationSelected,
    required this.onFluidSelected,
    required this.onSymptomsSelected,
    super.key,
  });

  /// Callback when user selects "Log Medication".
  final VoidCallback onMedicationSelected;

  /// Callback when user selects "Log Fluid Therapy".
  final VoidCallback onFluidSelected;

  /// Callback when user selects "Log Symptoms".
  final VoidCallback onSymptomsSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return LoggingPopupWrapper(
      title: l10n.treatmentChoiceTitle,
      onDismiss: () {
        ref.read(loggingProvider.notifier).reset();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.divider,
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
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.divider,
          ),

          // Symptoms button
          Semantics(
            label: l10n.treatmentChoiceSymptomsLabel,
            hint: l10n.treatmentChoiceSymptomsHint,
            button: true,
            child: _TreatmentChoiceButton(
              icon: AppIcons.symptoms,
              label: 'Symptoms',
              onTap: () {
                // Track choice selection
                ref
                    .read(analyticsServiceDirectProvider)
                    .trackTreatmentChoiceSelected(
                      choice: 'symptoms',
                    );

                onSymptomsSelected();
              },
            ),
          ),
        ],
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
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppBorderRadius.buttonRadius,
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
          child: Row(
            children: [
              // Icon
              HydraIcon(
                icon: icon,
                color: AppColors.textSecondary,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.md),

              // Label
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Chevron
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
