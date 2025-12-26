import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';

/// Shared layout component for pet information screens in onboarding
///
/// Provides consistent structure with:
/// - Illustration/icon at top
/// - Title and optional subtitle
/// - Content area for form fields
/// - Consistent spacing and styling
class PetInfoScreenLayout extends StatelessWidget {
  /// Creates a [PetInfoScreenLayout]
  const PetInfoScreenLayout({
    required this.illustration,
    required this.title,
    required this.content,
    super.key,
    this.subtitle,
  });

  /// Widget for illustration or icon at the top
  final Widget illustration;

  /// Screen title
  final String title;

  /// Optional subtitle for additional context
  final String? subtitle;

  /// Form fields and content area
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Illustration
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: illustration,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Title
          Text(
            title,
            style: AppTextStyles.h1.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          // Subtitle (if provided)
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              subtitle!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Content area (form fields)
          content,

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
