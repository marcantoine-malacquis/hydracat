# HydraCat - UI Design Guidelines (Updated)

**Last Updated:** December 2024
**Status:** Reflects current implementation

This document describes the actual UI implementation of HydraCat as of December 2024. It supersedes the original guidelines and documents what has been built.

---

## Design Philosophy

HydraCat's interface balances **medical professionalism** with **emotional comfort**. The design should feel like a trusted medical tool that also provides reassurance and warmth to stressed cat owners. The water theme reinforces both the medical purpose (fluid therapy) and emotional comfort (soothing, flowing, life-giving).

**Core Principles:**
- **Professional Clarity**: Medical data and vet-facing features maintain clinical precision
- **Emotional Comfort**: Owner-facing features use soft, reassuring design elements
- **Water Theme**: Subtle integration of water-inspired elements without being overwhelming
- **Accessibility First**: High contrast, large touch targets, stress-reducing interactions
- **Platform Adaptation**: Material Design for Android, Cupertino for iOS/macOS

---

## Color System

### Implementation Reference
**Source:** `lib/core/constants/app_colors.dart`

### Primary Colors
```dart
// Main brand color
primary: #6BB8A8 (teal)
primaryLight: #9DCBBF (hover states, backgrounds)
primaryDark: #4A8A7A (active states, emphasis)
```

### Background Colors
```dart
background: #F6F4F2 (warm off-white)
surface: #FFFFFF (cards, elevated surfaces)
```

### Accent Colors
```dart
// Success - Muted Golden Amber (achievements, completions)
success: #E6B35C
successLight: #F0C980
successDark: #D4A142

// Warning - Soft Coral (gentle alerts)
warning: #E87C6B
warningLight: #EDA08F
warningDark: #DC5A47

// Error - Traditional Red (critical alerts only)
error: #DC3545
errorLight: #E85D6B
errorDark: #C82333
```

### Neutral Colors
```dart
// Text hierarchy
textPrimary: #2D3436 (main content)
textSecondary: #636E72 (supporting text)
textTertiary: #B2BEC3 (placeholder, disabled)

// UI elements
border: #DDD6CE (soft borders)
divider: #E5E5E5 (section separators)
disabled: #F1F2F3 (disabled backgrounds)
```

### Special Colors
```dart
// Hero gradient (home screen header)
heroGradientStart: primary (#6BB8A8)
heroGradientEnd: primaryDark (#4A8A7A)
```

### Dark Theme Colors
```dart
darkBackground: #1A1A1A
darkSurface: #2A2A2A
darkPrimary: #8FCCB8 (lighter teal for dark mode)
darkOnBackground: #E0E0E0
darkOnSurface: #E0E0E0
```

**Note:** Dark theme is implemented and users can toggle it in Profile settings via `theme_provider.dart`.

### Color Usage Guidelines

