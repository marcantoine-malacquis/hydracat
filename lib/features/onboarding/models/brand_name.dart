import 'package:flutter/foundation.dart';

/// Immutable model representing a brand name for a medication.
///
/// Each brand has a name and flags indicating if it's the primary brand
/// and if it's a placeholder (like "Generic", "Various", "Compounded").
@immutable
class BrandName {
  /// Creates a [BrandName] instance
  const BrandName({
    required this.name,
    required this.primary,
    this.isPlaceholder = false,
  });

  /// Creates a [BrandName] from JSON data
  factory BrandName.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final primary = json['primary'] as bool? ?? false;

    // Auto-detect placeholders
    final isPlaceholder = _isPlaceholderBrand(name);

    return BrandName(
      name: name,
      primary: primary,
      isPlaceholder: isPlaceholder,
    );
  }

  /// Creates a [BrandName] from a simple string (legacy support)
  ///
  /// Used for backward compatibility when parsing old format where
  /// brand_names was a comma-separated string
  factory BrandName.fromString(String name, {bool isPrimary = false}) {
    return BrandName(
      name: name.trim(),
      primary: isPrimary,
      isPlaceholder: _isPlaceholderBrand(name.trim()),
    );
  }

  /// Brand name (e.g., "Cerenia", "Fortekor")
  final String name;

  /// True if this is the primary/most commonly recognized brand
  final bool primary;

  /// True if this is a placeholder brand ("Generic", "Various", "Compounded")
  final bool isPlaceholder;

  /// Checks if a brand name is a placeholder (not a real brand)
  static bool _isPlaceholderBrand(String name) {
    final lowercaseName = name.toLowerCase();
    return lowercaseName == 'generic' ||
        lowercaseName == 'various' ||
        lowercaseName == 'compounded' ||
        lowercaseName.contains('generic') ||
        lowercaseName.contains('off-label');
  }

  /// Returns true if this is a real brand (not a placeholder)
  bool get isRealBrand => !isPlaceholder;

  /// Converts this brand to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'primary': primary,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BrandName &&
        other.name == name &&
        other.primary == primary &&
        other.isPlaceholder == isPlaceholder;
  }

  @override
  int get hashCode {
    return Object.hash(name, primary, isPlaceholder);
  }

  @override
  String toString() {
    return 'BrandName('
        'name: $name, '
        'primary: $primary, '
        'isPlaceholder: $isPlaceholder'
        ')';
  }
}
