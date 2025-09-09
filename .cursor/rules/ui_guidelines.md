# HydraCat - UI Design Guidelines

## Design Philosophy

HydraCat's interface balances **medical professionalism** with **emotional comfort**. The design should feel like a trusted medical tool that also provides reassurance and warmth to stressed cat owners. The water theme reinforces both the medical purpose (fluid therapy) and emotional comfort (soothing, flowing, life-giving).

**Core Principles:**
- **Professional Clarity**: Medical data and vet-facing features maintain clinical precision
- **Emotional Comfort**: Owner-facing features use soft, reassuring design elements
- **Water Theme**: Subtle integration of water-inspired elements without being overwhelming
- **Accessibility First**: High contrast, large touch targets, stress-reducing interactions

## Color Palette

### Primary Colors
```css
/* Primary Teal - Main brand color */
--primary: #6BB8A8

/* Primary variants for depth */
--primary-light: #9DCBBF    /* Hover states, backgrounds */
--primary-dark: #4A8A7A     /* Active states, emphasis */

/* Background */
--background: #F6F4F2       /* Warm off-white, between #FAFAFA and #F9F5F1 */
--surface: #FFFFFF          /* Cards, elevated surfaces */
```

### Accent Colors
```css
/* Success - Muted Golden Amber */
--success: #E6B35C
--success-light: #F0C980
--success-dark: #D4A142

/* Warning - Soft Coral (non-critical alerts) */
--warning: #E87C6B
--warning-light: #EDA08F
--warning-dark: #DC5A47

/* Error - Traditional Red (critical alerts only) */
--error: #DC3545
--error-light: #E85D6B
--error-dark: #C82333
```

### Neutral Colors
```css
/* Text hierarchy */
--text-primary: #2D3436      /* Main content */
--text-secondary: #636E72    /* Supporting text */
--text-tertiary: #B2BEC3     /* Placeholder, disabled */

/* UI elements */
--border: #DDD6CE           /* Soft borders */
--divider: #E5E5E5          /* Section separators */
--disabled: #F1F2F3         /* Disabled backgrounds */
```

### Color Usage Rules

