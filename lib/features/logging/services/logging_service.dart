/// Service for logging treatment sessions with summary aggregation
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/logging/exceptions/logging_exceptions.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/shared/models/summary_update_dto.dart';

/// Service for logging treatment sessions with atomic batch writes
///
/// Handles medication and fluid therapy logging with:
/// - Schedule matching (name + time for medications, time only for fluids)
/// - Duplicate detection (medications only, ±15 minute window)
/// - Summary aggregation (daily, weekly, monthly)
/// - 8-write batch pattern (session + 3×(set+update) for summaries)
///
/// Usage:
/// ```dart
/// final service = LoggingService();
/// final sessionId = await service.logMedicationSession(
///   userId: currentUser.id,
///   petId: currentPet.id,
///   session: medicationSession,
///   todaysSchedules: schedules,
///   recentSessions: todaysSessions,
/// );
/// ```
class LoggingService {
  /// Creates a [LoggingService] instance
  const LoggingService();

  /// Firestore instance
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // ============================================
  // PUBLIC API - Medication Logging
  // ============================================

  /// Logs a new medication session with summary updates
  ///
  /// Process:
  /// 1. Validates session (model + business rules)
  /// 2. Detects duplicates (throws [DuplicateSessionException] if found)
  /// 3. Matches to schedule by medication name + closest time (±2 hours)
  /// 4. Creates 8-write batch: session + (daily + weekly + monthly) summaries
  /// 5. Commits atomically to Firestore
  ///
  /// Parameters:
  /// - `userId`: Current authenticated user ID
  /// - `petId`: Target pet ID
  /// - `session`: Medication session to log (from user input)
  /// - `todaysSchedules`: All active schedules for today (for matching)
  /// - `recentSessions`: Today's logged sessions (for duplicate detection)
  ///
  /// Returns: Session ID (same as `session.id`)
  ///
  /// Throws:
  /// - [SessionValidationException]: Session data is invalid
  /// - [DuplicateSessionException]: Duplicate session within ±15 minutes
  /// - [BatchWriteException]: Firestore write failed
  /// - [LoggingException]: Unexpected error
  Future<String> logMedicationSession({
    required String userId,
    required String petId,
    required MedicationSession session,
    required List<Schedule> todaysSchedules,
    required List<MedicationSession> recentSessions,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Logging medication session: '
          '${session.medicationName} at ${session.dateTime}',
        );
      }

      // STEP 1: Model validation
      _validateMedicationSession(session);

      // STEP 2: Duplicate detection (throws if found)
      final duplicate = _detectDuplicateMedication(session, recentSessions);
      if (duplicate != null) {
        if (kDebugMode) {
          debugPrint(
            '[LoggingService] Duplicate medication detected: '
            '${duplicate.medicationName} at ${duplicate.dateTime}',
          );
        }
        throw DuplicateSessionException(
          sessionType: 'medication',
          conflictingTime: duplicate.dateTime,
          medicationName: duplicate.medicationName,
        );
      }

      // STEP 3: Schedule matching
      final match = _matchMedicationSchedule(session, todaysSchedules);
      final sessionWithSchedule = session.copyWith(
        scheduleId: match.scheduleId,
        scheduledTime: match.scheduledTime,
      );

      if (kDebugMode) {
        if (match.scheduleId != null) {
          debugPrint(
            '[LoggingService] Matched to schedule ${match.scheduleId} '
            'at ${match.scheduledTime}',
          );
        } else {
          debugPrint('[LoggingService] No schedule match (manual log)');
        }
      }

      // STEP 4: Create summary update DTO
      final dto = SummaryUpdateDto.fromMedicationSession(
        sessionWithSchedule,
      );

      // STEP 5: Build 8-write batch
      final batch = _firestore.batch();
      final sessionRef = _getMedicationSessionRef(userId, petId, session.id);
      final date = AppDateUtils.startOfDay(session.dateTime);

      // Operation 1: Write session
      batch.set(sessionRef, sessionWithSchedule.toJson());

