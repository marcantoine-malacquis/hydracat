import 'package:flutter/material.dart';

/// Border radius constants for consistent rounded corners throughout the
/// HydraCat application.
///
/// Establishes a clear hierarchy of border radius values:
/// - **Extra Small (4px)**: Indicators, badges, small decorative elements
/// - **Small (8px)**: Buttons, inputs, chips, small interactive elements
/// - **Medium (12px)**: Cards, standard containers, most surfaces
/// - **Large (16px)**: Dialogs, bottom sheets, modals, prominent containers
/// - **Capsule (999px)**: Pill-shaped buttons and fully rounded elements
class AppBorderRadius {
  // Private constructor to prevent instantiation
  AppBorderRadius._();

  // Base border radius values
  /// Extra small border radius - 4px
  /// Use for: Progress indicators, badges, small decorative elements
  static const double xs = 4;

  /// Small border radius - 8px
  /// Use for: Buttons, text inputs, chips, dropdowns,
  /// small interactive elements
  static const double sm = 8;

  /// Medium border radius - 12px (default for most surfaces)
  /// Use for: Cards, standard containers, selection cards, most surfaces
  static const double md = 12;

  /// Large border radius - 16px
  /// Use for: Dialogs, bottom sheets, modals, large prominent containers
  static const double lg = 16;

  /// Extra large border radius - 20px
  /// Use for: Special large containers, hero elements
  static const double xl = 20;

  /// Capsule border radius - 999px
  /// Use for: Pill-shaped buttons, fully rounded elements (extended FAB, etc.)
  static const double capsule = 999;

  // Semantic border radius values (mapped to base values)

  /// Button border radius (small - 8px)
  static const double button = sm;

  /// Input field border radius (small - 8px)
  static const double input = sm;

  /// Card border radius (medium - 12px)
  static const double card = md;

  /// Dialog border radius (large - 16px)
  static const double dialog = lg;

  /// Bottom sheet border radius (large - 16px)
  static const double bottomSheet = lg;

  /// Modal border radius (large - 16px)
  static const double modal = lg;

  /// Chip border radius (20px - pill-shaped)
  static const double chip = 20;

  /// Dropdown border radius (small - 8px)
  static const double dropdown = sm;

  /// Progress indicator border radius (extra small - 4px)
  static const double progressIndicator = xs;

  /// Badge border radius (extra small - 4px)
  static const double badge = xs;

  /// Navigation indicator border radius (medium - 12px)
  static const double navigationIndicator = md;

  // BorderRadius objects for convenience

  /// Extra small border radius object - 4px
  static BorderRadius get xsRadius => BorderRadius.circular(xs);

  /// Small border radius object - 8px
  static BorderRadius get smRadius => BorderRadius.circular(sm);

  /// Medium border radius object - 12px
  static BorderRadius get mdRadius => BorderRadius.circular(md);

  /// Large border radius object - 16px
  static BorderRadius get lgRadius => BorderRadius.circular(lg);

  /// Extra large border radius object - 20px
  static BorderRadius get xlRadius => BorderRadius.circular(xl);

  /// Capsule border radius object - 999px
  static BorderRadius get capsuleRadius => BorderRadius.circular(capsule);

  /// Button border radius object
  static BorderRadius get buttonRadius => BorderRadius.circular(button);

  /// Input border radius object
  static BorderRadius get inputRadius => BorderRadius.circular(input);

  /// Card border radius object
  static BorderRadius get cardRadius => BorderRadius.circular(card);

  /// Dialog border radius object
  static BorderRadius get dialogRadius => BorderRadius.circular(dialog);

  /// Bottom sheet border radius object
  static BorderRadius get bottomSheetRadius =>
      BorderRadius.circular(bottomSheet);

  /// Modal border radius object
  static BorderRadius get modalRadius => BorderRadius.circular(modal);

  /// Chip border radius object
  static BorderRadius get chipRadius => BorderRadius.circular(chip);

  /// Dropdown border radius object
  static BorderRadius get dropdownRadius => BorderRadius.circular(dropdown);

  /// Navigation indicator border radius object
  static BorderRadius get navigationIndicatorRadius =>
      BorderRadius.circular(navigationIndicator);
}
