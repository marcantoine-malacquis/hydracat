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
import 'package:hydracat/features/logging/services/summary_cache_service.dart';
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

      // STEP 4: Build 4-write batch
      final batch = _firestore.batch();
      _addMedicationSessionToBatch(
        batch: batch,
        session: sessionWithSchedule,
        userId: userId,
        petId: petId,
      );

      // STEP 5: Commit batch
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

      // STEP 3: Build 4-write batch
      final batch = _firestore.batch();
      _addFluidSessionToBatch(
        batch: batch,
        session: sessionWithSchedule,
        userId: userId,
        petId: petId,
      );

      // STEP 4: Commit batch
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
        _buildMonthlySummaryWithIncrements(date, dto),
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
  /// Returns: Total number of sessions logged
  ///
  /// Throws:
  /// - [LoggingException]: Empty schedules or sessions already logged
  /// - [BatchWriteException]: Firestore write failed
  ///
  /// Cost: N sessions × 4 writes (typical: 5 sessions = 20 writes)
  ///
  /// Example:
  /// ```dart
  /// final count = await loggingService.quickLogAllTreatments(
  ///   userId: user.id,
  ///   petId: pet.id,
  ///   todaysSchedules: schedules,
  /// );
  /// // Returns: 5 (logged 3 med sessions + 2 fluid sessions)
  /// ```
  Future<int> quickLogAllTreatments({
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

      // STEP 2: Check cache for existing sessions (strict all-or-nothing)
      final cache = await _getDailySummaryCache(userId, petId);
      if (cache != null && cache.hasAnySessions) {
        throw const LoggingException(
          'Treatments already logged today. '
          'Use individual logging to add more sessions.',
        );
      }

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

      // STEP 4: Generate all sessions from schedules
      final medicationSessions = <MedicationSession>[];
      final fluidSessions = <FluidSession>[];

      for (final schedule in activeSchedules) {
        // Get today's reminder times only (centralized helper)
        final todaysReminders = schedule.todaysReminderTimes(now).toList();

        for (final reminderTime in todaysReminders) {
          if (schedule.treatmentType == TreatmentType.medication) {
            // Create medication session with scheduled time
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
          } else if (schedule.treatmentType == TreatmentType.fluid) {
            // Create fluid session with scheduled time
            fluidSessions.add(
              FluidSession.fromSchedule(
                schedule: schedule,
                scheduledTime: reminderTime,
                petId: petId,
                userId: userId,
                actualDateTime: reminderTime, // Use scheduled time
              ),
            );
          }
        }
      }

      final totalSessions = medicationSessions.length + fluidSessions.length;

      if (totalSessions == 0) {
        throw const LoggingException(
          'No sessions to log. Please check schedule configuration.',
        );
      }

      if (kDebugMode) {
        debugPrint(
          '[LoggingService] Generated $totalSessions sessions: '
          '${medicationSessions.length} medications, '
          '${fluidSessions.length} fluids',
        );
      }

      // STEP 5: Aggregate summary deltas (used for summaries)
      final todayDate = AppDateUtils.startOfDay(now);
      final aggregatedDto = _aggregateSummaryForQuickLog(
        medicationSessions: medicationSessions,
        fluidSessions: fluidSessions,
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
        batch.set(
          dailyRef,
          _buildDailySummaryWithIncrements(todayDate, aggregatedDto),
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

      return totalSessions;
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
  }) {
    final sessionRef = _getMedicationSessionRef(userId, petId, session.id);
    final date = AppDateUtils.startOfDay(session.dateTime);
    final dto = SummaryUpdateDto.fromMedicationSession(session);

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
  }) {
    final sessionRef = _getFluidSessionRef(userId, petId, session.id);
    final date = AppDateUtils.startOfDay(session.dateTime);
    final dto = SummaryUpdateDto.fromFluidSession(session);

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
    SummaryUpdateDto dto,
  ) {
    final map =
        <String, dynamic>{
            'date': Timestamp.fromDate(date),
            'overallStreak': 0, // Calculated in Phase 7
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }
          // Add DTO increments (will create or increment existing fields)
          ..addAll(dto.toFirestoreUpdate());

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
    SummaryUpdateDto dto,
  ) {
    final map =
        <String, dynamic>{
            'weekId': AppDateUtils.formatWeekForSummary(date), // "2025-W40"
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }
          // Add DTO increments (will create or increment existing fields)
          ..addAll(dto.toFirestoreUpdate());

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
    SummaryUpdateDto dto,
  ) {
    final map =
        <String, dynamic>{
            'monthId': AppDateUtils.formatMonthForSummary(date), // "2025-10"
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }
          // Add DTO increments (will create or increment existing fields)
          ..addAll(dto.toFirestoreUpdate());

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
  SummaryUpdateDto _aggregateSummaryForQuickLog({
    required List<MedicationSession> medicationSessions,
    required List<FluidSession> fluidSessions,
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
      medicationScheduledDelta: scheduledMedicationDoses == 0
          ? null
          : scheduledMedicationDoses,
      medicationMissedDelta: missedMedicationDoses == 0
          ? null
          : missedMedicationDoses,
      fluidVolumeDelta: fluidVolumeTotal == 0.0 ? null : fluidVolumeTotal,
      fluidSessionDelta: fluidSessionsCount == 0 ? null : fluidSessionsCount,
      fluidTreatmentDone: fluidSessions.isNotEmpty,
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
        batch.set(
          dailyRef,
          _buildDailySummaryWithIncrements(todayDate, aggregatedDto),
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
}
