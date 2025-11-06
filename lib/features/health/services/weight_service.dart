import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/health/exceptions/health_exceptions.dart';
import 'package:hydracat/features/health/models/health_parameter.dart';
import 'package:hydracat/features/health/models/weight_data_point.dart';
import 'package:hydracat/features/profile/services/profile_validation_service.dart';
import 'package:intl/intl.dart';

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
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
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
      final healthParamRef =
          _getHealthParameterRef(userId, petId, normalizedDate);
      batch.set(
        healthParamRef,
        {
          'weight': weightKg,
          if (notes != null) 'notes': notes,
          'date': Timestamp.fromDate(normalizedDate),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 2. Update monthly summary
      final monthlySummaryRef =
          _getMonthlySummaryRef(userId, petId, normalizedDate);

      // Fetch current summary to calculate deltas
      final currentSummaryDoc = await monthlySummaryRef.get();
      final currentData = currentSummaryDoc.data() as Map<String, dynamic>?;
      final hasExistingData =
          currentSummaryDoc.exists && currentData?['weightLatest'] != null;

      final previousWeight = hasExistingData
          ? (currentData!['weightLatest'] as num).toDouble()
          : null;

      final weightChange =
          previousWeight != null ? weightKg - previousWeight : 0.0;
      final weightChangePercent = previousWeight != null
          ? ((weightKg - previousWeight) / previousWeight) * 100
          : 0.0;

      final summaryUpdates = <String, dynamic>{
        'weightEntriesCount': FieldValue.increment(1),
        'weightLatest': weightKg,
        'weightLatestDate': Timestamp.fromDate(normalizedDate),
        'weightChange': weightChange,
        'weightChangePercent': weightChangePercent,
        'weightTrend': _calculateTrend(weightChange),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Set first weight of month if not exists
      if (!hasExistingData || currentData!['weightFirst'] == null) {
        summaryUpdates['weightFirst'] = weightKg;
        summaryUpdates['weightFirstDate'] = Timestamp.fromDate(normalizedDate);
      }

      batch.set(monthlySummaryRef, summaryUpdates, SetOptions(merge: true));

      // 3. Update pet profile with latest weight
      final petRef = _getPetRef(userId, petId);
      batch.update(petRef, {
        'weightKg': weightKg,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit batch
      await batch.commit();

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
      final isSameDate =
          normalizedOldDate.isAtSameMomentAs(normalizedNewDate);
      final isSameMonth = normalizedOldDate.year == normalizedNewDate.year &&
          normalizedOldDate.month == normalizedNewDate.month;

      final batch = _firestore.batch();

      // 1. If date changed, delete old entry
      if (!isSameDate) {
        final oldHealthParamRef =
            _getHealthParameterRef(userId, petId, normalizedOldDate);
        batch.delete(oldHealthParamRef);

        // Decrement old month's count if different month
        if (!isSameMonth) {
          final oldMonthlySummaryRef =
              _getMonthlySummaryRef(userId, petId, normalizedOldDate);
          batch.update(oldMonthlySummaryRef, {
            'weightEntriesCount': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // 2. Write/update new entry
      final newHealthParamRef =
          _getHealthParameterRef(userId, petId, normalizedNewDate);
      batch.set(
        newHealthParamRef,
        {
          'weight': newWeightKg,
          if (newNotes != null) 'notes': newNotes,
          'date': Timestamp.fromDate(normalizedNewDate),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 3. Update monthly summary for new date
      final newMonthlySummaryRef =
          _getMonthlySummaryRef(userId, petId, normalizedNewDate);
      final currentSummaryDoc = await newMonthlySummaryRef.get();
      final currentData = currentSummaryDoc.data() as Map<String, dynamic>?;

      final previousWeight = currentSummaryDoc.exists &&
              currentData != null &&
              currentData['weightLatest'] != null
          ? (currentData['weightLatest'] as num).toDouble()
          : null;

      final weightChange =
          previousWeight != null ? newWeightKg - previousWeight : 0.0;
      final weightChangePercent = previousWeight != null
          ? ((newWeightKg - previousWeight) / previousWeight) * 100
          : 0.0;

      batch.set(
        newMonthlySummaryRef,
        {
          if (!isSameMonth || !isSameDate)
            'weightEntriesCount': FieldValue.increment(1),
          'weightLatest': newWeightKg,
          'weightLatestDate': Timestamp.fromDate(normalizedNewDate),
          'weightChange': weightChange,
          'weightChangePercent': weightChangePercent,
          'weightTrend': _calculateTrend(weightChange),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 4. Update pet profile with latest weight
      // (always update to newest entry)
      final petRef = _getPetRef(userId, petId);
      batch.update(petRef, {
        'weightKg': newWeightKg,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit batch
      await batch.commit();

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
      final healthParamRef =
          _getHealthParameterRef(userId, petId, normalizedDate);
      batch.delete(healthParamRef);

      // 2. Decrement monthly summary count
      final monthlySummaryRef =
          _getMonthlySummaryRef(userId, petId, normalizedDate);
      batch.update(monthlySummaryRef, {
        'weightEntriesCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update CatProfile.weightKg to most recent remaining entry
      // Query for most recent weight (excluding the one being deleted)
      final recentWeightQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .collection('healthParameters')
          .where('weight', isNotEqualTo: null)
          .orderBy('weight')
          .orderBy('date', descending: true)
          .limit(2) // Get 2 to find next most recent
          .get();

      // Find the most recent entry that's not the one being deleted
      double? newLatestWeight;
      for (final doc in recentWeightQuery.docs) {
        final docDate = (doc.data()['date'] as Timestamp).toDate();
        if (!AppDateUtils.isSameDay(docDate, normalizedDate)) {
          newLatestWeight = (doc.data()['weight'] as num).toDouble();
          break;
        }
      }

      final petRef = _getPetRef(userId, petId);
      if (newLatestWeight != null) {
        batch.update(petRef, {
          'weightKg': newLatestWeight,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // No more weight entries, set to null
        batch.update(petRef, {
          'weightKg': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Commit batch
      await batch.commit();

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
  /// Filters for documents with non-null weight values only.
  Future<List<HealthParameter>> getWeightHistory({
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
          .where('weight', isNotEqualTo: null)
          .orderBy('weight')
          .orderBy('date', descending: true)
          .limit(limit);

      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map(HealthParameter.fromFirestore).toList();
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

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final weightLatest = (data['weightLatest'] as num).toDouble();
        final weightLatestDate =
            (data['weightLatestDate'] as Timestamp).toDate();

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
