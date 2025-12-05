import 'package:flutter/material.dart';

/// Shadow definitions for consistent elevation throughout the
/// HydraCat application.
/// Based on the UI guidelines for soft, comforting shadows.
class AppShadows {
  // Private constructor to prevent instantiation
  AppShadows._();

  // Primary button shadow
  /// Shadow for primary buttons (log session, save, etc.)
  static const BoxShadow primaryButton = BoxShadow(
    color: Color(0x4D6BB8A8), // rgba(107, 184, 168, 0.3)
    offset: Offset(0, 2),
    blurRadius: 8,
  );

  // FAB button shadow
  /// Shadow for the special FAB log button
  static const BoxShadow fabButton = BoxShadow(
    color: Color(0x666BB8A8), // rgba(107, 184, 168, 0.4)
    offset: Offset(0, 4),
    blurRadius: 12,
  );

  // Card and container shadows

  /// Subtle shadow for standard cards and containers
  /// Use for: Regular cards, list items, standard containers
  /// Color: rgba(0, 0, 0, 0.06)
  static const BoxShadow cardSubtle = BoxShadow(
    color: Color(0x0F000000), // rgba(0, 0, 0, 0.06)
    offset: Offset(0, 2),
    blurRadius: 8,
  );

  /// Elevated shadow for prominent cards
  /// Use for: Feature cards (water drop progress), important containers,
  /// hero sections
  /// Color: rgba(0, 0, 0, 0.08)
  static const BoxShadow cardElevated = BoxShadow(
    color: Color(0x14000000), // rgba(0, 0, 0, 0.08)
    offset: Offset(0, 4),
    blurRadius: 12,
  );

  /// Popup shadow for modals and overlays
  /// Use for: Dialogs, bottom sheets, popups, overlays
  /// Color: rgba(0, 0, 0, 0.12)
  static const BoxShadow cardPopup = BoxShadow(
    color: Color(0x1F000000), // rgba(0, 0, 0, 0.12)
    offset: Offset(0, 6),
    blurRadius: 16,
  );

  /// @deprecated Use cardSubtle instead for clarity
  /// Shadow for cards and elevated surfaces (default/subtle)
  static const BoxShadow card = cardSubtle;

  /// Tooltip shadow for chart labels and floating indicators
  /// Use for: Chart tooltips, floating labels, overlay indicators
  /// Color: rgba(0, 0, 0, 0.08)
  static const BoxShadow tooltip = BoxShadow(
    color: Color(0x14000000), // rgba(0, 0, 0, 0.08)
    offset: Offset(0, 2),
    blurRadius: 8,
  );

  // Navigation bar shadow
  /// Shadow for the bottom navigation bar
  static const BoxShadow navigationBar = BoxShadow(
    color: Color(0x14000000), // rgba(0, 0, 0, 0.08)
    offset: Offset(0, -2),
    blurRadius: 12,
  );

  // Hover state shadows
  /// Shadow for hover states on interactive elements
  static const BoxShadow hover = BoxShadow(
    color: Color(0x1A000000), // rgba(0, 0, 0, 0.1)
    offset: Offset(0, 4),
    blurRadius: 12,
  );

  // Focus state shadows
  /// Shadow for focus states on interactive elements
  static const BoxShadow focus = BoxShadow(
    color: Color(0x4D6BB8A8), // rgba(107, 184, 168, 0.3)
    spreadRadius: 2,
  );

  // Navigation icon shadows
  /// Shadow for navigation icons when pressed
  static const BoxShadow navigationIconPressed = BoxShadow(
    color: Color(0x666BB8A8), // rgba(107, 184, 168, 0.4) - More visible
    offset: Offset(0, 4), // Larger offset
    blurRadius: 12, // More blur for better effect
    spreadRadius: 1, // Add spread for more prominence
  );

  /// Shadow for navigation icons on hover (web/desktop)
  static const BoxShadow navigationIconHover = BoxShadow(
    color: Color(0x1A6BB8A8), // rgba(107, 184, 168, 0.1)
    offset: Offset(0, 1),
    blurRadius: 4,
  );
}
