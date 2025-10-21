# Progress Calendar Optimization & Enhancement Plan

## Overview
This document outlines optimizations and UX improvements for the Progress calendar feature based on comprehensive code review and PRD alignment. The calendar is currently functional but has opportunities for performance optimization, enhanced UX, and industry-standard features.

**Current Implementation Files:**
- `lib/features/progress/screens/progress_screen.dart` - Main screen container
- `lib/features/progress/widgets/progress_week_calendar.dart` - Calendar widget
- `lib/features/progress/widgets/progress_day_detail_popup.dart` - Day detail popup
- `lib/providers/progress_provider.dart` - State management
- `lib/features/progress/services/week_status_calculator.dart` - Business logic

**PRD Alignment Goals:**
- Encourage treatment adherence through visual feedback
- Reduce caregiver stress with positive reinforcement
- Veterinary-grade quality for professional consultations
- Build veterinary credibility

---

## <� QUICK WINS (Phase 1)
**Time Estimate**: 2-3 hours total
**Impact**: Immediate UX improvements with minimal effort

### 1. Add "Today" Button ✅ COMPLETED
**Files**: `progress_week_calendar.dart`
**Priority**: HIGH
**Effort**: 30 minutes (actual)
**Impact**: Critical UX feature - users get lost when swiping back months

**Issue**: No quick way to return to current date after browsing historical data

**Implementation** (as completed):
```dart
// Custom header in progress_week_calendar.dart
// Layout: [< chevron] [October 2025] [> chevron] [Spacer] [Today]
Widget _buildCustomHeader(BuildContext context, DateTime day) {
  final focusedDay = ref.watch(focusedDayProvider);
  final monthYearFormat = DateFormat('MMMM yyyy');
  final monthYearText = monthYearFormat.format(day);

  // Determine if we're viewing the current week
  final focusedWeekStart = AppDateUtils.startOfWeekMonday(focusedDay);
  final currentWeekStart = AppDateUtils.startOfWeekMonday(DateTime.now());
  final isOnCurrentWeek = focusedWeekStart == currentWeekStart;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        // Navigation chevrons grouped together on left
        IconButton(icon: const Icon(Icons.chevron_left), /* ... */),
        const SizedBox(width: 8),
        Text(monthYearText, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: 8),
        IconButton(icon: const Icon(Icons.chevron_right), /* ... */),
        const Spacer(),
        // "Today" button on right (only when NOT on current week)
        if (!isOnCurrentWeek)
          TextButton(
            onPressed: () {
              final today = DateTime.now();
              ref.read(focusedDayProvider.notifier).state = today;
              widget.onDaySelected(today); // Opens day detail popup
            },
            child: Text(
              'Today',
              style: AppTextStyles.buttonSecondary.copyWith(
                color: AppColors.primary, // Teal color
              ),
            ),
          ),
      ],
    ),
  );
}
```

**Key differences from original plan**:
- Implemented as custom calendar header (not AppBar button)
- Uses text "Today" instead of icon for clarity
- Conditionally visible: hidden when viewing current week
- Navigation chevrons moved close to month name
- Opens day detail popup when tapped (not just navigation)

**Learning Goal**: Custom calendar header layout, conditional widget visibility

---

### 2. Add Status Legend ✅ COMPLETED
**Files**: `progress_screen.dart`, `calendar_help_popup.dart` (new)
**Priority**: HIGH
**Effort**: 30 minutes (actual)
**Impact**: Users shouldn't have to guess what dots mean

**Issue**: No explanation of dot colors (teal/coral/amber/none)

**Implementation** (as completed):
```dart
// New file: lib/features/progress/widgets/calendar_help_popup.dart
// Accessible via help icon (?) in AppBar

// Main popup widget using OverlayService
class CalendarHelpPopup extends StatelessWidget {
  // Popup container with blur background
  // Header: "Calendar Legend" + close button
  // Body: Expandable help sections structure
}

// Expandable section widget for future help content
class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.children,
    this.title,
  });
  // Allows easy addition of new help sections
}

// Legend item widget - 8x8 dot + label + description
class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.description,
  });

  // Layout: [8x8 colored dot] [Label (bold)] + [Description]
  // Matches calendar dot appearance exactly
}

// Show function using OverlayService
void showCalendarHelpPopup(BuildContext context) {
  OverlayService.showFullScreenPopup(
    context: context,
    child: const CalendarHelpPopup(),
  );
}

// In progress_screen.dart AppBar
appBar: AppBar(
  title: const Text('Progress & Analytics'),
  actions: hasCompletedOnboarding
      ? [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => showCalendarHelpPopup(context),
            tooltip: 'Calendar help',
          ),
        ]
      : null,
),
```

**Legend Content**:
- **Complete** (Teal/AppColors.primary): "All scheduled treatments completed"
- **Today** (Amber/Color(0xFFFFB300)): "Current day (until all treatments complete)"
- **Missed** (Coral/AppColors.warning): "At least one treatment missed"
- **No dot** (Gray text, no circle): "Future days or days with no schedules"

**Key differences from original plan**:
- Implemented as full-screen popup (not inline legend below calendar)
- Accessible via help icon (?) in AppBar top-right
- Uses existing OverlayService with blur background and slideUp animation
- Includes close button (X) and dismissible by background tap
- Expandable structure allows future help content additions
- Each legend item shows description, not just label
- Only visible when user has completed onboarding

