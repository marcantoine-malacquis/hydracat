import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/home/models/pending_treatment.dart';
import 'package:hydracat/shared/widgets/cards/hydra_card.dart';
import 'package:hydracat/shared/widgets/icons/hydra_icon.dart';

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
    final strengthText = treatment.displayStrength != null
        ? ' ${treatment.displayStrength}'
        : '';

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
        borderColor: treatment.isOverdue ? AppColors.success : AppColors.border,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
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
              // Medication icon
              HydraIcon(
                icon: AppIcons.medication,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: AppSpacing.sm),

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
                            style: AppTextStyles.h3.copyWith(
                              color: theme.colorScheme.onSurface,
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
                    const SizedBox(height: 2),

                    // Dosage
                    Text(
                      treatment.displayDosage,
                      style: AppTextStyles.body.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    treatment.displayTime,
                    style: AppTextStyles.body.copyWith(
                      color: treatment.isOverdue
                          ? AppColors.success
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: treatment.isOverdue ? FontWeight.w600 : null,
                    ),
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
