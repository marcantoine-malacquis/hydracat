import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_icons.dart';

/// Platform-aware icon provider that resolves icons based on platform and type.
///
/// Supports:
/// - Material Icons (Android/Web/Desktop)
/// - Cupertino Icons (iOS/macOS)
/// - Custom SVG icons (brand elements)
/// - Custom IconData (for special cases)
class IconProvider {
  IconProvider._();

  /// Resolves an icon for the given icon name and platform.
  ///
  /// Returns IconData for Material/Cupertino icons, or null for custom icons
  /// that need special handling (SVG, etc.).
  static IconData? resolveIconData(
    String iconName, {
    required bool isCupertino,
  }) {
    // Custom icons that use SVG or special handling
    if (_isCustomIcon(iconName)) {
      return null; // Signal to use custom rendering
    }

    // Platform-specific icon resolution
    if (isCupertino) {
      return _resolveCupertinoIcon(iconName);
    } else {
      return _resolveMaterialIcon(iconName);
    }
  }

  /// Checks if an icon requires custom rendering (SVG, etc.)
  static bool _isCustomIcon(String iconName) {
    return iconName == AppIcons.profile || iconName == AppIcons.medication;
    // logSession stays Material for now, will be custom later
  }

  /// Resolves the asset path for custom-rendered icons (SVG, etc.)
  static String? resolveCustomAsset(String iconName) {
    switch (iconName) {
      case AppIcons.medication:
        return 'assets/fonts/icons/medication_icon.svg';
      default:
        return null;
    }
  }

  /// Resolves Material Design icons
  static IconData _resolveMaterialIcon(String iconName) {
    switch (iconName) {
      // Navigation Icons
      case AppIcons.home:
        return Icons.pets;
      case AppIcons.progress:
        return Icons.show_chart;
      case AppIcons.discover:
        return Icons.explore;
      case AppIcons.profile:
        return Icons.person; // Fallback for profile
      case AppIcons.logSession:
        return Icons.water_drop;

      // Session Logging Icons
      case AppIcons.medication:
        return Icons.medication;
      case AppIcons.symptoms:
        return Icons.medical_services;
      case AppIcons.completed:
        return Icons.check_circle;
      case AppIcons.notCompleted:
        return Icons.radio_button_unchecked;
      case AppIcons.inProgress:
        return Icons.pending;

      // Stress Level Icons
      case AppIcons.stressLow:
        return Icons.sentiment_satisfied;
      case AppIcons.stressMedium:
        return Icons.sentiment_neutral;
      case AppIcons.stressHigh:
        return Icons.sentiment_dissatisfied;

      // Notification Icons
      case AppIcons.reminder:
        return Icons.notifications;
      case AppIcons.missedSession:
        return Icons.schedule;
      case AppIcons.streak:
        return Icons.emoji_events;
      case AppIcons.weeklySummary:
        return Icons.summarize;

      // Profile & Settings Icons
      case AppIcons.petProfile:
        return Icons.pets;
      case AppIcons.petProfileOutlined:
        return Icons.pets_outlined;
      case AppIcons.medicalInformation:
        return Icons.medical_information;
      case AppIcons.settings:
        return Icons.settings;
      case AppIcons.export:
        return Icons.picture_as_pdf;
      case AppIcons.inventory:
        return Icons.inventory;
      case AppIcons.inventory2:
        return Icons.inventory_2;
      case AppIcons.weightUnit:
        return Icons.monitor_weight;
      case AppIcons.scale:
        return Icons.scale;
      case AppIcons.theme:
        return Icons.palette;
      case AppIcons.clearCache:
        return Icons.cleaning_services;
      case AppIcons.lightMode:
        return Icons.light_mode_outlined;
      case AppIcons.darkMode:
        return Icons.dark_mode_outlined;

      // Utility Icons
      case AppIcons.add:
        return Icons.add;
      case AppIcons.addCircleOutline:
        return Icons.add_circle_outline;
      case AppIcons.wifiOff:
        return Icons.wifi_off;
      case AppIcons.edit:
        return Icons.edit;
      case AppIcons.delete:
        return Icons.delete_outline;
      case AppIcons.close:
        return Icons.close;
      case AppIcons.back:
        return Icons.arrow_back;
      case AppIcons.forward:
        return Icons.arrow_forward;
      case AppIcons.chevronRight:
        return Icons.chevron_right;
      case AppIcons.chevronLeft:
        return Icons.chevron_left;
      case AppIcons.help:
        return Icons.help_outline;
      case AppIcons.calendar:
        return Icons.calendar_month;
      case AppIcons.locationOn:
        return Icons.location_on;
      case AppIcons.refresh:
        return Icons.refresh;
      case AppIcons.cancel:
        return Icons.cancel;
      case AppIcons.remove:
        return Icons.remove;
      case AppIcons.changeHistory:
        return Icons.change_history;
      case AppIcons.waterDropOutlined:
        return Icons.water_drop_outlined;
      case AppIcons.errorOutline:
        return Icons.error_outline;
      case AppIcons.privacyTip:
        return Icons.privacy_tip_outlined;
      case AppIcons.info:
        return Icons.info_outline;
      case AppIcons.warning:
        return Icons.warning;

      // Auth Icons
      case AppIcons.email:
        return Icons.email;
      case AppIcons.lock:
        return Icons.lock;
      case AppIcons.lockOutline:
        return Icons.lock_outline;
      case AppIcons.visibility:
        return Icons.visibility;
      case AppIcons.visibilityOff:
        return Icons.visibility_off;
      case AppIcons.lockReset:
        return Icons.lock_reset;
      case AppIcons.markEmailUnread:
        return Icons.mark_email_unread_outlined;
      case AppIcons.apple:
        return Icons.apple;

      default:
        return Icons.help_outline;
    }
  }

