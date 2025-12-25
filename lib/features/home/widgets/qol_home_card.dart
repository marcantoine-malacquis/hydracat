import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/icons/icon_provider.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/qol/widgets/qol_radar_chart.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/qol_provider.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_button.dart';
import 'package:hydracat/shared/widgets/cards/hydra_card.dart';
import 'package:intl/intl.dart';

/// Home screen card displaying the latest QoL assessment.
///
/// Features:
/// - Empty state: Encourages user to start their first assessment
/// - Populated state: Shows compact radar chart with overall score
/// - Tap to view full details
/// - Analytics tracking for views and interactions
///
/// Cost-optimized: Uses cached assessment from provider (no additional reads)
class QolHomeCard extends ConsumerStatefulWidget {
  /// Creates a [QolHomeCard].
  const QolHomeCard({super.key});

  @override
  ConsumerState<QolHomeCard> createState() => _QolHomeCardState();
}

class _QolHomeCardState extends ConsumerState<QolHomeCard> {
  bool _hasTrackedView = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Track card view once per widget lifecycle
    if (!_hasTrackedView) {
      _hasTrackedView = true;
      _trackCardView();
    }
  }

  void _trackCardView() {
    ref.read(analyticsServiceDirectProvider).trackFeatureUsed(
          featureName: 'qol_home_card_viewed',
        );
  }

  void _trackCardTap() {
    ref.read(analyticsServiceDirectProvider).trackFeatureUsed(
          featureName: 'qol_home_card_tapped',
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isCupertino =
        theme.platform == TargetPlatform.iOS ||
        theme.platform == TargetPlatform.macOS;
    final latestAssessment = ref.watch(currentQolAssessmentProvider);

    // Empty state: No assessment yet
    if (latestAssessment == null) {
      return _EmptyStateCard(
        onStartAssessment: () {
          _trackCardTap();
          context.push('/profile/qol/new');
        },
      );
    }

    // Populated state: Show latest assessment
    return Semantics(
      container: true,
      label: 'Quality of Life card',
      hint: 'Tap to view history',
      button: true,
      child: HydraCard(
        onTap: () {
          _trackCardTap();
          context.push('/profile/qol');
        },
        margin: const EdgeInsets.only(
          top: AppSpacing.xs,
          bottom: AppSpacing.mdSm,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Title + Chevron + Score badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.qolNavigationTitle,
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
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
                _ScoreBadge(
                  score: latestAssessment.overallScore,
                  scoreBand: latestAssessment.scoreBand,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Compact radar chart
            QolRadarChart(
              assessment: latestAssessment,
              isCompact: true,
            ),

            const SizedBox(height: AppSpacing.md),

            // Full-width separator
            Container(
              height: 1,
              color: AppColors.border,
            ),

            const SizedBox(height: AppSpacing.mdSm),

            // Last assessed footer (centered, full-width)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Last assessed: ',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  DateFormat.yMMMd().format(latestAssessment.date),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state card when no QoL assessments exist
class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.onStartAssessment});

  final VoidCallback onStartAssessment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return HydraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with icon
          Row(
            children: [
              const Icon(
                Icons.favorite_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.qolNavigationTitle,
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Description
          Text(
            l10n.qolNavigationSubtitle,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // CTA Button
          HydraButton(
            onPressed: onStartAssessment,
            variant: HydraButtonVariant.secondary,
            size: HydraButtonSize.small,
            child: Text(l10n.qolStartAssessment),
          ),
        ],
      ),
    );
  }
}

/// Compact score badge for home card header
class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({
    required this.score,
    required this.scoreBand,
  });

  final double? score;
  final String? scoreBand;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (score == null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.textTertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          l10n.qolInsufficientData,
          style: AppTextStyles.small.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      );
    }

    final color = _getScoreBandColor(scoreBand);
    final scoreValue = score!; // Safe to use ! here as null is checked above

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getScoreBandLabel(context, scoreBand),
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${scoreValue.toStringAsFixed(0)}%)',
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreBandColor(String? band) {
    switch (band) {
      case 'veryGood':
        return AppColors.primary;
      case 'good':
        return AppColors.primary;
      case 'fair':
        return AppColors.warning;
      case 'low':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getScoreBandLabel(BuildContext context, String? band) {
    final l10n = AppLocalizations.of(context)!;
    switch (band) {
      case 'veryGood':
        return l10n.qolScoreBandVeryGood;
      case 'good':
        return l10n.qolScoreBandGood;
      case 'fair':
        return l10n.qolScoreBandFair;
      case 'low':
        return l10n.qolScoreBandLow;
      default:
        return '';
    }
  }
}
