import 'package:flutter/material.dart';

/// Typography system for the HydraCat application.
/// Implements the type scale and font hierarchy from the UI guidelines.
class AppTextStyles {
  // Private constructor to prevent instantiation
  AppTextStyles._();

  // Font families
  /// Primary font for clinical data and professional content
  static const String _fontFamilyInter = 'Inter';

  /// Secondary font for friendly, comforting headers
  static const String _fontFamilyNunito = 'Nunito';

  // Display text - App title, major headings
  /// Display text style - 32px, tight, semi-bold
  static const TextStyle display = TextStyle(
    fontSize: 32,
    height: 1.2,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamilyNunito,
  );

  // H1 - Screen titles
  /// H1 text style - 24px, normal, semi-bold
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    height: 1.3,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamilyNunito,
  );

  // H2 - Section headers
  /// H2 text style - 20px, relaxed, medium
  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    height: 1.4,
    fontWeight: FontWeight.w500,
    fontFamily: _fontFamilyNunito,
  );

  // H3 - Subsection headers
  /// H3 text style - 18px, relaxed, medium
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    height: 1.4,
    fontWeight: FontWeight.w500,
    fontFamily: _fontFamilyNunito,
  );

  // Body - Main content
  /// Body text style - 16px, comfortable, regular
  static const TextStyle body = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamilyInter,
  );

  // Caption - Supporting info
  /// Caption text style - 14px, normal, regular
  static const TextStyle caption = TextStyle(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamilyInter,
  );

  // Small - Timestamps, metadata
  /// Small text style - 12px, tight, regular
  static const TextStyle small = TextStyle(
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamilyInter,
  );

  // Clinical data specific styles
  /// Clinical data text style - body with medium weight
  static const TextStyle clinicalData = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w500,
    fontFamily: _fontFamilyInter,
  );

  /// Timestamp text style - caption with secondary color
  static const TextStyle timestamp = TextStyle(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamilyInter,
  );

  // Button text styles
  /// Primary button text style
  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w500,
    fontFamily: _fontFamilyInter,
  );

  /// Secondary button text style
  static const TextStyle buttonSecondary = TextStyle(
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w500,
    fontFamily: _fontFamilyInter,
  );

  // Navigation text styles
  /// Navigation label text style
  static const TextStyle navigationLabel = TextStyle(
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w500,
    fontFamily: _fontFamilyInter,
  );

  // Helper methods for creating variants
  /// Create a clinical data style with custom color
  static TextStyle clinicalDataWithColor(Color color) {
    return clinicalData.copyWith(color: color);
  }

  /// Create a timestamp style with custom color
  static TextStyle timestampWithColor(Color color) {
    return timestamp.copyWith(color: color);
  }

  /// Create a button style with custom color
  static TextStyle buttonWithColor(Color color) {
    return buttonPrimary.copyWith(color: color);
  }
}
