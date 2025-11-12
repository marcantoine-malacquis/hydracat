import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';

/// Success popup shown after confirming or skipping a treatment.
///
/// Features:
/// - Center-positioned (unlike QuickLogSuccessPopup which is bottom-aligned)
/// - Scale-in entrance animation
/// - Auto-dismisses after 1.5 seconds
/// - Haptic feedback on appearance (medium for confirm, light for skip)
/// - Screen reader announcement via live region
class DashboardSuccessPopup extends StatefulWidget {
  /// Creates a [DashboardSuccessPopup].
  const DashboardSuccessPopup({
    required this.message,
    this.isSkipped = false,
    super.key,
  });

  /// Success message to display
  final String message;

  /// Whether this was a skip action (affects haptic feedback)
  final bool isSkipped;

  @override
  State<DashboardSuccessPopup> createState() => _DashboardSuccessPopupState();
}

class _DashboardSuccessPopupState extends State<DashboardSuccessPopup> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();

    // Haptic feedback on appearance
    if (widget.isSkipped) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    // Auto-dismiss after 1.5 seconds
    _dismissTimer = Timer(
      const Duration(milliseconds: 1500),
      () {
        if (mounted) {
          OverlayService.hide();
        }
      },
    );
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      liveRegion: true,
      label: widget.message,
      hint: 'Tap to dismiss',
      child: GestureDetector(
        onTap: () {
          _dismissTimer?.cancel();
          OverlayService.hide();
        },
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
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
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    widget.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
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
