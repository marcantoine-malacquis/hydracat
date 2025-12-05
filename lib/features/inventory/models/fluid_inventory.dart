import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Main fluid inventory document model.
///
/// Tracks current fluid supply, refill history, and threshold settings.
/// Single document per user at path: users/{userId}/fluidInventory/main
@immutable
class FluidInventory {
  /// Primary constructor for the fluid inventory document.
  ///
  /// All fields are required except for [lastThresholdNotificationSentAt],
  /// which is null until the first low-inventory alert is sent.
  const FluidInventory({
    required this.id,
    required this.remainingVolume,
    required this.initialVolume,
    required this.reminderSessionsLeft,
    required this.lastRefillDate,
    required this.refillCount,
    required this.inventoryEnabledAt,
    required this.createdAt,
    required this.updatedAt,
    this.lastThresholdNotificationSentAt,
  });

  /// Create from Firestore document
  factory FluidInventory.fromJson(Map<String, dynamic> json) {
    return FluidInventory(
      id: json['id'] as String,
      remainingVolume: (json['remainingVolume'] as num).toDouble(),
      initialVolume: (json['initialVolume'] as num).toDouble(),
      reminderSessionsLeft: json['reminderSessionsLeft'] as int,
      lastRefillDate: (json['lastRefillDate'] as Timestamp).toDate(),
      refillCount: json['refillCount'] as int,
      inventoryEnabledAt: (json['inventoryEnabledAt'] as Timestamp).toDate(),
      lastThresholdNotificationSentAt:
          json['lastThresholdNotificationSentAt'] != null
          ? (json['lastThresholdNotificationSentAt'] as Timestamp).toDate()
          : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      // updatedAt can be null temporarily when
      // using FieldValue.serverTimestamp()
      // The client receives the update before the server replaces the sentinel
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Document ID (always "main")
  final String id;

  /// Current volume in mL (can be negative if logged while empty)
  final double remainingVolume;

  /// Volume at last refill/reset (used for percentage calculation)
  final double initialVolume;

  /// User setting: notify when X sessions left (1-20, default 10)
  /// Note: Threshold volume is computed dynamically, not stored
  final int reminderSessionsLeft;

  /// Last refill date (for UI display)
  final DateTime lastRefillDate;

  /// Lifetime refill counter
  final int refillCount;

  /// When user first activated inventory tracking
  final DateTime inventoryEnabledAt;

  /// When threshold notification was last sent (null if not sent yet)
  final DateTime? lastThresholdNotificationSentAt;

  /// Document creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime updatedAt;

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'remainingVolume': remainingVolume,
      'initialVolume': initialVolume,
      'reminderSessionsLeft': reminderSessionsLeft,
      'lastRefillDate': Timestamp.fromDate(lastRefillDate),
      'refillCount': refillCount,
      'inventoryEnabledAt': Timestamp.fromDate(inventoryEnabledAt),
      if (lastThresholdNotificationSentAt != null)
        'lastThresholdNotificationSentAt': Timestamp.fromDate(
          lastThresholdNotificationSentAt!,
        ),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create copy with updated fields
  FluidInventory copyWith({
    String? id,
    double? remainingVolume,
    double? initialVolume,
    int? reminderSessionsLeft,
    DateTime? lastRefillDate,
    int? refillCount,
    DateTime? inventoryEnabledAt,
    DateTime? lastThresholdNotificationSentAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FluidInventory(
      id: id ?? this.id,
      remainingVolume: remainingVolume ?? this.remainingVolume,
      initialVolume: initialVolume ?? this.initialVolume,
      reminderSessionsLeft: reminderSessionsLeft ?? this.reminderSessionsLeft,
      lastRefillDate: lastRefillDate ?? this.lastRefillDate,
      refillCount: refillCount ?? this.refillCount,
      inventoryEnabledAt: inventoryEnabledAt ?? this.inventoryEnabledAt,
      lastThresholdNotificationSentAt:
          lastThresholdNotificationSentAt ??
          this.lastThresholdNotificationSentAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FluidInventory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          remainingVolume == other.remainingVolume &&
          initialVolume == other.initialVolume &&
          reminderSessionsLeft == other.reminderSessionsLeft &&
          lastRefillDate == other.lastRefillDate &&
          refillCount == other.refillCount &&
          inventoryEnabledAt == other.inventoryEnabledAt &&
          lastThresholdNotificationSentAt ==
              other.lastThresholdNotificationSentAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    remainingVolume,
    initialVolume,
    reminderSessionsLeft,
    lastRefillDate,
    refillCount,
    inventoryEnabledAt,
    lastThresholdNotificationSentAt,
    createdAt,
    updatedAt,
  );

  @override
  String toString() {
    return 'FluidInventory('
        'id: $id, '
        'remainingVolume: $remainingVolume, '
        'initialVolume: $initialVolume, '
        'reminderSessionsLeft: $reminderSessionsLeft, '
        'lastRefillDate: $lastRefillDate, '
        'refillCount: $refillCount, '
        'inventoryEnabledAt: $inventoryEnabledAt, '
        'lastThresholdNotificationSentAt: $lastThresholdNotificationSentAt, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}
