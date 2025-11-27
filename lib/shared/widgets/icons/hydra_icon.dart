import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydracat/core/icons/icon_provider.dart';

/// Platform-adaptive icon widget for HydraCat.
///
/// Automatically selects Material or Cupertino icons based on platform,
/// with support for custom SVG icons for brand elements.
class HydraIcon extends StatelessWidget {
  /// Creates a HydraIcon with the specified icon name.
  const HydraIcon({
    required this.icon,
    super.key,
    this.size = 24.0,
    this.color,
    this.semanticLabel,
  });

  /// The icon name from AppIcons constants.
  final String icon;

  /// The size of the icon.
  final double size;

  /// The color of the icon. If null, uses theme's icon color.
  final Color? color;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    // Cache platform detection (performance optimization)
    final platform = Theme.of(context).platform;
    final isCupertino = platform == TargetPlatform.iOS ||
        platform == TargetPlatform.macOS;

    final iconColor =
        color ?? Theme.of(context).iconTheme.color ?? Colors.black;

    // Check if this is a custom icon (SVG)
    final customAsset = IconProvider.getCustomIconAsset(icon);
    if (customAsset != null) {
      return _buildCustomIcon(
        context,
        customAsset,
        icon,
        iconColor,
        isCupertino,
      );
    }

    // Platform-specific icon resolution
    final iconData = IconProvider.resolveIconData(icon, isCupertino: isCupertino);
    if (iconData == null) {
      // Fallback if resolution fails
      final fallback = IconProvider.getCustomIconFallback(icon, isCupertino);
      return Icon(
        fallback,
        size: size,
        color: iconColor,
        semanticLabel: semanticLabel,
      );
    }

    return Icon(
      iconData,
      size: size,
      color: iconColor,
      semanticLabel: semanticLabel,
    );
  }

  Widget _buildCustomIcon(
    BuildContext context,
    String assetPath,
    String iconName,
    Color iconColor,
    bool isCupertino,
  ) {
    final fallback = IconProvider.getCustomIconFallback(iconName, isCupertino);

    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          assetPath,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          placeholderBuilder: (context) => Icon(
            fallback,
            size: size,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
