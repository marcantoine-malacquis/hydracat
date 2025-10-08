/// Operation models for offline logging queue
library;

import 'package:flutter/foundation.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/profile/models/schedule.dart';

/// Operation status in queue
enum OperationStatus {
  /// Waiting to sync
  pending,

  /// Currently syncing
  syncing,

  /// Max retries exhausted
  failed,
}

/// Base sealed class for logging operations
@immutable
sealed class LoggingOperation {
  /// Creates a [LoggingOperation]
  const LoggingOperation({
    required this.id,
    required this.userId,
    required this.petId,
    required this.createdAt,
    required this.status,
    required this.retryCount,
    this.lastError,
  });

  /// UUID for operation
  final String id;

  /// User ID
  final String userId;

  /// Pet ID
  final String petId;

  /// When operation was queued
  final DateTime createdAt;

  /// Current status
  final OperationStatus status;

  /// Number of retry attempts
  final int retryCount;

  /// Last error message (if any)
  final String? lastError;

  /// Convert to JSON for SharedPreferences
  Map<String, dynamic> toJson();

  /// Recreate from JSON
  static LoggingOperation fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'createMedication':
        return CreateMedicationOperation.fromJson(json);
      case 'createFluid':
        return CreateFluidOperation.fromJson(json);
      case 'updateMedication':
        return UpdateMedicationOperation.fromJson(json);
      case 'updateFluid':
        return UpdateFluidOperation.fromJson(json);
      case 'quickLogAll':
        return QuickLogAllOperation.fromJson(json);
      default:
        throw ArgumentError('Unknown operation type: $type');
    }
  }

  /// Copy with new status/retry count
  LoggingOperation copyWithStatus({
    OperationStatus? status,
    int? retryCount,
    String? lastError,
  });

  /// Check if operation is expired (>30 days old)
  bool get isExpired {
    final now = DateTime.now();
    return now.difference(createdAt).inDays > 30;
  }
}

/// Create new medication session
@immutable
final class CreateMedicationOperation extends LoggingOperation {
  /// Creates a [CreateMedicationOperation]
  const CreateMedicationOperation({
    required super.id,
    required super.userId,
    required super.petId,
    required super.createdAt,
    required this.session,
    required this.todaysSchedules,
    required this.recentSessions,
    super.status = OperationStatus.pending,
    super.retryCount = 0,
    super.lastError,
  });

