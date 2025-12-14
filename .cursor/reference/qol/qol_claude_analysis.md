# HydraCAT Quality of Life Tracking - Implementation Analysis

**Author:** Claude (Senior App Developer & Project Manager)
**Date:** December 14, 2024
**Status:** Implementation Specification
**Version:** 1.0

---

## Executive Summary

This document provides a comprehensive analysis for implementing the HydraCAT Quality of Life (QoL) tracking system within the existing HydraCat application architecture. The proposed implementation leverages existing patterns, follows established best practices, aligns with UI guidelines, and optimizes Firebase operations to minimize costs while providing a scientifically grounded, user-friendly QoL tracking experience.

**Key Findings:**
- ✅ The codebase has excellent existing patterns that map directly to QoL requirements
- ✅ Symptom tracking feature provides a near-perfect implementation template
- ✅ Daily/weekly/monthly summary infrastructure is already established and reusable
- ✅ Chart visualization libraries (fl_chart) and patterns are mature and proven
- ✅ State management (Riverpod), Firebase service patterns, and UI components are well-established
- ✅ No new dependencies required - all necessary libraries already present
- 💡 Opportunity to create a generalized "assessment framework" for future health questionnaires
- 📊 Latest QoL radar chart will be displayed on the home screen for quick visibility

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Data Model Design](#2-data-model-design)
3. [Firebase Schema & Cost Optimization](#3-firebase-schema--cost-optimization)
4. [Service Layer Implementation](#4-service-layer-implementation)
5. [State Management Strategy](#5-state-management-strategy)
6. [UI/UX Implementation](#6-uiux-implementation)
7. [Home Screen Integration](#7-home-screen-integration)
8. [Navigation Integration](#8-navigation-integration)
9. [Analytics Integration](#9-analytics-integration)
10. [Localization Requirements](#10-localization-requirements)
11. [Testing Strategy](#11-testing-strategy)
12. [Implementation Roadmap](#12-implementation-roadmap)
13. [Future Considerations](#13-future-considerations)

---

## 1. Architecture Overview

### 1.1 Feature Structure

Following the established domain-driven design pattern, the QoL feature will be organized as:

```
lib/features/qol/
├── models/
│   ├── qol_assessment.dart              # Main assessment model
│   ├── qol_response.dart                # Individual question response
│   ├── qol_domain.dart                  # Domain enumeration & metadata
│   ├── qol_question.dart                # Question model with metadata
│   └── qol_trend_summary.dart           # Computed trend data point
├── services/
│   ├── qol_service.dart                 # Firebase CRUD operations
│   └── qol_scoring_service.dart         # Scoring & trend calculations
├── screens/
│   ├── qol_questionnaire_screen.dart    # Assessment entry
│   ├── qol_history_screen.dart          # Historical assessments list
│   └── qol_detail_screen.dart           # Single assessment detail view
├── widgets/
│   ├── qol_question_card.dart           # Single question UI
│   ├── qol_radar_chart.dart             # 5-domain radar chart (reusable)
│   ├── qol_trend_line_chart.dart        # Historical trend visualization
│   ├── qol_score_summary_card.dart      # Current score display
│   └── qol_interpretation_card.dart     # Trend interpretation messages
└── exceptions/
    └── qol_exceptions.dart              # Feature-specific exceptions
```

**Rationale:** This structure mirrors the proven `features/health/` pattern (symptom tracking) and maintains consistency with the codebase's domain-driven architecture.

### 1.2 Integration Points

**Existing Systems to Leverage:**
- ✅ `lib/shared/models/treatment_summary_base.dart` - Base class for summaries
- ✅ `lib/core/utils/date_utils.dart` - Date normalization and formatting
- ✅ `lib/shared/widgets/charts/` - Chart utilities and tooltip positioning
- ✅ `lib/providers/analytics_provider.dart` - Analytics integration
- ✅ `lib/shared/widgets/` - HydraCard, HydraButton, HydraAppBar, etc.
- ✅ `lib/core/theme/` - Complete design system (colors, spacing, typography, shadows)
- ✅ `fl_chart: ^1.1.1` - Already present for radar and line charts

**No New Dependencies Required** - All necessary libraries already available in the codebase.

---

## 2. Data Model Design

### 2.1 QoL Domain Enumeration

**File:** `lib/features/qol/models/qol_domain.dart`

```dart
import 'package:flutter/foundation.dart';

/// QoL assessment domains
///
/// Five equally-weighted domains as defined in the scientific basis:
/// 1. Vitality - Observable energy and engagement
/// 2. Comfort - Physical comfort, mobility, litterbox use
/// 3. Emotional - Affect and social behaviors
/// 4. Appetite - Interest in food and enjoyment
/// 5. Treatment Burden - Stress from medications/fluids
@immutable
class QolDomain {
  const QolDomain._();

  /// Domain keys (used in Firestore and analytics)
  static const String vitality = 'vitality';
  static const String comfort = 'comfort';
  static const String emotional = 'emotional';
  static const String appetite = 'appetite';
  static const String treatmentBurden = 'treatmentBurden';

  /// All domain keys in canonical order
  static const List<String> all = [
    vitality,
    comfort,
    emotional,
    appetite,
    treatmentBurden,
  ];

  /// Domain display names (localized keys)
  static const Map<String, String> displayKeys = {
    vitality: 'qolDomainVitality',
    comfort: 'qolDomainComfort',
    emotional: 'qolDomainEmotional',
    appetite: 'qolDomainAppetite',
    treatmentBurden: 'qolDomainTreatmentBurden',
  };

  /// Domain descriptions (localized keys)
  static const Map<String, String> descriptionKeys = {
    vitality: 'qolDomainVitalityDesc',
    comfort: 'qolDomainComfortDesc',
    emotional: 'qolDomainEmotionalDesc',
    appetite: 'qolDomainAppetiteDesc',
    treatmentBurden: 'qolDomainTreatmentBurdenDesc',
  };

  /// Number of questions per domain
  static const Map<String, int> questionCounts = {
    vitality: 3,
    comfort: 3,
    emotional: 3,
    appetite: 3,
    treatmentBurden: 2,
  };

  /// Validates domain key
  static bool isValid(String domain) => all.contains(domain);
}
```

**Rationale:** Follows the same pattern as `SymptomType` class - centralized constants with metadata.

### 2.2 QoL Question Model

**File:** `lib/features/qol/models/qol_question.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:hydracat/features/qol/models/qol_domain.dart';

/// Represents a single QoL question with metadata
///
/// Questions are immutable and defined at compile-time.
/// Localization keys are used for internationalization support.
@immutable
class QolQuestion {
  const QolQuestion({
    required this.id,
    required this.domain,
    required this.textKey,
    required this.order,
    this.isReverseScored = false,
  });

  /// Unique question identifier (e.g., 'vitality_1', 'comfort_2')
  final String id;

  /// Domain this question belongs to
  final String domain;

  /// Localization key for question text
  /// Example: 'qolQuestionVitality1'
  final String textKey;

  /// Display order within questionnaire (0-13)
  final int order;

  /// Whether this question is reverse-scored
  ///
  /// Reverse-scored questions describe negative experiences
  /// (e.g., "How stressed does your cat seem?")
  /// UI should always imply right = better (handled in logic layer)
  final bool isReverseScored;

  /// All 14 questions in canonical order
  static const List<QolQuestion> all = [
    // Vitality (3 questions)
    QolQuestion(
      id: 'vitality_1',
      domain: QolDomain.vitality,
      textKey: 'qolQuestionVitality1',
      order: 0,
    ),
    QolQuestion(
      id: 'vitality_2',
      domain: QolDomain.vitality,
      textKey: 'qolQuestionVitality2',
      order: 1,
    ),
    QolQuestion(
      id: 'vitality_3',
      domain: QolDomain.vitality,
      textKey: 'qolQuestionVitality3',
      order: 2,
    ),

    // Comfort (3 questions)
    QolQuestion(
      id: 'comfort_1',
      domain: QolDomain.comfort,
      textKey: 'qolQuestionComfort1',
      order: 3,
    ),
    QolQuestion(
      id: 'comfort_2',
      domain: QolDomain.comfort,
      textKey: 'qolQuestionComfort2',
      order: 4,
    ),
    QolQuestion(
      id: 'comfort_3',
      domain: QolDomain.comfort,
      textKey: 'qolQuestionComfort3',
      order: 5,
    ),

    // Emotional (3 questions)
    QolQuestion(
      id: 'emotional_1',
      domain: QolDomain.emotional,
      textKey: 'qolQuestionEmotional1',
      order: 6,
    ),
    QolQuestion(
      id: 'emotional_2',
      domain: QolDomain.emotional,
      textKey: 'qolQuestionEmotional2',
      order: 7,
    ),
    QolQuestion(
      id: 'emotional_3',
      domain: QolDomain.emotional,
      textKey: 'qolQuestionEmotional3',
      order: 8,
    ),

    // Appetite (3 questions)
    QolQuestion(
      id: 'appetite_1',
      domain: QolDomain.appetite,
      textKey: 'qolQuestionAppetite1',
      order: 9,
    ),
    QolQuestion(
      id: 'appetite_2',
      domain: QolDomain.appetite,
      textKey: 'qolQuestionAppetite2',
      order: 10,
    ),
    QolQuestion(
      id: 'appetite_3',
      domain: QolDomain.appetite,
      textKey: 'qolQuestionAppetite3',
      order: 11,
    ),

    // Treatment Burden (2 questions)
    QolQuestion(
      id: 'treatment_1',
      domain: QolDomain.treatmentBurden,
      textKey: 'qolQuestionTreatment1',
      order: 12,
      isReverseScored: true, // "How stressed does your cat seem?"
    ),
    QolQuestion(
      id: 'treatment_2',
      domain: QolDomain.treatmentBurden,
      textKey: 'qolQuestionTreatment2',
      order: 13,
      isReverseScored: true, // "How much does your cat resist?"
    ),
  ];

  /// Get question by ID
  static QolQuestion? getById(String id) {
    try {
      return all.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get questions by domain
  static List<QolQuestion> getByDomain(String domain) {
    return all.where((q) => q.domain == domain).toList();
  }
}
```

**Rationale:** Compile-time definition ensures type safety and prevents runtime configuration errors. Mirrors the established pattern from symptom tracking.

### 2.3 QoL Response Model

**File:** `lib/features/qol/models/qol_response.dart`

```dart
import 'package:flutter/foundation.dart';

/// Represents a user's response to a single QoL question
///
/// Score is nullable to support "Not sure / Unable to observe" responses.
/// Null responses are excluded from domain score calculations.
@immutable
class QolResponse {
  const QolResponse({
    required this.questionId,
    required this.score,
  });

  /// Factory constructor from JSON
  factory QolResponse.fromJson(Map<String, dynamic> json) {
    return QolResponse(
      questionId: json['questionId'] as String,
      score: json['score'] as int?,
    );
  }

  /// Question ID this response is for
  final String questionId;

  /// User's score (0-4) or null if "not sure"
  ///
  /// Scale:
  /// - 4: Always / Very much / As usual or better
  /// - 3: Often
  /// - 2: Sometimes
  /// - 1: Rarely
  /// - 0: Never / Much worse than usual
  /// - null: Not sure / Unable to observe
  final int? score;

  /// Whether this response was answered (not "not sure")
  bool get isAnswered => score != null;

  /// Converts to JSON for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'score': score,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QolResponse &&
          other.questionId == questionId &&
          other.score == score;

  @override
  int get hashCode => Object.hash(questionId, score);

  @override
  String toString() => 'QolResponse(questionId: $questionId, score: $score)';
}
```

**Rationale:** Simple, immutable data structure following existing model patterns (e.g., `SymptomEntry`).

### 2.4 QoL Assessment Model

**File:** `lib/features/qol/models/qol_assessment.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/qol/models/qol_domain.dart';
import 'package:hydracat/features/qol/models/qol_question.dart';
import 'package:hydracat/features/qol/models/qol_response.dart';
import 'package:uuid/uuid.dart';

/// Sentinel value for copyWith to distinguish "not provided" from "set to null"
const _undefined = Object();

/// Represents a completed QoL assessment with computed scores
///
/// Document ID format: YYYY-MM-DD (e.g., "2025-12-14")
/// Path: users/{userId}/pets/{petId}/qolAssessments/{YYYY-MM-DD}
///
/// Scoring:
/// - Domain score = mean of answered items in that domain
/// - Overall score = mean of 5 domain scores
/// - Scores are 0-100 scale (internal 0-4 scale × 25)
/// - Higher score = better QoL
@immutable
class QolAssessment {
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

  /// Creates an empty assessment for a given date
  factory QolAssessment.empty({
    required String userId,
    required String petId,
    required DateTime date,
  }) {
    return QolAssessment(
      id: const Uuid().v4(),
      userId: userId,
      petId: petId,
      date: AppDateUtils.normalizeToMidnight(date),
      responses: const [],
      createdAt: DateTime.now(),
    );
  }

  /// Factory constructor from Firestore JSON
  factory QolAssessment.fromJson(Map<String, dynamic> json) {
    final responses = (json['responses'] as List<dynamic>?)
            ?.map((r) => QolResponse.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return QolAssessment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      petId: json['petId'] as String,
      date: _parseDateTime(json['date']),
      responses: responses,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updatedAt']),
      completionDurationSeconds:
          (json['completionDurationSeconds'] as num?)?.toInt(),
    );
  }

  /// Unique assessment ID (UUID v4)
  final String id;

  /// User ID who owns this assessment
  final String userId;

  /// Pet ID this assessment is for
  final String petId;

  /// Assessment date (normalized to midnight)
  final DateTime date;

  /// List of question responses
  final List<QolResponse> responses;

  /// When assessment was created
  final DateTime createdAt;

  /// When assessment was last updated
  final DateTime? updatedAt;

  /// Time taken to complete (in seconds)
  /// Used for analytics and UX improvements
  final int? completionDurationSeconds;

  /// Document ID for Firestore (YYYY-MM-DD format)
  String get documentId => AppDateUtils.formatDateForSummary(date);

  /// Whether assessment is for today
  bool get isToday => AppDateUtils.isToday(date);

  /// Whether assessment is complete (all 14 questions answered)
  bool get isComplete => answeredCount == QolQuestion.all.length;

  /// Number of answered questions
  int get answeredCount => responses.where((r) => r.isAnswered).length;

  /// Number of unanswered questions
  int get unansweredCount => QolQuestion.all.length - answeredCount;

  /// Answered question count by domain
  Map<String, int> get answeredCountByDomain {
    final counts = <String, int>{};
    for (final domain in QolDomain.all) {
      final domainQuestions = QolQuestion.getByDomain(domain);
      final domainResponses = responses.where(
        (r) =>
            domainQuestions.any((q) => q.id == r.questionId) && r.isAnswered,
      );
      counts[domain] = domainResponses.length;
    }
    return counts;
  }

  /// Computes domain score (0-100 scale)
  ///
  /// Returns null if less than 50% of domain questions are answered
  /// (low confidence threshold as per spec)
  double? getDomainScore(String domain) {
    final domainQuestions = QolQuestion.getByDomain(domain);
    final domainResponses = responses.where(
      (r) => domainQuestions.any((q) => q.id == r.questionId) && r.isAnswered,
    );

    if (domainResponses.isEmpty) return null;

    // Low confidence if <50% answered
    if (domainResponses.length < domainQuestions.length * 0.5) {
      return null;
    }

    // Calculate mean of answered items (handling reverse scoring)
    var sum = 0.0;
    for (final response in domainResponses) {
      final question = QolQuestion.getById(response.questionId);
      if (question == null) continue;

      var score = response.score!.toDouble();
      // Reverse scoring: 4→0, 3→1, 2→2, 1→3, 0→4
      if (question.isReverseScored) {
        score = 4.0 - score;
      }
      sum += score;
    }

    final mean = sum / domainResponses.length;
    // Convert 0-4 scale to 0-100 scale
    return (mean / 4.0) * 100.0;
  }

  /// Computes all domain scores
  Map<String, double?> get domainScores {
    return {
      for (final domain in QolDomain.all) domain: getDomainScore(domain),
    };
  }

  /// Computes overall QoL score (0-100 scale)
  ///
  /// Returns null if any domain has low confidence (<50% answered)
  double? get overallScore {
    final scores = domainScores.values.whereType<double>().toList();
    if (scores.length != QolDomain.all.length) return null;

    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Score band label (for display)
  String? get scoreBand {
    final score = overallScore;
    if (score == null) return null;

    if (score >= 80) return 'veryGood';
    if (score >= 60) return 'good';
    if (score >= 40) return 'fair';
    return 'low';
  }

  /// Whether any domain has low confidence (<50% answered)
  bool get hasLowConfidenceDomain {
    final counts = answeredCountByDomain;
    for (final domain in QolDomain.all) {
      final answered = counts[domain] ?? 0;
      final total = QolDomain.questionCounts[domain] ?? 0;
      if (answered < total * 0.5) return true;
    }
    return false;
  }

  /// Validates assessment data
  List<String> validate() {
    final errors = <String>[];

    // Date validation
    if (date.isAfter(DateTime.now())) {
      errors.add('Assessment date cannot be in the future');
    }

    // Response validation
    for (final response in responses) {
      if (response.score != null) {
        if (response.score! < 0 || response.score! > 4) {
          errors.add(
            'Invalid score ${response.score} for ${response.questionId}',
          );
        }
      }

      // Ensure question exists
      if (QolQuestion.getById(response.questionId) == null) {
        errors.add('Unknown question ID: ${response.questionId}');
      }
    }

    // Check for duplicate responses
    final questionIds = responses.map((r) => r.questionId).toList();
    final uniqueIds = questionIds.toSet();
    if (questionIds.length != uniqueIds.length) {
      errors.add('Duplicate responses found');
    }

    return errors;
  }

  /// Converts to JSON for Firestore storage
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

  /// Creates a copy with updated fields
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
      updatedAt: updatedAt == _undefined ? this.updatedAt : updatedAt as DateTime?,
      completionDurationSeconds: completionDurationSeconds == _undefined
          ? this.completionDurationSeconds
          : completionDurationSeconds as int?,
    );
  }

  // DateTime parsing helpers
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    throw ArgumentError('Invalid DateTime value: $value');
  }

  static DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    return _parseDateTime(value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QolAssessment &&
          other.id == id &&
          other.userId == userId &&
          other.petId == petId &&
          other.date == date &&
          listEquals(other.responses, responses) &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.completionDurationSeconds == completionDurationSeconds;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        petId,
        date,
        Object.hashAll(responses),
        createdAt,
        updatedAt,
        completionDurationSeconds,
      );

  @override
  String toString() {
    return 'QolAssessment('
        'id: $id, '
        'date: $date, '
        'answeredCount: $answeredCount, '
        'overallScore: $overallScore'
        ')';
  }
}
```

**Rationale:**
- Comprehensive model with computed properties for scores
- Follows existing patterns from `DailySummary` and `HealthParameter`
- Built-in validation and error handling
- Handles reverse scoring transparently
- Low confidence detection for data quality indicators

### 2.5 QoL Trend Summary Model

**File:** `lib/features/qol/models/qol_trend_summary.dart`

```dart
import 'package:flutter/foundation.dart';

/// Represents aggregated QoL data for trend analysis
///
/// This model is computed on-demand from historical assessments
/// rather than stored in Firestore (cost optimization).
@immutable
class QolTrendSummary {
  const QolTrendSummary({
    required this.date,
    required this.domainScores,
    required this.overallScore,
    this.assessmentId,
  });

  /// Date of the assessment
  final DateTime date;

  /// Domain scores (0-100 scale)
  final Map<String, double> domainScores;

  /// Overall QoL score (0-100 scale)
  final double overallScore;

  /// Optional reference to source assessment ID
  final String? assessmentId;

  /// Compute delta vs another trend point
  double deltaOverall(QolTrendSummary other) {
    return overallScore - other.overallScore;
  }

  /// Compute domain-specific delta
  double? deltaDomain(String domain, QolTrendSummary other) {
    final thisScore = domainScores[domain];
    final otherScore = other.domainScores[domain];
    if (thisScore == null || otherScore == null) return null;
    return thisScore - otherScore;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QolTrendSummary &&
          other.date == date &&
          other.overallScore == overallScore &&
          mapEquals(other.domainScores, domainScores);

  @override
  int get hashCode => Object.hash(date, overallScore, domainScores);

  @override
  String toString() {
    return 'QolTrendSummary(date: $date, overall: $overallScore)';
  }
}
```

**Rationale:** Lightweight model for chart consumption, computed on-demand to avoid storing redundant data.

---

## 3. Firebase Schema & Cost Optimization

### 3.1 Firestore Collections

```
users/
└── {userId}/
    └── pets/
        └── {petId}/
            ├── qolAssessments/           # PRIMARY: Assessment entries
            │   └── {YYYY-MM-DD}          # Document ID = date (e.g., "2025-12-14")
            │       ├── id: string
            │       ├── userId: string
            │       ├── petId: string
            │       ├── date: Timestamp
            │       ├── responses: array[
            │       │     {questionId: string, score: int | null}
            │       │   ]
            │       ├── createdAt: Timestamp
            │       ├── updatedAt: Timestamp (optional)
            │       └── completionDurationSeconds: int (optional)
            │
            └── treatmentSummaries/       # REUSE: Existing summary structure
                ├── daily/summaries/{YYYY-MM-DD}
                │   └── (add QoL fields to existing DailySummary)
                │       ├── qolOverallScore: double (0-100)
                │       ├── qolVitalityScore: double (0-100)
                │       ├── qolComfortScore: double (0-100)
                │       ├── qolEmotionalScore: double (0-100)
                │       ├── qolAppetiteScore: double (0-100)
                │       ├── qolTreatmentBurdenScore: double (0-100)
                │       └── hasQolAssessment: bool
                │
                ├── weekly/summaries/{YYYY-Www}
                │   └── (aggregate QoL data - computed on-demand)
                │
                └── monthly/summaries/{YYYY-MM}
                    └── (aggregate QoL data - computed on-demand)
```

### 3.2 Cost Optimization Strategy

**Following Firebase CRUD Rules:**

✅ **Minimize Reads:**
1. **Paginated queries:** Fetch assessments with `.limit(20)` and pagination
2. **Cache-first strategy:** Load recent data once, cache in memory (Riverpod state)
3. **Selective listeners:** Only attach real-time listeners to current period (e.g., last 30 days)
4. **No full-history fetch:** For trend analysis, limit to last 12 assessments (3 months)
5. **Offline persistence:** Enable Firestore offline cache to reduce redundant reads

✅ **Minimize Writes:**
1. **One assessment per day:** Document ID = date prevents duplicate daily entries
2. **Batch writes:** Update assessment + daily summary in single batch
3. **No micro-writes:** Store full assessment at once, not incremental
4. **Throttled updates:** If user edits an existing assessment, debounce save operations

✅ **Data Modeling:**
1. **No summary documents:** Weekly/monthly trend data is computed on-demand from cached daily summaries (already loaded for home screen)
2. **Denormalize when beneficial:** Store computed scores in assessment document to avoid recalculation on every read
3. **Reuse existing summaries:** Add QoL fields to existing `DailySummary` instead of creating separate collection

**Estimated Read/Write Impact:**
- **New assessment:** 2 writes (assessment + daily summary update) = Cost optimized ✅
- **View trends (30 days):** 1 read (if using cached daily summaries) = Cost optimized ✅
- **Historical chart (3 months):** ~12 reads (12 assessments) = Acceptable ✅
- **Home screen radar chart:** 0 additional reads (uses cached latest assessment) = Cost optimized ✅

### 3.3 Indexes Required

```yaml
# firestore.indexes.json additions
{
  "indexes": [
    {
      "collectionGroup": "qolAssessments",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "petId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "qolAssessments",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "petId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    }
  ]
}
```

**Rationale:** Composite index for efficient querying by pet + date range.

---

## 4. Service Layer Implementation

### 4.1 QoL Scoring Service

**File:** `lib/features/qol/services/qol_scoring_service.dart`

**Purpose:** Pure business logic for scoring and trend calculations (no Firebase dependencies).

**Key Methods:**
```dart
class QolScoringService {
  /// Computes domain score from responses
  double? calculateDomainScore(
    String domain,
    List<QolResponse> responses,
  );

  /// Computes overall QoL score
  double? calculateOverallScore(QolAssessment assessment);

  /// Detects notable change (≥15 point drop in domain, sustained ≥2 assessments)
  bool hasNotableChange(
    List<QolTrendSummary> recentTrends,
    String domain,
  );

  /// Computes stability indicator (stable/improving/declining)
  TrendStability calculateTrendStability(
    List<QolTrendSummary> recentTrends,
  );

  /// Generates interpretation message based on trend data
  String? generateInterpretationMessage(
    QolTrendSummary current,
    QolTrendSummary? previous,
    BuildContext context, // for localization
  );
}
```

**Rationale:** Separation of concerns - scoring logic is testable independently of Firebase.

### 4.2 QoL Service

**File:** `lib/features/qol/services/qol_service.dart`

**Purpose:** Firebase CRUD operations for QoL assessments.

**Pattern Reference:** `lib/features/health/services/symptoms_service.dart`

**Key Methods:**
```dart
class QolService {
  QolService({
    FirebaseFirestore? firestore,
    AnalyticsService? analyticsService,
  });

  // ============================================
  // CREATE
  // ============================================

  /// Saves a new QoL assessment
  ///
  /// Performs batch write:
  /// 1. Create/update qolAssessments/{date} document
  /// 2. Update daily summary with QoL scores
  Future<void> saveAssessment(QolAssessment assessment);

  // ============================================
  // READ
  // ============================================

  /// Gets single assessment by date
  Future<QolAssessment?> getAssessment(
    String userId,
    String petId,
    DateTime date,
  );

  /// Gets recent assessments (paginated)
  Future<List<QolAssessment>> getRecentAssessments(
    String userId,
    String petId, {
    int limit = 20,
    DateTime? startAfter,
  });

  /// Streams latest assessment (real-time)
  Stream<QolAssessment?> watchLatestAssessment(
    String userId,
    String petId,
  );

  // ============================================
  // UPDATE
  // ============================================

  /// Updates existing assessment
  Future<void> updateAssessment(QolAssessment assessment);

  // ============================================
  // DELETE
  // ============================================

  /// Deletes assessment (with daily summary cleanup)
  Future<void> deleteAssessment(
    String userId,
    String petId,
    DateTime date,
  );

  // ============================================
  // ANALYTICS
  // ============================================

  Future<void> _trackAssessmentCompleted(QolAssessment assessment);
  Future<void> _trackAssessmentUpdated(QolAssessment assessment);
  Future<void> _trackTrendViewed(String period);
}
```

**Implementation Notes:**
- Follow exact pattern from `symptoms_service.dart`
- Use `WriteBatch` for multi-document operations
- Comprehensive error handling with custom exceptions
- Analytics integration at every operation
- Validate data before writes
- Use private helper methods for Firestore paths

**Note:** PDF/image export functionality will be implemented later as part of a comprehensive export feature covering multiple insights. This service focuses solely on CRUD operations for QoL assessments.

---

## 5. State Management Strategy

### 5.1 Provider Architecture

**File:** `lib/providers/qol_provider.dart`

**Pattern Reference:** `lib/providers/logging_provider.dart` (2403 lines - comprehensive example)

```dart
// ============================================
// SERVICE PROVIDER (Foundation)
// ============================================

final qolServiceProvider = Provider<QolService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final analytics = ref.watch(analyticsServiceDirectProvider);
  return QolService(
    firestore: firestore,
    analyticsService: analytics,
  );
});

final qolScoringServiceProvider = Provider<QolScoringService>((ref) {
  return QolScoringService();
});

// ============================================
// STATE
// ============================================

@immutable
class QolState {
  const QolState({
    this.currentAssessment,
    this.recentAssessments = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.lastFetchTime,
  });

  final QolAssessment? currentAssessment;
  final List<QolAssessment> recentAssessments;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final DateTime? lastFetchTime;

  QolState copyWith({
    Object? currentAssessment = _undefined,
    List<QolAssessment>? recentAssessments,
    bool? isLoading,
    bool? isSaving,
    Object? error = _undefined,
    Object? lastFetchTime = _undefined,
  }) {
    return QolState(
      currentAssessment: currentAssessment == _undefined
          ? this.currentAssessment
          : currentAssessment as QolAssessment?,
      recentAssessments: recentAssessments ?? this.recentAssessments,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error == _undefined ? this.error : error as String?,
      lastFetchTime: lastFetchTime == _undefined
          ? this.lastFetchTime
          : lastFetchTime as DateTime?,
    );
  }
}

// ============================================
// STATE NOTIFIER
// ============================================

class QolNotifier extends StateNotifier<QolState> {
  QolNotifier(this._ref) : super(const QolState()) {
    _init();
  }

  final Ref _ref;

  QolService get _service => _ref.read(qolServiceProvider);
  QolScoringService get _scoring => _ref.read(qolScoringServiceProvider);
  AnalyticsService get _analytics => _ref.read(analyticsServiceDirectProvider);

  Future<void> _init() async {
    // Load cached data on startup
    await loadRecentAssessments();
  }

  // ============================================
  // CRUD OPERATIONS
  // ============================================

  Future<void> loadRecentAssessments({bool forceRefresh = false}) async {
    // Cache-first strategy
    if (!forceRefresh && state.recentAssessments.isNotEmpty) {
      final cacheAge = DateTime.now().difference(state.lastFetchTime!);
      if (cacheAge.inMinutes < 5) return; // Fresh cache
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final userId = _ref.read(currentUserProvider)!.uid;
      final petId = _ref.read(selectedPetIdProvider)!;

      final assessments = await _service.getRecentAssessments(
        userId,
        petId,
        limit: 20,
      );

      state = state.copyWith(
        recentAssessments: assessments,
        currentAssessment: assessments.firstOrNull,
        isLoading: false,
        lastFetchTime: DateTime.now(),
      );

      await _analytics.trackFeatureUsed(
        featureName: 'qol_history_loaded',
        additionalParams: {'count': assessments.length},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load QoL history: $e',
      );
    }
  }

  Future<void> saveAssessment(QolAssessment assessment) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _service.saveAssessment(assessment);

      // Update local state
      final updatedList = [
        assessment,
        ...state.recentAssessments.where((a) => a.id != assessment.id),
      ];

      state = state.copyWith(
        currentAssessment: assessment,
        recentAssessments: updatedList,
        isSaving: false,
      );

      await _analytics.trackFeatureUsed(
        featureName: 'qol_assessment_completed',
        additionalParams: {
          'overall_score': assessment.overallScore?.toInt(),
          'completion_duration_seconds': assessment.completionDurationSeconds,
          'answered_count': assessment.answeredCount,
        },
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save assessment: $e',
      );
      rethrow;
    }
  }

  Future<void> updateAssessment(QolAssessment assessment) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _service.updateAssessment(assessment);

      // Update local state
      final updatedList = state.recentAssessments
          .map((a) => a.id == assessment.id ? assessment : a)
          .toList();

      state = state.copyWith(
        currentAssessment:
            state.currentAssessment?.id == assessment.id
                ? assessment
                : state.currentAssessment,
        recentAssessments: updatedList,
        isSaving: false,
      );

      await _analytics.trackFeatureUsed(
        featureName: 'qol_assessment_updated',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to update assessment: $e',
      );
      rethrow;
    }
  }

  Future<void> deleteAssessment(String assessmentId) async {
    final assessment = state.recentAssessments
        .firstWhere((a) => a.id == assessmentId);

    try {
      await _service.deleteAssessment(
        assessment.userId,
        assessment.petId,
        assessment.date,
      );

      // Update local state
      final updatedList = state.recentAssessments
          .where((a) => a.id != assessmentId)
          .toList();

      state = state.copyWith(
        currentAssessment:
            state.currentAssessment?.id == assessmentId
                ? updatedList.firstOrNull
                : state.currentAssessment,
        recentAssessments: updatedList,
      );

      await _analytics.trackFeatureUsed(
        featureName: 'qol_assessment_deleted',
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete assessment: $e');
      rethrow;
    }
  }

  // ============================================
  // COMPUTED DATA
  // ============================================

  List<QolTrendSummary> getTrendData({int limit = 12}) {
    return state.recentAssessments
        .take(limit)
        .where((a) => a.overallScore != null)
        .map((a) => QolTrendSummary(
              date: a.date,
              domainScores: a.domainScores.map(
                (k, v) => MapEntry(k, v ?? 0.0),
              ),
              overallScore: a.overallScore!,
              assessmentId: a.id,
            ))
        .toList();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ============================================
// MAIN PROVIDER
// ============================================

final qolProvider = StateNotifierProvider<QolNotifier, QolState>((ref) {
  return QolNotifier(ref);
});

// ============================================
// SELECTOR PROVIDERS (Optimized rebuilds)
// ============================================

final isLoadingQolProvider = Provider<bool>((ref) {
  return ref.watch(qolProvider.select((state) => state.isLoading));
});

final isSavingQolProvider = Provider<bool>((ref) {
  return ref.watch(qolProvider.select((state) => state.isSaving));
});

final qolErrorProvider = Provider<String?>((ref) {
  return ref.watch(qolProvider.select((state) => state.error));
});

final currentQolAssessmentProvider = Provider<QolAssessment?>((ref) {
  return ref.watch(qolProvider.select((state) => state.currentAssessment));
});

final recentQolAssessmentsProvider = Provider<List<QolAssessment>>((ref) {
  return ref.watch(qolProvider.select((state) => state.recentAssessments));
});

final qolTrendDataProvider = Provider<List<QolTrendSummary>>((ref) {
  return ref.watch(qolProvider.notifier).getTrendData();
});
```

**Rationale:**
- Follows exact pattern from `logging_provider.dart`
- Cache-first strategy minimizes Firestore reads
- Selector providers for granular rebuilds
- Comprehensive analytics integration
- Clear separation between loading and saving states

### 5.2 Cache Lifecycle

**Strategy:**
1. **On app startup:** Load last 20 assessments into memory
2. **On navigation:** Check cache freshness (5-minute TTL)
3. **After save:** Update local cache immediately (optimistic UI)
4. **On pull-to-refresh:** Force cache invalidation

**Rationale:** Minimizes Firestore reads while keeping data fresh.

---

## 6. UI/UX Implementation

### 6.1 Navigation Entry Point

**Location:** Profile Screen (existing feature hub)

**Pattern:** Add navigation tile in `lib/features/profile/screens/profile_screen.dart`

```dart
// Add after "Medication Schedule" tile
ProfileNavigationTile(
  icon: Icons.favorite_outline,
  title: l10n.qolNavigationTitle,
  subtitle: l10n.qolNavigationSubtitle,
  onTap: () => context.push('/profile/qol'),
),
```

**Rationale:** Profile screen is the established location for health tracking features (CKD Profile, Schedules, etc.).

### 6.2 QoL Questionnaire Screen

**File:** `lib/features/qol/screens/qol_questionnaire_screen.dart`

**Pattern Reference:** `lib/features/onboarding/screens/ckd_medical_info_screen.dart` (form handling)

**Design:**
- **Layout:** Single-question-per-screen with swipe/tap progression
- **Progress indicator:** Linear progress bar at top (X/14 questions)
- **Question card:** Large, readable text with 5 response options + "Not sure"
- **Navigation:** "Previous" button (top-left), auto-advance on selection
- **Completion:** Summary screen showing scores before save

**UI Components:**
```dart
class QolQuestionnaireScreen extends ConsumerStatefulWidget {
  const QolQuestionnaireScreen({super.key, this.editDate});

  /// Optional: Date of existing assessment to edit
  final DateTime? editDate;

  @override
  ConsumerState<QolQuestionnaireScreen> createState() => ...;
}

// State management
class _QolQuestionnaireScreenState extends ConsumerState<QolQuestionnaireScreen> {
  final PageController _pageController = PageController();
  final Map<String, int?> _responses = {};
  final DateTime _startTime = DateTime.now();

  int _currentQuestionIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    if (widget.editDate != null) {
      // Load existing assessment
      final assessment = await ref.read(qolProvider.notifier)
          .loadAssessment(widget.editDate!);
      if (assessment != null) {
        setState(() {
          for (final response in assessment.responses) {
            _responses[response.questionId] = response.score;
          }
        });
      }
    }
  }

  void _handleResponseSelected(String questionId, int? score) {
    setState(() {
      _responses[questionId] = score;
    });

    // Auto-advance to next question after brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_currentQuestionIndex < QolQuestion.all.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    // Haptic feedback
    HapticFeedback.selectionClick();
  }

  Future<void> _saveAssessment() async {
    final userId = ref.read(currentUserProvider)!.uid;
    final petId = ref.read(selectedPetIdProvider)!;
    final completionDuration = DateTime.now().difference(_startTime);

    final responses = _responses.entries
        .map((e) => QolResponse(questionId: e.key, score: e.value))
        .toList();

    final assessment = QolAssessment(
      id: const Uuid().v4(),
      userId: userId,
      petId: petId,
      date: widget.editDate ?? DateTime.now(),
      responses: responses,
      createdAt: DateTime.now(),
      completionDurationSeconds: completionDuration.inSeconds,
    );

    try {
      setState(() => _isLoading = true);
      await ref.read(qolProvider.notifier).saveAssessment(assessment);

      if (mounted) {
        context.go('/profile/qol/detail/${assessment.documentId}');
      }
    } catch (e) {
      if (mounted) {
        HydraSnackBar.showError(context, l10n.qolSaveError);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: HydraAppBar(
        title: Text(l10n.qolQuestionnaireTitle),
        style: HydraAppBarStyle.default_,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / QolQuestion.all.length,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
          ),

          // Question pages
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentQuestionIndex = index);
              },
              itemCount: QolQuestion.all.length,
              itemBuilder: (context, index) {
                final question = QolQuestion.all[index];
                return QolQuestionCard(
                  question: question,
                  currentResponse: _responses[question.id],
                  onResponseSelected: (score) {
                    _handleResponseSelected(question.id, score);
                  },
                );
              },
            ),
          ),

          // Bottom navigation
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    HydraButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      variant: HydraButtonVariant.secondary,
                      child: Text(l10n.previous),
                    ),
                  const Spacer(),
                  if (_currentQuestionIndex == QolQuestion.all.length - 1)
                    HydraButton(
                      onPressed: _saveAssessment,
                      isLoading: _isLoading,
                      child: Text(l10n.complete),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Aligns with UI Guidelines:**
- ✅ Uses `HydraAppBar` with `default_` style
- ✅ Uses `HydraButton` for CTAs
- ✅ Uses `AppScaffold` wrapper
- ✅ Uses `AppSpacing` constants for padding
- ✅ Haptic feedback on interactions
- ✅ Loading states with spinner overlay

### 6.3 QoL Question Card Widget

**File:** `lib/features/qol/widgets/qol_question_card.dart`

```dart
class QolQuestionCard extends StatelessWidget {
  const QolQuestionCard({
    super.key,
    required this.question,
    required this.onResponseSelected,
    this.currentResponse,
  });

  final QolQuestion question;
  final int? currentResponse;
  final ValueChanged<int?> onResponseSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final questionText = l10n.translate(question.textKey);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Domain badge
          Chip(
            label: Text(l10n.translate(QolDomain.displayKeys[question.domain]!)),
            backgroundColor: AppColors.primaryLight.withOpacity(0.2),
            labelStyle: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Question text
          Text(
            questionText,
            style: AppTextStyles.h1,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Recall period reminder
          Text(
            l10n.qolRecallPeriod, // "In the past 7 days..."
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // Response options (0-4 + "Not sure")
          ...List.generate(5, (index) {
            final score = 4 - index; // Display 4 first (best)
            final isSelected = currentResponse == score;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: HydraCard(
                onTap: () => onResponseSelected(score),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                    borderRadius: AppBorderRadius.cardRadius,
                  ),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: score,
                        groupValue: currentResponse,
                        onChanged: (_) => onResponseSelected(score),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _getScoreLabel(score, context),
                          style: AppTextStyles.body.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // "Not sure" option
          HydraCard(
            onTap: () => onResponseSelected(null),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: currentResponse == null
                    ? Border.all(color: AppColors.textTertiary, width: 2)
                    : null,
                borderRadius: AppBorderRadius.cardRadius,
              ),
              child: Row(
                children: [
                  Radio<int?>(
                    value: null,
                    groupValue: currentResponse,
                    onChanged: (_) => onResponseSelected(null),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.qolNotSure,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: currentResponse == null ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  String _getScoreLabel(int score, BuildContext context) {
    final l10n = context.l10n;
    switch (score) {
      case 4: return l10n.qolScoreAlways;
      case 3: return l10n.qolScoreOften;
      case 2: return l10n.qolScoreSometimes;
      case 1: return l10n.qolScoreRarely;
      case 0: return l10n.qolScoreNever;
      default: return '';
    }
  }
}
```

**Aligns with UI Guidelines:**
- ✅ Large touch targets (min 44px)
- ✅ Clear visual feedback for selection
- ✅ Uses `HydraCard` with press feedback
- ✅ Uses `AppTextStyles` for typography
- ✅ Uses `AppSpacing` for consistent spacing

### 6.4 QoL Detail Screen (Results)

**File:** `lib/features/qol/screens/qol_detail_screen.dart`

**Design:**
- **Hero card:** Overall score with band label and trend indicator
- **Radar chart:** 5-domain visualization
- **Domain breakdown:** List of domain scores with confidence indicators
- **Interpretation message:** Contextual guidance based on trends
- **Actions:** Edit, View History

```dart
class QolDetailScreen extends ConsumerWidget {
  const QolDetailScreen({super.key, required this.assessmentId});

  final String assessmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessment = ref.watch(
      recentQolAssessmentsProvider.select(
        (assessments) => assessments.firstWhere((a) => a.documentId == assessmentId),
      ),
    );

    return AppScaffold(
      appBar: HydraAppBar(
        title: Text(l10n.qolResultsTitle),
        style: HydraAppBarStyle.default_,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overall score card
            QolScoreSummaryCard(assessment: assessment),

            const SizedBox(height: AppSpacing.lg),

            // Radar chart
            QolRadarChart(assessment: assessment),

            const SizedBox(height: AppSpacing.lg),

            // Domain breakdown
            _buildDomainBreakdown(context, assessment),

            const SizedBox(height: AppSpacing.lg),

            // Interpretation
            if (assessment.overallScore != null)
              QolInterpretationCard(assessment: assessment),

            const SizedBox(height: AppSpacing.lg),

            // Actions
            Row(
              children: [
                Expanded(
                  child: HydraButton(
                    onPressed: () => context.push('/profile/qol/edit/${assessment.documentId}'),
                    variant: HydraButtonVariant.secondary,
                    child: Text(l10n.edit),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: HydraButton(
                    onPressed: () => context.push('/profile/qol/history'),
                    child: Text(l10n.viewHistory),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### 6.5 QoL Radar Chart Widget

**File:** `lib/features/qol/widgets/qol_radar_chart.dart`

**Pattern Reference:** `lib/features/health/widgets/symptoms_stacked_bar_chart.dart` (fl_chart usage)

**Design:**
- 5 axes (one per domain)
- Scale: 0-100
- Fill with semi-transparent primary color
- Border with primary color
- Labels at each vertex
- Responsive sizing

```dart
class QolRadarChart extends StatelessWidget {
  const QolRadarChart({super.key, required this.assessment});

  final QolAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final domainScores = assessment.domainScores;

    // Convert to chart data points (0-100 scale)
    final dataEntries = QolDomain.all.map((domain) {
      final score = domainScores[domain] ?? 0.0;
      return RadarEntry(value: score);
    }).toList();

    return HydraCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text(
              context.l10n.qolRadarChartTitle,
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSpacing.md),

            SizedBox(
              height: 280,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  tickCount: 5,
                  ticksTextStyle: AppTextStyles.small.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  radarBorderData: BorderSide(
                    color: AppColors.border,
                    width: 1,
                  ),
                  gridBorderData: BorderSide(
                    color: AppColors.border.withOpacity(0.5),
                    width: 1,
                  ),
                  tickBorderData: BorderSide(
                    color: AppColors.border.withOpacity(0.3),
                  ),
                  getTitle: (index, angle) {
                    final domain = QolDomain.all[index];
                    return RadarChartTitle(
                      text: context.l10n.translate(QolDomain.displayKeys[domain]!),
                      angle: angle,
                    );
                  },
                  dataSets: [
                    RadarDataSet(
                      fillColor: AppColors.primary.withOpacity(0.2),
                      borderColor: AppColors.primary,
                      borderWidth: 2,
                      entryRadius: 3,
                      dataEntries: dataEntries,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Legend
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: QolDomain.all.map((domain) {
        final score = assessment.domainScores[domain];
        final displayName = context.l10n.translate(QolDomain.displayKeys[domain]!);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$displayName: ${score?.toStringAsFixed(0) ?? '—'}',
              style: AppTextStyles.caption,
            ),
          ],
        );
      }).toList(),
    );
  }
}
```

**Aligns with UI Guidelines:**
- ✅ Uses `AppColors.primary` for brand consistency
- ✅ Uses `HydraCard` wrapper
- ✅ Uses `AppTextStyles` for typography
- ✅ Uses `AppSpacing` for padding

### 6.6 QoL Trend Line Chart Widget

**File:** `lib/features/qol/widgets/qol_trend_line_chart.dart`

**Pattern Reference:** `lib/features/health/widgets/weight_line_chart.dart`

**Design:**
- X-axis: Dates (last 12 assessments)
- Y-axis: Score (0-100)
- Multiple lines (one per domain + overall)
- Touch tooltip with score details
- Empty state if <2 assessments

```dart
class QolTrendLineChart extends ConsumerWidget {
  const QolTrendLineChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendData = ref.watch(qolTrendDataProvider);

    if (trendData.length < 2) {
      return HydraInfoCard(
        type: HydraInfoCardType.info,
        message: context.l10n.qolNeedMoreDataForTrends,
      );
    }

    return HydraCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.qolTrendChartTitle,
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSpacing.md),

            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.border.withOpacity(0.5),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 25,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= trendData.length) {
                            return const SizedBox.shrink();
                          }
                          final date = trendData[index].date;
                          return Text(
                            DateFormat('MMM d').format(date),
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: AppColors.border),
                  ),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    // Overall score line (primary)
                    LineChartBarData(
                      spots: trendData.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.overallScore);
                      }).toList(),
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),

                    // Individual domain lines (optional, togglable)
                    // ... (similar pattern for each domain with different colors)
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: AppColors.surface,
                      tooltipBorder: BorderSide(color: AppColors.border),
                      tooltipRoundedRadius: AppBorderRadius.sm,
                      getTooltipItems: (touchedSpots) {
                        // Custom tooltip with date + score
                        // ... (implementation)
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Aligns with UI Guidelines:**
- ✅ Uses established chart patterns from weight/symptom charts
- ✅ Uses `AppColors` for line colors
- ✅ Uses `AppShadows.tooltip` for tooltip shadow
- ✅ Responsive axis calculations

### 6.7 QoL History Screen

**File:** `lib/features/qol/screens/qol_history_screen.dart`

**Design:**
- List of past assessments (paginated)
- Card per assessment showing date, overall score, trend indicator
- Pull-to-refresh
- Empty state if no assessments

```dart
class QolHistoryScreen extends ConsumerWidget {
  const QolHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessments = ref.watch(recentQolAssessmentsProvider);
    final isLoading = ref.watch(isLoadingQolProvider);

    return AppScaffold(
      appBar: HydraAppBar(
        title: Text(context.l10n.qolHistoryTitle),
        style: HydraAppBarStyle.default_,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(qolProvider.notifier).loadRecentAssessments(forceRefresh: true);
        },
        child: isLoading && assessments.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : assessments.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: assessments.length,
                    itemBuilder: (context, index) {
                      final assessment = assessments[index];
                      final previous = index < assessments.length - 1
                          ? assessments[index + 1]
                          : null;

                      return _QolHistoryCard(
                        assessment: assessment,
                        previousAssessment: previous,
                      );
                    },
                  ),
      ),
      floatingActionButton: HydraFab(
        icon: Icons.add,
        onPressed: () => context.push('/profile/qol/new'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.qolEmptyStateTitle,
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.qolEmptyStateMessage,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          HydraButton(
            onPressed: () => context.push('/profile/qol/new'),
            child: Text(context.l10n.qolStartFirstAssessment),
          ),
        ],
      ),
    );
  }
}
```

---

## 7. Home Screen Integration

### 7.1 Latest QoL Radar Chart Card

**Location:** Home Screen (alongside other health tracking cards)

**Purpose:** Display the most recent QoL assessment radar chart for quick visibility and trend awareness.

**File:** `lib/features/home/widgets/qol_home_card.dart` (new widget)

**Design:**
- Compact radar chart (smaller than detail view)
- Overall score badge
- Date of assessment
- Tap to navigate to QoL detail screen
- Empty state if no assessment exists

**Pattern Reference:** Similar to existing home screen cards (e.g., symptom summary, medication adherence)

**Implementation:**
```dart
class QolHomeCard extends ConsumerWidget {
  const QolHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAssessment = ref.watch(currentQolAssessmentProvider);

    if (latestAssessment == null) {
      return _buildEmptyState(context);
    }

    return HydraCard(
      onTap: () => context.push('/profile/qol/detail/${latestAssessment.documentId}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.qolHomeCardTitle,
                  style: AppTextStyles.h3,
                ),
                if (latestAssessment.overallScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreBandColor(latestAssessment.scoreBand).withOpacity(0.2),
                      borderRadius: AppBorderRadius.chipRadius,
                    ),
                    child: Text(
                      '${latestAssessment.overallScore!.toStringAsFixed(0)}%',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getScoreBandColor(latestAssessment.scoreBand),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.xs),

            // Date
            Text(
              context.l10n.qolAssessmentDate(
                DateFormat('MMM d, yyyy').format(latestAssessment.date),
              ),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Compact Radar Chart
            SizedBox(
              height: 180,
              child: QolRadarChart(
                assessment: latestAssessment,
                isCompact: true, // Use compact variant
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // CTA
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context.push('/profile/qol/history'),
                  child: Text(context.l10n.viewHistory),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return HydraCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.qolHomeCardTitle,
                  style: AppTextStyles.h3,
                ),
                Icon(
                  Icons.favorite_outline,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.qolHomeCardEmptyMessage,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            HydraButton(
              onPressed: () => context.push('/profile/qol/new'),
              variant: HydraButtonVariant.secondary,
              size: HydraButtonSize.small,
              child: Text(context.l10n.qolStartFirstAssessment),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreBandColor(String? band) {
    switch (band) {
      case 'veryGood':
        return AppColors.success;
      case 'good':
        return AppColors.primary;
      case 'fair':
        return AppColors.warning;
      case 'low':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
```

### 7.2 Radar Chart Compact Variant

**Update:** Add `isCompact` parameter to `QolRadarChart` widget

```dart
class QolRadarChart extends StatelessWidget {
  const QolRadarChart({
    super.key,
    required this.assessment,
    this.isCompact = false, // Add this parameter
  });

  final QolAssessment assessment;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    // ... existing code ...

    final height = isCompact ? 180.0 : 280.0; // Smaller height for home screen
    final showLegend = !isCompact; // Hide legend in compact view

    return HydraCard(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? AppSpacing.sm : AppSpacing.md),
        child: Column(
          children: [
            if (!isCompact)
              Text(
                context.l10n.qolRadarChartTitle,
                style: AppTextStyles.h2,
              ),
            SizedBox(height: isCompact ? 0 : AppSpacing.md),

            SizedBox(
              height: height,
              child: RadarChart(
                // ... existing chart configuration ...
              ),
            ),

            if (showLegend) ...[
              const SizedBox(height: AppSpacing.md),
              _buildLegend(context),
            ],
          ],
        ),
      ),
    );
  }
}
```

### 7.3 Home Screen Integration

**File to Modify:** `lib/features/home/screens/home_screen.dart`

**Integration:**
Add `QolHomeCard` to the home screen widget tree, positioned after medication/fluid tracking cards.

```dart
// In home_screen.dart, add to the card list:
children: [
  // ... existing cards ...

  // Add QoL card
  const QolHomeCard(),

  // ... remaining cards ...
],
```

**Rationale:**
- Provides immediate visibility of QoL status without navigation
- Encourages regular assessment through passive reminder
- Leverages cached data (no additional Firestore reads)
- Consistent with home screen pattern of showing latest data snapshots

---

## 8. Navigation Integration

### 8.1 Router Configuration

**File:** `lib/app/router.dart`

**Add QoL routes:**

```dart
// Add after profile routes (around line 300)

// QoL routes
GoRoute(
  path: '/profile/qol',
  name: 'profile-qol',
  pageBuilder: (context, state) => AppPageTransitions.bidirectionalSlide(
    child: const QolHistoryScreen(),
    key: state.pageKey,
  ),
  routes: [
    GoRoute(
      path: 'new',
      name: 'profile-qol-new',
      pageBuilder: (context, state) => AppPageTransitions.bidirectionalSlide(
        child: const QolQuestionnaireScreen(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: 'edit/:assessmentId',
      name: 'profile-qol-edit',
      pageBuilder: (context, state) {
        final assessmentId = state.pathParameters['assessmentId']!;
        return AppPageTransitions.bidirectionalSlide(
          child: QolQuestionnaireScreen(assessmentId: assessmentId),
          key: state.pageKey,
        );
      },
    ),
    GoRoute(
      path: 'detail/:assessmentId',
      name: 'profile-qol-detail',
      pageBuilder: (context, state) {
        final assessmentId = state.pathParameters['assessmentId']!;
        return AppPageTransitions.bidirectionalSlide(
          child: QolDetailScreen(assessmentId: assessmentId),
          key: state.pageKey,
        );
      },
    ),
  ],
),
```

**Rationale:** Follows existing profile route structure with nested routes for related screens.

---

## 9. Analytics Integration

### 9.1 Events to Track

**Reference:** `.cursor/reference/analytics_list.md` (MUST be updated)

**New Events:**

```dart
// Feature usage
'qol_assessment_started'
'qol_assessment_completed' {
  overall_score: int,
  completion_duration_seconds: int,
  answered_count: int,
  has_low_confidence_domain: bool,
}
'qol_assessment_updated'
'qol_assessment_deleted'

// Navigation
'qol_history_viewed'
'qol_detail_viewed' {
  assessment_date: string,
}
'qol_trends_viewed' {
  period: string, // '30d', '90d', 'all'
}
'qol_home_card_viewed'
'qol_home_card_tapped'

// Engagement
'qol_question_answered' {
  question_id: string,
  domain: string,
  score: int | null,
  time_spent_seconds: int,
}
'qol_interpretation_viewed' {
  trend_type: string, // 'stable', 'improving', 'declining'
}
```

**Integration Points:**
- `QolService`: Track CRUD operations
- `QolQuestionnaireScreen`: Track completion, time spent per question
- `QolDetailScreen`: Track detail views
- `QolTrendLineChart`: Track trend views
- `QolHomeCard`: Track home screen visibility and interactions

**Rationale:** Comprehensive analytics enable UX improvements and feature validation.

---

## 10. Localization Requirements

### 10.1 Required Keys

**File:** `lib/l10n/app_en.arb` (add ~85 new keys)

**Categories:**
1. **Navigation** (2 keys)
   - `qolNavigationTitle`
   - `qolNavigationSubtitle`

2. **Screen Titles** (4 keys)
   - `qolQuestionnaireTitle`
   - `qolHistoryTitle`
   - `qolResultsTitle`
   - `qolTrendChartTitle`

3. **Domain Names & Descriptions** (10 keys)
   - `qolDomainVitality` / `qolDomainVitalityDesc`
   - `qolDomainComfort` / `qolDomainComfortDesc`
   - `qolDomainEmotional` / `qolDomainEmotionalDesc`
   - `qolDomainAppetite` / `qolDomainAppetiteDesc`
   - `qolDomainTreatmentBurden` / `qolDomainTreatmentBurdenDesc`

4. **Questions** (14 keys)
   - `qolQuestionVitality1` through `qolQuestionVitality3`
   - `qolQuestionComfort1` through `qolQuestionComfort3`
   - `qolQuestionEmotional1` through `qolQuestionEmotional3`
   - `qolQuestionAppetite1` through `qolQuestionAppetite3`
   - `qolQuestionTreatment1` through `qolQuestionTreatment2`

5. **Response Labels** (6 keys)
   - `qolScoreAlways`
   - `qolScoreOften`
   - `qolScoreSometimes`
   - `qolScoreRarely`
   - `qolScoreNever`
   - `qolNotSure`

6. **Score Bands** (4 keys)
   - `qolScoreBandVeryGood`
   - `qolScoreBandGood`
   - `qolScoreBandFair`
   - `qolScoreBandLow`

7. **Interpretation Messages** (~15 keys)
   - `qolInterpretationStable`
   - `qolInterpretationImproving`
   - `qolInterpretationDeclining`
   - `qolInterpretationNotableDrop`
   - etc.

8. **UI Labels** (~20 keys)
   - `qolRecallPeriod` ("In the past 7 days...")
   - `qolRadarChartTitle`
   - `qolDataQuality` ("X / Y items answered")
   - `qolLowConfidenceWarning`
   - etc.

9. **Actions** (6 keys)
   - `qolStartAssessment`
   - `qolStartFirstAssessment`
   - `qolEditAssessment`
   - `viewHistory`
   - `edit`
   - `complete`

10. **Empty States & Errors** (~10 keys)
    - `qolEmptyStateTitle`
    - `qolEmptyStateMessage`
    - `qolSaveError`
    - `qolLoadError`
    - etc.

11. **Home Screen Card** (5 keys)
    - `qolHomeCardTitle`
    - `qolHomeCardEmptyMessage`
    - `qolAssessmentDate` (with date parameter)
    - etc.

**Total Estimate:** ~85-90 new localization keys

---

## 11. Testing Strategy

### 11.1 Unit Tests

**Files:**
```
test/features/qol/
├── models/
│   ├── qol_assessment_test.dart
│   ├── qol_response_test.dart
│   └── qol_domain_test.dart
├── services/
│   ├── qol_scoring_service_test.dart
│   └── qol_service_test.dart
└── providers/
    └── qol_provider_test.dart
```

**Key Test Cases:**
1. **QolAssessment Model:**
   - Domain score calculation (including reverse scoring)
   - Overall score calculation
   - Low confidence detection
   - Validation logic
   - JSON serialization/deserialization

2. **QolScoringService:**
   - Reverse scoring logic (critical for treatment burden)
   - Trend stability detection
   - Notable change detection (≥15 point drop)
   - Interpretation message generation

3. **QolService:**
   - Batch write operations (assessment + daily summary)
   - Error handling (network failures, validation errors)
   - Analytics tracking

4. **QolProvider:**
   - Cache lifecycle
   - Optimistic updates
   - State transitions

**Reference:** `test/providers/dashboard_provider_flexible_meds_test.dart` (provider testing pattern)

### 11.2 Widget Tests

**Files:**
```
test/features/qol/widgets/
├── qol_question_card_test.dart
├── qol_radar_chart_test.dart
├── qol_score_summary_card_test.dart
└── qol_home_card_test.dart
```

**Key Test Cases:**
- Response selection interaction
- Visual feedback states
- Accessibility labels
- Empty state rendering
- Home card compact radar chart display

### 11.3 Integration Tests

**Scenarios:**
1. Complete full assessment flow (14 questions)
2. Edit existing assessment
3. View trends with multiple assessments
4. Home screen radar chart display and interaction
5. Low confidence domain warning

### 11.4 Test Coverage Target

**Minimum:** 80% coverage for:
- Models (especially scoring logic)
- Services (especially QolScoringService)
- Providers (state management)

**Update:** `test/tests_index.md` with new test files

---

## 12. Implementation Roadmap

### Phase 1: Core Data & Service Layer (Week 1)
**Deliverables:**
- ✅ Data models (QolAssessment, QolResponse, QolDomain, QolQuestion)
- ✅ QolScoringService (pure business logic)
- ✅ QolService (Firebase CRUD)
- ✅ Unit tests for models and services
- ✅ Firebase schema implementation
- ✅ Firestore indexes

**Dependencies:** None

### Phase 2: State Management & Providers (Week 1-2)
**Deliverables:**
- ✅ QolProvider (Riverpod state notifier)
- ✅ Selector providers for optimized rebuilds
- ✅ Cache management logic
- ✅ Provider unit tests

**Dependencies:** Phase 1

### Phase 3: Questionnaire UI (Week 2)
**Deliverables:**
- ✅ QolQuestionnaireScreen
- ✅ QolQuestionCard widget
- ✅ Progress indicator
- ✅ Response selection UX
- ✅ Auto-advance logic
- ✅ Save & validation

**Dependencies:** Phase 2

### Phase 4: Results & Visualization (Week 2-3)
**Deliverables:**
- ✅ QolDetailScreen (results view)
- ✅ QolRadarChart widget
- ✅ QolScoreSummaryCard
- ✅ QolInterpretationCard
- ✅ Domain breakdown UI

**Dependencies:** Phase 3

### Phase 5: History & Trends (Week 3)
**Deliverables:**
- ✅ QolHistoryScreen
- ✅ QolTrendLineChart widget
- ✅ Trend calculation logic
- ✅ Notable change detection
- ✅ Stability indicators

**Dependencies:** Phase 4

### Phase 6: Home Screen Integration (Week 3)
**Deliverables:**
- ✅ QolHomeCard widget
- ✅ Compact radar chart variant
- ✅ Home screen integration
- ✅ Empty state handling
- ✅ Score band color coding

**Dependencies:** Phase 4

### Phase 7: Localization & Polish (Week 3-4)
**Deliverables:**
- ✅ All 85+ localization keys
- ✅ Copy review with clinical accuracy
- ✅ Empty states
- ✅ Error states
- ✅ Loading states
- ✅ Accessibility improvements

**Dependencies:** All previous phases

### Phase 8: Testing & QA (Week 4)
**Deliverables:**
- ✅ Complete unit test suite
- ✅ Widget tests for key components (including home card)
- ✅ Integration tests for flows
- ✅ Manual QA checklist
- ✅ Performance testing (Firestore read/write counts)

**Dependencies:** All previous phases

### Phase 9: Documentation & Launch (Week 4)
**Deliverables:**
- ✅ Update analytics_list.md
- ✅ Update tests_index.md
- ✅ User-facing feature documentation
- ✅ Release notes
- ✅ Analytics dashboard setup

**Dependencies:** Phase 8

**Total Estimated Timeline:** 4 weeks (1 developer)

**Note:** PDF/image export functionality and premium feature gating will be added in future iterations as separate features.

---

## 13. Future Considerations

### 13.1 Planned Features (Next Iterations)

**Export Functionality:**
1. **PDF Export**
   - Comprehensive PDF report generation covering multiple health insights
   - Include QoL assessments alongside symptom trends, medication adherence, etc.
   - Vet-friendly formatting with charts and summaries
   - Part of broader export feature (not QoL-specific)

2. **Image Export**
   - Radar chart image generation for quick sharing
   - Individual domain trend charts

**Premium Feature Gating:**
3. **Free vs Premium Tiers**
   - Free: Current snapshot + latest radar chart
   - Premium: Unlimited history, trend analysis, notable change detection
   - Follow existing premium feature patterns (e.g., injection sites analytics)

### 13.2 Potential Enhancements

**Scientifically Grounded:**
1. **MCID Calculation** (Minimum Clinically Important Difference)
   - Once enough data is collected, calculate personalized MCID thresholds
   - More accurate "notable change" detection

2. **Correlation Analysis**
   - Correlate QoL trends with treatment changes (medication, fluid volume)
   - Identify which interventions improve QoL

3. **Predictive Insights** (AI/ML - Future Premium Feature)
   - Predict QoL trajectory based on treatment adherence
   - Early warning system for quality of life decline

**User Experience:**
4. **Reminder System**
   - Scheduled reminders to complete weekly QoL assessments
   - Smart timing (not during active treatment times)

5. **Voice Input** (Accessibility)
   - Voice-to-text for question responses
   - Helpful for users with mobility issues

6. **Multi-Pet Support**
   - Compare QoL across multiple cats
   - Useful for households with multiple CKD cats

**Clinical Integration:**
7. **Vet Portal Integration**
   - Direct sharing with veterinary practice
   - API for vet practice management systems

8. **Custom Questions**
   - Allow vets to add practice-specific questions
   - Maintain core 14 questions + optional custom

### 13.3 Generalized Assessment Framework

**Opportunity:** The QoL implementation creates a reusable pattern for future health assessments.

**Future Questionnaires:**
- Pain assessment
- Mobility assessment
- Cognitive function assessment
- End-of-life quality assessment

**Abstraction:**
```dart
// Generalized assessment framework
abstract class HealthAssessment {
  List<AssessmentQuestion> get questions;
  Map<String, double> calculateDomainScores();
  double? calculateOverallScore();
  Widget buildVisualization();
}

// QoL extends this framework
class QolAssessment extends HealthAssessment { ... }
```

**Rationale:** Reduces future development time for similar features while maintaining consistency.

### 13.4 Data Export & Research

**Future Premium Feature:**
- Export anonymized QoL data for CKD research
- Contribute to veterinary studies
- Opt-in program with user consent
- Potential partnership with veterinary schools

**Ethical Considerations:**
- Clear informed consent
- Anonymization guarantees
- User control (opt-in/opt-out)
- No PII in research datasets

---

## Conclusion

This implementation plan provides a comprehensive, production-ready roadmap for integrating the HydraCAT Quality of Life tracking system into the HydraCat application. The proposed architecture:

✅ **Leverages existing patterns** - Reuses proven models, services, and UI components
✅ **Optimizes Firebase costs** - Batch writes, cache-first reads, paginated queries
✅ **Follows UI guidelines** - Consistent design system, accessibility standards
✅ **Maintains scientific integrity** - No diagnostic claims, trend-focused interpretation
✅ **Home screen integration** - Latest QoL radar chart displayed prominently
✅ **Scales for future** - Generalizable assessment framework
✅ **No new dependencies** - Uses existing fl_chart library

**Estimated Development Effort:** 4 weeks (1 senior developer)
**Estimated Firestore Cost Impact:** +10-15% (optimized batch writes, cache-first reads)
**User Value:** High - emotionally meaningful, clinically credible, vet-friendly
**Feature Scope:** Free feature for all users (premium gating to be added later)

**Recommendation:** Proceed with implementation following this specification. The QoL feature represents a flagship addition that strengthens HydraCat's value proposition as a comprehensive CKD management tool. Export functionality and premium gating will be implemented in subsequent iterations as part of broader feature enhancements.

---

## Appendix A: File Checklist

**New Files to Create:** 30 files

**Models (5):**
- `lib/features/qol/models/qol_assessment.dart`
- `lib/features/qol/models/qol_response.dart`
- `lib/features/qol/models/qol_domain.dart`
- `lib/features/qol/models/qol_question.dart`
- `lib/features/qol/models/qol_trend_summary.dart`

**Services (2):**
- `lib/features/qol/services/qol_service.dart`
- `lib/features/qol/services/qol_scoring_service.dart`

**Screens (3):**
- `lib/features/qol/screens/qol_questionnaire_screen.dart`
- `lib/features/qol/screens/qol_history_screen.dart`
- `lib/features/qol/screens/qol_detail_screen.dart`

**Widgets (6):**
- `lib/features/qol/widgets/qol_question_card.dart`
- `lib/features/qol/widgets/qol_radar_chart.dart` (with compact variant support)
- `lib/features/qol/widgets/qol_trend_line_chart.dart`
- `lib/features/qol/widgets/qol_score_summary_card.dart`
- `lib/features/qol/widgets/qol_interpretation_card.dart`
- `lib/features/home/widgets/qol_home_card.dart` (home screen integration)

**Exceptions (1):**
- `lib/features/qol/exceptions/qol_exceptions.dart`

**Providers (1):**
- `lib/providers/qol_provider.dart`

**Tests (11):**
- `test/features/qol/models/qol_assessment_test.dart`
- `test/features/qol/models/qol_response_test.dart`
- `test/features/qol/models/qol_domain_test.dart`
- `test/features/qol/services/qol_scoring_service_test.dart`
- `test/features/qol/services/qol_service_test.dart`
- `test/features/qol/providers/qol_provider_test.dart`
- `test/features/qol/widgets/qol_question_card_test.dart`
- `test/features/qol/widgets/qol_radar_chart_test.dart`
- `test/features/qol/widgets/qol_score_summary_card_test.dart`
- `test/features/qol/widgets/qol_home_card_test.dart`
- `test/features/qol/integration/qol_flow_test.dart`

**Modified Files:** 7 files
- `lib/app/router.dart` (add QoL routes)
- `lib/features/profile/screens/profile_screen.dart` (add navigation tile)
- `lib/features/home/screens/home_screen.dart` (add QoL home card)
- `lib/shared/models/daily_summary.dart` (add QoL fields)
- `lib/l10n/app_en.arb` (add ~85 localization keys)
- `.cursor/reference/analytics_list.md` (add QoL analytics events)
- `test/tests_index.md` (add QoL test files)

---

**End of Analysis Document**
