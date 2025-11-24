import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/constants/symptom_colors.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/health/models/symptom_bucket.dart';
import 'package:hydracat/features/health/models/symptom_granularity.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';
import 'package:hydracat/providers/symptoms_chart_provider.dart';
import 'package:intl/intl.dart';

/// Stacked bar chart widget for visualizing symptom counts over time
///
/// Displays symptom data as stacked vertical bars with:
/// - Support for week/month/year granularity
/// - All symptoms (stacked) or single symptom view
/// - Interactive tooltips with period labels and symptom breakdowns
/// - Legend (to be implemented in section 3.5)
///
/// This widget is driven by [symptomsChartStateProvider] and consumes
/// [symptomsChartDataProvider] for chart data. The widget expects to be
/// constructed from SymptomsScreen with props derived from the chart state:
/// - [granularity] from [SymptomsChartState.granularity]
/// - [selectedSymptomKey] from [SymptomsChartState.selectedSymptomKey]
///
/// Example:
/// ```dart
/// final state = ref.watch(symptomsChartStateProvider);
/// SymptomsStackedBarChart(
///   granularity: state.granularity,
///   selectedSymptomKey: state.selectedSymptomKey,
/// )
/// ```
class SymptomsStackedBarChart extends ConsumerStatefulWidget {
  /// Creates a [SymptomsStackedBarChart]
  const SymptomsStackedBarChart({
    required this.granularity,
    required this.selectedSymptomKey,
    super.key,
  });

  /// Current graph granularity (week/month/year)
  final SymptomGranularity granularity;

  /// Selected symptom key for single-symptom view
  ///
  /// - `null` means "All symptoms" (stacked view)
  /// - Non-null is a specific symptom key (e.g., `SymptomType.vomiting`)
  final String? selectedSymptomKey;

  @override
  ConsumerState<SymptomsStackedBarChart> createState() =>
      _SymptomsStackedBarChartState();
}

