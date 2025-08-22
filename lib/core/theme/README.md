# HydraCat Theme System

This directory contains the complete design system implementation for HydraCat, based on the UI guidelines.

## Overview

The theme system implements a water-themed design that balances **medical professionalism** with **emotional comfort**. It provides a consistent, accessible, and comforting user experience for cat owners managing fluid therapy.

## Architecture

### Core Files

- **`app_theme.dart`** - Main theme configuration with Material 3 integration
- **`app_text_styles.dart`** - Typography system with Inter (clinical) and Nunito (friendly) fonts
- **`app_spacing.dart`** - Spacing scale and layout constants
- **`app_shadows.dart`** - Shadow definitions for elevation and depth
- **`app_colors.dart`** - Water-themed color palette with semantic color mapping

### Theme Index

- **`theme.dart`** - Exports all theme classes for easy importing

## Usage

### Basic Theme Application

```dart
import 'package:hydracat/core/theme/theme.dart';

// The theme is automatically applied in main.dart
// Access theme colors anywhere in the app:
Container(
  color: AppColors.primary, // Teal #6BB8A8
  child: Text('Hello', style: AppTextStyles.h1),
)
```

### Typography

```dart
// Clinical data (Inter font)
Text('Fluid intake: 100ml', style: AppTextStyles.clinicalData);

// Friendly headers (Nunito font)
Text('Welcome back!', style: AppTextStyles.h1);

// Supporting text
Text('Last session: 2 hours ago', style: AppTextStyles.caption);
```

### Spacing

```dart
import 'package:hydracat/core/theme/app_spacing.dart';

// Use consistent spacing throughout the app
Padding(
  padding: EdgeInsets.all(AppSpacing.md), // 16px
  child: Column(
    children: [
      Widget1(),
      SizedBox(height: AppSpacing.lg), // 24px
      Widget2(),
    ],
  ),
)
```

### Colors

```dart
// Primary water theme
AppColors.primary        // #6BB8A8 - Main teal
AppColors.primaryLight  // #9DCBBF - Light teal
AppColors.primaryDark   // #4A8A7A - Dark teal

// Semantic colors
AppColors.success        // #E6B35C - Golden amber for achievements
AppColors.warning        // #E87C6B - Soft coral for gentle alerts
AppColors.error          // #DC3545 - Red for critical alerts only

// Context-aware color selection
AppColors.getStressLevelColor('low')    // Returns success color
AppColors.getAlertColor('warning')      // Returns warning color
```

## Design Principles

### 1. Water Theme Integration
- **Primary**: Teal (#6BB8A8) represents water and life
- **Success**: Golden amber (#E6B35C) for achievements and progress
- **Warning**: Soft coral (#E87C6B) for gentle reminders
- **Error**: Traditional red (#DC3545) reserved for critical medical alerts

### 2. Typography Strategy
- **Inter**: Clean, professional font for clinical data and medical content
- **Nunito**: Warm, friendly font for headers and comforting content
- **Hierarchy**: Clear type scale from display (32px) to small (12px)

### 3. Accessibility First
- **Touch Targets**: Minimum 44x44px for all interactive elements
- **Contrast**: High contrast ratios (4.5:1 minimum)
- **Spacing**: Generous spacing to reduce stress and improve usability

### 4. Component Consistency
- **Buttons**: Rounded corners (10px), consistent padding, proper shadows
- **Cards**: Soft borders, rounded corners (12px), subtle shadows
- **Forms**: Clear focus states, consistent styling, accessible labels

## Component Themes

### Buttons
```dart
// Primary button (teal background)
ElevatedButton(
  onPressed: () {},
  child: Text('Log Session'),
)

// Secondary button (teal outline)
OutlinedButton(
  onPressed: () {},
  child: Text('Cancel'),
)
```

### Cards
```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(AppSpacing.md),
    child: Text('Card content'),
  ),
)
```

### Navigation
```dart
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    // ... other items
  ],
)
```

## Future Enhancements

### Dark Theme
- Dark theme is prepared but not fully implemented
- Uses lighter teal (#8FCCB8) for dark mode
- Maintains accessibility and comfort

### Custom Icons
- Water droplet FAB icon
- Streak indicators with water drops
- Progress charts with flowing water elements

### Animations
- Gentle flowing transitions (0.3s cubic-bezier)
- Water-themed celebration effects
- Stress-reducing micro-interactions

## Migration Guide

### From Old Color System
```dart
// Old
Color(0xFF2196F3)  // Blue
Color(0xFF4CAF50)  // Green

// New
AppColors.primary   // Teal #6BB8A8
AppColors.success   // Amber #E6B35C
```

### From Hardcoded Values
```dart
// Old
EdgeInsets.all(16.0)
TextStyle(fontSize: 24.0)

// New
EdgeInsets.all(AppSpacing.md)
AppTextStyles.h1
```

## Best Practices

1. **Always use theme constants** instead of hardcoded values
2. **Choose typography based on content type** (clinical vs. friendly)
3. **Use semantic colors** for alerts and status indicators
4. **Maintain consistent spacing** using AppSpacing constants
5. **Test accessibility** with high contrast and screen readers

## Support

For questions about the theme system or design guidelines, refer to:
- `.cursor/rules/ui_guidelines.md` - Complete UI guidelines
- This README - Implementation details
- `app_theme.dart` - Theme configuration examples
