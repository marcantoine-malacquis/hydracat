import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_animations.dart';

/// A brief animated success indicator with a checkmark.
///
/// Displays a scaling checkmark icon in a circle, then auto-dismisses
/// after 500ms. Used to provide visual feedback when a logging operation
/// completes successfully.
class SuccessIndicator extends StatefulWidget {
  /// Creates a [SuccessIndicator].
  const SuccessIndicator({
    this.onComplete,
    super.key,
  });

  /// Callback when the indicator completes its animation
  final VoidCallback? onComplete;

  @override
  State<SuccessIndicator> createState() => _SuccessIndicatorState();
}

class _SuccessIndicatorState extends State<SuccessIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();

    // Setup scale animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation =
        Tween<double>(
          begin: 0,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.elasticOut,
          ),
        );

    // Start animation
    _controller.forward();

    // Auto-dismiss after 500ms
    _dismissTimer = Timer(AppAnimations.successDisplayDuration, () {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Success',
      liveRegion: true,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.check_circle,
            size: 48,
            // Primary teal color from UI guidelines: #6BB8A8
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
