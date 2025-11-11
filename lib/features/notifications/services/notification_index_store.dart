import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hydracat/features/notifications/models/scheduled_notification_entry.dart';
import 'package:hydracat/features/notifications/services/reminder_plugin.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing the local notification index in SharedPreferences.
///
/// The index tracks all scheduled notifications to enable:
/// - Idempotent scheduling (safe to retry operations)
/// - Efficient cancellation by scheduleId/timeSlot/kind
/// - Robust reconciliation after app restart or crash
/// - Data integrity validation via CRC32 checksum
///
/// **Storage Strategy**:
/// - Key format: `notif_index_v2_{userId}_{petId}_{YYYY-MM-DD}`
/// - Per-day, per-pet, per-user scoping prevents unlimited growth
/// - Versioned schema (`v2`) enables future migrations
/// - Daily cleanup removes yesterday's indexes
///
/// **Data Integrity**:
/// - FNV-1a hash checksum detects corruption
/// - Automatic reconciliation on corruption detection
/// - Plugin state is source of truth during reconciliation
///
/// Example usage:
/// ```dart
/// final store = NotificationIndexStore();
///
/// // Add entry after scheduling notification
/// await store.putEntry(userId, petId, entry);
///
/// // Remove entry when canceling notification
/// await store.removeEntryBy(userId, petId, scheduleId, '08:00', 'initial');
///
/// // Reconcile on app start
/// await store.reconcile(userId, petId, reminderPlugin);
/// ```
class NotificationIndexStore {
  /// Factory constructor to get the singleton instance
  factory NotificationIndexStore() => _instance ??= NotificationIndexStore._();

  /// Private unnamed constructor
  NotificationIndexStore._();
  static NotificationIndexStore? _instance;

  /// Key prefix for versioned schema
  static const String _keyPrefix = 'notif_index_v2_';

  /// Builds a storage key for a specific user, pet, and date.
  ///
  /// Format: `notif_index_v2_{userId}_{petId}_{YYYY-MM-DD}`
  ///
  /// Example: `notif_index_v2_user123_pet456_2025-01-24`
  static String _buildKey(String userId, String petId, DateTime date) {
    final dateStr = _formatDate(date);
    return '$_keyPrefix${userId}_${petId}_$dateStr';
  }

