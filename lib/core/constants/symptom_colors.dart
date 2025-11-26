import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';

/// Centralized color palette for symptom visualization in charts and analytics.
///
/// Provides a fixed pastel color mapping for each symptom type, following
/// the water-themed design system. Colors are chosen to be visually distinct
/// while maintaining the soft, comforting aesthetic of the app.
class SymptomColors {
  SymptomColors._();

  /// Soft lavender color for symptoms
  static const Color _pastelLavender = Color(0xFFC4B5FD);

  /// Soft aqua/blue color derived from primary palette
  static const Color _pastelAqua = Color(0xFFA8D5E2);

  /// Soft peach color for symptoms
  static const Color _pastelPeach = Color(0xFFF5C9A8);

  /// Private mapping of symptom keys to their assigned pastel colors
  static const Map<String, Color> _symptomColorMap = {
    SymptomType.vomiting: AppColors.primaryLight, // Pastel teal #9DCBBF
    SymptomType.diarrhea: AppColors.successLight, // Pastel amber #F0C980
    SymptomType.energy: AppColors.warningLight, // Pastel coral #EDA08F
    SymptomType.suppressedAppetite: _pastelLavender, // Soft lavender #C4B5FD
    SymptomType.constipation: _pastelAqua, // Soft aqua #A8D5E2
    SymptomType.injectionSiteReaction: _pastelPeach, // Soft peach #F5C9A8
  };

  /// Neutral color for "Other" symptom segments in stacked charts
  ///
  /// Uses a soft neutral derived from textTertiary with reduced opacity
  /// for chart segments, providing a subtle background for grouped symptoms.
  static Color colorForOther() {
    return AppColors.textTertiary.withValues(alpha: 0.35);
  }

  /// Get the assigned color for a specific symptom key.
  ///
  /// Returns the pastel color mapped to the given symptom key.
  /// If the key is invalid or unknown, returns the "Other" color.
  ///
  /// Parameters:
  /// - [symptomKey]: The symptom type key (e.g., `SymptomType.vomiting`)
  ///
  /// Returns:
  /// The color assigned to the symptom, or the "Other" color if invalid.
  static Color colorForSymptom(String symptomKey) {
    if (!SymptomType.isValid(symptomKey)) {
      return colorForOther();
    }
    return _symptomColorMap[symptomKey] ?? colorForOther();
  }
}
