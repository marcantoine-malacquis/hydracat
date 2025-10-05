import 'package:flutter/foundation.dart';

/// Cached summary of today's treatment logging activity
///
/// This cache mirrors the structure of the Firestore `treatmentSummaryDaily`
/// document but lives in SharedPreferences for instant access. It enables:
/// - Quick duplicate detection (has medication X been logged today?)
/// - Home screen adherence display (totals without Firestore reads)
/// - Logged status checks (show/hide quick-log button)
///
/// Cache is automatically invalidated at midnight (new day transition).
/// See DailyCacheService for persistence logic (implemented in Phase 2).
@immutable
class DailySummaryCache {
  /// Creates a [DailySummaryCache] instance
  const DailySummaryCache({
    required this.date,
    required this.medicationSessionCount,
    required this.fluidSessionCount,
    required this.medicationNames,
    required this.totalMedicationDosesGiven,
    required this.totalFluidVolumeGiven,
  });

  /// Creates an empty cache for the given date
  ///
  /// Use this when initializing a new day's cache with zero sessions.
  /// The date should be in format YYYY-MM-DD (e.g., "2025-10-05").
  factory DailySummaryCache.empty(String date) {
    return DailySummaryCache(
      date: date,
      medicationSessionCount: 0,
      fluidSessionCount: 0,
      medicationNames: const [],
      totalMedicationDosesGiven: 0,
      totalFluidVolumeGiven: 0,
    );
  }

