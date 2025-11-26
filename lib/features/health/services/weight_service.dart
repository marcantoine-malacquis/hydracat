import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/health/exceptions/health_exceptions.dart';
import 'package:hydracat/features/health/models/health_parameter.dart';
import 'package:hydracat/features/health/models/weight_data_point.dart';
import 'package:hydracat/features/profile/services/profile_validation_service.dart';
import 'package:intl/intl.dart';

/// Result class for weight history queries with pagination support
class WeightHistoryResult {
  /// Creates a [WeightHistoryResult]
  const WeightHistoryResult({
    required this.entries,
    this.lastDocument,
  });

  /// List of weight entries
  final List<HealthParameter> entries;

  /// Firestore document snapshot for pagination cursor
  final DocumentSnapshot? lastDocument;
}

/// Internal helper class for latest weight information
class _LatestWeightInfo {
  /// Creates a [_LatestWeightInfo]
  const _LatestWeightInfo({
    required this.weight,
    required this.date,
  });

  /// Weight value in kg
  final double weight;

  /// Date of the weight entry
  final DateTime date;
}

/// Service for weight tracking operations
///
/// Handles CRUD operations for weight entries with:
/// - Batch writes to healthParameters and monthly summaries
/// - Validation using ProfileValidationService
/// - Cost-optimized queries
/// - Cache invalidation
class WeightService {
  /// Creates a [WeightService] instance
  WeightService({
    FirebaseFirestore? firestore,
    ProfileValidationService? validationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _validationService =
           validationService ?? const ProfileValidationService();

  final FirebaseFirestore _firestore;
  final ProfileValidationService _validationService;

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

  /// Gets monthly summary document reference
  ///
  /// Path: users/{userId}/pets/{petId}/treatmentSummaries/monthly/summaries/{YYYY-MM}
  DocumentReference _getMonthlySummaryRef(
    String userId,
    String petId,
    DateTime date,
  ) {
    final docId = DateFormat('yyyy-MM').format(date);
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

  /// Gets pet document reference
  ///
  /// Path: users/{userId}/pets/{petId}
  DocumentReference _getPetRef(
    String userId,
    String petId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId);
  }

  // ============================================
  // VALIDATION
  // ============================================

  /// Validates weight value
  ///
  /// Uses ProfileValidationService to ensure weight is within valid range.
  /// Throws [WeightValidationException] if validation fails.
  void _validateWeight(double weightKg) {
    final result = _validationService.validateWeight(weightKg);
    if (!result.isValid) {
      final errorMessages = result.errors.map((e) => e.message).join(', ');
      throw WeightValidationException(errorMessages);
    }
  }

  /// Validates notes length
  ///
  /// Ensures notes do not exceed 500 character limit.
  /// Throws [WeightValidationException] if notes are too long.
  void _validateNotes(String? notes) {
    if (notes != null && notes.length > 500) {
      throw const WeightValidationException(
        'Notes must be 500 characters or less',
      );
    }
  }

  // ============================================
  // HELPER: Calculate Weight Trend
  // ============================================

  /// Calculates trend from weight change
  ///
  /// Returns:
  /// - "increasing" if change > 0.1 kg
  /// - "decreasing" if change < -0.1 kg
  /// - "stable" otherwise
  String _calculateTrend(double change) {
    if (change > 0.1) return 'increasing';
    if (change < -0.1) return 'decreasing';
    return 'stable';
  }

  // ============================================
  // HELPER: Find Latest Weights
  // ============================================

  /// Finds the latest weight entry in a specific month
  ///
  /// Returns the most recent weight and its date for the given month,
  /// optionally excluding a specific date (useful when updating/deleting).
  Future<_LatestWeightInfo?> _findLatestWeightInMonth({
    required String userId,
    required String petId,
    required DateTime monthDate,
    DateTime? excludeDate,
  }) async {
    final monthStart = DateTime(monthDate.year, monthDate.month);
    final monthEnd = DateTime(monthDate.year, monthDate.month + 1);

    final query = _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('healthParameters')
        .where('hasWeight', isEqualTo: true)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .where('date', isLessThan: Timestamp.fromDate(monthEnd))
        .orderBy('date', descending: true)
        .limit(10); // Get a few to handle exclusion

    final snapshot = await query.get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final normalizedDate = AppDateUtils.startOfDay(date);

      // Skip excluded date if specified
      if (excludeDate != null &&
          AppDateUtils.isSameDay(normalizedDate, excludeDate)) {
        continue;
      }

      final weight = (data['weight'] as num).toDouble();
      return _LatestWeightInfo(weight: weight, date: normalizedDate);
    }

    return null;
  }

  /// Finds the globally latest weight entry across all time
  ///
  /// Returns the most recent weight value across all health parameters,
  /// optionally excluding a specific date (useful when updating/deleting).
  Future<_LatestWeightInfo?> _findGlobalLatestWeight({
    required String userId,
    required String petId,
    DateTime? excludeDate,
  }) async {
    final query = _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('healthParameters')
        .where('hasWeight', isEqualTo: true)
        .orderBy('date', descending: true)
        .limit(10); // Get a few to handle exclusion

    final snapshot = await query.get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final normalizedDate = AppDateUtils.startOfDay(date);

      // Skip excluded date if specified
      if (excludeDate != null &&
          AppDateUtils.isSameDay(normalizedDate, excludeDate)) {
        continue;
      }

      final weight = (data['weight'] as num).toDouble();
      return _LatestWeightInfo(weight: weight, date: normalizedDate);
    }

    return null;
  }

