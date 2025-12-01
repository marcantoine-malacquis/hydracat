/// Service for logging treatment sessions with summary aggregation
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/logging/exceptions/logging_exceptions.dart';
import 'package:hydracat/features/logging/models/daily_summary_cache.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/logging/services/logging_validation_service.dart';
import 'package:hydracat/features/logging/services/monthly_array_helper.dart';
import 'package:hydracat/features/logging/services/summary_cache_service.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/shared/models/summary_update_dto.dart';

/// Service for logging treatment sessions with atomic batch writes
///
/// Handles medication and fluid therapy logging with:
/// - Schedule matching (name + time for medications, time only for fluids)
/// - Duplicate detection (medications only, ±15 minute window)
/// - Summary aggregation (daily, weekly, monthly)
/// - 4-write batch pattern (1 session + 3 summaries with merge + increments)
///
/// Usage:
/// ```dart
/// final cacheService = SummaryCacheService(prefs);
/// final service = LoggingService(cacheService);
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
  const LoggingService(
    this._cacheService, [
    this._analyticsService,
    this._validationService,
  ]);

  /// Cache service for 0-read duplicate detection
  final SummaryCacheService _cacheService;

  /// Optional analytics service for error tracking
  final AnalyticsService? _analyticsService;

  /// Optional validation service for business logic validation
  final LoggingValidationService? _validationService;

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
  /// 4. Creates 4-write batch: session + (daily + weekly + monthly) summaries
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
      if (_validationService != null) {
        final validationResult = _validationService.validateMedicationSession(
          session,
        );
        if (!validationResult.isValid) {
          final errorMessages = validationResult.errors
              .map((e) => e.message)
              .toList();
          throw SessionValidationException(errorMessages);
        }
      } else {
        // Fallback to existing method for backward compatibility
        _validateMedicationSession(session);
      }

      // STEP 2: Duplicate detection (throws if found)
      if (_validationService != null) {
        final duplicateResult = _validationService.validateForDuplicates(
          newSession: session,
          recentSessions: recentSessions,
        );
        if (!duplicateResult.isValid) {
          // Find the actual duplicate session using validation service
          final duplicate = _validationService.findDuplicateSession(
            newSession: session,
            recentSessions: recentSessions,
          );
          if (kDebugMode) {
            debugPrint(
              '[LoggingService] Duplicate medication detected: '
              '${duplicate?.medicationName} at ${duplicate?.dateTime}',
            );
          }

          throw _validationService.toLoggingException(
            duplicateResult,
            duplicateSession: duplicate,
          );
        }
      } else {
        // Fallback: use validation service's helper directly
        final duplicate = const LoggingValidationService().findDuplicateSession(
          newSession: session,
          recentSessions: recentSessions,
        );
        if (duplicate != null) {
          if (kDebugMode) {
            debugPrint(
              '[LoggingService] Duplicate medication detected: '
              '${duplicate.medicationName} at ${duplicate.dateTime}',
            );
          }

          final result = const LoggingValidationService().validateForDuplicates(
            newSession: session,
            recentSessions: recentSessions,
          );
          throw const LoggingValidationService().toLoggingException(
            result,
            duplicateSession: duplicate,
          );
        }
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

      // STEP 4: Check if scheduled doses already counted for this date
      final sessionDate = AppDateUtils.startOfDay(session.dateTime);
      final alreadyCounted = await _hasScheduledDosesCounted(
        userId,
        petId,
        sessionDate,
      );

      // STEP 5: Calculate scheduled doses (only if not already counted)
      final scheduledDosesCount = alreadyCounted
          ? 0
          : todaysSchedules
                .map((s) => s.reminderTimesOnDate(session.dateTime).length)
                .fold(0, (total, reminderCount) => total + reminderCount);

      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Scheduled doses: $scheduledDosesCount '
          '(alreadyCounted: $alreadyCounted)',
        );
      }

      // STEP 6: Build 4-write batch
      final batch = _firestore.batch();
      _addMedicationSessionToBatch(
        batch: batch,
        session: sessionWithSchedule,
        userId: userId,
        petId: petId,
        scheduledDosesCount: scheduledDosesCount,
      );

      // STEP 7: Commit batch
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

      // Track analytics
      await _analyticsService?.trackLoggingFailure(
        errorType: 'batch_write_failure',
        treatmentType: 'medication',
        source: 'manual',
        errorCode: e.code,
        exception: 'FirebaseException',
      );

      throw BatchWriteException(
        'logMedicationSession',
        e.message ?? 'Unknown Firebase error',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingService] Unexpected error: $e');
      }

      // Track analytics
      await _analyticsService?.trackLoggingFailure(
        errorType: 'unexpected_logging_error',
        treatmentType: 'medication',
        source: 'manual',
        exception: e.runtimeType.toString(),
      );

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
      if (_validationService != null) {
        final validationResult = _validationService.validateMedicationSession(
          newSession,
        );
        if (!validationResult.isValid) {
          final errorMessages = validationResult.errors
              .map((e) => e.message)
              .toList();
          throw SessionValidationException(errorMessages);
        }
      } else {
        // Fallback to existing method for backward compatibility
        _validateMedicationSession(newSession);
      }

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
        await sessionRef.update({
          ...newSession.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      // STEP 3: Build 4-write batch with deltas
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
        {
          ...newSession.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Operation 2: Daily summary (single set with merge + increments)
      final dailyRef = _getDailySummaryRef(userId, petId, date);
      batch.set(
        dailyRef,
        _buildDailySummaryWithIncrements(date, dto),
        SetOptions(merge: true),
      );

      // Operation 3: Weekly summary (single set with merge + increments)
      final weeklyRef = _getWeeklySummaryRef(userId, petId, date);
      batch.set(
        weeklyRef,
        _buildWeeklySummaryWithIncrements(date, dto),
        SetOptions(merge: true),
      );

      // Operation 4: Monthly summary (single set with merge + increments)
      final monthlyRef = _getMonthlySummaryRef(userId, petId, date);
      batch.set(
        monthlyRef,
        _buildMonthlySummaryWithIncrements(date, dto),
        SetOptions(merge: true),
      );

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

      // Track analytics
      await _analyticsService?.trackLoggingFailure(
        errorType: 'batch_write_failure',
        treatmentType: 'medication',
        source: 'update',
        errorCode: e.code,
        exception: 'FirebaseException',
      );

      throw BatchWriteException(
        'updateMedicationSession',
        e.message ?? 'Unknown Firebase error',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingService] Unexpected error: $e');
      }

      // Track analytics
      await _analyticsService?.trackLoggingFailure(
        errorType: 'unexpected_logging_error',
        treatmentType: 'medication',
        source: 'update',
        exception: e.runtimeType.toString(),
      );

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
      if (_validationService != null) {
        final validationResult = _validationService.validateFluidSession(
          session,
        );
        if (!validationResult.isValid) {
          final errorMessages = validationResult.errors
              .map((e) => e.message)
              .toList();
          throw SessionValidationException(errorMessages);
        }
      } else {
        // Fallback to existing method for backward compatibility
        _validateFluidSession(session);
      }

      // STEP 2: Calculate daily goal from active fluid schedule (if exists)
      // Note: Goal calculation is independent of schedule matching
      final fluidSchedule = todaysSchedules
          .where((s) => s.treatmentType == TreatmentType.fluid)
          .where((s) => s.isActive)
          .firstOrNull;

      final dailyGoal = fluidSchedule != null
          ? _calculateDailyFluidGoal(fluidSchedule, session.dateTime)
          : null;

      // STEP 3: Schedule matching (time only, for linking purposes)
      final match = _matchFluidSchedule(session, todaysSchedules);

      final sessionWithSchedule = session.copyWith(
        scheduleId: match.scheduleId,
        scheduledTime: match.scheduledTime,
        dailyGoalMl: dailyGoal,
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

      // STEP 4: Check if scheduled sessions already counted for this date
      final sessionDate = AppDateUtils.startOfDay(session.dateTime);
      final alreadyCounted = await _hasFluidScheduledCounted(
        userId,
        petId,
        sessionDate,
      );

      // STEP 5: Calculate scheduled fluid sessions (only if not counted)
      final scheduledSessionsCount = alreadyCounted
          ? 0
          : (fluidSchedule != null
                ? fluidSchedule.reminderTimesOnDate(session.dateTime).length
                : 0);

      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Scheduled fluid sessions: $scheduledSessionsCount '
          '(alreadyCounted: $alreadyCounted)',
        );
      }

      // STEP 5A: Calculate weekly goal (only if first session of week)
      final weeklyGoal = await _calculateWeeklyGoalFromSchedules(
        userId,
        petId,
        todaysSchedules,
        session.dateTime,
      );

      if (kDebugMode && weeklyGoal != null) {
        debugPrint(
          '[LoggingService] Calculated weekly goal: ${weeklyGoal}ml',
        );
      }

      // STEP 5B: Fetch daily totals for monthly array update
      final dailyTotals = await _fetchDailyTotalsForMonthly(
        userId: userId,
        petId: petId,
        date: sessionDate,
        sessionVolumeDelta: session.volumeGiven.toInt(),
        sessionGoalMl: dailyGoal?.toInt(),
        sessionScheduledCount: scheduledSessionsCount,
      );

      // STEP 5C: Fetch current monthly arrays
      final monthlyArrays = await _fetchMonthlyArrays(
        userId: userId,
        petId: petId,
        date: sessionDate,
      );

      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Daily totals for monthly: '
          'volume=${dailyTotals.volumeTotal}ml, '
          'goal=${dailyTotals.goalMl}ml, '
          'scheduled=${dailyTotals.scheduledCount}',
        );
      }

      // STEP 6: Build 5-write batch (session + 3 summaries + pet doc)
      final batch = _firestore.batch();

      // Add fluid session writes
      _addFluidSessionToBatch(
        batch: batch,
        session: sessionWithSchedule,
        userId: userId,
        petId: petId,
        scheduledSessionsCount: scheduledSessionsCount,
        weeklyGoalMl: weeklyGoal,
        // Monthly array data
        dayVolumeTotal: dailyTotals.volumeTotal,
        dayGoalMl: dailyTotals.goalMl,
        dayScheduledCount: dailyTotals.scheduledCount,
        currentDailyVolumes: monthlyArrays.dailyVolumes,
        currentDailyGoals: monthlyArrays.dailyGoals,
        currentDailyScheduledSessions: monthlyArrays.dailyScheduledSessions,
      );

      // STEP 6A: Update pet document with last injection site
      final petRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId);

      batch.update(petRef, {
        'lastFluidInjectionSite': session.injectionSite.name,
        'lastFluidSessionDate': session.dateTime,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Updating pet injection site: '
          '${session.injectionSite.name}',
        );
      }

      // STEP 7: Commit batch
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

      // Track analytics
      await _analyticsService?.trackLoggingFailure(
        errorType: 'batch_write_failure',
        treatmentType: 'fluid',
        source: 'manual',
        errorCode: e.code,
        exception: 'FirebaseException',
      );

      throw BatchWriteException(
        'logFluidSession',
        e.message ?? 'Unknown Firebase error',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingService] Unexpected error: $e');
      }

      // Track analytics
      await _analyticsService?.trackLoggingFailure(
        errorType: 'unexpected_logging_error',
        treatmentType: 'fluid',
        source: 'manual',
        exception: e.runtimeType.toString(),
      );

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
      if (_validationService != null) {
        final validationResult = _validationService.validateFluidSession(
          newSession,
        );
        if (!validationResult.isValid) {
          final errorMessages = validationResult.errors
              .map((e) => e.message)
              .toList();
          throw SessionValidationException(errorMessages);
        }
      } else {
        // Fallback to existing method for backward compatibility
        _validateFluidSession(newSession);
      }

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
        await sessionRef.update({
          ...newSession.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      // STEP 2A: Fetch daily totals for monthly array update
      final sessionDate = AppDateUtils.startOfDay(newSession.dateTime);
      final volumeDelta =
          (newSession.volumeGiven - oldSession.volumeGiven).toInt();

      final dailyTotals = await _fetchDailyTotalsForMonthly(
        userId: userId,
        petId: petId,
        date: sessionDate,
        sessionVolumeDelta: volumeDelta,
        sessionGoalMl: newSession.dailyGoalMl?.toInt(),
        sessionScheduledCount: 0, // No change in scheduled count on update
      );

      // STEP 2B: Fetch current monthly arrays
      final monthlyArrays = await _fetchMonthlyArrays(
        userId: userId,
        petId: petId,
        date: sessionDate,
      );

      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Daily totals for monthly (update): '
          'volume=${dailyTotals.volumeTotal}ml, '
          'goal=${dailyTotals.goalMl}ml, '
          'delta=${volumeDelta}ml',
        );
      }

      // STEP 3: Build 4-write batch with deltas
      final batch = _firestore.batch();
      final sessionRef = _getFluidSessionRef(userId, petId, newSession.id);
      final date = AppDateUtils.startOfDay(newSession.dateTime);

      // Operation 1: Update session
      batch.update(
        sessionRef,
        {
          ...newSession.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Operation 2: Daily summary (single set with merge + increments)
      final dailyRef = _getDailySummaryRef(userId, petId, date);
      batch.set(
        dailyRef,
        _buildDailySummaryWithIncrements(date, dto),
        SetOptions(merge: true),
      );

      // Operation 3: Weekly summary (single set with merge + increments)
      final weeklyRef = _getWeeklySummaryRef(userId, petId, date);
      batch.set(
        weeklyRef,
        _buildWeeklySummaryWithIncrements(date, dto),
        SetOptions(merge: true),
      );

      // Operation 4: Monthly summary (single set with merge + increments)
      final monthlyRef = _getMonthlySummaryRef(userId, petId, date);
      batch.set(
        monthlyRef,
        _buildMonthlySummaryWithIncrements(
          date,
          dto,
          dayVolumeTotal: dailyTotals.volumeTotal,
          dayGoalMl: dailyTotals.goalMl,
          dayScheduledCount: dailyTotals.scheduledCount,
          currentDailyVolumes: monthlyArrays.dailyVolumes,
          currentDailyGoals: monthlyArrays.dailyGoals,
          currentDailyScheduledSessions: monthlyArrays.dailyScheduledSessions,
        ),
        SetOptions(merge: true),
      );

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

      // Track analytics
      await _analyticsService?.trackLoggingFailure(
        errorType: 'batch_write_failure',
        treatmentType: 'fluid',
        source: 'update',
        errorCode: e.code,
        exception: 'FirebaseException',
      );

      throw BatchWriteException(
        'updateFluidSession',
        e.message ?? 'Unknown Firebase error',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingService] Unexpected error: $e');
      }

      // Track analytics
      await _analyticsService?.trackLoggingFailure(
        errorType: 'unexpected_logging_error',
        treatmentType: 'fluid',
        source: 'update',
        exception: e.runtimeType.toString(),
      );

      throw LoggingException('Unexpected error updating fluid: $e');
    }
  }

  // ============================================
  // PUBLIC API - Quick-Log
  // ============================================

  /// Logs all scheduled treatments for today in a single atomic batch
  ///
  /// Quick-log feature for FAB long-press. Creates sessions for all active
  /// schedules with today's reminders, using scheduled times and marking
  /// all medications as completed.
  ///
  /// Process:
  /// 1. Validate input (non-empty schedules)
  /// 2. Check cache for existing sessions (rejects if any found)
  /// 3. Filter schedules to active schedules with today's reminders
  /// 4. Generate all sessions from filtered schedules
  /// 5. Build single batch with all sessions (4 writes per session)
  /// 6. Commit atomically to Firestore
  ///
  /// Parameters:
  /// - `userId`: Current authenticated user ID
  /// - `petId`: Target pet ID
  /// - `todaysSchedules`: All active schedules for today (from provider)
  ///
  /// Returns: Record with detailed session information for cache update
  ///
  /// Throws:
  /// - [LoggingException]: Empty schedules or sessions already logged
  /// - [BatchWriteException]: Firestore write failed
  ///
  /// Cost: N sessions × 4 writes (typical: 5 sessions = 20 writes)
  ///
  /// Example:
  /// ```dart
  /// final result = await loggingService.quickLogAllTreatments(
  ///   userId: user.id,
  ///   petId: pet.id,
  ///   todaysSchedules: schedules,
  /// );
  /// // Returns: (sessionCount: 5, medicationNames: [...], ...)
  /// ```
  Future<
    ({
      int sessionCount,
      int medicationSessionCount,
      int fluidSessionCount,
      List<String> medicationNames,
      double totalMedicationDoses,
      double totalFluidVolume,
      Map<String, List<String>> medicationRecentTimes,
      Map<String, List<String>> medicationCompletedTimes,
    })
  >
  quickLogAllTreatments({
    required String userId,
    required String petId,
    required List<Schedule> todaysSchedules,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Quick-log starting with '
          '${todaysSchedules.length} schedules',
        );
      }

      // STEP 1: Validate input
      if (todaysSchedules.isEmpty) {
        throw const LoggingException('No active schedules found for today.');
      }

      // STEP 2: Get cache for smart session filtering
      // (allow partial completion)
      final cache = await _getDailySummaryCache(userId, petId);

      // STEP 3: Filter to active schedules with today's reminders
      final now = DateTime.now();
      final activeSchedules = todaysSchedules
          .where((schedule) => schedule.isActive)
          .where((schedule) => schedule.hasReminderTimeToday(now))
          .toList();

      if (activeSchedules.isEmpty) {
        throw const LoggingException(
          'No schedules have reminder times for today.',
        );
      }

      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Filtered to ${activeSchedules.length} '
          "active schedules with today's reminders",
        );
      }

      // STEP 4: Generate sessions ONLY for incomplete treatments
      // (smart filtering)
      final medicationSessions = <MedicationSession>[];
      final fluidSessions = <FluidSession>[];

      for (final schedule in activeSchedules) {
        if (schedule.treatmentType == TreatmentType.medication) {
          final medicationName = schedule.medicationName;
          if (medicationName == null) continue;

          // Check each reminder time individually for multi-dose schedules
          // Only create sessions for reminder times that don't have a completed
          // dose within the ±2h window
          final todaysReminders = schedule.todaysReminderTimes(now).toList();
          for (final reminderTime in todaysReminders) {
            // Skip if this specific reminder time already has a completed dose
            if (cache != null &&
                cache.hasMedicationCompletedNear(
                  medicationName,
                  reminderTime,
                )) {
              if (kDebugMode) {
                final hour = reminderTime.hour;
                final minute = reminderTime.minute.toString().padLeft(2, '0');
                final timeStr = '$hour:$minute';
                debugPrint(
                  '[LoggingService] Skipping $medicationName at $timeStr - '
                  'already completed',
                );
              }
              continue;
            }

            // Create session for this remaining reminder time
            medicationSessions.add(
              MedicationSession.fromSchedule(
                schedule: schedule,
                scheduledTime: reminderTime,
                petId: petId,
                userId: userId,
                actualDateTime: reminderTime, // Use scheduled time
                wasCompleted: true, // All quick-logged meds marked complete
              ),
            );
          }
        } else if (schedule.treatmentType == TreatmentType.fluid) {
          // Calculate remaining fluid volume needed
          final dailyGoal = _calculateDailyFluidGoal(schedule, now);
          if (dailyGoal == null) continue;

          final alreadyLogged = cache?.totalFluidVolumeGiven ?? 0.0;
          final remaining = dailyGoal - alreadyLogged;

          if (remaining <= 0) {
            if (kDebugMode) {
              debugPrint(
                '[LoggingService] Skipping fluid - already complete '
                '($alreadyLogged ml / $dailyGoal ml)',
              );
            }
            continue;
          }

          // Create single catch-up session for remaining volume
          final reminderTimes = schedule.todaysReminderTimes(now).toList();
          final scheduledTime = reminderTimes.isNotEmpty
              ? reminderTimes.first
              : now;

          if (kDebugMode) {
            debugPrint(
              '[LoggingService] Creating catch-up fluid session: '
              '$remaining ml (goal: $dailyGoal ml, logged: $alreadyLogged ml)',
            );
          }

          fluidSessions.add(
            FluidSession.fromSchedule(
              schedule: schedule,
              scheduledTime: scheduledTime,
              petId: petId,
              userId: userId,
              actualDateTime: now, // Use current time for catch-up
              dailyGoalMl: dailyGoal,
            ).copyWith(
              volumeGiven: remaining, // Override with remaining volume
            ),
          );
        }
      }

      final totalSessions = medicationSessions.length + fluidSessions.length;

      if (totalSessions == 0) {
        throw const LoggingException(
          'All scheduled treatments already logged today.',
        );
      }

      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Generated $totalSessions sessions: '
          '${medicationSessions.length} medications, '
          '${fluidSessions.length} fluids',
        );
      }

      // STEP 5: Check if scheduled doses/sessions already counted for this date
      // (to avoid double-counting when some doses were logged manually earlier)
      final todayDate = AppDateUtils.startOfDay(now);
      final scheduledDosesAlreadyCounted = await _hasScheduledDosesCounted(
        userId,
        petId,
        todayDate,
      );
      final fluidScheduledAlreadyCounted = await _hasFluidScheduledCounted(
        userId,
        petId,
        todayDate,
      );

      // STEP 6: Aggregate summary deltas (used for summaries)
      final aggregatedDto = _aggregateSummaryForQuickLog(
        medicationSessions: medicationSessions,
        fluidSessions: fluidSessions,
        scheduledDosesAlreadyCounted: scheduledDosesAlreadyCounted,
        fluidScheduledAlreadyCounted: fluidScheduledAlreadyCounted,
      );

      // STEP 6: Guardrail — split into chunks if near Firestore 500 op limit
      // Ops estimate: one write per session + 3 summary writes
      final totalOpsEstimate = totalSessions + 3;
      if (totalOpsEstimate <= 500) {
        // Single batch path
        final batch = _firestore.batch();

        // Write sessions
        for (final session in medicationSessions) {
          final ref = _getMedicationSessionRef(userId, petId, session.id);
          batch.set(ref, _buildSessionCreateData(session.toJson()));
        }
        for (final session in fluidSessions) {
          final ref = _getFluidSessionRef(userId, petId, session.id);
          batch.set(ref, _buildSessionCreateData(session.toJson()));
        }

        // Add exactly 3 summary writes
        final dailyRef = _getDailySummaryRef(userId, petId, todayDate);
        // Get daily goal from first fluid session if any exist
        final dailyGoal = fluidSessions.isNotEmpty
            ? fluidSessions.first.dailyGoalMl
            : null;
        batch.set(
          dailyRef,
          _buildDailySummaryWithIncrements(
            todayDate,
            aggregatedDto,
            dailyGoalMl: dailyGoal,
          ),
          SetOptions(merge: true),
        );

        final weeklyRef = _getWeeklySummaryRef(userId, petId, todayDate);
        batch.set(
          weeklyRef,
          _buildWeeklySummaryWithIncrements(todayDate, aggregatedDto),
          SetOptions(merge: true),
        );

        final monthlyRef = _getMonthlySummaryRef(userId, petId, todayDate);
        batch.set(
          monthlyRef,
          _buildMonthlySummaryWithIncrements(todayDate, aggregatedDto),
          SetOptions(merge: true),
        );

        await _executeBatchWrite(
          batch: batch,
          operation: 'quickLogAllTreatments',
        );
      } else {
        // Chunked path — summaries included in first batch only
        await _commitQuickLogInChunks(
          userId: userId,
          petId: petId,
          medicationSessions: medicationSessions,
          fluidSessions: fluidSessions,
          todayDate: todayDate,
          aggregatedDto: aggregatedDto,
        );
      }

      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Quick-log complete: $totalSessions sessions logged',
        );
      }

      // STEP 7: Build detailed result for cache update
      // Calculate actual logged values from generated sessions
      final medicationNames = medicationSessions
          .map((s) => s.medicationName)
          .toSet()
          .toList();

      // Build medicationRecentTimes (all sessions for duplicate detection)
      final medicationRecentTimes = <String, List<String>>{};
      for (final session in medicationSessions) {
        final time = session.scheduledTime ?? session.dateTime;
        medicationRecentTimes
            .putIfAbsent(session.medicationName, () => [])
            .add(time.toIso8601String());
      }

      // Build medicationCompletedTimes (only completed sessions for dashboard)
      // This is the source of truth for home dashboard completion detection
      final medicationCompletedTimes = <String, List<String>>{};
      for (final session in medicationSessions) {
        if (session.completed) {
          // Use scheduledTime if available (same basis as dashboard matching)
          final time = session.scheduledTime ?? session.dateTime;
          medicationCompletedTimes
              .putIfAbsent(session.medicationName, () => [])
              .add(time.toIso8601String());
        }
      }

      final totalMedicationDoses = medicationSessions.fold<double>(
        0,
        (total, s) => total + (s.dosageGiven),
      );

      final totalFluidVolume = fluidSessions.fold<double>(
        0,
        (total, s) => total + s.volumeGiven,
      );

      return (
        sessionCount: totalSessions,
        medicationSessionCount: medicationSessions.length,
        fluidSessionCount: fluidSessions.length,
        medicationNames: medicationNames,
        totalMedicationDoses: totalMedicationDoses,
        totalFluidVolume: totalFluidVolume,
        medicationRecentTimes: medicationRecentTimes,
        medicationCompletedTimes: medicationCompletedTimes,
      );
    } on LoggingException {
      rethrow; // UI handles these
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingService] Firebase error: ${e.message}');
      }

      // Track analytics
      await _analyticsService?.trackLoggingFailure(
        errorType: 'batch_write_failure',
        source: 'quick_log',
        errorCode: e.code,
        exception: 'FirebaseException',
      );

      throw BatchWriteException(
        'quickLogAllTreatments',
        e.message ?? 'Failed to log all treatments',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LoggingService] Unexpected error: $e');
      }

      // Track analytics
      await _analyticsService?.trackLoggingFailure(
        errorType: 'unexpected_logging_error',
        source: 'quick_log',
        exception: e.runtimeType.toString(),
      );

      throw LoggingException('Unexpected error in quick-log: $e');
    }
  }

  /// Gets cached daily summary for quick duplicate detection
  ///
  /// Uses [SummaryCacheService] to check SharedPreferences cache,
  /// avoiding Firestore reads for duplicate detection.
  ///
  /// Returns:
  /// - [DailySummaryCache] if valid cache exists for today
  /// - null if no cache or cache expired
  ///
  /// Cost: 0 Firestore reads when cache is valid
  Future<DailySummaryCache?> _getDailySummaryCache(
    String userId,
    String petId,
  ) async {
    return _cacheService.getTodaySummary(userId, petId);
  }

  // ============================================
  // PUBLIC API - Session Queries
  // ============================================

  /// Fetches today's medication sessions for a specific medication
  ///
  /// Used for duplicate detection. Only fetches sessions matching the
  /// medication name to minimize read costs (per Firebase CRUD rules).
  ///
  /// Process:
  /// 1. Calculate start of today (00:00:00)
  /// 2. Query medicationSessions where:
  ///    - petId == petId
  ///    - medicationName == medicationName
  ///    - dateTime >= startOfDay
  /// 3. Limit to 10 sessions (reasonable for ±15min duplicate window)
  ///
  /// Parameters:
  /// - `userId`: Current authenticated user ID
  /// - `petId`: Target pet ID
  /// - `medicationName`: Medication name to filter by
  ///
  /// Returns: List of medication sessions (empty if none found)
  ///
  /// Cost: 0-10 Firestore reads (only reads matching documents)
  ///
  /// Note: Requires composite index on (petId, medicationName, dateTime)
  Future<List<MedicationSession>> getTodaysMedicationSessions({
    required String userId,
    required String petId,
    required String medicationName,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          "[LoggingService] Fetching today's sessions for $medicationName",
        );
      }

      // Calculate start of today (00:00:00 local time)
      final now = DateTime.now();
      final startOfDay = AppDateUtils.startOfDay(now);

      // Query medication sessions
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .collection('medicationSessions')
          .where('medicationName', isEqualTo: medicationName)
          .where(
            'dateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .orderBy('dateTime', descending: true)
          .limit(10)
          .get();

      final sessions = snapshot.docs
          .map((doc) => MedicationSession.fromJson(doc.data()))
          .toList();

      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Found ${sessions.length} sessions for '
          '$medicationName today',
        );
      }

      return sessions;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Firebase error fetching sessions: ${e.message}',
        );
      }
      // Return empty list on error (don't block logging)
      return [];
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Unexpected error fetching sessions: $e',
        );
      }
      // Return empty list on error (don't block logging)
      return [];
    }
  }

  /// Fetches today's medication sessions across all medications (bounded)
  ///
  /// Used during cache warm when the local cache lacks medication names/times
  /// but the daily summary indicates medication activity today. This single
  /// query is capped via [limit] to comply with Firebase CRUD rules and cost
  /// guidelines.
  Future<List<MedicationSession>> getTodaysMedicationSessionsAll({
    required String userId,
    required String petId,
    int limit = 20,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          "[LoggingService] Fetching today's medication sessions (all)"
          ' limit=$limit',
        );
      }

      final now = DateTime.now();
      final startOfDay = AppDateUtils.startOfDay(now);

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .collection('medicationSessions')
          .where(
            'dateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .orderBy('dateTime', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MedicationSession.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
          "[LoggingService] Firebase error fetching today's all sessions: "
          '${e.message}',
        );
      }
      return const [];
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          "[LoggingService] Unexpected error fetching today's all sessions: $e",
        );
      }
      return const [];
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

  // Note: No duplicate detection for fluid sessions (per medical requirements)

  // ============================================
  // PRIVATE HELPERS - Daily Goal Calculation
  // ============================================

  /// Calculates the daily fluid goal from a schedule for a given date
  ///
  /// Formula: targetVolume × number of reminders on that date
  ///
  /// Example:
  /// - Schedule: 100ml per session, reminders at [9:00 AM, 3:00 PM, 9:00 PM]
  /// - Daily goal: 100ml × 3 = 300ml
  ///
  /// Returns null if schedule has no target volume or no reminders for date.
  double? _calculateDailyFluidGoal(Schedule schedule, DateTime date) {
    final targetVolume = schedule.targetVolume;
    if (targetVolume == null || targetVolume <= 0) {
      return null;
    }

    final reminderCount = schedule.reminderTimesOnDate(date).length;
    if (reminderCount == 0) {
      return null;
    }

    return targetVolume * reminderCount;
  }

  /// Calculates the weekly fluid goal from active schedules for a given date
  ///
  /// Formula: Daily volume × sessions per day × appropriate days per week
  /// - Once daily: volume × 1 × 7 = volume × 7
  /// - Twice daily: volume × 2 × 7 = volume × 14
  /// - Thrice daily: volume × 3 × 7 = volume × 21
  /// - Every other day: volume × 1 × 3.5 = volume × 3.5
  /// - Every 3 days: volume × 1 × 2.33 = volume × 2.33
  ///
  /// Returns null if:
  /// - No active fluid schedules found
  /// - Schedule has no target volume
  /// - This week already has a goal stored (prevents recalculation)
  ///
  /// This goal is stored in the weekly summary document for historical accuracy
  /// when schedules change mid-week.
  Future<int?> _calculateWeeklyGoalFromSchedules(
    String userId,
    String petId,
    List<Schedule> todaysSchedules,
    DateTime date,
  ) async {
    // Check if weekly summary already has goal stored
    final weeklyRef = _getWeeklySummaryRef(userId, petId, date);
    final weeklySnapshot = await weeklyRef.get();

    if (weeklySnapshot.exists) {
      final data = weeklySnapshot.data() as Map<String, dynamic>?;
      final existingGoal = (data?['fluidScheduledVolume'] as num?)?.toInt();
      if (existingGoal != null) {
        // Goal already calculated for this week, don't recalculate
        return null;
      }
    }

    // Find active fluid schedule
    final fluidSchedule = todaysSchedules
        .where((s) => s.treatmentType == TreatmentType.fluid)
        .where((s) => s.isActive)
        .firstOrNull;

    if (fluidSchedule == null || fluidSchedule.targetVolume == null) {
      return null;
    }

    final dailyVolume = fluidSchedule.targetVolume!;
    final frequency = fluidSchedule.frequency;

    // Calculate weekly multiplier based on frequency
    final weeklyMultiplier = switch (frequency) {
      TreatmentFrequency.onceDaily => 7.0,
      TreatmentFrequency.twiceDaily => 14.0,
      TreatmentFrequency.thriceDaily => 21.0,
      TreatmentFrequency.everyOtherDay => 3.5,
      TreatmentFrequency.every3Days => 2.33,
    };

    return (dailyVolume * weeklyMultiplier).round();
  }

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
  // PRIVATE HELPERS - Batch Writes (4-write pattern)
  // ============================================

  /// Adds medication session to batch with summary updates
  ///
  /// Adds 4 operations to the batch (optimized from 7):
  /// 1. Session document write
  /// 2. Daily summary (single set with merge + increments)
  /// 3. Weekly summary (single set with merge + increments)
  /// 4. Monthly summary (single set with merge + increments)
  ///
  /// This helper is used by both single session logging and quick-log batch.
  void _addMedicationSessionToBatch({
    required WriteBatch batch,
    required MedicationSession session,
    required String userId,
    required String petId,
    required int scheduledDosesCount,
  }) {
    final sessionRef = _getMedicationSessionRef(userId, petId, session.id);
    final date = AppDateUtils.startOfDay(session.dateTime);
    final dto = SummaryUpdateDto.fromMedicationSession(session).copyWith(
      medicationScheduledDelta: scheduledDosesCount,
    );

    // Operation 1: Write session
    batch.set(sessionRef, _buildSessionCreateData(session.toJson()));

    // Operation 2: Daily summary (single set with merge + increments)
    final dailyRef = _getDailySummaryRef(userId, petId, date);
    batch.set(
      dailyRef,
      _buildDailySummaryWithIncrements(date, dto),
      SetOptions(merge: true),
    );

    // Operation 3: Weekly summary (single set with merge + increments)
    final weeklyRef = _getWeeklySummaryRef(userId, petId, date);
    batch.set(
      weeklyRef,
      _buildWeeklySummaryWithIncrements(date, dto),
      SetOptions(merge: true),
    );

    // Operation 4: Monthly summary (single set with merge + increments)
    final monthlyRef = _getMonthlySummaryRef(userId, petId, date);
    batch.set(
      monthlyRef,
      _buildMonthlySummaryWithIncrements(date, dto),
      SetOptions(merge: true),
    );
  }

  /// Adds fluid session to batch with summary updates
  ///
  /// Adds 4 operations to the batch (optimized from 7):
  /// 1. Session document write
  /// 2. Daily summary (single set with merge + increments)
  /// 3. Weekly summary (single set with merge + increments)
  /// 4. Monthly summary (single set with merge + increments)
  ///
  /// This helper is used by both single session logging and quick-log batch.
  void _addFluidSessionToBatch({
    required WriteBatch batch,
    required FluidSession session,
    required String userId,
    required String petId,
    required int scheduledSessionsCount,
    int? weeklyGoalMl,
    // Optional monthly array data (for Phase 1: single-day logging)
    int? dayVolumeTotal,
    int? dayGoalMl,
    int? dayScheduledCount,
    List<int>? currentDailyVolumes,
    List<int>? currentDailyGoals,
    List<int>? currentDailyScheduledSessions,
  }) {
    final sessionRef = _getFluidSessionRef(userId, petId, session.id);
    final date = AppDateUtils.startOfDay(session.dateTime);
    final dto = SummaryUpdateDto.fromFluidSession(session).copyWith(
      fluidScheduledDelta: scheduledSessionsCount,
    );

    // Operation 1: Write session
    batch.set(sessionRef, _buildSessionCreateData(session.toJson()));

    // Operation 2: Daily summary (single set with merge + increments)
    final dailyRef = _getDailySummaryRef(userId, petId, date);
    batch.set(
      dailyRef,
      _buildDailySummaryWithIncrements(
        date,
        dto,
        dailyGoalMl: session.dailyGoalMl,
      ),
      SetOptions(merge: true),
    );

    // Operation 3: Weekly summary (single set with merge + increments)
    final weeklyRef = _getWeeklySummaryRef(userId, petId, date);
    batch.set(
      weeklyRef,
      _buildWeeklySummaryWithIncrements(date, dto, weeklyGoalMl: weeklyGoalMl),
      SetOptions(merge: true),
    );

    // Operation 4: Monthly summary (single set with merge + increments)
    final monthlyRef = _getMonthlySummaryRef(userId, petId, date);
    batch.set(
      monthlyRef,
      _buildMonthlySummaryWithIncrements(
        date,
        dto,
        dayVolumeTotal: dayVolumeTotal,
        dayGoalMl: dayGoalMl,
        dayScheduledCount: dayScheduledCount,
        currentDailyVolumes: currentDailyVolumes,
        currentDailyGoals: currentDailyGoals,
        currentDailyScheduledSessions: currentDailyScheduledSessions,
      ),
      SetOptions(merge: true),
    );
  }

  /// Executes batch write with error handling and logging
  ///
  /// Wraps batch.commit() with try-catch and debug logging.
  /// Total operations in batch: 4 per session (1 session + 3 summaries with
  /// merge + increments)
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

  /// Wraps session payload to ensure server timestamps for audit fields.
  ///
  /// - Always sets `createdAt` to server timestamp (on creation)
  /// - Always sets `updatedAt` to server timestamp
  Map<String, dynamic> _buildSessionCreateData(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    map['createdAt'] = FieldValue.serverTimestamp();
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }

  /// Builds daily summary with increments (optimized single-write)
  ///
  /// Combines initialization and increments into a single map for use with
  /// SetOptions(merge: true). This allows a single write operation that:
  /// - Creates the document if it doesn't exist
  /// - Updates existing fields if it does exist
  ///
  /// FieldValue.increment() works on non-existent fields (treats as 0).
  ///
  /// Note: overallStreak always 0 (calculated in Phase 7 by daily job)
  /// Note: For summaries with continuous updates, createdAt and updatedAt both
  /// use server timestamps and will be updated on each write (acceptable for
  /// aggregated data that changes frequently).
  Map<String, dynamic> _buildDailySummaryWithIncrements(
    DateTime date,
    SummaryUpdateDto dto, {
    double? dailyGoalMl,
  }) {
    final map =
        <String, dynamic>{
            'date': Timestamp.fromDate(date),
            'overallStreak': 0, // Calculated in Phase 7
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }
          // Add DTO increments (will create or increment existing fields)
          ..addAll(dto.toFirestoreUpdate());

    // Add daily goal if provided (only for fluid sessions)
    if (dailyGoalMl != null) {
      map['fluidDailyGoalMl'] = dailyGoalMl.round();
    }

    return map;
  }

  /// Builds weekly summary with increments (optimized single-write)
  ///
  /// Combines initialization and increments into a single map for use with
  /// SetOptions(merge: true). This allows a single write operation that:
  /// - Creates the document if it doesn't exist
  /// - Updates existing fields if it does exist
  ///
  /// FieldValue.increment() works on non-existent fields (treats as 0).
  Map<String, dynamic> _buildWeeklySummaryWithIncrements(
    DateTime date,
    SummaryUpdateDto dto, {
    int? weeklyGoalMl,
  }) {
    final map =
        <String, dynamic>{
            'weekId': AppDateUtils.formatWeekForSummary(date), // "2025-W40"
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }
          // Add DTO increments (will create or increment existing fields)
          ..addAll(dto.toFirestoreUpdate());

    // Add weekly goal if provided (only on first session of week)
    if (weeklyGoalMl != null) {
      map['fluidScheduledVolume'] = weeklyGoalMl;
    }

    return map;
  }

  /// Builds monthly summary with increments (optimized single-write)
  ///
  /// Combines initialization and increments into a single map for use with
  /// SetOptions(merge: true). This allows a single write operation that:
  /// - Creates the document if it doesn't exist
  /// - Updates existing fields if it does exist
  ///
  /// FieldValue.increment() works on non-existent fields (treats as 0).
  Map<String, dynamic> _buildMonthlySummaryWithIncrements(
    DateTime date,
    SummaryUpdateDto dto, {
    // Optional per-day fluid data for monthly arrays
    int? dayVolumeTotal,
    int? dayGoalMl,
    int? dayScheduledCount,
    List<int>? currentDailyVolumes,
    List<int>? currentDailyGoals,
    List<int>? currentDailyScheduledSessions,
  }) {
    final map =
        <String, dynamic>{
            'monthId': AppDateUtils.formatMonthForSummary(date), // "2025-10"
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }
          // Add DTO increments (will create or increment existing fields)
          ..addAll(dto.toFirestoreUpdate());

    // Add per-day arrays if data provided (fluids only)
    if (dayVolumeTotal != null && currentDailyVolumes != null) {
      final monthLength = AppDateUtils.getMonthStartEnd(date)['end']!.day;
      map['dailyVolumes'] = MonthlyArrayHelper.updateDailyArrayValue(
        currentArray: currentDailyVolumes,
        dayOfMonth: date.day,
        monthLength: monthLength,
        newValue: dayVolumeTotal,
      );
    }

    if (dayGoalMl != null && currentDailyGoals != null) {
      final monthLength = AppDateUtils.getMonthStartEnd(date)['end']!.day;
      map['dailyGoals'] = MonthlyArrayHelper.updateDailyArrayValue(
        currentArray: currentDailyGoals,
        dayOfMonth: date.day,
        monthLength: monthLength,
        newValue: dayGoalMl,
      );
    }

    if (dayScheduledCount != null && currentDailyScheduledSessions != null) {
      final monthLength = AppDateUtils.getMonthStartEnd(date)['end']!.day;
      map['dailyScheduledSessions'] = MonthlyArrayHelper.updateDailyArrayValue(
        currentArray: currentDailyScheduledSessions,
        dayOfMonth: date.day,
        monthLength: monthLength,
        newValue: dayScheduledCount,
      );
    }

    return map;
  }

  // ============================================
  // PRIVATE HELPERS - Aggregation for quick-log
  // ============================================

  /// Aggregates summary deltas for all quick-log sessions to minimize writes.
  ///
  /// Instead of writing daily/weekly/monthly summaries per session, we
  /// compute a single [SummaryUpdateDto] representing the union of all
  /// sessions and perform exactly three writes (one per period).
  ///
  /// Note: If [scheduledDosesAlreadyCounted] is true, medicationScheduledDelta
  /// will be null to avoid double-counting scheduled doses that were already
  /// set when the first medication session was logged manually.
  /// Similarly, if [fluidScheduledAlreadyCounted] is true, fluidScheduledDelta
  /// will be null to avoid double-counting scheduled fluid sessions.
  SummaryUpdateDto _aggregateSummaryForQuickLog({
    required List<MedicationSession> medicationSessions,
    required List<FluidSession> fluidSessions,
    required bool scheduledDosesAlreadyCounted,
    required bool fluidScheduledAlreadyCounted,
  }) {
    var completedMedicationDoses = 0;
    var scheduledMedicationDoses = 0;
    var missedMedicationDoses = 0;

    for (final session in medicationSessions) {
      scheduledMedicationDoses += 1;
      if (session.completed) {
        completedMedicationDoses += 1;
      } else {
        missedMedicationDoses += 1;
      }
    }

    var fluidVolumeTotal = 0.0;
    var fluidSessionsCount = 0;
    for (final session in fluidSessions) {
      fluidVolumeTotal += session.volumeGiven;
      fluidSessionsCount += 1;
    }

    return SummaryUpdateDto(
      medicationDosesDelta: completedMedicationDoses == 0
          ? null
          : completedMedicationDoses,
      // Only increment scheduled doses if they haven't been counted yet
      // (first medication log of the day sets the total scheduled count)
      medicationScheduledDelta: scheduledDosesAlreadyCounted
          ? null
          : (scheduledMedicationDoses == 0 ? null : scheduledMedicationDoses),
      medicationMissedDelta: missedMedicationDoses == 0
          ? null
          : missedMedicationDoses,
      fluidVolumeDelta: fluidVolumeTotal == 0.0 ? null : fluidVolumeTotal,
      fluidSessionDelta: fluidSessionsCount == 0 ? null : fluidSessionsCount,
      // Only increment scheduled fluid sessions if they haven't been
      // counted yet
      // (first fluid log of the day sets the total scheduled count)
      fluidScheduledDelta: fluidScheduledAlreadyCounted
          ? null
          : (fluidSessionsCount == 0 ? null : fluidSessionsCount),
      fluidTreatmentDone: fluidSessions.isNotEmpty,
      // Quick-log only creates remaining sessions,
      // so after quick-log completes,
      // all primary treatments for the day are indeed logged
      overallTreatmentDone: true,
    );
  }

  /// Commits quick-log sessions in chunks if operation count nears 500 limit.
  ///
  /// First batch writes all summaries plus as many sessions as will fit; the
  /// remaining sessions are written in subsequent batches without summaries.
  Future<void> _commitQuickLogInChunks({
    required String userId,
    required String petId,
    required List<MedicationSession> medicationSessions,
    required List<FluidSession> fluidSessions,
    required DateTime todayDate,
    required SummaryUpdateDto aggregatedDto,
  }) async {
    const maxOps = 500;

    var medIndex = 0;
    var fluidIndex = 0;
    var isFirstBatch = true;

    while (medIndex < medicationSessions.length ||
        fluidIndex < fluidSessions.length ||
        isFirstBatch) {
      var ops = 0;
      final batch = _firestore.batch();

      // Include summaries only in first batch (3 ops)
      if (isFirstBatch) {
        final dailyRef = _getDailySummaryRef(userId, petId, todayDate);
        // Get daily goal from first fluid session if any exist
        final dailyGoal = fluidSessions.isNotEmpty
            ? fluidSessions.first.dailyGoalMl
            : null;
        batch.set(
          dailyRef,
          _buildDailySummaryWithIncrements(
            todayDate,
            aggregatedDto,
            dailyGoalMl: dailyGoal,
          ),
          SetOptions(merge: true),
        );
        ops++;

        final weeklyRef = _getWeeklySummaryRef(userId, petId, todayDate);
        batch.set(
          weeklyRef,
          _buildWeeklySummaryWithIncrements(todayDate, aggregatedDto),
          SetOptions(merge: true),
        );
        ops++;

        final monthlyRef = _getMonthlySummaryRef(userId, petId, todayDate);
        batch.set(
          monthlyRef,
          _buildMonthlySummaryWithIncrements(todayDate, aggregatedDto),
          SetOptions(merge: true),
        );
        ops++;
      }

      // Add medication sessions until the batch is filled
      while (ops < maxOps && medIndex < medicationSessions.length) {
        final s = medicationSessions[medIndex++];
        final ref = _getMedicationSessionRef(userId, petId, s.id);
        batch.set(ref, _buildSessionCreateData(s.toJson()));
        ops++;
      }

      // Add fluid sessions until the batch is filled
      while (ops < maxOps && fluidIndex < fluidSessions.length) {
        final s = fluidSessions[fluidIndex++];
        final ref = _getFluidSessionRef(userId, petId, s.id);
        batch.set(ref, _buildSessionCreateData(s.toJson()));
        ops++;
      }

      await _executeBatchWrite(
        batch: batch,
        operation: isFirstBatch
            ? 'quickLogAllTreatments:chunk1'
            : 'quickLogAllTreatments:chunk',
      );

      // After first batch, summaries should not be written again
      isFirstBatch = false;

      // Loop continues if there are remaining sessions
      if (medIndex >= medicationSessions.length &&
          fluidIndex >= fluidSessions.length) {
        break;
      }
    }
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

  // ============================================
  // PRIVATE HELPERS - Monthly Array Updates
  // ============================================

  /// Fetches current daily summary to get accurate daily totals
  ///
  /// Returns daily totals after this operation for monthly array update.
  /// Reads daily summary once to handle multiple sessions per day correctly.
  ///
  /// **Purpose**: Ensures monthly arrays reflect the complete daily total,
  /// not just the current session's volume. Critical for correctness when
  /// logging multiple sessions on the same day.
  ///
  /// **Performance**: +1 Firestore read per operation (accepted tradeoff)
  ///
  /// **Returns**:
  /// - `volumeTotal`: Total fluid volume for the day (after this operation)
  /// - `goalMl`: Daily goal (from session or existing summary)
  /// - `scheduledCount`: Number of scheduled sessions for the day
  Future<({int volumeTotal, int goalMl, int scheduledCount})>
      _fetchDailyTotalsForMonthly({
    required String userId,
    required String petId,
    required DateTime date,
    required int sessionVolumeDelta, // +volume for add, delta for update
    required int? sessionGoalMl,
    required int sessionScheduledCount,
  }) async {
    final dailyRef = _getDailySummaryRef(userId, petId, date);
    final docSnapshot = await dailyRef.get();

    var currentVolume = 0;
    var currentGoal = 0;
    var currentScheduled = 0;

    if (docSnapshot.exists) {
      final data = docSnapshot.data()! as Map<String, dynamic>;
      currentVolume = (data['fluidTotalVolume'] as num?)?.toInt() ?? 0;
      currentGoal = (data['fluidDailyGoalMl'] as num?)?.toInt() ?? 0;
      currentScheduled =
          (data['fluidScheduledSessions'] as num?)?.toInt() ?? 0;
    }

    // Calculate new totals after this operation
    final newVolume = (currentVolume + sessionVolumeDelta).clamp(0, 50000);
    final newGoal = sessionGoalMl ?? currentGoal;
    final newScheduled =
        (currentScheduled + sessionScheduledCount).clamp(0, 100);

    return (
      volumeTotal: newVolume,
      goalMl: newGoal,
      scheduledCount: newScheduled,
    );
  }

  /// Fetches current monthly summary arrays for updating
  ///
  /// Returns existing arrays from Firestore to merge with new day's data.
  /// Returns null arrays if document doesn't exist yet
  /// (first session of month).
  ///
  /// **Purpose**: Retrieves current array state before updating a single day's
  /// value, maintaining data for other days in the month.
  ///
  /// **Performance**: +1 Firestore read per operation (accepted tradeoff)
  ///
  /// **Returns**:
  /// - `dailyVolumes`: Existing volume array or null if doc missing
  /// - `dailyGoals`: Existing goal array or null if doc missing
  /// - `dailyScheduledSessions`: Existing scheduled count array or null
  Future<({
    List<int>? dailyVolumes,
    List<int>? dailyGoals,
    List<int>? dailyScheduledSessions,
  })> _fetchMonthlyArrays({
    required String userId,
    required String petId,
    required DateTime date,
  }) async {
    final monthlyRef = _getMonthlySummaryRef(userId, petId, date);
    final docSnapshot = await monthlyRef.get();

    if (!docSnapshot.exists) {
      return (
        dailyVolumes: null,
        dailyGoals: null,
        dailyScheduledSessions: null,
      );
    }

    final data = docSnapshot.data()! as Map<String, dynamic>;

    // Parse arrays using same logic as MonthlySummary.fromJson
    List<int>? parseIntListOrNull(dynamic value, int expectedLength) {
      if (value == null || value is! List) return null;

      final parsed = value.map((e) {
        final intVal = (e as num?)?.toInt() ?? 0;
        return intVal.clamp(0, 5000);
      }).toList();

      // Pad or truncate to expected length
      if (parsed.length < expectedLength) {
        return [...parsed, ...List.filled(expectedLength - parsed.length, 0)];
      } else if (parsed.length > expectedLength) {
        return parsed.sublist(0, expectedLength);
      }
      return parsed;
    }

    final monthLength = AppDateUtils.getMonthStartEnd(date)['end']!.day;

    return (
      dailyVolumes: parseIntListOrNull(data['dailyVolumes'], monthLength),
      dailyGoals: parseIntListOrNull(data['dailyGoals'], monthLength),
      dailyScheduledSessions:
          parseIntListOrNull(data['dailyScheduledSessions'], monthLength),
    );
  }

  // ============================================
  // PRIVATE HELPERS - Schedule Count Checks
  // ============================================

  /// Check if scheduled doses have already been counted for this date
  ///
  /// Returns true if medicationScheduledDoses > 0 in the daily summary.
  /// This prevents overcounting when logging multiple medication sessions
  /// on the same day.
  ///
  /// Used by logMedicationSession to only count schedules once per day.
  Future<bool> _hasScheduledDosesCounted(
    String userId,
    String petId,
    DateTime date,
  ) async {
    try {
      final dailyRef = _getDailySummaryRef(userId, petId, date);
      final snapshot = await dailyRef.get();

      if (!snapshot.exists) return false;

      final data = snapshot.data() as Map<String, dynamic>?;
      final scheduledDoses =
          (data?['medicationScheduledDoses'] as num?)?.toInt() ?? 0;

      return scheduledDoses > 0;
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Error checking scheduled doses: $e',
        );
      }
      // On error, assume not counted (safer to overcount than undercount)
      return false;
    }
  }

  /// Check if scheduled fluid sessions have already been counted for this date
  ///
  /// Returns true if fluidScheduledSessions > 0 in the daily summary.
  /// This prevents overcounting when logging multiple fluid sessions
  /// on the same day.
  ///
  /// Used by logFluidSession to only count schedules once per day.
  Future<bool> _hasFluidScheduledCounted(
    String userId,
    String petId,
    DateTime date,
  ) async {
    try {
      final dailyRef = _getDailySummaryRef(userId, petId, date);
      final snapshot = await dailyRef.get();

      if (!snapshot.exists) return false;

      final data = snapshot.data() as Map<String, dynamic>?;
      final scheduledSessions =
          (data?['fluidScheduledSessions'] as num?)?.toInt() ?? 0;

      return scheduledSessions > 0;
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Error checking scheduled fluid sessions: $e',
        );
      }
      return false;
    }
  }
}
