import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/profile/models/schedule_history_entry.dart';

/// Service for managing schedule history in Firestore
///
/// Provides functionality to:
/// - Save schedule snapshots before updates
/// - Query historical schedule states by date
/// - Retrieve full history for audit purposes
class ScheduleHistoryService {
  /// Creates a [ScheduleHistoryService]
  ScheduleHistoryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Save schedule state to history before updating
  ///
  /// Creates a snapshot of the schedule in the history subcollection.
  /// Uses [effectiveFrom] as the start of this version's validity period,
  /// and [effectiveTo] as the end (null if this is the current version).
  ///
  /// The document ID is the millisecondsSinceEpoch of [effectiveFrom].
  Future<void> saveScheduleSnapshot({
    required String userId,
    required String petId,
    required Schedule schedule,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
  }) async {
    try {
      final entry = ScheduleHistoryEntry.fromSchedule(
        schedule,
        effectiveFrom: effectiveFrom,
        effectiveTo: effectiveTo,
      );

      final historyRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .collection('schedules')
          .doc(schedule.id)
          .collection('history')
          .doc(effectiveFrom.millisecondsSinceEpoch.toString());

      await historyRef.set(entry.toJson());

      if (kDebugMode) {
        debugPrint(
          '[ScheduleHistoryService] Saved snapshot for '
          'schedule ${schedule.id} '
          'effective from ${effectiveFrom.toIso8601String()}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleHistoryService] Error saving schedule snapshot: $e',
        );
      }
      rethrow;
    }
  }

  /// Get schedule state as it was on a specific date
  ///
  /// Queries the history subcollection for entries where:
  /// - effectiveFrom <= date
  /// - Orders by effectiveFrom descending
  /// - Returns the most recent entry (LIMIT 1)
  ///
  /// Verifies the date is within the effective range before returning.
  /// Returns null if no matching history entry is found.
  Future<ScheduleHistoryEntry?> getScheduleAtDate({
    required String userId,
    required String petId,
    required String scheduleId,
    required DateTime date,
  }) async {
    try {
      final historyRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .collection('schedules')
          .doc(scheduleId)
          .collection('history');

      // Query for entries where effectiveFrom <= date
      // Order by effectiveFrom descending to get most recent
      final query = await historyRef
          .where('effectiveFrom', isLessThanOrEqualTo: date.toIso8601String())
          .orderBy('effectiveFrom', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[ScheduleHistoryService] No history found for '
            'schedule $scheduleId at date ${date.toIso8601String()}',
          );
        }
        return null;
      }

      final entry = ScheduleHistoryEntry.fromJson(query.docs.first.data());

      // Verify date is within the effective range
      if (entry.effectiveTo != null && date.isAfter(entry.effectiveTo!)) {
        if (kDebugMode) {
          debugPrint(
            '[ScheduleHistoryService] Found entry but date is after '
            'effectiveTo',
          );
        }
        return null;
      }

      if (kDebugMode) {
        debugPrint(
          '[ScheduleHistoryService] Found history for '
          'schedule $scheduleId at date ${date.toIso8601String()}: '
          'effectiveFrom=${entry.effectiveFrom.toIso8601String()}, '
          'effectiveTo=${entry.effectiveTo?.toIso8601String() ?? "null"}',
        );
      }

      return entry;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleHistoryService] Error getting schedule at date: $e',
        );
      }
      rethrow;
    }
  }

  /// Get all history entries for a schedule (for audit/debugging)
  ///
  /// Returns all history entries ordered by effectiveFrom descending
  /// (most recent first).
  Future<List<ScheduleHistoryEntry>> getScheduleHistory({
    required String userId,
    required String petId,
    required String scheduleId,
  }) async {
    try {
      final historyRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .collection('schedules')
          .doc(scheduleId)
          .collection('history');

      final snapshot = await historyRef
          .orderBy('effectiveFrom', descending: true)
          .get();

      final entries = snapshot.docs
          .map((doc) => ScheduleHistoryEntry.fromJson(doc.data()))
          .toList();

      if (kDebugMode) {
        debugPrint(
          '[ScheduleHistoryService] Retrieved ${entries.length} history '
          'entries for schedule $scheduleId',
        );
      }

      return entries;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleHistoryService] Error getting schedule history: $e',
        );
      }
      rethrow;
    }
  }
}
