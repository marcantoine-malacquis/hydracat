import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/progress/models/fluid_month_chart_data.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:intl/intl.dart';

/// Monthly fluid volume bar chart (28-31 bars)
///
/// Displays 28-31 bars (one per day) showing daily fluid therapy volumes
/// with visual feedback for goal achievement, missed sessions, and progress.
///
/// Features:
/// - 28-31 bars matching month length (automatically handles leap years)
/// - Dashed amber goal line (unified goal) or subtle markers (varying goals)
/// - Smart touch tooltips with left/right positioning
/// - Rising animation with staggered wave effect on data load
/// - Opacity-based progress indication (darker = better adherence)
/// - Tiny coral bars for missed scheduled sessions
/// - Haptic feedback on touch for native feel
/// - X-axis labels every 5 days (1, 5, 10, 15, 20, 25, 30)
///
/// Cost: 0 Firestore reads (uses monthlyFluidChartDataProvider)
///
/// Example:
/// ```dart
/// // Automatically integrates with focused month
/// const FluidVolumeMonthChart()
/// ```
class FluidVolumeMonthChart extends ConsumerStatefulWidget {
  /// Creates a [FluidVolumeMonthChart]
  const FluidVolumeMonthChart({super.key});

  @override
  ConsumerState<FluidVolumeMonthChart> createState() =>
      _FluidVolumeMonthChartState();
}

