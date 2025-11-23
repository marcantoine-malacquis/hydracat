import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:hydracat/core/constants/app_colors.dart';

/// Platform-adaptive snackbar/toast for HydraCat.
///
/// On Material platforms (Android), uses [SnackBar] via [ScaffoldMessenger].
/// On iOS/macOS, displays a custom toast overlay positioned above the bottom
/// navigation bar.
///
/// Provides semantic helper methods for common use cases:
/// - [showSuccess] - Success messages (teal/primary color)
/// - [showError] - Error messages (red/error color)
/// - [showInfo] - Informational messages (neutral color)
/// - [show] - Low-level method for advanced cases (actions, custom durations)
class HydraSnackBar {
  HydraSnackBar._();

  /// Shows a success message.
  ///
  /// Uses app teal color ([AppColors.primary]) for success feedback.
  /// Announces message to screen readers via [SemanticsService].
  ///
  /// Example:
  /// ```dart
  /// HydraSnackBar.showSuccess(context, 'Weight logged successfully');
  /// ```
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(
      context,
      message,
      type: HydraSnackBarType.success,
      duration: duration,
    );
  }

  /// Shows an error message.
  ///
  /// Uses app red color ([AppColors.error]) for error feedback.
  /// Announces message to screen readers via [SemanticsService].
  ///
  /// Example:
  /// ```dart
  /// HydraSnackBar.showError(context, 'Failed to save');
  /// ```
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(
      context,
      message,
      type: HydraSnackBarType.error,
      duration: duration,
    );
  }

  /// Shows an informational message.
  ///
  /// Uses neutral color for informational feedback.
  /// Announces message to screen readers via [SemanticsService].
  ///
  /// Example:
  /// ```dart
  /// HydraSnackBar.showInfo(context, 'Settings saved');
  /// ```
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(
      context,
      message,
      type: HydraSnackBarType.info,
      duration: duration,
    );
  }

  /// Low-level method to show a snackbar/toast with full control.
  ///
  /// Supports optional action buttons for retry flows and other interactions.
  /// On iOS, actions are rendered as tappable text within the toast.
  ///
  /// Example with action:
  /// ```dart
  /// HydraSnackBar.show(
  ///   context,
  ///   'Sync failed',
  ///   type: HydraSnackBarType.error,
  ///   actionLabel: 'Retry',
  ///   onAction: () => retrySync(),
  ///   duration: const Duration(seconds: 6),
  /// );
  /// ```
  static void show(
    BuildContext context,
    String message, {
    required HydraSnackBarType type,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    final platform = Theme.of(context).platform;

    // Announce to screen readers
    final announcement = actionLabel != null
        ? '$message. $actionLabel button available.'
        : message;
    SemanticsService.announce(announcement, TextDirection.ltr);

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      _showCupertinoToast(
        context,
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration ?? const Duration(seconds: 4),
      );
    } else {
      _showMaterialSnackBar(
        context,
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration ?? const Duration(seconds: 4),
      );
    }
  }

  /// Shows Material SnackBar on Android/other platforms.
  static void _showMaterialSnackBar(
    BuildContext context, {
    required String message,
    required HydraSnackBarType type,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final backgroundColor = _getBackgroundColor(type);
    const behavior = SnackBarBehavior.floating;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: behavior,
          shape: shape,
          duration: duration,
          action: (actionLabel != null && onAction != null)
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: onAction,
                )
              : null,
        ),
      );
  }

  /// Shows custom toast overlay on iOS/macOS.
  static void _showCupertinoToast(
    BuildContext context, {
    required String message,
    required HydraSnackBarType type,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.of(context);
    final navigator = Navigator.of(context);

    // Remove any existing toast
    _removeCurrentToast(navigator);

    // Create overlay entry for toast
    final overlayEntry = OverlayEntry(
      builder: (context) => _HydraToast(
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        onDismiss: () => _removeCurrentToast(navigator),
      ),
    );

    // Store reference for cleanup
    _currentToastEntries[navigator] = overlayEntry;

    overlay.insert(overlayEntry);

    // Auto-dismiss after duration
    Timer(duration, () {
      _removeCurrentToast(navigator);
    });
  }

  /// Map of Navigator to current OverlayEntry for toast management.
  static final Map<NavigatorState, OverlayEntry> _currentToastEntries = {};

  /// Removes the current toast overlay if it exists.
  static void _removeCurrentToast(NavigatorState navigator) {
    final entry = _currentToastEntries.remove(navigator);
    entry?.remove();
  }

  /// Gets background color based on snackbar type.
  static Color _getBackgroundColor(HydraSnackBarType type) {
    switch (type) {
      case HydraSnackBarType.success:
        return AppColors.primary; // App teal for success
      case HydraSnackBarType.error:
        return AppColors.error; // App red for error
      case HydraSnackBarType.info:
        return AppColors.textSecondary; // Neutral gray for info
    }
  }
}

/// Type of snackbar/toast message.
enum HydraSnackBarType {
  /// Success message (teal/primary color).
  success,

  /// Error message (red/error color).
  error,

  /// Informational message (neutral color).
  info,
}

/// Custom toast widget for iOS/macOS.
///
/// Displays a capsule-shaped toast positioned above the bottom navigation bar.
/// Animates in with fade and slide-up, then auto-dismisses after [duration].
class _HydraToast extends StatefulWidget {
  const _HydraToast({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final HydraSnackBarType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_HydraToast> createState() => _HydraToastState();
}

class _HydraToastState extends State<_HydraToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor(widget.type);
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final bottomInset = mediaQuery.viewInsets.bottom;

    // Position above bottom nav bar (typically 80-90px from bottom)
    // Add extra space for safe area and bottom navigation
    final bottomOffset = 90.0 + bottomPadding + bottomInset;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomOffset,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onAction ?? _handleDismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(100), // Capsule shape
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Optional icon based on type
                    if (widget.type == HydraSnackBarType.success)
                      const Icon(
                        CupertinoIcons.check_mark,
                        color: Colors.white,
                        size: 18,
                      )
                    else if (widget.type == HydraSnackBarType.error)
                      const Icon(
                        CupertinoIcons.xmark,
                        color: Colors.white,
                        size: 18,
                      ),
                    if (widget.type != HydraSnackBarType.info)
                      const SizedBox(width: 8),
                    // Message text
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Optional action button
                    if (widget.actionLabel != null && widget.onAction != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: GestureDetector(
                          onTap: widget.onAction,
                          child: Text(
                            widget.actionLabel!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(HydraSnackBarType type) {
    switch (type) {
      case HydraSnackBarType.success:
        return AppColors.primary; // App teal for success
      case HydraSnackBarType.error:
        return AppColors.error; // App red for error
      case HydraSnackBarType.info:
        return AppColors.textSecondary; // Neutral gray for info
    }
  }
}