class _SymptomsStackedBarChartState
    extends ConsumerState<SymptomsStackedBarChart> {
  /// Fixed chart height matching FluidVolumeBarChart
  static const double _chartHeight = 200;

  /// Currently selected bar index (null when no bar is touched)
  int? _touchedBarGroupIndex;

  /// Last touch position from fl_chart (for tooltip positioning)
  Offset? _touchPosition;

  @override
  Widget build(BuildContext context) {
    // Watch chart state provider (for future use in sections 3.2-3.5)
    final chartState = ref.watch(symptomsChartStateProvider);

    // Watch chart data provider for view model
    final viewModel = ref.watch(symptomsChartDataProvider);

    // Loading state: show placeholder with fixed height
    if (viewModel == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: SizedBox(
          height: _chartHeight,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    // Empty state: no buckets or all zero
    if (viewModel.buckets.isEmpty ||
        viewModel.buckets.every(
          (bucket) => bucket.totalSymptomDays == 0,
        )) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          height: _chartHeight,
          child: Center(
            child: Text(
              'No symptom data for this period',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    // Non-empty data: render chart structure with tooltip overlay
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: _chartHeight,
        child: Stack(
          children: [
            // Base layer: chart and legend
            Column(
              children: [
                Expanded(
                  child: _buildChartBody(viewModel, chartState),
                ),
                // Legend placeholder (will be implemented in section 3.5)
                _buildLegendPlaceholder(viewModel),
              ],
            ),
            // Tooltip overlay (appears when a bar is tapped)
            if (_touchedBarGroupIndex != null &&
                _touchPosition != null &&
                _touchedBarGroupIndex! < viewModel.buckets.length)
              _buildTooltip(
                viewModel,
                viewModel.buckets[_touchedBarGroupIndex!],
                _touchedBarGroupIndex!,
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the main chart body area
  ///
  /// Hosts the fl_chart BarChart widget with stacked or single-symptom
  /// rendering based on selectedSymptomKey. Includes custom touch handling
  /// for tooltip interaction.
  Widget _buildChartBody(
    SymptomsChartViewModel viewModel,
    SymptomsChartState chartState,
  ) {
    final isStackedMode = widget.selectedSymptomKey == null;
    final maxY = _computeMaxY(viewModel, isStackedMode);
    final barGroups = _buildBarGroups(viewModel, isStackedMode);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        groupsSpace: 0,
        maxY: maxY,
        minY: 0,
        barTouchData: _buildTouchData(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _computeYAxisInterval(maxY),
              getTitlesWidget: (value, meta) {
                // Only show integer labels
                if (value != value.roundToDouble()) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= viewModel.buckets.length) {
                  return const SizedBox.shrink();
                }
                final bucket = viewModel.buckets[index];
                final label = _formatXAxisLabel(bucket, widget.granularity);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: _computeYAxisInterval(maxY),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.border.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: AppColors.border),
            left: BorderSide(color: AppColors.border),
          ),
        ),
        barGroups: barGroups,
      ),
    );
  }

  /// Computes the maximum Y-axis value with headroom
  ///
  /// For stacked mode: uses max of bucket.totalSymptomDays across all
  /// buckets. For single-symptom mode: uses max of the selected symptom
  /// count across buckets. Adds ~15% headroom and ensures minimum of 1.
  double _computeMaxY(
    SymptomsChartViewModel viewModel,
    bool isStackedMode,
  ) {
    if (viewModel.buckets.isEmpty) {
      return 1;
    }

    var maxValue = 0.0;

    if (isStackedMode) {
      // Stacked mode: find max totalSymptomDays
      for (final bucket in viewModel.buckets) {
        maxValue = maxValue > bucket.totalSymptomDays
            ? maxValue
            : bucket.totalSymptomDays.toDouble();
      }
    } else {
      // Single-symptom mode: find max count for selected symptom
      for (final bucket in viewModel.buckets) {
        final count = (bucket.daysWithSymptom[widget.selectedSymptomKey] ?? 0)
            .toDouble();
        maxValue = maxValue > count ? maxValue : count;
      }
    }

    // Add 15% headroom and ensure minimum of 1
    final withHeadroom = maxValue * 1.15;
    return withHeadroom < 1.0 ? 1.0 : withHeadroom;
  }

  /// Computes a nice Y-axis interval for grid lines and labels
  ///
  /// Returns intervals like 1, 2, 5, 10, etc. based on maxY value.
  double _computeYAxisInterval(double maxY) {
    if (maxY <= 2) return 1;
    if (maxY <= 5) return 2;
    if (maxY <= 10) return 5;
    if (maxY <= 20) return 5;
    if (maxY <= 50) return 10;
    return (maxY / 5).ceilToDouble();
  }

  /// Formats X-axis label based on granularity and bucket
  ///
  /// - Week: Short day abbreviation (Mon, Tue, etc.)
  /// - Month: Week range or week number
  /// - Year: 3-letter month (Jan, Feb, etc.)
  String _formatXAxisLabel(
    SymptomBucket bucket,
    SymptomGranularity granularity,
  ) {
    return switch (granularity) {
      SymptomGranularity.week => DateFormat('EEE').format(bucket.start),
      SymptomGranularity.month => () {
        // Show week range (e.g., "3-9" for Nov 3-9)
        final startDay = bucket.start.day;
        final endDay = bucket.end.day;
        if (startDay == endDay) {
          return startDay.toString();
        }
        return '$startDay-$endDay';
      }(),
      SymptomGranularity.year => DateFormat('MMM').format(bucket.start),
    };
  }

  /// Builds bar groups for the chart
  ///
  /// Returns a list of BarChartGroupData, one per bucket.
  /// In stacked mode, each bar has multiple stacked segments.
  /// In single-symptom mode, each bar has a single segment.
  List<BarChartGroupData> _buildBarGroups(
    SymptomsChartViewModel viewModel,
    bool isStackedMode,
  ) {
    return viewModel.buckets.asMap().entries.map((entry) {
      final index = entry.key;
      final bucket = entry.value;

      if (isStackedMode) {
        return _buildStackedBarGroup(bucket, index, viewModel);
      } else {
        return _buildSingleSymptomBarGroup(bucket, index);
      }
    }).toList();
  }

  /// Builds a stacked bar group (All symptoms mode)
  ///
  /// Creates a BarChartGroupData with a single BarChartRodData containing
  /// stacked segments for visible symptoms plus an optional "Other" segment.
  BarChartGroupData _buildStackedBarGroup(
    SymptomBucket bucket,
    int index,
    SymptomsChartViewModel viewModel,
  ) {
    final stackItems = <BarChartRodStackItem>[];
    var runningTotal = 0.0;

    // Add segments for each visible symptom
    for (final symptomKey in viewModel.visibleSymptoms) {
      final count = (bucket.daysWithSymptom[symptomKey] ?? 0).toDouble();
      if (count > 0) {
        stackItems.add(
          BarChartRodStackItem(
            runningTotal,
            runningTotal + count,
            SymptomColors.colorForSymptom(symptomKey),
          ),
        );
        runningTotal += count;
      }
    }

    // Add "Other" segment if needed
    if (viewModel.hasOther) {
      final visibleTotal = runningTotal;
      final otherCount = bucket.totalSymptomDays - visibleTotal;
      if (otherCount > 0) {
        stackItems.add(
          BarChartRodStackItem(
            runningTotal,
            runningTotal + otherCount,
            SymptomColors.colorForOther(),
          ),
        );
        runningTotal += otherCount;
      }
    }

    // If no stack items (all zeros), create a transparent placeholder
    if (stackItems.isEmpty) {
      stackItems.add(
        BarChartRodStackItem(
          0,
          0,
          Colors.transparent,
        ),
      );
    }

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: runningTotal,
          width: 40,
          borderRadius: BorderRadius.circular(8),
          rodStackItems: stackItems,
        ),
      ],
    );
  }

  /// Builds a single-symptom bar group
  ///
  /// Creates a BarChartGroupData with a single BarChartRodData showing
  /// only the count for the selected symptom.
  BarChartGroupData _buildSingleSymptomBarGroup(
    SymptomBucket bucket,
    int index,
  ) {
    final count = (bucket.daysWithSymptom[widget.selectedSymptomKey] ?? 0)
        .toDouble();

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: count,
          width: 40,
          borderRadius: BorderRadius.circular(8),
          color: SymptomColors.colorForSymptom(widget.selectedSymptomKey!),
        ),
      ],
    );
  }

  /// Configures touch interaction behavior
  ///
  /// Handles tap events to show/hide tooltips with haptic feedback.
  BarTouchData _buildTouchData() {
    return BarTouchData(
      enabled: true,
      handleBuiltInTouches: false, // Custom touch handling
      touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
        setState(() {
          if (event is FlTapDownEvent && response?.spot != null) {
            HapticFeedback.selectionClick(); // Gentle tap feedback
            _touchedBarGroupIndex = response!.spot!.touchedBarGroupIndex;
            _touchPosition = event.localPosition; // Actual pixel position
          } else if (event is FlTapUpEvent || event is FlTapCancelEvent) {
            _touchedBarGroupIndex = null;
            _touchPosition = null;
          }
        });
      },
    );
  }

  /// Builds tooltip positioned based on bar index and touch location
  ///
  /// Returns an empty widget if:
  /// - Touch position is null
  /// - Bucket has no symptom data (empty/zero buckets)
  /// - Bar index is out of range (guarded in build method)
  Widget _buildTooltip(
    SymptomsChartViewModel viewModel,
    SymptomBucket bucket,
    int barIndex,
  ) {
    if (_touchPosition == null) return const SizedBox.shrink();

    // Don't show tooltip for empty buckets (edge case: zero-data buckets)
    final isStackedMode = widget.selectedSymptomKey == null;
    final hasData = isStackedMode
        ? bucket.totalSymptomDays > 0
        : (bucket.daysWithSymptom[widget.selectedSymptomKey] ?? 0) > 0;

    if (!hasData) return const SizedBox.shrink();

    // Smart positioning: left half of bars → tooltip on right,
    // right half → left
    final totalBars = viewModel.buckets.length;
    final showOnRight = barIndex < (totalBars / 2);

    // Use actual touch position from fl_chart
    final screenWidth = MediaQuery.of(context).size.width;

    // Build tooltip content
    final periodLabel = _formatTooltipPeriodLabel(bucket);
    final totalDays = bucket.totalSymptomDays;
    final symptomRows = _buildSymptomTooltipRows(bucket, viewModel);

    return Positioned(
      left: showOnRight ? _touchPosition!.dx + 8 : null,
      right: !showOnRight ? screenWidth - _touchPosition!.dx + 8 : null,
      top: _touchPosition!.dy - 40, // Position above touch point
      child: TweenAnimationBuilder<double>(
        key: ValueKey('symptom-tooltip-$barIndex-${bucket.start}'),
        tween: Tween<double>(begin: 0.9, end: 1),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        builder: (context, scale, child) {
          final opacity = ((scale - 0.9) / 0.1).clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              alignment: showOnRight
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: child,
            ),
          );
        },
        child: Semantics(
          label: _buildTooltipSemanticsLabel(
            periodLabel,
            totalDays,
            symptomRows,
          ),
          child: _SymptomsTooltipCard(
            periodLabel: periodLabel,
            totalSymptomDays: totalDays,
            symptomRows: symptomRows,
            pointsLeft: showOnRight,
          ),
        ),
      ),
    );
  }

  /// Formats the period label for tooltip based on granularity
  ///
  /// - Week: "Mon 15 Jan" format
  /// - Month: "Week of Nov 3–9" format
  /// - Year: "Mar 2025" format
  String _formatTooltipPeriodLabel(SymptomBucket bucket) {
    return switch (widget.granularity) {
      SymptomGranularity.week => DateFormat('EEE dd MMM').format(bucket.start),
      SymptomGranularity.month => () {
        // Format as "Week of Nov 3–9"
        final startMonth = DateFormat('MMM').format(bucket.start);
        final startDay = bucket.start.day;
        final endDay = bucket.end.day;
        if (startDay == endDay) {
          return 'Week of $startMonth $startDay';
        }
        return 'Week of $startMonth $startDay–$endDay';
      }(),
      SymptomGranularity.year => DateFormat('MMM yyyy').format(bucket.start),
    };
  }

  /// Builds list of symptom rows for tooltip display
  ///
  /// Returns a list of (label, count, color) tuples for the tooltip.
  /// In stacked mode, includes visible symptoms + "Other" if applicable.
  /// In single-symptom mode, returns only the selected symptom.
  List<_SymptomTooltipRow> _buildSymptomTooltipRows(
    SymptomBucket bucket,
    SymptomsChartViewModel viewModel,
  ) {
    final rows = <_SymptomTooltipRow>[];

    if (widget.selectedSymptomKey == null) {
      // Stacked mode: show visible symptoms + Other
      for (final symptomKey in viewModel.visibleSymptoms) {
        final count = bucket.daysWithSymptom[symptomKey] ?? 0;
        if (count > 0) {
          rows.add(
            _SymptomTooltipRow(
              label: _getSymptomLabel(symptomKey),
              count: count,
              color: SymptomColors.colorForSymptom(symptomKey),
            ),
          );
        }
      }

      // Add "Other" if applicable
      if (viewModel.hasOther) {
        final visibleTotal = rows.fold<int>(
          0,
          (sum, row) => sum + row.count,
        );
        final otherCount = bucket.totalSymptomDays - visibleTotal;
        if (otherCount > 0) {
          rows.add(
            _SymptomTooltipRow(
              label: 'Other',
              count: otherCount,
              color: SymptomColors.colorForOther(),
            ),
          );
        }
      }
    } else {
      // Single-symptom mode: show only selected symptom
      final count = bucket.daysWithSymptom[widget.selectedSymptomKey] ?? 0;
      if (count > 0) {
        rows.add(
          _SymptomTooltipRow(
            label: _getSymptomLabel(widget.selectedSymptomKey!),
            count: count,
            color: SymptomColors.colorForSymptom(widget.selectedSymptomKey!),
          ),
        );
      }
    }

    return rows;
  }

  /// Gets the display label for a symptom key
  ///
  /// Maps symptom keys to human-readable names.
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

  /// Builds an accessibility label for the tooltip
  ///
  /// Summarizes the tooltip content for screen readers.
  String _buildTooltipSemanticsLabel(
    String periodLabel,
    int totalDays,
    List<_SymptomTooltipRow> symptomRows,
  ) {
    final buffer = StringBuffer('$periodLabel. Total symptom days: $totalDays');
    if (symptomRows.isNotEmpty) {
      buffer
        ..write('. ')
        ..write(
          symptomRows
              .map(
                (row) {
                  final dayLabel = row.count == 1 ? 'day' : 'days';
                  return '${row.label}: ${row.count} $dayLabel';
                },
              )
              .join(', '),
        );
    }
    return buffer.toString();
  }

  /// Builds the legend placeholder below the chart
  ///
  /// This will later display symptom color chips (section 3.5).
  /// For now, shows a simple placeholder.
  Widget _buildLegendPlaceholder(SymptomsChartViewModel viewModel) {
    // TODO(section-3.5): Implement legend with symptom color chips
    return const SizedBox.shrink();
  }

  // TODO(widget-tests): Add widget tests for tooltip behavior:
  // - Tapping a bar shows the tooltip with correct content
  // - Period labels are formatted correctly for each granularity
  // - Per-symptom breakdown matches bucket data in stacked mode
  // - Single-symptom mode shows only selected symptom
  // - Empty buckets don't show tooltips
  // - Tooltip positioning adapts to bar index (left/right)
}

