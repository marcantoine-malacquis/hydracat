import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';

/// Platform-adaptive list wrapper for HydraCat.
///
/// Renders Material `ListView/ListTile` on Android/other platforms and
/// `CupertinoListSection/CupertinoListTile` on iOS/macOS.
class HydraList extends StatelessWidget {
  /// Creates a platform-adaptive list.
  const HydraList({
    required this.items,
    this.padding,
    this.header,
    this.footer,
    this.insetGrouped = true,
    this.showDividers = true,
    this.physics,
    this.shrinkWrap = false,
    this.controller,
    this.primary,
    this.sectionBackgroundColor,
    this.elevation = 0,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.dividerColor,
    this.dividerThickness = 1.0,
    this.dividerIndent = 0,
    this.dividerEndIndent = 0,
    super.key,
  });

  /// Items to render.
  final List<HydraListItem> items;

  /// List padding.
  final EdgeInsetsGeometry? padding;

  /// Optional header shown above the list (Cupertino section header).
  final Widget? header;

  /// Optional footer shown below the list (Cupertino section footer).
  final Widget? footer;

  /// Whether to use inset grouped style on Cupertino.
  final bool insetGrouped;

  /// Whether to render dividers between items.
  final bool showDividers;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Whether the list should shrink-wrap its content.
  final bool shrinkWrap;

  /// Optional scroll controller.
  final ScrollController? controller;

  /// Whether this is the primary scroll view.
  final bool? primary;

  /// Optional background color for the section (Cupertino).
  /// Defaults to transparent.
  final Color? sectionBackgroundColor;

  /// Shadow elevation for the list container.
  final double elevation;

  /// Border radius applied when elevation > 0.
  final BorderRadius borderRadius;

  /// Optional divider color.
  final Color? dividerColor;

  /// Thickness of dividers.
  final double dividerThickness;

  /// Start indent for dividers.
  final double dividerIndent;

  /// End indent for dividers.
  final double dividerEndIndent;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isCupertino =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    if (isCupertino) {
      return _wrapWithElevation(
        _buildCupertino(context),
      );
    }

    return _wrapWithElevation(
      _buildMaterial(context),
    );
  }

  Widget _wrapWithElevation(Widget child) {
    if (elevation <= 0) return child;

    return Material(
      elevation: elevation,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      color: Colors.transparent,
      child: child,
    );
  }

  Widget _buildMaterial(BuildContext context) {
    final resolvedPadding = padding ?? EdgeInsets.zero;

    if (showDividers) {
      final resolvedDividerColor =
          dividerColor ?? Theme.of(context).dividerColor;
      return ListView.separated(
        padding: resolvedPadding,
        controller: controller,
        primary: primary,
        physics: physics,
        shrinkWrap: shrinkWrap,
        itemCount: items.length,
        itemBuilder: (context, index) => HydraListTile.fromItem(
          items[index],
        ),
        separatorBuilder: (context, _) => Divider(
          height: 1,
          thickness: dividerThickness,
          color: resolvedDividerColor,
          indent: 0,
          endIndent: 0,
        ),
      );
    }

    return ListView.builder(
      padding: resolvedPadding,
      controller: controller,
      primary: primary,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: items.length,
      itemBuilder: (context, index) => HydraListTile.fromItem(
        items[index],
      ),
    );
  }

  Widget _buildCupertino(BuildContext context) {
    final children = items
        .map(
          HydraListTile.fromItem,
        )
        .toList(growable: false);

    if (insetGrouped) {
      return CupertinoListSection.insetGrouped(
        header: header,
        footer: footer,
        separatorColor: showDividers
            ? (dividerColor ?? CupertinoColors.separator)
            : Colors.transparent,
        backgroundColor: sectionBackgroundColor ?? Colors.transparent,
        additionalDividerMargin: 0,
        children: children,
      );
    }

    return CupertinoListSection(
      header: header,
      footer: footer,
      separatorColor: showDividers
          ? (dividerColor ?? CupertinoColors.separator)
          : Colors.transparent,
      backgroundColor: sectionBackgroundColor ?? Colors.transparent,
      additionalDividerMargin: 0,
      children: children,
    );
  }
}

/// Simple data model for a Hydra list row.
class HydraListItem {
  /// Creates a Hydra list item.
  const HydraListItem({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.contentPadding,
    this.isDestructive = false,
    this.showChevron = false,
    this.isSelected = false,
    this.showSelectionCheck = true,
    this.selectedBackgroundColor,
  });

  /// The title of the list item.
  final Widget title;

  /// The subtitle of the list item.
  final Widget? subtitle;

  /// The leading widget of the list item.
  final Widget? leading;

  /// The trailing widget of the list item.
  final Widget? trailing;

