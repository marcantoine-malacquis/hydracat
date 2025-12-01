import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/logging/screens/fluid_logging_screen.dart';
import 'package:hydracat/features/logging/widgets/logging_bottom_sheet_helper.dart';
import 'package:hydracat/features/progress/models/fluid_chart_data.dart';
import 'package:hydracat/features/progress/providers/fluid_chart_provider.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/progress_provider.dart';
import 'package:intl/intl.dart';

/// Weekly fluid volume bar chart aligned with calendar columns
///
/// Displays 7 bars (Monday-Sunday) showing daily fluid therapy volumes
/// with visual feedback for goal achievement, missed sessions, and progress.
///
/// Features:
/// - Pixel-perfect alignment with calendar day columns
/// - Dashed amber goal line for daily target (when goals are consistent)
/// - Smart touch tooltips with left/right positioning
/// - Rising animation with staggered wave effect on data load
/// - Opacity-based progress indication (darker = better adherence)
/// - Tiny coral bars for missed scheduled sessions
/// - Haptic feedback on touch for native feel
///
/// Cost: 0 Firestore reads (uses weeklyFluidChartDataProvider)
///
/// Example:
/// ```dart
/// // Automatically integrates with focused week
/// const FluidVolumeBarChart()
/// ```
class FluidVolumeBarChart extends ConsumerStatefulWidget {
  /// Creates a [FluidVolumeBarChart]
  const FluidVolumeBarChart({super.key});

  @override
  ConsumerState<FluidVolumeBarChart> createState() =>
      _FluidVolumeBarChartState();
}

