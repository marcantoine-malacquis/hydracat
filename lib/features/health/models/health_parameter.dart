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
    this.notes,
    this.updatedAt,
  });

  /// Factory constructor to create new health parameter
  factory HealthParameter.create({
    required DateTime date,
    double? weight,
    String? appetite,
    String? symptoms,
    String? notes,
  }) {
    return HealthParameter(
      date: DateTime(date.year, date.month, date.day),
      weight: weight,
      appetite: appetite,
      symptoms: symptoms,
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
    return HealthParameter(
      date: _parseDate(data['date']),
      weight: data['weight'] != null
          ? (data['weight'] as num).toDouble()
          : null,
      appetite: data['appetite'] as String?,
      symptoms: data['symptoms'] as String?,
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

  /// Symptoms assessment (optional)
  /// Values: "good", "okay", "concerning"
  final String? symptoms;

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
    return {
      'date': Timestamp.fromDate(date),
      if (weight != null) 'weight': weight,
      if (appetite != null) 'appetite': appetite,
      if (symptoms != null) 'symptoms': symptoms,
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
    Object? notes = _undefined,
    DateTime? createdAt,
    Object? updatedAt = _undefined,
  }) {
    return HealthParameter(
      date: date ?? this.date,
      weight: weight == _undefined ? this.weight : weight as double?,
      appetite: appetite == _undefined ? this.appetite : appetite as String?,
      symptoms: symptoms == _undefined ? this.symptoms : symptoms as String?,
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
        other.symptoms == symptoms &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      date,
      weight,
      appetite,
      symptoms,
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
        'notes: $notes, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
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
}
