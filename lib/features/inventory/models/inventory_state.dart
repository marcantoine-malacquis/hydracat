import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/inventory/models/fluid_inventory.dart';
import 'package:intl/intl.dart';

/// UI state for the fluid inventory screen with computed display values.
@immutable
class InventoryState {
  /// Creates UI-ready inventory state with computed display values.
  const InventoryState({
    required this.inventory,
    required this.sessionsLeft,
    required this.estimatedEndDate,
    required this.displayVolume,
    required this.displayPercentage,
    required this.isNegative,
    required this.overageVolume,
  });

  /// Raw inventory document.
  final FluidInventory inventory;

  /// Computed sessions remaining based on current schedules.
  final int sessionsLeft;

  /// Estimated date when inventory reaches zero, or null if not estimable.
  final DateTime? estimatedEndDate;

  /// Non-negative volume to display (clamped from inventory.remainingVolume).
  final double displayVolume;

  /// Normalized percentage (0.0 - 1.0) for the progress bar.
  final double displayPercentage;

  /// True when remainingVolume is below zero.
  final bool isNegative;

  /// Absolute overdrawn volume when inventory is negative.
  final double overageVolume;

  static final NumberFormat _volumeFormat = NumberFormat.decimalPattern();

  /// Human-readable volume text (e.g., "2,350 mL").
  String get displayVolumeText => '${_volumeFormat.format(displayVolume)} mL';

  /// Percentage text (e.g., "47%").
  String get displayPercentageText {
    final pct = (displayPercentage * 100).clamp(0, 100);
    return '${pct.toStringAsFixed(0)}%';
  }

  /// Sessions left text with pluralization.
  String get sessionsLeftText =>
      '$sessionsLeft session${sessionsLeft == 1 ? '' : 's'}';

  /// Estimated end date text, or null when not available.
  String? get estimatedEndDateText => estimatedEndDate == null
      ? null
      : AppDateUtils.formatDate(estimatedEndDate!);

  /// Negative inventory warning text, or null if inventory is non-negative.
  String? get overageText => isNegative
      ? 'You have logged ${_volumeFormat.format(overageVolume)} mL while '
          'inventory was empty'
      : null;

  /// Copy with selectively overridden fields.
  InventoryState copyWith({
    FluidInventory? inventory,
    int? sessionsLeft,
    DateTime? estimatedEndDate,
    double? displayVolume,
    double? displayPercentage,
    bool? isNegative,
    double? overageVolume,
  }) {
    return InventoryState(
      inventory: inventory ?? this.inventory,
      sessionsLeft: sessionsLeft ?? this.sessionsLeft,
      estimatedEndDate: estimatedEndDate ?? this.estimatedEndDate,
      displayVolume: displayVolume ?? this.displayVolume,
      displayPercentage: displayPercentage ?? this.displayPercentage,
      isNegative: isNegative ?? this.isNegative,
      overageVolume: overageVolume ?? this.overageVolume,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryState &&
          runtimeType == other.runtimeType &&
          inventory == other.inventory &&
          sessionsLeft == other.sessionsLeft &&
          estimatedEndDate == other.estimatedEndDate &&
          displayVolume == other.displayVolume &&
          displayPercentage == other.displayPercentage &&
          isNegative == other.isNegative &&
          overageVolume == other.overageVolume;

  @override
  int get hashCode => Object.hash(
        inventory,
        sessionsLeft,
        estimatedEndDate,
        displayVolume,
        displayPercentage,
        isNegative,
        overageVolume,
      );

  @override
  String toString() {
    return 'InventoryState('
        'inventory: $inventory, '
        'sessionsLeft: $sessionsLeft, '
        'estimatedEndDate: $estimatedEndDate, '
        'displayVolume: $displayVolume, '
        'displayPercentage: $displayPercentage, '
        'isNegative: $isNegative, '
        'overageVolume: $overageVolume'
        ')';
  }
}
