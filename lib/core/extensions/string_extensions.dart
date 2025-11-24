/// Extension methods for String class providing utility functions.
library;
// The library directive may trigger deprecated_member_use warnings
// in some Dart versions.
// ignore_for_file: deprecated_member_use

/// Extension providing utility methods and getters for String operations.
extension StringExtensions on String {
  /// Capitalize first letter of string
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize first letter of each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Check if string is valid email
  bool get isEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Check if string is valid phone number
  bool get isPhoneNumber {
    final phoneRegex = RegExp(r'^\+?[\d\s-\(\)]+$');
    return phoneRegex.hasMatch(this);
  }

  /// Remove all whitespace from string
  String get removeWhitespace {
    return replaceAll(RegExp(r'\s+'), '');
  }

  /// Truncate string to specified length
  String truncate(int length, {String suffix = '...'}) {
    if (this.length <= length) return this;
    return '${substring(0, length)}$suffix';
  }

  /// Check if string contains only digits
  bool get isNumeric {
    return RegExp(r'^\d+$').hasMatch(this);
  }

  /// Convert string to double, returns null if invalid
  double? toDoubleOrNull() {
    try {
      return double.parse(this);
    } on FormatException {
      return null;
    }
  }

  /// Convert string to int, returns null if invalid
  int? toIntOrNull() {
    try {
      return int.parse(this);
    } on FormatException {
      return null;
    }
  }

  /// Check if string is empty or only whitespace
  bool get isBlank {
    return trim().isEmpty;
  }

  /// Check if string is not empty and not only whitespace
  bool get isNotBlank {
    return !isBlank;
  }
}
