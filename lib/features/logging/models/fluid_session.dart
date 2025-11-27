import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:uuid/uuid.dart';

/// Sentinel value for [FluidSession.copyWith] to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

/// Data class for fluid therapy logging sessions
///
/// Represents a single instance of fluid therapy administration with complete
/// audit trail including medical time (when treatment occurred), audit time
/// (when user logged it), sync confirmation, and modification tracking.
@immutable
class FluidSession {
  /// Creates a [FluidSession] instance
  const FluidSession({
    required this.id,
    required this.petId,
    required this.userId,
    required this.dateTime,
    required this.volumeGiven,
    required this.createdAt,
    required this.injectionSite,
    this.stressLevel,
    this.notes,
    this.scheduleId,
    this.scheduledTime,
    this.updatedAt,
    this.dailyGoalMl,
    this.calculatedFromWeight,
    this.initialBagWeightG,
    this.finalBagWeightG,
  });

  /// Factory constructor to create a new fluid session
  ///
  /// Generates a UUID for the session ID and sets createdAt to current time.
  /// Use this when creating a new session from user input.
  factory FluidSession.create({
    required String petId,
    required String userId,
    required DateTime dateTime,
    required double volumeGiven,
    required FluidLocation injectionSite,
    String? stressLevel,
    String? notes,
    String? scheduleId,
    DateTime? scheduledTime,
    double? dailyGoalMl,
    bool? calculatedFromWeight,
    double? initialBagWeightG,
    double? finalBagWeightG,
  }) {
    const uuid = Uuid();
    return FluidSession(
      id: uuid.v4(),
      petId: petId,
      userId: userId,
      dateTime: dateTime,
      volumeGiven: volumeGiven,
      injectionSite: injectionSite,
      stressLevel: stressLevel,
      notes: notes,
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
      createdAt: DateTime.now(),
      dailyGoalMl: dailyGoalMl,
      calculatedFromWeight: calculatedFromWeight,
      initialBagWeightG: initialBagWeightG,
      finalBagWeightG: finalBagWeightG,
    );
  }

  /// Factory constructor to create a session from a schedule
  ///
  /// Pre-fills fluid details from the schedule. Actual volume defaults to
  /// the target volume from the schedule. Injection site defaults to schedule's
  /// preferred location if not explicitly provided.
  factory FluidSession.fromSchedule({
    required Schedule schedule,
    required DateTime scheduledTime,
    required String petId,
    required String userId,
    DateTime? actualDateTime,
    double? actualVolume,
    FluidLocation? actualInjectionSite,
    String? stressLevel,
    String? notes,
    double? dailyGoalMl,
    bool? calculatedFromWeight,
    double? initialBagWeightG,
    double? finalBagWeightG,
  }) {
    const uuid = Uuid();
    final injectionSite = actualInjectionSite ??
        schedule.preferredLocation ??
        FluidLocation.shoulderBladeMiddle;

    return FluidSession(
      id: uuid.v4(),
      petId: petId,
      userId: userId,
      dateTime: actualDateTime ?? scheduledTime,
      volumeGiven: actualVolume ?? schedule.targetVolume!,
      injectionSite: injectionSite,
      stressLevel: stressLevel,
      notes: notes,
      scheduleId: schedule.id,
      scheduledTime: scheduledTime,
      createdAt: DateTime.now(),
      dailyGoalMl: dailyGoalMl,
      calculatedFromWeight: calculatedFromWeight,
      initialBagWeightG: initialBagWeightG,
      finalBagWeightG: finalBagWeightG,
    );
  }