**Learning Goal**: Help popup pattern, OverlayService usage, expandable content structure

---

### 3. Add Haptic Feedback ✅ COMPLETED
**Files**: `progress_week_calendar.dart`
**Priority**: MEDIUM
**Effort**: 10 minutes (actual)
**Impact**: Tactile response makes interactions feel responsive

**Issue**: No haptic feedback on day selection

**Implementation** (as completed):
```dart
// Import added at top of file
import 'package:flutter/services.dart';

// In progress_week_calendar.dart onDaySelected (line 80-86)
onDaySelected: (selected, focused) {
  HapticFeedback.selectionClick(); // ✅ Added
  setState(() {
    _selectedDay = selected;
  });
  widget.onDaySelected(selected);
},

// In "Today" button onPressed (line 150-155)
TextButton(
  onPressed: () {
    HapticFeedback.selectionClick(); // ✅ Added
    final today = DateTime.now();
    ref.read(focusedDayProvider.notifier).state = today;
    widget.onDaySelected(today);
  },
  // ...
),
```

**Key differences from original plan**:
- Also added haptic feedback to "Today" button for consistency
- Both day selection methods now provide tactile feedback
- No linting issues found (flutter analyze passed)

**Learning Goal**: Haptic feedback pattern (already used in logging screens)

---

### 4. Visual Highlight for Today's Cell ✅ COMPLETED
**Files**: `progress_week_calendar.dart`
**Priority**: MEDIUM
**Effort**: 5 minutes (actual)
**Impact**: Makes "today" immediately recognizable beyond just the dot

**Issue**: Today only has amber dot, cell itself looks identical to other days

**Implementation** (as completed):
```dart
// In progress_week_calendar.dart calendarStyle (lines 58-69)
calendarStyle: CalendarStyle(
  todayDecoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(
      color: Theme.of(context).colorScheme.primary,
      width: 2,
    ),
  ),
  todayTextStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
    color: Theme.of(context).colorScheme.primary,
    fontWeight: FontWeight.bold,
  ),
  selectedDecoration: BoxDecoration(
    shape: BoxShape.circle,
    color: Theme.of(context).colorScheme.primary,
  ),
  // ... rest of styles
),
```

**Key differences from original plan**:
- None - implemented exactly as planned
- When today is selected, the selection state (filled circle) takes precedence over the border decoration
- Uses `Theme.of(context).colorScheme.primary` for theme-aware color (adapts to light/dark mode)
- Amber dot continues to display below the day number, creating multi-layer visual feedback

**Additional implementation**: Tap-to-deselect functionality
- Added `selectedDayProvider` in `progress_provider.dart` for Riverpod state management
- Wrapped progress screen body in `GestureDetector` to allow deselecting by tapping outside calendar
- Selection state persists across week navigation until explicitly cleared
- No toggle behavior - tapping same day keeps it selected and reopens popup

**Learning Goal**: TableCalendar styling customization, Riverpod state management patterns

---

### 5. Add Loading Skeleton ✅ COMPLETED
**Files**: `progress_week_calendar.dart`
**Priority**: MEDIUM
**Effort**: 30 minutes (actual)
**Impact**: Professional appearance during data loading

**Issue**: Shows `SizedBox.shrink()` during loading

**Implementation** (as completed):
```dart
// In _WeekDotMarker build method (lines 186-206)
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Check if schedules are loaded yet - same pattern as dashboard
  final schedules = ref.watch(medicationSchedulesProvider);

  // Show skeleton if schedules haven't loaded yet
  // null = never loaded, [] = loaded but empty
  if (schedules == null) {
    return const _DotSkeleton();
  }

  final weekStatusAsync = ref.watch(weekStatusProvider(weekStart));

  return weekStatusAsync.when(
    data: (statuses) { /* existing */ },
    loading: () => const _DotSkeleton(), // ✅ Skeleton in loading state
    error: (_, _) => const SizedBox.shrink(),
  );
}

// Loading skeleton widget with shimmer animation (lines 243-270)
class _DotSkeleton extends StatelessWidget {
  const _DotSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading status',
      child: Shimmer(
        duration: const Duration(milliseconds: 1500),
        interval: const Duration(milliseconds: 1500),
        color: const Color(0xFFF6F4F2), // Highlight: warm background
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFDDD6CE), // Base: warm border color
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
```

