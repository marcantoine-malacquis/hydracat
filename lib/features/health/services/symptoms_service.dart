import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/health/exceptions/health_exceptions.dart';
import 'package:hydracat/features/health/models/health_parameter.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/shared/models/daily_summary.dart';
import 'package:intl/intl.dart';

/// Service for symptom tracking operations
///
/// Handles CRUD operations for symptom entries with:
/// - Batch writes to healthParameters and daily/weekly/monthly summaries
/// - Validation using ProfileValidationService
/// - Cost-optimized queries
/// - Delta-based summary updates
class SymptomsService {
  /// Creates a [SymptomsService] instance
  SymptomsService({
    FirebaseFirestore? firestore,
    AnalyticsService? analyticsService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _analyticsService = analyticsService;

  final FirebaseFirestore _firestore;
  final AnalyticsService? _analyticsService;

  // ============================================
  // PRIVATE HELPERS - Firestore Paths
  // ============================================

  /// Gets health parameter document reference
  ///
  /// Path: users/{userId}/pets/{petId}/healthParameters/{YYYY-MM-DD}
  DocumentReference _getHealthParameterRef(
    String userId,
    String petId,
    DateTime date,
  ) {
    final docId = DateFormat('yyyy-MM-dd').format(date);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('healthParameters')
        .doc(docId);
  }

  /// Gets daily summary document reference
  ///
  /// Path: users/{userId}/pets/{petId}/treatmentSummaries/daily/summaries/{YYYY-MM-DD}
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
  /// Path: users/{userId}/pets/{petId}/treatmentSummaries/weekly/summaries/{YYYY-Www}
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
  /// Path: users/{userId}/pets/{petId}/treatmentSummaries/monthly/summaries/{YYYY-MM}
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
  // VALIDATION
  // ============================================

  /// Validates symptom scores
  ///
  /// Ensures all symptom scores are in the 0-10 range.
  /// Throws [SymptomValidationException] if any score is invalid.
  void _validateSymptomScores(Map<String, int>? symptoms) {
    if (symptoms == null) return;

    for (final entry in symptoms.entries) {
      final score = entry.value;
      if (score < 0 || score > 10) {
        throw SymptomValidationException(
          'Symptom score for "${entry.key}" must be between 0 and 10 '
          '(inclusive), got: $score',
        );
      }
    }
  }

  /// Validates notes length
  ///
  /// Ensures notes do not exceed 500 character limit.
  /// Throws [SymptomValidationException] if notes are too long.
  void _validateNotes(String? notes) {
    if (notes != null && notes.length > 500) {
      throw const SymptomValidationException(
        'Notes must be 500 characters or less',
      );
    }
  }

  // ============================================
  // HELPER: Daily Summary Update Logic
  // ============================================

  /// Builds daily summary update map from HealthParameter entry
  ///
  /// Returns a map of fields to update in the daily summary document.
  /// If oldEntry is null, this is a new entry. Otherwise, it's an update.
  Map<String, dynamic> _buildDailySummaryUpdates(
    HealthParameter newEntry,
    HealthParameter? oldEntry,
    DateTime date,
  ) {
    final updates = <String, dynamic>{
      'date': Timestamp.fromDate(date),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Compute symptom boolean fields from new entry
    final symptoms = newEntry.symptoms;
    final hadVomiting = (symptoms?[SymptomType.vomiting] ?? 0) > 0;
    final hadDiarrhea = (symptoms?[SymptomType.diarrhea] ?? 0) > 0;
    final hadConstipation = (symptoms?[SymptomType.constipation] ?? 0) > 0;
    final hadLethargy = (symptoms?[SymptomType.lethargy] ?? 0) > 0;
    final hadSuppressedAppetite =
        (symptoms?[SymptomType.suppressedAppetite] ?? 0) > 0;
    final hadInjectionSiteReaction =
        (symptoms?[SymptomType.injectionSiteReaction] ?? 0) > 0;

    // Compute max scores for each symptom (for single day, max = current score)
    updates['hadVomiting'] = hadVomiting;
    updates['hadDiarrhea'] = hadDiarrhea;
    updates['hadConstipation'] = hadConstipation;
    updates['hadLethargy'] = hadLethargy;
    updates['hadSuppressedAppetite'] = hadSuppressedAppetite;
    updates['hadInjectionSiteReaction'] = hadInjectionSiteReaction;

    // Set max scores (only if symptom is present)
    if (hadVomiting && symptoms != null) {
      updates['vomitingMaxScore'] = symptoms[SymptomType.vomiting];
    }
    if (hadDiarrhea && symptoms != null) {
      updates['diarrheaMaxScore'] = symptoms[SymptomType.diarrhea];
    }
    if (hadConstipation && symptoms != null) {
      updates['constipationMaxScore'] = symptoms[SymptomType.constipation];
    }
    if (hadLethargy && symptoms != null) {
      updates['lethargyMaxScore'] = symptoms[SymptomType.lethargy];
    }
    if (hadSuppressedAppetite && symptoms != null) {
      updates['suppressedAppetiteMaxScore'] =
          symptoms[SymptomType.suppressedAppetite];
    }
    if (hadInjectionSiteReaction && symptoms != null) {
      updates['injectionSiteReactionMaxScore'] =
          symptoms[SymptomType.injectionSiteReaction];
    }

    // Set overall scores from newEntry (computed by HealthParameter.create())
    if (newEntry.symptomScoreTotal != null) {
      updates['symptomScoreTotal'] = newEntry.symptomScoreTotal;
    }
    if (newEntry.symptomScoreAverage != null) {
      updates['symptomScoreAverage'] = newEntry.symptomScoreAverage;
    }
    updates['hasSymptoms'] = newEntry.hasSymptoms ?? false;

    // Set createdAt if this is a new entry (oldEntry is null)
    if (oldEntry == null) {
      updates['createdAt'] = FieldValue.serverTimestamp();
    }

    return updates;
  }

  // ============================================
  // HELPER: Weekly Summary Delta Logic
  // ============================================

  /// Builds weekly summary delta updates from daily summary changes
  ///
  /// Returns a map of delta updates to apply to the weekly summary.
  /// Uses FieldValue.increment() where possible for atomic updates.
  Map<String, dynamic> _buildWeeklySummaryDeltas(
    DailySummary? oldDaily,
    DailySummary newDaily,
  ) {
    final deltas = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final oldHadVomiting = oldDaily?.hadVomiting ?? false;
    final oldHadDiarrhea = oldDaily?.hadDiarrhea ?? false;
    final oldHadConstipation = oldDaily?.hadConstipation ?? false;
    final oldHadLethargy = oldDaily?.hadLethargy ?? false;
    final oldHadSuppressedAppetite = oldDaily?.hadSuppressedAppetite ?? false;
    final oldHadInjectionSiteReaction =
        oldDaily?.hadInjectionSiteReaction ?? false;

    // Compute day count deltas for each symptom
    if (oldHadVomiting == false && newDaily.hadVomiting == true) {
      deltas['daysWithVomiting'] = FieldValue.increment(1);
    } else if (oldHadVomiting == true && newDaily.hadVomiting == false) {
      deltas['daysWithVomiting'] = FieldValue.increment(-1);
    }

    if (oldHadDiarrhea == false && newDaily.hadDiarrhea == true) {
      deltas['daysWithDiarrhea'] = FieldValue.increment(1);
    } else if (oldHadDiarrhea == true && newDaily.hadDiarrhea == false) {
      deltas['daysWithDiarrhea'] = FieldValue.increment(-1);
    }

    if (oldHadConstipation == false && newDaily.hadConstipation == true) {
      deltas['daysWithConstipation'] = FieldValue.increment(1);
    } else if (oldHadConstipation == true &&
        newDaily.hadConstipation == false) {
      deltas['daysWithConstipation'] = FieldValue.increment(-1);
    }

    if (oldHadLethargy == false && newDaily.hadLethargy == true) {
      deltas['daysWithLethargy'] = FieldValue.increment(1);
    } else if (oldHadLethargy == true && newDaily.hadLethargy == false) {
      deltas['daysWithLethargy'] = FieldValue.increment(-1);
    }

    if (oldHadSuppressedAppetite == false &&
        newDaily.hadSuppressedAppetite == true) {
      deltas['daysWithSuppressedAppetite'] = FieldValue.increment(1);
    } else if (oldHadSuppressedAppetite == true &&
        newDaily.hadSuppressedAppetite == false) {
      deltas['daysWithSuppressedAppetite'] = FieldValue.increment(-1);
    }

    if (oldHadInjectionSiteReaction == false &&
        newDaily.hadInjectionSiteReaction == true) {
      deltas['daysWithInjectionSiteReaction'] = FieldValue.increment(1);
    } else if (oldHadInjectionSiteReaction == true &&
        newDaily.hadInjectionSiteReaction == false) {
      deltas['daysWithInjectionSiteReaction'] = FieldValue.increment(-1);
    }

    // Handle daysWithAnySymptoms delta (based on hasSymptoms boolean)
    final oldHasSymptoms = oldDaily?.hasSymptoms ?? false;
    final newHasSymptoms = newDaily.hasSymptoms;
    if (oldHasSymptoms == false && newHasSymptoms == true) {
      deltas['daysWithAnySymptoms'] = FieldValue.increment(1);
    } else if (oldHasSymptoms == true && newHasSymptoms == false) {
      deltas['daysWithAnySymptoms'] = FieldValue.increment(-1);
    }

    // Handle symptomScoreTotal delta
    final oldTotal = oldDaily?.symptomScoreTotal;
    final newTotal = newDaily.symptomScoreTotal;
    if (oldTotal != null && newTotal != null) {
      final delta = newTotal - oldTotal;
      if (delta != 0) {
        deltas['symptomScoreTotal'] = FieldValue.increment(delta);
      }
    } else if (oldTotal == null && newTotal != null) {
      // New entry with symptoms
      deltas['symptomScoreTotal'] = newTotal;
    } else if (oldTotal != null && newTotal == null) {
      // Removed all symptoms
      deltas['symptomScoreTotal'] = FieldValue.increment(-oldTotal);
    }

    // For symptomScoreMax and symptomScoreAverage, we need to read current
    // summary. These will be handled separately in saveSymptoms method

    return deltas;
  }

  // ============================================
  // HELPER: Monthly Summary Delta Logic
  // ============================================

  /// Builds monthly summary delta updates from daily summary changes
  ///
  /// Returns a map of delta updates to apply to the monthly summary.
  /// Uses FieldValue.increment() where possible for atomic updates.
  Map<String, dynamic> _buildMonthlySummaryDeltas(
    DailySummary? oldDaily,
    DailySummary newDaily,
  ) {
    // Same logic as weekly deltas
    return _buildWeeklySummaryDeltas(oldDaily, newDaily);
  }

  // ============================================
  // CRUD OPERATIONS
  // ============================================

  /// Gets health parameter for a specific date
  ///
  /// Returns the health parameter document if it exists, null otherwise.
  /// Throws [SymptomServiceException] if Firestore operation fails.
  Future<HealthParameter?> getDailyHealth(
    String userId,
    String petId,
    DateTime date,
  ) async {
    try {
      final normalizedDate = AppDateUtils.startOfDay(date);
      final ref = _getHealthParameterRef(userId, petId, normalizedDate);
      final doc = await ref.get();

      if (!doc.exists) {
        return null;
      }

      return HealthParameter.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw SymptomServiceException(
        'Failed to fetch health parameter: ${e.message}',
      );
    }
  }

  /// Saves symptom data for a specific date
  ///
  /// Creates or updates the health parameter document and all related summaries
  /// (daily, weekly, monthly) in a single batch operation.
  ///
  /// Writes to:
  /// 1. healthParameters/{YYYY-MM-DD} - individual entry
  /// 2. treatmentSummaries/daily/summaries/{YYYY-MM-DD} - daily summary
  /// 3. treatmentSummaries/weekly/summaries/{YYYY-Www} - weekly summary
  /// 4. treatmentSummaries/monthly/summaries/{YYYY-MM} - monthly summary
  ///
  /// Throws:
  /// - [SymptomValidationException] if validation fails
  /// - [SymptomServiceException] if Firestore operation fails
  Future<void> saveSymptoms({
    required String userId,
    required String petId,
    required DateTime date,
    Map<String, int>? symptoms,
    String? notes,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[SymptomsService] Saving symptoms for date: $date',
        );
      }

      // 1. Validate inputs
      _validateSymptomScores(symptoms);
      _validateNotes(notes);

      // 2. Normalize date
      final normalizedDate = AppDateUtils.startOfDay(date);

      // 3. Create HealthParameter (automatically computes derived fields)
      final newEntry = HealthParameter.create(
        date: normalizedDate,
        symptoms: symptoms,
        notes: notes,
      );

      // 4. Fetch existing HealthParameter and DailySummary to compute deltas
      final existingHealthParam = await getDailyHealth(
        userId,
        petId,
        normalizedDate,
      );

      // If existing entry has weight/appetite, preserve them
      final finalEntry = existingHealthParam != null
          ? HealthParameter.create(
              date: normalizedDate,
              weight: existingHealthParam.weight,
              appetite: existingHealthParam.appetite,
              symptoms: symptoms,
              notes: notes ?? existingHealthParam.notes,
            )
          : newEntry;

      // Fetch existing daily summary
      final dailySummaryRef = _getDailySummaryRef(
        userId,
        petId,
        normalizedDate,
      );
      final dailySummaryDoc = await dailySummaryRef.get();
      DailySummary? oldDailySummary;
      if (dailySummaryDoc.exists) {
        try {
          final data = dailySummaryDoc.data();
          if (data != null) {
            oldDailySummary = DailySummary.fromJson(
              data as Map<String, dynamic>,
            );
          }
        } on Exception catch (e) {
          if (kDebugMode) {
            debugPrint(
              '[SymptomsService] Failed to parse existing daily summary: $e',
            );
          }
          // Continue with null oldDailySummary
        }
      }

      // Build new daily summary for delta computation
      final newDailySummary = DailySummary(
        date: normalizedDate,
        overallStreak: oldDailySummary?.overallStreak ?? 0,
        medicationTotalDoses: oldDailySummary?.medicationTotalDoses ?? 0,
        medicationScheduledDoses:
            oldDailySummary?.medicationScheduledDoses ?? 0,
        medicationMissedCount: oldDailySummary?.medicationMissedCount ?? 0,
        fluidTotalVolume: oldDailySummary?.fluidTotalVolume ?? 0.0,
        fluidTreatmentDone: oldDailySummary?.fluidTreatmentDone ?? false,
        fluidSessionCount: oldDailySummary?.fluidSessionCount ?? 0,
        fluidScheduledSessions: oldDailySummary?.fluidScheduledSessions ?? 0,
        overallTreatmentDone: oldDailySummary?.overallTreatmentDone ?? false,
        createdAt: oldDailySummary?.createdAt ?? DateTime.now(),
        fluidDailyGoalMl: oldDailySummary?.fluidDailyGoalMl,
        hadVomiting: (symptoms?[SymptomType.vomiting] ?? 0) > 0,
        hadDiarrhea: (symptoms?[SymptomType.diarrhea] ?? 0) > 0,
        hadConstipation: (symptoms?[SymptomType.constipation] ?? 0) > 0,
        hadLethargy: (symptoms?[SymptomType.lethargy] ?? 0) > 0,
        hadSuppressedAppetite:
            (symptoms?[SymptomType.suppressedAppetite] ?? 0) > 0,
        hadInjectionSiteReaction:
            (symptoms?[SymptomType.injectionSiteReaction] ?? 0) > 0,
        vomitingMaxScore: symptoms?[SymptomType.vomiting],
        diarrheaMaxScore: symptoms?[SymptomType.diarrhea],
        constipationMaxScore: symptoms?[SymptomType.constipation],
        lethargyMaxScore: symptoms?[SymptomType.lethargy],
        suppressedAppetiteMaxScore: symptoms?[SymptomType.suppressedAppetite],
        injectionSiteReactionMaxScore:
            symptoms?[SymptomType.injectionSiteReaction],
        symptomScoreTotal: finalEntry.symptomScoreTotal,
        symptomScoreAverage: finalEntry.symptomScoreAverage,
        hasSymptoms: finalEntry.hasSymptoms ?? false,
      );

      // 5. Fetch weekly and monthly summaries for max score computation
      final weeklySummaryRef = _getWeeklySummaryRef(
        userId,
        petId,
        normalizedDate,
      );
      final monthlySummaryRef = _getMonthlySummaryRef(
        userId,
        petId,
        normalizedDate,
      );

      final weeklySummaryDoc = await weeklySummaryRef.get();
      final monthlySummaryDoc = await monthlySummaryRef.get();

      // 6. Create WriteBatch
      final batch = _firestore.batch();

      // 7. Update healthParameters document
      final healthParamRef = _getHealthParameterRef(
        userId,
        petId,
        normalizedDate,
      );
      batch.set(
        healthParamRef,
        finalEntry.toJson(),
        SetOptions(merge: true),
      );

      // 8. Update daily summary
      final dailyUpdates = _buildDailySummaryUpdates(
        finalEntry,
        existingHealthParam,
        normalizedDate,
      );
      batch.set(
        dailySummaryRef,
        dailyUpdates,
        SetOptions(merge: true),
      );

      // 9. Update weekly summary
      final weeklyDeltas = _buildWeeklySummaryDeltas(
        oldDailySummary,
        newDailySummary,
      );

      // Add max score update if needed
      final newTotal = newDailySummary.symptomScoreTotal;
      if (newTotal != null) {
        final currentWeeklyData =
            weeklySummaryDoc.data() as Map<String, dynamic>?;
        final currentMax = currentWeeklyData?['symptomScoreMax'] as int?;
        if (currentMax == null || newTotal > currentMax) {
          weeklyDeltas['symptomScoreMax'] = newTotal;
        }
      }

      // Compute average (simple: total / days with symptoms)
      // For now, we'll set it from daily average (can be refined later)
      if (newDailySummary.symptomScoreAverage != null) {
        weeklyDeltas['symptomScoreAverage'] =
            newDailySummary.symptomScoreAverage;
      }

      // Add startDate/endDate if creating new weekly summary
      if (!weeklySummaryDoc.exists) {
        final weekDates = AppDateUtils.getWeekStartEnd(normalizedDate);
        weeklyDeltas['startDate'] = Timestamp.fromDate(weekDates['start']!);
        weeklyDeltas['endDate'] = Timestamp.fromDate(weekDates['end']!);
        weeklyDeltas['createdAt'] = FieldValue.serverTimestamp();
      }

      batch.set(
        weeklySummaryRef,
        weeklyDeltas,
        SetOptions(merge: true),
      );

      // 10. Update monthly summary
      final monthlyDeltas = _buildMonthlySummaryDeltas(
        oldDailySummary,
        newDailySummary,
      );

      // Read current monthly data once for reuse
      final currentMonthlyData =
          monthlySummaryDoc.data() as Map<String, dynamic>?;

      // Add max score update if needed
      if (newTotal != null) {
        final currentMax = currentMonthlyData?['symptomScoreMax'] as int?;
        if (currentMax == null || newTotal > currentMax) {
          monthlyDeltas['symptomScoreMax'] = newTotal;
        }
      }

      // Compute average
      if (newDailySummary.symptomScoreAverage != null) {
        monthlyDeltas['symptomScoreAverage'] =
            newDailySummary.symptomScoreAverage;
      }

      // Add startDate/endDate if creating new monthly summary OR if missing
      if (!monthlySummaryDoc.exists) {
        final monthDates = AppDateUtils.getMonthStartEnd(normalizedDate);
        monthlyDeltas['startDate'] = Timestamp.fromDate(monthDates['start']!);
        monthlyDeltas['endDate'] = Timestamp.fromDate(monthDates['end']!);
        monthlyDeltas['createdAt'] = FieldValue.serverTimestamp();
      } else if (currentMonthlyData?['startDate'] == null ||
          currentMonthlyData?['endDate'] == null) {
        // Document exists but missing date fields - set them
        final monthDates = AppDateUtils.getMonthStartEnd(normalizedDate);
        if (currentMonthlyData?['startDate'] == null) {
          monthlyDeltas['startDate'] = Timestamp.fromDate(monthDates['start']!);
        }
        if (currentMonthlyData?['endDate'] == null) {
          monthlyDeltas['endDate'] = Timestamp.fromDate(monthDates['end']!);
        }
        if (kDebugMode) {
          debugPrint(
            '[SymptomsService] Setting missing date fields in existing '
            'monthly summary',
          );
        }
      }

      batch.set(
        monthlySummaryRef,
        monthlyDeltas,
        SetOptions(merge: true),
      );

      // 11. Commit batch
      await batch.commit();

      if (kDebugMode) {
        debugPrint('[SymptomsService] Symptoms saved successfully');
      }

      // 12. Log analytics events
      final isNewEntry =
          existingHealthParam == null ||
          (existingHealthParam.hasSymptoms == null ||
              existingHealthParam.hasSymptoms == false);
      final symptomMap = finalEntry.symptoms;
      final symptomCount =
          symptomMap?.values.where((score) => score > 0).length ?? 0;
      final hasInjectionSiteReaction =
          symptomMap?[SymptomType.injectionSiteReaction] != null &&
          (symptomMap![SymptomType.injectionSiteReaction] ?? 0) > 0;

      final analyticsService = _analyticsService;
      if (analyticsService != null) {
        if (isNewEntry) {
          await analyticsService.trackFeatureUsed(
            featureName: 'symptoms_log_created',
            additionalParams: {
              'symptom_count': symptomCount,
              if (finalEntry.symptomScoreTotal != null)
                'total_score': finalEntry.symptomScoreTotal,
              'has_injection_site_reaction': hasInjectionSiteReaction,
            },
          );
        } else {
          await analyticsService.trackFeatureUsed(
            featureName: 'symptoms_log_updated',
            additionalParams: {
              'symptom_count': symptomCount,
              if (finalEntry.symptomScoreTotal != null)
                'total_score': finalEntry.symptomScoreTotal,
              'has_injection_site_reaction': hasInjectionSiteReaction,
            },
          );
        }
      }
    } on SymptomValidationException {
      rethrow;
    } on FirebaseException catch (e) {
      throw SymptomServiceException(
        'Failed to save symptoms: ${e.message}',
      );
    } catch (e) {
      throw SymptomServiceException('Unexpected error saving symptoms: $e');
    }
  }

  /// Clears symptom data for a specific date
  ///
  /// Sets all symptom fields to null while preserving other health parameter
  /// data. Updates all summaries accordingly (decrements counts, subtracts
  /// scores).
  ///
  /// Throws:
  /// - [SymptomServiceException] if Firestore operation fails
  Future<void> clearSymptoms(
    String userId,
    String petId,
    DateTime date,
  ) async {
    // Clear symptoms by setting them to null
    await saveSymptoms(
      userId: userId,
      petId: petId,
      date: date,
    );
  }

  /// Gets recent health parameters
  ///
  /// Returns up to [limit] health parameters ordered by date descending.
  /// If [symptomsOnly] is true, only returns entries with symptoms.
  ///
  /// Cost: Max [limit] reads per call (default 30, within CRUD rules).
  ///
  /// Throws:
  /// - [SymptomServiceException] if Firestore operation fails
  Future<List<HealthParameter>> getRecentHealth({
    required String userId,
    required String petId,
    int limit = 30,
    bool symptomsOnly = false,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .collection('healthParameters')
          .orderBy('date', descending: true)
          .limit(limit);

      if (symptomsOnly) {
        query = query.where('hasSymptoms', isEqualTo: true);
      }

      final snapshot = await query.get();

      return snapshot.docs.map(HealthParameter.fromFirestore).toList();
    } on FirebaseException catch (e) {
      throw SymptomServiceException(
        'Failed to fetch recent health parameters: ${e.message}',
      );
    }
  }
}
