import 'package:flutter/foundation.dart';

/// Types of validation errors for different categorization
enum ValidationErrorType {
  /// Required field is missing
  missing,

  /// Field value is invalid (e.g., negative age)
  invalid,

  /// Field is incomplete (e.g., no medications added)
  incomplete,

  /// Field values are inconsistent (e.g., diagnosis date after birth date)
  inconsistent,

  /// Duplicate entry detected (e.g., session already logged)
  duplicate,
}

/// Represents a single validation error with actionable information
@immutable
class ValidationError {
  /// Creates a [ValidationError] instance
  const ValidationError({
    required this.message,
    this.fieldName,
    this.type = ValidationErrorType.missing,
    this.suggestedAction,
    this.actionRoute,
  });

  /// User-friendly error message
  final String message;

  /// Name of the field that has the error (for UI highlighting)
  final String? fieldName;

  /// Type of validation error
  final ValidationErrorType type;

  /// Suggested action text (e.g., "Add Medication")
  final String? suggestedAction;

  /// Route to navigate to fix the error (e.g., "/onboarding/treatment/medication")
  final String? actionRoute;

  /// Whether this error has an actionable solution
  bool get hasAction => suggestedAction != null && actionRoute != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValidationError &&
        other.message == message &&
        other.fieldName == fieldName &&
        other.type == type &&
        other.suggestedAction == suggestedAction &&
        other.actionRoute == actionRoute;
  }

  @override
  int get hashCode {
    return Object.hash(
      message,
      fieldName,
      type,
      suggestedAction,
      actionRoute,
    );
  }

  @override
  String toString() {
    return 'ValidationError('
        'message: $message, '
        'fieldName: $fieldName, '
        'type: $type, '
        'suggestedAction: $suggestedAction, '
        'actionRoute: $actionRoute'
        ')';
  }
}

/// Result of validation operation with comprehensive error information
@immutable
class ValidationResult {
  /// Creates a [ValidationResult] instance
  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.missingFields = const [],
  });

  /// Creates a successful validation result
  const ValidationResult.success()
    : isValid = true,
      errors = const [],
      warnings = const [],
      missingFields = const [];

  /// Creates a failed validation result with errors
  ValidationResult.failure(this.errors)
    : isValid = false,
      warnings = const [],
      missingFields = errors
          .where((e) => e.fieldName != null)
          .map((e) => e.fieldName!)
          .toList();

  /// Creates a validation result with warnings but no errors
  const ValidationResult.withWarnings(this.warnings)
    : isValid = true,
      errors = const [],
      missingFields = const [];

  /// Whether the validation passed
  final bool isValid;

  /// List of detailed validation errors
  final List<ValidationError> errors;

  /// List of validation warning messages (non-blocking)
  final List<String> warnings;

  /// List of field names that are missing (for backward compatibility)
  final List<String> missingFields;

  /// Number of validation errors
  int get errorCount => errors.length;

  /// Whether there are any errors
  bool get hasErrors => errors.isNotEmpty;

  /// Whether there are any warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Combined error message for display
  String get errorMessage =>
      errors.isEmpty ? '' : errors.map((e) => e.message).join('\n');

  /// Combined warning message for display
  String get warningMessage => warnings.isEmpty ? '' : warnings.join('\n');

  /// Gets errors of a specific type
  List<ValidationError> getErrorsByType(ValidationErrorType type) {
    return errors.where((error) => error.type == type).toList();
  }

  /// Gets errors that have actionable solutions
  List<ValidationError> getActionableErrors() {
    return errors.where((error) => error.hasAction).toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValidationResult &&
        other.isValid == isValid &&
        listEquals(other.errors, errors) &&
        listEquals(other.warnings, warnings) &&
        listEquals(other.missingFields, missingFields);
  }

  @override
  int get hashCode {
    return Object.hash(
      isValid,
      Object.hashAll(errors),
      Object.hashAll(warnings),
      Object.hashAll(missingFields),
    );
  }

  @override
  String toString() {
    return 'ValidationResult('
        'isValid: $isValid, '
        'errorCount: $errorCount, '
        'errors: $errors'
        ')';
  }
}
