import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/features/onboarding/models/medication_database_entry.dart';
import 'package:hydracat/features/onboarding/models/medication_search_result.dart';

/// Service for loading and searching the CKD medication database
///
/// Loads the medication database from a local JSON asset file once on
/// initialization and caches it in memory for the app lifetime.
/// Provides fast, offline search functionality with relevance sorting.
class MedicationDatabaseService {
  /// Creates a [MedicationDatabaseService] instance
  ///
  /// The [assetBundle] parameter is optional and defaults to [rootBundle].
  /// It can be overridden for testing purposes.
  MedicationDatabaseService({AssetBundle? assetBundle})
      : _assetBundle = assetBundle ?? rootBundle;

  /// Path to the medication database JSON file
  static const String _databasePath =
      'assets/medication_db/ckd_medications_eu_us.json';

  /// Maximum number of search results to return
  static const int _maxResults = 10;

  /// Asset bundle for loading the JSON file
  final AssetBundle _assetBundle;

  /// Cached list of medications loaded from the database
  List<MedicationDatabaseEntry>? _medications;

  /// Flag indicating whether the database has been initialized
  bool _isInitialized = false;

  /// Returns true if the database has been initialized
  bool get isInitialized => _isInitialized;

  /// Returns the total count of loaded medications
  ///
  /// Returns 0 if the database is not initialized or failed to load
  int get medicationCount => _medications?.length ?? 0;