**Primary Teal (#6BB8A8):**
- Log session FAB button
- Active navigation items
- Primary CTAs
- Progress indicators
- Links and interactive elements

**Success Amber (#E6B35C):**
- Completed sessions
- Achievement celebrations
- Streak milestones
- Positive progress indicators

**Soft Coral (#E87C6B) - Gentle Alerts:**
- Missed session reminders
- Low fluid inventory warnings
- Schedule adjustment nudges
- Non-critical notifications

**Red (#DC3545) - Critical Only:**
- Medical risk alerts
- Critical supply shortages
- System errors
- Vet-flagged concerns

## Typography

### Font Stack
```css
/* Primary - Clean, professional sans-serif */
font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;

/* Headers - Softer, warmer alternative */
font-family: 'Nunito', 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
```

### Type Scale
```css
/* Display - App title, major headings */
--text-display: 2rem/1.2/600    /* 32px, tight, semi-bold */

/* H1 - Screen titles */
--text-h1: 1.5rem/1.3/600       /* 24px, normal, semi-bold */

/* H2 - Section headers */
--text-h2: 1.25rem/1.4/500      /* 20px, relaxed, medium */

/* H3 - Subsection headers */
--text-h3: 1.125rem/1.4/500     /* 18px, relaxed, medium */

/* Body - Main content */
--text-body: 1rem/1.5/400       /* 16px, comfortable, regular */

/* Caption - Supporting info */
--text-caption: 0.875rem/1.4/400 /* 14px, normal, regular */

/* Small - Timestamps, metadata */
--text-small: 0.75rem/1.3/400   /* 12px, tight, regular */
```

### Typography Applications

**Clinical Clarity** (logs, schedules, data):
- Use Inter font
- Higher contrast colors
- Tabular numbers for data
- Clear hierarchy

**Friendly Readability** (notifications, onboarding):
- Use Nunito for headers
- Softer colors
- Increased line-height
- Warmer tone

**Medical Data Integration:**
- Volume numbers: `--text-body` with `font-weight: 500`
- Dates/times: `--text-caption` with `--text-secondary`
- Never overemphasize medical data - integrate subtly

## Layout & Spacing

### Spacing Scale
```css
--space-xs: 0.25rem    /* 4px - Tight elements */
--space-sm: 0.5rem     /* 8px - Related items */
--space-md: 1rem       /* 16px - Standard spacing */
--space-lg: 1.5rem     /* 24px - Section separation */
--space-xl: 2rem       /* 32px - Major sections */
--space-2xl: 3rem      /* 48px - Screen separation */
```

### Layout Rules

**Touch Targets:**
- Minimum 44px × 44px for all interactive elements
- Extra spacing between buttons to prevent accidental taps
- Log FAB button: 56px × 56px minimum

**Content Areas:**
- Screen padding: `--space-lg` (24px) minimum
- Card internal padding: `--space-md` (16px)
- Section spacing: `--space-xl` (32px)

**One-Handed Consideration:**
- Important actions within thumb reach
- No critical interactions during treatment sessions
- Post-treatment logging optimized for quick, easy access

## Component Design

### Buttons

**Primary Button (Log Session, Save, etc.):**
```css
background: var(--primary);
color: white;
border-radius: 10px;
padding: 12px 24px;
font-weight: 500;
box-shadow: 0 2px 8px rgba(107, 184, 168, 0.3);
```

**Secondary Button:**
```css
background: transparent;
color: var(--primary);
border: 1.5px solid var(--primary);
border-radius: 10px;
padding: 12px 24px;
font-weight: 500;
```

**FAB Log Button (Special):**
```css
background: var(--primary);
width: 56px;
height: 56px;
border-radius: 28px;
/* Custom droplet icon */
box-shadow: 0 4px 12px rgba(107, 184, 168, 0.4);
```

### Cards & Containers
```css
background: var(--surface);
border: 1px solid var(--border);
border-radius: 12px;
box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
padding: var(--space-md);
```

### Navigation Bar

**Structure:** 5 icons from left to right
1. **Home**: Paw icon (filled when active, outlined when inactive)
2. **Schedule**: Calendar icon (filled when active, outlined when inactive)
3. **Log**: Droplet FAB (always prominent, teal background)
4. **Progress**: Graph icon (filled when active, outlined when inactive)  
5. **Profile**: Cat icon (filled when active, outlined when inactive)

**Styling:**
```css
background: var(--surface);
border-top: 1px solid var(--border);
height: 80px; /* Extra height for FAB */
box-shadow: 0 -2px 12px rgba(0, 0, 0, 0.08);
```

## Iconography

### Icon Strategy
- **Filled icons**: Primary actions, alerts, active states
- **Outlined icons**: Secondary elements, inactive states, informational

### Custom Water-Themed Icons
- **Log FAB**: Water droplet (custom designed)
- **Streak indicators**: Small water drops
- **Progress**: Flowing water elements in charts
- **Missed sessions**: Outlined droplet with gentle ripple

### Standard Material Icons
Use for most other interface elements to maintain familiarity and accessibility.

## Stress Indicators & Emotional States

### Stress Level Visualization
**Low Stress:**
```css
color: var(--success);
/* Light green droplet or calm wave icon */
```

**Medium Stress:**  
```css
color: var(--warning);
/* Amber droplet or gentle ripple icon */
```

**High Stress:**
```css
color: var(--warning-dark);
/* Darker amber droplet, never red */
```

**Abstract Representation:**
- Use soft, flowing shapes
- Avoid sharp or aggressive elements
- Integrate water theme subtly

## Streak Celebrations & Achievements

### Visual Elements
- **Small water drops** for daily streaks
- **Flowing animation** for milestone achievements
- **Golden amber accents** for celebrations
- **Gentle particle effects** (water-themed)

### Animation Principles
```css
/* Gentle, flowing animations */
transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);

/* Celebration animations */
/* More enthusiastic but still elegant */
/* Water-themed effects (droplets, ripples) */
```

## Alert & Feedback Systems

### Missed Sessions (Owner View)
**Gentle Approach:**
```css
color: var(--warning);
/* Soft coral color */
/* Small, calm outline droplet icon */
/* Subtle rounded background */
```

### Missed Sessions (Vet Report)
**Clear Documentation:**
```css
color: var(--warning);
/* More direct coral droplet with "X" */
/* Clear timeline marking */
/* Professional documentation style */
```

### Alert Hierarchy
1. **Nudges** (missed sessions): Soft coral, gentle icons
2. **Warnings** (low supplies): Standard coral, clear icons  
3. **Critical** (medical risks): Red, prominent icons

## Data Visualization

### Charts & Graphs
**Primary Data** (fluid intake, completion rates):
```css
/* Use water-themed color palette */
fill: var(--primary);
stroke: var(--primary-dark);
border-radius: 4px; /* Rounded bar edges */
```

**Supporting Elements** (grid lines, axes):
```css
stroke: var(--text-tertiary);
opacity: 0.5;
/* Neutral/gray tones for clarity */
```

**Accessibility:**
- High contrast ratios (4.5:1 minimum)
- Rounded edges for comfort
- Soft, calming shades
- Clear data hierarchy

### Progress Indicators
```css
/* Circular progress */
background: var(--primary);
border-radius: 50%;

/* Linear progress */
background: linear-gradient(90deg, var(--primary) 0%, var(--primary-light) 100%);
border-radius: 8px;
```

## Professional vs Comfort Balance

### Owner-Facing Features
- **Color**: Full water-themed palette
- **Typography**: Mix of Inter + Nunito
- **Styling**: Rounded corners, soft shadows
- **Tone**: Warm, reassuring, gentle

### Vet-Facing Features (PDF Reports)
```css
/* Professional medical styling */
background: #FFFFFF;
color: #000000;
font-family: Inter, sans-serif;
border: 1px solid #CCCCCC;
border-radius: 4px; /* Minimal rounding */

/* Critical alerts in reports */
color: #DC3545; /* Traditional red */
font-weight: 600;
```

### Medical Alerts/Recommendations
**Visual Approach:**
- Professional styling with neutral colors
- Subtle rounded corners (6px)
- Soft shadows for depth
- Clear visual hierarchy

**Content Approach:**
- Calm, clear, reassuring language
- More noticeable styling for critical alerts
- Softer styling for tips and recommendations

## Mobile Experience

### Screen Focus
- **Primary target**: Phone (iOS/Android)
- **Orientation**: Portrait-optimized
- **Responsive**: Adapt to different phone sizes

### Touch Interaction
```css
/* Minimum touch targets */
min-width: 44px;
min-height: 44px;

/* Button spacing */
gap: var(--space-md); /* Prevent accidental taps */

/* FAB positioning */
bottom: var(--space-md);
/* Within thumb reach */
```

### Treatment Session Consideration
- **Pre-treatment**: Easy navigation, tips, guides
- **During treatment**: No phone interaction expected  
- **Post-treatment**: Quick, one-handed logging

## Accessibility Standards

### Color Accessibility
- **Contrast ratios**: 4.5:1 minimum (WCAG AA)
- **Color blindness**: Never rely on color alone
- **High stress users**: Extra attention to clarity

### Interactive Elements
```css
/* Focus states */
outline: 2px solid var(--primary);
outline-offset: 2px;

/* Touch feedback */
/* Gentle haptic feedback where appropriate */
```

### Typography Accessibility
- **Minimum size**: 16px for body text
- **Line height**: 1.4 minimum for readability
- **Color contrast**: High contrast for medical data

## Theming & Future-Proofing

### Material Design 3 Integration
- **Dynamic Color**: Support system-generated colors where appropriate  
- **Component Library**: Use Material 3 components as base
- **Customization**: Apply water theme through careful color and shape customization

### Theme Structure
```css
/* Light theme (primary) */
:root {
  /* All color variables defined above */
}

/* Dark theme (implemented) */
@media (prefers-color-scheme: dark) {
  :root {
    --background: #1A1A1A;
    --surface: #2A2A2A;
    --primary: #8FCCB8; /* Lighter teal for dark mode */
    /* Adjust other colors for dark theme */
  }
}
```

### Manual Theme Toggle
**Implementation Status**: ✅ **Completed**

The app now includes a manual theme toggle that overrides system preferences:
- **Default Mode**: Light theme (regardless of system setting)
- **Toggle Location**: Profile screen with palette icon and light/dark mode button
- **Persistence**: User preference saved using SharedPreferences
- **Instant Switch**: No app restart required
- **State Management**: Riverpod-based theme provider (`lib/providers/theme_provider.dart`)

**Usage**: Users can manually switch between light and dark themes via the toggle button in the Profile screen, ensuring consistent testing experience and user control over theme preference.

### Design System Evolution
- **Component tokens**: Design system-ready variable structure
- **Scalability**: Easy color and spacing adjustments
- **Consistency**: Centralized design decisions
- **Maintenance**: Clear documentation for future developers

---

## Implementation Checklist

### Phase 1 (MVP)
- [ ] Implement core color palette
- [ ] Set up typography scales  
- [ ] Create primary button components
- [ ] Design navigation bar with droplet FAB
- [ ] Basic card/container styling

### Phase 2 (Enhancement)
- [ ] Custom water-themed icons
- [ ] Animation system setup
- [ ] Chart/visualization components
- [ ] Advanced accessibility features
- [x] Dark theme preparation

### Phase 3 (Polish)
- [ ] Celebration animations
- [ ] Micro-interactions
- [ ] Advanced theming system
- [ ] Performance optimization

---

*These guidelines ensure HydraCat maintains its unique identity as a comforting yet professional medical application. Every design decision should reinforce trust, reduce anxiety, and support successful fluid therapy management.*