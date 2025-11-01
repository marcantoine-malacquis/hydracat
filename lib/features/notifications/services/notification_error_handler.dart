/// Centralized error handling utility for notification system
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hydracat/core/config/flavor_config.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/shared/services/firebase_service.dart';

/// Static utility class for consistent error handling across
///  notification feature
///
/// Provides centralized methods for:
/// - Crashlytics reporting with proper context (userId, petId, scheduleId)
/// - User-facing error dialogs for critical failures (permissions)
/// - Silent logging for auto-recovering failures (scheduling, cancellation)
///
/// **Privacy**: Never logs PII (medication names, dosages, volumes)
///  to Crashlytics.
///
/// Usage:
/// ```dart
/// NotificationErrorHandler.handleSchedulingError(
///   context: null,
///   operation: 'schedule_medication_reminder',
///   error: e,
///   userId: userId,
///   petId: petId,
///   scheduleId: scheduleId,
/// );
/// ```
class NotificationErrorHandler {
  // Private constructor to prevent instantiation
  NotificationErrorHandler._();

  /// Reports error to Crashlytics with proper context.
  ///
  /// Includes operational identifiers (userId, petId, scheduleId) but never
  /// logs sensitive medical data (medication names, dosages, volumes).
  ///
  /// Parameters:
  /// - [operation]: Name of the operation that failed
  ///  (e.g., 'schedule_medication_reminder')
  /// - [error]: The exception that was thrown
  /// - [stackTrace]: Optional stack trace for debugging
  /// - [userId]: Current user ID (required)
  /// - [petId]: Pet ID if applicable (optional)
  /// - [scheduleId]: Schedule ID if applicable (optional)
  /// - [additionalContext]: Additional key-value pairs for debugging (optional)
  static Future<void> reportToCrashlytics({
    required String operation,
    required Exception error,
    required String userId,
    StackTrace? stackTrace,
    String? petId,
    String? scheduleId,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      final crashlytics = FirebaseService().crashlytics;

      // Build context map (no PII)
      final context = <String, dynamic>{
        'operation': operation,
        'userId': userId,
      };

      if (petId != null) {
        context['petId'] = petId;
      }

      if (scheduleId != null) {
        context['scheduleId'] = scheduleId;
      }

      // Add platform info
      context['platform'] = Platform.operatingSystem;
      context['os_version'] = Platform.operatingSystemVersion;

      // Merge additional context
      if (additionalContext != null) {
        context.addAll(additionalContext);
      }

      // Set custom keys
      for (final entry in context.entries) {
        await crashlytics.setCustomKey(entry.key, entry.value.toString());
      }

      // Log error message
      await crashlytics.log(
        'Notification error: $operation failed for user $userId',
      );

      // Record error with stack trace
      if (stackTrace != null) {
        await crashlytics.recordError(
          error,
          stackTrace,
          reason: 'Notification operation failed: $operation',
        );
      } else {
        await crashlytics.recordError(
          error,
          StackTrace.current,
          reason: 'Notification operation failed: $operation',
        );
      }
    } on Exception catch (e) {
      // Silently fail if Crashlytics not available
      if (FlavorConfig.isDevelopment) {
        debugPrint(
          '[NotificationErrorHandler] Failed to report to Crashlytics: $e',
        );
      }
    }
  }

  /// Handles plugin initialization failures.
  ///
  /// Logs to Crashlytics with device info (platform, OS version) but no user
  /// context (user not authenticated yet during app initialization).
  ///
  /// Parameters:
  /// - [error]: The exception that occurred
  /// - [stackTrace]: Optional stack trace
  /// - [retryCount]: Number of retry attempts made
  static Future<void> handlePluginInitializationError({
    required Exception error,
    StackTrace? stackTrace,
    int retryCount = 0,
  }) async {
    await reportToCrashlytics(
      operation: 'plugin_initialization',
      error: error,
      stackTrace: stackTrace,
      userId: 'app_initialization', // No user context yet
      additionalContext: {
        'retry_count': retryCount,
      },
    );
  }

