import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/icons/icon_provider.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/shared/widgets/cards/hydra_card.dart';
import 'package:hydracat/shared/widgets/icons/icon_container.dart';

/// A unified navigation card component for consistent navigation UI.
///
/// This component replaces both ProfileNavigationTile and InsightsCard,
/// providing a standardized look across the app with support for:
/// - Icon with subtle background circle (Option B design)
/// - Title and optional metadata/subtitle
/// - Chevron indicator
/// - Tap interaction
///
/// Example usage:
/// ```dart
/// NavigationCard(
///   title: 'Medication Schedule',
///   icon: Icons.medication,
///   metadata: '3 medications',
///   onTap: () => context.go('/profile/medication'),
/// )
/// ```
class NavigationCard extends StatelessWidget {
  /// Creates a [NavigationCard].
  const NavigationCard({
    required this.title,
    required this.onTap,
    super.key,
    this.metadata,
    this.icon,
    this.customIconAsset,
    this.iconColor,
    this.trailing,
    this.showBackgroundCircle = true,
    this.margin,
  });

  /// The primary title text
  final String title;

  /// Optional metadata/subtitle text (e.g., "3 medications", "Stage 2")
  final String? metadata;

  /// Optional leading icon (IconData)
  final IconData? icon;

  /// Optional custom SVG icon asset path
  final String? customIconAsset;

  /// Optional icon color (defaults to primary color)
  final Color? iconColor;

  /// Optional trailing widget (defaults to chevron right)
  final Widget? trailing;

  /// Whether to show background circle on icon (defaults to true)
  final bool showBackgroundCircle;

  /// Optional margin (defaults to CardConstants.cardMargin)
  final EdgeInsetsGeometry? margin;

  /// Callback when the card is tapped
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HydraCard(
      onTap: onTap,
      margin: margin ?? CardConstants.cardMargin,
      padding: CardConstants.contentPadding,
      borderColor: CardConstants.cardBorderColor(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: CardConstants.iconContainerSize,
        ),
        child: Row(
          children: [
            // Leading icon with background circle
            if (icon != null || customIconAsset != null) ...[
              IconContainer(
                icon: icon,
                customIconAsset: customIconAsset,
                color: iconColor ?? theme.colorScheme.primary,
                showBackgroundCircle: showBackgroundCircle,
              ),
              const SizedBox(width: AppSpacing.md),
            ],

            // Title and metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    title,
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Metadata/subtitle
                  if (metadata != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      metadata!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Trailing widget (chevron by default)
            trailing ??
                Builder(
                  builder: (context) {
                    final platform = Theme.of(context).platform;
                    final isCupertino =
                        platform == TargetPlatform.iOS ||
                        platform == TargetPlatform.macOS;
                    return Icon(
                      IconProvider.resolveIconData(
                        AppIcons.chevronRight,
                        isCupertino: isCupertino,
                      ),
                      color: AppColors.textTertiary,
                      size: 20,
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
