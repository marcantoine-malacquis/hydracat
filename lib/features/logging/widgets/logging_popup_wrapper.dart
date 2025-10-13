import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/shared/widgets/accessibility/touch_target_icon_button.dart';

/// A reusable bottom-sheet-style popup container for logging screens.
///
/// Provides a consistent popup experience with:
/// - Bottom-positioned container
/// - Responsive sizing (max 80% screen height)
/// - Header with title and close button
/// - Scrollable content area
/// - Tap-outside or back-button dismissal
///
/// Note: Blurred background is handled by OverlayService
///
/// Usage:
/// ```dart
/// LoggingPopupWrapper(
///   title: 'Log Medication',
///   onDismiss: () {
///     ref.read(loggingProvider.notifier).reset();
///   },
///   child: MedicationFormContent(),
/// )
/// ```
class LoggingPopupWrapper extends StatelessWidget {
  /// Creates a [LoggingPopupWrapper].
  const LoggingPopupWrapper({
    required this.title,
    required this.child,
    this.onDismiss,
    this.showCloseButton = true,
    super.key,
  });

  /// Title displayed in the popup header.
  final String title;

  /// Content widget displayed in the scrollable area.
  final Widget child;

  /// Callback when the popup is dismissed.
  ///
  /// Should typically call `ref.read(loggingProvider.notifier).reset()`.
  final VoidCallback? onDismiss;

  /// Whether to show the close button in the header.
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && onDismiss != null) {
          onDismiss!();
        }
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            // Dismiss on swipe down
            if (details.primaryVelocity != null &&
                details.primaryVelocity! > 300) {
              onDismiss?.call();
              OverlayService.hide();
            }
          },
          child: Material(
            type: MaterialType.transparency,
            child: Semantics(
              label: l10n.loggingPopupSemantic(title),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: mediaQuery.size.height * 0.8,
                ),
                margin: EdgeInsets.only(
                  // Add keyboard padding when visible, plus safe area padding
                  bottom:
                      mediaQuery.viewInsets.bottom +
                      mediaQuery.padding.bottom +
                      AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    _buildHeader(context, theme),

                    // Scrollable content area
                    Flexible(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Design for 640px height minimum (iPhone SE)
                          // Show subtle scroll indicator if content exceeds
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: child,
                          );
                        },
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

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (showCloseButton)
            TouchTargetIconButton(
              onPressed: () {
                onDismiss?.call();
                OverlayService.hide();
              },
              icon: Icon(
                Icons.close,
                color: theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              tooltip: l10n.loggingCloseTooltip,
              semanticLabel: l10n.loggingClosePopupSemantic,
            ),
        ],
      ),
    );
  }
}