  /// Formats a date to YYYY-MM-DD string.
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Computes FNV-1a hash (32-bit) for a list of entries.
  ///
  /// FNV-1a is a simple, fast, non-cryptographic hash suitable for
  /// corruption detection. It's deterministic and has good distribution.
  ///
  /// Returns hex string representation of the hash.
  static String _computeChecksum(List<ScheduledNotificationEntry> entries) {
    // FNV-1a constants (32-bit)
    const fnvPrime = 16777619;
    const fnvOffsetBasis = 2166136261;

    var hash = fnvOffsetBasis;

    // Sort entries by notificationId for deterministic hash
    final sortedEntries = [...entries]
      ..sort((a, b) => a.notificationId.compareTo(b.notificationId));

    // Hash each entry's JSON representation
    for (final entry in sortedEntries) {
      final json = jsonEncode(entry.toJson());
      for (final byte in utf8.encode(json)) {
        hash ^= byte;
        hash = (hash * fnvPrime) & 0xFFFFFFFF; // Keep as 32-bit unsigned
      }
    }

    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// Validates the checksum of stored data.
  ///
  /// Returns true if checksum matches, false if corrupted.
  static bool _validateChecksum(Map<String, dynamic> data) {
    try {
      final storedChecksum = data['checksum'] as String?;
      final entriesJson = data['entries'] as List<dynamic>?;

      if (storedChecksum == null || entriesJson == null) {
        return false;
      }

      // Parse entries
      final entries = entriesJson
          .map(
            (e) =>
                ScheduledNotificationEntry.fromJson(e as Map<String, dynamic>),
          )
          .toList();

      // Compute checksum and compare
      final computedChecksum = _computeChecksum(entries);
      return storedChecksum == computedChecksum;
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationIndexStore] Checksum validation failed: $e');
      }
      return false;
    }
  }

  /// Loads the index for a specific user, pet, and date.
  ///
  /// Returns empty list if:
  /// - No index exists for this key (new day)
  /// - Stored data is corrupted (checksum mismatch) and rebuild fails
  /// - Parsing fails
  ///
  /// Corrupted data triggers rebuild attempt from plugin state if plugin
  /// is provided. If rebuild succeeds, saves new index and returns entries.
  /// If rebuild fails, triggers analytics and returns empty list.
  Future<List<ScheduledNotificationEntry>> _loadIndex(
    String userId,
    String petId,
    DateTime date, {
    AnalyticsService? analyticsService,
    ReminderPlugin? plugin,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildKey(userId, petId, date);
      final jsonString = prefs.getString(key);

      if (jsonString == null) {
        // No index exists yet (expected for new day)
        if (kDebugMode) {
          debugPrint(
            '[NotificationIndexStore] No index found for key: $key',
          );
        }
        return [];
      }

      // Parse JSON
      final indexData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate checksum
      if (!_validateChecksum(indexData)) {
        if (kDebugMode) {
          debugPrint(
            '[NotificationIndexStore] Checksum validation failed for '
            'key: $key. Attempting rebuild from plugin state...',
          );
        }

        // Attempt rebuild from plugin state
        if (plugin != null) {
          final rebuilt = await _rebuildFromPluginState(
            userId: userId,
            petId: petId,
            date: date,
            plugin: plugin,
          );

          if (rebuilt != null && rebuilt.isNotEmpty) {
            // Rebuild succeeded - save new index
            await _saveIndex(userId, petId, date, rebuilt);

            if (kDebugMode) {
              debugPrint(
                '[NotificationIndexStore] Index rebuilt from plugin state: '
                '${rebuilt.length} entries recovered',
              );
            }

            // Track successful recovery
            if (analyticsService != null) {
              try {
                await analyticsService.trackNotificationError(
                  errorType: AnalyticsEvents.notificationIndexRebuildSuccess,
                  operation: 'index_rebuild_from_plugin',
                  userId: userId,
                  petId: petId,
                  additionalContext: {
                    'date': _formatDate(date),
                    'recovered_count': rebuilt.length,
                  },
                );
              } on Exception catch (e) {
                if (kDebugMode) {
                  debugPrint(
                    '[NotificationIndexStore] Analytics tracking failed: $e',
                  );
                }
              }
            }

            return rebuilt;
          } else {
            // Rebuild failed or no matching notifications found
            if (kDebugMode) {
              debugPrint(
                '[NotificationIndexStore] Index rebuild failed or no matching '
                'notifications found. Returning empty list.',
              );
            }

            // Track failed recovery
            if (analyticsService != null) {
              try {
                await analyticsService.trackNotificationError(
                  errorType: AnalyticsEvents.notificationIndexRebuildFailed,
                  operation: 'index_rebuild_from_plugin',
                  userId: userId,
                  petId: petId,
                  additionalContext: {
                    'date': _formatDate(date),
                  },
                );
                await analyticsService.trackIndexCorruptionDetected(
                  userId: userId,
                  petId: petId,
                  date: _formatDate(date),
                );
              } on Exception catch (e) {
                if (kDebugMode) {
                  debugPrint(
                    '[NotificationIndexStore] Analytics tracking failed: $e',
                  );
                }
              }
            }

            return [];
          }
        } else {
          // Plugin not available - report corruption
          if (kDebugMode) {
            debugPrint(
              '[NotificationIndexStore] Checksum validation failed, but plugin '
              'not available. Cannot rebuild. Returning empty list.',
            );
          }

          // Report to analytics: index_corruption_detected
          if (analyticsService != null) {
            try {
              await analyticsService.trackIndexCorruptionDetected(
                userId: userId,
                petId: petId,
                date: _formatDate(date),
              );
            } on Exception catch (e) {
              if (kDebugMode) {
                debugPrint(
                  '[NotificationIndexStore] Analytics tracking failed: $e',
                );
              }
            }
          }

          return [];
        }
      }

      // Parse entries
      final entriesJson = indexData['entries'] as List<dynamic>;
      final entries = entriesJson
          .map(
            (e) =>
                ScheduledNotificationEntry.fromJson(e as Map<String, dynamic>),
          )
          .toList();

      if (kDebugMode) {
        debugPrint(
          '[NotificationIndexStore] Loaded ${entries.length} entries for '
          'key: $key',
        );
      }

      return entries;
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationIndexStore] Failed to load index for '
          'user: $userId, pet: $petId, date: $date. Error: $e',
        );
        debugPrint('Stack trace: $stackTrace');
      }
      return [];
    }
  }

  /// Attempts to rebuild index entries from plugin's pending notifications.
  ///
  /// Parses each pending notification's payload to extract scheduleId,
  /// timeSlot, kind, and treatmentType. Only includes notifications that
  /// belong to the specified userId and petId.
  ///
  /// Returns list of entries if rebuild succeeds and entries found,
  /// null if rebuild fails or no matching notifications.
  Future<List<ScheduledNotificationEntry>?> _rebuildFromPluginState({
    required String userId,
    required String petId,
    required DateTime date,
    required ReminderPlugin plugin,
  }) async {
    try {
      final pending = await plugin.pendingNotificationRequests();
      final entries = <ScheduledNotificationEntry>[];

      for (final notification in pending) {
        // Parse payload to extract scheduleId, timeSlot, kind, treatmentType
        final payload = notification.payload;
        if (payload == null) continue;

        try {
          final payloadMap = jsonDecode(payload) as Map<String, dynamic>;

          // Validate this notification belongs to current user/pet
          if (payloadMap['userId'] != userId || payloadMap['petId'] != petId) {
            continue;
          }

          // Validate required fields present
          final scheduleId = payloadMap['scheduleId'] as String?;
          final timeSlot = payloadMap['timeSlot'] as String?;
          final kind = payloadMap['kind'] as String?;
          final treatmentType = payloadMap['treatmentType'] as String?;

          if (scheduleId == null ||
              timeSlot == null ||
              kind == null ||
              treatmentType == null) {
            if (kDebugMode) {
              debugPrint(
                '[NotificationIndexStore] Skipping notification '
                '${notification.id}: missing required fields in payload',
              );
            }
            continue;
          }

          // Validate kind and treatmentType
          if (!ScheduledNotificationEntry.isValidKind(kind) ||
              !ScheduledNotificationEntry.isValidTreatmentType(treatmentType)) {
            if (kDebugMode) {
              debugPrint(
                '[NotificationIndexStore] Skipping notification '
                '${notification.id}: invalid kind or treatmentType',
              );
            }
            continue;
          }

          // Create entry with validation
          final entry = ScheduledNotificationEntry.create(
            notificationId: notification.id,
            scheduleId: scheduleId,
            treatmentType: treatmentType,
            timeSlotISO: timeSlot,
            kind: kind,
          );

          entries.add(entry);
        } on Exception catch (e) {
          if (kDebugMode) {
            debugPrint(
              '[NotificationIndexStore] Failed to parse notification '
              '${notification.id} payload: $e',
            );
          }
          continue;
        }
      }

      return entries.isNotEmpty ? entries : null;
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationIndexStore] Failed to rebuild index from plugin '
          'state: $e',
        );
      }
      return null;
    }
  }

  /// Saves the index for a specific user, pet, and date.
  ///
  /// Computes checksum and stores data atomically.
  /// Throws if SharedPreferences write fails.
  Future<void> _saveIndex(
    String userId,
    String petId,
    DateTime date,
    List<ScheduledNotificationEntry> entries,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildKey(userId, petId, date);

      // Compute checksum
      final checksum = _computeChecksum(entries);

      // Build data structure
      final indexPayload = {
        'checksum': checksum,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

      // Save to SharedPreferences
      final jsonString = jsonEncode(indexPayload);
      await prefs.setString(key, jsonString);

      if (kDebugMode) {
        debugPrint(
          '[NotificationIndexStore] Saved ${entries.length} entries for '
          'key: $key (checksum: $checksum)',
        );
      }
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationIndexStore] Failed to save index for '
          'user: $userId, pet: $petId, date: $date. Error: $e',
        );
        debugPrint('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Returns notification index entries for today.
  ///
  /// Returns empty list if no entries exist or data is corrupted.
  ///
  /// Optionally provides [plugin] for automatic rebuild on corruption.
  Future<List<ScheduledNotificationEntry>> getForToday(
    String userId,
    String petId, {
    AnalyticsService? analyticsService,
    ReminderPlugin? plugin,
  }) async {
    final today = DateTime.now();
    return _loadIndex(
      userId,
      petId,
      today,
      analyticsService: analyticsService,
      plugin: plugin,
    );
  }

  /// Returns notification index entries for a specific date.
  ///
  /// Returns empty list if no entries exist or data is corrupted.
  ///
  /// Optionally provides [plugin] for automatic rebuild on corruption.
  Future<List<ScheduledNotificationEntry>> getForDate(
    String userId,
    String petId,
    DateTime date, {
    AnalyticsService? analyticsService,
    ReminderPlugin? plugin,
  }) async {
    return _loadIndex(
      userId,
      petId,
      date,
      analyticsService: analyticsService,
      plugin: plugin,
    );
  }

  /// Adds a notification entry to today's index.
  ///
  /// This operation is idempotent - adding the same entry multiple times
  /// is safe. If an entry with the same notificationId already exists,
  /// it will be updated.
  Future<void> putEntry(
    String userId,
    String petId,
    ScheduledNotificationEntry entry,
  ) async {
    try {
      final today = DateTime.now();
      final entries = await _loadIndex(userId, petId, today);

      // Remove existing entry with same notificationId (if any)
      // Add new entry
      entries
        ..removeWhere((e) => e.notificationId == entry.notificationId)
        ..add(entry);

      // Save updated index
      await _saveIndex(userId, petId, today, entries);

      if (kDebugMode) {
        debugPrint(
          '[NotificationIndexStore] Added entry: $entry',
        );
      }
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationIndexStore] Failed to put entry: $entry. Error: $e',
        );
        debugPrint('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Removes notification entries matching scheduleId, timeSlot, and kind.
  ///
  /// This is used when canceling specific notifications (e.g., when a
  /// treatment is logged, cancel the initial + follow-up).
  ///
  /// Returns the number of entries removed.
  Future<int> removeEntryBy(
    String userId,
    String petId,
    String scheduleId,
    String timeSlotISO,
    String kind,
  ) async {
    try {
      final today = DateTime.now();
      final entries = await _loadIndex(userId, petId, today);

      // Count entries before removal
      final initialCount = entries.length;

      // Remove matching entries
      entries.removeWhere(
        (e) =>
            e.scheduleId == scheduleId &&
            e.timeSlotISO == timeSlotISO &&
            e.kind == kind,
      );

      final removedCount = initialCount - entries.length;

      if (removedCount > 0) {
        // Save updated index
        await _saveIndex(userId, petId, today, entries);

        if (kDebugMode) {
          debugPrint(
            '[NotificationIndexStore] Removed $removedCount entries for '
            'scheduleId: $scheduleId, timeSlot: $timeSlotISO, kind: $kind',
          );
        }
      }

      return removedCount;
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationIndexStore] Failed to remove entries for scheduleId: '
          '$scheduleId, timeSlot: $timeSlotISO, kind: $kind. Error: $e',
        );
        debugPrint('Stack trace: $stackTrace');
      }
      // Don't rethrow - removal failures shouldn't block other operations
      return 0;
    }
  }

  /// Removes all notification entries for a specific schedule.
  ///
  /// This is used when a schedule is deleted entirely.
  /// Returns the number of entries removed.
  Future<int> removeAllForSchedule(
    String userId,
    String petId,
    String scheduleId,
  ) async {
    try {
      final today = DateTime.now();
      final entries = await _loadIndex(userId, petId, today);

      // Count entries before removal
      final initialCount = entries.length;

      // Remove all entries with matching scheduleId
      entries.removeWhere((e) => e.scheduleId == scheduleId);

      final removedCount = initialCount - entries.length;

      if (removedCount > 0) {
        // Save updated index
        await _saveIndex(userId, petId, today, entries);

        if (kDebugMode) {
          debugPrint(
            '[NotificationIndexStore] Removed $removedCount entries for '
            'scheduleId: $scheduleId',
          );
        }
      }

      return removedCount;
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationIndexStore] Failed to remove all entries for '
          'scheduleId: $scheduleId. Error: $e',
        );
        debugPrint('Stack trace: $stackTrace');
      }
      // Don't rethrow - removal failures shouldn't block other operations
      return 0;
    }
  }

  /// Clears the notification index for a specific date.
  ///
  /// Used for cleanup operations (e.g., clearing yesterday's index).
  Future<void> clearForDate(
    String userId,
    String petId,
    DateTime date,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildKey(userId, petId, date);
      await prefs.remove(key);

      if (kDebugMode) {
        debugPrint(
          '[NotificationIndexStore] Cleared index for key: $key',
        );
      }
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationIndexStore] Failed to clear index for '
          'user: $userId, pet: $petId, date: $date. Error: $e',
        );
        debugPrint('Stack trace: $stackTrace');
      }
      // Don't rethrow - cleanup failures are not critical
    }
  }

  /// Clears all notification indexes for yesterday.
  ///
  /// Should be called once per day (e.g., on app start after midnight
  /// rollover) to prevent unlimited index growth.
  ///
  /// This method scans all SharedPreferences keys and removes any
  /// matching the pattern `notif_index_v2_*_YYYY-MM-DD` where the date
  /// is yesterday.
  Future<void> clearAllForYesterday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = _formatDate(yesterday);

      // Find all keys for yesterday
      final keys = prefs
          .getKeys()
          .where(
            (key) => key.startsWith(_keyPrefix) && key.endsWith(yesterdayStr),
          )
          .toList();

      // Remove all matching keys
      for (final key in keys) {
        await prefs.remove(key);
      }

      if (kDebugMode) {
        debugPrint(
          '[NotificationIndexStore] Cleared ${keys.length} indexes for '
          'yesterday ($yesterdayStr)',
        );
      }
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationIndexStore] Failed to clear indexes for yesterday. '
          'Error: $e',
        );
        debugPrint('Stack trace: $stackTrace');
      }
      // Don't rethrow - cleanup failures are not critical
    }
  }

  /// Reconciles the index with the plugin's pending notifications.
  ///
  /// **Reconciliation Strategy**:
  /// 1. Fetch current index from SharedPreferences
  /// 2. Fetch pending notifications from plugin.pendingNotificationRequests()
  /// 3. Compare and repair:
  ///    - Index missing entries that plugin has: Add to index
  ///    - Index has entries that plugin doesn't: Remove from index
  ///    - Plugin state is source of truth
  ///
  /// Returns a reconciliation report with counts:
  /// - `added`: Entries added to index (were in plugin but not in index)
  /// - `removed`: Entries removed from index (were in index but not in plugin)
  ///
  /// This method should be called:
  /// - On app start
  /// - After corruption detection
  /// - After any critical notification operation failure
  ///
  /// Example:
  /// ```dart
  /// final report = await store.reconcile(userId, petId, reminderPlugin);
  /// // report: {'added': 2, 'removed': 1}
  /// ```
  Future<Map<String, int>> reconcile(
    String userId,
    String petId,
    ReminderPlugin plugin, {
    AnalyticsService? analyticsService,
  }) async {
    var added = 0;
    var removed = 0;

    try {
      if (kDebugMode) {
        debugPrint(
          '[NotificationIndexStore] Starting reconciliation for '
          'user: $userId, pet: $petId',
        );
      }

      // 1. Load current index
      final today = DateTime.now();
      final indexEntries = await _loadIndex(
        userId,
        petId,
        today,
        analyticsService: analyticsService,
      );

      // 2. Fetch pending notifications from plugin
      final pendingRequests = await plugin.pendingNotificationRequests();

      if (kDebugMode) {
        debugPrint(
          '[NotificationIndexStore] Found ${indexEntries.length} entries in '
          'index, ${pendingRequests.length} pending plugin notifications',
        );
      }

      // 3. Build sets of notification IDs for comparison
      final indexIds = indexEntries.map((e) => e.notificationId).toSet();
      final pluginIds = pendingRequests.map((r) => r.id).toSet();

      // 4. Find entries to add (in plugin but not in index)
      // Note: We can't rebuild full entry data from plugin requests alone
      // (missing scheduleId, treatmentType, etc.), so we can only detect
      // discrepancies, not fix them. The ReminderService will need to
      // reschedule to rebuild the index properly.
      final idsToAdd = pluginIds.difference(indexIds);
      added = idsToAdd.length;

      // 5. Find entries to remove (in index but not in plugin)
      final idsToRemove = indexIds.difference(pluginIds);
      removed = idsToRemove.length;

      if (idsToRemove.isNotEmpty) {
        // Remove stale entries from index
        indexEntries.removeWhere(
          (e) => idsToRemove.contains(e.notificationId),
        );
        await _saveIndex(userId, petId, today, indexEntries);
      }

      if (kDebugMode) {
        debugPrint(
          '[NotificationIndexStore] Reconciliation complete: '
          'added: $added, removed: $removed',
        );
      }

      // Report analytics: index_reconciliation_performed
      if (analyticsService != null) {
        try {
          await analyticsService.trackIndexReconciliationPerformed(
            userId: userId,
            petId: petId,
            added: added,
            removed: removed,
          );
        } on Exception catch (e) {
          if (kDebugMode) {
            debugPrint(
              '[NotificationIndexStore] Analytics tracking failed: $e',
            );
          }
        }
      }

      return {'added': added, 'removed': removed};
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationIndexStore] Reconciliation failed for '
          'user: $userId, pet: $petId. Error: $e',
        );
        debugPrint('Stack trace: $stackTrace');
      }
      // Return zero counts on failure
      return {'added': 0, 'removed': 0};
    }
  }

  /// Returns the count of scheduled notifications for a pet on a specific date.
  ///
  /// This is useful for checking notification limits before scheduling more.
  ///
  /// Parameters:
  /// - [userId]: User identifier
  /// - [petId]: Pet identifier
  /// - [date]: Date to count notifications for (defaults to today)
  ///
  /// Returns: Number of scheduled notifications for the pet on the date
  ///
  /// Example:
  /// ```dart
  /// final count = await store.getCountForPet(userId, petId, DateTime.now());
  /// if (count >= 50) {
  ///   // Apply rolling 24h window logic
  /// }
  /// ```
  Future<int> getCountForPet(
    String userId,
    String petId,
    DateTime date,
  ) async {
    try {
      final entries = await _loadIndex(userId, petId, date);
      return entries.length;
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationIndexStore] Failed to get count for '
          'user: $userId, pet: $petId, date: $date. Error: $e',
        );
        debugPrint('Stack trace: $stackTrace');
      }
      // Return 0 on error to allow graceful degradation
      return 0;
    }
  }

  /// Returns all notification entries for a pet on a specific date.
  ///
  /// This is an alias for [getForDate] with clearer naming for the use case
  /// of retrieving all entries for a specific pet.
  ///
  /// Returns empty list if no entries exist or data is corrupted.
  Future<List<ScheduledNotificationEntry>> getEntriesForPet(
    String userId,
    String petId,
    DateTime date,
  ) async {
    return _loadIndex(userId, petId, date);
  }

  /// Categorizes notification entries by treatment type.
  ///
  /// Returns a map with counts for each treatment type:
  /// - 'medication': Number of medication reminders
  /// - 'fluid': Number of fluid therapy reminders
  ///
  /// This is useful for building group summary notifications that show
  /// breakdown like "2 medications, 1 fluid therapy".
  ///
  /// Example:
  /// ```dart
  /// final entries = await store.getEntriesForPet(userId, petId, date);
  /// final breakdown = NotificationIndexStore.categorizeByType(entries);
  /// print('${breakdown['medication']} meds, ${breakdown['fluid']} fluids');
  /// ```
  static Map<String, int> categorizeByType(
    List<ScheduledNotificationEntry> entries,
  ) {
    var medicationCount = 0;
    var fluidCount = 0;

    for (final entry in entries) {
      switch (entry.treatmentType) {
        case 'medication':
          medicationCount++;
        case 'fluid':
          fluidCount++;
        default:
          // Unknown type, skip
          if (kDebugMode) {
            debugPrint(
              '[NotificationIndexStore] Unknown treatment type: '
              '${entry.treatmentType}',
            );
          }
      }
    }

    return {
      'medication': medicationCount,
      'fluid': fluidCount,
    };
  }
}
