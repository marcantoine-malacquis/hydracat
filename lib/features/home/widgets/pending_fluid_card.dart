import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/icons/icon_provider.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/home/models/pending_fluid_treatment.dart';
import 'package:hydracat/shared/widgets/cards/hydra_card.dart';

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
    final isCupertino =
        theme.platform == TargetPlatform.iOS ||
        theme.platform == TargetPlatform.macOS;
    final iconColor = fluidTreatment.hasOverdueTimes
        ? AppColors.success
        : AppColors.primary;
    final cardTone = fluidTreatment.hasOverdueTimes
        ? AppColors.success
        : AppColors.primary;
    final fluidIcon = IconProvider.resolveIconData(
      AppIcons.fluidTherapy,
      isCupertino: isCupertino,
    );

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
        backgroundColor: Color.alphaBlend(
          cardTone.withAlpha(8),
          AppColors.surface,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        borderColor: fluidTreatment.hasOverdueTimes
            ? Color.alphaBlend(cardTone.withAlpha(80), AppColors.border)
            : AppColors.border,
        margin: const EdgeInsets.symmetric(
          vertical: CardConstants.cardMarginVertical,
        ),
        child: Row(
          children: [
            // Fluid therapy icon
            SizedBox(
              width: CardConstants.iconContainerSize,
              height: CardConstants.iconContainerSize,
              child: Center(
                child: Icon(
                  fluidIcon ?? Icons.water_drop,
                  size: 32,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Fluid info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Fluid Therapy',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Remaining volume
                  Text(
                    fluidTreatment.displayVolume,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Scheduled times
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fluidTreatment.displayTimes,
                  style: AppTextStyles.caption.copyWith(
                    color: fluidTreatment.hasOverdueTimes
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.end,
                ),
              ],
            ),

            const SizedBox(width: AppSpacing.md),

            // Chevron
            Icon(
              IconProvider.resolveIconData(
                AppIcons.chevronRight,
                isCupertino: isCupertino,
              ),
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