**Key differences from original plan**:
- Used `shimmer_animation` package instead of plain gray circle
- Warm neutral colors from design system (#DDD6CE base, #F6F4F2 highlight)
- Two loading states: initial schedules load + weekly status load
- Includes semantic label for accessibility
- 1500ms shimmer duration for subtle animation

**Learning Goal**: Loading states UX pattern, shimmer animations

---

### 6. Add Pull-to-Refresh ✅ COMPLETED
**Files**: `progress_screen.dart`
**Priority**: LOW
**Effort**: 10 minutes (actual)
**Impact**: Standard mobile pattern for refreshing data

**Issue**: No way to manually refresh calendar data

**Implementation** (as completed):
```dart
// In progress_screen.dart body
// Import added: package:hydracat/providers/profile_provider.dart

body: hasCompletedOnboarding
  ? GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        ref.read(selectedDayProvider.notifier).state = null;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          // Invalidate schedule data
          // (may have changed in Profile screen)
          ref
            ..invalidate(medicationSchedulesProvider)
            ..invalidate(fluidScheduleProvider)
            // Invalidate calendar data
            ..invalidate(weekSummariesProvider)
            ..invalidate(weekStatusProvider);

          // Brief delay to allow providers to rebuild
          await Future<void>.delayed(
            const Duration(milliseconds: 500),
          );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ProgressWeekCalendar(
            onDaySelected: (day) {
              showProgressDayDetailPopup(context, day);
            },
          ),
        ),
      ),
    )
  : /* onboarding state */,
```

**Key differences from original plan**:
- GestureDetector remains as outer wrapper for tap-to-deselect functionality
- Also invalidates schedule providers (medicationSchedulesProvider, fluidScheduleProvider)
- Uses cascade notation for cleaner code
- Removed "Analytics cards coming soon" placeholder text
- Column wrapper removed (only one child in SingleChildScrollView)

**Learning Goal**: RefreshIndicator pattern, cascade notation for multiple invalidations

---

## =� PERFORMANCE OPTIMIZATIONS (Phase 2)
**Time Estimate**: 4-5 hours total
**Impact**: Measurable performance improvements

### 7. Optimize FutureBuilder in Popup ✅ COMPLETED
**Files**: `progress_day_detail_popup.dart`, `progress_provider.dart`
**Priority**: HIGH
**Effort**: 50 minutes (actual)
**Impact**: Reduces popup loading time, better offline support

**Issue**: Sessions fetched on every popup open, no caching

**Current Flow** (before):
1. User taps day → popup opens
2. FutureBuilder fires → Firestore read
3. Data displays

**Optimized Flow** (after):
1. Week navigation → pre-fetch sessions for all 7 days
2. User taps day → instant popup with cached data
3. Background refresh when new sessions logged

**Implementation** (as completed):

**Step 7.1**: Create week sessions provider
```dart
// In progress_provider.dart (lines 136-183)

/// Pre-fetches all sessions for the focused week (7 days).
///
/// Returns a map of `date → (List<MedicationSession>, List<FluidSession>)`
/// for efficient popup rendering without additional Firestore reads.
///
/// Cache invalidates automatically when:
/// - User logs out (currentUserProvider changes)
/// - User switches pets (primaryPetProvider changes)
/// - New sessions are logged (dailyCacheProvider updates)
///
/// Does NOT use autoDispose to persist cache across navigation
/// (Progress → Home → Progress).
final FutureProviderFamily<
    Map<DateTime, (List<MedicationSession>, List<FluidSession>)>,
    DateTime> weekSessionsProvider = FutureProvider.family<
    Map<DateTime, (List<MedicationSession>, List<FluidSession>)>,
    DateTime>(
  (ref, weekStart) async {
    // Watch cache to invalidate when today's sessions change
    ref.watch(dailyCacheProvider);

    final user = ref.read(currentUserProvider);
    final pet = ref.read(primaryPetProvider);
    if (user == null || pet == null) return {};

    final service = ref.read(sessionReadServiceProvider);
    final days = List<DateTime>.generate(
      7,
      (i) => weekStart.add(Duration(days: i)),
    );

    // Fetch all 7 days in parallel
    final results = await Future.wait(
      days.map(
        (day) => service.getAllSessionsForDate(
          userId: user.id,
          petId: pet.id,
          date: day,
        ),
      ),
    );

    // Build map: date → (medSessions, fluidSessions)
    return {
      for (var i = 0; i < days.length; i++) days[i]: results[i],
    };
  },
);
```

**Step 7.2**: Update popup to use cached data
```dart
// In progress_day_detail_popup.dart _buildPlannedWithStatus (lines 233-353)

Widget _buildPlannedWithStatus(BuildContext context, WidgetRef ref) {
  // ... existing setup code (schedules, reminders)

  // Fetch from week cache
  final weekStart = AppDateUtils.startOfWeekMonday(date);
  final weekSessionsAsync = ref.watch(weekSessionsProvider(weekStart));

  return weekSessionsAsync.when(
    data: (weekSessions) {
      final (medSessions, fluidSessions) = weekSessions[date] ??
          (<MedicationSession>[], <FluidSession>[]);

      // ... existing matching and display logic
    },
    loading: () => const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: CircularProgressIndicator(),
      ),
    ),
    error: (error, stackTrace) => Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Error loading sessions: $error',
            style: const TextStyle(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () {
              // Retry by invalidating the provider
              ref.invalidate(weekSessionsProvider(weekStart));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
```

**Key differences from original plan**:
- **No autoDispose**: Cache persists across navigation (Progress → Home → Progress)
- **Auto-invalidation**: Watches `dailyCacheProvider` for instant updates when sessions logged
- **Retry functionality**: Added retry button in error state
- **Type safety**: Explicit type annotations for empty list fallback
- **Import cleanup**: Removed unused `session_read_service.dart` import from popup

**Cost Analysis**:
- Before: 1 Firestore read per popup open (frequent)
- After: 7 Firestore reads per week navigation (infrequent)
- Savings: ~80-90% reduction for typical usage patterns
- Cache persists across navigation without additional reads

**Testing Results**:
- ✅ `flutter analyze`: No issues found
- ✅ Cache persists when navigating Progress → Home → Progress
- ✅ Auto-refreshes when new sessions logged
- ✅ Retry button works in error state

**Learning Goal**: Pre-fetching pattern for predictable user flows, cache persistence strategies

---

### 8. Add Memoization for Status Calculations
**Files**: `week_status_calculator.dart`, `progress_provider.dart`
**Priority**: MEDIUM
**Effort**: 45 minutes
**Impact**: Reduces CPU usage on frequent rebuilds

**Issue**: Pure function recalculates on every provider rebuild

**Implementation**:

**Step 8.1**: Create memoization helper
```dart
// In core/utils/memoization.dart

class _MemoKey {
  final DateTime weekStart;
  final List<Schedule> medicationSchedules;
  final Schedule? fluidSchedule;
  final Map<DateTime, DailySummary?> summaries;
  final DateTime now;

  _MemoKey({
    required this.weekStart,
    required this.medicationSchedules,
    required this.fluidSchedule,
    required this.summaries,
    required this.now,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MemoKey &&
          runtimeType == other.runtimeType &&
          weekStart == other.weekStart &&
          _listEquals(medicationSchedules, other.medicationSchedules) &&
          fluidSchedule == other.fluidSchedule &&
          _mapEquals(summaries, other.summaries) &&
          now.difference(other.now).inMinutes < 1; // Cache for 1 minute

  @override
  int get hashCode => Object.hash(
        weekStart,
        Object.hashAll(medicationSchedules),
        fluidSchedule,
        Object.hashAll(summaries.entries),
        now.millisecondsSinceEpoch ~/ 60000, // Round to minute
      );
}

final _statusCache = <_MemoKey, Map<DateTime, DayDotStatus>>{};

Map<DateTime, DayDotStatus> computeWeekStatusesMemoized({
  required DateTime weekStart,
  required List<Schedule> medicationSchedules,
  required Schedule? fluidSchedule,
  required Map<DateTime, DailySummary?> summaries,
  required DateTime now,
}) {
  final key = _MemoKey(
    weekStart: weekStart,
    medicationSchedules: medicationSchedules,
    fluidSchedule: fluidSchedule,
    summaries: summaries,
    now: now,
  );

  if (_statusCache.containsKey(key)) {
    return _statusCache[key]!;
  }

  final result = computeWeekStatuses(
    weekStart: weekStart,
    medicationSchedules: medicationSchedules,
    fluidSchedule: fluidSchedule,
    summaries: summaries,
    now: now,
  );

  _statusCache[key] = result;

  // LRU eviction - keep only 10 most recent
  if (_statusCache.length > 10) {
    _statusCache.remove(_statusCache.keys.first);
  }

  return result;
}
```

**Step 8.2**: Use memoized version in provider
```dart
// In progress_provider.dart weekStatusProvider

return computeWeekStatusesMemoized( // � Changed from computeWeekStatuses
  weekStart: weekStart,
  medicationSchedules: medicationSchedules,
  fluidSchedule: fluid,
  summaries: summaries,
  now: now,
);
```

**Performance Impact**: ~50% reduction in CPU for status calculations on rapid calendar swiping

**Learning Goal**: Memoization pattern for pure functions

---

### 9. Lazy Load Popup Content
**Files**: `overlay_service.dart`, `progress_day_detail_popup.dart`
**Priority**: LOW
**Effort**: 1 hour
**Impact**: Smoother animation, perceived performance improvement

**Issue**: Popup content loads during slideUp animation, causing jank

**Implementation**:

**Step 9.1**: Add delayed content loading
```dart
// In progress_day_detail_popup.dart

class _ProgressDayDetailPopupState extends ConsumerState<ProgressDayDetailPopup> {
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    // Wait for animation to complete (200ms slideUp + 50ms buffer)
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _showContent = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          // ... existing container setup
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: AppSpacing.md),
                Divider(/* ... */),
                const SizedBox(height: AppSpacing.md),

                // Lazy load content
                if (_showContent)
                  _buildContent(context, ref, isFuture)
                else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

**Alternative**: Use `FutureBuilder` with artificial 250ms delay

**Learning Goal**: Animation timing coordination

---

## <� UX ENHANCEMENTS (Phase 3)
**Time Estimate**: 6-8 hours total
**Impact**: Significantly improved user experience

### 10. Month View Toggle
**Files**: `progress_week_calendar.dart`, `progress_provider.dart`
**Priority**: HIGH
**Effort**: 1.5 hours
**Impact**: Industry-standard calendar feature, better overview

**Issue**: Fixed to week view, can't see full month at once

**Implementation**:

**Step 10.1**: Add format state provider
```dart
// In progress_provider.dart

final calendarFormatProvider = StateProvider<CalendarFormat>((ref) {
  return CalendarFormat.week;
});
```

**Step 10.2**: Update calendar widget
```dart
// In progress_week_calendar.dart

final format = ref.watch(calendarFormatProvider);

return TableCalendar<void>(
  calendarFormat: format, // � Changed from CalendarFormat.week
  availableCalendarFormats: const {
    CalendarFormat.week: 'Week',
    CalendarFormat.month: 'Month',
  },
  headerStyle: HeaderStyle(
    formatButtonVisible: true, // � Changed from false
    formatButtonDecoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(8),
    ),
    formatButtonTextStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
      color: Theme.of(context).colorScheme.onPrimaryContainer,
    ),
  ),
  onFormatChanged: (newFormat) {
    ref.read(calendarFormatProvider.notifier).state = newFormat;
  },
  // ... rest of config
);
```

**Step 10.3**: Update data loading for month view
```dart
// In progress_provider.dart

