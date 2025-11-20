import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/progress/models/injection_site_stats.dart';

/// Donut chart displaying injection site distribution
///
/// Shows percentage breakdown of injection sites used in the last N sessions.
/// Uses pastel colors for empathetic visual tone, with consistent color
/// mapping for predictability.
///
/// Features:
/// - Donut shape (50-60% center space)
/// - Percentage labels in pie sections
/// - Legend below with full context
/// - Only shows used sites
/// - Consistent color mapping per site
class InjectionSitesDonutChart extends StatelessWidget {
  /// Creates an [InjectionSitesDonutChart]
  const InjectionSitesDonutChart({
    required this.stats,
    super.key,
  });

  /// Injection site statistics to visualize
  final InjectionSiteStats stats;

  /// Color mapping for injection sites (consistent and pastel)
  static const Map<FluidLocation, Color> _siteColors = {
    FluidLocation.shoulderBladeLeft: Color(0xFF9DCBBF), // Pastel Teal
    FluidLocation.shoulderBladeRight: Color(0xFFC4B5FD), // Pastel Lavender
    FluidLocation.hipBonesLeft: Color(0xFFF0C980), // Pastel Amber
    FluidLocation.hipBonesRight: Color(0xFFEDA08F), // Pastel Coral
  };

  /// Get color for a specific injection site
  Color _getColorForSite(FluidLocation site) {
    return _siteColors[site] ?? AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final usedSites = stats.getUsedSites();

    if (usedSites.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Donut chart with accessibility
        Semantics(
          label: 'Injection site distribution chart showing '
              '${usedSites.length} '
              '${usedSites.length == 1 ? 'site' : 'sites'} used',
          child: SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 65, // 50-60% for donut effect
                sections: usedSites.map((site) {
                  final count = stats.getCount(site);
                  final percentage = stats.getPercentage(site);
                  final color = _getColorForSite(site);

                  return PieChartSectionData(
                    value: count.toDouble(),
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    color: color,
                    // Add semantic label for screen readers
                    badgeWidget: Semantics(
                      label: '${site.getLocalizedName(context)}: '
                          '${percentage.toStringAsFixed(0)}%, '
                          '$count ${count == 1 ? 'session' : 'sessions'}',
                      excludeSemantics: true,
                      child: const SizedBox.shrink(),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Legend
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: usedSites.map((site) {
            final count = stats.getCount(site);
            final percentage = stats.getPercentage(site);
            final color = _getColorForSite(site);

            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${site.getLocalizedName(context)}: $count '
                        '${count == 1 ? 'session' : 'sessions'} '
                        '(${percentage.toStringAsFixed(0)}%)',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
