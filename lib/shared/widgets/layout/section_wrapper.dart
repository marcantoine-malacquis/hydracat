import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/app_layout.dart';
import 'package:hydracat/core/theme/app_spacing.dart';

/// A wrapper for content sections that provides consistent spacing
/// and responsive behavior.
class SectionWrapper extends StatelessWidget {
  /// Creates a section wrapper with optional customization.
  const SectionWrapper({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.padding,
    this.margin,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  /// The content of the section.
  final Widget child;

  /// Optional section title.
  final String? title;

  /// Optional section subtitle.
  final String? subtitle;

  /// Internal padding for the section content.
  final EdgeInsetsGeometry? padding;

  /// External margin for the section.
  final EdgeInsetsGeometry? margin;

  /// Cross-axis alignment for the section content.
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final responsivePadding = AppLayout.getResponsiveCardPadding(
          constraints.maxWidth,
        );
        final finalPadding = padding ?? EdgeInsets.all(responsivePadding);

        return Container(
          margin:
              margin ??
              const EdgeInsets.only(bottom: AppSpacing.sectionSpacing),
          child: Column(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
              ],
              Padding(
                padding: finalPadding,
                child: child,
              ),
            ],
          ),
        );
      },
    );
  }
}