final focusedMonthStartProvider = StateProvider<DateTime>((ref) {
  final format = ref.watch(calendarFormatProvider);
  final focusedDay = ref.watch(focusedDayProvider);

  if (format == CalendarFormat.month) {
    return DateTime(focusedDay.year, focusedDay.month, 1);
  } else {
    return AppDateUtils.startOfWeekMonday(focusedDay);
  }
});

// Update weekStatusProvider to handle both week and month
final dateRangeStatusProvider = FutureProvider.autoDispose
    .family<Map<DateTime, DayDotStatus>, DateTime>(
  (ref, rangeStart) async {
    ref.watch(dailyCacheProvider);

    final format = ref.watch(calendarFormatProvider);
    final days = format == CalendarFormat.month
        ? _getDaysInMonth(rangeStart)
        : List.generate(7, (i) => rangeStart.add(Duration(days: i)));

    // ... fetch summaries for all days in range
  },
);
```

**Performance Note**: Month view = 28-31 days, ~4x more Firestore reads than week view. Consider pagination or on-demand loading.

**Learning Goal**: Dynamic data loading based on view format

---

### 11. Date Picker for Quick Navigation
**Files**: `progress_screen.dart`
**Priority**: MEDIUM
**Effort**: 45 minutes
**Impact**: Allows jumping to specific date (e.g., vet appointment)

**Issue**: No way to jump to specific date, must swipe repeatedly

**Implementation**:
```dart
// In progress_screen.dart AppBar actions

