import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
/// - "View History" link to see all assessments
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
    return HydraCard(
      onTap: () {
        _trackCardTap();
        context.push('/profile/qol/detail/${latestAssessment.documentId}');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Title + Score badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.favorite,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.qolNavigationTitle,
                    style: AppTextStyles.h2,
                  ),
                ],
              ),
              _ScoreBadge(
                score: latestAssessment.overallScore,
                scoreBand: latestAssessment.scoreBand,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          // Assessment date
          Text(
            l10n.qolAssessedOn(
              DateFormat.yMMMd().format(latestAssessment.date),
            ),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Compact radar chart
          QolRadarChart(
            assessment: latestAssessment,
            isCompact: true,
          ),

          const SizedBox(height: AppSpacing.md),

          // Footer: View History link
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                _trackCardTap();
                context.push('/profile/qol');
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Text(
                  l10n.viewHistory,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
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
                style: AppTextStyles.h2,
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
            scoreValue.toStringAsFixed(0),
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '%',
            style: AppTextStyles.small.copyWith(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreBandColor(String? band) {
    switch (band) {
      case 'veryGood':
        return AppColors.success;
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
}
