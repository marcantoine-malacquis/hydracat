import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:uuid/uuid.dart';

/// Data class for medication logging sessions
///
/// Represents a single instance of medication administration with complete
/// audit trail including medical time (when treatment occurred), audit time
/// (when user logged it), sync confirmation, and modification tracking.
@immutable
class MedicationSession {
  /// Creates a [MedicationSession] instance
  const MedicationSession({
    required this.id,
    required this.petId,
    required this.userId,
    required this.dateTime,
    required this.medicationName,
    required this.dosageGiven,
    required this.dosageScheduled,
    required this.medicationUnit,
    required this.completed,
    required this.createdAt,
    this.medicationStrengthAmount,
    this.medicationStrengthUnit,
    this.customMedicationStrengthUnit,
    this.notes,
    this.scheduleId,
    this.scheduledTime,
    this.syncedAt,
    this.updatedAt,
  });

  /// Factory constructor to create a new medication session
  ///
  /// Generates a UUID for the session ID and sets createdAt to current time.
  /// Use this when creating a new session from user input.
  factory MedicationSession.create({
    required String petId,
    required String userId,
    required DateTime dateTime,
    required String medicationName,
    required double dosageGiven,
    required double dosageScheduled,
    required String medicationUnit,
    required bool completed,
    String? medicationStrengthAmount,
    String? medicationStrengthUnit,
    String? customMedicationStrengthUnit,
    String? notes,
    String? scheduleId,
    DateTime? scheduledTime,
  }) {
    const uuid = Uuid();
    return MedicationSession(
      id: uuid.v4(),
      petId: petId,
      userId: userId,
      dateTime: dateTime,
      medicationName: medicationName,
      dosageGiven: dosageGiven,
      dosageScheduled: dosageScheduled,
      medicationUnit: medicationUnit,
      medicationStrengthAmount: medicationStrengthAmount,
      medicationStrengthUnit: medicationStrengthUnit,
      customMedicationStrengthUnit: customMedicationStrengthUnit,
      completed: completed,
      notes: notes,
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
      createdAt: DateTime.now(),
    );
  }

  /// Factory constructor to create a session from a schedule
  ///
  /// Pre-fills medication details from the schedule and uses scheduled values
  /// as the target. Actual values (dosageGiven) default to scheduled values.
  factory MedicationSession.fromSchedule({
    required Schedule schedule,
    required DateTime scheduledTime,
    required String petId,
    required String userId,
    DateTime? actualDateTime,
    double? actualDosage,
    bool? wasCompleted,
    String? notes,
  }) {
    const uuid = Uuid();
    return MedicationSession(
      id: uuid.v4(),
      petId: petId,
      userId: userId,
      dateTime: actualDateTime ?? scheduledTime,
      medicationName: schedule.medicationName!,
      dosageGiven: actualDosage ?? schedule.targetDosage!,
      dosageScheduled: schedule.targetDosage!,
      medicationUnit: schedule.medicationUnit!,
      medicationStrengthAmount: schedule.medicationStrengthAmount,
      medicationStrengthUnit: schedule.medicationStrengthUnit,
      customMedicationStrengthUnit: schedule.customMedicationStrengthUnit,
      completed: wasCompleted ?? true,
      notes: notes,
      scheduleId: schedule.id,
      scheduledTime: scheduledTime,
      createdAt: DateTime.now(),
    );
  }

  /// Factory to create a lightweight synthetic session used only for
  /// duplicate detection comparisons when sourced from local cache.
  factory MedicationSession.syntheticForDuplicate({
    required String petId,
    required String userId,
    required DateTime dateTime,
    required String medicationName,
  }) {
    return MedicationSession(
      id: 'synthetic-${dateTime.microsecondsSinceEpoch}',
      petId: petId,
      userId: userId,
      dateTime: dateTime,
      medicationName: medicationName,
      // Use safe defaults; values are irrelevant to duplicate time comparison
      dosageGiven: 0,
      dosageScheduled: 0,
      medicationUnit: '',
      completed: true,
      createdAt: DateTime.now(),
    );
  }

