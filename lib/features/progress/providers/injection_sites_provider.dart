import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/progress/models/injection_site_stats.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';

/// Provider for injection site statistics based on last 20 sessions
final injectionSitesStatsProvider =
    FutureProvider<InjectionSiteStats>((ref) async {
  final user = ref.watch(currentUserProvider);
  final pet = ref.watch(primaryPetProvider);

  if (user == null || pet == null) {
    if (kDebugMode) {
      debugPrint('[InjectionSitesProvider] No user or pet available');
    }
    return const InjectionSiteStats(siteUsage: {}, totalSessions: 0);
  }

  try {
    final firestore = FirebaseFirestore.instance;

    // Query last 20 fluid sessions by dateTime
    // Filter in Dart for sessions with injection sites (simpler & cheaper)
    final query = firestore
        .collection('users')
        .doc(user.id)
        .collection('pets')
        .doc(pet.id)
        .collection('fluidSessions')
        .orderBy('dateTime', descending: true)
        .limit(20);

    if (kDebugMode) {
      debugPrint(
        '[InjectionSitesProvider] Querying last 20 sessions for pet ${pet.id}',
      );
    }

    final snapshot = await query.get();

    if (kDebugMode) {
      debugPrint(
        '[InjectionSitesProvider] Retrieved ${snapshot.docs.length} sessions',
      );
    }

    // Aggregate statistics
    final siteUsage = <FluidLocation, int>{};
    var sessionCount = 0;

    for (final doc in snapshot.docs) {
      try {
        final session = FluidSession.fromJson(doc.data());
        siteUsage[session.injectionSite] =
            (siteUsage[session.injectionSite] ?? 0) + 1;
        sessionCount++;
      } on Exception catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[InjectionSitesProvider] Error parsing session ${doc.id}: $e',
          );
        }
      }
    }

    final stats = InjectionSiteStats(
      siteUsage: siteUsage,
      totalSessions: sessionCount,
    );

    if (kDebugMode) {
      debugPrint('[InjectionSitesProvider] Stats: $stats');
    }

    return stats;
  } on Exception catch (e) {
    if (kDebugMode) {
      debugPrint('[InjectionSitesProvider] Error fetching stats: $e');
    }
    return const InjectionSiteStats(siteUsage: {}, totalSessions: 0);
  }
});