IconButton(
  icon: const Icon(Icons.calendar_month),
  tooltip: 'Jump to date',
  onPressed: () async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: ref.read(focusedDayProvider),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      ref.read(focusedDayProvider.notifier).state = selectedDate;
    }
  },
),
```

**Location**: Add next to "Today" button in AppBar actions

**Learning Goal**: showDatePicker usage and theming

---

### 12. Swipe-to-Dismiss Popup
**Files**: `progress_day_detail_popup.dart`, `overlay_service.dart`
**Priority**: MEDIUM
**Effort**: 2 hours
**Impact**: More natural mobile interaction

**Issue**: Only dismissible by close button or background tap

**Implementation**:

**Step 12.1**: Replace current popup with DraggableScrollableSheet
```dart
// In progress_day_detail_popup.dart

void showProgressDayDetailPopup(BuildContext context, DateTime date) {
  OverlayService.showFullScreenPopup(
    context: context,
    child: DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.5, 0.75, 0.9],
      builder: (context, scrollController) {
        return ProgressDayDetailPopup(
          date: date,
          scrollController: scrollController,
        );
      },
    ),
  );
}
```

**Step 12.2**: Update popup to use scroll controller
```dart
// In ProgressDayDetailPopup build method

child: SingleChildScrollView(
  controller: widget.scrollController, // � Pass from DraggableScrollableSheet
  child: Column(/* existing content */),
),
```

**Accessibility Note**: Ensure screen readers announce drag capability

**Learning Goal**: DraggableScrollableSheet for bottom sheets

---

### 13. Week Number Display
**Files**: `progress_week_calendar.dart`
**Priority**: LOW
**Effort**: 30 minutes
**Impact**: Useful for medical tracking and vet appointments

**Issue**: No week number reference for medical documentation

**Implementation**:
```dart
// In progress_week_calendar.dart

return Column(
  children: [
    _buildWeekHeader(context, ref),
    TableCalendar<void>(/* ... */),
  ],
);

Widget _buildWeekHeader(BuildContext context, WidgetRef ref) {
  final focusedDay = ref.watch(focusedDayProvider);
  final weekNumber = _getISOWeekNumber(focusedDay);
  final monthYear = DateFormat('MMMM yyyy').format(focusedDay);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Week $weekNumber',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          monthYear,
          style: AppTextStyles.h3,
        ),
      ],
    ),
  );
}

int _getISOWeekNumber(DateTime date) {
  final dayOfYear = int.parse(DateFormat('D').format(date));
  final weekNumber = ((dayOfYear - date.weekday + 10) / 7).floor();
  return weekNumber;
}
```

**Location**: Above TableCalendar widget

**Learning Goal**: ISO 8601 week number calculation

---

### 14. Dot Animation on Status Change
**Files**: `progress_week_calendar.dart`
**Priority**: LOW
**Effort**: 1 hour
**Impact**: Satisfying visual feedback when logging treatments

**Issue**: Dot color changes instantly, no visual feedback

**Implementation**:
```dart
// In _WeekDotMarker build method

