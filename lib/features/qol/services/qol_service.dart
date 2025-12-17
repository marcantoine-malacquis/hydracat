import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/qol/exceptions/qol_exceptions.dart';
import 'package:hydracat/features/qol/models/qol_assessment.dart';
import 'package:hydracat/features/qol/models/qol_domain.dart';
import 'package:hydracat/providers/analytics_provider.dart';

/// Service for Quality of Life assessment operations.
///
/// Handles CRUD operations for QoL assessments with:
/// - Batch writes to qolAssessments and daily/weekly/monthly summaries
/// - Denormalized scores in summaries for zero-read home screen
/// - Cost-optimized queries with pagination
/// - Analytics tracking
class QolService {
  /// Creates a [QolService] instance.
  QolService({
    FirebaseFirestore? firestore,
    AnalyticsService? analyticsService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _analyticsService = analyticsService;

  final FirebaseFirestore _firestore;
  final AnalyticsService? _analyticsService;

  // ============================================
  // PRIVATE HELPERS - Firestore Paths
  // ============================================

  /// Gets QoL assessment document reference.
  ///
  /// Path: users/{userId}/pets/{petId}/qolAssessments/{YYYY-MM-DD}
  DocumentReference _getQolAssessmentRef(
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
        .collection('qolAssessments')
        .doc(docId);
  }

  /// Gets daily summary document reference.
  ///
  /// Path: users/{userId}/pets/{petId}/treatmentSummaries/daily/summaries/
  /// {YYYY-MM-DD}
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

  /// Gets weekly summary document reference.
  ///
  /// Path: users/{userId}/pets/{petId}/treatmentSummaries/weekly/summaries/
  /// {YYYY-Www}
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

  /// Gets monthly summary document reference.
  ///
  /// Path: users/{userId}/pets/{petId}/treatmentSummaries/monthly/summaries/
  /// {YYYY-MM}
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

  /// Validates a QoL assessment and throws [QolValidationException] if invalid.
  void _validateAssessment(QolAssessment assessment) {
    final errors = assessment.validate();
    if (errors.isNotEmpty) {
      throw QolValidationException(errors.join(', '));
    }
  }

  // ============================================
  // CRUD OPERATIONS
  // ============================================

  /// Saves a QoL assessment with batch write to 4 documents.
  ///
  /// Updates:
  /// 1. qolAssessments/{YYYY-MM-DD} - full assessment document
  /// 2. daily summary - denormalized scores + hasQolAssessment flag
  /// 3. weekly summary - updatedAt timestamp (future aggregation)
  /// 4. monthly summary - updatedAt timestamp (future aggregation)
  ///
  /// Throws [QolValidationException] if assessment is invalid.
  /// Throws [QolServiceException] if Firestore operation fails.
  ///
  /// Example:
  /// ```dart
  /// await qolService.saveAssessment(assessment);
  /// ```
  Future<void> saveAssessment(QolAssessment assessment) async {
    try {
      // Validate assessment
      _validateAssessment(assessment);

      // Create batch
      final batch = _firestore.batch();

      // 1. Write assessment document
      final assessmentRef = _getQolAssessmentRef(
        assessment.userId,
        assessment.petId,
        assessment.date,
      );

      batch.set(assessmentRef, assessment.toJson());

      // 2. Update daily summary with denormalized scores
      final dailyRef = _getDailySummaryRef(
        assessment.userId,
        assessment.petId,
        assessment.date,
      );

      final domainScores = assessment.domainScores;

      batch.set(
        dailyRef,
        {
          'qolOverallScore': assessment.overallScore,
          'qolVitalityScore': domainScores[QolDomain.vitality],
          'qolComfortScore': domainScores[QolDomain.comfort],
          'qolEmotionalScore': domainScores[QolDomain.emotional],
          'qolAppetiteScore': domainScores[QolDomain.appetite],
          'qolTreatmentBurdenScore': domainScores[QolDomain.treatmentBurden],
          'hasQolAssessment': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 3. Update weekly summary (placeholder for future aggregation)
      final weeklyRef = _getWeeklySummaryRef(
        assessment.userId,
        assessment.petId,
        assessment.date,
      );

      batch.set(
        weeklyRef,
        {
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 4. Update monthly summary (placeholder for future aggregation)
      final monthlyRef = _getMonthlySummaryRef(
        assessment.userId,
        assessment.petId,
        assessment.date,
      );

      batch.set(
        monthlyRef,
        {
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Commit batch
      await batch.commit();

      // Track analytics
      await _trackAssessmentCompleted(assessment);
    } on QolValidationException {
      rethrow;
    } catch (e) {
      throw QolServiceException('Failed to save QoL assessment: $e');
    }
  }

  /// Gets a QoL assessment for a specific date.
  ///
  /// Returns null if no assessment exists for the given date.
  ///
  /// Throws [QolServiceException] if Firestore operation fails.
  ///
  /// Example:
  /// ```dart
  /// final assessment = await qolService.getAssessment(
  ///   userId,
  ///   petId,
  ///   DateTime(2025, 1, 15),
  /// );
  /// ```
  Future<QolAssessment?> getAssessment(
    String userId,
    String petId,
    DateTime date,
  ) async {
    try {
      final ref = _getQolAssessmentRef(userId, petId, date);
      final doc = await ref.get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return QolAssessment.fromJson(doc.data()! as Map<String, dynamic>);
    } catch (e) {
      throw QolServiceException('Failed to get QoL assessment: $e');
    }
  }

  /// Gets recent QoL assessments with pagination.
  ///
  /// Returns assessments ordered by date descending (most recent first).
  /// Use [limit] to control page size (default 20 for cost optimization).
  /// Use [startAfter] for pagination to get next page.
  ///
  /// Throws [QolServiceException] if Firestore operation fails.
  ///
  /// Example:
  /// ```dart
  /// // First page
  /// final assessments = await qolService.getRecentAssessments(
  ///   userId,
  ///   petId,
  ///   limit: 20,
  /// );
  ///
  /// // Next page
  /// final nextPage = await qolService.getRecentAssessments(
  ///   userId,
  ///   petId,
  ///   limit: 20,
  ///   startAfter: assessments.last.date,
  /// );
  /// ```
  Future<List<QolAssessment>> getRecentAssessments(
    String userId,
    String petId, {
    int limit = 20,
    DateTime? startAfter,
  }) async {
    try {
      var query = _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .collection('qolAssessments')
          .orderBy('date', descending: true)
          .limit(limit);

      // Apply pagination if startAfter provided
      if (startAfter != null) {
        query = query.startAfter([Timestamp.fromDate(startAfter)]);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => QolAssessment.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw QolServiceException('Failed to get recent QoL assessments: $e');
    }
  }

  /// Watches the latest QoL assessment for real-time updates.
  ///
  /// Returns a stream of the most recent assessment or null if none exist.
  /// Stream emits new values whenever the latest assessment changes.
  ///
  /// Note: Use sparingly - each stream is a real-time listener (cost $).
  /// Prefer cached data from provider for most UI needs.
  ///
  /// Example:
  /// ```dart
  /// final stream = qolService.watchLatestAssessment(userId, petId);
  /// stream.listen((assessment) {
  ///   if (assessment != null) {
  ///     print('Latest score: ${assessment.overallScore}');
  ///   }
  /// });
  /// ```
  Stream<QolAssessment?> watchLatestAssessment(
    String userId,
    String petId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('qolAssessments')
        .orderBy('date', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      return QolAssessment.fromJson(snapshot.docs.first.data());
    });
  }

  /// Updates an existing QoL assessment.
  ///
  /// Sets updatedAt to current time and completionDurationSeconds to null
  /// (edited assessments lose their duration).
  ///
  /// Updates denormalized scores in daily summary to match.
  ///
  /// Throws [QolValidationException] if assessment is invalid.
  /// Throws [QolServiceException] if Firestore operation fails.
  ///
  /// Example:
  /// ```dart
  /// final updated = assessment.copyWith(responses: newResponses);
  /// await qolService.updateAssessment(updated);
  /// ```
  Future<void> updateAssessment(QolAssessment assessment) async {
    try {
      // Validate assessment
      _validateAssessment(assessment);

      // Create updated assessment with metadata
      final updatedAssessment = assessment.copyWith(
        updatedAt: DateTime.now(),
        completionDurationSeconds: null, // Edited assessments lose duration
      );

      // Create batch
      final batch = _firestore.batch();

      // Update assessment document
      final assessmentRef = _getQolAssessmentRef(
        updatedAssessment.userId,
        updatedAssessment.petId,
        updatedAssessment.date,
      );

      batch.set(assessmentRef, updatedAssessment.toJson());

      // Update daily summary with new scores
      final dailyRef = _getDailySummaryRef(
        updatedAssessment.userId,
        updatedAssessment.petId,
        updatedAssessment.date,
      );

      final domainScores = updatedAssessment.domainScores;

      batch.set(
        dailyRef,
        {
          'qolOverallScore': updatedAssessment.overallScore,
          'qolVitalityScore': domainScores[QolDomain.vitality],
          'qolComfortScore': domainScores[QolDomain.comfort],
          'qolEmotionalScore': domainScores[QolDomain.emotional],
          'qolAppetiteScore': domainScores[QolDomain.appetite],
          'qolTreatmentBurdenScore': domainScores[QolDomain.treatmentBurden],
          'hasQolAssessment': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Commit batch
      await batch.commit();

      // Track analytics
      await _trackAssessmentUpdated(updatedAssessment);
    } on QolValidationException {
      rethrow;
    } catch (e) {
      throw QolServiceException('Failed to update QoL assessment: $e');
    }
  }

  /// Deletes a QoL assessment.
  ///
  /// Removes assessment document and clears QoL fields in daily summary.
  /// Sets hasQolAssessment to false and all scores to null.
  ///
  /// Throws [QolServiceException] if Firestore operation fails.
  ///
  /// Example:
  /// ```dart
  /// await qolService.deleteAssessment(
  ///   userId,
  ///   petId,
  ///   DateTime(2025, 1, 15),
  /// );
  /// ```
  Future<void> deleteAssessment(
    String userId,
    String petId,
    DateTime date,
  ) async {
    try {
      // Create batch
      final batch = _firestore.batch();

      // Delete assessment document
      final assessmentRef = _getQolAssessmentRef(userId, petId, date);
      batch.delete(assessmentRef);

      // Clear QoL fields in daily summary
      final dailyRef = _getDailySummaryRef(userId, petId, date);

      batch.set(
        dailyRef,
        {
          'qolOverallScore': null,
          'qolVitalityScore': null,
          'qolComfortScore': null,
          'qolEmotionalScore': null,
          'qolAppetiteScore': null,
          'qolTreatmentBurdenScore': null,
          'hasQolAssessment': false,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Commit batch
      await batch.commit();

      // Track analytics
      await _trackAssessmentDeleted(AppDateUtils.formatDateForSummary(date));
    } catch (e) {
      throw QolServiceException('Failed to delete QoL assessment: $e');
    }
  }

  // ============================================
  // ANALYTICS INTEGRATION
  // ============================================

  /// Tracks assessment completion event.
  Future<void> _trackAssessmentCompleted(QolAssessment assessment) async {
    if (_analyticsService == null) return;

    // TODO(analytics): Add trackQolAssessmentCompleted method to
    // AnalyticsService
    // Parameters: overall_score, completion_duration_seconds,
    // answered_count, has_low_confidence_domain
    // See: .cursor/reference/analytics_list.md
  }

  /// Tracks assessment update event.
  Future<void> _trackAssessmentUpdated(QolAssessment assessment) async {
    if (_analyticsService == null) return;

    // TODO(analytics): Add trackQolAssessmentUpdated method to AnalyticsService
    // Parameters: assessment_date
    // See: .cursor/reference/analytics_list.md
  }

  /// Tracks assessment deletion event.
  Future<void> _trackAssessmentDeleted(String date) async {
    if (_analyticsService == null) return;

    // TODO(analytics): Add trackQolAssessmentDeleted method to AnalyticsService
    // Parameters: assessment_date
    // See: .cursor/reference/analytics_list.md
  }
}
