/// Service for managing offline logging queue
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hydracat/features/logging/exceptions/logging_exceptions.dart';
import 'package:hydracat/features/logging/models/logging_operation.dart';
import 'package:hydracat/features/logging/services/logging_service.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing offline logging operations queue
///
/// Handles queueing, syncing, and retry logic for logging operations
/// when the device is offline or when operations fail.
class OfflineLoggingService {
  /// Creates an [OfflineLoggingService]
  OfflineLoggingService(
    this._prefs,
    this._loggingService, [
    this._analyticsService,
  ]);

  final SharedPreferences _prefs;
  final LoggingService _loggingService;
  final AnalyticsService? _analyticsService;

  static const String _queueKey = 'logging_operation_queue';
  static const int _maxQueueSize = 200;
  static const int _softWarningThreshold = 50;
  static const int _maxRetries = 5;

  // Exponential backoff: 1s, 2s, 4s, 8s, 30s (capped)
  static const List<Duration> _retryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 30),
  ];

  /// Add operation to queue
  ///
  /// Throws [QueueFullException] if queue is at max capacity.
  /// Throws [QueueWarningException] if queue exceeds soft warning threshold.
  Future<void> enqueueOperation(LoggingOperation operation) async {
    final queue = await _loadQueue();

    // Check hard limit
    if (queue.length >= _maxQueueSize) {
      if (kDebugMode) {
        debugPrint(
          '[OfflineLogging] Queue full (${queue.length}/$_maxQueueSize)',
        );
      }

      // Track queue full error
      await _analyticsService?.trackError(
        errorType: AnalyticsErrorTypes.offlineQueueFull,
        errorContext: 'Queue size: ${queue.length}',
      );

      throw QueueFullException(queue.length);
    }

    // Remove expired operations (30 days TTL)
    queue
      ..removeWhere((op) => op.isExpired)
      ..add(operation);
    await _saveQueue(queue);

    if (kDebugMode) {
      debugPrint(
        '[OfflineLogging] Enqueued ${operation.runtimeType} '
        '(${queue.length} total)',
      );
    }

    // Track offline queuing
    await _analyticsService?.trackFeatureUsed(
      featureName: AnalyticsEvents.offlineLoggingQueued,
      additionalParams: {
        AnalyticsParams.queueSize: queue.length,
        AnalyticsParams.treatmentType:
            operation is CreateMedicationOperation ||
                operation is UpdateMedicationOperation
            ? 'medication'
            : 'fluid',
      },
    );

    // Check soft warning threshold AFTER queuing
    // (operation succeeded but warn user)
    if (queue.length >= _softWarningThreshold) {
      if (kDebugMode) {
        debugPrint(
          '[OfflineLogging] Queue approaching limit: ${queue.length}/$_maxQueueSize',
        );
      }
      throw QueueWarningException(queue.length);
    }
  }

  /// Get all pending operations
  Future<List<LoggingOperation>> getPendingOperations() async {
    final queue = await _loadQueue();
    return queue.where((op) => op.status == OperationStatus.pending).toList();
  }

  /// Get failed operations
  Future<List<LoggingOperation>> getFailedOperations() async {
    final queue = await _loadQueue();
    return queue.where((op) => op.status == OperationStatus.failed).toList();
  }

  /// Get queue size
  Future<int> getQueueSize() async {
    final queue = await _loadQueue();
    return queue.length;
  }

  /// Check if warning threshold reached
  Future<bool> shouldShowWarning() async {
    final size = await getQueueSize();
    return size >= _softWarningThreshold;
  }

  /// Sync all pending operations
  ///
  /// Returns (successCount, failureCount)
  Future<(int, int)> syncPendingOperations() async {
    final startTime = DateTime.now();
    final queue = await _loadQueue();
    final pending = queue
        .where((op) => op.status == OperationStatus.pending)
        .toList();

    if (pending.isEmpty) {
      if (kDebugMode) {
        debugPrint('[OfflineLogging] No pending operations to sync');
      }
      return (0, 0);
    }

    if (kDebugMode) {
      debugPrint(
        '[OfflineLogging] Syncing ${pending.length} pending operations',
      );
    }

    final initialQueueSize = pending.length;
    var successCount = 0;
    var failureCount = 0;

    for (final operation in pending) {
      // Mark as syncing
      final syncingOp = operation.copyWithStatus(
        status: OperationStatus.syncing,
      );
      await _updateOperation(syncingOp);

      // Try to sync with exponential backoff
      final success = await _syncOperationWithRetry(operation);

      if (success) {
        // Remove from queue
        await _removeOperation(operation.id);
        successCount++;
      } else {
        // Mark as failed after max retries
        final failedOp = operation.copyWithStatus(
          status: OperationStatus.failed,
          lastError: 'Max retries exceeded',
        );
        await _updateOperation(failedOp);
        failureCount++;
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[OfflineLogging] Sync complete: $successCount success, '
        '$failureCount failed',
      );
    }

    // Track sync completion
    final durationMs = DateTime.now().difference(startTime).inMilliseconds;
    await _analyticsService?.trackOfflineSync(
      queueSize: initialQueueSize,
      successCount: successCount,
      failureCount: failureCount,
      syncDurationMs: durationMs,
    );

    // Explicit failure hook for product insights
    if (failureCount > 0) {
      await _analyticsService?.trackLoggingFailure(
        errorType: AnalyticsEvents.offlineSyncFailed,
        source: 'offline_sync',
        exception: 'SyncFailedException',
        extra: {
          AnalyticsParams.queueSize: initialQueueSize,
          AnalyticsParams.failureCount: failureCount,
        },
      );
    }

    // Throw exception if any operations failed
    // This signals to the UI that sync partially failed and
    // user should see retry option
    if (failureCount > 0) {
      throw SyncFailedException(failureCount, 'Max retries exceeded');
    }

    return (successCount, failureCount);
  }

  /// Sync single operation with exponential backoff
  Future<bool> _syncOperationWithRetry(LoggingOperation operation) async {
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        // Execute operation via LoggingService
        await _executeOperation(operation);
        return true; // Success!
      } on Exception catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[OfflineLogging] Sync attempt ${attempt + 1}/${_maxRetries + 1} '
            'failed: $e',
          );
        }

        // Update retry count
        final updated = operation.copyWithStatus(
          retryCount: attempt + 1,
          lastError: e.toString(),
        );
        await _updateOperation(updated);

        // Wait before retry (exponential backoff)
        if (attempt < _maxRetries) {
          final delay = _retryDelays[attempt.clamp(0, _retryDelays.length - 1)];
          await Future<void>.delayed(delay);
        }
      }
    }

    return false; // Failed after max retries
  }

  /// Execute operation via LoggingService
  Future<void> _executeOperation(LoggingOperation operation) async {
    switch (operation) {
      case final CreateMedicationOperation op:
        await _loggingService.logMedicationSession(
          userId: op.userId,
          petId: op.petId,
          session: op.session,
          todaysSchedules: op.todaysSchedules,
          recentSessions: op.recentSessions,
        );
      case final CreateFluidOperation op:
        await _loggingService.logFluidSession(
          userId: op.userId,
          petId: op.petId,
          session: op.session,
          todaysSchedules: op.todaysSchedule != null
              ? [op.todaysSchedule!]
              : [],
          recentSessions: [], // Fluids don't need duplicate detection
        );
      case final UpdateMedicationOperation op:
        await _loggingService.updateMedicationSession(
          userId: op.userId,
          petId: op.petId,
          oldSession: op.oldSession,
          newSession: op.newSession,
        );
      case final UpdateFluidOperation op:
        await _loggingService.updateFluidSession(
          userId: op.userId,
          petId: op.petId,
          oldSession: op.oldSession,
          newSession: op.newSession,
        );
      case final QuickLogAllOperation op:
        await _loggingService.quickLogAllTreatments(
          userId: op.userId,
          petId: op.petId,
          todaysSchedules: op.todaysSchedules,
        );
    }
  }

  /// Retry failed operation
  ///
  /// Returns true if sync succeeded, false otherwise
  Future<bool> retryFailedOperation(String operationId) async {
    final queue = await _loadQueue();
    final operationIndex = queue.indexWhere((op) => op.id == operationId);

    if (operationIndex == -1) {
      if (kDebugMode) {
        debugPrint('[OfflineLogging] Operation $operationId not found');
      }
      return false;
    }

    final operation = queue[operationIndex];

    // Reset to pending
    final resetOp = operation.copyWithStatus(
      status: OperationStatus.pending,
      retryCount: 0,
    );
    await _updateOperation(resetOp);

    // Sync immediately
    return _syncOperationWithRetry(resetOp);
  }

  /// Clear specific operation
  Future<void> removeOperation(String operationId) async {
    await _removeOperation(operationId);
  }

  /// Clear all operations (dangerous!)
  Future<void> clearAllOperations() async {
    await _prefs.remove(_queueKey);
    if (kDebugMode) {
      debugPrint('[OfflineLogging] Cleared all operations');
    }
  }

  // ============================================
  // Internal Queue Management
  // ============================================

  Future<List<LoggingOperation>> _loadQueue() async {
    final json = _prefs.getString(_queueKey);
    if (json == null) return [];

    try {
      final decoded = jsonDecode(json) as List;
      return decoded
          .map(
            (item) => LoggingOperation.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[OfflineLogging] Failed to load queue: $e');
      }
      return [];
    }
  }

  Future<void> _saveQueue(List<LoggingOperation> queue) async {
    final json = jsonEncode(queue.map((op) => op.toJson()).toList());
    await _prefs.setString(_queueKey, json);
  }

  Future<void> _updateOperation(LoggingOperation updated) async {
    final queue = await _loadQueue();
    final index = queue.indexWhere((op) => op.id == updated.id);
    if (index != -1) {
      queue[index] = updated;
      await _saveQueue(queue);
    }
  }

  Future<void> _removeOperation(String id) async {
    final queue = await _loadQueue();
    queue.removeWhere((op) => op.id == id);
    await _saveQueue(queue);
  }
}
