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
class LoggingPopupWrapper extends StatefulWidget {
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
  /// Should typically call `ref.read(loggingProvider.notifier).reset()`.
  final VoidCallback? onDismiss;

  /// Whether to show the close button in the header.
  final bool showCloseButton;

  /// Optional custom content to display in the header instead of [title].
  ///
  /// When provided, this widget is rendered in the center of the header,
  /// while [title] continues to be used for accessibility semantics.
  final Widget? headerContent;

  @override
  State<LoggingPopupWrapper> createState() => _LoggingPopupWrapperState();
}

class _LoggingPopupWrapperState extends State<LoggingPopupWrapper>
    with SingleTickerProviderStateMixin {
  // Require a fairly intentional pull to dismiss.
  static const double _dragDismissThreshold = 140;
  static const double _velocityDismissThreshold = 600;

  late final AnimationController _animationController;
  Animation<double>? _animation;
  late double _dragOffset;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _dragOffset = 0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animateBackToOrigin() {
    _animationController
      ..stop()
      ..reset();
    _animation =
        Tween<double>(
            begin: _dragOffset,
            end: 0,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ),
          )
          ..addListener(() {
            setState(() {
              _dragOffset = _animation!.value;
            });
          });

    _animationController.forward();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, 300.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldDismiss =
        _dragOffset > _dragDismissThreshold ||
        velocity > _velocityDismissThreshold;

    if (shouldDismiss && velocity >= 0) {
      widget.onDismiss?.call();
      OverlayService.hide();
    } else {
      _animateBackToOrigin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && widget.onDismiss != null) {
          widget.onDismiss!();
        }
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          type: MaterialType.transparency,
          child: Semantics(
            label: l10n.loggingPopupSemantic(widget.title),
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
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
                    // Header (also acts as drag handle)
                    _buildHeader(context, theme),

                    // Scrollable content area
                    Flexible(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Design for 640px height minimum (iPhone SE)
                          // Show subtle scroll indicator if content exceeds
                          return SingleChildScrollView(
                            padding: const EdgeInsets.only(
                              left: AppSpacing.lg,
                              right: AppSpacing.lg,
                              top: AppSpacing.sm,
                              bottom: AppSpacing.lg,
                            ),
                            child: widget.child,
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: Container(
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
                if (widget.leading != null) widget.leading!,
                Expanded(
                  child:
                      widget.headerContent ??
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                ),
                if (widget.trailing != null)
                  widget.trailing!
                else if (widget.showCloseButton)
                  TouchTargetIconButton(
                    onPressed: () {
                      widget.onDismiss?.call();
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
          ],
        ),
      ),
    );
  }
}
