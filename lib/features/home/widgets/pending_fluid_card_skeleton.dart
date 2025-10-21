import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/shared/widgets/cards/hydra_card.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

/// Skeleton loading widget matching the pending fluid card layout.
///
/// Uses warm neutral shimmer colors from the design system:
/// - Base: #DDD6CE (border color - warm, soft)
/// - Highlight: #F6F4F2 (background color - warm off-white)
class PendingFluidCardSkeleton extends StatelessWidget {
  /// Creates a [PendingFluidCardSkeleton].
  const PendingFluidCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const HydraCard(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          // Icon skeleton (48x48 circle)
          _ShimmerCircle(size: 48),
          SizedBox(width: AppSpacing.sm),

          // Text skeletons (fluid info)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Fluid Therapy" title skeleton
                _ShimmerBar(width: 100, height: 18),
                SizedBox(height: 4),

                // Volume skeleton
                _ShimmerBar(width: 80, height: 16),
              ],
            ),
          ),

          SizedBox(width: AppSpacing.sm),

          // Scheduled times skeleton (right aligned, can be multi-line)
          _ShimmerBar(width: 50, height: 14),

          SizedBox(width: AppSpacing.xs),

          // Chevron skeleton
          _ShimmerCircle(size: 20),
        ],
      ),
    );
  }
}

/// Circular shimmer skeleton component.
class _ShimmerCircle extends StatelessWidget {
  const _ShimmerCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(milliseconds: 1500),
      interval: const Duration(milliseconds: 1500),
      color: const Color(0xFFF6F4F2), // Highlight: warm background
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFDDD6CE), // Base: warm border color
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Rectangular shimmer skeleton bar component.
class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(milliseconds: 1500),
      interval: const Duration(milliseconds: 1500),
      color: const Color(0xFFF6F4F2), // Highlight: warm background
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFDDD6CE), // Base: warm border color
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