**Primary Teal (#6BB8A8):**
- FAB icon color (on white background)
- Active navigation items (icons and indicator)
- Primary CTAs
- Progress indicators
- Links and interactive elements

**Success Amber (#E6B35C):**
- Completed sessions
- Achievement celebrations
- Positive progress indicators

**Soft Coral (#E87C6B) - Gentle Alerts:**
- Missed session reminders
- Non-critical notifications

**Red (#DC3545) - Critical Only:**
- Medical risk alerts
- Critical supply shortages
- System errors

### Symptom Color Palette
**Source:** `lib/core/constants/symptom_colors.dart`

Fixed pastel colors for symptom visualization:
```dart
vomiting: #9DCBBF (pastel teal)
diarrhea: #F0C980 (pastel amber)
energy: #EDA08F (pastel coral)
suppressedAppetite: #C4B5FD (soft lavender)
constipation: #A8D5E2 (soft aqua)
injectionSiteReaction: #F5C9A8 (soft peach)
other: rgba(178, 190, 195, 0.35) (neutral with opacity)
```

**Chart Pattern:**
- Top 4-5 symptoms shown as distinct colored segments
- Remaining symptoms grouped into "Other"
- Use `SymptomColors.colorForSymptom()` and `SymptomColors.colorForOther()`

---

## Typography

### Implementation Reference
**Source:** `lib/core/theme/app_text_styles.dart`

### Font Stack
```dart
// Primary - Clean, professional sans-serif
fontFamily: 'Inter' // Body text, data, clinical content

// Secondary - Softer, warmer for headers
fontFamily: 'Nunito' // Headers, titles
```

### Type Scale
```dart
display:   32px / 1.2 / w600 (Nunito) - App title, major headings
h1:        24px / 1.3 / w600 (Nunito) - Screen titles
h2:        20px / 1.4 / w500 (Nunito) - Section headers
h3:        18px / 1.4 / w500 (Nunito) - Subsection headers
body:      16px / 1.5 / w400 (Inter)  - Main content
caption:   14px / 1.4 / w400 (Inter)  - Supporting info
small:     12px / 1.3 / w400 (Inter)  - Timestamps, metadata
```

### Specialized Styles
```dart
clinicalData:     16px / 1.5 / w500 (Inter) - Medical data emphasis
timestamp:        14px / 1.4 / w400 (Inter) - Date/time displays
buttonPrimary:    16px / 1.2 / w500 (Inter) - Button text
buttonSecondary:  16px / 1.2 / w500 (Inter) - Secondary buttons
navigationLabel:  12px / 1.2 / w500 (Inter) - Nav bar labels
```

### Typography Guidelines

**Clinical Content** (logs, schedules, data):
- Use Inter font
- Higher contrast colors
- Clear hierarchy
- Medium weight (w500) for emphasis

**Friendly Content** (notifications, onboarding):
- Use Nunito for headers
- Softer colors
- Warmer tone

---

## Border Radius System

### Implementation Reference
**Source:** `lib/core/theme/app_border_radius.dart`

### Hierarchy
```dart
xs (4px):      Progress indicators, badges, small decorative elements
sm (8px):      Buttons, inputs, chips, dropdowns, small interactive elements
md (12px):     Cards, standard containers, most surfaces (default)
lg (16px):     Dialogs, bottom sheets, modals, large containers
xl (20px):     Special large containers, hero elements
chip (20px):   Chips (pill-shaped)
capsule (999px): Pill-shaped buttons, fully rounded elements
```

### Semantic Constants
```dart
AppBorderRadius.button               // 8px
AppBorderRadius.input                // 8px
AppBorderRadius.card                 // 12px
AppBorderRadius.dialog               // 16px
AppBorderRadius.bottomSheet          // 16px
AppBorderRadius.modal                // 16px
AppBorderRadius.chip                 // 20px
AppBorderRadius.dropdown             // 8px
AppBorderRadius.progressIndicator    // 4px
AppBorderRadius.badge                // 4px
AppBorderRadius.navigationIndicator  // 12px
```

### BorderRadius Objects (for convenience)
```dart
AppBorderRadius.buttonRadius              // BorderRadius.circular(8)
AppBorderRadius.cardRadius                // BorderRadius.circular(12)
AppBorderRadius.dialogRadius              // BorderRadius.circular(16)
AppBorderRadius.capsuleRadius             // BorderRadius.circular(999)
AppBorderRadius.navigationIndicatorRadius // BorderRadius.circular(12)
```

### Usage Guidelines

**Small Elements (8px):**
- All buttons (primary, secondary, text)
- Text input fields
- Dropdowns
- Small interactive elements
- Consistent with touch-friendly interaction

**Medium Elements (12px - Default):**
- Cards and standard containers
- Selection cards
- Most surfaces
- Default for most UI elements

**Large Elements (16px):**
- Dialogs and modals
- Bottom sheets
- Large prominent containers
- Creates visual hierarchy

**Special Cases:**
- **Chips (20px):** More rounded for pill-like appearance
- **Capsule (999px):** Extended FAB, fully rounded buttons
- **Progress indicators (4px):** Subtle rounding for small elements

---

## Spacing System

### Implementation Reference
**Source:** `lib/core/theme/app_spacing.dart`

### Base Spacing Scale (4px unit)
```dart
xs:    4px   - Tight elements, minimal spacing
sm:    8px   - Related items, compact grouping
mdSm:  12px  - Tight grouping of related elements, compact layouts
md:    16px  - Standard spacing (default)
mdLg:  20px  - Between-section spacing, loose grouping
lg:    24px  - Section separation
xl:    32px  - Major sections
xxl:   48px  - Screen separation
```

### Spacing Usage Guidelines

**xs (4px):**
- Minimal padding inside compact elements
- Tight icon-to-text spacing
- Progress indicator gaps

**sm (8px):**
- Related items within a group
- Compact button padding (vertical)
- Icon spacing in toolbars

**mdSm (12px):**
- Tight grouping of related elements
- Compact card margins
- Small button horizontal padding
- Spacing between tightly related form fields

**md (16px - Default):**
- Standard spacing for most use cases
- Card internal padding
- Button spacing (prevents accidental taps)
- General element spacing

**mdLg (20px):**
- Between-section spacing
- Loose grouping of elements
- Large button horizontal padding
- Comfortable breathing room

**lg (24px):**
- Section separation
- Screen padding minimum
- Major grouping boundaries

**xl (32px):**
- Major section separation
- Clear content boundaries
- Large content blocks

**xxl (48px):**
- Screen-level separation
- Hero section spacing
- Major layout divisions

### Layout Spacing
```dart
screenPadding:        24px (lg) - Minimum screen padding
cardPadding:          16px (md) - Card internal padding
sectionSpacing:       32px (xl) - Between major sections
buttonSpacing:        16px (md) - Between buttons (prevents accidental taps)
bottomSheetInset:     16px (md) - Bottom sheet breathing room
appBarHeight:         60px      - Standard app bar height
appBarContentPadding: 16px (md) horizontal - App bar content inset
```

### Accessibility Touch Targets
**Source:** `lib/core/constants/app_accessibility.dart`
```dart
minTouchTarget: 44px  - Minimum tap target (WCAG AA)
fabTouchTarget: 56px  - FAB button size
```

### Responsive Spacing
**Source:** `lib/core/theme/app_layout.dart`

```dart
// Responsive padding based on screen width
Mobile (<600px):   16px (md)
Tablet (600-900px): 24px (lg)
Desktop (>900px):   32px (xl)
```

---

## Component Design

### Buttons

#### Implementation Reference
**Source:** `lib/shared/widgets/buttons/hydra_button.dart`

#### Primary Button
```dart
backgroundColor: AppColors.primary
foregroundColor: white
borderRadius: 8px  // � Note: Different from cards (12px)
padding: 16px horizontal, 12px vertical (medium)
elevation: 2
shadow: primary.withAlpha(0.3)
minHeight: 44px
```

#### Secondary Button
```dart
backgroundColor: transparent
foregroundColor: AppColors.primary
border: 1px solid primary
borderRadius: 8px
padding: 16px horizontal, 12px vertical
minHeight: 44px
```

#### Text Button
```dart
backgroundColor: transparent
foregroundColor: AppColors.primary
borderRadius: 8px
padding: 16px horizontal, 12px vertical
minHeight: 44px
```

#### Button Sizes
```dart
small:  32px min height, 12px/8px padding
medium: 44px min height, 16px/12px padding
large:  54px min height, 20px vertical padding
```

#### Platform Adaptation
- **Material (Android):** ElevatedButton with ripple effect
- **Cupertino (iOS):** CupertinoButton.filled with opacity changes

### FAB (Floating Action Button)

#### Implementation Reference
**Source:** `lib/shared/widgets/buttons/hydra_fab.dart`

#### Design (Updated from original guidelines)
```dart
// � CHANGED: FAB is now white background with teal icon
backgroundColor: AppColors.surface (white)
foregroundColor: AppColors.primary (teal)
icon: water_drop (32px)
size: 56px � 56px
shape: circle
border: 1px solid AppColors.border
elevation: 0
```

**Features:**
- Long-press gesture detection (500ms)
- Scale animation on long-press (0.92x)
- Haptic feedback
- Loading state support
- Platform-specific implementation

#### Extended FAB
```dart
borderRadius: 999px (pill shape)
padding: 16px horizontal, 12px vertical
icon + label layout
glassEffect: optional backdrop blur
```

### Cards

#### Implementation Reference
**Source:** `lib/shared/widgets/cards/hydra_card.dart`

#### Base Card (HydraCard)
```dart
backgroundColor: AppColors.surface
border: 1px solid AppColors.border
borderRadius: 12px
elevation: 0
shadow: BoxShadow(
  color: rgba(0, 0, 0, 0.06),
  offset: (0, 2),
  blurRadius: 8
)
padding: 16px (md)
margin: 8px (sm)
```

#### Interactive Cards (with onTap)
**Press Feedback Animation:**
- Scale: 1.0 � 0.95
- Shadow: Teal glow (0 � 1 opacity)
- Duration: 100ms
- Curve: easeOutCubic
- Minimum press duration: 80ms for visibility

#### Section Card (HydraSectionCard)
- Title + optional subtitle
- Optional action buttons in header
- Expandable content area

#### Info Card (HydraInfoCard)
- Type-specific colors (info, success, warning, error)
- Icon + message + optional actions
- Colored background (10% opacity) and border

### Navigation Bar

#### Implementation Reference
**Source:** `lib/shared/widgets/navigation/hydra_navigation_bar.dart`

#### Structure
```dart
height: 84px
backgroundColor: AppColors.surface
topBorder: 1px solid AppColors.border
```

**Material (Android):**
```dart
boxShadow: rgba(0, 0, 0, 0.08), offset: (0, -2), blur: 12
```

**Cupertino (iOS):**
```dart
border: 0.5px hairline (CupertinoColors.separator)
// No shadow - flat design
```

#### Layout
- **Left:** 2 items (Home, Schedule)
- **Center:** FAB (16px spacing on each side)
- **Right:** 2 items (Progress, Profile)

#### Top Indicator
```dart
height: 3px
borderRadius: 12px
color: AppColors.primary
animation: 160ms Material, 120ms Cupertino
curve: easeInOut Material, easeOut Cupertino
```

#### Navigation Items
```dart
// Material
iconSize: 26px
selectedWeight: w600
unselectedWeight: w400

// Cupertino
iconSize: 24px
selectedWeight: w500
unselectedWeight: w400
```

**Colors:**
- Selected: AppColors.primary
- Unselected: AppColors.textSecondary

### App Bar

#### Implementation Reference
**Source:** `lib/shared/widgets/navigation/hydra_app_bar.dart`

#### Style Variants

**1. Default (HydraAppBarStyle.default_)**
```dart
backgroundColor: Color.alphaBlend(
  primary.withAlpha(0.06),
  background
)
// Subtle tonal surface (6% primary blend)
// Use for: All standard screens
```

**2. Accent (HydraAppBarStyle.accent)**
```dart
backgroundColor: Color.alphaBlend(
  primary.withAlpha(0.12),
  background
)
// Stronger primary blend (12%)
// Use for: Analytics/insights screens ONLY
// Examples: Progress & Analytics, Injection Sites Analytics
// � Reserved exclusively for this use case
```

**3. Transparent (HydraAppBarStyle.transparent)**
```dart
backgroundColor: transparent
border: none
// Use for: Onboarding, overlay screens
```

#### Common Properties
```dart
height: 60px (AppSpacing.appBarHeight)
foregroundColor: AppColors.textPrimary
elevation: 0
border: 1px solid AppColors.border (bottom)
centerTitle: true
titlePadding: 16px horizontal
```

#### Platform Adaptation
- **Material:** AppBar with custom styling
- **Cupertino:** CupertinoNavigationBar with matching design

#### Bottom Widget Support
- Optional segmented control or tabs
- Default height: 44px
- Padding: 16px horizontal, 8px vertical

---

## Shadows & Elevation

### Implementation Reference
**Source:** `lib/core/theme/app_shadows.dart`

### Button Shadows
```dart
// Primary button shadow
primaryButton: BoxShadow(
  color: rgba(107, 184, 168, 0.3),
  offset: (0, 2),
  blurRadius: 8
)

// FAB button shadow
fabButton: BoxShadow(
  color: rgba(107, 184, 168, 0.4),
  offset: (0, 4),
  blurRadius: 12
)
```

### Card & Container Shadows
```dart
// Subtle shadow for standard cards
cardSubtle: BoxShadow(
  color: rgba(0, 0, 0, 0.06),
  offset: (0, 2),
  blurRadius: 8
)

// Elevated shadow for prominent cards
cardElevated: BoxShadow(
  color: rgba(0, 0, 0, 0.08),
  offset: (0, 4),
  blurRadius: 12
)

// Popup shadow for modals and overlays
cardPopup: BoxShadow(
  color: rgba(0, 0, 0, 0.12),
  offset: (0, 6),
  blurRadius: 16
)

// Tooltip shadow for chart labels
tooltip: BoxShadow(
  color: rgba(0, 0, 0, 0.08),
  offset: (0, 2),
  blurRadius: 8
)

// @deprecated - Use cardSubtle instead
card: BoxShadow(
  color: rgba(0, 0, 0, 0.06),
  offset: (0, 2),
  blurRadius: 8
)
```

### Navigation Shadows
```dart
// Navigation bar shadow (Material only)
navigationBar: BoxShadow(
  color: rgba(0, 0, 0, 0.08),
  offset: (0, -2),
  blurRadius: 12
)

// Press state shadow (cards, icons)
navigationIconPressed: BoxShadow(
  color: rgba(107, 184, 168, 0.4),
  offset: (0, 4),
  blurRadius: 12,
  spreadRadius: 1
)

// Hover state shadow (web/desktop)
navigationIconHover: BoxShadow(
  color: rgba(107, 184, 168, 0.1),
  offset: (0, 1),
  blurRadius: 4
)
```

### Shadow Usage Guidelines

**cardSubtle (0.06 alpha):**
- Standard cards (HydraCard)
- List items
- Regular containers
- Default for most surfaces

**cardElevated (0.08 alpha):**
- Feature cards (water drop progress card)
- Important containers
- Hero sections
- Emphasized content areas

**cardPopup (0.12 alpha):**
- Dialogs
- Bottom sheets
- Modals
- Popups and overlays

**tooltip (0.08 alpha):**
- Chart tooltips
- Floating labels
- Overlay indicators
- Goal markers

### Elevation Strategy
- **Default:** elevation: 0 (flat design with borders)
- **Shadows:** Used for depth, not Material elevation
- **Cards:** Border + subtle shadow
- **iOS/Cupertino:** No shadows on navigation bars, use borders only

---

## Animation System

### Implementation Reference
**Source:** `lib/core/constants/app_animations.dart`

### Loading Overlays
```dart
loadingFadeIn:    200ms
successDisplay:   500ms
errorDisplay:     300ms
```

### Popup Overlays
```dart
slideUp:          200ms, Curves.easeOut
slideFromRight:   250ms
slideFromLeft:    250ms
scaleIn:          300ms, Curves.easeOutBack
```

### Drag Interactions
```dart
dragSpringBack:   200ms, Curves.easeOutCubic
dragDismiss:      250ms, Curves.easeInCubic
```

### Navigation Transitions
```dart
tabFade:          150ms, Curves.easeInOut
pageSlide:        260ms, Curves.easeInOut
```

### Overlay Opacity
```dart
contentDimmed:    0.3
overlayBackground: 0.3
```

### Accessibility Support
```dart
// Check if animations should be disabled
MediaQuery.disableAnimationsOf(context)

// Use AppAnimations.getDuration(context, duration)
// Returns Duration.zero if reduce motion is enabled
```

---

## Layout & Responsive Design

### Implementation Reference
**Source:** `lib/core/theme/app_layout.dart`

**Note:** Border radius constants have been moved to `lib/core/theme/app_border_radius.dart`. See Border Radius System section above for current values.

### Breakpoints
```dart
mobile:   < 600px
tablet:   600px - 900px
desktop:  > 900px
```

### Layout Dimensions
```dart
bottomNavHeight:   84px  // � Reduced from original 80px
topAppBarHeight:   56px

// Border radius values moved to AppBorderRadius
cardRadius:        12px  // @deprecated Use AppBorderRadius.card
buttonRadius:      8px   // � Different from cardRadius
inputRadius:       8px
maxContentWidth:   1200px
sidebarWidth:      280px
```

### Responsive Helpers
```dart
AppLayout.isMobile(width)
AppLayout.isTablet(width)
AppLayout.isDesktop(width)
AppLayout.getResponsivePadding(width)
AppLayout.getResponsiveCardPadding(width)
```

---

## Iconography

### Icon Strategy
- **Material Icons:** Default for most UI elements
- **Custom Water Theme:** Droplet icon for FAB
- **Filled vs Outlined:**
  - Filled: Active states, primary actions
  - Outlined: Inactive states, secondary elements

### Navigation Icons
```dart
home:     'home' (paw)
schedule: (calendar)
log:      'water_drop' (custom droplet)
progress: 'show_chart' (graph)
profile:  'profile' (cat)
```

---

## Platform Adaptation

### Material Design (Android)
- ElevatedButton with ripple effects
- AppBar with Material styling
- Shadows and elevation
- 26px navigation icons
- Standard Material motion (160ms)

### Cupertino (iOS/macOS)
- CupertinoButton with opacity changes
- CupertinoNavigationBar
- Borders instead of shadows
- 24px navigation icons
- Lighter, faster animations (120ms)
- No tooltips

### Shared Hydra Components
All Hydra* components (HydraButton, HydraFab, HydraAppBar, etc.) automatically adapt to the platform while maintaining brand consistency.

---

## Accessibility Standards

### Color Contrast
- **Minimum ratio:** 4.5:1 (WCAG AA)
- **Never rely on color alone** for information
- **High stress users:** Extra attention to clarity

### Touch Targets
```dart
Minimum: 44px � 44px (AppAccessibility.minTouchTarget)
FAB:     56px � 56px (AppAccessibility.fabTouchTarget)
Spacing: 16px minimum between interactive elements
```

### Typography
```dart
Minimum body size: 16px
Line height:       1.4 minimum
```

### Focus States
```dart
outline: 2px solid AppColors.primary
outlineOffset: 2px
```

### Haptic Feedback
- Provided on button presses
- Navigation item selection
- FAB interactions
- Respect system settings

### Reduce Motion
- All animations check `MediaQuery.disableAnimationsOf(context)`
- Use `AppAnimations.getDuration(context, duration)`
- Graceful degradation to instant transitions

---

## Data Visualization

### Charts & Graphs

**Primary Data** (fluid intake, completion rates):
```dart
fill: AppColors.primary
stroke: AppColors.primaryDark
borderRadius: 4px (rounded bar edges)
```

**Supporting Elements** (grid, axes):
```dart
stroke: AppColors.textTertiary
opacity: 0.5
```

**Symptom Charts:**
- Use `SymptomColors.colorForSymptom(key)`
- Top 4-5 symptoms as distinct colors
- Remaining as "Other" (neutral color)
- Legend with colored indicators

### Progress Indicators

**Water Drop Visualization:**
- Animated fill based on percentage
- Uses `WaterDropPainter` custom painter
- Teal fill color (AppColors.primary)
- Smooth animation on data changes

**Linear Progress:**
```dart
background: linear-gradient(90deg, primary, primaryLight)
borderRadius: 8px
```

**Circular Progress:**
```dart
HydraProgressIndicator(
  strokeWidth: 2,
  color: context-appropriate
)
```

---

## Standardization Status & Remaining Opportunities

### � Border Radius Variance
**Status:** ✅ RESOLVED - Standardized via `AppBorderRadius` constants

All border radius values now use semantic constants from `lib/core/theme/app_border_radius.dart`:
- Small elements (buttons, inputs, dropdowns): 8px
- Medium elements (cards, containers): 12px
- Large elements (dialogs, modals, bottom sheets): 16px
- Special cases: chips (20px), capsule (999px), indicators (4px, 12px)

**Implementation:**
- Created centralized `AppBorderRadius` class with semantic constants
- Updated all theme configurations (buttons, cards, inputs, dialogs, chips)
- Updated key components (HydraButton, HydraCard, HydraFab, HydraNavigationBar)
- Deprecated old constants in AppLayout with @deprecated annotations
- All components now reference AppBorderRadius for consistency

### � AppBar Accent Style Usage
**Current State:** `HydraAppBarStyle.accent` is used exclusively for analytics screens.

**Recommendation:** Document clear semantic rules:
- **Default:** All standard screens (Profile, Home, Schedule, etc.)
- **Accent:** Analytics/insights screens ONLY (Progress, Injection Sites Analytics)
- **Transparent:** Onboarding/overlay screens only
- Never mix arbitrarily - each screen type should consistently use the same variant

### � Card Shadow Variance
**Status:** ✅ RESOLVED - Standardized via `AppShadows` hierarchy

All shadow values now use semantic constants from `lib/core/theme/app_shadows.dart`:
- **cardSubtle (0.06)**: Standard cards, list items, regular containers
- **cardElevated (0.08)**: Feature cards, important containers, hero sections
- **cardPopup (0.12)**: Dialogs, bottom sheets, modals, overlays
- **tooltip (0.08)**: Chart tooltips, floating labels, overlay indicators

**Implementation:**
- Created comprehensive shadow hierarchy with clear semantic meanings
- Updated water drop progress card to use `AppShadows.cardElevated`
- Updated chart tooltips to use `AppShadows.tooltip`
- Deprecated generic `AppShadows.card` in favor of `cardSubtle` for clarity
- All components now reference appropriate shadow constants

### � Spacing Consistency
**Status:** ✅ SUBSTANTIALLY IMPROVED - Extended spacing scale with intermediate values

**New intermediate spacing constants added:**
- **mdSm (12px)**: Tight grouping, compact layouts, common intermediate value
- **mdLg (20px)**: Between-section spacing, loose grouping

**Key updates:**
- Added intermediate spacing values (mdSm=12px, mdLg=20px) to fill common gaps
- Updated HydraButton to use AppSpacing constants for all padding
- Updated WaterDropProgressCard to use AppSpacing for margins and internal spacing
- All new components should reference AppSpacing constants

**Acceptable spacing exceptions:**
- Component-specific spacing that doesn't fit the scale (e.g., 10px, 14px) may remain if intentional
- Special layout requirements (e.g., 28px, 36px, 40px) are documented per-component
- Icon sizes and specific design elements may use custom values

**Recommendation for future:**
- New components should always use AppSpacing constants where possible
- Document any intentional deviations from the spacing scale
- Consider adding more intermediate values if patterns emerge (e.g., 6px, 10px)

### � Platform-Specific Differences
**Current State:**
- Navigation icon size: 26px Material, 24px Cupertino
- Navigation selected weight: w600 Material, w500 Cupertino
- Shadow usage: Material only

**Status:** These are intentional platform adaptations, not inconsistencies.

---

## Implementation Checklist

### Completed 
- [x] Core color palette (`app_colors.dart`)
- [x] Typography system (`app_text_styles.dart`)
- [x] Spacing system (`app_spacing.dart` with intermediate values)
- [x] Button components (`hydra_button.dart`, `hydra_fab.dart`)
- [x] Card components (`hydra_card.dart` with press feedback)
- [x] Navigation bar (`hydra_navigation_bar.dart` with top indicator)
- [x] App bar with style variants (`hydra_app_bar.dart`)
- [x] Border radius hierarchy (`app_border_radius.dart`)
- [x] Shadow hierarchy (`app_shadows.dart` with card/tooltip variants)
- [x] Animation constants (`app_animations.dart`)
- [x] Layout system (`app_layout.dart`)
- [x] Dark theme support (`theme_provider.dart`)
- [x] Platform adaptation (Material + Cupertino)
- [x] Accessibility support (touch targets, reduce motion, haptics)
- [x] Symptom color palette (`symptom_colors.dart`)

### To Consider =
- [ ] Create comprehensive design tokens documentation
- [ ] Establish component variant naming conventions

---

## Design Tokens Quick Reference

### Color Tokens
```dart
import 'package:hydracat/core/constants/app_colors.dart';

AppColors.primary
AppColors.success
AppColors.warning
AppColors.error
AppColors.textPrimary
AppColors.textSecondary
AppColors.border
```

### Border Radius Tokens
```dart
import 'package:hydracat/core/theme/app_border_radius.dart';

// Semantic constants
AppBorderRadius.button        // 8px
AppBorderRadius.input         // 8px
AppBorderRadius.card          // 12px
AppBorderRadius.dialog        // 16px
AppBorderRadius.chip          // 20px
AppBorderRadius.capsule       // 999px

// BorderRadius objects (convenience)
AppBorderRadius.buttonRadius
AppBorderRadius.cardRadius
AppBorderRadius.dialogRadius
AppBorderRadius.capsuleRadius
```

### Spacing Tokens
```dart
import 'package:hydracat/core/theme/app_spacing.dart';

// Base spacing scale (4px unit)
AppSpacing.xs    // 4px   - Minimal spacing
AppSpacing.sm    // 8px   - Compact grouping
AppSpacing.mdSm  // 12px  - Tight grouping
AppSpacing.md    // 16px  - Standard (default)
AppSpacing.mdLg  // 20px  - Loose grouping
AppSpacing.lg    // 24px  - Section separation
AppSpacing.xl    // 32px  - Major sections
AppSpacing.xxl   // 48px  - Screen separation

// Semantic constants
AppSpacing.screenPadding    // 24px
AppSpacing.cardPadding      // 16px
AppSpacing.sectionSpacing   // 32px
AppSpacing.buttonSpacing    // 16px
```

### Typography Tokens
```dart
import 'package:hydracat/core/theme/app_text_styles.dart';

AppTextStyles.display
AppTextStyles.h1
AppTextStyles.h2
AppTextStyles.body
AppTextStyles.caption
AppTextStyles.small
```

### Shadow Tokens
```dart
import 'package:hydracat/core/theme/app_shadows.dart';

// Button shadows
AppShadows.primaryButton
AppShadows.fabButton

// Card & container shadows
AppShadows.cardSubtle      // Standard cards (0.06)
AppShadows.cardElevated    // Feature cards (0.08)
AppShadows.cardPopup       // Modals/dialogs (0.12)
AppShadows.tooltip         // Chart tooltips (0.08)

// Navigation shadows
AppShadows.navigationBar
AppShadows.navigationIconPressed
AppShadows.navigationIconHover

// @deprecated
AppShadows.card  // Use cardSubtle instead
```

### Animation Tokens
```dart
import 'package:hydracat/core/constants/app_animations.dart';

AppAnimations.tabFadeDuration
AppAnimations.pageSlideDuration
AppAnimations.slideUpDuration
```

---

## Component Usage Examples

### Button
```dart
HydraButton(
  onPressed: () {},
  variant: HydraButtonVariant.primary,
  size: HydraButtonSize.medium,
  child: const Text('Save'),
)
```

### Card
```dart
HydraCard(
  onTap: () {}, // Optional, enables press feedback
  child: Column(
    children: [
      Text('Title', style: AppTextStyles.h3),
      Text('Content', style: AppTextStyles.body),
    ],
  ),
)
```

### App Bar
```dart
HydraAppBar(
  title: const Text('Screen Title'),
  style: HydraAppBarStyle.default_, // or .accent, .transparent
  actions: [
    IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
  ],
)
```

---

*This document reflects the actual implementation of HydraCat UI as of December 2024. When adding new components or making design decisions, refer to this document for consistency. Update this document when making significant UI changes.*