  /// The callback to be called when the list item is tapped.
  final VoidCallback? onTap;

  /// Whether the list item is enabled.
  final bool enabled;

  /// The content padding of the list item.
  final EdgeInsetsGeometry? contentPadding;

  /// Whether the list item is destructive.
  final bool isDestructive;

  /// Whether to show a chevron icon.
  final bool showChevron;

  /// Whether this item is currently selected.
  final bool isSelected;

  /// Whether to show a selection checkmark when [isSelected] is true.
  final bool showSelectionCheck;

  /// Optional background color when selected (falls back to platform default).
  final Color? selectedBackgroundColor;
}

/// Platform-adaptive list tile used by [HydraList] and available standalone.
class HydraListTile extends StatelessWidget {
  /// Creates a platform-adaptive list tile.
  const HydraListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.contentPadding,
    this.isDestructive = false,
    this.showChevron = false,
    this.isSelected = false,
    this.showSelectionCheck = true,
    this.selectedBackgroundColor,
    super.key,
  });

  /// Creates a Hydra list tile from a Hydra list item.
  factory HydraListTile.fromItem(HydraListItem item) {
    return HydraListTile(
      title: item.title,
      subtitle: item.subtitle,
      leading: item.leading,
      trailing: item.trailing,
      onTap: item.onTap,
      enabled: item.enabled,
      contentPadding: item.contentPadding,
      isDestructive: item.isDestructive,
      showChevron: item.showChevron,
      isSelected: item.isSelected,
      showSelectionCheck: item.showSelectionCheck,
      selectedBackgroundColor: item.selectedBackgroundColor,
    );
  }

  /// The title of the list tile.
  final Widget title;

  /// The subtitle of the list tile.
  final Widget? subtitle;

  /// The leading widget of the list tile.
  final Widget? leading;

  /// The trailing widget of the list tile.
  final Widget? trailing;

  /// The callback to be called when the list tile is tapped.
  final VoidCallback? onTap;

  /// Whether the list tile is enabled.
  final bool enabled;

  /// The content padding of the list tile.
  final EdgeInsetsGeometry? contentPadding;

  /// Whether the list tile is destructive.
  final bool isDestructive;

  /// Whether to show a chevron icon.
  final bool showChevron;

  /// Whether this tile is currently selected.
  final bool isSelected;

  /// Whether to show a selection checkmark when [isSelected] is true.
  final bool showSelectionCheck;

  /// Optional background color when selected (falls back to platform default).
  final Color? selectedBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isCupertino =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    if (isCupertino) {
      return _buildCupertino(context);
    }

    return _buildMaterial(context);
  }

  Widget _buildMaterial(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = isDestructive ? theme.colorScheme.error : null;
    final selectedColor = theme.colorScheme.primary;
    final selectedTileColor =
        selectedBackgroundColor ??
        AppColors.primaryLight.withValues(alpha: 0.25);

    return ListTile(
      leading: leading,
      title: DefaultTextStyle.merge(
        style: TextStyle(color: textColor),
        child: title,
      ),
      subtitle: subtitle != null
          ? DefaultTextStyle.merge(
              style: TextStyle(color: textColor),
              child: subtitle!,
            )
          : null,
      trailing:
          trailing ??
          (showChevron
              ? const Icon(Icons.chevron_right)
              : (isSelected && showSelectionCheck
                    ? Icon(
                        Icons.check,
                        color: selectedColor,
                      )
                    : null)),
      enabled: enabled,
      contentPadding: contentPadding,
      selected: isSelected,
      selectedTileColor: isSelected ? selectedTileColor : null,
      onTap: enabled ? onTap : null,
    );
  }

  Widget _buildCupertino(BuildContext context) {
    final textColor = isDestructive ? CupertinoColors.destructiveRed : null;
    final selectedColor = CupertinoTheme.of(context).primaryColor;
    final selectedBackground =
        selectedBackgroundColor ??
        AppColors.primaryLight.withValues(alpha: 0.25);

    final tile = CupertinoListTile(
      leading: leading,
      title: DefaultTextStyle.merge(
        style: TextStyle(color: textColor),
        child: title,
      ),
      subtitle: subtitle != null
          ? DefaultTextStyle.merge(
              style: TextStyle(color: textColor),
              child: subtitle!,
            )
          : null,
      trailing:
          trailing ??
          (showChevron
              ? const CupertinoListTileChevron()
              : (isSelected && showSelectionCheck
                    ? Icon(
                        CupertinoIcons.check_mark_circled_solid,
                        color: selectedColor,
                      )
                    : null)),
      onTap: enabled ? onTap : null,
      padding: contentPadding,
    );

    if (!isSelected) {
      return tile;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selectedBackground,
      ),
      child: tile,
    );
  }
}