  /// Creates a [DailySummaryCache] from JSON data
  factory DailySummaryCache.fromJson(Map<String, dynamic> json) {
    return DailySummaryCache(
      date: json['date'] as String,
      medicationSessionCount: json['medicationSessionCount'] as int,
      fluidSessionCount: json['fluidSessionCount'] as int,
      medicationNames: (json['medicationNames'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      totalMedicationDosesGiven:
          (json['totalMedicationDosesGiven'] as num).toDouble(),
      totalFluidVolumeGiven:
          (json['totalFluidVolumeGiven'] as num).toDouble(),
    );
  }

  /// Date of this cache in YYYY-MM-DD format (e.g., "2025-10-05")
  ///
  /// This is the primary cache validation field. When the current date
  /// differs from this value, the cache is considered expired and should
  /// be discarded.
  final String date;

  /// Number of medication sessions logged today
  ///
  /// Used for:
  /// - Logged status detection (has any medication been logged?)
  /// - Home screen daily progress display
  final int medicationSessionCount;

  /// Number of fluid therapy sessions logged today
  ///
  /// Used for:
  /// - Logged status detection (has fluid therapy been logged?)
  /// - Home screen daily progress display
  final int fluidSessionCount;

  /// Names of medications logged today (unique list)
  ///
  /// Used for duplicate detection. When user attempts quick-log for
  /// medication X, check if it exists in this list to show "already logged"
  /// warning and offer to update instead.
  final List<String> medicationNames;

  /// Total medication doses given today (sum of all dosageGiven)
  ///
  /// Used for home screen adherence display. This is the sum of all
  /// `dosageGiven` values from today's medication sessions.
  final double totalMedicationDosesGiven;

  /// Total fluid volume given today in ml (sum of all volumeGiven)
  ///
  /// Used for home screen adherence display. This is the sum of all
  /// `volumeGiven` values from today's fluid therapy sessions.
  final double totalFluidVolumeGiven;

  // Domain validation and queries

  /// Check if this cache is valid for the given date
  ///
  /// Pure validation function with no side effects. Returns true if the
  /// cache's date matches the target date, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final cache = DailySummaryCache(date: '2025-10-05', ...);
  /// cache.isValidFor('2025-10-05'); // true
  /// cache.isValidFor('2025-10-06'); // false - cache is expired
  /// ```
  bool isValidFor(String targetDate) {
    return date == targetDate;
  }

  /// Check if any sessions have been logged today
  ///
  /// Returns true if at least one medication OR fluid session exists.
  /// Used to determine if quick-log button should be shown.
  bool get hasAnySessions =>
      medicationSessionCount > 0 || fluidSessionCount > 0;

  /// Check if a specific medication has been logged today
  ///
  /// Used for duplicate detection in quick-log flow. If true, show
  /// "already logged" warning and offer to update instead of create.
  bool hasMedicationLogged(String medicationName) =>
      medicationNames.contains(medicationName);

  /// Check if any fluid therapy has been logged today
  ///
  /// Returns true if at least one fluid session exists. Used to show/hide
  /// fluid quick-log button.
  bool get hasFluidSession => fluidSessionCount > 0;

  /// Check if any medication has been logged today
  ///
  /// Returns true if at least one medication session exists. Used to show/hide
  /// medication quick-log button.
  bool get hasMedicationSession => medicationSessionCount > 0;

  // Immutability support

  /// Creates a copy with updated session data
  ///
  /// This is the primary method for incrementally updating the cache as
  /// sessions are logged throughout the day. It handles:
  /// - Incrementing session counts
  /// - Adding medication names (with duplicate prevention)
  /// - Accumulating totals
  ///
  /// Example:
  /// ```dart
  /// // Log a medication session
  /// final updated = cache.copyWithSession(
  ///   medicationName: 'Benazepril',
  ///   dosageGiven: 2.5,
  /// );
  ///
  /// // Log a fluid session
  /// final updated = cache.copyWithSession(
  ///   volumeGiven: 150.0,
  /// );
  /// ```
  DailySummaryCache copyWithSession({
    String? medicationName,
    double? dosageGiven,
    double? volumeGiven,
  }) {
    return DailySummaryCache(
      date: date,
      medicationSessionCount: medicationName != null
          ? medicationSessionCount + 1
          : medicationSessionCount,
      fluidSessionCount:
          volumeGiven != null ? fluidSessionCount + 1 : fluidSessionCount,
      medicationNames: medicationName != null &&
              !medicationNames.contains(medicationName)
          ? [...medicationNames, medicationName]
          : medicationNames,
      totalMedicationDosesGiven:
          totalMedicationDosesGiven + (dosageGiven ?? 0.0),
      totalFluidVolumeGiven: totalFluidVolumeGiven + (volumeGiven ?? 0.0),
    );
  }

  /// Creates a copy of this [DailySummaryCache] with the given fields replaced
  ///
  /// Use this for general updates when you need to replace specific fields.
  /// For adding sessions, prefer [copyWithSession] instead.
  DailySummaryCache copyWith({
    String? date,
    int? medicationSessionCount,
    int? fluidSessionCount,
    List<String>? medicationNames,
    double? totalMedicationDosesGiven,
    double? totalFluidVolumeGiven,
  }) {
    return DailySummaryCache(
      date: date ?? this.date,
      medicationSessionCount:
          medicationSessionCount ?? this.medicationSessionCount,
      fluidSessionCount: fluidSessionCount ?? this.fluidSessionCount,
      medicationNames: medicationNames ?? this.medicationNames,
      totalMedicationDosesGiven:
          totalMedicationDosesGiven ?? this.totalMedicationDosesGiven,
      totalFluidVolumeGiven:
          totalFluidVolumeGiven ?? this.totalFluidVolumeGiven,
    );
  }

  // JSON serialization

  /// Converts [DailySummaryCache] to JSON for SharedPreferences storage
  Map<String, dynamic> toJson() => {
        'date': date,
        'medicationSessionCount': medicationSessionCount,
        'fluidSessionCount': fluidSessionCount,
        'medicationNames': medicationNames,
        'totalMedicationDosesGiven': totalMedicationDosesGiven,
        'totalFluidVolumeGiven': totalFluidVolumeGiven,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DailySummaryCache &&
        other.date == date &&
        other.medicationSessionCount == medicationSessionCount &&
        other.fluidSessionCount == fluidSessionCount &&
        listEquals(other.medicationNames, medicationNames) &&
        other.totalMedicationDosesGiven == totalMedicationDosesGiven &&
        other.totalFluidVolumeGiven == totalFluidVolumeGiven;
  }

  @override
  int get hashCode {
    return Object.hash(
      date,
      medicationSessionCount,
      fluidSessionCount,
      Object.hashAll(medicationNames),
      totalMedicationDosesGiven,
      totalFluidVolumeGiven,
    );
  }

  @override
  String toString() {
    return 'DailySummaryCache('
        'date: $date, '
        'medicationSessionCount: $medicationSessionCount, '
        'fluidSessionCount: $fluidSessionCount, '
        'medicationNames: $medicationNames, '
        'totalMedicationDosesGiven: $totalMedicationDosesGiven, '
        'totalFluidVolumeGiven: $totalFluidVolumeGiven'
        ')';
  }
}
