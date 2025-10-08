/// Riverpod providers for offline logging queue management
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/logging/services/offline_logging_service.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/connectivity_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/shared/services/connectivity_service.dart'
    as connectivity;

// ============================================
// Service Providers
// ============================================

/// Provider for OfflineLoggingService instance
final offlineLoggingServiceProvider = Provider<OfflineLoggingService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  final analytics = ref.read(analyticsServiceDirectProvider);
  return OfflineLoggingService(prefs, loggingService, analytics);
});

// ============================================
// Queue State Providers
// ============================================

/// Provider for queue size (updates periodically)
final queueSizeProvider = StreamProvider<int>((ref) async* {
  final service = ref.watch(offlineLoggingServiceProvider);

  // Initial value
  yield await service.getQueueSize();

  // Update every 5 seconds (or when manually invalidated)
  while (true) {
    await Future<void>.delayed(const Duration(seconds: 5));
    yield await service.getQueueSize();
  }
});

/// Provider for warning state (soft threshold: 50 operations)
final shouldShowQueueWarningProvider = Provider<bool>((ref) {
  final queueSize = ref.watch(queueSizeProvider);
  return queueSize.when(
    data: (size) => size >= 50,
    loading: () => false,
    error: (_, _) => false,
  );
});

/// Toast message provider for sync notifications
final syncToastMessageProvider = StateProvider<String?>((ref) => null);

// ============================================
// Auto-Sync Listener
// ============================================

/// Auto-sync listener - syncs when connectivity restored
///
/// This provider watches for connectivity changes and automatically
/// triggers sync when the device goes from offline to online.
final autoSyncListenerProvider = Provider<void>((ref) {
  // Watch connection state
  ref.listen<AsyncValue<connectivity.ConnectionState>>(
    connectionStateProvider,
    (previous, next) {
      next.whenData((state) async {
        // Trigger sync when going from offline to online
        final wasOffline =
            previous?.value == connectivity.ConnectionState.offline;
        final isNowOnline = state == connectivity.ConnectionState.connected;

        if (wasOffline && isNowOnline) {
          final offlineService = ref.read(offlineLoggingServiceProvider);
          final (success, failures) = await offlineService
              .syncPendingOperations();

          // Show toast notifications
          if (success > 0) {
            ref.read(syncToastMessageProvider.notifier).state =
                'Synced $success treatment${success == 1 ? '' : 's'}';
          }

          if (failures > 0) {
            ref.read(syncToastMessageProvider.notifier).state =
                '$failures operation${failures == 1 ? '' : 's'} failed to sync';
          }

          // Invalidate queue size to refresh UI
          ref.invalidate(queueSizeProvider);
        }
      });
    },
  );
});
