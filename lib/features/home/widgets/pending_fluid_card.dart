import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/home/models/pending_fluid_treatment.dart';
import 'package:hydracat/shared/widgets/cards/hydra_card.dart';
import 'package:hydracat/shared/widgets/icons/hydra_icon.dart';

/// Card widget displaying pending fluid therapy status on the dashboard.
///
/// Shows aggregated remaining volume for today with scheduled times,
/// including visual indicators for overdue times (3px golden left border).
class PendingFluidCard extends StatelessWidget {
  /// Creates a [PendingFluidCard].
  const PendingFluidCard({
    required this.fluidTreatment,
    required this.onTap,
    super.key,
  });

  /// The pending fluid treatment to display
  final PendingFluidTreatment fluidTreatment;

  /// Callback when card is tapped
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label:
          'Fluid Therapy, '
          '${fluidTreatment.displayVolume}, '
          'scheduled at ${fluidTreatment.displayTimes}'
          '${fluidTreatment.hasOverdueTimes ? ", overdue" : ""}',
      hint: 'Tap to confirm fluid therapy',
      button: true,
      child: HydraCard(
        onTap: onTap,
        borderColor: fluidTreatment.hasOverdueTimes
            ? AppColors.success
            : AppColors.border,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Container(
          decoration: fluidTreatment.hasOverdueTimes
              ? const BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: AppColors.success,
                      width: 3,
                    ),
                  ),
                )
              : null,
          padding: fluidTreatment.hasOverdueTimes
              ? const EdgeInsets.only(left: AppSpacing.sm)
              : null,
          child: Row(
            children: [
              // Fluid therapy icon
              HydraIcon(
                icon: AppIcons.fluidTherapy,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Fluid info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Fluid Therapy',
                      style: AppTextStyles.h3.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Remaining volume
                    Text(
                      fluidTreatment.displayVolume,
                      style: AppTextStyles.body.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Scheduled times
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fluidTreatment.displayTimes,
                    style: AppTextStyles.caption.copyWith(
                      color: fluidTreatment.hasOverdueTimes
                          ? AppColors.success
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: fluidTreatment.hasOverdueTimes
                          ? FontWeight.w600
                          : null,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),

              const SizedBox(width: AppSpacing.xs),

              // Chevron
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