  /// Creates a [MedicationSession] from JSON data
  ///
  /// Handles Firestore Timestamp conversion for all DateTime fields.
  factory MedicationSession.fromJson(Map<String, dynamic> json) {
    return MedicationSession(
      id: json['id'] as String,
      petId: json['petId'] as String,
      userId: json['userId'] as String,
      dateTime: _parseDateTime(json['dateTime']),
      medicationName: json['medicationName'] as String,
      dosageGiven: (json['dosageGiven'] as num).toDouble(),
      dosageScheduled: (json['dosageScheduled'] as num).toDouble(),
      medicationUnit: json['medicationUnit'] as String,
      medicationStrengthAmount: json['medicationStrengthAmount'] as String?,
      medicationStrengthUnit: json['medicationStrengthUnit'] as String?,
      customMedicationStrengthUnit:
          json['customMedicationStrengthUnit'] as String?,
      completed: json['completed'] as bool,
      notes: json['notes'] as String?,
      scheduleId: json['scheduleId'] as String?,
      scheduledTime: json['scheduledTime'] != null
          ? _parseDateTime(json['scheduledTime'])
          : null,
      createdAt: _parseDateTime(json['createdAt']),
      syncedAt: json['syncedAt'] != null
          ? _parseDateTime(json['syncedAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? _parseDateTime(json['updatedAt'])
          : null,
    );
  }

  /// Helper method to parse DateTime from various formats
  ///
  /// Handles both Firestore Timestamp objects and ISO 8601 strings.
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    } else {
      throw ArgumentError(
        'Invalid DateTime format: expected Timestamp, String, or DateTime, '
        'got ${value.runtimeType}',
      );
    }
  }

  /// Unique identifier for the session (UUID)
  final String id;

  /// ID of the pet this session belongs to
  final String petId;

  /// ID of the user who logged this session
  final String userId;

  /// Medical timestamp: when the treatment actually occurred
  final DateTime dateTime;

  /// Name of the medication administered
  final String medicationName;

  /// Actual dosage administered
  final double dosageGiven;

  /// Scheduled/target dosage from schedule
  final double dosageScheduled;

  /// Unit of medication (e.g., "pills", "ml", "mg")
  final String medicationUnit;

  /// Medication strength amount (e.g., "2.5", "10")
  final String? medicationStrengthAmount;

  /// Medication strength unit (e.g., "mg", "mgPerMl")
  final String? medicationStrengthUnit;

  /// Custom medication strength unit (only when strengthUnit is "other")
  final String? customMedicationStrengthUnit;

  /// Whether the medication was successfully administered
  final bool completed;

  /// Optional user notes about this administration
  final String? notes;

  /// Link to the schedule this session is associated with
  final String? scheduleId;

  /// Original scheduled time from the schedule
  final DateTime? scheduledTime;

  /// Audit timestamp: when the user created this log entry
  final DateTime createdAt;

  /// Sync timestamp: when Firestore confirmed receipt (server timestamp)
  final DateTime? syncedAt;

  /// Modification timestamp: when this session was last edited
  final DateTime? updatedAt;

  // Sync helpers

  /// Whether this session has been synced to the server
  bool get isSynced => syncedAt != null;

  /// Whether this session has been modified after creation
  bool get wasModified => updatedAt != null && updatedAt!.isAfter(createdAt);

  /// Whether this session is pending sync
  bool get isPendingSync => !isSynced;

  // Adherence helpers

  /// Adherence percentage (0-100+)
  double get adherencePercentage =>
      dosageScheduled > 0 ? (dosageGiven / dosageScheduled) * 100 : 0;

  /// Whether the full scheduled dose was given
  bool get isFullDose => dosageGiven >= dosageScheduled;

  /// Whether a partial dose was given
  bool get isPartialDose => dosageGiven > 0 && dosageGiven < dosageScheduled;

  /// Whether no dose was given (missed)
  bool get isMissed => dosageGiven == 0 || !completed;

  // Validation

  /// Whether this session has valid data
  bool get isValid => validate().isEmpty;

  /// Validates the session data
  ///
  /// Returns a list of validation error messages. Empty list means valid.
  /// Follows the structural validation pattern from ProfileValidationService.
  List<String> validate() {
    final errors = <String>[];

    // Required fields
    if (id.isEmpty) errors.add('Session ID is required');
    if (petId.isEmpty) errors.add('Pet ID is required');
    if (userId.isEmpty) errors.add('User ID is required');
    if (medicationName.isEmpty) errors.add('Medication name is required');
    if (medicationUnit.isEmpty) errors.add('Medication unit is required');

    // Dosage validation
    if (dosageGiven < 0) errors.add('Dosage given cannot be negative');
    if (dosageScheduled <= 0) {
      errors.add('Dosage scheduled must be greater than 0');
    }

    // Reasonable ranges (structural only, not medical appropriateness)
    if (dosageGiven > 100) {
      errors.add('Dosage given seems unrealistically high (over 100)');
    }

    // DateTime validation
    if (dateTime.isAfter(DateTime.now())) {
      errors.add('Treatment time cannot be in the future');
    }

    // Conditional field validation
    if (medicationStrengthUnit == 'other' &&
        (customMedicationStrengthUnit == null ||
            customMedicationStrengthUnit!.isEmpty)) {
      errors.add(
        'Custom strength unit is required when '
        'strength unit is "other"',
      );
    }

    return errors;
  }