/// Data class for a single symptom row in the tooltip
class _SymptomTooltipRow {
  /// Creates a [_SymptomTooltipRow]
  const _SymptomTooltipRow({
    required this.label,
    required this.count,
    required this.color,
  });

  /// Display label for the symptom (e.g., "Vomiting", "Other")
  final String label;

  /// Number of days with this symptom
  final int count;

  /// Color for the symptom indicator
  final Color color;
}

/// Compact tooltip card with period label, total days, and symptom breakdown.
///
/// Displays symptom data when user taps a bar:
///  - Line 1: Period label (e.g., "Mon 15 Jan", "Week of Nov 3–9", "Mar 2025")
///  - Line 2: "Total symptom days: X"
///  - Following lines: Per-symptom breakdown with colored indicators
/// Includes a small triangle arrow that points toward the tapped bar.
class _SymptomsTooltipCard extends StatelessWidget {
  /// Creates a [_SymptomsTooltipCard]
  const _SymptomsTooltipCard({
    required this.periodLabel,
    required this.totalSymptomDays,
    required this.symptomRows,
    required this.pointsLeft,
  });

  /// Period label (formatted based on granularity)
  final String periodLabel;

  /// Total number of symptom days in the bucket
  final int totalSymptomDays;

  /// List of symptom rows to display
  final List<_SymptomTooltipRow> symptomRows;

  /// Whether the tooltip arrow points left (tooltip appears on right side)
  final bool pointsLeft;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line 1: Period label
              Text(
                periodLabel,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              // Line 2: Total symptom days
              Text(
                'Total symptom days: $totalSymptomDays',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              // Symptom breakdown rows
              if (symptomRows.isNotEmpty) ...[
                const SizedBox(height: 4),
                ...symptomRows.map((row) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Colored dot indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: row.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Symptom label and count
                        Text(
                          () {
                            final dayLabel = row.count == 1 ? 'day' : 'days';
                            return '${row.label}: ${row.count} $dayLabel';
                          }(),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        // Directional arrow pointing toward the tapped bar
        Positioned(
          left: pointsLeft ? -6 : null,
          right: pointsLeft ? null : -6,
          top: 10,
          child: Transform.rotate(
            angle: pointsLeft ? -1.5708 : 1.5708, // ±90 degrees in radians
            child: const Icon(
              Icons.change_history,
              size: 12,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
