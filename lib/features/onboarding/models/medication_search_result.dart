import 'package:flutter/foundation.dart';
import 'package:hydracat/features/onboarding/models/medication_database_entry.dart';

/// Search intent detected from user's query
///
/// Determines how to display medication in search results based on
/// whether user searched for brand name, generic name, or both.
enum SearchIntent {
  /// User searched for a brand name (e.g., "Cerenia")
  /// Display: "Cerenia (Maropitant) 16mg tablet"
  brand,

  /// User searched for a generic name (e.g., "Maropitant")
  /// Display: "Maropitant 16mg tablet"
  generic,

  /// Query matches both brand and generic, or intent is unclear
  /// Display: Default to full format with brand
  ambiguous,
}

/// Result from medication search including the medication entry and context
///
/// Encapsulates not just the matched medication, but also the detected
/// search intent, which specific brand matched (if any), and relevance score.
@immutable
class MedicationSearchResult {
  /// Creates a [MedicationSearchResult] instance
  const MedicationSearchResult({
    required this.medication,
    required this.intent,
    required this.relevanceScore,
    this.matchedBrand,
  });

  /// The medication database entry that matched the search
  final MedicationDatabaseEntry medication;

  /// Detected search intent based on what user searched for
  final SearchIntent intent;

  /// Which specific brand name matched (if intent is brand)
  ///
  /// Null if intent is generic or if no specific brand matched
  final String? matchedBrand;

  /// Relevance score for ranking results (higher = more relevant)
  ///
  /// Calculated based on match type:
  /// - Exact matches: 1000+
  /// - Starts with: 500-700
  /// - Contains: 200-400
  /// - Word boundary: 100-150
  final int relevanceScore;

  /// Returns the display name based on search intent
  ///
  /// Delegates to medication's getDisplayName with the detected intent
  /// and matched brand for contextual display
  String get displayName {
    return medication.getDisplayName(intent, matchedBrand: matchedBrand);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MedicationSearchResult &&
        other.medication == medication &&
        other.intent == intent &&
        other.matchedBrand == matchedBrand &&
        other.relevanceScore == relevanceScore;
  }

  @override
  int get hashCode {
    return Object.hash(medication, intent, matchedBrand, relevanceScore);
  }

  @override
  String toString() {
    return 'MedicationSearchResult('
        'medication: ${medication.name}, '
        'intent: $intent, '
        'matchedBrand: $matchedBrand, '
        'score: $relevanceScore'
        ')';
  }
}
