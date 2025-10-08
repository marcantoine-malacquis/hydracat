/// Centralized error handling utility for logging feature
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/logging/exceptions/logging_exceptions.dart';

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
  static String getErrorMessage(Exception exception) {
    if (exception is LoggingException) {
      return exception.userMessage;
    }

    if (exception is FirebaseException) {
      return handleFirebaseError(exception);
    }

    // Generic fallback for unknown exceptions
    return 'Something went wrong. Please try again.';
  }

  /// Maps Firebase error codes to user-friendly messages
  ///
  /// Handles the 4 most common Firebase errors specifically:
  /// - permission-denied: Permission issues
  /// - unavailable/deadline-exceeded: Network timeouts
  /// - resource-exhausted: Rate limits or quotas
  /// - All others: Generic offline fallback
  static String handleFirebaseError(FirebaseException firebaseError) {
    switch (firebaseError.code) {
      case 'permission-denied':
        return 'Unable to save. Please check your account permissions.';

      case 'unavailable':
      case 'deadline-exceeded':
        return 'Connection timeout. Your data is saved offline and will '
            'sync automatically.';

      case 'resource-exhausted':
        return 'Service temporarily unavailable. Please try again in a '
            'moment.';

      default:
        return 'Unable to save right now. Your data is saved offline.';
    }
  }

  /// Shows an error message with consistent styling
  ///
  /// Uses snackbar with error background color and floating behavior.
  /// Clears any existing snackbars before showing the new one.
  /// Announces message to screen readers via SemanticsService.
  static void showLoggingError(BuildContext context, String message) {
    // Announce to screen readers
    SemanticsService.announce(message, TextDirection.ltr);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
  }

  /// Shows a success message with optional offline indicator
  ///
  /// When [isOffline] is true, appends " (will sync later)" to message
  /// to inform users that their data will sync when reconnected.
  ///
  /// Uses success background color and floating behavior.
  /// Announces message to screen readers via SemanticsService.
  static void showLoggingSuccess(
    BuildContext context,
    String message, {
    bool isOffline = false,
  }) {
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();

    final displayMessage = isOffline ? '$message (will sync later)' : message;

    // Announce to screen readers with offline context if applicable
    final announcement = isOffline
        ? '$message. Will sync when online.'
        : message;
    SemanticsService.announce(announcement, TextDirection.ltr);

    messenger.showSnackBar(
      SnackBar(
        content: Text(displayMessage),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
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
    // Announce to screen readers with retry context
    SemanticsService.announce(
      '$message. Retry button available.',
      TextDirection.ltr,
    );

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 6), // Longer for retry action
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: onRetry,
          ),
        ),
      );
  }
}
