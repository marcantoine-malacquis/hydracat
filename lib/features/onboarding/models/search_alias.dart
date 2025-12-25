import 'package:flutter/foundation.dart';

/// Immutable model representing a search alias for medication names.
///
/// Search aliases help users find medications even when they misspell
/// brand or generic names. Each alias has text and a type indicating
/// whether it's an alias for a brand name or generic name.
@immutable
class SearchAlias {
  /// Creates a [SearchAlias] instance
  const SearchAlias({
    required this.text,
    required this.type,
  });

  /// Creates a [SearchAlias] from JSON data
  factory SearchAlias.fromJson(Map<String, dynamic> json) {
    return SearchAlias(
      text: json['text'] as String? ?? '',
      type: json['type'] as String? ?? 'generic',
    );
  }

  /// Creates a [SearchAlias] from a simple string with default type
  ///
  /// Used for backward compatibility when parsing old format
  factory SearchAlias.fromString(String text, {String type = 'generic'}) {
    return SearchAlias(
      text: text.trim(),
      type: type,
    );
  }

  /// Alias text (e.g., "serenia" for "Cerenia", "mirtazapine" for "Mirataz")
  final String text;

  /// Type of alias: "brand" or "generic"
  ///
  /// Indicates whether this alias represents a misspelling of a brand name
  /// or generic name. This affects search intent detection.
  final String type;

  /// Returns true if this is a brand alias
  bool get isBrandAlias => type.toLowerCase() == 'brand';

  /// Returns true if this is a generic alias
  bool get isGenericAlias => type.toLowerCase() == 'generic';

  /// Converts this alias to JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'type': type,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SearchAlias && other.text == text && other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(text, type);
  }

  @override
  String toString() {
    return 'SearchAlias(text: $text, type: $type)';
  }
}
