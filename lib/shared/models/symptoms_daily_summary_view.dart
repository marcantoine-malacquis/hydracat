import 'package:flutter/foundation.dart';

/// Represents a single symptom logged for a day
@immutable
class SymptomItem {
  /// Creates a symptom item with label and descriptor
  const SymptomItem({
    required this.symptomKey,
    required this.label,
    required this.descriptor,
  });

  /// The symptom type key (e.g., "vomiting", "diarrhea")
  final String symptomKey;

  /// User-facing label (e.g., "Vomiting", "Diarrhea")
  final String label;

  /// Formatted descriptor (e.g., "3 episodes", "Soft", "Visible swelling")
  final String descriptor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomItem &&
          runtimeType == other.runtimeType &&
          symptomKey == other.symptomKey &&
          label == other.label &&
          descriptor == other.descriptor;

  @override
  int get hashCode => Object.hash(symptomKey, label, descriptor);
}

/// Lightweight view model for a day's symptom summary
@immutable
class SymptomsDailySummaryView {
  /// Creates a view model for a day's symptoms
  const SymptomsDailySummaryView({
    required this.symptoms,
    required this.isToday,
  });

  /// List of symptoms logged for this day
  final List<SymptomItem> symptoms;

  /// Whether the represented day is today
  final bool isToday;

  /// Number of symptoms logged
  int get symptomCount => symptoms.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomsDailySummaryView &&
          runtimeType == other.runtimeType &&
          listEquals(symptoms, other.symptoms) &&
          isToday == other.isToday;

  @override
  int get hashCode => Object.hash(symptoms, isToday);
}
