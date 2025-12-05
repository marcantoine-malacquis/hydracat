import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Refill history entry for fluid inventory.
@immutable
class RefillEntry {
  /// Creates an immutable refill history entry.
  const RefillEntry({
    required this.id,
    required this.volumeAdded,
    required this.totalAfterRefill,
    required this.isReset,
    required this.reminderSessionsLeft,
    required this.refillDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory RefillEntry.fromJson(Map<String, dynamic> json) {
    return RefillEntry(
      id: json['id'] as String,
      volumeAdded: (json['volumeAdded'] as num).toDouble(),
      totalAfterRefill: (json['totalAfterRefill'] as num).toDouble(),
      isReset: json['isReset'] as bool,
      reminderSessionsLeft: json['reminderSessionsLeft'] as int,
      refillDate: (json['refillDate'] as Timestamp).toDate(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Auto-generated document ID
  final String id;

  /// Volume added in this refill (always positive, in mL)
  final double volumeAdded;

  /// Snapshot of remainingVolume immediately after this refill
  final double totalAfterRefill;

  /// Whether the refill replaced current inventory (reset mode)
  final bool isReset;

  /// Threshold sessions-left setting at time of refill
  final int reminderSessionsLeft;

  /// When the refill was performed
  final DateTime refillDate;

  /// Document creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime updatedAt;

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'volumeAdded': volumeAdded,
      'totalAfterRefill': totalAfterRefill,
      'isReset': isReset,
      'reminderSessionsLeft': reminderSessionsLeft,
      'refillDate': Timestamp.fromDate(refillDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with selectively overridden fields.
  RefillEntry copyWith({
    String? id,
    double? volumeAdded,
    double? totalAfterRefill,
    bool? isReset,
    int? reminderSessionsLeft,
    DateTime? refillDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RefillEntry(
      id: id ?? this.id,
      volumeAdded: volumeAdded ?? this.volumeAdded,
      totalAfterRefill: totalAfterRefill ?? this.totalAfterRefill,
      isReset: isReset ?? this.isReset,
      reminderSessionsLeft: reminderSessionsLeft ?? this.reminderSessionsLeft,
      refillDate: refillDate ?? this.refillDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RefillEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          volumeAdded == other.volumeAdded &&
          totalAfterRefill == other.totalAfterRefill &&
          isReset == other.isReset &&
          reminderSessionsLeft == other.reminderSessionsLeft &&
          refillDate == other.refillDate &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        volumeAdded,
        totalAfterRefill,
        isReset,
        reminderSessionsLeft,
        refillDate,
        createdAt,
        updatedAt,
      );

  @override
  String toString() {
    return 'RefillEntry('
        'id: $id, '
        'volumeAdded: $volumeAdded, '
        'totalAfterRefill: $totalAfterRefill, '
        'isReset: $isReset, '
        'reminderSessionsLeft: $reminderSessionsLeft, '
        'refillDate: $refillDate, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}
