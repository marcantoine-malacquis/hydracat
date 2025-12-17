import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/qol/models/qol_domain.dart';
import 'package:hydracat/features/qol/models/qol_question.dart';
import 'package:hydracat/features/qol/models/qol_response.dart';
import 'package:uuid/uuid.dart';

/// Sentinel value for nullable fields in copyWith.
const _undefined = Object();

/// Represents a complete Quality of Life assessment for a cat.
///
/// Contains responses to all 14 QoL questions, with computed domain and
/// overall scores. Uses semantic scaling where higher scores = better QoL.
@immutable
class QolAssessment {
  /// Creates a QoL assessment.
  const QolAssessment({
    required this.id,
    required this.userId,
    required this.petId,
    required this.date,
    required this.responses,
    required this.createdAt,
    this.updatedAt,
    this.completionDurationSeconds,
  });

  /// Creates an empty assessment for a given user, pet, and date.
  factory QolAssessment.empty({
    required String userId,
    required String petId,
    DateTime? date,
  }) {
    final assessmentDate = date ?? DateTime.now();
    final normalizedDate = AppDateUtils.startOfDay(assessmentDate);

    return QolAssessment(
      id: const Uuid().v4(),
      userId: userId,
      petId: petId,
      date: normalizedDate,
      responses: const [],
      createdAt: DateTime.now(),
    );
  }

  /// Creates a QoL assessment from Firestore JSON.
  factory QolAssessment.fromJson(Map<String, dynamic> json) {
    final responsesList = json['responses'] as List<dynamic>? ?? [];

    return QolAssessment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      petId: json['petId'] as String,
      date: (json['date'] as Timestamp).toDate(),
      responses: responsesList
          .map((r) => QolResponse.fromJson(r as Map<String, dynamic>))
          .toList(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      completionDurationSeconds: json['completionDurationSeconds'] as int?,
    );
  }

  /// Unique identifier (UUID v4).
  final String id;

  /// User who owns this assessment.
  final String userId;

  /// Pet this assessment is for.
  final String petId;

  /// Date of assessment (normalized to midnight).
  final DateTime date;

  /// List of responses to QoL questions.
  final List<QolResponse> responses;

  /// When this assessment was created.
  final DateTime createdAt;

  /// When this assessment was last updated (null if never edited).
  final DateTime? updatedAt;

  /// Time taken to complete (seconds), null if edited.
  final int? completionDurationSeconds;

  // Computed Getters

  /// Document ID for Firestore (YYYY-MM-DD format).
  String get documentId => AppDateUtils.formatDateForSummary(date);

  /// Whether this assessment is for today.
  bool get isToday => AppDateUtils.isToday(date);

  /// Whether all 14 questions have been answered.
  bool get isComplete => answeredCount == 14;

  /// Number of questions answered (non-null scores).
  int get answeredCount =>
      responses.where((r) => r.isAnswered).length;

  /// Number of questions not answered.
  int get unansweredCount => 14 - answeredCount;

  /// Count of answered questions per domain.
  Map<String, int> get answeredCountByDomain {
    final counts = <String, int>{};

    for (final domain in QolDomain.all) {
      final answeredInDomain = responses.where((r) {
        final question = QolQuestion.getById(r.questionId);
        return question?.domain == domain && r.isAnswered;
      }).length;

      counts[domain] = answeredInDomain;
    }

    return counts;
  }

  // Domain Scoring Methods

  /// Calculates score for a specific domain (0-100 scale).
  ///
  /// Returns null if less than 50% of domain questions are answered
  /// (low confidence). All questions use semantic scaling where
  /// higher score = better QoL (no reverse scoring needed).
  double? getDomainScore(String domain) {
    if (!QolDomain.isValid(domain)) return null;

    final domainQuestions = QolQuestion.getByDomain(domain);
    final totalQuestions = domainQuestions.length;

    // Get answered responses for this domain
    final domainResponses = responses.where((r) {
      final question = QolQuestion.getById(r.questionId);
      return question?.domain == domain && r.isAnswered;
    }).toList();

    final answeredCount = domainResponses.length;

    // Require at least 50% answered for confidence
    if (answeredCount < (totalQuestions * 0.5)) {
      return null;
    }

    // Calculate mean of answered scores (0-4 scale)
    final sum = domainResponses.fold<int>(
      0,
      (sum, r) => sum + (r.score ?? 0),
    );
    final mean = sum / answeredCount;

    // Convert to 0-100 scale
    return (mean / 4.0) * 100.0;
  }

