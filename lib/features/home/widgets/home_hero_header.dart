import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/providers/profile_provider.dart';

/// Gradient hero header for the home dashboard.
///
/// Shows a welcoming message in a rounded, water-themed card with
/// decorative blobs in the background.
class HomeHeroHeader extends StatelessWidget {
  /// Creates a gradient hero header for the home dashboard.
  const HomeHeroHeader({
    super.key,
    this.title = 'Welcome Back',
    this.subtitle,
  });

  /// Main heading text displayed in the hero.
  final String title;

  /// Optional subtitle displayed below the main heading.
  final String? subtitle;

  /// Builds the default subtitle using the pet name from profile, if available.
  String _buildDefaultSubtitle(WidgetRef ref) {
    final petName = ref.watch(petNameProvider);
    if (petName != null && petName.isNotEmpty) {
      return "Let's keep $petName hydrated this week";
    }
    return "Let's keep your cat hydrated this week";
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: Stack(
        children: [
          // Outer surface background with rounded corners
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.surface,
            ),
          ),

          // Inset gradient so color sits slightly away from the border
          Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.heroGradientStart,
                    AppColors.heroGradientEnd,
                  ],
                  stops: [0.05, 0.95],
                ),
              ),
            ),
          ),

          // Decorative blobs behind content
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: const Stack(
                children: [
                  Positioned(
                    top: -40,
                    right: -20,
                    child: _HeroBlob(size: 140),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -20,
                    child: _HeroBlob(size: 110),
                  ),
                  Positioned(
                    top: 40,
                    right: 40,
                    child: _HeroBlob(size: 70),
                  ),
                ],
              ),
            ),
          ),

          // Optional subtle overlay to ensure text contrast
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.black.withValues(alpha: 0.03),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h1.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Consumer(
                  builder: (context, ref, _) {
                    final effectiveSubtitle =
                        subtitle ??
                        _buildDefaultSubtitle(
                          ref,
                        );

                    return Text(
                      effectiveSubtitle,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBlob extends StatelessWidget {
  const _HeroBlob({
    required this.size,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.11),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.11),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