Widget _buildStatusDot(DayDotStatus status) {
  final Color? color;
  final String semanticLabel;

  switch (status) {
    case DayDotStatus.complete:
      color = AppColors.primary;
      semanticLabel = 'Completed day';
    case DayDotStatus.missed:
      color = AppColors.warning;
      semanticLabel = 'Missed day';
    case DayDotStatus.today:
      color = Colors.amber[600];
      semanticLabel = 'Today';
    case DayDotStatus.none:
      return const SizedBox.shrink();
  }

  return Semantics(
    label: semanticLabel,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    ),
  );
}
```

**Enhancement**: Add scale animation on change
```dart
return TweenAnimationBuilder<double>(
  tween: Tween(begin: 0.8, end: 1.0),
  duration: const Duration(milliseconds: 300),
  curve: Curves.elasticOut,
  builder: (context, scale, child) {
    return Transform.scale(
      scale: scale,
      child: Semantics(
        label: semanticLabel,
        child: AnimatedContainer(/* ... */),
      ),
    );
  },
);
```

**Learning Goal**: AnimatedContainer and TweenAnimationBuilder patterns

---

### 15. Empty State Messaging
**Files**: `progress_week_calendar.dart`
**Priority**: MEDIUM
**Effort**: 45 minutes
**Impact**: Guides users to set up schedules

**Issue**: No helpful message when user has no treatment schedules

**Implementation**:

**Step 15.1**: Detect empty schedule state
```dart
// In progress_provider.dart

final hasAnySchedulesProvider = Provider<bool>((ref) {
  final medSchedules = ref.watch(medicationSchedulesProvider) ?? [];
  final fluidSchedule = ref.watch(fluidScheduleProvider);
  return medSchedules.isNotEmpty || fluidSchedule != null;
});
```

**Step 15.2**: Show empty state
```dart
// In progress_screen.dart

body: hasCompletedOnboarding
  ? Builder(
      builder: (context) {
        final hasSchedules = ref.watch(hasAnySchedulesProvider);

        if (!hasSchedules) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No schedules set up yet',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Add treatment schedules in Settings to start tracking your progress',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: () => context.go('/settings'),
                    icon: const Icon(Icons.settings),
                    label: const Text('Go to Settings'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(/* existing calendar */);
      },
    )
  : /* onboarding empty state */,
```

**Learning Goal**: Contextual empty states with CTAs

---

## =� INDUSTRY-STANDARD FEATURES (Phase 4)
**Time Estimate**: 8-10 hours total
**Impact**: Professional-grade calendar feature set

### 16. Export Calendar View (PDF)
**Files**: New file `progress_export_service.dart`, `progress_screen.dart`
**Priority**: HIGH (PRD Goal: "Veterinary consultation-ready documentation")
**Effort**: 3 hours
**Impact**: Critical for vet appointments

**Issue**: No way to export calendar for veterinary consultations

**Implementation**:

**Step 16.1**: Add dependency
```yaml
# pubspec.yaml
dependencies:
  pdf: ^3.10.7
  printing: ^5.11.1
```

**Step 16.2**: Create export service
```dart
// lib/features/progress/services/progress_export_service.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ProgressExportService {
  Future<void> exportMonthToPDF({
    required DateTime month,
    required String petName,
    required Map<DateTime, DayDotStatus> statuses,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(petName, month),
              pw.SizedBox(height: 20),
              _buildCalendarGrid(month, statuses),
              pw.SizedBox(height: 20),
              _buildLegend(),
              pw.SizedBox(height: 20),
              _buildSummary(statuses),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  pw.Widget _buildHeader(String petName, DateTime month) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Treatment Progress Report',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Pet: $petName'),
        pw.Text('Period: ${DateFormat('MMMM yyyy').format(month)}'),
        pw.Text('Generated: ${DateFormat('MMM d, yyyy').format(DateTime.now())}'),
      ],
    );
  }

  pw.Widget _buildCalendarGrid(DateTime month, Map<DateTime, DayDotStatus> statuses) {
    // Build 7x5 grid for month
    // Each cell shows day number + status indicator
    // ...implementation details
  }

  pw.Widget _buildLegend() {
    return pw.Row(
      children: [
        _legendItem(PdfColors.teal, 'Completed'),
        pw.SizedBox(width: 20),
        _legendItem(PdfColors.amber, 'Today'),
        pw.SizedBox(width: 20),
        _legendItem(PdfColors.red300, 'Missed'),
      ],
    );
  }

  pw.Widget _buildSummary(Map<DateTime, DayDotStatus> statuses) {
    final completed = statuses.values.where((s) => s == DayDotStatus.complete).length;
    final missed = statuses.values.where((s) => s == DayDotStatus.missed).length;
    final total = statuses.length;
    final adherenceRate = total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('Adherence Rate: $adherenceRate%'),
        pw.Text('Completed Days: $completed'),
        pw.Text('Missed Days: $missed'),
      ],
    );
  }
}
```

**Step 16.3**: Add export button to UI
```dart
// In progress_screen.dart AppBar