  /// Returns scores for all 5 domains.
  ///
  /// Map keys are domain IDs, values are scores (0-100) or null
  /// if insufficient data.
  Map<String, double?> get domainScores {
    return {
      for (final domain in QolDomain.all) domain: getDomainScore(domain),
    };
  }

  /// Overall QoL score (0-100 scale).
  ///
  /// Returns null if any domain has low confidence (missing score).
  /// Calculated as mean of all 5 domain scores.
  double? get overallScore {
    final scores = domainScores;

    // Check if any domain is null (low confidence)
    if (scores.values.any((score) => score == null)) {
      return null;
    }

    // Calculate mean of valid domain scores
    final validScores = scores.values.whereType<double>().toList();
    if (validScores.isEmpty) return null;

    final sum = validScores.reduce((a, b) => a + b);
    return sum / validScores.length;
  }

  /// Score band classification based on overall score.
  ///
  /// Returns:
  /// - 'veryGood': ≥80
  /// - 'good': ≥60
  /// - 'fair': ≥40
  /// - 'low': <40
  /// - null: insufficient data
  String? get scoreBand {
    final score = overallScore;
    if (score == null) return null;

    if (score >= 80) return 'veryGood';
    if (score >= 60) return 'good';
    if (score >= 40) return 'fair';
    return 'low';
  }

  /// Whether any domain has low confidence (<50% answered).
  bool get hasLowConfidenceDomain {
    return domainScores.values.any((score) => score == null);
  }

  // Validation

  /// Validates this assessment and returns list of error messages.
  ///
  /// Returns empty list if valid.
  List<String> validate() {
    final errors = <String>[];

    // Date not in future
    if (date.isAfter(DateTime.now())) {
      errors.add('Assessment date cannot be in the future');
    }

    // Check all scores are valid (0-4 or null)
    for (final response in responses) {
      if (response.score != null) {
        if (response.score! < 0 || response.score! > 4) {
          errors.add(
            'Invalid score ${response.score} for '
            'question ${response.questionId}',
          );
        }
      }
    }

    // Check all question IDs are valid
    for (final response in responses) {
      if (QolQuestion.getById(response.questionId) == null) {
        errors.add('Invalid question ID: ${response.questionId}');
      }
    }

    // Check for duplicate question IDs
    final questionIds = responses.map((r) => r.questionId).toList();
    final uniqueIds = questionIds.toSet();
    if (questionIds.length != uniqueIds.length) {
      errors.add('Duplicate question responses found');
    }

    return errors;
  }

  // Serialization

  /// Converts this assessment to JSON for Firestore storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'petId': petId,
      'date': Timestamp.fromDate(date),
      'responses': responses.map((r) => r.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (completionDurationSeconds != null)
        'completionDurationSeconds': completionDurationSeconds,
    };
  }

  /// Creates a copy of this assessment with updated fields.
  ///
  /// Uses sentinel pattern to distinguish between "not provided" and
  /// "explicitly set to null" for nullable fields.
  QolAssessment copyWith({
    String? id,
    String? userId,
    String? petId,
    DateTime? date,
    List<QolResponse>? responses,
    DateTime? createdAt,
    Object? updatedAt = _undefined,
    Object? completionDurationSeconds = _undefined,
  }) {
    return QolAssessment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      date: date ?? this.date,
      responses: responses ?? this.responses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt == _undefined
          ? this.updatedAt
          : updatedAt as DateTime?,
      completionDurationSeconds:
          completionDurationSeconds == _undefined
              ? this.completionDurationSeconds
              : completionDurationSeconds as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QolAssessment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          petId == other.petId &&
          date == other.date &&
          listEquals(responses, other.responses) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          completionDurationSeconds == other.completionDurationSeconds;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      petId.hashCode ^
      date.hashCode ^
      Object.hashAll(responses) ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      completionDurationSeconds.hashCode;

  @override
  String toString() => 'QolAssessment('
      'id: $id, '
      'documentId: $documentId, '
      'date: $date, '
      'answeredCount: $answeredCount, '
      'overallScore: $overallScore'
      ')';
}