  /// Helper to update monthly summary for new/updated weight entry
  ///
  /// Checks if the date is actually the latest before updating latest fields.
  Future<void> _updateNewMonthSummary({
    required WriteBatch batch,
    required String userId,
    required String petId,
    required DateTime normalizedNewDate,
    required double newWeightKg,
    required bool isSameMonth,
    required bool isSameDate,
  }) async {
    final newMonthlySummaryRef = _getMonthlySummaryRef(
      userId,
      petId,
      normalizedNewDate,
    );
    final currentSummaryDoc = await newMonthlySummaryRef.get();
    final currentData = currentSummaryDoc.data() as Map<String, dynamic>?;

    // Check if this is the latest weight in the month
    final currentLatestDate =
        currentSummaryDoc.exists &&
            currentData != null &&
            currentData['weightLatestDate'] != null
        ? (currentData['weightLatestDate'] as Timestamp).toDate()
        : null;
    final isLatestInMonth =
        currentLatestDate == null ||
        !normalizedNewDate.isBefore(currentLatestDate);

    if (kDebugMode) {
      debugPrint(
        '[WeightService] New month date comparison: '
        'normalizedNewDate=$normalizedNewDate, '
        'currentLatestDate=$currentLatestDate, '
        'isLatestInMonth=$isLatestInMonth',
      );
    }

    final newSummaryUpdates = <String, dynamic>{
      if (!isSameMonth || !isSameDate)
        'weightEntriesCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Only update latest weight fields if this is the most recent date
    if (isLatestInMonth) {
      final previousWeight =
          currentSummaryDoc.exists &&
              currentData != null &&
              currentData['weightLatest'] != null
          ? (currentData['weightLatest'] as num).toDouble()
          : null;

      final weightChange = previousWeight != null
          ? newWeightKg - previousWeight
          : 0.0;
      final weightChangePercent = previousWeight != null
          ? ((newWeightKg - previousWeight) / previousWeight) * 100
          : 0.0;

      newSummaryUpdates['weightLatest'] = newWeightKg;
      newSummaryUpdates['weightLatestDate'] = Timestamp.fromDate(
        normalizedNewDate,
      );
      newSummaryUpdates['weightChange'] = weightChange;
      newSummaryUpdates['weightChangePercent'] = weightChangePercent;
      newSummaryUpdates['weightTrend'] = _calculateTrend(weightChange);

      if (kDebugMode) {
        debugPrint(
          '[WeightService] Updating latest weight in new monthly summary',
        );
      }
    } else {
      if (kDebugMode) {
        debugPrint(
          '[WeightService] Not updating latest weight '
          '(entry is not most recent in month)',
        );
      }
    }

    // Set startDate and endDate if they don't exist (needed for graph queries)
    if (!currentSummaryDoc.exists) {
      // New document - set both dates
      final monthDates = AppDateUtils.getMonthStartEnd(normalizedNewDate);
      newSummaryUpdates['startDate'] = Timestamp.fromDate(monthDates['start']!);
      newSummaryUpdates['endDate'] = Timestamp.fromDate(monthDates['end']!);
    } else {
      // Existing document - backfill missing dates
      if (currentData?['startDate'] == null ||
          currentData?['endDate'] == null) {
        final monthDates = AppDateUtils.getMonthStartEnd(normalizedNewDate);
        if (currentData?['startDate'] == null) {
          newSummaryUpdates['startDate'] =
              Timestamp.fromDate(monthDates['start']!);
        }
        if (currentData?['endDate'] == null) {
          newSummaryUpdates['endDate'] =
              Timestamp.fromDate(monthDates['end']!);
        }
      }
    }

    batch.set(
      newMonthlySummaryRef,
      newSummaryUpdates,
      SetOptions(merge: true),
    );
  }

  // ============================================
  // CRUD OPERATIONS
  // ============================================

  /// Logs a new weight entry
  ///
  /// Writes to:
  /// 1. healthParameters/{YYYY-MM-DD} - individual entry
  /// 2. treatmentSummaries/monthly/summaries/{YYYY-MM} - monthly summary
  /// 3. pets/{petId} - updates CatProfile.weightKg
  ///
  /// Throws:
  /// - [WeightValidationException] if validation fails
  /// - [WeightServiceException] if Firestore operation fails
  Future<void> logWeight({
    required String userId,
    required String petId,
    required DateTime date,
    required double weightKg,
    String? notes,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[WeightService] Logging weight: ${weightKg}kg on $date',
        );
      }

      // Validate inputs
      _validateWeight(weightKg);
      _validateNotes(notes);

      final normalizedDate = AppDateUtils.startOfDay(date);
      final batch = _firestore.batch();

      // 1. Write health parameter
      final healthParamRef = _getHealthParameterRef(
        userId,
        petId,
        normalizedDate,
      );
      batch.set(
        healthParamRef,
        {
          'weight': weightKg,
          'hasWeight': true,
          if (notes != null) 'notes': notes,
          'date': Timestamp.fromDate(normalizedDate),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 2. Update monthly summary
      final monthlySummaryRef = _getMonthlySummaryRef(
        userId,
        petId,
        normalizedDate,
      );

      // Fetch current summary to calculate deltas
      final currentSummaryDoc = await monthlySummaryRef.get();
      final currentData = currentSummaryDoc.data() as Map<String, dynamic>?;
      final hasExistingData =
          currentSummaryDoc.exists && currentData?['weightLatest'] != null;

      if (kDebugMode) {
        debugPrint('[WeightService] Monthly summary state:');
        debugPrint('  - Document exists: ${currentSummaryDoc.exists}');
        debugPrint('  - Has weight data: $hasExistingData');
        debugPrint('  - Current data: $currentData');
      }

      // Check if this is the latest weight in the month
      final currentLatestDate =
          hasExistingData && currentData!['weightLatestDate'] != null
          ? (currentData['weightLatestDate'] as Timestamp).toDate()
          : null;
      final isLatestInMonth =
          currentLatestDate == null ||
          !normalizedDate.isBefore(currentLatestDate);

      if (kDebugMode) {
        debugPrint(
          '[WeightService] Date comparison: '
          'normalizedDate=$normalizedDate, '
          'currentLatestDate=$currentLatestDate, '
          'isLatestInMonth=$isLatestInMonth',
        );
      }

      final summaryUpdates = <String, dynamic>{
        'weightEntriesCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only update latest weight fields if this is the most recent date
      if (isLatestInMonth) {
        final previousWeight = hasExistingData
            ? (currentData!['weightLatest'] as num).toDouble()
            : null;

        final weightChange = previousWeight != null
            ? weightKg - previousWeight
            : 0.0;
        final weightChangePercent = previousWeight != null
            ? ((weightKg - previousWeight) / previousWeight) * 100
            : 0.0;

        summaryUpdates['weightLatest'] = weightKg;
        summaryUpdates['weightLatestDate'] = Timestamp.fromDate(normalizedDate);
        summaryUpdates['weightChange'] = weightChange;
        summaryUpdates['weightChangePercent'] = weightChangePercent;
        summaryUpdates['weightTrend'] = _calculateTrend(weightChange);

        if (kDebugMode) {
          debugPrint(
            '[WeightService] Updating latest weight in monthly summary',
          );
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            '[WeightService] Not updating latest weight '
            '(entry is not most recent in month)',
          );
        }
      }

      // Set first weight of month if not exists
      if (!hasExistingData || currentData!['weightFirst'] == null) {
        summaryUpdates['weightFirst'] = weightKg;
        summaryUpdates['weightFirstDate'] = Timestamp.fromDate(normalizedDate);
      }

      // Set startDate if it doesn't exist (needed for graph queries)
      if (!currentSummaryDoc.exists || currentData?['startDate'] == null) {
        final monthStart = DateTime(normalizedDate.year, normalizedDate.month);
        summaryUpdates['startDate'] = Timestamp.fromDate(monthStart);
        if (kDebugMode) {
          debugPrint(
            '[WeightService] Setting startDate for monthly summary: '
            '$monthStart',
          );
        }
      }

      if (kDebugMode) {
        debugPrint(
          '[WeightService] Updating monthly summary: '
          '${DateFormat('yyyy-MM').format(normalizedDate)}'
          ' with data: $summaryUpdates',
        );
      }

      batch.set(monthlySummaryRef, summaryUpdates, SetOptions(merge: true));

      // 3. Update pet profile with latest weight (only if globally latest)
      // First commit the health parameter so it's included in the query
      await batch.commit();

      // Query for the actual global latest weight
      final globalLatest = await _findGlobalLatestWeight(
        userId: userId,
        petId: petId,
      );

      if (globalLatest != null) {
        final petRef = _getPetRef(userId, petId);
        await petRef.update({
          'weightKg': globalLatest.weight,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) {
          debugPrint(
            '[WeightService] Updated pet profile with global latest: '
            '${globalLatest.weight}kg',
          );
        }
      }

      if (kDebugMode) {
        debugPrint('[WeightService] Weight logged successfully');
      }
    } on WeightValidationException {
      rethrow;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightService] Firebase error: ${e.message}');
      }
      throw WeightServiceException('Failed to log weight: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightService] Unexpected error: $e');
      }
      throw WeightServiceException('Failed to log weight: $e');
    }
  }

  /// Updates an existing weight entry
  ///
  /// Recalculates monthly summary based on deltas.
  /// Also updates CatProfile.weightKg if this is the most recent entry.
  ///
  /// Throws:
  /// - [WeightValidationException] if validation fails
  /// - [WeightServiceException] if Firestore operation fails
  Future<void> updateWeight({
    required String userId,
    required String petId,
    required DateTime oldDate,
    required double oldWeightKg,
    required DateTime newDate,
    required double newWeightKg,
    String? newNotes,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[WeightService] Updating weight from '
          '${oldWeightKg}kg to ${newWeightKg}kg',
        );
      }

      // Validate new inputs
      _validateWeight(newWeightKg);
      _validateNotes(newNotes);

      final normalizedOldDate = AppDateUtils.startOfDay(oldDate);
      final normalizedNewDate = AppDateUtils.startOfDay(newDate);
      final isSameDate = normalizedOldDate.isAtSameMomentAs(normalizedNewDate);
      final isSameMonth =
          normalizedOldDate.year == normalizedNewDate.year &&
          normalizedOldDate.month == normalizedNewDate.month;

      final batch = _firestore.batch();

      // 1. If date changed, delete old entry and handle old month summary
      if (!isSameDate) {
        final oldHealthParamRef = _getHealthParameterRef(
          userId,
          petId,
          normalizedOldDate,
        );
        batch.delete(oldHealthParamRef);

        // Handle old month's summary if different month
        if (!isSameMonth) {
          final oldMonthlySummaryRef = _getMonthlySummaryRef(
            userId,
            petId,
            normalizedOldDate,
          );

          // Commit batch so deleted entry is not included in queries
          await batch.commit();

          // Check if old entry was the latest in its month
          final oldSummaryDoc = await oldMonthlySummaryRef.get();
          final oldSummaryData = oldSummaryDoc.data() as Map<String, dynamic>?;

          if (oldSummaryDoc.exists &&
              oldSummaryData != null &&
              oldSummaryData['weightLatestDate'] != null) {
            final oldLatestDate =
                (oldSummaryData['weightLatestDate'] as Timestamp).toDate();

            if (AppDateUtils.isSameDay(oldLatestDate, normalizedOldDate)) {
              // Old entry was the latest, find new latest for old month
              final newLatestInOldMonth = await _findLatestWeightInMonth(
                userId: userId,
                petId: petId,
                monthDate: normalizedOldDate,
              );

              if (newLatestInOldMonth != null) {
                // Update old month with new latest
                await oldMonthlySummaryRef.update({
                  'weightLatest': newLatestInOldMonth.weight,
                  'weightLatestDate': Timestamp.fromDate(
                    newLatestInOldMonth.date,
                  ),
                  'weightEntriesCount': FieldValue.increment(-1),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (kDebugMode) {
                  debugPrint(
                    '[WeightService] Updated old month with new latest: '
                    '${newLatestInOldMonth.weight}kg',
                  );
                }
              } else {
                // No more entries in old month, just decrement count
                await oldMonthlySummaryRef.update({
                  'weightEntriesCount': FieldValue.increment(-1),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              }
            } else {
              // Old entry was not the latest, just decrement count
              await oldMonthlySummaryRef.update({
                'weightEntriesCount': FieldValue.increment(-1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }

          // Create new batch for remaining operations
          final newBatch = _firestore.batch();

          // 2. Write/update new entry
          final newHealthParamRef = _getHealthParameterRef(
            userId,
            petId,
            normalizedNewDate,
          );
          newBatch.set(
            newHealthParamRef,
            {
              'weight': newWeightKg,
              'hasWeight': true,
              if (newNotes != null) 'notes': newNotes,
              'date': Timestamp.fromDate(normalizedNewDate),
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          // Continue with new batch
          await _updateNewMonthSummary(
            batch: newBatch,
            userId: userId,
            petId: petId,
            normalizedNewDate: normalizedNewDate,
            newWeightKg: newWeightKg,
            isSameMonth: isSameMonth,
            isSameDate: isSameDate,
          );

          await newBatch.commit();
        } else {
          // Same month, different date - no need to commit early
          // Just continue with the batch
          final newHealthParamRef = _getHealthParameterRef(
            userId,
            petId,
            normalizedNewDate,
          );
          batch.set(
            newHealthParamRef,
            {
              'weight': newWeightKg,
              'hasWeight': true,
              if (newNotes != null) 'notes': newNotes,
              'date': Timestamp.fromDate(normalizedNewDate),
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          await _updateNewMonthSummary(
            batch: batch,
            userId: userId,
            petId: petId,
            normalizedNewDate: normalizedNewDate,
            newWeightKg: newWeightKg,
            isSameMonth: isSameMonth,
            isSameDate: isSameDate,
          );

          await batch.commit();
        }
      } else {
        // Same date, just update in place
        final newHealthParamRef = _getHealthParameterRef(
          userId,
          petId,
          normalizedNewDate,
        );
        batch.set(
          newHealthParamRef,
          {
            'weight': newWeightKg,
            'hasWeight': true,
            if (newNotes != null) 'notes': newNotes,
            'date': Timestamp.fromDate(normalizedNewDate),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await _updateNewMonthSummary(
          batch: batch,
          userId: userId,
          petId: petId,
          normalizedNewDate: normalizedNewDate,
          newWeightKg: newWeightKg,
          isSameMonth: isSameMonth,
          isSameDate: isSameDate,
        );

        await batch.commit();
      }

      // Query for the actual global latest weight to update pet profile
      final globalLatest = await _findGlobalLatestWeight(
        userId: userId,
        petId: petId,
      );

      if (globalLatest != null) {
        final petRef = _getPetRef(userId, petId);
        await petRef.update({
          'weightKg': globalLatest.weight,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) {
          debugPrint(
            '[WeightService] Updated pet profile with global latest: '
            '${globalLatest.weight}kg',
          );
        }
      }

      if (kDebugMode) {
        debugPrint('[WeightService] Weight updated successfully');
      }
    } on WeightValidationException {
      rethrow;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightService] Firebase error: ${e.message}');
      }
      throw WeightServiceException(
        'Failed to update weight: ${e.message}',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightService] Unexpected error: $e');
      }
      throw WeightServiceException('Failed to update weight: $e');
    }
  }

  /// Deletes a weight entry
  ///
  /// Updates monthly summary count and CatProfile if needed.
  ///
  /// Throws:
  /// - [WeightServiceException] if Firestore operation fails
  Future<void> deleteWeight({
    required String userId,
    required String petId,
    required DateTime date,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('[WeightService] Deleting weight for $date');
      }

      final normalizedDate = AppDateUtils.startOfDay(date);
      final batch = _firestore.batch();

      // 1. Delete health parameter
      final healthParamRef = _getHealthParameterRef(
        userId,
        petId,
        normalizedDate,
      );
      batch.delete(healthParamRef);

      // 2. Check monthly summary before deletion
      final monthlySummaryRef = _getMonthlySummaryRef(
        userId,
        petId,
        normalizedDate,
      );
      final monthlySummaryDoc = await monthlySummaryRef.get();
      final monthlySummaryData =
          monthlySummaryDoc.data() as Map<String, dynamic>?;

      // Check if deleted entry was the latest in its month
      final wasLatestInMonth =
          monthlySummaryDoc.exists &&
          monthlySummaryData != null &&
          monthlySummaryData['weightLatestDate'] != null &&
          AppDateUtils.isSameDay(
            (monthlySummaryData['weightLatestDate'] as Timestamp).toDate(),
            normalizedDate,
          );

      if (kDebugMode) {
        debugPrint(
          '[WeightService] Deleted entry was latest in month: '
          '$wasLatestInMonth',
        );
      }

      // Commit deletion first so it's excluded from queries
      await batch.commit();

      // 3. Update monthly summary
      if (wasLatestInMonth) {
        // Find new latest for the month
        final newLatestInMonth = await _findLatestWeightInMonth(
          userId: userId,
          petId: petId,
          monthDate: normalizedDate,
        );

        if (newLatestInMonth != null) {
          // Update with new latest
          await monthlySummaryRef.update({
            'weightLatest': newLatestInMonth.weight,
            'weightLatestDate': Timestamp.fromDate(newLatestInMonth.date),
            'weightEntriesCount': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (kDebugMode) {
            debugPrint(
              '[WeightService] Updated monthly summary with new latest: '
              '${newLatestInMonth.weight}kg on ${newLatestInMonth.date}',
            );
          }
        } else {
          // No more entries in month, just decrement count
          await monthlySummaryRef.update({
            'weightEntriesCount': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (kDebugMode) {
            debugPrint(
              '[WeightService] No more entries in month after deletion',
            );
          }
        }
      } else {
        // Not the latest, just decrement count
        await monthlySummaryRef.update({
          'weightEntriesCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 4. Update CatProfile.weightKg to most recent remaining entry
      final globalLatest = await _findGlobalLatestWeight(
        userId: userId,
        petId: petId,
      );

      final petRef = _getPetRef(userId, petId);
      if (globalLatest != null) {
        await petRef.update({
          'weightKg': globalLatest.weight,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) {
          debugPrint(
            '[WeightService] Updated pet profile with global latest: '
            '${globalLatest.weight}kg',
          );
        }
      } else {
        // No more weight entries, set to null
        await petRef.update({
          'weightKg': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) {
          debugPrint(
            '[WeightService] No more weight entries, cleared pet profile',
          );
        }
      }

      if (kDebugMode) {
        debugPrint('[WeightService] Weight deleted successfully');
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightService] Firebase error: ${e.message}');
      }
      throw WeightServiceException('Failed to delete weight: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightService] Unexpected error: $e');
      }
      throw WeightServiceException('Failed to delete weight: $e');
    }
  }

  /// Gets paginated weight history
  ///
  /// Returns up to [limit] entries, optionally starting after [startAfterDoc].
  /// Filters for documents with hasWeight flag set to true.
  /// Returns [WeightHistoryResult] containing entries and pagination cursor.
  Future<WeightHistoryResult> getWeightHistory({
    required String userId,
    required String petId,
    DocumentSnapshot? startAfterDoc,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .collection('healthParameters')
          .where('hasWeight', isEqualTo: true)
          .orderBy('date', descending: true)
          .limit(limit);

      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }

      final snapshot = await query.get();
      final entries = snapshot.docs.map(HealthParameter.fromFirestore).toList();

      // Return both entries AND the last document for pagination
      return WeightHistoryResult(
        entries: entries,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[WeightService] Failed to fetch weight history: ${e.message}',
        );
      }
      throw WeightServiceException(
        'Failed to fetch weight history: ${e.message}',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightService] Unexpected error: $e');
      }
      throw WeightServiceException('Failed to fetch weight history: $e');
    }
  }

  /// Gets weight graph data from monthly summaries
  ///
  /// Returns data points for the last [months] months that have weight data.
  /// Uses monthly summaries for optimal performance.
  Future<List<WeightDataPoint>> getWeightGraphData({
    required String userId,
    required String petId,
    int months = 12,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[WeightService] Fetching graph data for last $months months',
        );
      }

      final query = _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .collection('treatmentSummaries')
          .doc('monthly')
          .collection('summaries')
          .where('weightEntriesCount', isGreaterThan: 0)
          .orderBy('weightEntriesCount')
          .orderBy('startDate', descending: true)
          .limit(months);

      final snapshot = await query.get();

      if (kDebugMode) {
        debugPrint(
          '[WeightService] Graph query returned '
          '${snapshot.docs.length} documents',
        );
        for (final doc in snapshot.docs) {
          debugPrint(
            '[WeightService] Doc ID: ${doc.id}, data: ${doc.data()}',
          );
        }
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final weightLatest = (data['weightLatest'] as num).toDouble();
        final weightLatestDate = (data['weightLatestDate'] as Timestamp)
            .toDate();

        return WeightDataPoint(
          date: weightLatestDate,
          weightKg: weightLatest,
        );
      }).toList();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[WeightService] Failed to fetch graph data: ${e.message}',
        );
      }
      throw WeightServiceException(
        'Failed to fetch graph data: ${e.message}',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightService] Unexpected error: $e');
      }
      throw WeightServiceException('Failed to fetch graph data: $e');
    }
  }

  /// Gets weight graph data for a specific week
  ///
  /// Returns daily weight data points for 7-day period (Monday to Sunday).
  /// Uses hasWeight filter for efficient querying (only days with weight data).
  /// Cost: ≤7 reads per week
  Future<List<WeightDataPoint>> getWeightGraphDataWeek({
    required String userId,
    required String petId,
    required DateTime weekStart,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[WeightService] Fetching week graph data starting $weekStart',
        );
      }

      final weekEnd = weekStart.add(const Duration(days: 7));

      final query = _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .collection('healthParameters')
          .where('hasWeight', isEqualTo: true)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('date', isLessThan: Timestamp.fromDate(weekEnd))
          .orderBy('date');

      final snapshot = await query.get();

      if (kDebugMode) {
        debugPrint(
          '[WeightService] Week query returned '
          '${snapshot.docs.length} documents',
        );
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final weightKg = (data['weight'] as num).toDouble();
        final date = (data['date'] as Timestamp).toDate();

        return WeightDataPoint(
          date: date,
          weightKg: weightKg,
        );
      }).toList();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[WeightService] Failed to fetch week data: ${e.message}',
        );
      }
      throw WeightServiceException(
        'Failed to fetch week data: ${e.message}',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightService] Unexpected error: $e');
      }
      throw WeightServiceException('Failed to fetch week data: $e');
    }
  }

  /// Gets weight graph data for a specific month
  ///
  /// Returns daily weight data points for calendar month.
  /// Uses hasWeight filter for efficient querying (only days with weight data).
  /// Cost: ≤31 reads per month
  Future<List<WeightDataPoint>> getWeightGraphDataMonth({
    required String userId,
    required String petId,
    required DateTime monthStart,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[WeightService] Fetching month graph data for '
          '${DateFormat('yyyy-MM').format(monthStart)}',
        );
      }

      final monthEnd = DateTime(monthStart.year, monthStart.month + 1);

      final query = _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .collection('healthParameters')
          .where('hasWeight', isEqualTo: true)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('date', isLessThan: Timestamp.fromDate(monthEnd))
          .orderBy('date');

      final snapshot = await query.get();

      if (kDebugMode) {
        debugPrint(
          '[WeightService] Month query returned '
          '${snapshot.docs.length} documents',
        );
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final weightKg = (data['weight'] as num).toDouble();
        final date = (data['date'] as Timestamp).toDate();

        return WeightDataPoint(
          date: date,
          weightKg: weightKg,
        );
      }).toList();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[WeightService] Failed to fetch month data: ${e.message}',
        );
      }
      throw WeightServiceException(
        'Failed to fetch month data: ${e.message}',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightService] Unexpected error: $e');
      }
      throw WeightServiceException('Failed to fetch month data: $e');
    }
  }

  /// Gets latest weight from most recent monthly summary
  ///
  /// Checks current month first, falls back to previous month.
  /// Returns null if no weight data exists.
  Future<double?> getLatestWeight({
    required String userId,
    required String petId,
  }) async {
    try {
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

      final currentMonthRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .collection('treatmentSummaries')
          .doc('monthly')
          .collection('summaries')
          .doc(currentMonth);

      final doc = await currentMonthRef.get();

      if (doc.exists && doc.data()?['weightLatest'] != null) {
        return (doc.data()!['weightLatest'] as num).toDouble();
      }

      // Fallback to previous month
      final previousMonth = DateFormat('yyyy-MM').format(
        DateTime.now().subtract(const Duration(days: 31)),
      );

      final prevDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .collection('treatmentSummaries')
          .doc('monthly')
          .collection('summaries')
          .doc(previousMonth)
          .get();

      if (prevDoc.exists && prevDoc.data()?['weightLatest'] != null) {
        return (prevDoc.data()!['weightLatest'] as num).toDouble();
      }

      return null;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[WeightService] Failed to fetch latest weight: ${e.message}',
        );
      }
      throw WeightServiceException(
        'Failed to fetch latest weight: ${e.message}',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightService] Unexpected error: $e');
      }
      throw WeightServiceException('Failed to fetch latest weight: $e');
    }
  }
}