  /// Creates a [CreateMedicationOperation] from JSON
  factory CreateMedicationOperation.fromJson(Map<String, dynamic> json) {
    return CreateMedicationOperation(
      id: json['id'] as String,
      userId: json['userId'] as String,
      petId: json['petId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: OperationStatus.values.byName(json['status'] as String),
      retryCount: json['retryCount'] as int,
      lastError: json['lastError'] as String?,
      session: MedicationSession.fromJson(
        json['session'] as Map<String, dynamic>,
      ),
      todaysSchedules: (json['todaysSchedules'] as List)
          .map((s) => Schedule.fromJson(s as Map<String, dynamic>))
          .toList(),
      recentSessions: (json['recentSessions'] as List)
          .map((s) => MedicationSession.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Medication session to log
  final MedicationSession session;

  /// Today's schedules for matching
  final List<Schedule> todaysSchedules;

  /// Recent sessions for duplicate detection
  final List<MedicationSession> recentSessions;

  @override
  CreateMedicationOperation copyWithStatus({
    OperationStatus? status,
    int? retryCount,
    String? lastError,
  }) => CreateMedicationOperation(
    id: id,
    userId: userId,
    petId: petId,
    createdAt: createdAt,
    session: session,
    todaysSchedules: todaysSchedules,
    recentSessions: recentSessions,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError ?? this.lastError,
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': 'createMedication',
    'id': id,
    'userId': userId,
    'petId': petId,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'retryCount': retryCount,
    'lastError': lastError,
    'session': session.toJson(),
    'todaysSchedules': todaysSchedules.map((s) => s.toJson()).toList(),
    'recentSessions': recentSessions.map((s) => s.toJson()).toList(),
  };
}

/// Create new fluid session
@immutable
final class CreateFluidOperation extends LoggingOperation {
  /// Creates a [CreateFluidOperation]
  const CreateFluidOperation({
    required super.id,
    required super.userId,
    required super.petId,
    required super.createdAt,
    required this.session,
    this.todaysSchedule,
    super.status = OperationStatus.pending,
    super.retryCount = 0,
    super.lastError,
  });

  /// Creates a [CreateFluidOperation] from JSON
  factory CreateFluidOperation.fromJson(Map<String, dynamic> json) {
    return CreateFluidOperation(
      id: json['id'] as String,
      userId: json['userId'] as String,
      petId: json['petId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: OperationStatus.values.byName(json['status'] as String),
      retryCount: json['retryCount'] as int,
      lastError: json['lastError'] as String?,
      session: FluidSession.fromJson(json['session'] as Map<String, dynamic>),
      todaysSchedule: json['todaysSchedule'] != null
          ? Schedule.fromJson(json['todaysSchedule'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Fluid session to log
  final FluidSession session;

  /// Today's fluid schedule for matching (optional)
  final Schedule? todaysSchedule;

  @override
  CreateFluidOperation copyWithStatus({
    OperationStatus? status,
    int? retryCount,
    String? lastError,
  }) => CreateFluidOperation(
    id: id,
    userId: userId,
    petId: petId,
    createdAt: createdAt,
    session: session,
    todaysSchedule: todaysSchedule,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError ?? this.lastError,
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': 'createFluid',
    'id': id,
    'userId': userId,
    'petId': petId,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'retryCount': retryCount,
    'lastError': lastError,
    'session': session.toJson(),
    'todaysSchedule': todaysSchedule?.toJson(),
  };
}

/// Update existing medication session
@immutable
final class UpdateMedicationOperation extends LoggingOperation {
  /// Creates an [UpdateMedicationOperation]
  const UpdateMedicationOperation({
    required super.id,
    required super.userId,
    required super.petId,
    required super.createdAt,
    required this.oldSession,
    required this.newSession,
    super.status = OperationStatus.pending,
    super.retryCount = 0,
    super.lastError,
  });

  /// Creates an [UpdateMedicationOperation] from JSON
  factory UpdateMedicationOperation.fromJson(Map<String, dynamic> json) {
    return UpdateMedicationOperation(
      id: json['id'] as String,
      userId: json['userId'] as String,
      petId: json['petId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: OperationStatus.values.byName(json['status'] as String),
      retryCount: json['retryCount'] as int,
      lastError: json['lastError'] as String?,
      oldSession: MedicationSession.fromJson(
        json['oldSession'] as Map<String, dynamic>,
      ),
      newSession: MedicationSession.fromJson(
        json['newSession'] as Map<String, dynamic>,
      ),
    );
  }

  /// Original session (for delta calculation)
  final MedicationSession oldSession;

  /// Updated session
  final MedicationSession newSession;

  @override
  UpdateMedicationOperation copyWithStatus({
    OperationStatus? status,
    int? retryCount,
    String? lastError,
  }) => UpdateMedicationOperation(
    id: id,
    userId: userId,
    petId: petId,
    createdAt: createdAt,
    oldSession: oldSession,
    newSession: newSession,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError ?? this.lastError,
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': 'updateMedication',
    'id': id,
    'userId': userId,
    'petId': petId,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'retryCount': retryCount,
    'lastError': lastError,
    'oldSession': oldSession.toJson(),
    'newSession': newSession.toJson(),
  };
}

/// Update existing fluid session
@immutable
final class UpdateFluidOperation extends LoggingOperation {
  /// Creates an [UpdateFluidOperation]
  const UpdateFluidOperation({
    required super.id,
    required super.userId,
    required super.petId,
    required super.createdAt,
    required this.oldSession,
    required this.newSession,
    super.status = OperationStatus.pending,
    super.retryCount = 0,
    super.lastError,
  });

  /// Creates an [UpdateFluidOperation] from JSON
  factory UpdateFluidOperation.fromJson(Map<String, dynamic> json) {
    return UpdateFluidOperation(
      id: json['id'] as String,
      userId: json['userId'] as String,
      petId: json['petId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: OperationStatus.values.byName(json['status'] as String),
      retryCount: json['retryCount'] as int,
      lastError: json['lastError'] as String?,
      oldSession: FluidSession.fromJson(
        json['oldSession'] as Map<String, dynamic>,
      ),
      newSession: FluidSession.fromJson(
        json['newSession'] as Map<String, dynamic>,
      ),
    );
  }

  /// Original session (for delta calculation)
  final FluidSession oldSession;

  /// Updated session
  final FluidSession newSession;

  @override
  UpdateFluidOperation copyWithStatus({
    OperationStatus? status,
    int? retryCount,
    String? lastError,
  }) => UpdateFluidOperation(
    id: id,
    userId: userId,
    petId: petId,
    createdAt: createdAt,
    oldSession: oldSession,
    newSession: newSession,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError ?? this.lastError,
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': 'updateFluid',
    'id': id,
    'userId': userId,
    'petId': petId,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'retryCount': retryCount,
    'lastError': lastError,
    'oldSession': oldSession.toJson(),
    'newSession': newSession.toJson(),
  };
}

/// Quick-log all scheduled treatments
@immutable
final class QuickLogAllOperation extends LoggingOperation {
  /// Creates a [QuickLogAllOperation]
  const QuickLogAllOperation({
    required super.id,
    required super.userId,
    required super.petId,
    required super.createdAt,
    required this.todaysSchedules,
    super.status = OperationStatus.pending,
    super.retryCount = 0,
    super.lastError,
  });

  /// Creates a [QuickLogAllOperation] from JSON
  factory QuickLogAllOperation.fromJson(Map<String, dynamic> json) {
    return QuickLogAllOperation(
      id: json['id'] as String,
      userId: json['userId'] as String,
      petId: json['petId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: OperationStatus.values.byName(json['status'] as String),
      retryCount: json['retryCount'] as int,
      lastError: json['lastError'] as String?,
      todaysSchedules: (json['todaysSchedules'] as List)
          .map((s) => Schedule.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Today's schedules to log
  final List<Schedule> todaysSchedules;

  @override
  QuickLogAllOperation copyWithStatus({
    OperationStatus? status,
    int? retryCount,
    String? lastError,
  }) => QuickLogAllOperation(
    id: id,
    userId: userId,
    petId: petId,
    createdAt: createdAt,
    todaysSchedules: todaysSchedules,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError ?? this.lastError,
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': 'quickLogAll',
    'id': id,
    'userId': userId,
    'petId': petId,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'retryCount': retryCount,
    'lastError': lastError,
    'todaysSchedules': todaysSchedules.map((s) => s.toJson()).toList(),
  };
}
