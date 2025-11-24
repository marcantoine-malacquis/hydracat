import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/health/models/symptom_granularity.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';
import 'package:hydracat/features/health/widgets/symptoms_entry_dialog.dart';
import 'package:hydracat/features/health/widgets/symptoms_stacked_bar_chart.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:hydracat/providers/symptoms_chart_provider.dart';
import 'package:hydracat/shared/models/monthly_summary.dart';
import 'package:hydracat/shared/widgets/custom_dropdown.dart';
import 'package:hydracat/shared/widgets/widgets.dart';
import 'package:intl/intl.dart';

/// Screen for viewing and managing symptom tracking
///
/// Features (V1):
/// - Empty state for first-time users
/// - FAB for adding new symptom entries
/// - Minimal implementation - no charts/trends yet
class SymptomsScreen extends ConsumerStatefulWidget {
  /// Creates a [SymptomsScreen]
  const SymptomsScreen({super.key});

  @override
  ConsumerState<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends ConsumerState<SymptomsScreen> {
  ScrollController? _scrollController;
  bool _showFab = true;

  /// Static priority order for symptoms
  ///
  /// Matches _symptomPriorityOrder in provider. Used to order dropdown
  /// options consistently with chart ranking logic.
  static const List<String> _symptomPriorityOrder = [
    SymptomType.lethargy,
    SymptomType.suppressedAppetite,
    SymptomType.vomiting,
    SymptomType.injectionSiteReaction,
    SymptomType.constipation,
    SymptomType.diarrhea,
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
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

  void _showAddSymptomsDialog() {
    OverlayService.showFullScreenPopup(
      context: context,
      child: const SymptomsEntryDialog(),
      onDismiss: () {
        // No special cleanup needed
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HydraAppBar(
        title: const Text('Symptoms'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: HydraBackButton(
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: _buildBody(),
      ),
      floatingActionButton: _showFab
          ? HydraExtendedFab(
              onPressed: _showAddSymptomsDialog,
              icon: Icons.add,
              label: 'Add Symptoms',
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              useGlassEffect: true,
            )
          : null,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }

  Widget _buildBody() {
    // Watch providers for data detection
    final summaryAsync = ref.watch(currentMonthSymptomsSummaryProvider);
    final viewModel = ref.watch(symptomsChartDataProvider);

    // Check if we have any symptom data
    final hasData = _hasAnySymptomData(summaryAsync, viewModel);

    if (!hasData) {
      return _buildEmptyState();
    }

    return _buildAnalyticsLayout();
  }

  /// Determines if any symptom data exists
  ///
  /// Returns true if:
  /// - Current month summary has daysWithAnySymptoms > 0, or
  /// - Chart view model has at least one bucket with totalSymptomDays > 0
  bool _hasAnySymptomData(
    AsyncValue<MonthlySummary?> summaryAsync,
    SymptomsChartViewModel? viewModel,
  ) {
    // Check monthly summary
    final summary = summaryAsync.valueOrNull;
    if (summary != null && summary.daysWithAnySymptoms > 0) {
      return true;
    }

    // Check chart buckets
    if (viewModel != null &&
        viewModel.buckets.isNotEmpty &&
        viewModel.buckets.any((bucket) => bucket.totalSymptomDays > 0)) {
      return true;
    }

    return false;
  }

  /// Builds the analytics layout with chart and controls
  Widget _buildAnalyticsLayout() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period header (placeholder for section 4.2-4.3)
          _buildGraphHeader(),
          const SizedBox(height: AppSpacing.sm),
          // Granularity selector (placeholder for section 4.2)
          _buildGranularitySelector(),
          const SizedBox(height: AppSpacing.sm),
          // Symptom selection dropdown
          _buildSymptomSelector(),
          const SizedBox(height: AppSpacing.md),
          // Chart widget
          _buildChartSection(),
          const SizedBox(height: AppSpacing.lg),
          // Optional summary placeholder (for future use)
          // SizedBox(height: AppSpacing.md),
          // Text('Summary placeholder', style: AppTextStyles.body),
        ],
      ),
    );
  }

  /// Builds period navigation header with chevrons and Today button
  Widget _buildGraphHeader() {
    final state = ref.watch(symptomsChartStateProvider);
    final isOnCurrentPeriod = state.isOnCurrentPeriod;
    final periodLabel = _formatPeriodLabel(state);

    return Row(
      children: [
        // Left chevron
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            HapticFeedback.selectionClick();
            ref.read(symptomsChartStateProvider.notifier).previousPeriod();
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
                  ref.read(symptomsChartStateProvider.notifier).nextPeriod();
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
              ref.read(symptomsChartStateProvider.notifier).goToToday();
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
  String _formatPeriodLabel(SymptomsChartState state) {
    return switch (state.granularity) {
      SymptomGranularity.week => _formatWeekLabel(state.weekStart),
      SymptomGranularity.month => DateFormat(
        'MMMM yyyy',
      ).format(state.monthStart),
      SymptomGranularity.year => state.yearStart.year.toString(),
    };
  }

  /// Formats week label as "Nov 4-10, 2025" or "Nov 30 - Dec 6, 2025"
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

  /// Builds granularity selector (Week/Month/Year)
  Widget _buildGranularitySelector() {
    final state = ref.watch(symptomsChartStateProvider);

    return SizedBox(
      width: double.infinity,
      child: HydraSlidingSegmentedControl<SymptomGranularity>(
        value: state.granularity,
        segments: const {
          SymptomGranularity.week: Text('Week'),
          SymptomGranularity.month: Text('Month'),
          SymptomGranularity.year: Text('Year'),
        },
        onChanged: (newGranularity) {
          HapticFeedback.selectionClick();
          ref
              .read(symptomsChartStateProvider.notifier)
              .setGranularity(
                newGranularity,
              );
        },
      ),
    );
  }

  /// Builds symptom selection dropdown (All vs single symptom)
  ///
  /// Allows users to switch between stacked view (All) and single-symptom
  /// view for focused analysis. The dropdown is positioned below the
  /// granularity selector and above the chart.
  Widget _buildSymptomSelector() {
    final state = ref.watch(symptomsChartStateProvider);

    // Build list of dropdown items: All (null) + ordered symptoms
    final items = <String?>[null, ..._symptomPriorityOrder];

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 200, // Fixed width for consistent layout
        child: CustomDropdown<String?>(
          value: state.selectedSymptomKey,
          items: items,
          onChanged: (newKey) {
            HapticFeedback.selectionClick();
            ref
                .read(symptomsChartStateProvider.notifier)
                .setSelectedSymptom(newKey);
          },
          itemBuilder: (key) => Text(
            key == null ? 'All symptoms' : _getSymptomLabel(key),
            style: AppTextStyles.body,
          ),
          labelText: 'Symptom',
          hintText: 'All symptoms',
        ),
      ),
    );
  }

  /// Gets the display label for a symptom key
  ///
  /// Maps symptom keys to human-readable names, matching the labels
  /// used in the chart widget for consistency.
  String _getSymptomLabel(String symptomKey) {
    switch (symptomKey) {
      case SymptomType.vomiting:
        return 'Vomiting';
      case SymptomType.diarrhea:
        return 'Diarrhea';
      case SymptomType.constipation:
        return 'Constipation';
      case SymptomType.lethargy:
        return 'Lethargy';
      case SymptomType.suppressedAppetite:
        return 'Suppressed Appetite';
      case SymptomType.injectionSiteReaction:
        return 'Injection Site Reaction';
      default:
        return symptomKey;
    }
  }

  /// Builds the chart section with SymptomsStackedBarChart
  Widget _buildChartSection() {
    final state = ref.watch(symptomsChartStateProvider);
    return SymptomsStackedBarChart(
      granularity: state.granularity,
      selectedSymptomKey: state.selectedSymptomKey,
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
              Icons.medical_services,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              "Track Your Pet's Symptoms",
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "Monitor daily symptoms to help manage your pet's CKD. "
              'Tracking symptoms like vomiting, diarrhea, and lethargy helps '
              'you and your vet identify patterns and adjust treatment.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
