/// Riverpod providers for medication database service
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/onboarding/models/medication_search_result.dart';
import 'package:hydracat/shared/services/medication_database_service.dart';

/// Provider for MedicationDatabaseService instance
///
/// Creates a singleton service and initializes it asynchronously.
/// The service will load the medication database from assets on first access.
final medicationDatabaseServiceProvider =
    Provider<MedicationDatabaseService>((ref) {
  final service = MedicationDatabaseService()
    // Initialize service asynchronously (don't block provider creation)
    ..initialize();
  return service;
});

/// Provider for medication database initialization state
///
/// Returns true when the database has been loaded and is ready for queries.
/// Use this to show loading indicators or handle initialization errors.
final medicationDatabaseInitializedProvider = Provider<bool>((ref) {
  final service = ref.watch(medicationDatabaseServiceProvider);
  return service.isInitialized;
});

/// Provider for searching medications by query string with intent detection
///
/// Returns a list of search results including the medication and detected
/// search intent (brand vs generic). Results are cached automatically by
/// Riverpod for performance.
///
/// Search intent affects display format:
/// - Brand intent: "Cerenia (Maropitant) 16mg tablet"
/// - Generic intent: "Maropitant 16mg tablet"
///
/// Returns empty list if:
/// - Database is not initialized yet
/// - Query is empty or whitespace only
/// - No medications match the query
///
/// Example:
/// ```dart
/// final results = ref.watch(medicationSearchProvider('cere'));
/// for (final result in results) {
///   print(result.displayName); // "Cerenia (Maropitant) 16mg tablet"
/// }
/// ```
final Provider<List<MedicationSearchResult>> Function(String)
    medicationSearchProvider = Provider.family<
    List<MedicationSearchResult>,
    String>((ref, query) {
  final service = ref.watch(medicationDatabaseServiceProvider);

  if (!service.isInitialized) {
    return []; // Not ready yet
  }

  return service.searchMedications(query);
});