  /// Resolves Cupertino icons for iOS/macOS
  static IconData _resolveCupertinoIcon(String iconName) {
    switch (iconName) {
      // Navigation Icons
      case AppIcons.home:
        return CupertinoIcons.paw;
      case AppIcons.progress:
        return CupertinoIcons.chart_bar_fill;
      case AppIcons.discover:
        return CupertinoIcons.compass_fill;
      case AppIcons.profile:
        return CupertinoIcons.person_fill; // Fallback for profile
      case AppIcons.logSession:
        return CupertinoIcons.drop_fill;

      // Session Logging Icons
      case AppIcons.medication:
        // No pill icon in Cupertino, using square
        return CupertinoIcons.square_fill;
      case AppIcons.symptoms:
        return CupertinoIcons.heart_fill;
      case AppIcons.completed:
        return CupertinoIcons.check_mark_circled_solid;
      case AppIcons.notCompleted:
        return CupertinoIcons.circle;
      case AppIcons.inProgress:
        return CupertinoIcons.clock_fill;

      // Stress Level Icons
      case AppIcons.stressLow:
        return CupertinoIcons.smiley_fill;
      case AppIcons.stressMedium:
        return CupertinoIcons.smiley;
      case AppIcons.stressHigh:
        // Using same as low, can be customized
        return CupertinoIcons.smiley_fill;

      // Notification Icons
      case AppIcons.reminder:
        return CupertinoIcons.bell_fill;
      case AppIcons.missedSession:
        return CupertinoIcons.clock_fill;
      case AppIcons.streak:
        return CupertinoIcons.star_fill;
      case AppIcons.weeklySummary:
        return CupertinoIcons.doc_text_fill;

      // Profile & Settings Icons
      case AppIcons.petProfile:
        return CupertinoIcons.paw;
      case AppIcons.petProfileOutlined:
        return CupertinoIcons.person_2;
      case AppIcons.medicalInformation:
        return CupertinoIcons.doc_text_search;
      case AppIcons.settings:
        return CupertinoIcons.settings;
      case AppIcons.export:
        return CupertinoIcons.doc_fill;
      case AppIcons.inventory:
        return CupertinoIcons.archivebox_fill;
      case AppIcons.inventory2:
        return CupertinoIcons.archivebox_fill;
      case AppIcons.weightUnit:
        return CupertinoIcons.square_grid_2x2;
      case AppIcons.scale:
        // No direct scale icon in Cupertino, using square_grid as alternative
        return CupertinoIcons.square_grid_2x2;
      case AppIcons.theme:
        return CupertinoIcons.paintbrush_fill;
      case AppIcons.clearCache:
        return CupertinoIcons.trash_fill;
      case AppIcons.lightMode:
        return CupertinoIcons.sun_max;
      case AppIcons.darkMode:
        return CupertinoIcons.moon;

      // Utility Icons
      case AppIcons.add:
        return CupertinoIcons.add;
      case AppIcons.addCircleOutline:
        return CupertinoIcons.add_circled;
      case AppIcons.wifiOff:
        return CupertinoIcons.wifi_slash;
      case AppIcons.edit:
        return CupertinoIcons.pencil;
      case AppIcons.delete:
        return CupertinoIcons.delete;
      case AppIcons.close:
        return CupertinoIcons.xmark;
      case AppIcons.back:
        return CupertinoIcons.arrow_left;
      case AppIcons.forward:
        return CupertinoIcons.arrow_right;
      case AppIcons.chevronRight:
        return CupertinoIcons.chevron_right;
      case AppIcons.chevronLeft:
        return CupertinoIcons.chevron_left;
      case AppIcons.help:
        return CupertinoIcons.question_circle;
      case AppIcons.calendar:
        return CupertinoIcons.calendar;
      case AppIcons.locationOn:
        return CupertinoIcons.location_fill;
      case AppIcons.refresh:
        return CupertinoIcons.arrow_clockwise;
      case AppIcons.cancel:
        return CupertinoIcons.xmark_circle;
      case AppIcons.remove:
        return CupertinoIcons.minus;
      case AppIcons.changeHistory:
        return CupertinoIcons.triangle_fill;
      case AppIcons.waterDropOutlined:
        return CupertinoIcons.drop;
      case AppIcons.errorOutline:
        return CupertinoIcons.exclamationmark_triangle;
      case AppIcons.privacyTip:
        return CupertinoIcons.shield_fill;
      case AppIcons.info:
        return CupertinoIcons.info;
      case AppIcons.warning:
        return CupertinoIcons.exclamationmark_triangle;

      // Auth Icons
      case AppIcons.email:
        return CupertinoIcons.mail;
      case AppIcons.lock:
        return CupertinoIcons.lock;
      case AppIcons.lockOutline:
        return CupertinoIcons.lock;
      case AppIcons.visibility:
        return CupertinoIcons.eye;
      case AppIcons.visibilityOff:
        return CupertinoIcons.eye_slash;
      case AppIcons.lockReset:
        return CupertinoIcons.lock_rotation;
      case AppIcons.markEmailUnread:
        return CupertinoIcons.mail;
      case AppIcons.apple:
        // CupertinoIcons doesn't have apple_logo, use a fallback
        return CupertinoIcons.app_badge;

      default:
        return CupertinoIcons.question;
    }
  }

  /// Gets the asset path for custom SVG icons
  static String? getCustomIconAsset(String iconName) {
    switch (iconName) {
      case AppIcons.profile:
        return 'assets/fonts/icons/cat_profile_icon_nav.svg';
      // Add more custom SVG icons here
      default:
        return null;
    }
  }

  /// Gets the platform-specific asset path for icons that have
  /// custom SVG variants
  /// Returns the custom asset path for iOS/macOS, null for other platforms
  static String? getPlatformSpecificIconAsset(
    String iconName, {
    required bool isCupertino,
  }) {
    if (!isCupertino) {
      return null;
    }

    switch (iconName) {
      case AppIcons.scale:
        return 'assets/fonts/icons/SF_Symboles/weight.svg';
      default:
        return null;
    }
  }

  /// Gets fallback IconData for custom icons if SVG fails
  static IconData getCustomIconFallback(
    String iconName, {
    required bool isCupertino,
  }) {
    switch (iconName) {
      case AppIcons.profile:
        return isCupertino ? CupertinoIcons.person_fill : Icons.person;
      default:
        return isCupertino ? CupertinoIcons.question : Icons.help_outline;
    }
  }
}
