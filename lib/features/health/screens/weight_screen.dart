import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/core/utils/weight_utils.dart';
import 'package:hydracat/features/health/exceptions/health_exceptions.dart';
import 'package:hydracat/features/health/models/health_parameter.dart';
import 'package:hydracat/features/health/models/weight_granularity.dart';
import 'package:hydracat/features/health/widgets/weight_entry_dialog.dart';
import 'package:hydracat/features/health/widgets/weight_line_chart.dart';
import 'package:hydracat/features/health/widgets/weight_stat_card.dart';
import 'package:hydracat/providers/weight_provider.dart';
import 'package:hydracat/providers/weight_unit_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';
import 'package:intl/intl.dart';

/// Screen for viewing and managing weight tracking
///
/// Features:
/// - Empty state for first-time users
/// - Loading state while fetching data
/// - Error state with retry button
/// - FAB for adding new weight entries
class WeightScreen extends ConsumerStatefulWidget {
  /// Creates a [WeightScreen]
  const WeightScreen({super.key});

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen> {
  ScrollController? _scrollController;
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    // Load weight data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(weightProvider.notifier).loadInitialData();
    });
  }

  void _handleScroll() {
    if (_scrollController == null || !_scrollController!.hasClients) return;

    final direction = _scrollController!.position.userScrollDirection;

    // Hide FAB when scrolling down
    if (direction == ScrollDirection.reverse) {
      if (_showFab) {
        setState(() {
          _showFab = false;
        });
      }
    }
    // Show FAB when scrolling up
    else if (direction == ScrollDirection.forward) {
      if (!_showFab) {
        setState(() {
          _showFab = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  Future<void> _showAddWeightDialog() async {
    final result = await showHydraBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.background,
      builder: (sheetContext) => const HydraBottomSheet(
        backgroundColor: AppColors.background,
        child: WeightEntryDialog(),
      ),
    );

    if (result != null && mounted) {
      final success = await ref
          .read(weightProvider.notifier)
          .logWeight(
            date: result['date'] as DateTime,
            weightKg: result['weightKg'] as double,
            notes: result['notes'] as String?,
          );

      if (success && mounted) {
        HydraSnackBar.showSuccess(context, 'Weight logged successfully');
      } else if (mounted) {
        final error = ref.read(weightProvider).error;
        HydraSnackBar.showError(
          context,
          error?.message ?? 'Failed to log weight',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weightState = ref.watch(weightProvider);
    final platform = Theme.of(context).platform;
    final isIOS =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HydraAppBar(
        title: const Text('Weight'),
        leading: HydraBackButton(
          onPressed: () => context.pop(),
        ),
        actions: isIOS
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _showAddWeightDialog();
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
      body: weightState.isLoading && weightState.historyEntries.isEmpty
          ? const _LoadingState()
          : weightState.error != null && weightState.historyEntries.isEmpty
          ? _ErrorState(error: weightState.error)
          : weightState.historyEntries.isEmpty
          ? _EmptyState(onAddWeight: _showAddWeightDialog)
          : _ContentView(
              state: weightState,
              scrollController: _scrollController,
              onShowAddDialog: _showAddWeightDialog,
              onShowEditDialog: _showEditWeightDialog,
              onDeleteWeight: _deleteWeight,
            ),
      // On iOS, use navigation bar button instead of FAB
      // On Android, show solid FAB (no glass effect)
      floatingActionButton: isIOS
          ? null
          : (_showFab
                ? HydraExtendedFab(
                    onPressed: _showAddWeightDialog,
                    icon: Icons.add,
                    label: 'Add Weight',
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                  )
                : null),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }




  /// Shows dialog to edit an existing weight entry
  Future<void> _showEditWeightDialog(HealthParameter entry) async {
    final result = await showHydraBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.background,
      builder: (sheetContext) => HydraBottomSheet(
        backgroundColor: AppColors.background,
        child: WeightEntryDialog(existingEntry: entry),
      ),
    );

    if (result != null && mounted) {
      final success = await ref
          .read(weightProvider.notifier)
          .updateWeight(
            oldDate: entry.date,
            oldWeightKg: entry.weight!,
            newDate: result['date'] as DateTime,
            newWeightKg: result['weightKg'] as double,
            newNotes: result['notes'] as String?,
          );

      if (success && mounted) {
        HydraSnackBar.showSuccess(context, 'Weight updated successfully');
      }
    }
  }

  /// Deletes a weight entry
  Future<void> _deleteWeight(DateTime date) async {
    // Provide haptic feedback
    unawaited(HapticFeedback.mediumImpact());

    final success = await ref
        .read(weightProvider.notifier)
        .deleteWeight(
          date: date,
        );

    if (mounted) {
      if (success) {
        HydraSnackBar.showSuccess(context, 'Weight entry deleted');
      } else {
        final error = ref.read(weightProvider).error;
        HydraSnackBar.showError(
          context,
          error?.message ?? 'Failed to delete weight',
        );
      }
    }
  }
}

/// Loading state widget for weight screen
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HydraProgressIndicator(
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Loading weight data...',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state widget when no weight entries exist
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onAddWeight,
  });

  final VoidCallback onAddWeight;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_weight,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              "Track Your Pet's Weight",
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "Start monitoring weight changes to help manage your pet's CKD. "
              'Regular weighing helps you and your vet track progress.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onAddWeight,
              icon: const Icon(Icons.add),
              label: const Text('Log Your First Weight'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state widget for weight screen
class _ErrorState extends ConsumerWidget {
  const _ErrorState({
    required this.error,
  });

  final HealthException? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to Load Weight Data',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error?.message ?? 'An unexpected error occurred',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: () {
                ref.read(weightProvider.notifier).loadInitialData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Content view widget with graph controls and chart
class _ContentView extends ConsumerWidget {
  const _ContentView({
    required this.state,
    required this.scrollController,
    required this.onShowAddDialog,
    required this.onShowEditDialog,
    required this.onDeleteWeight,
  });

  final WeightState state;
  final ScrollController? scrollController;
  final VoidCallback onShowAddDialog;
  final void Function(HealthParameter) onShowEditDialog;
  final Future<void> Function(DateTime) onDeleteWeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUnit = ref.watch(weightUnitProvider);

    return SafeArea(
      child: Stack(
        children: [
          HydraRefreshIndicator(
            onRefresh: () async {
              await ref.read(weightProvider.notifier).refreshData();
            },
            child: SingleChildScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weight change indicator at the top
                  if (state.graphData.isEmpty)
                    const WeightStatCard.empty()
                  else if (state.graphData.length == 1)
                    // Show stat card for single data point
                    WeightStatCard(
                      weight: currentUnit == 'kg'
                          ? state.graphData.first.weightKg
                          : state.graphData.first.weightLbs,
                      unit: currentUnit,
                    )
                  else
                    // Calculate change from previous period
                    () {
                      final sorted = [...state.graphData]
                        ..sort((a, b) => a.date.compareTo(b.date));
                      final latest = sorted.last.weightKg;
                      final previous = sorted[sorted.length - 2].weightKg;
                      final changeKg = latest - previous;
                      final change = currentUnit == 'kg'
                          ? changeKg
                          : WeightUtils.convertKgToLbs(changeKg);

                      return WeightStatCard(
                        weight: currentUnit == 'kg'
                            ? sorted.last.weightKg
                            : sorted.last.weightLbs,
                        unit: currentUnit,
                        change: change,
                      );
                    }(),
                  const SizedBox(height: AppSpacing.lg),
                  // Graph controls and chart together
                  _GranularitySelector(state: state),
                  const SizedBox(height: AppSpacing.sm),
                  _GraphHeader(state: state),
                  const SizedBox(height: AppSpacing.md),
                  // Show chart - either empty state or with data
                  if (state.graphData.isEmpty)
                    WeightLineChart(
                      dataPoints: const [],
                      unit: currentUnit,
                      granularity: state.granularity,
                      showEmptyState: true,
                    )
                  else
                    WeightLineChart(
                      dataPoints: state.graphData,
                      unit: currentUnit,
                      granularity: state.granularity,
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  _HistorySection(
                    state: state,
                    currentUnit: currentUnit,
                    onShowEditDialog: onShowEditDialog,
                    onDeleteWeight: onDeleteWeight,
                  ),
                ],
              ),
            ),
          ),
          // Show loading overlay when refreshing
          if (state.isRefreshing)
            ColoredBox(
              color: AppColors.background.withValues(alpha: 0.7),
              child: const Center(
                child: HydraProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Granularity selector widget (Week/Month/Year)
class _GranularitySelector extends ConsumerWidget {
  const _GranularitySelector({
    required this.state,
  });

  final WeightState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: HydraSlidingSegmentedControl<WeightGranularity>(
        value: state.granularity,
        segments: const {
          WeightGranularity.week: Text('Week'),
          WeightGranularity.month: Text('Month'),
          WeightGranularity.year: Text('Year'),
        },
        onChanged: (newGranularity) {
          HapticFeedback.selectionClick();
          ref.read(weightProvider.notifier).setGranularity(newGranularity);
        },
      ),
    );
  }
}

/// Graph header widget with period navigation
class _GraphHeader extends ConsumerWidget {
  const _GraphHeader({
    required this.state,
  });

  final WeightState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnCurrentPeriod =
        ref.read(weightProvider.notifier).isOnCurrentPeriod;
    final periodLabel = _formatPeriodLabel(state);

    return Row(
      children: [
        // Left chevron
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            HapticFeedback.selectionClick();
            ref.read(weightProvider.notifier).previousPeriod();
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Previous ${state.granularity.label.toLowerCase()}',
        ),
        const SizedBox(width: AppSpacing.xs),
        // Period label
        Text(
          periodLabel,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(width: AppSpacing.xs),
        // Right chevron
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isOnCurrentPeriod
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  ref.read(weightProvider.notifier).nextPeriod();
                },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: isOnCurrentPeriod
              ? 'Cannot view future'
              : 'Next ${state.granularity.label.toLowerCase()}',
        ),
        const Spacer(),
        // Today button (only when not on current period)
        if (!isOnCurrentPeriod)
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(weightProvider.notifier).goToToday();
            },
            child: Text(
              'Today',
              style: AppTextStyles.buttonSecondary.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  /// Formats period label based on granularity
  String _formatPeriodLabel(WeightState state) {
    return switch (state.granularity) {
      WeightGranularity.week => _formatWeekLabel(state.periodStart),
      WeightGranularity.month => DateFormat('MMMM yyyy').format(
          state.periodStart,
        ),
      WeightGranularity.year => state.periodStart.year.toString(),
    };
  }

  /// Formats week label as "Nov 4-10, 2025"
  String _formatWeekLabel(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final sameMonth = weekStart.month == weekEnd.month;

    if (sameMonth) {
      return '${DateFormat('MMM d').format(weekStart)}-'
          '${DateFormat('d, yyyy').format(weekEnd)}';
    } else {
      return '${DateFormat('MMM d').format(weekStart)} - '
          '${DateFormat('MMM d, yyyy').format(weekEnd)}';
    }
  }
}

/// History section widget displaying paginated weight entries
class _HistorySection extends ConsumerWidget {
  const _HistorySection({
    required this.state,
    required this.currentUnit,
    required this.onShowEditDialog,
    required this.onDeleteWeight,
  });

  final WeightState state;
  final String currentUnit;
  final void Function(HealthParameter) onShowEditDialog;
  final Future<void> Function(DateTime) onDeleteWeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.historyEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Entries',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: AppSpacing.md),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.historyEntries.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
          itemBuilder: (context, index) {
            final entry = state.historyEntries[index];
            final displayWeight = currentUnit == 'kg'
                ? entry.weight!
                : WeightUtils.convertKgToLbs(entry.weight!);

            return Slidable(
              key: Key('weight_${entry.date.millisecondsSinceEpoch}'),
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                extentRatio: 0.25,
                children: [
                  SlidableAction(
                    onPressed: (context) => onDeleteWeight(entry.date),
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('MMM dd, yyyy').format(entry.date),
                            style: AppTextStyles.body,
                          ),
                          if (entry.notes != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              entry.notes!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      '${displayWeight.toStringAsFixed(2)} $currentUnit',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => onShowEditDialog(entry),
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
          },
        ),
        if (state.hasMore) ...[
          const SizedBox(height: AppSpacing.md),
          Center(
            child: OutlinedButton(
              onPressed: state.isLoading
                  ? null
                  : () => ref.read(weightProvider.notifier).loadMoreHistory(),
              child: state.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: HydraProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load More'),
            ),
          ),
        ],
      ],
    );
  }
}
