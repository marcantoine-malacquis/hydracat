import 'package:flutter/foundation.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';

/// Statistics for injection site usage across fluid sessions
@immutable
class InjectionSiteStats {
  /// Creates injection site statistics
  const InjectionSiteStats({
    required this.siteUsage,
    required this.totalSessions,
  });

  /// Map of injection sites to their usage count
  final Map<FluidLocation, int> siteUsage;

  /// Total number of sessions included in statistics
  final int totalSessions;

  /// Whether there are any sessions
  bool get hasSessions => totalSessions > 0;

  /// Get percentage for a specific site (0-100)
  double getPercentage(FluidLocation site) {
    if (totalSessions == 0) return 0;
    final count = siteUsage[site] ?? 0;
    return (count / totalSessions) * 100;
  }

  /// Get count for a specific site
  int getCount(FluidLocation site) {
    return siteUsage[site] ?? 0;
  }

  /// Get sorted list of sites by usage (most used first)
  List<FluidLocation> getSortedSites() {
    final sites = siteUsage.keys.toList()
      ..sort((a, b) => siteUsage[b]!.compareTo(siteUsage[a]!));
    return sites;
  }

  /// Get only sites that have been used (in enum order for stable display)
  List<FluidLocation> getUsedSites() {
    // Return sites in enum declaration order for consistent display
    // This ensures stable colors and predictable visual experience
    return FluidLocation.values
        .where((site) => (siteUsage[site] ?? 0) > 0)
        .toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is InjectionSiteStats &&
        mapEquals(other.siteUsage, siteUsage) &&
        other.totalSessions == totalSessions;
  }

  @override
  int get hashCode => Object.hash(siteUsage, totalSessions);

  @override
  String toString() {
    return 'InjectionSiteStats('
        'siteUsage: $siteUsage, '
        'totalSessions: $totalSessions'
        ')';
  }
}
