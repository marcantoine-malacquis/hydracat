/// Centralized error handling utility for logging feature
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/features/logging/exceptions/logging_exceptions.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Static utility class for consistent error handling across logging feature
///
/// Provides centralized methods for:
/// - Displaying error/success messages with consistent styling
/// - Mapping Firebase errors to user-friendly messages
/// - Converting exceptions to user-friendly messages
///
/// Usage:
/// ```dart
/// LoggingErrorHandler.showLoggingError(context, 'Something went wrong');
/// LoggingErrorHandler.showLoggingSuccess(
///   context,
///   'Logged successfully',
///   isOffline: true,
/// );
/// ```
class LoggingErrorHandler {
  // Private constructor to prevent instantiation
  LoggingErrorHandler._();

  /// Maps any exception to a user-friendly message
  ///
  /// Uses the exception's `userMessage` if it's a [LoggingException],
  /// otherwise maps Firebase errors or returns a generic message.
  ///
  /// Requires [l10n] for localized error messages.
  static String getErrorMessage(Exception exception, AppLocalizations l10n) {
    if (exception is LoggingException) {
      return exception.getUserMessage(l10n);
    }

    if (exception is FirebaseException) {
      return handleFirebaseError(exception, l10n);
    }

    // Generic fallback for unknown exceptions
    return l10n.errorGeneric;
  }

  /// Maps Firebase error codes to user-friendly messages
  ///
  /// Handles the 4 most common Firebase errors specifically:
  /// - permission-denied: Permission issues
  /// - unavailable/deadline-exceeded: Network timeouts
  /// - resource-exhausted: Rate limits or quotas
  /// - All others: Generic offline fallback
  ///
  /// Requires [l10n] for localized error messages.
  static String handleFirebaseError(
    FirebaseException firebaseError,
    AppLocalizations l10n,
  ) {
    switch (firebaseError.code) {
      case 'permission-denied':
        return l10n.errorPermissionDenied;

      case 'unavailable':
      case 'deadline-exceeded':
        return l10n.errorConnectionTimeout;

      case 'resource-exhausted':
        return l10n.errorServiceUnavailable;

      default:
        return l10n.errorOffline;
    }
  }

  /// Shows an error message with consistent styling
  ///
  /// Uses platform-adaptive snackbar/toast with error background color.
  /// Clears any existing snackbars/toasts before showing the new one.
  /// Announces message to screen readers via SemanticsService.
  static void showLoggingError(BuildContext context, String message) {
    HydraSnackBar.showError(context, message);
  }

  /// Shows a success message with optional offline indicator
  ///
  /// When [isOffline] is true, appends localized offline message to inform
  /// users that their data will sync when reconnected.
  ///
  /// Uses platform-adaptive snackbar/toast with success background color.
  /// Announces message to screen readers via SemanticsService.
  static void showLoggingSuccess(
    BuildContext context,
    String message, {
    bool isOffline = false,
  }) {
    final l10n = AppLocalizations.of(context)!;

    final displayMessage = isOffline
        ? '$message ${l10n.errorSyncLater}'
        : message;

    HydraSnackBar.showSuccess(context, displayMessage);
  }

  /// Shows an error message with a retry action button
  ///
  /// Used specifically for sync failures that can be retried.
  /// The [onRetry] callback is invoked when user taps Retry button.
  /// Announces message to screen readers via SemanticsService.
  static void showSyncRetry(
    BuildContext context,
    String message,
    VoidCallback onRetry,
  ) {
    final l10n = AppLocalizations.of(context)!;

    HydraSnackBar.show(
      context,
      message,
      type: HydraSnackBarType.error,
      actionLabel: l10n.retry,
      onAction: onRetry,
      duration: const Duration(seconds: 6), // Longer for retry action
    );
  }
}
