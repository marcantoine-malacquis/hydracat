import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/icons/icon_provider.dart';
import 'package:hydracat/core/theme/app_border_radius.dart';
import 'package:hydracat/core/theme/app_shadows.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/shared/widgets/accessibility/touch_target_icon_button.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// A card displaying medication summary information
class MedicationSummaryCard extends StatelessWidget {
  /// Creates a [MedicationSummaryCard]
  const MedicationSummaryCard({
    required this.medication,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    super.key,
  });

  /// The medication data to display
  final MedicationData medication;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Callback when edit button is pressed
  final VoidCallback? onEdit;

  /// Callback when delete button is pressed
  final VoidCallback? onDelete;

  /// Whether to show action buttons (edit/delete)
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isCupertino =
        theme.platform == TargetPlatform.iOS ||
        theme.platform == TargetPlatform.macOS;
    final medIcon = IconProvider.resolveIconData(
      AppIcons.medication,
      isCupertino: isCupertino,
    );
    final medIconAsset = IconProvider.resolveCustomAsset(AppIcons.medication);

    return HydraCard(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
      ),
      padding: EdgeInsets.zero,
      borderColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          border: Border.all(color: AppColors.border),
          boxShadow: const [AppShadows.cardElevated],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (medIconAsset != null)
                    SvgPicture.asset(
                      medIconAsset,
                      width: 32,
                      height: 32,
                      colorFilter: const ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                    )
                  else
                    Icon(
                      medIcon ?? Icons.medication,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  const SizedBox(width: AppSpacing.md),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (medication.formattedStrength != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            medication.formattedStrength!,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (showActions) ...[
                    if (onEdit != null)
                      TouchTargetIconButton(
                        onPressed: onEdit,
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        tooltip: l10n.editMedicationTooltip,
                        semanticLabel: l10n.editMedicationTooltip,
                      ),
                    if (onDelete != null)
                      TouchTargetIconButton(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: AppColors.error,
                        ),
                        tooltip: l10n.deleteMedicationTooltip,
                        semanticLabel: l10n.deleteMedicationTooltip,
                      ),
                  ],
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                medication.summary,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              if (medication.reminderTimes.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${medication.reminderTimes.length} reminder'
                      '${medication.reminderTimes.length != 1 ? 's' : ''}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                _buildCompactReminderChips(
                                      context,
                                      theme,
                                    )
                                    .expand(
                                      (w) => [
                                        w,
                                        const SizedBox(width: AppSpacing.xs),
                                      ],
                                    )
                                    .toList()
                                  ..removeLast(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Removed old _buildReminderTimes; logic moved to _buildCompactReminderChips

  Widget _buildTimeChip(BuildContext context, DateTime time, ThemeData theme) {
    final timeOfDay = TimeOfDay.fromDateTime(time);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: AppBorderRadius.chipRadius,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        timeOfDay.format(context),
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<Widget> _buildCompactReminderChips(
    BuildContext context,
    ThemeData theme,
  ) {
    return medication.reminderTimes
        .map((t) => _buildTimeChip(context, t, theme))
        .toList();
  }
}

/// Empty state widget for when no medications are added
class EmptyMedicationState extends StatelessWidget {
  /// Creates an [EmptyMedicationState]
  const EmptyMedicationState({
    this.onAddMedication,
    super.key,
  });

  /// Callback when add medication button is pressed
  final VoidCallback? onAddMedication;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isCupertino =
        theme.platform == TargetPlatform.iOS ||
        theme.platform == TargetPlatform.macOS;
    final medIcon = IconProvider.resolveIconData(
      AppIcons.medication,
      isCupertino: isCupertino,
    );
    final medIconAsset = IconProvider.resolveCustomAsset(AppIcons.medication);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (medIconAsset != null)
            SvgPicture.asset(
              medIconAsset,
              width: 64,
              height: 64,
              colorFilter: ColorFilter.mode(
                theme.colorScheme.onSurface.withValues(alpha: 0.3),
                BlendMode.srcIn,
              ),
            )
          else
            Icon(
              medIcon ?? Icons.medication,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          const SizedBox(height: 16),

          Text(
            'No medications added',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            'Add your first medication to get started with your treatment '
            'schedule.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),

          if (onAddMedication != null) ...[
            const SizedBox(height: 24),
            HydraButton(
              onPressed: onAddMedication,
              isFullWidth: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add),
                  const SizedBox(width: AppSpacing.xs),
                  Text(l10n.addMedication),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading state widget for medication operations
class MedicationLoadingCard extends StatelessWidget {
  /// Creates a [MedicationLoadingCard]
  const MedicationLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HydraCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: AppBorderRadius.inputRadius,
                ),
                child: const HydraProgressIndicator(),
              ),
              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: AppBorderRadius.inputRadius,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: AppBorderRadius.buttonRadius,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