IconButton(
  icon: const Icon(Icons.picture_as_pdf),
  tooltip: 'Export to PDF',
  onPressed: () async {
    final pet = ref.read(primaryPetProvider);
    final focusedDay = ref.read(focusedDayProvider);
    final monthStart = DateTime(focusedDay.year, focusedDay.month, 1);

    // Fetch month data
    final statuses = await ref.read(
      dateRangeStatusProvider(monthStart).future,
    );

    await ref.read(progressExportServiceProvider).exportMonthToPDF(
      month: monthStart,
      petName: pet?.name ?? 'Unknown',
      statuses: statuses,
    );
  },
),
```

**Learning Goal**: PDF generation for professional documentation

---

### 17. Streak Visualization
**Files**: `progress_screen.dart`, new widget `streak_display_card.dart`
**Priority**: HIGH (PRD Goal: "Gamification & Motivation System")
**Effort**: 2 hours
**Impact**: Motivational element from PRD

**Issue**: Streak counter exists in data model but not prominently displayed

**Implementation**:

**Step 17.1**: Create streak display widget
```dart
// lib/features/progress/widgets/streak_display_card.dart

class StreakDisplayCard extends ConsumerWidget {
  const StreakDisplayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysSummaryAsync = ref.watch(
      summaryServiceProvider.getTodaySummary(/* userId, petId */),
    );