      // Operations 2-3: Daily summary (set + update)
      final dailyRef = _getDailySummaryRef(userId, petId, date);
      batch
        ..set(
          dailyRef,
          _buildDailySummaryInit(date),
          SetOptions(merge: true),
        )
        ..update(dailyRef, dto.toFirestoreUpdate());

      // Operations 4-5: Weekly summary (set + update)
      final weeklyRef = _getWeeklySummaryRef(userId, petId, date);
      batch
        ..set(
          weeklyRef,
          _buildWeeklySummaryInit(date),
          SetOptions(merge: true),
        )
        ..update(weeklyRef, dto.toFirestoreUpdate());

      // Operations 6-7: Monthly summary (set + update)
      final monthlyRef = _getMonthlySummaryRef(userId, petId, date);
      batch
        ..set(
          monthlyRef,
          _buildMonthlySummaryInit(date),
          SetOptions(merge: true),
        )
        ..update(monthlyRef, dto.toFirestoreUpdate());

      // STEP 6: Commit batch
      await _executeBatchWrite(
        batch: batch,
        operation: 'logMedicationSession',
      );

      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Successfully logged medication session '
          '${session.id}',
        );
      }

      return session.id;
    } on DuplicateSessionException {
      rethrow; // UI handles duplicate dialog
    } on SessionValidationException {
      rethrow; // UI shows validation errors
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingService] Firebase error: ${e.message}');
      }
      throw BatchWriteException(
        'logMedicationSession',
        e.message ?? 'Unknown Firebase error',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingService] Unexpected error: $e');
      }
      throw LoggingException('Unexpected error logging medication: $e');
    }
  }

  /// Updates an existing medication session with delta-based summary updates
  ///
  /// Calculates delta between old and new session values and applies to
  /// summaries. Uses same 8-write batch pattern for consistency.
  ///
  /// Parameters:
  /// - [userId]: Current authenticated user ID
  /// - [petId]: Target pet ID
  /// - [oldSession]: Original session (before update)
  /// - [newSession]: Updated session (after user edits)
  ///
  /// Throws:
  /// - [SessionValidationException]: New session data is invalid
  /// - [BatchWriteException]: Firestore write failed
  /// - [LoggingException]: Unexpected error
  Future<void> updateMedicationSession({
    required String userId,
    required String petId,
    required MedicationSession oldSession,
    required MedicationSession newSession,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Updating medication session: ${newSession.id}',
        );
      }

      // STEP 1: Validate new session
      _validateMedicationSession(newSession);

      // STEP 2: Calculate delta DTO
      final dto = SummaryUpdateDto.forMedicationSessionUpdate(
        oldSession: oldSession,
        newSession: newSession,
      );

      // No summary updates needed if nothing changed
      if (!dto.hasUpdates) {
        if (kDebugMode) {
          debugPrint(
            '[LoggingService] No summary updates needed '
            '(session-only change)',
          );
        }
        // Still update the session document
        final sessionRef = _getMedicationSessionRef(
          userId,
          petId,
          newSession.id,
        );
        await sessionRef.update(
          newSession.copyWith(updatedAt: DateTime.now()).toJson(),
        );
        return;
      }

      // STEP 3: Build 8-write batch with deltas
      final batch = _firestore.batch();
      final sessionRef = _getMedicationSessionRef(
        userId,
        petId,
        newSession.id,
      );
      final date = AppDateUtils.startOfDay(newSession.dateTime);

      // Operation 1: Update session
      batch.update(
        sessionRef,
        newSession.copyWith(updatedAt: DateTime.now()).toJson(),
      );

      // Operations 2-3: Daily summary (set + update)
      final dailyRef = _getDailySummaryRef(userId, petId, date);
      batch
        ..set(
          dailyRef,
          _buildDailySummaryInit(date),
          SetOptions(merge: true),
        )
        ..update(dailyRef, dto.toFirestoreUpdate());

      // Operations 4-5: Weekly summary (set + update)
      final weeklyRef = _getWeeklySummaryRef(userId, petId, date);
      batch
        ..set(
          weeklyRef,
          _buildWeeklySummaryInit(date),
          SetOptions(merge: true),
        )
        ..update(weeklyRef, dto.toFirestoreUpdate());

      // Operations 6-7: Monthly summary (set + update)
      final monthlyRef = _getMonthlySummaryRef(userId, petId, date);
      batch
        ..set(
          monthlyRef,
          _buildMonthlySummaryInit(date),
          SetOptions(merge: true),
        )
        ..update(monthlyRef, dto.toFirestoreUpdate());

      // STEP 4: Commit batch
      await _executeBatchWrite(
        batch: batch,
        operation: 'updateMedicationSession',
      );

      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Successfully updated medication session '
          '${newSession.id}',
        );
      }
    } on SessionValidationException {
      rethrow;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingService] Firebase error: ${e.message}');
      }
      throw BatchWriteException(
        'updateMedicationSession',
        e.message ?? 'Unknown Firebase error',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingService] Unexpected error: $e');
      }
      throw LoggingException('Unexpected error updating medication: $e');
    }
  }

  // ============================================
  // PUBLIC API - Fluid Logging
  // ============================================

  /// Logs a new fluid session with summary updates
  ///
  /// Similar to medication logging but:
  /// - No duplicate detection (partial sessions are valid)
  /// - Schedule matching by time only (no name matching)
  ///
  /// Parameters:
  /// - `userId`: Current authenticated user ID
  /// - `petId`: Target pet ID
  /// - `session`: Fluid session to log (from user input)
  /// - `todaysSchedules`: All active schedules for today (for matching)
  /// - `recentSessions`: Today's logged sessions (unused, for API consistency)
  ///
  /// Returns: Session ID (same as `session.id`)
  ///
  /// Throws:
  /// - [SessionValidationException]: Session data is invalid
  /// - [BatchWriteException]: Firestore write failed
  /// - [LoggingException]: Unexpected error
  Future<String> logFluidSession({
    required String userId,
    required String petId,
    required FluidSession session,
    required List<Schedule> todaysSchedules,
    // Unused but kept for API consistency
    required List<FluidSession> recentSessions,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Logging fluid session: '
          '${session.volumeGiven}ml at ${session.dateTime}',
        );
      }

      // STEP 1: Model validation (no duplicate detection for fluids)
      _validateFluidSession(session);

      // STEP 2: Schedule matching (time only)
      final match = _matchFluidSchedule(session, todaysSchedules);
      final sessionWithSchedule = session.copyWith(
        scheduleId: match.scheduleId,
        scheduledTime: match.scheduledTime,
      );

      if (kDebugMode) {
        if (match.scheduleId != null) {
          debugPrint(
            '[LoggingService] Matched to schedule ${match.scheduleId} '
            'at ${match.scheduledTime}',
          );
        } else {
          debugPrint('[LoggingService] No schedule match (manual log)');
        }
      }

      // STEP 3: Create summary update DTO
      final dto = SummaryUpdateDto.fromFluidSession(
        sessionWithSchedule,
      );

      // STEP 4: Build 8-write batch
      final batch = _firestore.batch();
      final sessionRef = _getFluidSessionRef(userId, petId, session.id);
      final date = AppDateUtils.startOfDay(session.dateTime);

      // Operation 1: Write session
      batch.set(sessionRef, sessionWithSchedule.toJson());

      // Operations 2-3: Daily summary (set + update)
      final dailyRef = _getDailySummaryRef(userId, petId, date);
      batch
        ..set(
          dailyRef,
          _buildDailySummaryInit(date),
          SetOptions(merge: true),
        )
        ..update(dailyRef, dto.toFirestoreUpdate());

      // Operations 4-5: Weekly summary (set + update)
      final weeklyRef = _getWeeklySummaryRef(userId, petId, date);
      batch
        ..set(
          weeklyRef,
          _buildWeeklySummaryInit(date),
          SetOptions(merge: true),
        )
        ..update(weeklyRef, dto.toFirestoreUpdate());

      // Operations 6-7: Monthly summary (set + update)
      final monthlyRef = _getMonthlySummaryRef(userId, petId, date);
      batch
        ..set(
          monthlyRef,
          _buildMonthlySummaryInit(date),
          SetOptions(merge: true),
        )
        ..update(monthlyRef, dto.toFirestoreUpdate());

      // STEP 5: Commit batch
      await _executeBatchWrite(
        batch: batch,
        operation: 'logFluidSession',
      );

      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Successfully logged fluid session '
          '${session.id}',
        );
      }

      return session.id;
    } on SessionValidationException {
      rethrow;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingService] Firebase error: ${e.message}');
      }
      throw BatchWriteException(
        'logFluidSession',
        e.message ?? 'Unknown Firebase error',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingService] Unexpected error: $e');
      }
      throw LoggingException('Unexpected error logging fluid: $e');
    }
  }

  /// Updates an existing fluid session with delta-based summary updates
  ///
  /// Parameters:
  /// - [userId]: Current authenticated user ID
  /// - [petId]: Target pet ID
  /// - [oldSession]: Original session (before update)
  /// - [newSession]: Updated session (after user edits)
  ///
  /// Throws:
  /// - [SessionValidationException]: New session data is invalid
  /// - [BatchWriteException]: Firestore write failed
  /// - [LoggingException]: Unexpected error
  Future<void> updateFluidSession({
    required String userId,
    required String petId,
    required FluidSession oldSession,
    required FluidSession newSession,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Updating fluid session: ${newSession.id}',
        );
      }

      // STEP 1: Validate new session
      _validateFluidSession(newSession);

      // STEP 2: Calculate delta DTO
      final dto = SummaryUpdateDto.forFluidSessionUpdate(
        oldSession: oldSession,
        newSession: newSession,
      );

      // No summary updates needed if volume unchanged
      if (!dto.hasUpdates) {
        if (kDebugMode) {
          debugPrint(
            '[LoggingService] No summary updates needed '
            '(session-only change)',
          );
        }
        // Still update the session document
        final sessionRef = _getFluidSessionRef(userId, petId, newSession.id);
        await sessionRef.update(
          newSession.copyWith(updatedAt: DateTime.now()).toJson(),
        );
        return;
      }

      // STEP 3: Build 8-write batch with deltas
      final batch = _firestore.batch();
      final sessionRef = _getFluidSessionRef(userId, petId, newSession.id);
      final date = AppDateUtils.startOfDay(newSession.dateTime);

      // Operation 1: Update session
      batch.update(
        sessionRef,
        newSession.copyWith(updatedAt: DateTime.now()).toJson(),
      );

      // Operations 2-3: Daily summary (set + update)
      final dailyRef = _getDailySummaryRef(userId, petId, date);
      batch
        ..set(
          dailyRef,
          _buildDailySummaryInit(date),
          SetOptions(merge: true),
        )
        ..update(dailyRef, dto.toFirestoreUpdate());

      // Operations 4-5: Weekly summary (set + update)
      final weeklyRef = _getWeeklySummaryRef(userId, petId, date);
      batch
        ..set(
          weeklyRef,
          _buildWeeklySummaryInit(date),
          SetOptions(merge: true),
        )
        ..update(weeklyRef, dto.toFirestoreUpdate());

      // Operations 6-7: Monthly summary (set + update)
      final monthlyRef = _getMonthlySummaryRef(userId, petId, date);
      batch
        ..set(
          monthlyRef,
          _buildMonthlySummaryInit(date),
          SetOptions(merge: true),
        )
        ..update(monthlyRef, dto.toFirestoreUpdate());

      // STEP 4: Commit batch
      await _executeBatchWrite(
        batch: batch,
        operation: 'updateFluidSession',
      );

      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Successfully updated fluid session '
          '${newSession.id}',
        );
      }
    } on SessionValidationException {
      rethrow;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingService] Firebase error: ${e.message}');
      }
      throw BatchWriteException(
        'updateFluidSession',
        e.message ?? 'Unknown Firebase error',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingService] Unexpected error: $e');
      }
      throw LoggingException('Unexpected error updating fluid: $e');
    }
  }

  // ============================================
  // PRIVATE HELPERS - Validation
  // ============================================

  /// Validates medication session (model + business rules)
  ///
  /// Two-layer validation:
  /// 1. Model validation: Structural integrity (via session.validate())
  /// 2. Business validation: Service-specific rules
  ///
  /// Throws [SessionValidationException] if validation fails.
  void _validateMedicationSession(MedicationSession session) {
    // Layer 1: Model structural validation
    final modelErrors = session.validate();
    if (modelErrors.isNotEmpty) {
      throw SessionValidationException(modelErrors);
    }

    // Layer 2: Business rule validation
    final businessErrors = <String>[];

    // Medication name minimum length (additional to model validation)
    if (session.medicationName.trim().length < 2) {
      businessErrors.add('Medication name must be at least 2 characters');
    }

    // Future timestamp check (redundant with model but explicit)
    if (session.dateTime.isAfter(DateTime.now())) {
      businessErrors.add('Cannot log medication for future time');
    }

    if (businessErrors.isNotEmpty) {
      throw SessionValidationException(businessErrors);
    }
  }

  /// Validates fluid session (model + business rules)
  ///
  /// Two-layer validation:
  /// 1. Model validation: Structural integrity (via session.validate())
  /// 2. Business validation: Service-specific rules
  ///
  /// Throws [SessionValidationException] if validation fails.
  void _validateFluidSession(FluidSession session) {
    // Layer 1: Model structural validation
    final modelErrors = session.validate();
    if (modelErrors.isNotEmpty) {
      throw SessionValidationException(modelErrors);
    }

    // Layer 2: Business rule validation
    final businessErrors = <String>[];

    // Future timestamp check (redundant with model but explicit)
    if (session.dateTime.isAfter(DateTime.now())) {
      businessErrors.add('Cannot log fluid therapy for future time');
    }

    if (businessErrors.isNotEmpty) {
      throw SessionValidationException(businessErrors);
    }
  }

  /// Detects duplicate medication sessions
  ///
  /// A duplicate is defined as:
  /// - Same medication name (exact match)
  /// - Within ±15 minutes of existing session
  ///
  /// Returns the existing session if duplicate found, null otherwise.
  ///
  /// Note: Ignores scheduleId - manual logs and scheduled logs are both
  /// considered duplicates if they match name+time criteria.
  MedicationSession? _detectDuplicateMedication(
    MedicationSession newSession,
    List<MedicationSession> recentSessions,
  ) {
    const duplicateWindow = Duration(minutes: 15);

    for (final existing in recentSessions) {
      // Same medication name (case-sensitive exact match)
      if (existing.medicationName != newSession.medicationName) continue;

      // Within ±15 minutes
      final timeDiff = existing.dateTime.difference(newSession.dateTime).abs();
      if (timeDiff <= duplicateWindow) {
        return existing; // Duplicate found
      }
    }

    return null; // No duplicate
  }

  // Note: No duplicate detection for fluid sessions (per medical requirements)

  // ============================================
  // PRIVATE HELPERS - Schedule Matching
  // ============================================

  /// Matches medication session to schedule by name + closest time
  ///
  /// Matching algorithm:
  /// 1. Filter schedules by medication name (exact match)
  /// 2. For each matching schedule, check all reminder times
  /// 3. Find reminder within ±2 hours of session time
  /// 4. Return schedule with closest matching reminder
  ///
  /// Returns:
  /// - scheduleId and scheduledTime if match found
  /// - Both null if no match (manual log)
  ///
  /// Example:
  /// - Session: Amlodipine at 9:30 AM
  /// - Schedule: Amlodipine with reminders [9:00 AM, 9:00 PM]
  /// - Result: scheduleId = schedule.id, scheduledTime = 9:00 AM
  ({String? scheduleId, DateTime? scheduledTime}) _matchMedicationSchedule(
    MedicationSession session,
    List<Schedule> schedules,
  ) {
    // Filter schedules by medication name
    final matchingSchedules = schedules.where((schedule) {
      return schedule.treatmentType == TreatmentType.medication &&
          schedule.medicationName == session.medicationName;
    }).toList();

    if (matchingSchedules.isEmpty) {
      return (scheduleId: null, scheduledTime: null); // Manual log
    }

    // Find closest reminder time within ±2 hours
    DateTime? closestTime;
    String? matchedScheduleId;
    Duration? smallestDifference;

    for (final schedule in matchingSchedules) {
      for (final reminder in schedule.reminderTimes) {
        // Build DateTime for this reminder on the session's date
        final reminderDateTime = DateTime(
          session.dateTime.year,
          session.dateTime.month,
          session.dateTime.day,
          reminder.hour,
          reminder.minute,
        );

        final difference = session.dateTime.difference(reminderDateTime).abs();

        // Within ±2 hours and closer than previous matches?
        if (difference <= const Duration(hours: 2) &&
            (smallestDifference == null || difference < smallestDifference)) {
          smallestDifference = difference;
          closestTime = reminderDateTime;
          matchedScheduleId = schedule.id;
        }
      }
    }

    return (scheduleId: matchedScheduleId, scheduledTime: closestTime);
  }

  /// Matches fluid session to schedule by closest time
  ///
  /// Matching algorithm:
  /// 1. Filter schedules by treatment type (fluid only)
  /// 2. For each fluid schedule, check all reminder times
  /// 3. Find reminder within ±2 hours of session time
  /// 4. Return schedule with closest matching reminder
  ///
  /// Returns:
  /// - scheduleId and scheduledTime if match found
  /// - Both null if no match (manual log)
  ///
  /// Note: No name matching needed - typically only one fluid schedule exists.
  ({String? scheduleId, DateTime? scheduledTime}) _matchFluidSchedule(
    FluidSession session,
    List<Schedule> schedules,
  ) {
    // Filter schedules by treatment type
    final fluidSchedules = schedules.where((schedule) {
      return schedule.treatmentType == TreatmentType.fluid;
    }).toList();

    if (fluidSchedules.isEmpty) {
      return (scheduleId: null, scheduledTime: null); // Manual log
    }

    // Find closest reminder time within ±2 hours
    DateTime? closestTime;
    String? matchedScheduleId;
    Duration? smallestDifference;

    for (final schedule in fluidSchedules) {
      for (final reminder in schedule.reminderTimes) {
        // Build DateTime for this reminder on the session's date
        final reminderDateTime = DateTime(
          session.dateTime.year,
          session.dateTime.month,
          session.dateTime.day,
          reminder.hour,
          reminder.minute,
        );

        final difference = session.dateTime.difference(reminderDateTime).abs();

        // Within ±2 hours and closer than previous matches?
        if (difference <= const Duration(hours: 2) &&
            (smallestDifference == null || difference < smallestDifference)) {
          smallestDifference = difference;
          closestTime = reminderDateTime;
          matchedScheduleId = schedule.id;
        }
      }
    }

    return (scheduleId: matchedScheduleId, scheduledTime: closestTime);
  }

  // ============================================
  // PRIVATE HELPERS - Batch Writes (8-write pattern)
  // ============================================

  /// Executes batch write with error handling and logging
  ///
  /// Wraps batch.commit() with try-catch and debug logging.
  /// Total operations in batch: 8 (session + 3×(set+update) for summaries)
  ///
  /// Throws [BatchWriteException] if commit fails.
  Future<void> _executeBatchWrite({
    required WriteBatch batch,
    required String operation,
  }) async {
    try {
      await batch.commit();
      if (kDebugMode) {
        debugPrint('[LoggingService] Batch write committed: $operation');
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingService] Batch write failed: ${e.message}');
      }
      throw BatchWriteException(operation, e.message ?? 'Unknown error');
    }
  }

  /// Builds daily summary initialization data
  ///
  /// All counters initialized to 0, booleans to false.
  /// Used with SetOptions(merge: true) - won't overwrite existing data.
  ///
  /// Note: overallStreak always 0 (calculated in Phase 7 by daily job)
  Map<String, dynamic> _buildDailySummaryInit(DateTime date) {
    return {
      'date': Timestamp.fromDate(date),
      'medicationTotalDoses': 0,
      'medicationScheduledDoses': 0,
      'medicationMissedCount': 0,
      'fluidTotalVolume': 0.0,
      'fluidSessionCount': 0,
      'fluidTreatmentDone': false,
      'overallTreatmentDone': false,
      'overallStreak': 0, // Calculated in Phase 7
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Builds weekly summary initialization data
  ///
  /// All counters initialized to 0.
  /// Used with SetOptions(merge: true) - won't overwrite existing data.
  Map<String, dynamic> _buildWeeklySummaryInit(DateTime date) {
    return {
      'weekId': AppDateUtils.formatWeekForSummary(date), // "2025-W40"
      'medicationTotalDoses': 0,
      'medicationScheduledDoses': 0,
      'medicationMissedCount': 0,
      'fluidTotalVolume': 0.0,
      'fluidSessionCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Builds monthly summary initialization data
  ///
  /// All counters initialized to 0.
  /// Used with SetOptions(merge: true) - won't overwrite existing data.
  Map<String, dynamic> _buildMonthlySummaryInit(DateTime date) {
    return {
      'monthId': AppDateUtils.formatMonthForSummary(date), // "2025-10"
      'medicationTotalDoses': 0,
      'medicationScheduledDoses': 0,
      'medicationMissedCount': 0,
      'fluidTotalVolume': 0.0,
      'fluidSessionCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ============================================
  // PRIVATE HELPERS - Firestore Paths
  // ============================================

  /// Gets medication session document reference
  ///
  /// Path: users/{userId}/pets/{petId}/medicationSessions/{sessionId}
  DocumentReference _getMedicationSessionRef(
    String userId,
    String petId,
    String sessionId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('medicationSessions')
        .doc(sessionId);
  }

  /// Gets fluid session document reference
  ///
  /// Path: users/{userId}/pets/{petId}/fluidSessions/{sessionId}
  DocumentReference _getFluidSessionRef(
    String userId,
    String petId,
    String sessionId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('fluidSessions')
        .doc(sessionId);
  }

  /// Gets daily summary document reference
  ///
  /// Path: users/{userId}/pets/{petId}/treatmentSummaries/daily/{YYYY-MM-DD}
  ///
  /// Document ID format: "2025-10-05"
  DocumentReference _getDailySummaryRef(
    String userId,
    String petId,
    DateTime date,
  ) {
    final docId = AppDateUtils.formatDateForSummary(date);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('treatmentSummaries')
        .doc('daily')
        .collection('summaries')
        .doc(docId);
  }

  /// Gets weekly summary document reference
  ///
  /// Path: users/{userId}/pets/{petId}/treatmentSummaries/weekly/{YYYY-Www}
  ///
  /// Document ID format: "2025-W40" (ISO 8601 week number)
  DocumentReference _getWeeklySummaryRef(
    String userId,
    String petId,
    DateTime date,
  ) {
    final docId = AppDateUtils.formatWeekForSummary(date);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('treatmentSummaries')
        .doc('weekly')
        .collection('summaries')
        .doc(docId);
  }

  /// Gets monthly summary document reference
  ///
  /// Path: users/{userId}/pets/{petId}/treatmentSummaries/monthly/{YYYY-MM}
  ///
  /// Document ID format: "2025-10"
  DocumentReference _getMonthlySummaryRef(
    String userId,
    String petId,
    DateTime date,
  ) {
    final docId = AppDateUtils.formatMonthForSummary(date);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('treatmentSummaries')
        .doc('monthly')
        .collection('summaries')
        .doc(docId);
  }
}