class _FluidVolumeBarChartState extends ConsumerState<FluidVolumeBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _touchedBarIndex;
  Offset? _touchPosition;
  DateTime? _lastAnimatedWeek;

  static const double _chartHeight = 200;
  static const double _barBorderRadius = 10;
  static const double _missedBarHeightPercent = 0.015; // 1.5% of Y-axis
  static const double _barWidth = 40; // Slightly slimmer for a lighter feel

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
    final weekStart = ref.watch(focusedWeekStartProvider);
    final chartData = ref.watch(weeklyFluidChartDataProvider(weekStart));

    // While data is loading (provider returns null), reserve vertical space so
    // the layout below doesn't jump when the chart appears and animates in.
    if (chartData == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: SizedBox(
          height: _chartHeight,
        ),
      );
    }

    // Show ghost empty state when there are no scheduled sessions for the week.
    if (!chartData.shouldShowChart) {
      final currentWeekStart = AppDateUtils.startOfWeekMonday(DateTime.now());
      final isCurrentWeek =
          weekStart.year == currentWeekStart.year &&
          weekStart.month == currentWeekStart.month &&
          weekStart.day == currentWeekStart.day;
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: FluidVolumeChartEmptyState(
          chartData: chartData,
          showLogCta: isCurrentWeek,
        ),
      );
    }

    // Trigger animation only when week changes (not on every rebuild)
    if (_lastAnimatedWeek != weekStart) {
      _animationController
        ..reset()
        ..forward();
      _lastAnimatedWeek = weekStart;
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

  /// Builds the main bar chart with animation and accessibility support
  Widget _buildBarChart(FluidChartData chartData) {
    return Semantics(
      label:
          'Weekly fluid therapy chart showing volumes for '
          '${_formatWeekRange()}',
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return TweenAnimationBuilder<double>(
            // When a bar is selected, briefly boost its highlight in a
            // lightweight implicit animation. This keeps the interaction
            // feeling responsive without changing layout.
            tween: Tween<double>(
              begin: 0,
              end: _touchedBarIndex == null ? 0 : 1,
            ),
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            builder: (context, selectionHighlight, _) {
              return BarChart(
                BarChartData(
                  // Use spaceAround so edge gaps are half of the inner gaps.
                  // This mirrors how 7 calendar cells are laid out
                  // horizontally, keeping each bar centered under its
                  // corresponding day column.
                  alignment: BarChartAlignment.spaceAround,
                  groupsSpace: 0, // Alignment handles horizontal spacing
                  maxY: chartData.maxVolume,
                  minY: 0,
                  barTouchData: _buildTouchData(),
                  titlesData: const FlTitlesData(
                    show: false,
                  ), // No Y-axis labels
                  gridData: const FlGridData(show: false), // No grid lines
                  borderData: FlBorderData(show: false), // No border
                  barGroups: _buildBarGroups(
                    chartData,
                    selectionHighlight,
                  ),
                  extraLinesData: _buildGoalLine(chartData),
                ),
                duration: Duration.zero, // Use custom animation
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
      handleBuiltInTouches: false, // Custom touch handling
      touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
        setState(() {
          if (event is FlTapDownEvent && response?.spot != null) {
            HapticFeedback.selectionClick(); // Gentle tap feedback
            _touchedBarIndex = response!.spot!.touchedBarGroupIndex;
            _touchPosition = event.localPosition; // Actual pixel position
          } else if (event is FlTapUpEvent || event is FlTapCancelEvent) {
            _touchedBarIndex = null;
            _touchPosition = null;
          }
        });
      },
    );
  }

  /// Builds all 7 bar groups with staggered animation
  List<BarChartGroupData> _buildBarGroups(
    FluidChartData chartData,
    double selectionHighlight,
  ) {
    return List.generate(7, (index) {
      final day = chartData.days[index];

      // Staggered animation: each bar starts 50ms after previous
      final staggerDelay = index * 50;
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
    FluidDayData day,
    double animationProgress,
    double maxVolume,
    bool isSelected,
    double selectionHighlight,
  ) {
    // Missed session: tiny coral bar (1.5% of Y-axis for consistent visibility)
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

    // When selected, keep width fixed but boost the bar's visual treatment
    // slightly using a darker top color and optional outline. The extra
    // emphasis is gently animated via [selectionHighlight] without affecting
    // the chart layout or neighboring bars.
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
          AppColors.primary.withValues(alpha: baseOpacity * 0.8),
          (isSelected ? AppColors.primaryDark : AppColors.primary).withValues(
            alpha: topOpacity,
          ),
        ],
      ),
      borderSide: isSelected && selectionHighlight > 0
          ? BorderSide(
              color: AppColors.primaryDark.withValues(
                alpha: 0.25 * selectionHighlight,
              ),
              width: 1.2,
            )
          : BorderSide.none,
    );
  }

  /// Builds an overlaid pill label for the unified goal line.
  ///
  /// When a single consistent daily goal exists across the week, this overlay
  /// renders a small pill on the right edge of the chart. When overlapping
  /// with bars, it uses a glass morphism effect (backdrop blur) with reduced
  /// opacity for a premium, elegant appearance.
  Widget _buildGoalLabelOverlay(
    BuildContext context,
    FluidChartData chartData,
  ) {
    final goalY = chartData.goalLineY;
    if (goalY == null || chartData.maxVolume <= 0) {
      return const SizedBox.shrink();
    }

    // Use first non-zero goal as the label value (all goals are unified here).
    final goalValue = chartData.days
        .firstWhere(
          (d) => d.goalMl > 0,
          orElse: () => chartData.days.first,
        )
        .goalMl;

    // Map chart Y-value to pixel offset within the fixed chart height.
    final clampedGoal = goalY.clamp(0, chartData.maxVolume);
    final ratio = 1 - (clampedGoal / chartData.maxVolume);
    final goalLineTop = (ratio * _chartHeight)
        .clamp(
          0,
          _chartHeight - 24,
        )
        .toDouble();

    // Calculate pill bounds (approximately 24px height based on padding)
    const pillHeight = 24.0;
    final pillTop = goalLineTop - 12.0; // Center on goal line
    final pillBottom = pillTop + pillHeight;

    // Detect overlap: check if any bar extends into the pill's vertical range
    final hasOverlap = chartData.days.any((day) {
      if (!day.shouldShowBar || day.isMissed) return false;

      // Convert bar height to pixel position
      final barRatio = 1 - (day.volumeMl / chartData.maxVolume);
      final barTop = (barRatio * _chartHeight).clamp(0, _chartHeight);

      // Check if bar overlaps with pill (with small buffer)
      return barTop <= pillBottom + 2 && barTop >= pillTop - 2;
    });

    // Glass morphism style: semi-transparent background with backdrop blur
    //when overlapping
    // Solid background when no overlap for better readability
    final backgroundColor = hasOverlap
        ? Colors.white.withValues(alpha: 0.75) // 75% opacity when overlapping
        : Colors.white; // Solid when clear

    return Positioned(
      right: 8,
      top: pillTop,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: hasOverlap
              // Glass blur when overlapping
              ? ImageFilter.blur(sigmaX: 8, sigmaY: 8)
              // No blur when clear
              : ImageFilter.blur(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.amber[600]!.withValues(
                  // Slightly more transparent border when overlapping
                  alpha: hasOverlap ? 0.6 : 0.8,
                ),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: hasOverlap ? 0.05 : 0.08,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Goal ${goalValue.toStringAsFixed(0)}ml',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary.withValues(
                  alpha: hasOverlap
                      ? 0.9
                      : 1.0, // Slightly dimmed text when overlapping
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds goal line(s) based on goal consistency
  ///
  /// Returns:
  /// - Unified goal: Single bold amber dashed line (all days same goal)
  /// - Varying goals: Subtle markers for each unique goal value
  /// - No goals: Empty (no lines)
  ExtraLinesData _buildGoalLine(FluidChartData chartData) {
    // Unified goal: show single prominent dashed line
    if (chartData.goalLineY != null) {
      return ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: chartData.goalLineY!,
            color: Colors.amber[600],
            dashArray: const [8, 4], // Prominent: 8px dash, 4px gap
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

  /// Builds tooltip positioned based on bar index and touch location
  Widget _buildTooltip(FluidDayData day, int barIndex) {
    if (_touchPosition == null) return const SizedBox.shrink();

    // Smart positioning: Mon-Thu (0-3) right, Fri-Sun (4-6) left
    final showOnRight = barIndex <= 3;

    // Use actual touch position from fl_chart (no approximations!)
    final screenWidth = MediaQuery.of(context).size.width;

    return Positioned(
      left: showOnRight ? _touchPosition!.dx + 8 : null,
      right: !showOnRight ? screenWidth - _touchPosition!.dx + 8 : null,
      top: _touchPosition!.dy - 40, // Position above touch point
      child: TweenAnimationBuilder<double>(
        key: ValueKey('tooltip-${day.date}-$barIndex'),
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
        child: _TooltipCard(
          volumeMl: day.volumeMl,
          goalMl: day.goalMl,
          percentage: day.percentage,
          pointsLeft: showOnRight,
        ),
      ),
    );
  }

  /// Formats the current week range for accessibility labels
  ///
  /// Returns date range in "MMM d to MMM d" format (e.g., "Jan 1 to Jan 7")
  /// for screen reader users to understand the temporal context of the chart.
  ///
  /// Example outputs:
  /// - "Jan 15 to Jan 21" (same month)
  /// - "Dec 26 to Jan 1" (spanning months)
  /// - "Feb 29 to Mar 6" (leap year)
  String _formatWeekRange() {
    final weekStart = ref.read(focusedWeekStartProvider);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final startFormatted = DateFormat.MMMd().format(weekStart);
    final endFormatted = DateFormat.MMMd().format(weekEnd);
    return '$startFormatted to $endFormatted';
  }
}

/// Compact 2-line tooltip card with shadow and directional arrow.
///
/// Displays fluid volume data when user taps a bar:
///  - Line 1: "85ml / 100ml"
///  - Line 2: "(85%)"
/// Includes a small triangle arrow that points toward the tapped bar so
/// the tooltip feels visually anchored to the chart.
class _TooltipCard extends StatelessWidget {
  /// Creates a [_TooltipCard]
  const _TooltipCard({
    required this.volumeMl,
    required this.goalMl,
    required this.percentage,
    required this.pointsLeft,
  });

  /// Volume administered in milliliters
  final double volumeMl;

  /// Daily goal in milliliters
  final double goalMl;

  /// Goal achievement percentage
  final double percentage;

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
            children: [
              // Line 1: "85ml / 100ml"
              Text(
                '${volumeMl.toStringAsFixed(0)}ml / ${goalMl.toStringAsFixed(0)}ml',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              // Line 2: "(85%)"
              Text(
                '(${percentage.toStringAsFixed(0)}%)',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
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

/// Ghost empty-state widget for weekly fluid chart
///
/// Displays a placeholder chart with ghost bars, optional goal line,
/// and informative copy when no data exists for the focused week.
/// Shows a CTA button only for the current week.
class FluidVolumeChartEmptyState extends StatelessWidget {
  /// Creates a [FluidVolumeChartEmptyState]
  const FluidVolumeChartEmptyState({
    required this.chartData,
    required this.showLogCta,
    super.key,
  });

  /// Chart data for the week (used for goal line positioning)
  final FluidChartData chartData;

  /// Whether to show the log fluids CTA (true only for current week)
  final bool showLogCta;

  static const double _chartHeight = 200;
  static const double _barWidth = 40;
  static const double _barBorderRadius = 10;
  static const double _ghostBarHeight = 30; // Small placeholder height
  static const double _ghostBarOpacity = 0.15; // Very light ghost bars

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const SizedBox(height: _chartHeight);
    }

    final semanticsLabel = showLogCta
        ? 'Weekly fluid therapy chart – no data yet for this week. '
              'Log fluids to see your progress.'
        : 'Weekly fluid therapy chart – no data for this week.';
    return Semantics(
      label: semanticsLabel,
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 250),
        child: SizedBox(
          height: _chartHeight,
          child: Stack(
            children: [
              // Ghost bars row
              _buildGhostBars(),

              // Goal line (if exists)
              if (chartData.goalLineY != null) _buildGoalLine(context),

              // Empty state content overlay
              _buildEmptyStateContent(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a row of 7 ghost bars aligned with weekday columns
  Widget _buildGhostBars() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            return Container(
              width: _barWidth,
              height: _ghostBarHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: _ghostBarOpacity * 0.8),
                    AppColors.primary.withValues(alpha: _ghostBarOpacity),
                  ],
                ),
                borderRadius: BorderRadius.circular(_barBorderRadius),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Builds goal line overlay (same style as real chart)
  Widget _buildGoalLine(BuildContext context) {
    final goalY = chartData.goalLineY!;
    final goalValue = chartData.days
        .firstWhere(
          (d) => d.goalMl > 0,
          orElse: () => chartData.days.first,
        )
        .goalMl;

    // Map chart Y-value to pixel offset
    final clampedGoal = goalY.clamp(0, chartData.maxVolume);
    final ratio = 1 - (clampedGoal / chartData.maxVolume);
    final goalLineTop = (ratio * _chartHeight)
        .clamp(0, _chartHeight - 24)
        .toDouble();

    return Stack(
      children: [
        // Dashed goal line spanning the width
        Positioned(
          left: 0,
          right: 0,
          top: goalLineTop,
          child: CustomPaint(
            painter: _DashedLinePainter(
              color: Colors.amber[600]!,
              dashWidth: 8,
              dashSpace: 4,
            ),
            child: const SizedBox(
              height: 1,
              width: double.infinity,
            ),
          ),
        ),
        // Goal label pill
        Positioned(
          right: 8,
          top: goalLineTop - 12.0,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.amber[600]!.withValues(alpha: 0.8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Goal ${goalValue.toStringAsFixed(0)}ml',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds centered empty state content with optional CTA
  Widget _buildEmptyStateContent(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 45, // Reserve bottom 45px for ghost bars
      //(30px height + 4px padding + margin)
      child: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Icon(
                  Icons.water_drop_outlined,
                  size: 36,
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  l10n.progressChartEmptyTitle,
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    l10n.progressChartEmptySubtitle,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // CTA button (only for current week)
                if (showLogCta) ...[
                  const SizedBox(height: 12),
                  _buildLogCtaButton(context, l10n),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the log fluids CTA button
  Widget _buildLogCtaButton(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Semantics(
      button: true,
      label: l10n.progressChartEmptyCta,
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            showLoggingBottomSheet(
              context,
              const FluidLoggingScreen(),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            child: Text(
              l10n.progressChartEmptyCta,
              style: AppTextStyles.buttonPrimary.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for drawing dashed horizontal lines
class _DashedLinePainter extends CustomPainter {
  /// Creates a [_DashedLinePainter]
  const _DashedLinePainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
  });

  /// Color of the dashed line
  final Color color;

  /// Width of each dash segment
  final double dashWidth;

  /// Space between dash segments
  final double dashSpace;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) {
    return color != oldDelegate.color ||
        dashWidth != oldDelegate.dashWidth ||
        dashSpace != oldDelegate.dashSpace;
  }
}
