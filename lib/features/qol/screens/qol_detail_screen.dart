import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/qol/models/qol_assessment.dart';
import 'package:hydracat/features/qol/models/qol_domain.dart';
import 'package:hydracat/features/qol/widgets/qol_interpretation_card.dart';
import 'package:hydracat/features/qol/widgets/qol_radar_chart.dart';
import 'package:hydracat/features/qol/widgets/qol_score_summary_card.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/qol_provider.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_button.dart';
import 'package:hydracat/shared/widgets/cards/hydra_card.dart';
import 'package:hydracat/shared/widgets/layout/layout.dart';

/// Detail screen for viewing a single QoL assessment.
///
/// Displays:
/// - Overall score summary card
/// - Full radar chart visualization
/// - Domain breakdown with individual scores
/// - Trend interpretation (comparison with previous assessment)
/// - Action buttons (Edit, View History)
class QolDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [QolDetailScreen].
  ///
  /// [assessmentId] is the document ID (YYYY-MM-DD format) of the
  /// assessment to display.
  const QolDetailScreen({
    required this.assessmentId,
    super.key,
  });

  /// Assessment document ID to display.
  ///
  /// Format: YYYY-MM-DD
  final String assessmentId;

  @override
  ConsumerState<QolDetailScreen> createState() => _QolDetailScreenState();
}

class _QolDetailScreenState extends ConsumerState<QolDetailScreen> {
  bool _hasTrackedView = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Track screen view once per widget lifecycle
    if (!_hasTrackedView) {
      _hasTrackedView = true;
      _trackScreenView();
    }
  }

  void _trackScreenView() {
    final petId = ref.read(primaryPetProvider)?.id;
    ref
        .read(analyticsServiceDirectProvider)
        .trackQolDetailViewed(
          assessmentDate: widget.assessmentId,
          petId: petId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recentAssessments = ref.watch(recentQolAssessmentsProvider);

    // Find the assessment with matching documentId
    final assessment = recentAssessments.firstWhere(
      (a) => a.documentId == widget.assessmentId,
      orElse: () => throw Exception(
        'Assessment not found: ${widget.assessmentId}',
      ),
    );

    return AppScaffold(
      title: l10n.qolResultsTitle,
      actions: [
        // Edit button in app bar
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () =>
              context.push('/profile/qol/edit/${widget.assessmentId}'),
          tooltip: l10n.edit,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overall score summary card
            QolScoreSummaryCard(assessment: assessment),
            const SizedBox(height: AppSpacing.lg),

            // Full radar chart
            QolRadarChart(assessment: assessment),
            const SizedBox(height: AppSpacing.lg),

            // Domain breakdown section
            _DomainBreakdownSection(assessment: assessment),
            const SizedBox(height: AppSpacing.lg),

            // Trend interpretation
            QolInterpretationCard(assessment: assessment),
            const SizedBox(height: AppSpacing.lg),

            // Action buttons row
            _ActionButtonsRow(assessmentId: widget.assessmentId),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// Widget displaying the breakdown of scores by domain.
class _DomainBreakdownSection extends StatelessWidget {
  const _DomainBreakdownSection({
    required this.assessment,
  });

  final QolAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            l10n.qolDomainScoresTitle,
            style: AppTextStyles.h2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Domain cards
        ...QolDomain.all.map((domain) {
          return _DomainScoreCard(
            assessment: assessment,
            domain: domain,
          );
        }),
      ],
    );
  }
}

/// Individual domain score card with progress indicator.
class _DomainScoreCard extends StatelessWidget {
  const _DomainScoreCard({
    required this.assessment,
    required this.domain,
  });

  final QolAssessment assessment;
  final String domain;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final score = assessment.getDomainScore(domain);
    final answeredCount = assessment.answeredCountByDomain[domain] ?? 0;
    final totalQuestions = QolDomain.questionCounts[domain] ?? 0;

    // Get domain display name
    final displayNameKey = QolDomain.getDisplayNameKey(domain);
    final domainName = displayNameKey != null
        ? _getDomainDisplayName(l10n, displayNameKey)
        : domain;

    // Handle low confidence (null score) vs valid score
    if (score == null) {
      return _buildLowConfidenceCard(
        l10n,
        domainName,
        answeredCount,
        totalQuestions,
      );
    }

    return _buildScoreCard(
      l10n,
      domainName,
      score,
      answeredCount,
      totalQuestions,
    );
  }

  /// Builds card for domain with low confidence (insufficient data).
  Widget _buildLowConfidenceCard(
    AppLocalizations l10n,
    String domainName,
    int answeredCount,
    int totalQuestions,
  ) {
    return HydraCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                domainName,
                style: AppTextStyles.h3,
              ),
              Text(
                l10n.qolInsufficientData,
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.qolQuestionsAnswered(answeredCount, totalQuestions),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds card for domain with valid score.
  Widget _buildScoreCard(
    AppLocalizations l10n,
    String domainName,
    double score,
    int answeredCount,
    int totalQuestions,
  ) {
    return HydraCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                domainName,
                style: AppTextStyles.h3,
              ),
              Text(
                '${score.round()}',
                style: AppTextStyles.h2.copyWith(
                  color: _getScoreBandColor(score),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.qolQuestionsAnswered(answeredCount, totalQuestions),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            child: LinearProgressIndicator(
              value: score / 100.0,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getScoreBandColor(score),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gets the localized domain display name.
  String _getDomainDisplayName(AppLocalizations l10n, String key) {
    switch (key) {
      case 'qolDomainVitality':
        return l10n.qolDomainVitality;
      case 'qolDomainComfort':
        return l10n.qolDomainComfort;
      case 'qolDomainEmotional':
        return l10n.qolDomainEmotional;
      case 'qolDomainAppetite':
        return l10n.qolDomainAppetite;
      case 'qolDomainTreatmentBurden':
        return l10n.qolDomainTreatmentBurden;
      default:
        return key;
    }
  }

  /// Gets the color based on score value.
  Color _getScoreBandColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.primary;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }
}

/// Action buttons row for navigation.
class _ActionButtonsRow extends StatelessWidget {
  const _ActionButtonsRow({
    required this.assessmentId,
  });

  final String assessmentId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: [
        // Edit button (secondary)
        Expanded(
          child: HydraButton(
            onPressed: () => context.push('/profile/qol/edit/$assessmentId'),
            variant: HydraButtonVariant.secondary,
            child: Text(l10n.edit),
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // View History button (primary)
        Expanded(
          child: HydraButton(
            onPressed: () => context.push('/profile/qol'),
            child: Text(l10n.viewHistory),
          ),
        ),
      ],
    );
  }
}
