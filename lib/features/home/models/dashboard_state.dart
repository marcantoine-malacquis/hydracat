import 'package:flutter/foundation.dart';
import 'package:hydracat/features/home/models/pending_fluid_treatment.dart';
import 'package:hydracat/features/home/models/pending_treatment.dart';

/// Sentinel value for [DashboardState.copyWith] to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

/// Immutable UI state container for the dashboard's pending treatments section.
@immutable
class DashboardState {
  /// Creates a [DashboardState]
  const DashboardState({
    required this.pendingMedications,
    this.pendingFluid,
    this.isLoading = false,
    this.errorMessage,
  });

  /// List of pending medication treatments for today
  final List<PendingTreatment> pendingMedications;

  /// Pending fluid treatment for today (if any)
  final PendingFluidTreatment? pendingFluid;

  /// Whether dashboard data is currently loading
  final bool isLoading;

  /// Error message if dashboard data failed to load
  final String? errorMessage;

  /// Whether there are any pending treatments (medications or fluid)
  bool get hasPendingTreatments =>
      pendingMedications.isNotEmpty || pendingFluid != null;

  /// Total count of pending treatment items
  int get totalPendingCount =>
      pendingMedications.length + (pendingFluid != null ? 1 : 0);

  /// Creates a copy with the given fields replaced
  DashboardState copyWith({
    List<PendingTreatment>? pendingMedications,
    Object? pendingFluid = _undefined,
    bool? isLoading,
    Object? errorMessage = _undefined,
  }) {
    return DashboardState(
      pendingMedications: pendingMedications ?? this.pendingMedications,
      pendingFluid: pendingFluid == _undefined 
          ? this.pendingFluid 
          : pendingFluid as PendingFluidTreatment?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _undefined 
          ? this.errorMessage 
          : errorMessage as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DashboardState &&
            listEquals(other.pendingMedications, pendingMedications) &&
            other.pendingFluid == pendingFluid &&
            other.isLoading == isLoading &&
            other.errorMessage == errorMessage);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(pendingMedications),
    pendingFluid,
    isLoading,
    errorMessage,
  );
}
