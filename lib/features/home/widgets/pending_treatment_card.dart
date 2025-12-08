import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydracat/core/constants/app_icons.dart';
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
    final theme = Theme.of(context);
    final isCupertino =
        theme.platform == TargetPlatform.iOS ||
        theme.platform == TargetPlatform.macOS;
    final medIcon = IconProvider.resolveIconData(
      AppIcons.medication,
      isCupertino: isCupertino,
    );
    final medIconAsset = IconProvider.resolveCustomAsset(AppIcons.medication);
    final strengthText = treatment.displayStrength != null
        ? ' ${treatment.displayStrength}'
        : '';
    final cardBackground = treatment.isOverdue
        ? AppColors.surface
        : Color.alphaBlend(
            AppColors.primary.withAlpha(8),
            AppColors.surface,
          );

    return Semantics(
      label:
          'Medication: ${treatment.displayName}$strengthText, '
          '${treatment.displayDosage}, '
          'scheduled at ${treatment.displayTime}'
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
        borderColor: treatment.isOverdue ? AppColors.success : AppColors.border,
        margin: const EdgeInsets.symmetric(
          vertical: CardConstants.cardMarginVertical,
        ),
        child: Container(
          decoration: treatment.isOverdue
              ? const BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: AppColors.success,
                      width: 3,
                    ),
                  ),
                )
              : null,
          padding: treatment.isOverdue
              ? const EdgeInsets.only(left: AppSpacing.sm)
              : null,
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
                          colorFilter: const ColorFilter.mode(
                            AppColors.primary,
                            BlendMode.srcIn,
                          ),
                        )
                      : Icon(
                          medIcon ?? Icons.medication,
                          size: 32,
                          color: AppColors.primary,
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

              // Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    treatment.displayTime,
                    style: AppTextStyles.caption.copyWith(
                      color: treatment.isOverdue
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontWeight: treatment.isOverdue ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: AppSpacing.md),

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