    return todaysSummaryAsync.when(
      data: (summary) {
        final currentStreak = summary?.overallStreak ?? 0;
        final longestStreak = _getLongestStreak(ref); // From monthly summaries

        return Card(
          margin: const EdgeInsets.all(AppSpacing.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: _StreakColumn(
                    icon: Icons.local_fire_department,
                    iconColor: Colors.orange,
                    label: 'Current Streak',
                    value: '$currentStreak days',
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(
                  child: _StreakColumn(
                    icon: Icons.emoji_events,
                    iconColor: Colors.amber,
                    label: 'Longest Streak',
                    value: '$longestStreak days',
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StreakColumn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 32),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
```

**Step 17.2**: Add to progress screen
```dart
// In progress_screen.dart

Column(
  children: [
    StreakDisplayCard(), // � Add this
    ProgressWeekCalendar(/* ... */),
    // ... rest of content
  ],
)
```

**Learning Goal**: Motivational UI patterns from PRD gamification goals

---

### 18. Notes/Events on Calendar
**Files**: New model `calendar_event.dart`, `progress_provider.dart`, `progress_week_calendar.dart`
**Priority**: MEDIUM
**Effort**: 3 hours
**Impact**: Allows marking vet appointments, medication changes

**Issue**: No way to annotate calendar with important events

**Implementation**:

**Step 18.1**: Create calendar event model
```dart
// lib/features/progress/models/calendar_event.dart

@immutable
class CalendarEvent {
  final String id;
  final String petId;
  final String userId;
  final DateTime date;
  final String title;
  final String? notes;
  final CalendarEventType type;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CalendarEvent({
    required this.id,
    required this.petId,
    required this.userId,
    required this.date,
    required this.title,
    this.notes,
    required this.type,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() { /* ... */ }
  factory CalendarEvent.fromJson(Map<String, dynamic> json) { /* ... */ }
}

enum CalendarEventType {
  vetAppointment,
  medicationChange,
  labWork,
  other;

  IconData get icon {
    switch (this) {
      case CalendarEventType.vetAppointment:
        return Icons.medical_services;
      case CalendarEventType.medicationChange:
        return Icons.medication;
      case CalendarEventType.labWork:
        return Icons.science;
      case CalendarEventType.other:
        return Icons.event_note;
    }
  }

  Color get color {
    switch (this) {
      case CalendarEventType.vetAppointment:
        return Colors.blue;
      case CalendarEventType.medicationChange:
        return Colors.purple;
      case CalendarEventType.labWork:
        return Colors.green;
      case CalendarEventType.other:
        return Colors.grey;
    }
  }
}
```

**Step 18.2**: Add Firestore collection
```dart
// Firestore path: users/{userId}/pets/{petId}/calendarEvents/{eventId}
```

**Step 18.3**: Display events on calendar
```dart
// In progress_week_calendar.dart calendarBuilders

calendarBuilders: CalendarBuilders(
  markerBuilder: (context, day, events) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WeekDotMarker(day: day, weekStart: weekStart),
        if (_hasEventOnDay(ref, day))
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  },
),
```

**Step 18.4**: Add event creation dialog
```dart
// Floating action button to add event on selected day
// Dialog with: title, type selector, notes, date picker
```

**Learning Goal**: Complex calendar annotations with Firestore

---

### 19. Keyboard Navigation (Accessibility)
**Files**: `progress_week_calendar.dart`
**Priority**: LOW
**Effort**: 1.5 hours
**Impact**: Accessibility compliance for desktop/tablet users

**Issue**: No keyboard shortcuts for calendar navigation

**Implementation**:
```dart
// In progress_week_calendar.dart

return Focus(
  autofocus: true,
  onKey: (node, event) {
    if (event is RawKeyDownEvent) {
      final focusedDay = ref.read(focusedDayProvider);

      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        ref.read(focusedDayProvider.notifier).state =
            focusedDay.subtract(const Duration(days: 1));
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        ref.read(focusedDayProvider.notifier).state =
            focusedDay.add(const Duration(days: 1));
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        ref.read(focusedDayProvider.notifier).state =
            focusedDay.subtract(const Duration(days: 7));
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        ref.read(focusedDayProvider.notifier).state =
            focusedDay.add(const Duration(days: 7));
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        showProgressDayDetailPopup(context, focusedDay);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        OverlayService.hide();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  },
  child: TableCalendar<void>(/* ... */),
);
```

**Keyboard Shortcuts**:
- Arrow Left/Right: Previous/next day
- Arrow Up/Down: Previous/next week
- Enter: Open day details
- Escape: Close popup

**Learning Goal**: Keyboard navigation for accessibility

---

### 20. Deep Linking
**Files**: `router.dart`
**Priority**: LOW
**Effort**: 1 hour
**Impact**: Useful for notification taps jumping to specific dates

**Issue**: No URL-based navigation to specific calendar dates

**Implementation**:
```dart
// In router.dart

GoRoute(
  path: '/progress/:date?',
  builder: (context, state) {
    final dateParam = state.pathParameters['date'];

    // Parse date from URL parameter (YYYY-MM-DD format)
    if (dateParam != null) {
      try {
        final targetDate = DateTime.parse(dateParam);
        // Set focused day before showing screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final container = ProviderScope.containerOf(context);
          container.read(focusedDayProvider.notifier).state = targetDate;
        });
      } catch (e) {
        // Invalid date, use default
      }
    }

    return const ProgressScreen();
  },
),
```

**Usage Examples**:
- `/progress` - Default (today)
- `/progress/2025-10-15` - Jump to specific date
- `hydracat://progress/2025-10-15` - From notification

**Learning Goal**: Deep linking with GoRouter parameters

---

### 21. Reduce Motion Support
**Files**: `progress_week_calendar.dart`, `progress_day_detail_popup.dart`
**Priority**: LOW
**Effort**: 30 minutes
**Impact**: Accessibility compliance for motion-sensitive users

**Issue**: No respect for system "reduce motion" preference

**Implementation**:
```dart
// In progress_week_calendar.dart _buildStatusDot

Widget _buildStatusDot(DayDotStatus status, BuildContext context) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);

  // ... color logic

  return Semantics(
    label: semanticLabel,
    child: reduceMotion
        ? Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          )
        : AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
  );
}
```

**Apply to**:
- Dot animations
- Popup slide animations
- DraggableScrollableSheet snapping

**Learning Goal**: Accessibility-first animation approach (already used in logging plan)

---

### 22. Error State with Retry
**Files**: `progress_week_calendar.dart`
**Priority**: MEDIUM
**Effort**: 30 minutes
**Impact**: Better error handling UX

**Issue**: Error state shows nothing (line 114)

**Implementation**:
```dart
// In _WeekDotMarker build method

return weekStatusAsync.when(
  data: (statuses) { /* existing */ },
  loading: () => _DotSkeleton(),
  error: (error, stackTrace) => Tooltip(
    message: 'Failed to load status. Tap to retry.',
    child: GestureDetector(
      onTap: () {
        ref.invalidate(weekStatusProvider(weekStart));
      },
      child: Icon(
        Icons.error_outline,
        size: 12,
        color: AppColors.error.withOpacity(0.5),
      ),
    ),
  ),
);
```

**Learning Goal**: Error state recovery patterns

---

## <� RECOMMENDED IMPLEMENTATION ORDER

1. **Week 1**: Phase 1 (Quick Wins) - Immediate UX improvements
2. **Week 2**: Items 16, 17 from Phase 4 - PRD critical features (PDF export, streaks)
3. **Week 3**: Phase 2 (Performance) - Foundation for scaling
4. **Week 4**: Phase 3 (UX Enhancements) - Polish
5. **Week 5**: Remaining Phase 4 items - Nice-to-haves

---

## =� SUCCESS METRICS

**User Engagement**:
- Time spent on Progress screen increases by 30%
- Calendar interactions (swipes, taps) increase by 50%

**Performance**:
- Popup load time <200ms (from ~500ms)
- Calendar swipe jank eliminated (60fps maintained)
- Firestore reads reduced by 80% for popup data

**User Satisfaction**:
- Reduced support questions about calendar navigation
- Positive feedback on PDF export feature
- Increased streak engagement (from PRD gamification goals)

---

## =' TESTING STRATEGY

**Unit Tests**:
- Memoization cache hit/miss rates
- Status calculation logic
- Event model validation

**Widget Tests**:
- Calendar interaction flows
- Popup opening/closing
- Empty state displays

**Integration Tests**:
- Week/month data loading performance
- PDF generation with real data
- Deep linking navigation

**Manual Testing**:
- Accessibility (VoiceOver/TalkBack)
- Keyboard navigation
- Reduce motion compliance
- Various screen sizes

---

## =� NOTES

- **Priority Changes**: If vet consultations are critical soon, do Phase 4 item #16 (PDF export) immediately
- **Month View Performance**: May need to implement pagination if >31 days becomes slow
- **Deep Linking**: Requires coordination with notification system (future feature)
- **Calendar Events**: Consider premium tier feature (aligns with PRD business model)

**Defer to Future**:
- Multi-pet calendar view (Premium feature)
- Calendar widget for home screen
- Share calendar with vet portal (requires backend integration)
- Advanced analytics overlays (correlations, trends)

---

*This plan aligns with PRD goals: encouraging adherence through visual feedback, reducing caregiver stress, and building veterinary credibility through professional documentation tools.*
