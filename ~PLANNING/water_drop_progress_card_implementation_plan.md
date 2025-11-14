# Water Drop Progress Card - Complete Implementation Plan

## Implementation Status

**Current Phase**: Complete Phases 2-3 minor additions, then implement Phase 4

✅ **Phase 1: Data Alignment** - COMPLETE (Verified 2025-01-14)
⚠️ **Phase 2: Data Models** - MOSTLY COMPLETE (needs fields added to WeeklySummary and CatProfile)
⚠️ **Phase 3: Services** - MOSTLY COMPLETE (needs LoggingService updates)
🚧 **Phase 4-10**: Ready to implement after Phase 2-3 additions

**Next Steps**:
1. Add `fluidScheduledVolume` field to `WeeklySummary` model
2. Add `lastFluidInjectionSite` and `lastFluidSessionDate` fields to `CatProfile` model
3. Update `LoggingService` to:
   - Write injection site to pet document
   - Calculate and write `fluidScheduledVolume` to weekly summary
4. Proceed with Phase 4 (Riverpod Providers)

**Cost Optimization Summary**:
- ✅ 0-1 reads per home screen load (weekly summary only, cached 15min)
- ✅ 0 extra reads for injection site (from cached pet profile)
- ✅ 0 extra reads for weekly goal (stored in weekly summary)
- ✅ Follows firebase_CRUDrules.md: "Denormalize when beneficial"

## Overview

A visually prominent card widget that displays **weekly** fluid intake progress using an animated water drop illustration combined with large, readable text statistics and injection site tracking.

**Purpose**: Serve as a motivational hero element on the home screen, positioned between "Welcome Back" and "Today's Treatments", showing at-a-glance weekly progress.

**Key Features**:
- Animated water drop with organic 3-layer wave system
- Large, readable volume statistics (current/goal)
- Last injection site display for easy reference (continuous tracking across weeks for safe site rotation)
- Fixed 220px height for consistent layout
- Automatic transition to subtle pulse after 10 seconds
- Re-energizes animation on session log (5 seconds)
- Weekly completion celebration with hybrid animation
- Accessibility support (reduced motion, semantics)
- Optimized Firebase reads (1 read per home screen load)

---

## Design Decisions (All Confirmed ✅)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Position** | Between "Welcome Back" and "Today's Treatments" | Immediate visual impact, motivational context before tasks |
| **Tracking Period** | Weekly | Most users have 1 daily session; weekly shows gradual progress |
| **Sizing** | Fixed 220px height | Consistent, predictable, works on all devices |
| **Expansion** | None (no tap-to-expand) | Simplified, no battery concerns |
| **Animation** | Organic waves (calming medical tone) | Sophisticated, not mechanical |
| **Data Source** | Existing `WeeklySummary` via `SummaryService` + local goal from `fluidSchedule` | 1 cached read; no schema changes; respects pre-aggregated summaries |
| **Celebration** | Hybrid (enhanced success animation) | Medical-appropriate, consistent with existing system |

---

## File Structure

### New Files to Create

1. **`lib/shared/widgets/fluid/water_drop_painter.dart`**
   - Reusable animated water drop component
   - Contains: `WaterDropWidget` (StatefulWidget) and `WaterDropPainter` (CustomPainter)
   - Can be used standalone in other contexts

2. **`lib/shared/widgets/fluid/water_drop_progress_card.dart`**
   - Main card widget combining drop + text layout
   - Contains: `WaterDropProgressCard` (ConsumerWidget)
   - Handles layout, formatting, responsive sizing

3. **`lib/providers/weekly_progress_provider.dart`**
   - Composes `authProvider`, `profileProvider`, and `SummaryService.getWeeklySummary(DateTime.now())`
   - Outputs `WeeklyProgressViewModel { givenMl (double), goalMl (int), fillPercentage (double 0..1+), lastInjectionSite (String) }`
   - **Cost optimization**: 0-1 reads total (weekly summary only, cached 15min). Pet profile and injection site already cached in `profileProvider`.
   - **Last injection site**: Read directly from `primaryPet.lastFluidInjectionSite` (0 extra reads, no week boundaries)
   - **Weekly goal**: Read from `weeklySummary.fluidScheduledVolume`, fallback to calculating from `fluidSchedule` if null

4. **`lib/shared/widgets/animations/weekly_completion_animation.dart`** (Optional v2)
   - Hybrid celebration animation (no external package)
   - Contains: `WeeklyCompletionAnimation` (StatefulWidget)
   - Radial particle burst + scaled checkmark

5. **`lib/shared/widgets/animations/weekly_completion_dialog.dart`** (Optional v2)
   - Success dialog for weekly milestone
   - Contains: `WeeklyCompletionDialog` (StatelessWidget)
   - Shows animation + congratulatory message

### Files to Modify

1. **`lib/shared/models/weekly_summary.dart`**
   - Add `fluidScheduledVolume` field (int?, nullable)
   - Update `fromJson()`, `toJson()`, `copyWith()`, equality, hashCode

2. **`lib/features/profile/models/cat_profile.dart`**
   - Add `lastFluidInjectionSite` field (String?, nullable)
   - Add `lastFluidSessionDate` field (DateTime?, nullable)
   - Update `fromJson()`, `toJson()`, `copyWith()`, equality, hashCode

