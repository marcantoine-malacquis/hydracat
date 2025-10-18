/// Riverpod provider for cache management service
library;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/shared/services/cache_management_service.dart';

/// Provider for CacheManagementService instance
///
/// Dependencies:
/// - SharedPreferences (from sharedPreferencesProvider)
/// - FirebaseAnalytics (optional, for tracking cache operations)
final cacheManagementServiceProvider = Provider<CacheManagementService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final analytics = FirebaseAnalytics.instance;

  return CacheManagementService(prefs, analytics);
});
