import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';

/// A reusable profile section item component using Material 3 ListTile
/// Follows UI guidelines and supports future profile sections
class ProfileSectionItem extends StatelessWidget {
  /// Creates a [ProfileSectionItem]
  const ProfileSectionItem({
    required this.title,
    required this.onTap,
    super.key,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  /// The primary title text
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Optional leading icon
  final IconData? icon;

  /// Optional trailing widget (defaults to chevron right)
  final Widget? trailing;

  /// Callback when the item is tapped
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: icon != null
            ? Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 20,
                ),
              )
            : null,
        title: Text(
          title,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitle != null
            ? Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  subtitle!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
        trailing:
            trailing ??
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
              size: 20,
            ),
        // Ensure proper touch target size
        minVerticalPadding: 12,
        // Enable ink splash effect
        splashColor: AppColors.primary.withValues(alpha: 0.1),
        hoverColor: AppColors.primary.withValues(alpha: 0.05),
      ),
    );
  }
}