3. **`lib/features/logging/services/logging_service.dart`**
   - Update `logFluidSession()` to write injection site to pet document
   - Add `_calculateWeeklyGoalFromSchedules()` helper method
   - Update `_updateFluidSummaries()` to write `fluidScheduledVolume` to weekly summary
   - Cache weekly goal per week to avoid repeated schedule reads

4. **`lib/features/home/screens/home_screen.dart`**
   - Add `WaterDropProgressCard` between header and treatments
   - No changes to logging flow required

5. **`lib/providers/analytics_provider.dart`** (Optional v2)
   - Add weekly-progress events if desired (non-blocking)

---

## Phase 1: Data Alignment (Minor Schema Additions) ✅ MOSTLY COMPLETE

### Use Existing Weekly Summary Path with Minor Additions

**Path (already exists):**

```markdown
users/{userId}/pets/{petId}/treatmentSummaries/weekly/summaries/{YYYY-Www}
```

**Status**: ✅ **VERIFIED COMPLETE**
- Path confirmed in `lib/features/logging/services/summary_service.dart:477-494`
- Path confirmed in `.cursor/rules/firestore_schema.md:201-224`

**Existing Fields** (already in use):
- ✅ `fluidTotalVolume` (double) - Total ml given this week
- ✅ `fluidTreatmentDays` (int) - Days with sessions
- ✅ `fluidSessionCount` (int) - Total sessions
- ✅ `startDate`, `endDate` (Timestamp)

**New Field** (to add):
- ⚠️ `fluidScheduledVolume` (int?, nullable) - Weekly goal in ml
  - Written by LoggingService when first session logged each week
  - Ensures historically accurate goals when schedule changes mid-week

**Pet Document Updates** (for injection site tracking):

```markdown
users/{userId}/pets/{petId}
```

**New Fields** (to add):
- ⚠️ `lastFluidInjectionSite` (String?, nullable) - Most recent injection site
- ⚠️ `lastFluidSessionDate` (Timestamp?, nullable) - When that site was used

**Cost Optimization**:
- ✅ 0-1 reads per home screen load (weekly summary cached 15min)
- ✅ 0 extra reads for injection site (pet profile already cached)
- ✅ Follows firebase_CRUDrules.md: "Denormalize when beneficial"

**Rationale**:
- Reuses pre-aggregated summaries per firebase_CRUDrules.md
- Stores weekly goal for historical accuracy
- Stores injection site in pet doc for continuous tracking (no week boundaries)
- Keeps existing write paths in `LoggingService` with minimal additions

---

## Phase 2: Data Models (Minor Additions Required)

### Weekly Summary Model - Minor Addition Required

**Status**: ⚠️ **NEEDS MINOR UPDATE**

- ✅ `lib/shared/models/weekly_summary.dart` exists and is complete
- ✅ `fluidTotalVolume` is correctly typed as `double` (line 109)
- ✅ Model includes required fields: `startDate`, `endDate`, `fluidTotalVolume`, `fluidTreatmentDays`, `fluidSessionCount`
- ⚠️ **ADD FIELD**: `fluidScheduledVolume` (int?, nullable) - Weekly goal in ml
  - Enables historically accurate weekly goals when schedule changes
  - Written by `LoggingService` at time of first session each week
  - Eliminates need to calculate goal from schedule (which may have changed)

### Pet Profile Model - Minor Addition Required

**Status**: ⚠️ **NEEDS MINOR UPDATE**

- ✅ `lib/features/profile/models/cat_profile.dart` exists
- ⚠️ **ADD FIELDS** for continuous injection site tracking:
  - `lastFluidInjectionSite` (String?, nullable) - Most recent injection site used
  - `lastFluidSessionDate` (DateTime?, nullable) - When that site was used
  - **Benefits**: 0 extra reads (pet already cached), no week boundaries, simple access
  - **Cost optimization**: Follows "denormalize when beneficial" principle from firebase_CRUDrules.md
  - Will be populated by `LoggingService` when logging fluid sessions

## Phase 3: Business Logic & Services ⚠️ MOSTLY COMPLETE

### Summary Service

**Status**: ✅ **VERIFIED COMPLETE**

**File**: `lib/features/logging/services/summary_service.dart` (ALREADY EXISTS)

**Purpose**: Fetch and cache weekly summary data

**What's Already Implemented**:

✅ **`SummaryService.getWeeklySummary()`** (lines 248-300):
- Fetches weekly summary for any date's ISO week
- Returns `WeeklySummary` model with all required fields
- Uses 15-minute TTL in-memory cache
- Exactly 1 Firestore read per cache miss
- Handles null/missing documents gracefully

✅ **Cache Management**:
- `clearMemoryCache()` - Clear all caches
- `invalidateTodaysCache()` - Invalidate today's cache after logging
- `invalidateCacheForDate()` - Invalidate specific date cache

✅ **Firestore Paths**:
- `_getWeeklySummaryRef()` - Returns correct document reference
- Path: `users/{userId}/pets/{petId}/treatmentSummaries/weekly/summaries/{YYYY-Www}`

### Logging Service Updates

**Status**: ⚠️ **UPDATES NEEDED**

**File**: `lib/features/logging/services/logging_service.dart`

**What Needs to be Added**:

