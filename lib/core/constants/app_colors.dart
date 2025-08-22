import 'package:flutter/material.dart';

/// Constants for all app colors used throughout the HydraCat application.
/// Implements the water-themed color palette from the UI guidelines.
class AppColors {
  // Primary Colors - Water Theme
  /// Primary teal color - Main brand color
  static const Color primary = Color(0xFF6BB8A8);

  /// Primary light variant - Hover states, backgrounds
  static const Color primaryLight = Color(0xFF9DCBBF);

  /// Primary dark variant - Active states, emphasis
  static const Color primaryDark = Color(0xFF4A8A7A);

  // Background Colors
  /// Background color - Warm off-white
  static const Color background = Color(0xFFF6F4F2);

  /// Surface color - Cards, elevated surfaces
  static const Color surface = Color(0xFFFFFFFF);

  // Accent Colors
  /// Success color - Muted golden amber for achievements
  static const Color success = Color(0xFFE6B35C);

  /// Success light variant
  static const Color successLight = Color(0xFFF0C980);

  /// Success dark variant
  static const Color successDark = Color(0xFFD4A142);

  /// Warning color - Soft coral for gentle alerts
  static const Color warning = Color(0xFFE87C6B);

  /// Warning light variant
  static const Color warningLight = Color(0xFFEDA08F);

  /// Warning dark variant
  static const Color warningDark = Color(0xFFDC5A47);

  /// Error color - Traditional red for critical alerts only
  static const Color error = Color(0xFFDC3545);

  /// Error light variant
  static const Color errorLight = Color(0xFFE85D6B);

  /// Error dark variant
  static const Color errorDark = Color(0xFFC82333);

  // Neutral Colors
  /// Text primary color - Main content
  static const Color textPrimary = Color(0xFF2D3436);

  /// Text secondary color - Supporting text
  static const Color textSecondary = Color(0xFF636E72);

  /// Text tertiary color - Placeholder, disabled
  static const Color textTertiary = Color(0xFFB2BEC3);

  /// Border color - Soft borders
  static const Color border = Color(0xFFDDD6CE);

  /// Divider color - Section separators
  static const Color divider = Color(0xFFE5E5E5);

  /// Disabled color - Disabled backgrounds
  static const Color disabled = Color(0xFFF1F2F3);

  // Semantic Color Mappings
  /// Text color on primary background
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Text color on secondary background
  static const Color onSecondary = Color(0xFFFFFFFF);

  /// Text color on background
  static const Color onBackground = textPrimary;

  /// Text color on surface
  static const Color onSurface = textPrimary;

  // Legacy Support (deprecated - use new color names)
  /// @deprecated Use primary instead
  static const Color primaryVariant = primaryDark;

  /// @deprecated Use success instead
  static const Color secondary = success;

  /// @deprecated Use info instead
  static const Color info = primary;

  // Dark Theme Variants (Future Implementation)
  /// Dark theme background color
  static const Color darkBackground = Color(0xFF1A1A1A);

  /// Dark theme surface color
  static const Color darkSurface = Color(0xFF2A2A2A);

  /// Dark theme primary color - Lighter teal for dark mode
  static const Color darkPrimary = Color(0xFF8FCCB8);

  /// Text color on dark background
  static const Color darkOnBackground = Color(0xFFE0E0E0);

  /// Text color on dark surface
  static const Color darkOnSurface = Color(0xFFE0E0E0);

  // Color Usage Contexts

  /// Get color for clinical data display
  static Color getClinicalDataColor({required bool isHighlighted}) {
    return isHighlighted ? primary : textPrimary;
  }

  /// Get color for stress level visualization
  static Color getStressLevelColor(String stressLevel) {
    switch (stressLevel.toLowerCase()) {
      case 'low':
        return success;
      case 'medium':
        return warning;
      case 'high':
        return warningDark;
      default:
        return textSecondary;
    }
  }

  /// Get color for alert severity
  static Color getAlertColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return error;
      case 'warning':
        return warning;
      case 'info':
        return primary;
      default:
        return textSecondary;
    }
  }
}