  /// Converts [MedicationSession] to JSON for Firestore
  ///
  /// Note: customMedicationStrengthUnit is only included if non-null to
  /// optimize storage for the majority of users who don't need it.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'petId': petId,
      'userId': userId,
      'dateTime': dateTime,
      'medicationName': medicationName,
      'dosageGiven': dosageGiven,
      'dosageScheduled': dosageScheduled,
      'medicationUnit': medicationUnit,
      'medicationStrengthAmount': medicationStrengthAmount,
      'medicationStrengthUnit': medicationStrengthUnit,
      'completed': completed,
      'notes': notes,
      'scheduleId': scheduleId,
      'scheduledTime': scheduledTime,
      'createdAt': createdAt,
      'syncedAt': syncedAt,
      'updatedAt': updatedAt,
    };

    // Only include customMedicationStrengthUnit if it's actually used
    if (customMedicationStrengthUnit != null) {
      json['customMedicationStrengthUnit'] = customMedicationStrengthUnit;
    }

    return json;
  }

  /// Creates a copy of this [MedicationSession] with the given fields replaced
  MedicationSession copyWith({
    String? id,
    String? petId,
    String? userId,
    DateTime? dateTime,
    String? medicationName,
    double? dosageGiven,
    double? dosageScheduled,
    String? medicationUnit,
    String? medicationStrengthAmount,
    String? medicationStrengthUnit,
    String? customMedicationStrengthUnit,
    bool? completed,
    String? notes,
    String? scheduleId,
    DateTime? scheduledTime,
    DateTime? createdAt,
    DateTime? syncedAt,
    DateTime? updatedAt,
  }) {
    return MedicationSession(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      userId: userId ?? this.userId,
      dateTime: dateTime ?? this.dateTime,
      medicationName: medicationName ?? this.medicationName,
      dosageGiven: dosageGiven ?? this.dosageGiven,
      dosageScheduled: dosageScheduled ?? this.dosageScheduled,
      medicationUnit: medicationUnit ?? this.medicationUnit,
      medicationStrengthAmount:
          medicationStrengthAmount ?? this.medicationStrengthAmount,
      medicationStrengthUnit:
          medicationStrengthUnit ?? this.medicationStrengthUnit,
      customMedicationStrengthUnit:
          customMedicationStrengthUnit ?? this.customMedicationStrengthUnit,
      completed: completed ?? this.completed,
      notes: notes ?? this.notes,
      scheduleId: scheduleId ?? this.scheduleId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MedicationSession &&
        other.id == id &&
        other.petId == petId &&
        other.userId == userId &&
        other.dateTime == dateTime &&
        other.medicationName == medicationName &&
        other.dosageGiven == dosageGiven &&
        other.dosageScheduled == dosageScheduled &&
        other.medicationUnit == medicationUnit &&
        other.medicationStrengthAmount == medicationStrengthAmount &&
        other.medicationStrengthUnit == medicationStrengthUnit &&
        other.customMedicationStrengthUnit == customMedicationStrengthUnit &&
        other.completed == completed &&
        other.notes == notes &&
        other.scheduleId == scheduleId &&
        other.scheduledTime == scheduledTime &&
        other.createdAt == createdAt &&
        other.syncedAt == syncedAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      petId,
      userId,
      dateTime,
      medicationName,
      dosageGiven,
      dosageScheduled,
      medicationUnit,
      medicationStrengthAmount,
      medicationStrengthUnit,
      customMedicationStrengthUnit,
      completed,
      notes,
      scheduleId,
      scheduledTime,
      createdAt,
      syncedAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'MedicationSession('
        'id: $id, '
        'petId: $petId, '
        'userId: $userId, '
        'dateTime: $dateTime, '
        'medicationName: $medicationName, '
        'dosageGiven: $dosageGiven, '
        'dosageScheduled: $dosageScheduled, '
        'medicationUnit: $medicationUnit, '
        'medicationStrengthAmount: $medicationStrengthAmount, '
        'medicationStrengthUnit: $medicationStrengthUnit, '
        'customMedicationStrengthUnit: $customMedicationStrengthUnit, '
        'completed: $completed, '
        'notes: $notes, '
        'scheduleId: $scheduleId, '
        'scheduledTime: $scheduledTime, '
        'createdAt: $createdAt, '
        'syncedAt: $syncedAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}