1. **Update Pet Document with Last Injection Site** (in `logFluidSession` method):
   ```dart
   // Add to batch in logFluidSession method
   final petRef = _firestore
       .collection('users')
       .doc(userId)
       .collection('pets')
       .doc(petId);

   batch.update(petRef, {
     'lastFluidInjectionSite': session.injectionSite?.toString().split('.').last,
     'lastFluidSessionDate': session.dateTime,
     'updatedAt': FieldValue.serverTimestamp(),
   });
   ```

2. **Add `fluidScheduledVolume` to Weekly Summary** (in `_updateFluidSummaries` method):
   ```dart
   // Calculate weekly goal from active schedules
   final weeklyGoal = await _calculateWeeklyGoalFromSchedules(userId, petId);

   // Add to weekly summary batch.set():
   batch.set(
     weeklyRef,
     {
       // ... existing fields
       'fluidScheduledVolume': weeklyGoal,  // NEW: Store calculated goal
       'updatedAt': FieldValue.serverTimestamp(),
     },
     SetOptions(merge: true),
   );
   ```

3. **Add Helper Method** `_calculateWeeklyGoalFromSchedules()`:
   - Fetches active fluid schedules
   - Calculates weekly goal based on frequency (once daily × 7, twice daily × 14, etc.)
   - Returns int (total ml for the week)
   - Cache the result per week to avoid repeated schedule reads

---

## Phase 4: Riverpod Providers

### Weekly Progress Provider

**File**: `lib/providers/weekly_progress_provider.dart` (NEW)

This provider composes weekly summary data with pet profile data (for injection site).

**Cost Optimization:**
- 0-1 reads: Weekly summary (cached 15 min)
- 0 extra reads: Pet profile already cached in `profileProvider`
- 0 extra reads: No schedule calculation needed (goal stored in weekly summary)

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/logging/services/summary_service.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_providers.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/models/weekly_summary.dart';

/// View model for weekly progress display
@immutable
class WeeklyProgressViewModel {
  const WeeklyProgressViewModel({
    required this.givenMl,
    required this.goalMl,
    required this.fillPercentage,
    required this.lastInjectionSite,
  });

  /// Total volume given this week (ml)
  final double givenMl;

  /// Weekly goal volume (ml)
  final int goalMl;

  /// Fill percentage (0.0 to 1.0+)
  final double fillPercentage;

  /// Last injection site used (continuous across weeks)
  /// Shows "None yet" only if no sessions have ever been logged
  final String lastInjectionSite;
}

/// Provider for weekly progress data
///
/// Composes:
/// - Weekly summary (from SummaryService with 15-min cache) - 0-1 reads
/// - Weekly goal (from fluidScheduledVolume in weekly summary) - 0 reads
/// - Last injection site (from pet profile, already cached) - 0 reads
final weeklyProgressProvider = FutureProvider.autoDispose<WeeklyProgressViewModel?>((ref) async {
  // Get auth state and current pet
  final authState = ref.watch(authProvider);
  final profileState = ref.watch(profileProvider);

  if (authState is! AuthStateAuthenticated || profileState.primaryPet == null) {
    return null;
  }

  final userId = authState.user.uid;
  final petId = profileState.primaryPet!.id;
  final summaryService = ref.watch(summaryServiceProvider);

  try {
    // 1. Get weekly summary (cached, 0-1 read)
    final weeklySummary = await summaryService.getWeeklySummary(
      userId: userId,
      petId: petId,
      date: DateTime.now(),
    );

    final givenMl = weeklySummary?.fluidTotalVolume ?? 0.0;

    // 2. Get weekly goal from summary (0 reads, already in summary)
    // Fallback to calculating from schedule if not yet logged this week
    final goalMl = weeklySummary?.fluidScheduledVolume
        ?? _calculateWeeklyGoalFromSchedule(profileState.fluidSchedule);

    // 3. Get last injection site from pet profile (0 reads, already cached)
    final lastSite = profileState.primaryPet!.lastFluidInjectionSite;
    final lastInjectionSite = lastSite != null
        ? _formatInjectionSite(lastSite)
        : 'None yet';

    // 4. Calculate fill percentage
    final fillPercentage = goalMl > 0 ? (givenMl / goalMl).clamp(0.0, 2.0) : 0.0;

    return WeeklyProgressViewModel(
      givenMl: givenMl,
      goalMl: goalMl,
      fillPercentage: fillPercentage,
      lastInjectionSite: lastInjectionSite,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[WeeklyProgressProvider] Error: $e');
    }
    return null;
  }
});

/// Calculate weekly goal from fluid schedule (fallback for new weeks)
///
/// Used only when fluidScheduledVolume not yet written to weekly summary
/// (i.e., first home screen load before any sessions logged this week)
int _calculateWeeklyGoalFromSchedule(Schedule? fluidSchedule) {
  if (fluidSchedule == null || fluidSchedule.targetVolume == null) {
    return 0;
  }

  final dailyVolume = fluidSchedule.targetVolume!;
  final frequency = fluidSchedule.frequency;

  switch (frequency) {
    case TreatmentFrequency.onceDaily:
      return (dailyVolume * 7).round();
    case TreatmentFrequency.twiceDaily:
      return (dailyVolume * 2 * 7).round();
    case TreatmentFrequency.thriceDaily:
      return (dailyVolume * 3 * 7).round();
    case TreatmentFrequency.alternateDays:
      return (dailyVolume * 3.5).round(); // ~3-4 times per week
    default:
      return (dailyVolume * 7).round();
  }
}

