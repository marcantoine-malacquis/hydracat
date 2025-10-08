import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';

/// A success popup that appears after quick-log completion.
///
/// Features:
/// - Shows session count and pet name
/// - Scale-in entrance animation (300ms)
/// - Auto-dismisses after 2.5 seconds
/// - Tap anywhere to dismiss immediately
/// - Haptic feedback on appearance
/// - Live region announcement for screen readers
/// - Positioned above navigation bar
///
/// Usage:
/// ```dart
/// OverlayService.showFullScreenPopup(
///   context: context,
///   child: QuickLogSuccessPopup(
///     sessionCount: 3,
///     petName: 'Whiskers',
///   ),
///   animationType: OverlayAnimationType.scaleIn,
/// );
/// ```
class QuickLogSuccessPopup extends StatefulWidget {
  /// Creates a [QuickLogSuccessPopup].
  const QuickLogSuccessPopup({
    required this.sessionCount,
    required this.petName,
    super.key,
  });

  /// Number of treatment sessions logged
  final int sessionCount;

  /// Pet's name from CatProfile
  final String petName;

  @override
  State<QuickLogSuccessPopup> createState() => _QuickLogSuccessPopupState();
}

class _QuickLogSuccessPopupState extends State<QuickLogSuccessPopup> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();

    // Haptic feedback on appearance
    HapticFeedback.lightImpact();

    // Auto-dismiss after 2.5 seconds
    _dismissTimer = Timer(
      const Duration(milliseconds: 2500),
      OverlayService.hide,
    );
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  String get _treatmentLabel =>
      widget.sessionCount == 1 ? 'treatment' : 'treatments';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Semantics(
      liveRegion: true,
      label: '${widget.sessionCount} $_treatmentLabel logged '
          'for ${widget.petName}',
      hint: 'Tap to dismiss',
      child: GestureDetector(
        onTap: () {
          _dismissTimer?.cancel();
          OverlayService.hide();
        },
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              // Position above navigation bar (56px) + extra spacing
              bottom: mediaQuery.padding.bottom + AppSpacing.xl + 80,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    '${widget.sessionCount} $_treatmentLabel logged '
                    'for ${widget.petName} ✓',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
