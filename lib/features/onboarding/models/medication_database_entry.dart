import 'package:flutter/foundation.dart';
import 'package:hydracat/features/onboarding/models/brand_name.dart';
import 'package:hydracat/features/onboarding/models/medication_search_result.dart';
import 'package:hydracat/features/onboarding/models/search_alias.dart';

/// Immutable model representing a single medication entry from the CKD
/// medication database JSON file.
///
/// Each entry contains structured information about a veterinary CKD medication
/// including its name, form, strength, unit, and brand names.
@immutable
class MedicationDatabaseEntry {
  /// Creates a [MedicationDatabaseEntry] instance
  const MedicationDatabaseEntry({
    required this.name,
    required this.form,
    required this.strength,
    required this.unit,
    required this.route,
    required this.category,
    required this.brandNames,
    this.searchAliases,
  });

  /// Creates a [MedicationDatabaseEntry] from JSON data
  ///
  /// Supports both legacy format (brand_names as string) and new format
  /// (brand_names as array of objects) for backward compatibility.
  factory MedicationDatabaseEntry.fromJson(Map<String, dynamic> json) {
    return MedicationDatabaseEntry(
      name: json['name'] as String? ?? '',
      form: json['form'] as String? ?? '',
      strength: json['strength'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      route: json['route'] as String? ?? '',
      category: json['category'] as String? ?? '',
      brandNames: _parseBrandNames(json['brand_names']),
      searchAliases: _parseSearchAliases(json['search_aliases']),
    );
  }

  /// Parses brand_names field from JSON (handles both string and array)
  static List<BrandName> _parseBrandNames(dynamic brandData) {
    if (brandData == null) return [];

    if (brandData is String) {
      // Legacy format: "Cerenia" or "Cerenia, Prevomax"
      if (brandData.isEmpty) return [];

      final names = brandData.split(',').map((e) => e.trim()).toList();
      return names
          .asMap()
          .entries
          .map((entry) => BrandName.fromString(
                entry.value,
                isPrimary: entry.key == 0, // First one is primary
              ))
          .toList();
    } else if (brandData is List) {
      // New format: array of objects
      return brandData
          .map((item) => BrandName.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Parses search_aliases field from JSON (handles both string and array)
  static List<SearchAlias>? _parseSearchAliases(dynamic aliasData) {
    if (aliasData == null) return null;

    if (aliasData is String) {
      // Legacy format: comma-separated strings
      if (aliasData.isEmpty) return null;

      final aliases = aliasData.split(',').map((e) => e.trim()).toList();
      return aliases.map(SearchAlias.fromString).toList();
    } else if (aliasData is List) {
      // New format: array of objects
      return aliasData
          .map((item) => SearchAlias.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return null;
  }

  /// Generic medication name (e.g., "Benazepril")
  final String name;

  /// Medication form (e.g., "tablet", "powder", "liquid", "capsule",
  /// "oral_solution", "gel", "transdermal")
  final String form;

  /// Strength value (numeric value or "variable")
  final String strength;

  /// Measurement unit (e.g., "mg", "ml", "g", "mg/mL", "mcg")
  final String unit;

  /// Administration route (e.g., "oral", "transdermal")
  final String route;

  /// Medication category (e.g., "phosphate_binder", "ACE_inhibitor",
  /// "antiemetic", "appetite_stimulant")
  final String category;

  /// List of brand names with primary designation
  final List<BrandName> brandNames;

  /// Optional search aliases for common misspellings
  final List<SearchAlias>? searchAliases;

  /// Returns list of real brands (excluding placeholders like "Generic")
  List<BrandName> get realBrands {
    return brandNames.where((b) => b.isRealBrand).toList();
  }

  /// Returns true if this medication has any real brand names
  bool get hasRealBrands => realBrands.isNotEmpty;

  /// Returns the primary brand name, or null if none exists
  ///
  /// Primary brand is the most commonly recognized/used brand.
  /// Returns null if no brands exist or all brands are placeholders.
  String? get primaryBrandName {
    final primaryBrand = realBrands.where((b) => b.primary).firstOrNull;
    if (primaryBrand != null) {
      return primaryBrand.name;
    }
    // No primary brand found, return first real brand if available
    return realBrands.isNotEmpty ? realBrands.first.name : null;
  }

  /// Returns true if this medication has variable strength
  bool get hasVariableStrength {
    return strength.toLowerCase() == 'variable';
  }

  /// Returns lowercase concatenation of name, brand names, and aliases
  /// for searching
  ///
  /// Example: "benazepril fortekor" for searching both generic and brand names
  String get searchableText {
    final brandText = brandNames.map((b) => b.name.toLowerCase()).join(' ');
    final aliasText =
        searchAliases?.map((a) => a.text.toLowerCase()).join(' ') ?? '';
    return '${name.toLowerCase()} $brandText $aliasText'.trim();
  }

  /// Returns formatted display string based on search intent
  ///
  /// Examples:
  /// - Brand intent: "Cerenia (Maropitant) 16mg tablet"
  /// - Generic intent: "Maropitant 16mg tablet"
  /// - Ambiguous: "Cerenia (Maropitant) 16mg tablet" (defaults to brand-first)
  String getDisplayName(SearchIntent intent, {String? matchedBrand}) {
    final details = hasVariableStrength ? form : '$strength$unit $form';

    switch (intent) {
      case SearchIntent.brand:
        final brand = matchedBrand ?? primaryBrandName;
        if (brand != null && brand.toLowerCase() != name.toLowerCase()) {
          return '$brand ($name) $details';
        }
        return '$name $details';

      case SearchIntent.generic:
        return '$name $details';

      case SearchIntent.ambiguous:
        if (hasRealBrands) {
          return '${primaryBrandName!} ($name) $details';
        }
        return '$name $details';
    }
  }

  /// Returns formatted display string for UI (legacy compatibility)
  ///
  /// Defaults to generic-only format. Use getDisplayName() for intent-based.
  String get displayName => getDisplayName(SearchIntent.generic);

  /// Validates this entry and returns a list of validation error messages
  ///
  /// Returns an empty list if the entry is valid
  List<String> validate() {
    final errors = <String>[];

    // Validate name
    if (name.isEmpty) {
      errors.add('Name is required');
    }

    // Validate form
    const validForms = {
      'tablet',
      'powder',
      'liquid',
      'capsule',
      'oral_solution',
      'gel',
      'transdermal',
    };
    if (form.isEmpty) {
      errors.add('Form is required');
    } else if (!validForms.contains(form.toLowerCase())) {
      errors.add('Invalid form: "$form"');
    }

    // Validate strength
    if (strength.isEmpty) {
      errors.add('Strength is required');
    } else if (strength.toLowerCase() != 'variable') {
      // Try to parse as number
      if (double.tryParse(strength) == null) {
        errors.add('Strength must be numeric or "variable", got "$strength"');
      }
    }

    // Validate unit
    if (unit.isEmpty) {
      errors.add('Unit is required');
    }

    return errors;
  }

  /// Converts this entry to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'form': form,
      'strength': strength,
      'unit': unit,
      'route': route,
      'category': category,
      'brand_names': brandNames.map((b) => b.toJson()).toList(),
      if (searchAliases != null)
        'search_aliases': searchAliases!.map((a) => a.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MedicationDatabaseEntry &&
        other.name == name &&
        other.form == form &&
        other.strength == strength &&
        other.unit == unit &&
        other.route == route &&
        other.category == category &&
        _listEquals(other.brandNames, brandNames) &&
        _listEquals(other.searchAliases, searchAliases);
  }

  /// Helper for list equality comparison
  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      form,
      strength,
      unit,
      route,
      category,
      Object.hashAll(brandNames),
      searchAliases != null ? Object.hashAll(searchAliases!) : null,
    );
  }

  @override
  String toString() {
    return 'MedicationDatabaseEntry('
        'name: $name, '
        'form: $form, '
        'strength: $strength, '
        'unit: $unit, '
        'route: $route, '
        'category: $category, '
        'brandNames: $brandNames, '
        'searchAliases: $searchAliases'
        ')';
  }
}