  /// Handles scheduling operation failures silently.
  ///
  /// Logs to Crashlytics but shows no user-facing error (silent recovery via
  /// reconciliation). This is for non-critical failures that auto-correct.
  ///
  /// Parameters:
  /// - [context]: BuildContext if available (null in service layer)
  /// - [operation]: Name of the operation
  ///  (e.g., 'schedule_medication_reminder')
  /// - [error]: The exception that occurred
  /// - [userId]: Current user ID
  /// - [petId]: Pet ID if applicable
  /// - [scheduleId]: Schedule ID if applicable
  static void handleSchedulingError({
    required BuildContext? context,
    required String operation,
    required Exception error,
    required String userId,
    String? petId,
    String? scheduleId,
  }) {
    // Always log to Crashlytics
    unawaited(
      reportToCrashlytics(
        operation: operation,
        error: error,
        userId: userId,
        petId: petId,
        scheduleId: scheduleId,
      ),
    );

    // Silent failure - no user-facing message
    // Scheduling failures auto-recover via reconciliation on app resume
  }

  /// Handles index corruption errors.
  ///
  /// Logs to Crashlytics and tracks analytics.
  /// Recovery is handled automatically
  /// by rebuilding from plugin state.
  ///
  /// Parameters:
  /// - [userId]: Current user ID
  /// - [petId]: Pet ID
  /// - [date]: Date of the corrupted index
  /// - [error]: Optional error that occurred during corruption detection
  static Future<void> handleIndexCorruptionError({
    required String userId,
    required String petId,
    required String date,
    Exception? error,
  }) async {
    if (error != null) {
      await reportToCrashlytics(
        operation: 'index_corruption_detection',
        error: error,
        userId: userId,
        petId: petId,
        additionalContext: {
          'date': date,
        },
      );
    }
  }

  /// Handles permission-related errors.
  ///
  /// Logs to Crashlytics and shows user-facing dialog for actionable scenarios
  /// (permission revoked). Non-actionable errors (already denied) are silent.
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing dialog
  /// - [operation]: Name of the operation
  /// - [error]: The exception that occurred
  /// - [userId]: Current user ID
  /// - [showDialog]: Whether to show user-facing dialog (default: true)
  static Future<void> handlePermissionError({
    required BuildContext context,
    required String operation,
    required Exception error,
    required String userId,
    bool showDialog = true,
  }) async {
    // Always log to Crashlytics
    await reportToCrashlytics(
      operation: operation,
      error: error,
      userId: userId,
    );

    // Show user-facing dialog if requested
    // Note: BuildContext is captured before async gap
    if (showDialog && context.mounted) {
      // Context is checked for mounted before use to ensure it's safe to use
      // after the async gap (reportToCrashlytics call above)
      // ignore: use_build_context_synchronously
      await showPermissionRevokedDialog(context);
    }
  }

  /// Shows dialog explaining notification permission was revoked.
  ///
  /// Educational dialog that guides users to re-enable notifications in
  /// system settings. This appears when permission is revoked after being
  /// granted (actionable scenario).
  static Future<void> showPermissionRevokedDialog(
    BuildContext context,
  ) async {
    final l10n = AppLocalizations.of(context);

    if (l10n == null) {
      // Can't show dialog without localization
      return;
    }

    // Get localized strings
    final title = l10n.notificationPermissionRevokedTitle;
    final message = l10n.notificationPermissionRevokedMessage;
    final actionText = l10n.notificationPermissionRevokedAction;
    final cancelText = l10n.cancel;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Open system settings (platform-specific)
              // Note: This requires platform channels or openAppSettings
              //from permission_handler
              // For now, navigation to app settings screen is handled by the
              //permission prompt
            },
            child: Text(actionText),
          ),
        ],
      ),
    );
  }
}