/// Format injection site enum value for display
String _formatInjectionSite(String siteValue) {
  // Convert "left_flank" or "leftFlank" to "Left Flank"
  return siteValue
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
      .join(' ');
}
```

---

## Phase 5: Water Drop Widget

### Animated Water Drop Component

**File**: `lib/shared/widgets/fluid/water_drop_painter.dart`

```dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_animations.dart';
import 'package:hydracat/core/constants/app_colors.dart';

/// Animated water drop widget with organic wave motion
/// 
/// Shows fill percentage (0.0 to 1.0) with animated waves.
/// Automatically transitions to subtle pulse after 10 seconds to save battery.
/// 
/// Usage:
/// ```dart
/// WaterDropWidget(
///   fillPercentage: 0.75,  // 75% filled
///   height: 220.0,
/// )
/// ```
class WaterDropWidget extends StatefulWidget {
  /// Fill percentage (0.0 = empty, 1.0 = full)
  final double fillPercentage;
  
  /// Height of the drop widget (width is calculated as height * 0.83)
  final double height;

  const WaterDropWidget({
    super.key,
    required this.fillPercentage,
    required this.height,
  });

  @override
  State<WaterDropWidget> createState() => _WaterDropWidgetState();
}

class _WaterDropWidgetState extends State<WaterDropWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  
  late AnimationController _waveController;
  Timer? _pulseTransitionTimer;
  bool _isSubtlePulse = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Start animation if motion is not reduced
    if (!AppAnimations.shouldReduceMotion(context)) {
      _waveController.repeat();

      // Transition to subtle pulse after 10 seconds
      _pulseTransitionTimer = Timer(const Duration(seconds: 10), () {
        _transitionToSubtlePulse();
      });
    }
  }

  /// Transition to slower, less intense wave animation
  void _transitionToSubtlePulse() {
    if (!mounted || _isSubtlePulse) return;

    setState(() {
      _isSubtlePulse = true;
    });

    // Slower animation (4 seconds instead of 2.5)
    _waveController.duration = const Duration(milliseconds: 4000);
    _waveController.repeat();
  }

  /// Called when session is logged - re-energize animation
  void refreshAfterLog() {
    if (!mounted || AppAnimations.shouldReduceMotion(context)) return;

    _pulseTransitionTimer?.cancel();
    
    setState(() {
      _isSubtlePulse = false;
    });

    // Reset to normal speed
    _waveController.duration = const Duration(milliseconds: 2500);
    _waveController.repeat();

    // Resume subtle pulse after 5 seconds
    _pulseTransitionTimer = Timer(const Duration(seconds: 5), () {
      _transitionToSubtlePulse();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _waveController.stop();
      _pulseTransitionTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (mounted && !AppAnimations.shouldReduceMotion(context)) {
        _waveController.repeat();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _waveController.dispose();
    _pulseTransitionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.height * 0.83;

    return Semantics(
      label: 'Water drop showing ${(widget.fillPercentage * 100).round()} percent progress',
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return CustomPaint(
            size: Size(width, widget.height),
            painter: WaterDropPainter(
              fillLevel: widget.fillPercentage,
              wavePhase: _waveController.value * 2 * pi,
              enableWaves: !AppAnimations.shouldReduceMotion(context),
              isSubtlePulse: _isSubtlePulse,
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for water drop shape with animated waves
class WaterDropPainter extends CustomPainter {
  final double fillLevel;
  final double wavePhase;
  final bool enableWaves;
  final bool isSubtlePulse;

  WaterDropPainter({
    required this.fillLevel,
    required this.wavePhase,
    required this.enableWaves,
    required this.isSubtlePulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Create drop shape path
    final dropPath = _createDropPath(width, height);

    // Clip to drop shape
    canvas.save();
    canvas.clipPath(dropPath);

    if (enableWaves) {
      _drawWaveFill(canvas, width, height);
    } else {
      _drawStaticGradientFill(canvas, width, height);
    }

    canvas.restore();

    // Draw drop border
    canvas.drawPath(
      dropPath,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  /// Create classic water drop shape using Bezier curves
  Path _createDropPath(double width, double height) {
    final path = Path();

    // Start at top point (center-top)
    path.moveTo(width / 2, 0);

    // Left curve (control point at 10% width, 35% height)
    path.quadraticBezierTo(
      width * 0.1,
      height * 0.35,
      width * 0.1,
      height * 0.7,
    );

    // Bottom circular arc
    path.arcToPoint(
      Offset(width * 0.9, height * 0.7),
      radius: Radius.circular(width * 0.4),
      clockwise: false,
    );

    // Right curve (symmetrical)
    path.quadraticBezierTo(
      width * 0.9,
      height * 0.35,
      width / 2,
      0,
    );

    path.close();
    return path;
  }

  /// Draw animated wave fill
  void _drawWaveFill(Canvas canvas, double width, double height) {
    final waterLevel = height * (1 - fillLevel);

    // Adjust amplitudes for subtle pulse mode
    final amplitudeMultiplier = isSubtlePulse ? 0.5 : 1.0;

    // Optimized wave parameters (organic, not mechanical)
    final amplitude1 = 2.5 * amplitudeMultiplier;  // Fast shimmer (surface detail)
    final amplitude2 = 6.0 * amplitudeMultiplier;  // Medium swell (main motion)
    final amplitude3 = 4.0 * amplitudeMultiplier;  // Slow base (foundation)

    const frequency1 = 3.0;  // Finer ripples
    const frequency2 = 1.5;  // Broader waves
    const frequency3 = 0.8;  // Very broad

    const speed1 = 1.0;
    const speed2 = 0.6;  // Calmer
    const speed3 = 0.4;  // Very slow

    // Build wave path
    final wavePath = Path();
    wavePath.moveTo(0, height);

    for (double x = 0; x <= width; x += 1) {
      final normalizedX = x / width;

      final wave1 = amplitude1 *
          sin(normalizedX * 2 * pi * frequency1 + wavePhase * speed1);
      final wave2 = amplitude2 *
          sin(normalizedX * 2 * pi * frequency2 + wavePhase * speed2);
      final wave3 = amplitude3 *
          sin(normalizedX * 2 * pi * frequency3 + wavePhase * speed3);

      final y = waterLevel + wave1 + wave2 + wave3;

      if (x == 0) {
        wavePath.lineTo(x, y);
      } else {
        wavePath.lineTo(x, y);
      }
    }

    wavePath.lineTo(width, height);
    wavePath.close();

    // Draw base water fill
    canvas.drawPath(
      wavePath,
      Paint()..color = AppColors.primary,
    );

    // Draw wave highlights (lighter, translucent)
    canvas.drawPath(
      wavePath,
      Paint()
        ..color = AppColors.primaryLight.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Draw wave shadows (darker, translucent)
    canvas.drawPath(
      wavePath,
      Paint()
        ..color = AppColors.primaryDark.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  /// Draw static gradient fill (reduced motion mode)
  void _drawStaticGradientFill(Canvas canvas, double width, double height) {
    final waterLevel = height * (1 - fillLevel);

    final fillRect = Rect.fromLTWH(0, waterLevel, width, height - waterLevel);

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primaryLight.withOpacity(0.8),
        AppColors.primary,
        AppColors.primaryDark,
      ],
    );

    canvas.drawRect(
      fillRect,
      Paint()..shader = gradient.createShader(fillRect),
    );
  }

  @override
  bool shouldRepaint(WaterDropPainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.enableWaves != enableWaves ||
        oldDelegate.isSubtlePulse != isSubtlePulse;
  }
}
```

---

## Phase 6: Water Drop Progress Card

### Main Card Widget

**File**: `lib/shared/widgets/fluid/water_drop_progress_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/providers/summary_provider.dart';
import 'package:hydracat/shared/widgets/fluid/water_drop_painter.dart';

/// Water drop progress card showing weekly fluid intake progress
/// 
/// Displays:
/// - Animated water drop (fills based on weekly progress)
/// - Current volume vs goal
/// - Last injection site used
/// - Completion percentage with color coding
/// 
/// Data source: weeklyProgressProvider (SummaryService + cached schedule)
class WaterDropProgressCard extends ConsumerWidget {
  final EdgeInsetsGeometry? padding;

  const WaterDropProgressCard({
    super.key,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklySummaryAsync = ref.watch(weeklyProgressProvider);

    return weeklySummaryAsync.when(
      data: (vm) {
        if (vm == null) {
          return const SizedBox.shrink();
        }
        return _buildCard(context, vm);
      },
      loading: () => _buildLoadingCard(context),
      error: (error, stack) => _buildErrorCard(context, error),
    );
  }

  Widget _buildCard(BuildContext context, WeeklyProgressViewModel vm) {
    final currentMl = vm.givenMl;
    final goalMl = vm.goalMl;
    final fillPercentage = vm.fillPercentage;
    final percentageDisplay = (vm.fillPercentage * 100).round();
    final lastSiteDisplay = vm.lastInjectionSite;

    return Semantics(
      container: true,
      label: 'Weekly fluid intake progress card',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, 4),
              color: Colors.black.withOpacity(0.08),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Water drop (60% space)
            Flexible(
              flex: 6,
              child: WaterDropWidget(
                fillPercentage: fillPercentage,
                height: 220.0,
              ),
            ),

            const SizedBox(width: 24),

            // Right: Text stats (40% space)
            Flexible(
              flex: 4,
              child: _buildTextStats(
                context,
                currentMl: currentMl,
                goalMl: goalMl,
                percentageDisplay: percentageDisplay,
                fillPercentage: fillPercentage,
                lastSiteDisplay: lastSiteDisplay,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextStats(
    BuildContext context, {
    required num currentMl,
    required int goalMl,
    required int percentageDisplay,
    required double fillPercentage,
    required String lastSiteDisplay,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Current Volume (Large, prominent)
        Text(
          _formatMl(currentMl),
          style: AppTextStyles.display,  // 32px, semi-bold
        ),

        const SizedBox(height: 8),

        // Goal Volume (Medium, secondary color for hierarchy)
        Row(
          children: [
            Text(
              'Goal: ',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              _formatMl(goalMl),
              style: AppTextStyles.h2,  // 20px, medium
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Separator line
        Container(
          width: 120,
          height: 1,
          color: AppColors.border,
        ),

        const SizedBox(height: 12),

        // Last Injection Site (Small, supplementary)
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              'Last: ',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: Text(
                lastSiteDisplay,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Percentage (Medium-large, color-coded status)
        Text(
          '$percentageDisplay%',
          style: AppTextStyles.h1.copyWith(  // 24px, semi-bold
            color: _getPercentageColor(fillPercentage),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      height: 260,  // Fixed height (220 + padding)
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, Object error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Unable to load weekly progress',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format volume (reused from fluid_daily_summary_card.dart)
  String _formatMl(num ml) {
    if (ml >= 1000) {
      final liters = ml / 1000.0;
      return '${liters.toStringAsFixed(liters >= 10 ? 0 : 1)} L';
    }
    return '${ml.round()} ml';
  }

  // (Optional) last injection site formatting can be added later if needed.

  /// Get percentage color based on progress
  Color _getPercentageColor(double percentage) {
    if (percentage >= 1.0) {
      return AppColors.success;  // Week complete! (green)
    } else if (percentage >= 0.7) {
      return AppColors.primary;  // On track (teal)
    } else if (percentage >= 0.5) {
      return AppColors.warning;  // Okay pace (amber)
    } else {
      return AppColors.error;    // Behind schedule (red)
    }
  }
}
```

---

## Phase 7: Weekly Completion Celebration

### Hybrid Celebration Animation (No External Package)

**File**: `lib/shared/widgets/animations/weekly_completion_animation.dart` (NEW)

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';

/// Hybrid celebration animation for weekly goal completion
/// 
/// Features:
/// - Enlarged checkmark (1.5x scale) with pulse effect
/// - 12 particle burst (radial, fading outward)
/// - Duration: 2.5 seconds
/// - Medical-appropriate subtlety (not overly playful)
/// 
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => WeeklyCompletionAnimation(),
/// );
/// ```
class WeeklyCompletionAnimation extends StatefulWidget {
  const WeeklyCompletionAnimation({super.key});

  @override
  State<WeeklyCompletionAnimation> createState() =>
      _WeeklyCompletionAnimationState();
}

class _WeeklyCompletionAnimationState extends State<WeeklyCompletionAnimation>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Checkmark scale animation (0 → 1.5 → 1.5)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.5).chain(
          CurveTween(curve: Curves.elasticOut),
        ),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.5),
        weight: 40,
      ),
    ]).animate(_controller);

    // Pulse animation (1.5 → 1.6 → 1.5)
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween(1.5),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.5, end: 1.6).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.6, end: 1.5).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 20,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Particle burst (12 particles)
            ...List.generate(12, (i) {
              final angle = (i * 30.0) * (pi / 180);
              return _buildParticle(angle);
            }),

            // Checkmark (animated scale + pulse)
            AnimatedBuilder(
              animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _controller.value < 0.6
                      ? _scaleAnimation.value
                      : _pulseAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build single particle with radial motion and fade
  Widget _buildParticle(double angle) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 80.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, distance, child) {
        final offsetX = distance * cos(angle);
        final offsetY = distance * sin(angle);
        final opacity = 1.0 - (distance / 80.0);

        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
```

---

### Weekly Completion Dialog

**File**: `lib/shared/widgets/animations/weekly_completion_dialog.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/shared/widgets/animations/weekly_completion_animation.dart';

/// Dialog shown when weekly goal is completed
/// 
/// Displays:
/// - Celebration animation (checkmark + particles)
/// - Congratulatory message with pet name
/// - "Continue" button to dismiss
class WeeklyCompletionDialog extends StatelessWidget {
  final String petName;
  final int totalVolume;

  const WeeklyCompletionDialog({
    super.key,
    required this.petName,
    required this.totalVolume,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation
            const SizedBox(
              height: 200,
              child: WeeklyCompletionAnimation(),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Week Complete! 🎉',
              style: AppTextStyles.h1.copyWith(
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              'Perfect week for $petName!',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Volume stat
            Text(
              _formatMl(totalVolume),
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: AppTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMl(int ml) {
    if (ml >= 1000) {
      final liters = ml / 1000.0;
      return '${liters.toStringAsFixed(liters >= 10 ? 0 : 1)} L total';
    }
    return '$ml ml total';
  }
}
```

---

## Phase 8: Integration with Home Screen

### Update Home Screen Layout

**File**: `lib/features/home/screens/home_screen.dart`

**Locate**: In the main `Column` after the "Welcome Back" header.

**Add**:
```dart
// After the 'Welcome Back' Text:
const SizedBox(height: AppSpacing.md),
const WaterDropProgressCard(),
const SizedBox(height: AppSpacing.md),
```

---

### Handle Celebration Dialog (Optional v2)

- Prefer to trigger from Home after a fresh load detects `fill >= 1.0`.
- Use a simple in-memory guard per `{userId, petId, weekId}` to avoid duplicates.

---

## Phase 9: Testing & Validation

### Widget Tests

**File**: `test/shared/widgets/fluid/water_drop_progress_card_test.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/shared/widgets/fluid/water_drop_progress_card.dart';
import 'package:hydracat/providers/weekly_progress_provider.dart';

void main() {
  testWidgets('displays weekly progress correctly', (tester) async {
    final mock = WeeklyProgressViewModel(
      givenMl: 1050.0,
      goalMl: 1400,
      fillPercentage: 1050.0 / 1400.0,
      lastInjectionSite: 'Left Flank',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklyProgressProvider.overrideWith((_) async => mock),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: WaterDropProgressCard(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify current volume is displayed
    expect(find.text('1.1 L'), findsOneWidget);  // 1050ml → 1.1 L

    // Verify goal is displayed
    expect(find.text('Goal: '), findsOneWidget);
    expect(find.text('1.4 L'), findsOneWidget);

    // Verify percentage is displayed
    expect(find.text('75%'), findsOneWidget);  // 1050/1400 = 75%
  });

  testWidgets('shows empty state for new week', (tester) async {
    final empty = WeeklyProgressViewModel(
      givenMl: 0.0,
      goalMl: 1400,
      fillPercentage: 0.0,
      lastInjectionSite: 'None yet',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklyProgressProvider.overrideWith((_) async => empty),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: WaterDropProgressCard(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify 0ml displayed
    expect(find.text('0 ml'), findsOneWidget);

    // Verify goal displayed
    expect(find.text('1.4 L'), findsOneWidget);

    // Verify 0% displayed
    expect(find.text('0%'), findsOneWidget);

    // Verify "None yet" for injection site
    expect(find.text('None yet'), findsOneWidget);
  });

  testWidgets('shows loading state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklyProgressProvider.overrideWith((_) async => null),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: WaterDropProgressCard(),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify loading indicator is shown
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

---

## Phase 10: Analytics Integration

### Analytics Events

**File**: `lib/core/constants/analytics_events.dart`

**Add** to existing events:
```dart
class AnalyticsEvents {
  // ... existing events

  // Weekly milestone events
  static const weeklyGoalAchieved = 'weekly_goal_achieved';
  static const weeklyProgressViewed = 'weekly_progress_viewed';
  static const weeklyCardTapped = 'weekly_card_tapped';
}

class AnalyticsParams {
  // ... existing params

  // Weekly milestone params
  static const weeklyVolume = 'weekly_volume';
  static const weeklyGoal = 'weekly_goal';
  static const achievedEarly = 'achieved_early';
  static const daysRemaining = 'days_remaining';
}
```

---

## Complete Implementation Checklist

### Phase 1: Data Alignment ⚠️ MINOR ADDITIONS
- [x] Reuse existing path `treatmentSummaries/weekly/summaries/{YYYY-Www}`
- [ ] Add `fluidScheduledVolume` field to weekly summary schema
- [ ] Add `lastFluidInjectionSite` and `lastFluidSessionDate` fields to pet document schema

### Phase 2: Data Models ⚠️ MINOR ADDITIONS NEEDED
- [x] Reuse `lib/shared/models/weekly_summary.dart` as base
- [x] Handle `fluidTotalVolume` as double in UI math/formatting
- [ ] Add `fluidScheduledVolume` field to `lib/shared/models/weekly_summary.dart`
- [ ] Add `lastFluidInjectionSite` and `lastFluidSessionDate` fields to `lib/features/profile/models/cat_profile.dart`

### Phase 3: Services ⚠️ UPDATES NEEDED
- [x] Use `SummaryService.getWeeklySummary(...)` (TTL cached)
- [ ] Update `LoggingService.logFluidSession()` to write injection site to pet document
- [ ] Add `_calculateWeeklyGoalFromSchedules()` helper to `LoggingService`
- [ ] Update `_updateFluidSummaries()` to write `fluidScheduledVolume` to weekly summary

### Phase 4: Providers
- [ ] Create `lib/providers/weekly_progress_provider.dart`
- [ ] Create `WeeklyProgressViewModel` class with fields: `givenMl`, `goalMl`, `fillPercentage`, `lastInjectionSite`
- [ ] Implement `weeklyProgressProvider` that composes weekly summary + pet profile
- [ ] Read `goalMl` from `weeklySummary.fluidScheduledVolume` (fallback to calculating from schedule)
- [ ] Read `lastInjectionSite` from `primaryPet.lastFluidInjectionSite` (0 extra reads)
- [ ] Implement `_calculateWeeklyGoalFromSchedule()` helper (fallback only)
- [ ] Implement `_formatInjectionSite()` helper for display formatting

### Phase 5: Water Drop Widget
- [ ] Create `lib/shared/widgets/fluid/water_drop_painter.dart`
- [ ] Implement `WaterDropWidget` with lifecycle management
- [ ] Implement `_transitionToSubtlePulse()` after 10 seconds
- [ ] Implement `refreshAfterLog()` method (5-second re-energize)
- [ ] Implement `WaterDropPainter` with 3-layer wave system
- [ ] Implement `_createDropPath()` using Bezier curves
- [ ] Implement `_drawWaveFill()` with optimized wave parameters
- [ ] Implement `_drawStaticGradientFill()` for reduced motion
 - [ ] Use `AppAnimations.shouldReduceMotion(context)`

### Phase 6: Progress Card
- [ ] Create `lib/shared/widgets/fluid/water_drop_progress_card.dart`
- [ ] Implement `_buildCard()` with drop + text layout
- [ ] Implement `_buildTextStats()` with 4-element column
- [ ] Implement `_formatMl(num ml)` helper (handles double)
- [ ] (Optional) Add last-site display without extra reads
- [ ] Implement `_getPercentageColor()` with 4-tier logic
- [ ] Implement `_buildLoadingCard()` skeleton
- [ ] Implement `_buildErrorCard()` error state

### Phase 7: Celebration Animation (Optional v2)
- [ ] Create `lib/shared/widgets/animations/weekly_completion_animation.dart`
- [ ] Implement checkmark scale animation (0 → 1.5)
- [ ] Implement pulse animation (1.5 ↔ 1.6)
- [ ] Implement `_buildParticle()` with 12 radial particles
- [ ] Create `lib/shared/widgets/animations/weekly_completion_dialog.dart`
- [ ] Implement dialog with animation + message + stats
 - [ ] Trigger from Home after detecting `fill >= 1.0`

### Phase 8: Home Screen Integration
- [ ] Update `lib/features/home/screens/home_screen.dart`
- [ ] Add `WaterDropProgressCard()` between header and treatments
- [ ] (Optional) Add simple completion guard/trigger in Home

### Phase 9: Testing
- [ ] Create `test/shared/widgets/fluid/water_drop_progress_card_test.dart`
- [ ] Test normal progress display
- [ ] Test empty state (new week)
- [ ] Test loading state
- [ ] Provider composition math test (fill from summary + schedule)

### Phase 10: Analytics
- [ ] (Optional) Add weekly progress events in `analytics_provider.dart`

### Phase 11: Documentation & Polish
- [ ] Add dartdoc comments to all public APIs
- [ ] Document wave animation parameters
- [ ] Add usage examples in file headers
- [ ] Run `flutter analyze` and fix warnings
- [ ] Test on physical devices (iOS and Android)
- [ ] Test with reduced motion enabled
- [ ] Test on small screens (iPhone SE) and large screens (tablets)
- [ ] Verify animation smoothness (60fps target)
- [ ] Test app lifecycle (background/resume)
- [ ] Move plan to `~PLANNING/DONE/` when complete

---

## Success Criteria

### Functional Requirements ✅
- [ ] Card displays between "Welcome Back" and "Today's Treatments"
- [ ] Water drop fills based on weekly progress (0-100%+)
- [ ] Current volume and goal displayed with proper formatting
- [ ] Last injection site shown (continuous tracking across week boundaries for safe site rotation)
- [ ] Percentage color-coded (red/amber/teal/green)
- [ ] Wave animation runs for 10 seconds, then subtle pulse
- [ ] Animation re-energizes for 5 seconds after session log
- [ ] Celebration dialog shows on 100% weekly completion
- [ ] Reduced motion support (static gradient fill)
- [ ] Loading and error states handled gracefully

### Performance Requirements ✅
- [ ] 0-1 Firestore reads per home screen load (weekly summary only, cached 15min via SummaryService)
- [ ] 0 extra reads for injection site (from cached pet profile in `profileProvider`)
- [ ] 0 extra reads for weekly goal (stored in weekly summary, fallback to cached schedule calculation)
- [ ] Follows firebase_CRUDrules.md optimization guidelines
- [ ] Animation runs at 60fps on mid-range devices
- [ ] App lifecycle properly pauses/resumes animation
- [ ] No memory leaks from animation controllers

### User Experience ✅
- [ ] Card is visually prominent but not overwhelming
- [ ] Text is large and readable
- [ ] Injection site info is easily accessible
- [ ] Empty state provides actionable context
- [ ] Celebration feels rewarding but medical-appropriate
- [ ] No battery drain from continuous animation

### Code Quality ✅
- [ ] All code follows existing patterns and style
- [ ] Comprehensive dartdoc comments
- [ ] No `flutter analyze` warnings
- [ ] Test coverage >80% for new code
- [ ] Accessibility semantic labels correct

---

## Future Enhancements (Out of Scope)

- Tap card to see detailed weekly breakdown
- Weekly trend comparison (this week vs last week)
- Multiple pet progress (side-by-side drops)
- Custom themes (drop color customization)
- Haptic feedback on milestone
- Sound effects (optional, settings-controlled)
- Social sharing ("Share Progress" button)
- Weekly streak badges
- Historical week gallery

---

## References

- **Existing Pattern**: `lib/shared/widgets/fluid/fluid_daily_summary_card.dart` (formatting helpers)
- **Animation Constants**: `lib/core/constants/app_animations.dart` (reduced motion)
- **Color Scheme**: `lib/core/constants/app_colors.dart` (primary, success, error)
- **Text Styles**: `lib/core/theme/app_text_styles.dart` (display, h1, h2, body, caption)
- **Date Utils**: `lib/core/utils/date_utils.dart` (week/month formatting)
- **Firestore Schema**: `.cursor/rules/firestore_schema.md` (data structure)
- **Logging Plan**: `logging_plan.md` (session logging flow)
- **App Shell**: `lib/app/app_shell.dart` (lifecycle example)

---

**Plan Created**: 2025-11-14  
**Status**: Ready for Implementation  
**Estimated Implementation Time**: 8-12 hours (experienced developer)

---

## Quick Start

1. ~~**Phase 1**: Data alignment (reuse existing summaries)~~ ✅ COMPLETE
2. ~~**Phase 2**: Confirm existing models (WeeklySummary)~~ ✅ COMPLETE
3. ~~**Phase 3**: Reuse SummaryService in provider~~ ✅ COMPLETE
4. **START HERE → Phase 4**: Weekly progress provider (compose summary + schedule)
5. **Phase 5**: Water drop painter (visual core)
6. **Phase 6**: Progress card (assembly)
7. **Phase 7**: Celebration animation (optional)
8. **Phase 8**: Home screen (user-facing)
9. **Phase 9**: Provider + widget tests
10. **Phase 10**: Optional analytics and documentation

**Current Status**: Phases 1-3 verified complete. Ready to implement Phase 4 (Riverpod Providers).
