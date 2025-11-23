import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Sentinel value for [HealthParameter.copyWith] to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

/// Health parameter data for a specific date
///
/// Tracks daily health metrics including weight, appetite, symptoms.
/// Stored in Firestore: `healthParameters/{YYYY-MM-DD}`
@immutable
class HealthParameter {
  /// Creates a [HealthParameter] instance
  const HealthParameter({
    required this.date,
    required this.createdAt,
    this.weight,
    this.appetite,
    this.symptoms,
    this.hasSymptoms,
    this.symptomScoreTotal,
    this.symptomScoreAverage,
    this.notes,
    this.updatedAt,
  });

  /// Factory constructor to create new health parameter
  factory HealthParameter.create({
    required DateTime date,
    double? weight,
    String? appetite,
    Map<String, int>? symptoms,
    String? notes,
  }) {
    // Validate symptom scores
    if (symptoms != null) {
      for (final entry in symptoms.entries) {
        _validateSymptomScore(entry.value);
      }
    }

    // Compute derived fields
    final hasSymptoms = _computeHasSymptoms(symptoms);
    final symptomScoreTotal = _computeSymptomScoreTotal(symptoms);
    final symptomScoreAverage = _computeSymptomScoreAverage(symptoms);

    return HealthParameter(
      date: DateTime(date.year, date.month, date.day),
      weight: weight,
      appetite: appetite,
      symptoms: symptoms,
      hasSymptoms: hasSymptoms,
      symptomScoreTotal: symptomScoreTotal,
      symptomScoreAverage: symptomScoreAverage,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  /// Factory constructor from Firestore document
  factory HealthParameter.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw ArgumentError('Document data is null');
    }

    // Parse symptoms map (handle both old string and new map format)
    Map<String, int>? symptomsMap;
    if (data['symptoms'] != null) {
      if (data['symptoms'] is Map) {
        // New format: map of symptom scores
        final symptomsData = data['symptoms'] as Map<String, dynamic>;
        symptomsMap = symptomsData.map((key, value) {
          if (value is num) {
            return MapEntry(key, value.toInt());
          }
          return MapEntry(key, value as int);
        });
      }
      // Old string format is ignored (backward compatibility)
    }

    return HealthParameter(
      date: _parseDate(data['date']),
      weight: data['weight'] != null
          ? (data['weight'] as num).toDouble()
          : null,
      appetite: data['appetite'] as String?,
      symptoms: symptomsMap,
      hasSymptoms: data['hasSymptoms'] as bool?,
      symptomScoreTotal: data['symptomScoreTotal'] != null
          ? (data['symptomScoreTotal'] as num).toInt()
          : null,
      symptomScoreAverage: data['symptomScoreAverage'] != null
          ? (data['symptomScoreAverage'] as num).toDouble()
          : null,
      notes: data['notes'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestampNullable(data['updatedAt']),
    );
  }

  /// Date this health parameter is for (normalized to start of day)
  final DateTime date;

  /// Weight in kilograms (optional)
  final double? weight;

  /// Appetite assessment (optional)
  /// Values: "all", "3-4", "half", "1-4", "nothing"
  final String? appetite;

  /// Per-symptom scores (optional)
  /// Map of symptom type keys to severity scores (0-10)
  /// Keys: vomiting, diarrhea, constipation, lethargy,
  /// suppressedAppetite, injectionSiteReaction
  /// Values: integers 0-10 (omitted if N/A)
  final Map<String, int>? symptoms;

  /// Whether any symptom score > 0 (computed and stored)
  final bool? hasSymptoms;

  /// Sum of all present symptom scores
  /// (0-60 for 6 symptoms, computed and stored)
  final int? symptomScoreTotal;

  /// Average of present symptom scores (0-10, computed and stored)
  final double? symptomScoreAverage;

  /// Optional notes (max 500 characters)
  final String? notes;

  /// When this parameter was first created
  final DateTime createdAt;

  /// When this parameter was last updated
  final DateTime? updatedAt;

  /// Document ID for Firestore (YYYY-MM-DD format)
  String get documentId => DateFormat('yyyy-MM-dd').format(date);

  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() {
    // Serialize symptoms map
    Map<String, dynamic>? symptomsJson;
    final symptomsValue = symptoms;
    if (symptomsValue != null && symptomsValue.isNotEmpty) {
      symptomsJson = <String, dynamic>{
        for (final entry in symptomsValue.entries) entry.key: entry.value,
      };
    }

    return {
      'date': Timestamp.fromDate(date),
      if (weight != null) 'weight': weight,
      if (appetite != null) 'appetite': appetite,
      if (symptomsJson != null) 'symptoms': symptomsJson,
      if (hasSymptoms != null) 'hasSymptoms': hasSymptoms,
      if (symptomScoreTotal != null) 'symptomScoreTotal': symptomScoreTotal,
      if (symptomScoreAverage != null)
        'symptomScoreAverage': symptomScoreAverage,
      if (notes != null) 'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Create a copy with updated fields
  HealthParameter copyWith({
    DateTime? date,
    Object? weight = _undefined,
    Object? appetite = _undefined,
    Object? symptoms = _undefined,
    Object? hasSymptoms = _undefined,
    Object? symptomScoreTotal = _undefined,
    Object? symptomScoreAverage = _undefined,
    Object? notes = _undefined,
    DateTime? createdAt,
    Object? updatedAt = _undefined,
  }) {
    return HealthParameter(
      date: date ?? this.date,
      weight: weight == _undefined ? this.weight : weight as double?,
      appetite: appetite == _undefined ? this.appetite : appetite as String?,
      symptoms: symptoms == _undefined
          ? this.symptoms
          : symptoms as Map<String, int>?,
      hasSymptoms: hasSymptoms == _undefined
          ? this.hasSymptoms
          : hasSymptoms as bool?,
      symptomScoreTotal: symptomScoreTotal == _undefined
          ? this.symptomScoreTotal
          : symptomScoreTotal as int?,
      symptomScoreAverage: symptomScoreAverage == _undefined
          ? this.symptomScoreAverage
          : symptomScoreAverage as double?,
      notes: notes == _undefined ? this.notes : notes as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt == _undefined
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HealthParameter &&
        other.date == date &&
        other.weight == weight &&
        other.appetite == appetite &&
        _mapEquals(other.symptoms, symptoms) &&
        other.hasSymptoms == hasSymptoms &&
        other.symptomScoreTotal == symptomScoreTotal &&
        other.symptomScoreAverage == symptomScoreAverage &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  /// Helper to compare maps by value
  static bool _mapEquals(Map<String, int>? a, Map<String, int>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      date,
      weight,
      appetite,
      symptoms,
      hasSymptoms,
      symptomScoreTotal,
      symptomScoreAverage,
      notes,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'HealthParameter('
        'date: $date, '
        'weight: $weight, '
        'appetite: $appetite, '
        'symptoms: $symptoms, '
        'hasSymptoms: $hasSymptoms, '
        'symptomScoreTotal: $symptomScoreTotal, '
        'symptomScoreAverage: $symptomScoreAverage, '
        'notes: $notes, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }

  // Computed getters (fallback when stored fields are missing)

  /// Computes hasSymptoms from symptoms map if stored value is null
  bool get computedHasSymptoms {
    return hasSymptoms ?? _computeHasSymptoms(symptoms) ?? false;
  }

  /// Computes symptomScoreTotal from symptoms map if stored value is null
  int? get computedSymptomScoreTotal {
    return symptomScoreTotal ?? _computeSymptomScoreTotal(symptoms);
  }

  /// Computes symptomScoreAverage from symptoms map if stored value is null
  double? get computedSymptomScoreAverage {
    return symptomScoreAverage ?? _computeSymptomScoreAverage(symptoms);
  }

  // Helper parsers
  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static DateTime? _parseTimestampNullable(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return null;
  }

  // Symptom computation helpers

  /// Computes whether any symptom score > 0
  static bool? _computeHasSymptoms(Map<String, int>? symptoms) {
    if (symptoms == null || symptoms.isEmpty) return false;
    return symptoms.values.any((score) => score > 0);
  }

  /// Computes sum of all present symptom scores
  static int? _computeSymptomScoreTotal(Map<String, int>? symptoms) {
    if (symptoms == null || symptoms.isEmpty) return null;
    return symptoms.values.fold<int>(0, (total, score) => total + score);
  }

  /// Computes average of present symptom scores
  static double? _computeSymptomScoreAverage(Map<String, int>? symptoms) {
    if (symptoms == null || symptoms.isEmpty) return null;
    final scores = symptoms.values.toList();
    if (scores.isEmpty) return null;
    final total = scores.fold<int>(0, (acc, score) => acc + score);
    return total / scores.length;
  }

  /// Validates that a symptom score is in the valid range (0-10)
  static void _validateSymptomScore(int? score) {
    if (score != null && (score < 0 || score > 10)) {
      throw ArgumentError(
        'Symptom score must be between 0 and 10 (inclusive), got: $score',
      );
    }
  }
}
