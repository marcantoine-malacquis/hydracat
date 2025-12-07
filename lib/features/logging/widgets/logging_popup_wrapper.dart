import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/shared/widgets/accessibility/touch_target_icon_button.dart';

/// A reusable bottom-sheet-style content container for logging screens.
///
/// Provides a consistent popup experience with:
/// - Header with title and close button
/// - Scrollable content area
/// - Back-button dismissal support
///
/// Designed to be used inside a modal bottom sheet
/// (via `showHydraBottomSheet`).
/// The sheet itself handles animations, drag-to-dismiss, and backdrop.
///
/// Usage:
/// ```dart
/// showHydraBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   builder: (context) => HydraBottomSheet(
///     child: LoggingPopupWrapper(
///       title: 'Log Medication',
///       onDismiss: () {
///         Navigator.pop(context);
///         ref.read(loggingProvider.notifier).reset();
///       },
///       child: MedicationFormContent(),
///     ),
///   ),
/// );
/// ```
class LoggingPopupWrapper extends StatelessWidget {
  /// Creates a [LoggingPopupWrapper].
  const LoggingPopupWrapper({
    required this.title,
    required this.child,
    this.leading,
    this.trailing,
    this.onDismiss,
    this.showCloseButton = true,
    this.headerContent,
    super.key,
  });

  /// Title displayed in the popup header.
  final String title;

  /// Content widget displayed in the scrollable area.
  final Widget child;

  /// Optional widget displayed before the title (e.g., back button).
  final Widget? leading;

  /// Optional widget displayed after the title (e.g., Done/Save button).
  ///
  /// When provided, this is rendered instead of the default close button.
  final Widget? trailing;

  /// Callback when the popup is dismissed.
  ///
  /// Should typically call `Navigator.pop(context)` and
  /// `ref.read(loggingProvider.notifier).reset()`.
  final VoidCallback? onDismiss;

  /// Whether to show the close button in the header.
  final bool showCloseButton;

  /// Optional custom content to display in the header instead of [title].
  ///
  /// When provided, this widget is rendered in the center of the header,
  /// while [title] continues to be used for accessibility semantics.
  final Widget? headerContent;

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
      child: Semantics(
        label: l10n.loggingPopupSemantic(title),
        child: ColoredBox(
          color: AppColors.background,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: mediaQuery.size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with drag handle
                _buildHeader(context, theme),

                // Scrollable content area
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      top: AppSpacing.sm,
                      bottom: AppSpacing.lg,
                    ),
                    child: child,
                  ),
                ),
              ],
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.25,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Row(
            children: [
              // Left side: leading widget or spacer to balance close button
              if (leading != null)
                leading!
              else if (trailing != null || showCloseButton)
                const SizedBox(width: 44),
              // Center: title/content
              Expanded(
                child:
                    headerContent ??
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
              ),
              // Right side: trailing widget or close button
              if (trailing != null)
                trailing!
              else if (showCloseButton)
                TouchTargetIconButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                    onDismiss?.call();
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
        ],
      ),
    );
  }
}
