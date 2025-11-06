import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/health/models/weight_granularity.dart';
import 'package:hydracat/features/health/widgets/weight_entry_dialog.dart';
import 'package:hydracat/features/health/widgets/weight_line_chart.dart';
import 'package:hydracat/features/health/widgets/weight_stat_card.dart';
import 'package:hydracat/providers/weight_provider.dart';
import 'package:hydracat/providers/weight_unit_provider.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_fab.dart';
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
  @override
  void initState() {
    super.initState();
    // Load weight data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(weightProvider.notifier).loadInitialData();
    });
  }

  Future<void> _showAddWeightDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const WeightEntryDialog(),
    );

    if (result != null && mounted) {
      final success = await ref.read(weightProvider.notifier).logWeight(
        date: result['date'] as DateTime,
        weightKg: result['weightKg'] as double,
        notes: result['notes'] as String?,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weight logged successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else if (mounted) {
        final error = ref.read(weightProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error?.message ?? 'Failed to log weight'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weightState = ref.watch(weightProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Weight'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: weightState.isLoading && weightState.historyEntries.isEmpty
          ? _buildLoadingState()
          : weightState.error != null && weightState.historyEntries.isEmpty
              ? _buildErrorState()
              : weightState.historyEntries.isEmpty
                  ? _buildEmptyState()
                  : _buildContentView(weightState),
      floatingActionButton: HydraFab(
        onPressed: _showAddWeightDialog,
        icon: Icons.scale,
        tooltip: 'Add Weight',
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
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
              onPressed: _showAddWeightDialog,
              icon: const Icon(Icons.add),
              label: const Text('Log Your First Weight'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final error = ref.read(weightProvider).error;

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

  /// Content view with graph card
  Widget _buildContentView(WeightState state) {
    final currentUnit = ref.watch(weightUnitProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _buildGraphCard(state, currentUnit),
      ),
    );
  }

  /// Graph card showing weight trend or single weight stat
  Widget _buildGraphCard(WeightState state, String currentUnit) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGranularitySelector(state),
          const SizedBox(height: AppSpacing.sm),
          _buildGraphHeader(state),
          const SizedBox(height: AppSpacing.md),
          if (state.graphData.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Log more weights to see your trend',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else if (state.graphData.length == 1)
            // Show stat card for single data point
            WeightStatCard(
              weight: currentUnit == 'kg'
                  ? state.graphData.first.weightKg
                  : state.graphData.first.weightLbs,
              date: state.graphData.first.date,
              unit: currentUnit,
            )
          else
            // Show line chart for 2+ data points
            WeightLineChart(
              dataPoints: state.graphData,
              unit: currentUnit,
              granularity: state.granularity,
            ),
        ],
      ),
    );
  }

  /// Builds period navigation header with chevrons and Today button
  Widget _buildGraphHeader(WeightState state) {
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
        const SizedBox(width: AppSpacing.sm),
        // Period label
        Expanded(
          child: Text(
            periodLabel,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
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

  /// Builds granularity selector (Week/Month/Year)
  Widget _buildGranularitySelector(WeightState state) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<WeightGranularity>(
        segments: const [
          ButtonSegment<WeightGranularity>(
            value: WeightGranularity.week,
            label: Text('Week'),
          ),
          ButtonSegment<WeightGranularity>(
            value: WeightGranularity.month,
            label: Text('Month'),
          ),
          ButtonSegment<WeightGranularity>(
            value: WeightGranularity.year,
            label: Text('Year'),
          ),
        ],
        selected: {state.granularity},
        onSelectionChanged: (Set<WeightGranularity> newSelection) {
          HapticFeedback.selectionClick();
          if (newSelection.isNotEmpty) {
            ref
                .read(weightProvider.notifier)
                .setGranularity(newSelection.first);
          }
        },
        showSelectedIcon: false,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary;
              }
              return Colors.transparent;
            },
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return AppColors.textPrimary;
            },
          ),
        ),
      ),
    );
  }

  /// Formats period label based on granularity
  String _formatPeriodLabel(WeightState state) {
    return switch (state.granularity) {
      WeightGranularity.week => _formatWeekLabel(state.periodStart),
      WeightGranularity.month =>
        DateFormat('MMMM yyyy').format(state.periodStart),
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
