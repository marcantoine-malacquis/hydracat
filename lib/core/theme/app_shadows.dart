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
  /// Shadow for cards and elevated surfaces
  static const BoxShadow card = BoxShadow(
    color: Color(0x0F000000), // rgba(0, 0, 0, 0.06)
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
}
