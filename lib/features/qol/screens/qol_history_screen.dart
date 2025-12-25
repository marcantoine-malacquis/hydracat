import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/qol/models/qol_assessment.dart';
import 'package:hydracat/features/qol/widgets/qol_trend_line_chart.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/qol_provider.dart';
import 'package:hydracat/shared/widgets/buttons/buttons.dart';
import 'package:hydracat/shared/widgets/navigation/navigation.dart';
import 'package:intl/intl.dart' as intl;

/// Displays the history of QoL assessments with trend visualization.
///
/// Features:
/// - Trend line chart at top (when ≥2 assessments)
/// - Scrollable list of historical assessments
/// - Pull-to-refresh
/// - Empty state for new users
/// - "+ Add" pill button (iOS) or FAB (Android) to add new assessment
/// - Tap to view details
/// - Long-press for edit/delete options
class QolHistoryScreen extends ConsumerStatefulWidget {
  /// Creates a QolHistoryScreen.
  const QolHistoryScreen({super.key});

  @override
  ConsumerState<QolHistoryScreen> createState() => _QolHistoryScreenState();
}

class _QolHistoryScreenState extends ConsumerState<QolHistoryScreen> {
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
    final assessments = ref.read(recentQolAssessmentsProvider);
    final petId = ref.read(primaryPetProvider)?.id;
    ref.read(analyticsServiceDirectProvider).trackQolHistoryViewed(
          assessmentCount: assessments.length,
          petId: petId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final assessments = ref.watch(recentQolAssessmentsProvider);
    final isLoading = ref.watch(isLoadingQolProvider);
    final platform = Theme.of(context).platform;
    final isIOS =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HydraAppBar(
        title: Text(l10n.qolHistoryTitle),
        actions: isIOS
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context.push('/profile/qol/new');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.add,
                            size: 18,
                            color: AppColors.primaryDark,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(qolProvider.notifier)
                .loadRecentAssessments(forceRefresh: true);
          },
          child: _buildBody(context, assessments, isLoading, l10n),
        ),
      ),
      floatingActionButton: isIOS
          ? null
          : HydraFab(
              onPressed: () => context.push('/profile/qol/new'),
              icon: Icons.add,
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<QolAssessment> assessments,
    bool isLoading,
    AppLocalizations l10n,
  ) {
    // Loading state (initial load)
    if (isLoading && assessments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Empty state
    if (assessments.isEmpty) {
      return _EmptyState(
        onStartAssessment: () => context.push('/profile/qol/new'),
      );
    }

    // Content with assessments
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Trend chart (only show if ≥2 assessments)
        if (assessments.length >= 2) ...[
          const QolTrendLineChart(),
          const SizedBox(height: AppSpacing.xl),
        ],

        // History section title
        Text(
          l10n.qolHistorySectionTitle,
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: AppSpacing.md),

        // Assessment cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: assessments.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
          itemBuilder: (context, index) {
            final assessment = assessments[index];
            return _QolHistoryCard(
              key: ValueKey(assessment.id),
              assessment: assessment,
              onTap: () => context.push(
                '/profile/qol/detail/${assessment.documentId}',
              ),
              onEdit: () => context.push(
                '/profile/qol/edit/${assessment.documentId}',
              ),
              onDelete: () => _confirmDelete(context, ref, assessment, l10n),
            );
          },
        ),
      ],
    );
  }

  /// Show confirmation dialog before deleting assessment
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    QolAssessment assessment,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.qolDeleteConfirmTitle),
        content: Text(
          l10n.qolDeleteConfirmMessage(
            intl.DateFormat.yMMMd().format(assessment.date),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      if (!context.mounted) return;
      try {
        await ref.read(qolProvider.notifier).deleteAssessment(assessment.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.qolDeleteSuccess)),
          );
        }
      } on Exception {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.qolDeleteError),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

/// Empty state widget when no assessments exist
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStartAssessment});

  final VoidCallback onStartAssessment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_border,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.qolEmptyStateTitle,
              style: AppTextStyles.h1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.qolEmptyStateMessage,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            HydraButton(
              onPressed: onStartAssessment,
              child: Text(l10n.qolStartFirstAssessment),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual history card for an assessment
class _QolHistoryCard extends StatelessWidget {
  const _QolHistoryCard({
    required this.assessment,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final QolAssessment assessment;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onLongPress: () => _showContextMenu(context, l10n),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Date column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    intl.DateFormat('MMM dd, yyyy').format(assessment.date),
                    style: AppTextStyles.body,
                  ),
                  if (!assessment.isComplete) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.qolIncomplete,
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Score badge
            _ScoreBadge(
              score: assessment.overallScore,
              scoreBand: assessment.scoreBand,
            ),

            const SizedBox(width: AppSpacing.xs),

            // Edit icon
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: onEdit,
              tooltip: 'Edit',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  /// Show context menu for edit/delete options
  void _showContextMenu(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.edit),
              onTap: () {
                Navigator.of(context).pop();
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: Text(
                l10n.delete,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge displaying the overall score with color coding
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
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.textTertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          l10n.qolInsufficientData,
          style: AppTextStyles.small.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final color = _getScoreBandColor(scoreBand);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color,
          width: 1.5,
        ),
      ),
      child: Text(
        '${_getScoreBandLabel(context, scoreBand)} '
        '(${score!.toStringAsFixed(0)}%)',
        style: AppTextStyles.body.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
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
