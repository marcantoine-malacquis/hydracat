# Card Style Guide

This document provides comprehensive guidelines for using and creating cards throughout the HydraCat application. Following these standards ensures visual consistency and excellent user experience.

## Table of Contents

1. [Overview](#overview)
2. [Card Components](#card-components)
3. [Design Constants](#design-constants)
4. [Usage Guidelines](#usage-guidelines)
5. [Best Practices](#best-practices)
6. [Examples](#examples)

---

## Overview

Cards are a fundamental UI pattern in HydraCat, used to display information, enable navigation, and present treatment data. All cards follow a unified design language with:

- **12px border radius** for consistent rounded corners
- **Flat design** (0 elevation) with subtle borders
- **Icon containers with background circles** for visual hierarchy
- **Standardized spacing** and padding
- **Meaningful metadata** where applicable

---

## Card Components

### 1. NavigationCard

**Purpose:** Unified navigation component for profile sections and insights.

**Location:** `lib/shared/widgets/cards/navigation_card.dart`

**Features:**
- Icon with subtle background circle (56px outer, 40px inner container)
- Title (h3 text style)
- Optional metadata/subtitle (caption text style)
- Chevron indicator
- Tap interaction

**When to Use:**
- Profile section navigation (CKD Profile, Medication Schedule, etc.)
- Insights/Analytics navigation (Injection Sites, Weight tracking, etc.)
- Any screen-to-screen navigation with context

**Example:**
```dart
NavigationCard(
  title: 'Medication Schedule',
  icon: Icons.medication,
  metadata: '3 medications',
  onTap: () => context.go('/profile/medication'),
)
```

**Metadata Best Practices:**
- **CKD Profile:** Show IRIS stage (e.g., "Stage 2")
- **Fluid Schedule:** Show volume + frequency (e.g., "150ml, Once daily")
- **Medication Schedule:** Show count (e.g., "3 medications")
- **Weight:** Show current weight with unit (e.g., "4.2 kg")

---

### 2. HydraCard

**Purpose:** Base card component for all cards in the app.

**Location:** `lib/shared/widgets/cards/hydra_card.dart`

**Features:**
- Configurable padding, margin, border radius, border color
- Optional tap interaction
- Flat design (0 elevation)

**Variants:**
- **HydraSectionCard:** Section card with header and optional actions
- **HydraInfoCard:** Information cards with type-based styling (info, success, warning, error)

**When to Use:**
- As a base for custom card implementations
- When you need a simple container with consistent styling
- Building specialized cards not covered by other components

**Example:**
```dart
HydraCard(
  onTap: () => doSomething(),
  child: Row(
    children: [
      Icon(Icons.info),
      SizedBox(width: 12),
      Text('Custom content'),
    ],
  ),
)
```

---

### 3. PendingTreatmentCard

**Purpose:** Display pending medication treatments on the dashboard.

**Location:** `lib/features/home/widgets/pending_treatment_card.dart`

**Features:**
- Icon with background circle
- Medication name, strength, and dosage
- Scheduled time
- Overdue indicator (3px golden left border)

**When to Use:**
- Dashboard "Today's Treatments" section
- Medication reminder displays

**Example:**
```dart
PendingTreatmentCard(
  treatment: pendingTreatment,
  onTap: () => showTreatmentConfirmation(context),
)
```

---

### 4. PendingFluidCard

**Purpose:** Display pending fluid therapy on the dashboard.

**Location:** `lib/features/home/widgets/pending_fluid_card.dart`

**Features:**
- Icon with background circle
- Remaining volume
- Scheduled times
- Overdue indicator (3px golden left border)

**When to Use:**
- Dashboard "Today's Treatments" section
- Fluid therapy reminder displays

**Example:**
```dart
PendingFluidCard(
  fluidTreatment: pendingFluid,
  onTap: () => showFluidConfirmation(context),
)
```

---

### 5. SelectionCard

**Purpose:** Interactive selection cards with animation.

**Location:** `lib/shared/widgets/selection_card.dart`

**Features:**
- 3D press effect with scale animation
- Elevation changes (2→8)
- Square or rectangle layouts
- Loading overlay support

**When to Use:**
- Onboarding screens
- Choice/selection interfaces
- Interactive option displays

**Example:**
```dart
SelectionCard(
  icon: Icons.medication_outlined,
  title: 'Track Medications',
  subtitle: 'Set up medication schedules',
  layout: CardLayout.rectangle,
  onTap: () => context.push('/profile/medication'),
)
```

---

### 6. WaterDropProgressCard

**Purpose:** Display weekly fluid therapy progress.

**Location:** `lib/shared/widgets/fluid/water_drop_progress_card.dart`

**Features:**
- Animated water drop fill indicator
- Weekly progress visualization
- Injection site display
- 16px border radius (specialized design)

**When to Use:**
- Home screen weekly progress section
- Only for users with fluid therapy schedules

---

### 7. IconContainer

**Purpose:** Consistent icon presentation with optional background circle.

**Location:** `lib/shared/widgets/icons/icon_container.dart`

**Features:**
- 56px outer circle with radial gradient (optional)
- 40px inner container with 8px border radius
- 20px icon
- Configurable colors

**When to Use:**
- Within custom card implementations
- Whenever you need an icon with background styling
- Building new card types

**Example:**
```dart
IconContainer(
  icon: Icons.medication,
  color: AppColors.primary,
  showBackgroundCircle: true,
)
```

---

## Design Constants

All card styling should use constants from `lib/core/theme/card_constants.dart`:

### Dimensions
```dart
CardConstants.borderRadius              // 12px - standard border radius
CardConstants.iconCircleSize            // 56px - outer background circle
CardConstants.iconContainerSize         // 40px - inner icon container
CardConstants.iconSize                  // 20px - icon size
CardConstants.iconContainerRadius       // 8px - inner container radius
```

### Spacing
```dart
CardConstants.cardMargin                // Horizontal: md (16px), Vertical: xs (4px)
CardConstants.cardPadding               // Horizontal: md, Vertical: sm (8px)
CardConstants.contentPadding            // ListTile-like content padding
```

### Colors
```dart
CardConstants.iconBackgroundColor(color)         // 0.1 alpha
CardConstants.iconCircleGradientStart(color)     // 0.05 alpha
CardConstants.iconCircleGradientEnd(color)       // 0.0 alpha (transparent)
CardConstants.cardBorderColor(context)           // outline with 0.2 alpha
```

### Other
```dart
CardConstants.cardElevation             // 0 - flat design
CardConstants.cardShadow(context)       // Subtle shadow when needed
```

---

## Usage Guidelines

### Choosing the Right Card

| Use Case | Component | Notes |
|----------|-----------|-------|
| Navigation to another screen | NavigationCard | Always include metadata when available |
| Treatment reminder display | PendingTreatmentCard / PendingFluidCard | Use on dashboard only |
| Selection/Choice interface | SelectionCard | Onboarding and option selection |
| Weekly progress | WaterDropProgressCard | Fluid therapy only |
| Custom data display | HydraCard | Base component for custom needs |
| Information message | HydraInfoCard | Type-based styling |

### Icon Guidelines

1. **Always use IconContainer** for consistency
2. **Background circles are enabled by default** (Option B design)
3. **Icon colors should be semantic:**
   - Primary color for navigation/interactive elements
   - OnSurface variants for status/data display
   - Type-specific colors for alerts (success, warning, error)

### Spacing Guidelines

1. **Between cards:** Use `SizedBox(height: AppSpacing.sm)` (8px) for vertical spacing
2. **Card margins:** Use `CardConstants.cardMargin` for consistency
3. **Internal padding:** Use `CardConstants.cardPadding` or `contentPadding`

### Typography Guidelines

1. **Card titles:** Use `AppTextStyles.h3`
2. **Metadata/subtitles:** Use `AppTextStyles.caption`
3. **Body text:** Use `AppTextStyles.body`
4. **Color hierarchy:**
   - Primary text: `AppColors.textPrimary`
   - Secondary text: `AppColors.textSecondary`
   - Tertiary text: `AppColors.textTertiary`

---

## Best Practices

### 1. Meaningful Metadata

Always show relevant metadata when available:

✅ **Good:**
```dart
NavigationCard(
  title: 'Medication Schedule',
  metadata: '3 medications',
  icon: Icons.medication,
  onTap: () => navigate(),
)
```

❌ **Bad:**
```dart
NavigationCard(
  title: 'Medication Schedule',
  // No metadata - user doesn't know how many medications
  icon: Icons.medication,
  onTap: () => navigate(),
)
```

### 2. Consistent Spacing

Use standardized constants instead of hardcoded values:

✅ **Good:**
```dart
margin: CardConstants.cardMargin,
```

❌ **Bad:**
```dart
margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
```

### 3. Icon Consistency

Use IconContainer for all card icons:

✅ **Good:**
```dart
IconContainer(
  icon: Icons.medication,
  color: theme.colorScheme.primary,
)
```

❌ **Bad:**
```dart
Container(
  width: 42,  // Non-standard size
  height: 42,
  decoration: BoxDecoration(
    color: Colors.blue.withOpacity(0.15),  // Hardcoded values
    borderRadius: BorderRadius.circular(10),
  ),
  child: Icon(Icons.medication, size: 22),
)
```

### 4. Reactive Metadata

Use Consumer widgets to ensure metadata updates reactively:

✅ **Good:**
```dart
Consumer(
  builder: (context, ref, _) {
    final count = ref.watch(medicationScheduleCountProvider);
    return NavigationCard(
      title: 'Medication Schedule',
      metadata: '$count ${count == 1 ? 'medication' : 'medications'}',
      onTap: () => navigate(),
    );
  },
)
```

❌ **Bad:**
```dart
// Metadata won't update when count changes
final count = ref.read(medicationScheduleCountProvider);
NavigationCard(
  title: 'Medication Schedule',
  metadata: '$count medications',
  onTap: () => navigate(),
)
```

### 5. Accessibility

Always provide semantic labels and hints:

✅ **Good:**
```dart
Semantics(
  label: 'Medication: Benazepril 2mg, 1 pill, scheduled at 09:00',
  hint: 'Tap to confirm or skip this medication',
  button: true,
  child: PendingTreatmentCard(...),
)
```

---

## Examples

### Example 1: Profile Navigation with Metadata

```dart
// CKD Profile with IRIS stage
NavigationCard(
  title: 'CKD Profile',
  icon: Icons.medical_information,
  metadata: primaryPet?.medicalInfo.irisStage?.displayName,
  onTap: () => context.go('/profile/ckd'),
)

// Fluid Schedule with volume and frequency
Consumer(
  builder: (context, ref, _) {
    final fluidSchedule = profileState.fluidSchedule;
    String? metadata;
    if (fluidSchedule != null) {
      final volume = fluidSchedule.targetVolume?.toInt() ?? 0;
      final frequency = fluidSchedule.frequency.displayName;
      metadata = '${volume}ml, $frequency';
    }
    return NavigationCard(
      title: 'Fluid Schedule',
      icon: Icons.water_drop,
      metadata: metadata,
      onTap: () => context.go('/profile/fluid'),
    );
  },
)

// Weight with current value and unit
Consumer(
  builder: (context, ref, _) {
    final weightUnit = ref.watch(weightUnitProvider);
    final metadata = WeightUtils.formatWeight(
      primaryPet?.weightKg,
      weightUnit,
    );
    return NavigationCard(
      title: 'Weight',
      icon: Icons.scale,
      metadata: metadata,
      onTap: () => context.push('/profile/weight'),
    );
  },
)
```

### Example 2: Custom Card Using HydraCard

```dart
HydraCard(
  onTap: () => handleTap(),
  margin: CardConstants.cardMargin,
  child: Row(
    children: [
      IconContainer(
        icon: Icons.analytics,
        color: AppColors.primary,
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom Analytics',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 2),
            Text(
              'Last updated: 2 hours ago',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      const Icon(
        Icons.chevron_right,
        color: AppColors.textTertiary,
        size: 20,
      ),
    ],
  ),
)
```

### Example 3: Information Card with Type

```dart
HydraInfoCard(
  type: HydraInfoType.success,
  message: 'All treatments completed for today!',
  icon: Icons.check_circle_outline,
  actions: [
    TextButton(
      onPressed: () => viewProgress(),
      child: const Text('View Progress'),
    ),
  ],
)
```

---

## Migration Guide

### From ProfileNavigationTile/InsightsCard to NavigationCard

**Before:**
```dart
ProfileNavigationTile(
  title: 'CKD Profile',
  icon: Icons.medical_information,
  onTap: () => context.go('/profile/ckd'),
)

InsightsCard(
  title: 'Injection Sites',
  subtitle: 'Track rotation patterns',
  icon: Icons.location_on,
  onTap: () => context.push('/progress/injection-sites'),
)
```

**After:**
```dart
NavigationCard(
  title: 'CKD Profile',
  icon: Icons.medical_information,
  metadata: 'Stage 2',  // Add meaningful metadata!
  onTap: () => context.go('/profile/ckd'),
)

NavigationCard(
  title: 'Injection Sites',
  metadata: 'Track rotation patterns',  // subtitle → metadata
  icon: Icons.location_on,
  onTap: () => context.push('/progress/injection-sites'),
)
```

**Key Changes:**
1. `subtitle` parameter renamed to `metadata`
2. Always try to add meaningful metadata when available
3. Background circles are now enabled by default
4. Typography changed to h3 for titles (more consistent)
5. Spacing standardized using CardConstants

---

## Deprecated Components

The following components are deprecated and should not be used in new code:

- ❌ **ProfileNavigationTile** - Use `NavigationCard` instead
- ❌ **InsightsCard** - Use `NavigationCard` instead

These will be removed in a future version.

---

## Summary

Following this style guide ensures:

✓ Visual consistency across the entire app
✓ Better user experience with meaningful metadata
✓ Easier maintenance and updates
✓ Predictable behavior and spacing
✓ Professional, cohesive design language

When in doubt, refer to existing implementations in:
- `lib/features/profile/screens/profile_screen.dart` (NavigationCard with metadata)
- `lib/features/home/widgets/pending_treatment_card.dart` (Treatment cards)
- `lib/features/progress/screens/progress_screen.dart` (Insights navigation)

---

**Last Updated:** 2025-01-20
**Maintained By:** Development Team
