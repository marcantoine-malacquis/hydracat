import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/core/utils/chart_utils.dart';
import 'package:hydracat/features/health/models/weight_data_point.dart';
import 'package:hydracat/features/health/models/weight_granularity.dart';
import 'package:intl/intl.dart';

const _ln10 = 2.302585092994046;

/// Line chart widget for displaying weight trends
///
/// Shows weight data points over time with:
/// - Smooth curved line
/// - Gradient fill below line
/// - Touch interaction with tooltips
/// - Responsive axis labels
/// - Minimum 0.5kg Y-axis range for meaningful scale
/// - Empty state with x-axis labels only
class WeightLineChart extends StatelessWidget {
  /// Creates a [WeightLineChart]
  const WeightLineChart({
    required this.dataPoints,
    required this.unit,
    required this.granularity,
    this.showEmptyState = false,
    super.key,
  });

  /// Weight data points to display (requires 2+ points)
  final List<WeightDataPoint> dataPoints;

  /// Unit to display (kg or lbs)
  final String unit;

  /// Granularity for X-axis label formatting
  final WeightGranularity granularity;

  /// Whether to show empty state with x-axis labels only
  final bool showEmptyState;

  /// Gets X-axis interval based on data points and granularity
  double _getXAxisInterval(int pointCount) {
    return switch (granularity) {
      WeightGranularity.week => 1, // Show all days
      WeightGranularity.month => pointCount > 15 ? 2 : 1,
      WeightGranularity.year => pointCount > 6 ? 2 : 1,
    };
  }

  /// Calculates a "nice" interval for chart axis
  /// Returns values like 0.1, 0.25, 0.5, 1, 2, 5, etc.
  double _calculateNiceInterval(double rawInterval) {
    final magnitude = pow(10, (log(rawInterval) / _ln10).floor()).toDouble();
    final normalized = rawInterval / magnitude;

    // Choose nice number: 0.1, 0.25, 0.5, 1.0, 2.0, 5.0
    final nice = normalized <= 0.15
        ? 0.1
        : normalized <= 0.35
        ? 0.25
        : normalized <= 0.75
        ? 0.5
        : normalized <= 1.5
        ? 1.0
        : normalized <= 3.0
        ? 2.0
        : 5.0;

    return nice * magnitude;
  }

  /// Calculates optimal Y-axis reserved size based on label widths
  ///
  /// Dynamically measures the width of Y-axis labels to minimize
  /// wasted space and improve chart centering.
  /// Adapts automatically to different data ranges.
  double _calculateYAxisReservedSize({
    required double minY,
    required double maxY,
    required double interval,
  }) {
    // Generate all Y-axis labels that will be displayed
    final labels = ChartUtils.generateYAxisLabels(
      minY: minY,
      maxY: maxY,
      interval: interval,
    );

    // Calculate optimal width
    return ChartUtils.calculateYAxisReservedSize(
      labels: labels,
      textStyle: AppTextStyles.caption.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Handle empty state with x-axis labels
    if (dataPoints.isEmpty && showEmptyState) {
      return _buildEmptyChart(context);
    }

    if (dataPoints.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No weight data available',
            style: AppTextStyles.small.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    // Sort by date ascending for chart
    final sortedPoints = [...dataPoints]
      ..sort((a, b) => a.date.compareTo(b.date));

    // Convert to chart spots
    final spots = sortedPoints.asMap().entries.map((entry) {
      final x = entry.key.toDouble();
      final weight = unit == 'kg'
          ? entry.value.weightKg
          : entry.value.weightLbs;
      return FlSpot(x, weight);
    }).toList();

    // Calculate min/max for Y axis
    final weights = spots.map((spot) => spot.y).toList();
    final minWeight = weights.reduce(min);
    final maxWeight = weights.reduce(max);
    final range = maxWeight - minWeight;

    // Enforce minimum 2.0kg range for meaningful scale
    final effectiveRange = max(range, 2);

    // Add 10% padding to Y axis
    final padding = effectiveRange * 0.1;
    final yMin = minWeight - padding;
    final yMax = maxWeight + padding;

    // Calculate nice interval and align min/max to it
    final rawInterval = (yMax - yMin) / 4;
    final niceInterval = _calculateNiceInterval(rawInterval);
    final alignedMin = (yMin / niceInterval).floor() * niceInterval;
    final alignedMax = (yMax / niceInterval).ceil() * niceInterval;

    // Calculate optimal Y-axis reserved size
    final yAxisReservedSize = _calculateYAxisReservedSize(
      minY: alignedMin,
      maxY: alignedMax,
      interval: niceInterval,
    );

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: niceInterval,
            getDrawingHorizontalLine: (value) {
              return const FlLine(
                color: AppColors.border,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: yAxisReservedSize,
                interval: niceInterval,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(2),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _getXAxisInterval(sortedPoints.length),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= sortedPoints.length) {
                    return const SizedBox.shrink();
                  }

                  final date = sortedPoints[index].date;
                  final format = switch (granularity) {
                    WeightGranularity.week => DateFormat('EEE'),
                    WeightGranularity.month => DateFormat('d'),
                    WeightGranularity.year => DateFormat('MMM'),
                  };

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      format.format(date),
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
          borderData: FlBorderData(
            show: true,
            border: const Border(
              bottom: BorderSide(color: AppColors.border),
              left: BorderSide(color: AppColors.border),
            ),
          ),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: alignedMin,
          maxY: alignedMax,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.primary,
                    strokeWidth: 2,
                    strokeColor: AppColors.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    AppColors.primary.withValues(alpha: 0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => AppColors.textPrimary,
              tooltipBorder: const BorderSide(color: AppColors.textPrimary),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  final date = sortedPoints[index].date;
                  final weight = spot.y;

                  return LineTooltipItem(
                    '${DateFormat('MMM dd').format(date)}\n'
                    '${weight.toStringAsFixed(2)} $unit',
                    AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Builds an empty chart with only x-axis labels
  Widget _buildEmptyChart(BuildContext context) {
    // Get current date for reference
    final now = DateTime.now();

    // Generate x-axis labels based on granularity
    final xLabels = _generateEmptyStateLabels(now);

    // Calculate reserved size for empty state (2.00 to 8.00 range)
    final yAxisReservedSize = _calculateYAxisReservedSize(
      minY: 2,
      maxY: 8,
      interval: 2,
    );

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) {
              return const FlLine(
                color: AppColors.border,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            // Show placeholder y-axis labels
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: yAxisReservedSize,
                interval: 2,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(2),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
            // Show x-axis labels
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= xLabels.length) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      xLabels[index],
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
          borderData: FlBorderData(
            show: true,
            border: const Border(
              bottom: BorderSide(color: AppColors.border),
              left: BorderSide(color: AppColors.border),
            ),
          ),
          minX: 0,
          maxX: (xLabels.length - 1).toDouble(),
          minY: 2,
          maxY: 8, // Typical cat weight range
          lineBarsData: [], // No data lines
        ),
      ),
    );
  }

  /// Generates x-axis labels for empty state based on granularity
  List<String> _generateEmptyStateLabels(DateTime referenceDate) {
    return switch (granularity) {
      // Week: Show 7 day abbreviations
      WeightGranularity.week => [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ],

      // Month: Show 1, 15, and last day of month
      WeightGranularity.month => () {
        final lastDay = DateTime(
          referenceDate.year,
          referenceDate.month + 1,
          0,
        ).day;
        return ['1', '15', lastDay.toString()];
      }(),

      // Year: Show Jan, Jun, Dec
      WeightGranularity.year => [
        'Jan',
        'Jun',
        'Dec',
      ],
    };
  }
}