class _FluidVolumeMonthChartState extends ConsumerState<FluidVolumeMonthChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _touchedBarIndex;
  Offset? _touchPosition;
  DateTime? _lastAnimatedMonth;

  static const double _chartHeight = 200;
  static const double _barBorderRadius = 10;
  static const double _missedBarHeightPercent = 0.015; // 1.5% of Y-axis
  static const double _barWidth = 8; // Narrower than week's 40px

  @override
  void initState() {
    super.initState();

    // Setup rising animation (600ms with easeOutCubic)
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focusedDay = ref.watch(focusedDayProvider);
    final monthStart = DateTime(focusedDay.year, focusedDay.month);
    final chartData = ref.watch(monthlyFluidChartDataProvider(monthStart));

    // While data is loading, reserve vertical space so layout doesn't jump
    if (chartData == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: SizedBox(
          height: _chartHeight,
        ),
      );
    }

    // Show empty state when there are no scheduled sessions for the month
    if (!chartData.shouldShowChart) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: _buildEmptyState(chartData),
      );
    }

    // Trigger animation only when month changes (not on every rebuild)
    if (_lastAnimatedMonth != monthStart) {
      _animationController
        ..reset()
        ..forward();
      _lastAnimatedMonth = monthStart;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: _chartHeight,
        child: Stack(
          children: [
            // Main bar chart
            _buildBarChart(chartData),

            // Unified goal label (when a single consistent goal exists)
            if (chartData.goalLineY != null)
              _buildGoalLabelOverlay(context, chartData),

            // Touch tooltip overlay
            if (_touchedBarIndex != null && _touchPosition != null)
              _buildTooltip(
                chartData.days[_touchedBarIndex!],
                _touchedBarIndex!,
              ),
          ],
        ),
      ),
    );
  }

  /// Builds empty state when no data exists
  Widget _buildEmptyState(FluidMonthChartData chartData) {
    final monthName = DateFormat.MMMM().format(
      chartData.days.isNotEmpty ? chartData.days.first.date : DateTime.now(),
    );

    return SizedBox(
      height: _chartHeight,
      child: Center(
        child: Text(
          'No fluid therapy data for $monthName',
          style: AppTextStyles.small.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Builds the main bar chart with animation and accessibility support
  Widget _buildBarChart(FluidMonthChartData chartData) {
    final monthName = DateFormat.MMMM().format(chartData.days.first.date);

    return Semantics(
      label:
          'Monthly fluid therapy chart for $monthName showing '
          '${chartData.monthLength} days',
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: _touchedBarIndex == null ? 0 : 1,
            ),
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            builder: (context, selectionHighlight, _) {
              return BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  groupsSpace: 0,
                  maxY: chartData.maxVolume,
                  minY: 0,
                  barTouchData: _buildTouchData(),
                  titlesData: _buildTitlesData(chartData),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _buildBarGroups(
                    chartData,
                    selectionHighlight,
                  ),
                  extraLinesData: _buildGoalLine(chartData),
                ),
                duration: Duration.zero,
              );
            },
          );
        },
      ),
    );
  }

  /// Configures touch interaction behavior
  BarTouchData _buildTouchData() {
    return BarTouchData(
      enabled: true,
      handleBuiltInTouches: false,
      touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
        setState(() {
          if (event is FlTapDownEvent && response?.spot != null) {
            HapticFeedback.selectionClick();
            _touchedBarIndex = response!.spot!.touchedBarGroupIndex;
            _touchPosition = event.localPosition;
          } else if (event is FlTapUpEvent || event is FlTapCancelEvent) {
            _touchedBarIndex = null;
            _touchPosition = null;
          }
        });
      },
    );
  }

  /// Builds X-axis titles showing day numbers every 5 days
  FlTitlesData _buildTitlesData(FluidMonthChartData chartData) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          getTitlesWidget: (value, meta) {
            final dayIndex = value.toInt();
            if (dayIndex < 0 || dayIndex >= chartData.monthLength) {
              return const SizedBox.shrink();
            }

            final dayOfMonth = chartData.days[dayIndex].dayOfMonth;

            // Show labels for days 1, 5, 10, 15, 20, 25, 30
            final showLabel =
                dayOfMonth == 1 || (dayOfMonth % 5 == 0 && dayOfMonth <= 30);

            if (!showLabel) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '$dayOfMonth',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: const AxisTitles(),
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
    );
  }

  /// Builds all bar groups with staggered animation
  List<BarChartGroupData> _buildBarGroups(
    FluidMonthChartData chartData,
    double selectionHighlight,
  ) {
    return List.generate(chartData.monthLength, (index) {
      final day = chartData.days[index];

      // Staggered animation: each bar starts 20ms after previous
      final staggerDelay = index * 20;
      final animationTime = _animation.value * 600;
      final staggeredProgress = animationTime < staggerDelay
          ? 0.0
          : ((animationTime - staggerDelay) / (600 - staggerDelay)).clamp(
              0.0,
              1.0,
            );

      return BarChartGroupData(
        x: index,
        barRods: [
          _buildBarRod(
            day,
            staggeredProgress,
            chartData.maxVolume,
            _touchedBarIndex == index,
            selectionHighlight,
          ),
        ],
      );
    });
  }

  /// Builds a single bar rod with appropriate styling
  BarChartRodData _buildBarRod(
    FluidMonthDayData day,
    double animationProgress,
    double maxVolume,
    bool isSelected,
    double selectionHighlight,
  ) {
    // Missed session: tiny coral bar (1.5% of Y-axis)
    if (day.isMissed) {
      return BarChartRodData(
        toY: maxVolume * _missedBarHeightPercent,
        color: AppColors.warning,
        width: _barWidth,
        borderRadius: BorderRadius.circular(_barBorderRadius),
      );
    }

    // No bar for future days or unscheduled past days
    if (!day.shouldShowBar) {
      return BarChartRodData(
        toY: 0,
        color: Colors.transparent,
        width: _barWidth,
      );
    }

    // Regular bar with animation
    final animatedHeight = day.volumeMl * animationProgress;

    final baseOpacity = day.barOpacity;
    final highlightBoost = (isSelected ? 0.2 * selectionHighlight : 0).clamp(
      0.0,
      0.4,
    );
    final topOpacity = (baseOpacity + highlightBoost).clamp(0.0, 1.0);

    return BarChartRodData(
      toY: animatedHeight,
      width: _barWidth,
      borderRadius: BorderRadius.circular(_barBorderRadius),
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          AppColors.primary.withValues(alpha: baseOpacity),
          AppColors.primary.withValues(alpha: topOpacity),
        ],
      ),
    );
  }

  /// Builds goal line(s) based on goal consistency
  ///
  /// Returns:
  /// - Unified goal: Single bold amber dashed line (all days same goal)
  /// - Varying goals: Subtle markers for each unique goal value
  /// - No goals: Empty (no lines)
  ExtraLinesData _buildGoalLine(FluidMonthChartData chartData) {
    // Unified goal: show single prominent dashed line
    if (chartData.goalLineY != null) {
      return ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: chartData.goalLineY!,
            color: Colors.amber[600],
            strokeWidth: 1.5,
            dashArray: const [8, 4],
          ),
        ],
      );
    }

    // Varying goals: show subtle markers for each unique goal value
    final uniqueGoals = chartData.days
        .where((d) => d.goalMl > 0) // Only days with goals
        .map((d) => d.goalMl) // Extract goal values
        .toSet() // Remove duplicates
        .toList();

    // If no goals exist, return empty
    if (uniqueGoals.isEmpty) {
      return const ExtraLinesData();
    }

    // Create subtle marker for each unique goal
    return ExtraLinesData(
      horizontalLines: uniqueGoals.map((goalMl) {
        return HorizontalLine(
          y: goalMl,
          color: Colors.amber[600]!.withValues(alpha: 0.3), // 30% opacity
          strokeWidth: 1, // Thinner than unified line
          dashArray: const [4, 4], // Shorter dashes: 4px dash, 4px gap
        );
      }).toList(),
    );
  }

  /// Builds goal label overlay with glass morphism effect
  Widget _buildGoalLabelOverlay(
    BuildContext context,
    FluidMonthChartData chartData,
  ) {
    final goalLineY = chartData.goalLineY!;
    final goalText = '${goalLineY.toInt()} ml';

    // Calculate Y position (invert because chart Y increases downward)
    final yPosition = _chartHeight * (1 - goalLineY / chartData.maxVolume);

    return Positioned(
      right: 8,
      top: yPosition - 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).scaffoldBackgroundColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber[600]!.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              goalText,
              style: AppTextStyles.caption.copyWith(
                color: Colors.amber[700],
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds touch tooltip showing day details
  Widget _buildTooltip(FluidMonthDayData day, int barIndex) {
    if (_touchPosition == null) return const SizedBox.shrink();

    final formattedDate = DateFormat('MMM d').format(day.date);
    final volumeText = '${day.volumeMl.toInt()} ml';
    final goalText = day.goalMl > 0 ? '/ ${day.goalMl.toInt()} ml' : '';
    final percentageText = day.goalMl > 0
        ? ' (${day.percentage.toInt()}%)'
        : '';

    // Position tooltip left or right based on bar index
    // Left side for bars 0-14, right side for bars 15+
    final isLeftSide = barIndex < 15;

    return Positioned(
      left: isLeftSide ? _touchPosition!.dx + 16 : null,
      right: isLeftSide
          ? null
          : MediaQuery.of(context).size.width - _touchPosition!.dx + 16,
      top: _touchPosition!.dy - 60,
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
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
                Text(
                  formattedDate,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.body,
                    children: [
                      TextSpan(
                        text: volumeText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      TextSpan(
                        text: ' $goalText',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextSpan(
                        text: percentageText,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
