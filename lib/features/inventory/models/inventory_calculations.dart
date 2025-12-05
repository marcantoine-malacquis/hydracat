import 'package:flutter/foundation.dart';

/// Pure data object for inventory calculations derived from inventory and
/// schedules.
@immutable
class InventoryCalculations {
  /// Creates an immutable calculations bundle for inventory metrics.
  const InventoryCalculations({
    required this.sessionsLeft,
    required this.estimatedEndDate,
    required this.averageVolumePerSession,
    required this.totalDailyVolume,
  });

  /// Computed sessions remaining (clamped to non-negative).
  final int sessionsLeft;

  /// Estimated date when inventory reaches zero, or null if not estimable.
  final DateTime? estimatedEndDate;

  /// Average mL per session across all active fluid schedules.
  final double averageVolumePerSession;

  /// Total mL needed per day across all active fluid schedules.
  final double totalDailyVolume;

  /// Copy with selectively overridden fields.
  InventoryCalculations copyWith({
    int? sessionsLeft,
    DateTime? estimatedEndDate,
    double? averageVolumePerSession,
    double? totalDailyVolume,
  }) {
    return InventoryCalculations(
      sessionsLeft: sessionsLeft ?? this.sessionsLeft,
      estimatedEndDate: estimatedEndDate ?? this.estimatedEndDate,
      averageVolumePerSession:
          averageVolumePerSession ?? this.averageVolumePerSession,
      totalDailyVolume: totalDailyVolume ?? this.totalDailyVolume,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryCalculations &&
          runtimeType == other.runtimeType &&
          sessionsLeft == other.sessionsLeft &&
          estimatedEndDate == other.estimatedEndDate &&
          averageVolumePerSession == other.averageVolumePerSession &&
          totalDailyVolume == other.totalDailyVolume;

  @override
  int get hashCode => Object.hash(
        sessionsLeft,
        estimatedEndDate,
        averageVolumePerSession,
        totalDailyVolume,
      );

  @override
  String toString() {
    return 'InventoryCalculations('
        'sessionsLeft: $sessionsLeft, '
        'estimatedEndDate: $estimatedEndDate, '
        'averageVolumePerSession: $averageVolumePerSession, '
        'totalDailyVolume: $totalDailyVolume'
        ')';
  }
}
