import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/weekly_progress_provider.dart';
import 'package:hydracat/shared/widgets/fluid/water_drop_painter.dart';

/// Water drop progress card showing weekly fluid intake progress
///
/// Displays:
/// - Animated water drop (fills based on weekly progress)
/// - Current volume vs goal
/// - Last injection site used
/// - Completion percentage with color coding
///
/// Data source: weeklyProgressProvider (SummaryService + cached schedule)
class WaterDropProgressCard extends ConsumerStatefulWidget {
  /// Creates a water drop progress card
  const WaterDropProgressCard({
    super.key,
    this.padding,
  });

  /// Optional custom padding for the card content
  final EdgeInsetsGeometry? padding;

  @override
  ConsumerState<WaterDropProgressCard> createState() =>
      _WaterDropProgressCardState();
}

class _WaterDropProgressCardState
    extends ConsumerState<WaterDropProgressCard> {
  bool _hasTrackedView = false;

  @override
  Widget build(BuildContext context) {
    final weeklySummaryAsync = ref.watch(weeklyProgressProvider);

    return weeklySummaryAsync.when(
      data: (vm) {
        if (vm == null) {
          return const SizedBox.shrink();
        }

        // Track view event once per card lifecycle
        if (!_hasTrackedView) {
          _hasTrackedView = true;
          _trackWeeklyProgressViewed(vm);
        }

        return _buildCard(context, vm);
      },
      loading: () => _buildLoadingCard(context),
      error: (error, stack) => _buildErrorCard(context, error),
    );
  }

  /// Track weekly progress card view analytics
  void _trackWeeklyProgressViewed(WeeklyProgressViewModel vm) {
    // Run asynchronously to avoid blocking UI
    Future.microtask(() async {
      try {
        final analyticsService = ref.read(analyticsServiceDirectProvider);
        final petId = ref.read(primaryPetProvider)?.id;
        final now = DateTime.now();
        final daysRemainingInWeek = 7 - now.weekday;

        await analyticsService.trackWeeklyProgressViewed(
          fillPercentage: vm.fillPercentage,
          currentVolume: vm.givenMl,
          goalVolume: vm.goalMl,
          daysRemainingInWeek: daysRemainingInWeek,
          lastInjectionSite:
              vm.lastInjectionSite != 'None yet' ? vm.lastInjectionSite : null,
          petId: petId,
        );
      } on Exception catch (e) {
        // Silently catch analytics errors (shouldn't block UI)
        if (kDebugMode) {
          debugPrint('[Analytics] Failed to track weekly progress viewed: $e');
        }
      }
    });
  }

  /// Track weekly goal achievement analytics
  void _trackWeeklyGoalAchieved(WeeklyProgressViewModel vm) {
    Future.microtask(() async {
      try {
        final analyticsService = ref.read(analyticsServiceDirectProvider);
        final petId = ref.read(primaryPetProvider)?.id;
        final now = DateTime.now();
        final daysRemainingInWeek = 7 - now.weekday;
        final achievedEarly = now.weekday < 7; // Before Sunday

        await analyticsService.trackWeeklyGoalAchieved(
          finalVolume: vm.givenMl,
          goalVolume: vm.goalMl,
          daysRemainingInWeek: daysRemainingInWeek,
          achievedEarly: achievedEarly,
          petId: petId,
        );
      } on Exception catch (e) {
        if (kDebugMode) {
          debugPrint('[Analytics] Failed to track weekly goal achieved: $e');
        }
      }
    });
  }

  Widget _buildCard(BuildContext context, WeeklyProgressViewModel vm) {
    final currentMl = vm.givenMl;
    final goalMl = vm.goalMl;
    final fillPercentage = vm.fillPercentage;
    final percentageDisplay = (vm.fillPercentage * 100).round();
    final lastSiteDisplay = vm.lastInjectionSite;

    return Semantics(
      container: true,
      label: 'Weekly fluid intake progress card',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: widget.padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, 4),
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main content: Water drop + stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Left: Water drop (60% space)
                Flexible(
                  flex: 6,
                  child: WaterDropWidget(
                    fillPercentage: fillPercentage,
                    height: 220,
                    onGoalAchieved: () => _trackWeeklyGoalAchieved(vm),
                  ),
                ),

                const SizedBox(width: 24),

                // Right: Text stats (40% space)
                Flexible(
                  flex: 4,
                  child: _buildTextStats(
                    context,
                    currentMl: currentMl,
                    goalMl: goalMl,
                    percentageDisplay: percentageDisplay,
                    fillPercentage: fillPercentage,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Full-width separator
            Container(
              height: 1,
              color: AppColors.border,
            ),

            const SizedBox(height: 12),

            // Injection site (centered, full-width)
            _buildInjectionSite(lastSiteDisplay),
          ],
        ),
      ),
    );
  }

  Widget _buildTextStats(
    BuildContext context, {
    required num currentMl,
    required int goalMl,
    required int percentageDisplay,
    required double fillPercentage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Current Volume (Large, prominent)
        Text(
          _formatMl(currentMl),
          style: AppTextStyles.display, // 32px, semi-bold
        ),

        const SizedBox(height: 8),

        // Goal Volume with slash separator (Small, muted)
        Text(
          '/${_formatMl(goalMl)}',
          style: AppTextStyles.h2.copyWith(
            fontSize: 14, // Reduced from 20px for clearer hierarchy
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 16),

        // Percentage with descriptive text
        // (Medium size, brand color for emphasis)
        Text(
          '$percentageDisplay% of your goal',
          style: AppTextStyles.h2.copyWith(
            fontSize: 16, // Medium size between goal and main number
            color: AppColors.primary, // Brand color for visual interest
          ),
        ),
      ],
    );
  }

  /// Build injection site display (centered, full-width)
  Widget _buildInjectionSite(String lastSiteDisplay) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.location_on,
          size: 14,
          color: AppColors.primary,
        ),
        const SizedBox(width: 4),
        Text(
          'Last: ',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          lastSiteDisplay,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
      height: 260, // Fixed height (220 + padding)
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, Object error) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Unable to load weekly progress',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format volume (ml to L conversion)
  String _formatMl(num ml) {
    if (ml >= 1000) {
      final liters = ml / 1000.0;
      return '${liters.toStringAsFixed(liters >= 10 ? 0 : 1)} L';
    }
    return '${ml.round()} ml';
  }
}
