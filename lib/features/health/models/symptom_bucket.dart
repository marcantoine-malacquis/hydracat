import 'package:flutter/foundation.dart';

/// Bucket model for symptom chart visualization
///
/// Represents aggregated symptom counts over a date range (day or month).
/// Used across all chart granularities (week, month, year views).
///
/// **Week view**: Each bucket represents a single day (`start == end`), with
/// `daysWithSymptom` entries of `0` or `1` per symptom for that day.
///
/// **Month view**: Each bucket represents a single
/// calendar day (`start == end`),
/// providing per-day granularity for daily "sticks" visualization.
///
/// **Year view**: Each bucket represents a calendar month, with counts
/// populated directly from monthly summary fields.
@immutable
class SymptomBucket {
  /// Creates a [SymptomBucket] instance
  ///
  /// Parameters:
  /// - [start]: Inclusive start date of the bucket
  /// - [end]: Inclusive end date of the bucket
  ///  (for day buckets, `start == end`)
  /// - [daysWithSymptom]: Map of symptom key → number of days in this bucket
  ///   where score > 0
  /// - [daysWithAnySymptoms]: Number of days in the bucket where any symptom
  ///   was present
  SymptomBucket({
    required this.start,
    required this.end,
    required Map<String, int> daysWithSymptom,
    required this.daysWithAnySymptoms,
  }) : _daysWithSymptom = Map.unmodifiable(daysWithSymptom);

  /// Factory constructor to create an empty multi-day bucket
  ///
  /// Creates a bucket for a date range with no symptoms. Useful for
  /// initializing buckets that will be populated by accumulating daily data.
  ///
  /// Example:
  /// ```dart
  /// final bucket = SymptomBucket.forRange(
  ///   start: DateTime(2025, 10, 1),
  ///   end: DateTime(2025, 10, 7),
  /// );
  /// ```
  factory SymptomBucket.forRange({
    required DateTime start,
    required DateTime end,
  }) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    return SymptomBucket(
      start: normalizedStart,
      end: normalizedEnd,
      daysWithSymptom: const {},
      daysWithAnySymptoms: 0,
    );
  }

  /// Factory constructor to create an empty single-day bucket
  ///
  /// Creates a bucket for a single day with no symptoms.
  ///
  /// Example:
  /// ```dart
  /// final bucket = SymptomBucket.empty(DateTime(2025, 10, 5));
  /// // start == end == Oct 5, 2025
  /// // daysWithSymptom == {}
  /// // daysWithAnySymptoms == 0
  /// ```
  factory SymptomBucket.empty(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return SymptomBucket(
      start: normalizedDate,
      end: normalizedDate,
      daysWithSymptom: const {},
      daysWithAnySymptoms: 0,
    );
  }

  /// Inclusive start date of the bucket
  final DateTime start;

  /// Inclusive end date of the bucket
  ///
  /// For single-day buckets (week view), `start == end`.
  final DateTime end;

  /// Map of symptom key → number of days in this bucket where score > 0
  ///
  /// Keys should match `SymptomType` constants (e.g., `SymptomType.vomiting`).
  /// Values represent the count of days within this bucket's date range where
  /// that symptom had a score > 0.
  Map<String, int> get daysWithSymptom => _daysWithSymptom;
  final Map<String, int> _daysWithSymptom;

  /// Number of days in the bucket where any symptom was present
  ///
  /// This is the count of days where `hasSymptoms == true` within the bucket's
  /// date range.
  final int daysWithAnySymptoms;

  /// Total symptom days across all symptoms in this bucket
  ///
  /// Computed as the sum of all values in `daysWithSymptom`. This represents
  /// the total number of symptom-day occurrences (a day can contribute multiple
  /// counts if multiple symptoms were present).
  int get totalSymptomDays => _daysWithSymptom.values.fold(0, (a, b) => a + b);

  /// Create a copy with updated fields
  ///
  /// Returns a new [SymptomBucket] with the same values except for the
  /// specified fields. Useful for functional-style bucket building.
  SymptomBucket copyWith({
    DateTime? start,
    DateTime? end,
    Map<String, int>? daysWithSymptom,
    int? daysWithAnySymptoms,
  }) {
    return SymptomBucket(
      start: start ?? this.start,
      end: end ?? this.end,
      daysWithSymptom: daysWithSymptom ?? _daysWithSymptom,
      daysWithAnySymptoms: daysWithAnySymptoms ?? this.daysWithAnySymptoms,
    );
  }

  @override
  String toString() {
    return 'SymptomBucket('
        'start: $start, '
        'end: $end, '
        'daysWithSymptom: $_daysWithSymptom, '
        'daysWithAnySymptoms: $daysWithAnySymptoms'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SymptomBucket &&
        other.start == start &&
        other.end == end &&
        _mapEquals(other._daysWithSymptom, _daysWithSymptom) &&
        other.daysWithAnySymptoms == daysWithAnySymptoms;
  }

  @override
  int get hashCode {
    return Object.hash(
      start,
      end,
      _mapHashCode(_daysWithSymptom),
      daysWithAnySymptoms,
    );
  }

  /// Helper to compute hash code for a map by value
  static int _mapHashCode(Map<String, int> map) {
    var hash = 0;
    for (final entry in map.entries) {
      hash ^= Object.hash(entry.key, entry.value);
    }
    return hash;
  }

  /// Helper to compare maps by value
  static bool _mapEquals(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
