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
import 'package:hydracat/shared/widgets/cards/cards.dart';
import 'package:intl/intl.dart' as intl;

/// Displays a line chart showing QoL trends over time.
///
/// Shows overall score trends across the last 12 assessments with:
/// - Line graph with filled area
/// - Fixed 0-100 Y-axis scale
/// - Date labels on X-axis
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

    return HydraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            l10n.qolTrendChartTitle,
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: AppSpacing.md),

          // Chart or empty state
          if (trendData.length < 2)
            _EmptyState(message: l10n.qolNeedMoreData)
          else
            _TrendChart(trendData: trendData),
        ],
      ),
    );
  }
}

/// Empty state widget when insufficient data for trends
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
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

    return SizedBox(
      height: 240,
      child: Padding(
        padding: const EdgeInsets.only(
          right: AppSpacing.sm,
          top: AppSpacing.sm,
        ),
        child: LineChart(
          _buildLineChartData(context, reversedData),
        ),
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
      // Grid styling
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: 25,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppColors.border.withValues(alpha: 0.5),
            strokeWidth: 1,
          );
        },
      ),

      // Border styling
      borderData: FlBorderData(
        border: Border.all(
          color: AppColors.border,
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
            reservedSize: 30,
            interval: _calculateXAxisInterval(data.length),
            getTitlesWidget: (value, meta) {
              return _buildXAxisLabel(value.toInt(), data);
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            reservedSize: 40,
            interval: 25,
            getTitlesWidget: (value, meta) {
              return _buildYAxisLabel(value);
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
            color: AppColors.primary.withValues(alpha: 0.1),
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

  /// Build X-axis label (date)
  Widget _buildXAxisLabel(int index, List<QolTrendSummary> data) {
    if (index < 0 || index >= data.length) {
      return const SizedBox.shrink();
    }

    final date = data[index].date;
    final formattedDate = intl.DateFormat('MMM d').format(date);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        formattedDate,
        style: AppTextStyles.small.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  /// Build Y-axis label (score)
  Widget _buildYAxisLabel(double value) {
    return Text(
      value.toInt().toString(),
      style: AppTextStyles.small.copyWith(
        color: AppColors.textTertiary,
      ),
      textAlign: TextAlign.right,
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

    // Build domain scores text
    final domainScoresText = StringBuffer();
    summary.domainScores.forEach((domain, domainScore) {
      domainScoresText.writeln(
        '${_getDomainDisplayName(domain)}: ${domainScore.toStringAsFixed(0)}',
      );
    });

    final tooltipText =
        '$date\n'
        'Overall: $score\n'
        '${domainScoresText.toString().trimRight()}';

    return LineTooltipItem(
      tooltipText,
      AppTextStyles.small.copyWith(
        color: AppColors.textPrimary,
        height: 1.4,
      ),
    );
  }

  /// Get display name for domain (abbreviated)
  String _getDomainDisplayName(String domain) {
    switch (domain) {
      case 'vitality':
        return 'Vitality';
      case 'comfort':
        return 'Comfort';
      case 'emotional':
        return 'Emotional';
      case 'appetite':
        return 'Appetite';
      case 'treatmentBurden':
        return 'Treatment';
      default:
        return domain;
    }
  }
}
