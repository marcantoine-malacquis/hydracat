import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/qol/models/qol_trend_summary.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/qol_provider.dart';
import 'package:intl/intl.dart' as intl;

/// Displays a line chart showing QoL trends over time.
///
/// Shows overall score trends across the last 12 assessments with:
/// - Line graph with gradient filled area
/// - Fixed 0-100 Y-axis scale (showing 50% and 100% labels)
/// - Month labels on X-axis
/// - Touch tooltips with detailed scores
/// - Empty state for insufficient data (<2 assessments)
class QolTrendLineChart extends ConsumerStatefulWidget {
  /// Creates a QolTrendLineChart.
  const QolTrendLineChart({super.key});

  @override
  ConsumerState<QolTrendLineChart> createState() => _QolTrendLineChartState();
}

class _QolTrendLineChartState extends ConsumerState<QolTrendLineChart> {
  bool _hasTrackedView = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Track trends viewed once per widget lifecycle (only if chart is shown)
    if (!_hasTrackedView) {
      final trendData = ref.read(qolTrendDataProvider);
      if (trendData.length >= 2) {
        _hasTrackedView = true;
        _trackTrendsView(trendData.length);
      }
    }
  }

  void _trackTrendsView(int assessmentCount) {
    final petId = ref.read(primaryPetProvider)?.id;
    ref.read(analyticsServiceDirectProvider).trackQolTrendsViewed(
          assessmentCount: assessmentCount,
          petId: petId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trendData = ref.watch(qolTrendDataProvider);

    // Chart or empty state - no card wrapper, no title
    if (trendData.length < 2) {
      return _EmptyState(message: l10n.qolNeedMoreData);
    }
    return _TrendChart(trendData: trendData);
  }
}

/// Empty state widget when insufficient data for trends
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.show_chart,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
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

/// The actual trend line chart widget
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.trendData});

  final List<QolTrendSummary> trendData;

  @override
  Widget build(BuildContext context) {
    // Reverse data to show oldest → newest (left to right)
    final reversedData = trendData.reversed.toList();

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        _buildLineChartData(context, reversedData),
      ),
    );
  }

  LineChartData _buildLineChartData(
    BuildContext context,
    List<QolTrendSummary> data,
  ) {
    final spots = data.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.overallScore,
      );
    }).toList();

    return LineChartData(
      // Grid styling - no horizontal lines
      gridData: const FlGridData(
        drawVerticalLine: false,
        drawHorizontalLine: false,
      ),

      // Border styling - only bottom and left
      borderData: FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
        ),
      ),

      // Fixed Y-axis range (0-100)
      minY: 0,
      maxY: 100,

      // X-axis range based on data points
      minX: 0,
      maxX: (data.length - 1).toDouble(),

      // X-axis labels (dates)
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _calculateXAxisInterval(data.length),
            getTitlesWidget: (value, meta) {
              return _buildXAxisLabel(value.toInt(), data);
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 50,
            getTitlesWidget: (value, meta) {
              // Only show 50 and 100 labels
              if (value == 50 || value == 100) {
                return _buildYAxisLabel(value);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),

      // Line data
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 3,
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
          preventCurveOverShooting: true,
        ),
      ],

      // Touch tooltip
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.surface,
          tooltipPadding: const EdgeInsets.all(AppSpacing.sm),
          tooltipBorder: const BorderSide(
            color: AppColors.border,
          ),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return _buildTooltipItem(spot, data);
            }).toList();
          },
        ),
      ),
    );
  }

  /// Calculate appropriate interval for X-axis labels based on data count
  double _calculateXAxisInterval(int dataCount) {
    if (dataCount <= 4) return 1;
    if (dataCount <= 8) return 2;
    return 3;
  }

  /// Build X-axis label (month)
  Widget _buildXAxisLabel(int index, List<QolTrendSummary> data) {
    if (index < 0 || index >= data.length) {
      return const SizedBox.shrink();
    }

    final date = data[index].date;
    final formattedDate = intl.DateFormat('MMM').format(date);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        formattedDate,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  /// Build Y-axis label (score)
  Widget _buildYAxisLabel(double value) {
    return Text(
      value.toInt().toString(),
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }

  /// Build tooltip content for touched point
  LineTooltipItem _buildTooltipItem(
    LineBarSpot spot,
    List<QolTrendSummary> data,
  ) {
    final index = spot.x.toInt();
    if (index < 0 || index >= data.length) {
      return const LineTooltipItem('', AppTextStyles.small);
    }

    final summary = data[index];
    final date = intl.DateFormat('MMM d, yyyy').format(summary.date);
    final score = summary.overallScore.toStringAsFixed(0);

    final tooltipText = '$date\nOverall: $score';

    return LineTooltipItem(
      tooltipText,
      AppTextStyles.small.copyWith(
        color: AppColors.textPrimary,
        height: 1.4,
      ),
    );
  }

}
