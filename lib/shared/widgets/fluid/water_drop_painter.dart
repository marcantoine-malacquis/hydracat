import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/constants/app_animations.dart';
import 'package:hydracat/core/constants/app_colors.dart';

/// Animated water drop widget with organic wave motion
///
/// Shows fill percentage (0.0 to 1.0) with animated waves.
/// Uses subtle pulse animation for battery efficiency.
///
/// Usage:
/// ```dart
/// WaterDropWidget(
///   fillPercentage: 0.75,  // 75% filled
///   height: 220.0,
///   onGoalAchieved: () => print('Goal achieved!'),
/// )
/// ```
class WaterDropWidget extends StatefulWidget {
  /// Creates an animated water drop widget
  const WaterDropWidget({
    required this.fillPercentage,
    required this.height,
    this.onGoalAchieved,
    super.key,
  });

  /// Fill percentage (0.0 = empty, 1.0 = full)
  final double fillPercentage;

  /// Height of the drop widget (width is calculated as height * 0.83)
  final double height;

  /// Callback fired once when weekly goal is achieved (fillPercentage >= 1.0)
  final VoidCallback? onGoalAchieved;

  @override
  State<WaterDropWidget> createState() => _WaterDropWidgetState();
}

class _WaterDropWidgetState extends State<WaterDropWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _waveController;

  // Celebration state
  bool _hasShownCelebration = false;
  bool _showingParticles = false;

  // Track if animation has been initialized (prevent re-initialization)
  bool _hasInitializedAnimation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Start with subtle pulse speed (4 seconds) for battery efficiency
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Start animation once (only when first mounted and context is available)
    if (!_hasInitializedAnimation) {
      _hasInitializedAnimation = true;

      // Start animation if motion is not reduced
      if (!AppAnimations.shouldReduceMotion(context)) {
        _waveController.repeat();
      }
    }
  }

  @override
  void didUpdateWidget(WaterDropWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect threshold crossing from <100% to >=100%
    if (!_hasShownCelebration &&
        oldWidget.fillPercentage < 1.0 &&
        widget.fillPercentage >= 1.0) {
      _triggerCelebration();
    }
  }

  /// Trigger celebration animation when weekly goal is reached
  void _triggerCelebration() {
    if (!mounted) return;

    setState(() {
      _showingParticles = true;
      _hasShownCelebration = true;
    });

    // Trigger haptic feedback
    HapticFeedback.mediumImpact();

    // Fire analytics callback
    widget.onGoalAchieved?.call();

    // Hide particles after animation completes
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showingParticles = false;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _waveController.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (mounted && !AppAnimations.shouldReduceMotion(context)) {
        _waveController.repeat();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.height * 0.83;

    return Semantics(
      label: 'Water drop showing '
          '${(widget.fillPercentage * 100).round()} percent progress',
      child: SizedBox(
        width: width,
        height: widget.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Base water drop animation
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(width, widget.height),
                  painter: WaterDropPainter(
                    fillLevel: widget.fillPercentage,
                    wavePhase: _waveController.value * 2 * pi,
                    enableWaves: !AppAnimations.shouldReduceMotion(context),
                  ),
                );
              },
            ),

            // Particle burst overlay (only when celebrating)
            if (_showingParticles)
              const Positioned.fill(
                child: _ParticleBurstAnimation(
                  particleCount: 10,
                  color: AppColors.success,
                ),
              ),

            // Checkmark badge (persistent when >= 100%)
            if (widget.fillPercentage >= 1.0)
              Positioned(
                top: 8,
                right: 8,
                child: _CompletionBadge(
                  animate: !_hasShownCelebration,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for water drop shape with animated waves
class WaterDropPainter extends CustomPainter {
  /// Creates a water drop painter
  WaterDropPainter({
    required this.fillLevel,
    required this.wavePhase,
    required this.enableWaves,
  });

  /// Fill level from 0.0 (empty) to 1.0 (full)
  final double fillLevel;

  /// Current wave animation phase (0 to 2π)
  final double wavePhase;

  /// Whether to draw animated waves
  final bool enableWaves;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Create drop shape path
    final dropPath = _createDropPath(width, height);

    // Clip to drop shape
    canvas
      ..save()
      ..clipPath(dropPath);

    if (enableWaves) {
      _drawWaveFill(canvas, width, height);
    } else {
      _drawStaticGradientFill(canvas, width, height);
    }

    // Draw drop shadow (subtle depth) and border
    canvas
      ..restore()
      ..drawPath(
        dropPath,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawPath(
        dropPath,
        Paint()
          ..color = AppColors.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
  }

  /// Create classic water drop shape using Bezier curves
  Path _createDropPath(double width, double height) {
    return Path()
      // Start at top point (center-top)
      ..moveTo(width / 2, 0)
      // Left curve (control point at 10% width, 35% height)
      ..quadraticBezierTo(
        width * 0.1,
        height * 0.35,
        width * 0.1,
        height * 0.7,
      )
      // Bottom circular arc
      ..arcToPoint(
        Offset(width * 0.9, height * 0.7),
        radius: Radius.circular(width * 0.4),
        clockwise: false,
      )
      // Right curve (symmetrical)
      ..quadraticBezierTo(
        width * 0.9,
        height * 0.35,
        width / 2,
        0,
      )
      ..close();
  }

  /// Draw animated wave fill
  void _drawWaveFill(Canvas canvas, double width, double height) {
    final waterLevel = height * (1 - fillLevel);

    // Use subtle pulse amplitudes (50% of original) for battery efficiency
    const amplitudeMultiplier = 0.5;

    // Optimized wave parameters (organic, not mechanical)
    // Fast shimmer (surface detail)
    const amplitude1 = 2.5 * amplitudeMultiplier;
    // Medium swell (main motion)
    const amplitude2 = 6.0 * amplitudeMultiplier;
    // Slow base (foundation)
    const amplitude3 = 4.0 * amplitudeMultiplier;

    const frequency1 = 4.0; // Finer ripples
    const frequency2 = 2.0; // Broader waves
    const frequency3 = 1.0; // Very broad

    const speed1 = 1.0;
    const speed2 = 1.0; // Synchronized for seamless loop
    const speed3 = 1.0; // Synchronized for seamless loop

    // Build wave path
    final wavePath = Path()..moveTo(0, height);

    for (double x = 0; x <= width; x += 1) {
      final normalizedX = x / width;

      final wave1 = amplitude1 *
          sin(normalizedX * 2 * pi * frequency1 + wavePhase * speed1);
      final wave2 = amplitude2 *
          sin(normalizedX * 2 * pi * frequency2 + wavePhase * speed2);
      final wave3 = amplitude3 *
          sin(normalizedX * 2 * pi * frequency3 + wavePhase * speed3);

      final y = waterLevel + wave1 + wave2 + wave3;

      wavePath.lineTo(x, y);
    }

    wavePath
      ..lineTo(width, height)
      ..close();

    // Create gradient for base water fill (darker at bottom, lighter at top)
    final fillRect = Rect.fromLTWH(0, waterLevel, width, height - waterLevel);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primaryLight.withValues(alpha: 0.9),
        AppColors.primary,
        AppColors.primaryDark,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    // Draw base water fill with gradient
    canvas
      ..drawPath(
        wavePath,
        Paint()..shader = gradient.createShader(fillRect),
      )
      // Draw wave highlights (lighter, translucent)
      ..drawPath(
        wavePath,
        Paint()
          ..color = AppColors.primaryLight.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      // Draw wave shadows (darker, translucent)
      ..drawPath(
        wavePath,
        Paint()
          ..color = AppColors.primaryDark.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
  }

  /// Draw static gradient fill (reduced motion mode)
  void _drawStaticGradientFill(Canvas canvas, double width, double height) {
    final waterLevel = height * (1 - fillLevel);

    final fillRect = Rect.fromLTWH(0, waterLevel, width, height - waterLevel);

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primaryLight.withValues(alpha: 0.8),
        AppColors.primary,
        AppColors.primaryDark,
      ],
    );

    canvas.drawRect(
      fillRect,
      Paint()..shader = gradient.createShader(fillRect),
    );
  }

  @override
  bool shouldRepaint(WaterDropPainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.enableWaves != enableWaves;
  }
}

/// Particle burst animation for weekly completion celebration
class _ParticleBurstAnimation extends StatelessWidget {
  const _ParticleBurstAnimation({
    required this.particleCount,
    required this.color,
  });

  final int particleCount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(
        particleCount,
        (i) {
          // Fountain pattern: -20° to +20° from vertical (upward)
          final angle = (-pi / 2) +
              (i - particleCount / 2) * (40 * pi / 180) / particleCount;
          return _Particle(angle: angle, color: color);
        },
      ),
    );
  }
}

/// Single particle with arc trajectory animation
class _Particle extends StatefulWidget {
  const _Particle({
    required this.angle,
    required this.color,
  });

  final double angle;
  final Color color;

  @override
  State<_Particle> createState() => _ParticleState();
}

class _ParticleState extends State<_Particle> {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 60), // Travel 60px
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, distance, child) {
        // Arc trajectory (parabolic motion)
        final offsetX = distance * cos(widget.angle);
        final offsetY =
            distance * sin(widget.angle) + (distance * distance / 100);
        final opacity = 1.0 - (distance / 60);

        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Completion badge that appears when goal is reached
class _CompletionBadge extends StatefulWidget {
  const _CompletionBadge({
    required this.animate,
  });

  final bool animate;

  @override
  State<_CompletionBadge> createState() => _CompletionBadgeState();
}

class _CompletionBadgeState extends State<_CompletionBadge> {
  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return _buildBadge(1);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value * 1.2, // Overshoot to 1.2, then settle to 1.0
          child: _buildBadge(value),
        );
      },
    );
  }

  Widget _buildBadge(double opacity) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