  /// Creates a [FluidSession] from JSON data
  ///
  /// Handles Firestore Timestamp conversion for all DateTime fields and
  /// FluidLocation enum conversion from string. Defaults to shoulderBladeMiddle
  /// for backward compatibility with old data.
  factory FluidSession.fromJson(Map<String, dynamic> json) {
    final injectionSite = json['injectionSite'] != null
        ? FluidLocation.fromString(json['injectionSite'] as String)
        : null;

    return FluidSession(
      id: json['id'] as String,
      petId: json['petId'] as String,
      userId: json['userId'] as String,
      dateTime: _parseDateTime(json['dateTime']),
      volumeGiven: (json['volumeGiven'] as num).toDouble(),
      injectionSite: injectionSite ?? FluidLocation.shoulderBladeMiddle,
      stressLevel: json['stressLevel'] as String?,
      notes: json['notes'] as String?,
      scheduleId: json['scheduleId'] as String?,
      scheduledTime: json['scheduledTime'] != null
          ? _parseDateTime(json['scheduledTime'])
          : null,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? _parseDateTime(json['updatedAt'])
          : null,
      dailyGoalMl: json['dailyGoalMl'] != null
          ? (json['dailyGoalMl'] as num).toDouble()
          : null,
      calculatedFromWeight: json['calculatedFromWeight'] as bool?,
      initialBagWeightG: json['initialBagWeightG'] != null
          ? (json['initialBagWeightG'] as num).toDouble()
          : null,
      finalBagWeightG: json['finalBagWeightG'] != null
          ? (json['finalBagWeightG'] as num).toDouble()
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

  /// Volume of fluids administered (in milliliters)
  final double volumeGiven;

  /// Injection site location (required for proper rotation tracking)
  final FluidLocation injectionSite;

  /// Stress level during administration ("low", "medium", "high")
  final String? stressLevel;

  /// Optional user notes about this administration
  final String? notes;

  /// Link to the schedule this session is associated with
  final String? scheduleId;

  /// Original scheduled time from the schedule
  final DateTime? scheduledTime;

  /// Audit timestamp: when the user created this log entry
  final DateTime createdAt;

  /// Modification timestamp: when this session was last edited
  final DateTime? updatedAt;

  /// Daily goal (in ml) that was active when this session was logged
  ///
  /// Stores the point-in-time daily fluid goal to ensure historical accuracy
  /// when schedules change. Nullable for backward compatibility with old data.
  final double? dailyGoalMl;

  /// Whether this volume was calculated from weight measurements
  ///
  /// When true, indicates the user used the weight calculator feature to
  /// determine the volume instead of manual estimation.
  final bool? calculatedFromWeight;

  /// Initial bag weight in grams (before fluid administration)
  ///
  /// Stored when weight calculator is used. Enables analytics and audit trail
  /// for weight-based volume calculations.
  final double? initialBagWeightG;

  /// Final bag weight in grams (after fluid administration)
  ///
  /// Stored when weight calculator is used. Used for "continue from same bag"
  /// feature in subsequent sessions.
  final double? finalBagWeightG;

  // Sync helpers

  /// Whether this session has been modified after creation
  bool get wasModified => updatedAt != null && updatedAt!.isAfter(createdAt);

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

    // Volume validation (matches plan: 1-500ml range)
    if (volumeGiven <= 0) {
      errors.add('Volume must be greater than 0');
    } else if (volumeGiven < 1) {
      errors.add('Volume must be at least 1ml');
    } else if (volumeGiven > 500) {
      errors.add('Volume must be 500ml or less');
    }

    // Stress level validation (if provided)
    if (stressLevel != null &&
        !['low', 'medium', 'high'].contains(stressLevel)) {
      errors.add('Stress level must be "low", "medium", or "high"');
    }

    // Injection site validation
    // Note: injectionSite is required (non-nullable) for proper rotation
    // tracking. Type system ensures it's always present, so no runtime
    // check needed.

    // DateTime validation
    if (dateTime.isAfter(DateTime.now())) {
      errors.add('Treatment time cannot be in the future');
    }

    return errors;
  }

  /// Converts [FluidSession] to JSON for Firestore
  ///
  /// Converts FluidLocation enum to string for storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'userId': userId,
      'dateTime': dateTime,
      'volumeGiven': volumeGiven,
      'injectionSite': injectionSite.name,
      'stressLevel': stressLevel,
      'notes': notes,
      'scheduleId': scheduleId,
      'scheduledTime': scheduledTime,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'dailyGoalMl': dailyGoalMl,
      'calculatedFromWeight': calculatedFromWeight,
      'initialBagWeightG': initialBagWeightG,
      'finalBagWeightG': finalBagWeightG,
    };
  }

  /// Creates a copy of this [FluidSession] with the given fields replaced
  FluidSession copyWith({
    String? id,
    String? petId,
    String? userId,
    DateTime? dateTime,
    double? volumeGiven,
    FluidLocation? injectionSite,
    Object? stressLevel = _undefined,
    Object? notes = _undefined,
    Object? scheduleId = _undefined,
    Object? scheduledTime = _undefined,
    DateTime? createdAt,
    Object? updatedAt = _undefined,
    Object? dailyGoalMl = _undefined,
    Object? calculatedFromWeight = _undefined,
    Object? initialBagWeightG = _undefined,
    Object? finalBagWeightG = _undefined,
  }) {
    return FluidSession(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      userId: userId ?? this.userId,
      dateTime: dateTime ?? this.dateTime,
      volumeGiven: volumeGiven ?? this.volumeGiven,
      injectionSite: injectionSite ?? this.injectionSite,
      stressLevel: stressLevel == _undefined
          ? this.stressLevel
          : stressLevel as String?,
      notes: notes == _undefined ? this.notes : notes as String?,
      scheduleId: scheduleId == _undefined
          ? this.scheduleId
          : scheduleId as String?,
      scheduledTime: scheduledTime == _undefined
          ? this.scheduledTime
          : scheduledTime as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt == _undefined
          ? this.updatedAt
          : updatedAt as DateTime?,
      dailyGoalMl: dailyGoalMl == _undefined
          ? this.dailyGoalMl
          : dailyGoalMl as double?,
      calculatedFromWeight: calculatedFromWeight == _undefined
          ? this.calculatedFromWeight
          : calculatedFromWeight as bool?,
      initialBagWeightG: initialBagWeightG == _undefined
          ? this.initialBagWeightG
          : initialBagWeightG as double?,
      finalBagWeightG: finalBagWeightG == _undefined
          ? this.finalBagWeightG
          : finalBagWeightG as double?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FluidSession &&
        other.id == id &&
        other.petId == petId &&
        other.userId == userId &&
        other.dateTime == dateTime &&
        other.volumeGiven == volumeGiven &&
        other.injectionSite == injectionSite &&
        other.stressLevel == stressLevel &&
        other.notes == notes &&
        other.scheduleId == scheduleId &&
        other.scheduledTime == scheduledTime &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.dailyGoalMl == dailyGoalMl &&
        other.calculatedFromWeight == calculatedFromWeight &&
        other.initialBagWeightG == initialBagWeightG &&
        other.finalBagWeightG == finalBagWeightG;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      petId,
      userId,
      dateTime,
      volumeGiven,
      injectionSite,
      stressLevel,
      notes,
      scheduleId,
      scheduledTime,
      createdAt,
      updatedAt,
      Object.hash(
        dailyGoalMl,
        calculatedFromWeight,
        initialBagWeightG,
        finalBagWeightG,
      ),
    );
  }

  @override
  String toString() {
    return 'FluidSession('
        'id: $id, '
        'petId: $petId, '
        'userId: $userId, '
        'dateTime: $dateTime, '
        'volumeGiven: $volumeGiven, '
        'injectionSite: $injectionSite, '
        'stressLevel: $stressLevel, '
        'notes: $notes, '
        'scheduleId: $scheduleId, '
        'scheduledTime: $scheduledTime, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'dailyGoalMl: $dailyGoalMl, '
        'calculatedFromWeight: $calculatedFromWeight, '
        'initialBagWeightG: $initialBagWeightG, '
        'finalBagWeightG: $finalBagWeightG'
        ')';
  }
}
