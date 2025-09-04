import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_icons.dart';

/// A consistent icon widget for HydraCat application.
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
    return Icon(
      _getIconData(icon),
      size: size,
      color: color ?? Theme.of(context).iconTheme.color,
      semanticLabel: semanticLabel,
    );
  }

  /// Converts string icon names to IconData.
  /// Uses Material Icons for now, can be extended for custom icons later.
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case AppIcons.home:
        return Icons.home;
      case AppIcons.profile:
        return Icons.person;
      case AppIcons.petProfile:
        return Icons.pets;
      case AppIcons.learn:
        return Icons.menu_book;
      case AppIcons.missedSession:
        return Icons.schedule;
      case AppIcons.logSession:
        return Icons.water_drop;
      case AppIcons.progress:
        return Icons.show_chart;
      case AppIcons.completed:
        return Icons.check_circle;
      case AppIcons.notCompleted:
        return Icons.radio_button_unchecked;
      case AppIcons.inProgress:
        return Icons.pending;
      case AppIcons.stressLow:
        return Icons.sentiment_satisfied;
      case AppIcons.stressMedium:
        return Icons.sentiment_neutral;
      case AppIcons.stressHigh:
        return Icons.sentiment_dissatisfied;
      case AppIcons.reminder:
        return Icons.notifications;
      case AppIcons.streak:
        return Icons.emoji_events;
      case AppIcons.weeklySummary:
        return Icons.summarize;
      case AppIcons.settings:
        return Icons.settings;
      case AppIcons.export:
        return Icons.picture_as_pdf;
      case AppIcons.inventory:
        return Icons.inventory;
      case AppIcons.add:
        return Icons.add;
      case AppIcons.edit:
        return Icons.edit;
      case AppIcons.delete:
        return Icons.delete;
      case AppIcons.close:
        return Icons.close;
      case AppIcons.back:
        return Icons.arrow_back;
      case AppIcons.forward:
        return Icons.arrow_forward;

      default:
        return Icons.help_outline;
    }
  }
}