  /// Initializes the service by loading and parsing the medication database
  ///
  /// This method can be called multiple times safely - it will only load
  /// the database once. If loading fails, the service will continue to work
  /// with an empty database (allowing manual entry only).
  ///
  /// Errors are logged but not thrown to ensure graceful degradation.
  Future<void> initialize() async {
    if (_isInitialized) return; // Already loaded

    try {
      final jsonString = await _assetBundle.loadString(_databasePath);
      final jsonList = json.decode(jsonString) as List<dynamic>;

      _medications = jsonList
          .map(
            (json) => MedicationDatabaseEntry.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .where((entry) => entry.validate().isEmpty) // Filter invalid entries
          .toList();

      _isInitialized = true;

      debugPrint(
        'MedicationDatabaseService: Loaded ${_medications!.length} '
        'medications',
      );
    } on Exception catch (e) {
      // Log error but don't throw - graceful degradation
      // App continues to work with manual entry only
      debugPrint('Failed to load medication database: $e');
      _medications = [];
      _isInitialized = true; // Mark as initialized to prevent retry loops
    }
  }

  /// Searches for medications matching the given query with intent detection
  ///
  /// Performs case-insensitive matching on medication name, brand names,
  /// and search aliases. Results include detected search intent (brand vs
  /// generic) which determines display format.
  ///
  /// Search intent detection:
  /// - Brand intent: Query matches brand name better than generic
  /// - Generic intent: Query matches generic name better than brand
  /// - Ambiguous: Query matches both equally (returns both variants)
  ///
  /// Ambiguous matches produce multiple results:
  /// When a query matches both brand and generic names with equal scores
  /// (e.g., "mir" matches both "Mirataz" and "Mirtazapine" as "starts with"),
  /// the service returns TWO results for the same medication - one with brand
  /// intent and one with generic intent. This allows users to see both display
  /// formats and choose their preferred terminology.
  ///
  /// Relevance scoring (higher = better):
  /// - Exact match: 1000+ points
  /// - Starts with: 500-700 points
  /// - Contains: 200-400 points
  /// - Word boundary: 100-150 points
  ///
  /// Returns empty list if:
  /// - Database is not initialized
  /// - Query is empty or whitespace only
  /// - No medications match the query
  ///
  /// Results are limited to [_maxResults] entries (note: ambiguous matches
  /// count as multiple entries toward this limit).
  ///
  /// Example:
  /// ```dart
  /// final results = service.searchMedications('mir');
  /// // Returns: [
  /// //   MedicationSearchResult(intent: brand, "Mirataz (Mirtazapine)..."),
  /// //   MedicationSearchResult(intent: generic, "Mirtazapine..."),
  /// // ]
  /// ```
  List<MedicationSearchResult> searchMedications(String query) {
    if (!_isInitialized || query.trim().isEmpty) {
      return [];
    }

    final normalizedQuery = query.toLowerCase().trim();
    final results = <_ScoredResult>[];

    for (final medication in _medications!) {
      final score = _calculateRelevance(medication, normalizedQuery);

      if (score > 0) {
        final isAmbiguous = _isAmbiguousMatch(medication, normalizedQuery);

        if (isAmbiguous) {
          // Ambiguous match: create both brand and generic results
          // This allows users to see both display formats when the query
          // matches brand and generic names equally well (e.g., "mir" for
          // both "Mirataz" and "Mirtazapine")

          // Find which specific brand matched
          final matchedBrand = medication.realBrands
              .firstWhere(
                (b) => b.name.toLowerCase().contains(normalizedQuery),
                orElse: () => medication.realBrands.first,
              )
              .name;

          // Add brand version and generic version
          results
            ..add(_ScoredResult(
              result: MedicationSearchResult(
                medication: medication,
                intent: SearchIntent.brand,
                matchedBrand: matchedBrand,
                relevanceScore: score,
              ),
              score: score,
            ))
            ..add(_ScoredResult(
              result: MedicationSearchResult(
                medication: medication,
                intent: SearchIntent.generic,
                relevanceScore: score,
              ),
              score: score,
            ));
        } else {
          // Unambiguous match: use detected intent
          final intent = _detectIntent(medication, normalizedQuery);
          String? matchedBrand;

          // Find which specific brand matched (if brand intent)
          if (intent == SearchIntent.brand) {
            matchedBrand = medication.realBrands
                .firstWhere(
                  (b) => b.name.toLowerCase().contains(normalizedQuery),
                  orElse: () => medication.realBrands.isNotEmpty
                      ? medication.realBrands.first
                      : medication.brandNames.first,
                )
                .name;
          }

          results.add(_ScoredResult(
            result: MedicationSearchResult(
              medication: medication,
              intent: intent,
              matchedBrand: matchedBrand,
              relevanceScore: score,
            ),
            score: score,
          ));
        }
      }
    }

    // Sort by relevance (descending), then alphabetically for ties
    results.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);
      if (scoreComparison != 0) return scoreComparison;
      // Secondary sort: alphabetical by medication name
      return a.result.medication.name.compareTo(b.result.medication.name);
    });

    return results.take(_maxResults).map((r) => r.result).toList();
  }

  /// Detects search intent based on match quality comparison
  ///
  /// Decision logic:
  /// 1. Calculates best match score for generic name
  /// 2. Calculates best match score for all brand names
  /// 3. Calculates best match score for aliases (with type tracking)
  /// 4. Compares scores to determine if brand or generic intent
  ///
  /// If brand/brand-alias scores higher → Brand intent
  /// If generic/generic-alias scores higher → Generic intent
  /// If equal → Generic intent (default)
  ///
  /// This ensures users see what they're actually typing - if "Mirat"
  /// is a better match for "Mirataz" than "Mirtazapine", show the brand.
  SearchIntent _detectIntent(
    MedicationDatabaseEntry medication,
    String query,
  ) {
    // Calculate best score for generic name
    final genericScore = _calculateMatchScore(medication.name, query);

    // Calculate best score for brand names (only real brands)
    var bestBrandScore = 0;
    for (final brand in medication.realBrands) {
      final score = _calculateMatchScore(brand.name, query);
      if (score > bestBrandScore) {
        bestBrandScore = score;
      }
    }

    // Calculate best score for aliases and track type
    var bestBrandAliasScore = 0;
    var bestGenericAliasScore = 0;

    if (medication.searchAliases != null) {
      for (final alias in medication.searchAliases!) {
        final score = _calculateMatchScore(alias.text, query);
        if (alias.type == 'brand' && score > bestBrandAliasScore) {
          bestBrandAliasScore = score;
        } else if (alias.type == 'generic' && score > bestGenericAliasScore) {
          bestGenericAliasScore = score;
        }
      }
    }

    // Compare best scores for brand vs generic (including aliases)
    final bestBrandRelatedScore = bestBrandScore > bestBrandAliasScore
        ? bestBrandScore
        : bestBrandAliasScore;

    final bestGenericRelatedScore = genericScore > bestGenericAliasScore
        ? genericScore
        : bestGenericAliasScore;

    // Determine intent based on which scored higher
    if (bestBrandRelatedScore > bestGenericRelatedScore) {
      return SearchIntent.brand;
    } else {
      return SearchIntent.generic;
    }
  }

  /// Detects if a search query produces an ambiguous match
  ///
  /// Returns true when both brand and generic names match equally well,
  /// indicating that both display formats should be shown to the user.
  ///
  /// Decision logic:
  /// 1. Calculates best match score for generic name (including aliases)
  /// 2. Calculates best match score for brand names (including aliases)
  /// 3. Returns true if scores are equal and both > 0
  /// 4. Returns false if brand and generic names are identical
  /// (no need for both)
  ///
  /// Example: "mir" matches both "Mirtazapine" and "Mirataz" equally
  /// (both start with "mir"), so this is ambiguous.
  bool _isAmbiguousMatch(
    MedicationDatabaseEntry medication,
    String query,
  ) {
    // Only check medications that have real brands
    if (!medication.hasRealBrands) return false;

    // Calculate best score for generic name
    final genericScore = _calculateMatchScore(medication.name, query);

    // Calculate best score for brand names (only real brands)
    var bestBrandScore = 0;
    String? bestMatchingBrand;
    for (final brand in medication.realBrands) {
      final score = _calculateMatchScore(brand.name, query);
      if (score > bestBrandScore) {
        bestBrandScore = score;
        bestMatchingBrand = brand.name;
      }
    }

    // Calculate best score for aliases and track type
    var bestBrandAliasScore = 0;
    var bestGenericAliasScore = 0;

    if (medication.searchAliases != null) {
      for (final alias in medication.searchAliases!) {
        final score = _calculateMatchScore(alias.text, query);
        if (alias.type == 'brand' && score > bestBrandAliasScore) {
          bestBrandAliasScore = score;
        } else if (alias.type == 'generic' && score > bestGenericAliasScore) {
          bestGenericAliasScore = score;
        }
      }
    }

    // Compare best scores for brand vs generic (including aliases)
    final bestBrandRelatedScore = bestBrandScore > bestBrandAliasScore
        ? bestBrandScore
        : bestBrandAliasScore;

    final bestGenericRelatedScore = genericScore > bestGenericAliasScore
        ? genericScore
        : bestGenericAliasScore;

    // Not ambiguous if scores are different
    if (bestBrandRelatedScore != bestGenericRelatedScore) return false;

    // Not ambiguous if either score is 0
    if (bestBrandRelatedScore == 0 || bestGenericRelatedScore == 0) {
      return false;
    }

    // Not ambiguous if the brand name and generic name are the same
    // (e.g., "Cerenia" as both brand and generic name)
    if (bestMatchingBrand != null &&
        bestMatchingBrand.toLowerCase() == medication.name.toLowerCase()) {
      return false;
    }

    // Ambiguous: scores are equal, both > 0, and names are different
    return true;
  }

  /// Calculates match score for a specific string against the query
  ///
  /// Scoring tiers (aligned with _calculateRelevance):
  /// - Exact: 1000 points
  /// - Starts with: 600 points
  /// - Contains: 300 points
  /// - Word boundary starts: 150 points
  /// - Word boundary contains: 100 points
  ///
  /// Returns 0 if no match.
  int _calculateMatchScore(String text, String query) {
    final lowercaseText = text.toLowerCase();

    // Exact match
    if (lowercaseText == query) return 1000;

    // Starts with
    if (lowercaseText.startsWith(query)) return 600;

    // Contains
    if (lowercaseText.contains(query)) return 300;

    // Word boundary
    final words = lowercaseText.split(RegExp(r'[\s\-]'));
    for (final word in words) {
      if (word.startsWith(query)) return 150;
      if (word.contains(query)) return 100;
    }

    return 0; // No match
  }

  /// Calculate relevance score for ranking results
  ///
  /// Scoring tiers:
  /// - TIER 1 (Exact): 900-1100 points
  /// - TIER 2 (Starts with): 550-700 points
  /// - TIER 3 (Contains): 250-400 points
  /// - TIER 4 (Word boundary): 100-150 points
  ///
  /// Primary brands rank higher than secondary brands within each tier.
  int _calculateRelevance(MedicationDatabaseEntry medication, String query) {
    final genericName = medication.name.toLowerCase();

    // TIER 1: Exact matches (900-1100 points)
    if (genericName == query) return 1000;

    for (final brand in medication.realBrands) {
      if (brand.name.toLowerCase() == query) {
        return brand.primary ? 1100 : 1050;
      }
    }

    // Check aliases for exact match
    if (medication.searchAliases != null) {
      for (final alias in medication.searchAliases!) {
        if (alias.text.toLowerCase() == query) return 900;
      }
    }

    // TIER 2: Starts with query (550-700 points)
    for (final brand in medication.realBrands) {
      if (brand.name.toLowerCase().startsWith(query)) {
        return brand.primary ? 700 : 650;
      }
    }

    if (genericName.startsWith(query)) return 600;

    if (medication.searchAliases != null) {
      for (final alias in medication.searchAliases!) {
        if (alias.text.toLowerCase().startsWith(query)) return 550;
      }
    }

    // TIER 3: Contains query (250-400 points)
    for (final brand in medication.realBrands) {
      if (brand.name.toLowerCase().contains(query)) {
        return brand.primary ? 400 : 350;
      }
    }

    if (genericName.contains(query)) return 300;

    if (medication.searchAliases != null) {
      for (final alias in medication.searchAliases!) {
        if (alias.text.toLowerCase().contains(query)) return 250;
      }
    }

    // TIER 4: Word boundary matches (100-150 points)
    final words = genericName.split(RegExp(r'[\s\-]'));
    for (final word in words) {
      if (word.startsWith(query)) return 150;
      if (word.contains(query)) return 100;
    }

    return 0; // No match
  }

  /// Finds a medication by exact name match (case-insensitive)
  ///
  /// Returns the first medication with a matching name, or null if not found.
  ///
  /// Example:
  /// ```dart
  /// final med = service.getMedicationByName('Benazepril');
  /// // Returns: MedicationDatabaseEntry for Benazepril
  /// ```
  MedicationDatabaseEntry? getMedicationByName(String name) {
    if (!_isInitialized) return null;

    final normalizedName = name.toLowerCase();
    for (final medication in _medications!) {
      if (medication.name.toLowerCase() == normalizedName) {
        return medication;
      }
    }
    return null; // Not found
  }
}

/// Helper class for scoring search results
class _ScoredResult {
  const _ScoredResult({
    required this.result,
    required this.score,
  });

  final MedicationSearchResult result;
  final int score;
}
