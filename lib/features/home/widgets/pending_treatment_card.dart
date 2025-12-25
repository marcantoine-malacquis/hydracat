import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/icons/icon_provider.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/home/models/pending_treatment.dart';
import 'package:hydracat/shared/widgets/cards/hydra_card.dart';

/// Card widget displaying a pending medication treatment on the dashboard.
///
/// Shows medication name, dosage, strength, and scheduled time with visual
/// indicators for overdue treatments (3px golden left border, tinted time
/// text).
class PendingTreatmentCard extends StatelessWidget {
  /// Creates a [PendingTreatmentCard].
  const PendingTreatmentCard({
    required this.treatment,
    required this.onTap,
    super.key,
  });

  /// The pending medication treatment to display
  final PendingTreatment treatment;

  /// Callback when card is tapped
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isCupertino =
        theme.platform == TargetPlatform.iOS ||
        theme.platform == TargetPlatform.macOS;
    final medIcon = IconProvider.resolveIconData(
      AppIcons.medication,
      isCupertino: isCupertino,
    );
    final medIconAsset = IconProvider.resolveCustomAsset(AppIcons.medication);
    final iconColor = treatment.isOverdue
        ? AppColors.success
        : AppColors.primary;
    final strengthText = treatment.displayStrength != null
        ? ' ${treatment.displayStrength}'
        : '';
    final cardTone = treatment.isOverdue
        ? AppColors.success
        : AppColors.primary;
    final cardBackground = Color.alphaBlend(
      cardTone.withAlpha(8),
      AppColors.surface,
    );

    // Determine time text for display and accessibility
    final timeDescription = treatment.isFlexible
        ? l10n.noTimeSet
        : 'scheduled at ${treatment.displayTime}';

    return Semantics(
      label:
          'Medication: ${treatment.displayName}$strengthText, '
          '${treatment.displayDosage}, '
          '$timeDescription'
          '${treatment.isOverdue ? ", overdue" : ""}',
      hint: 'Tap to confirm or skip this medication',
      button: true,
      child: HydraCard(
        onTap: onTap,
        backgroundColor: cardBackground,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        borderColor: treatment.isOverdue
            ? Color.alphaBlend(cardTone.withAlpha(80), AppColors.border)
            : AppColors.border,
        margin: const EdgeInsets.symmetric(
          vertical: CardConstants.cardMarginVertical,
        ),
        child: Row(
          children: [
            // Medication icon in clinical container
            SizedBox(
              width: CardConstants.iconContainerSize,
              height: CardConstants.iconContainerSize,
              child: Center(
                child: medIconAsset != null
                    ? SvgPicture.asset(
                        medIconAsset,
                        width: 32,
                        height: 32,
                        colorFilter: ColorFilter.mode(
                          iconColor,
                          BlendMode.srcIn,
                        ),
                      )
                    : Icon(
                        medIcon ?? Icons.medication,
                        size: 32,
                        color: iconColor,
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Medication info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medication name and strength on same line
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: treatment.displayName,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (treatment.displayStrength != null) ...[
                          TextSpan(
                            text: ' ${treatment.displayStrength}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Dosage
                  Text(
                    treatment.displayDosage,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Time (only displayed when set)
            if (treatment.displayTime != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    treatment.displayTime!,
                    style: AppTextStyles.caption.copyWith(
                      color: treatment.isOverdue
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
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
