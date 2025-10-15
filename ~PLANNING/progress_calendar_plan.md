## HydraCat Progress Calendar (Weekly) – Implementation Plan

### Overview
Add a horizontal, Monday→Sunday weekly calendar under the `AppBar` on `ProgressScreen`. The calendar uses `table_calendar` to render one row of days with a single status dot per day:
- Green: all scheduled treatments for that date were completed
- Red: at least one scheduled treatment not fully completed (medication or fluid)
- Gold: current day (until the day satisfies green)
- No dot: future days of the visible week and past days with zero schedules

On day tap, a full-screen blurred popup shows either the day’s logged treatments (past/today) or the planned treatments (future), reusing existing cards/patterns where possible.

References: `table_calendar` package [pub page](https://pub.dev/packages/table_calendar), [API docs](https://pub.dev/documentation/table_calendar/latest/).

---

### Requirements (confirmed)
1. Green day: medicationTotalDoses == medicationScheduledDoses AND fluidSessionCount == scheduledFluidSessions(for that date). If a type isn’t scheduled that day, it doesn’t affect the result.
2. Adherence for v1 uses session count (not volume-based) for fluids.
3. Past days with zero schedules: no dot. Today: gold dot until the day becomes green.
4. Future days within the week: no dot regardless of schedules.
5. Tap opens popup (blurred background via existing `OverlayService`) showing:
   - Past/today: logged treatments (list + daily summary)
   - Future: planned view (read-only schedules for that date)
6. Reads optimized: up to 7 daily summary docs for week; day detail uses two date-range queries (med sessions, fluid sessions), each `limit(50)` and offline-cache friendly.
7. Calendar config: `CalendarFormat.week`, `StartingDayOfWeek.monday`, minimal header with chevrons, row height ~64–72, palette: green[500], red[500], amber[600] exposed via theme constants.
8. Primary pet only (for now). Accessibility: add semantics on markers: Completed/Missed/Today/No status.

---

### Architecture & Data Flow

#### Inputs we already have
- Schedules: `medicationSchedulesProvider` and `fluidScheduleProvider` (+ helpers like `Schedule.reminderTimesOnDate(date)` and frequency-aware `_isActiveOnDate`).
- Summaries: `SummaryService.getDailySummary(userId, petId, date)` with fast in-memory TTL caches.
- Today cache: `DailySummaryCache` via `dailyCacheProvider` and `SummaryCacheService` warm-up on startup.
- Auth/Pet: `currentUserProvider`, `primaryPetProvider`.

#### New pieces
1. Day status model
   - `enum DayDotStatus { none, today, complete, missed }`
   - Helper: `DayDot computeStatus({required DateTime date, required DayContext ctx})` where `DayContext` carries scheduled counts, `DailySummary?`, and `DateTime now`.

2. Weekly status calculator (pure function)
   - Input: `DateTime weekStart (Mon)`, schedules, a map of `date -> DailySummary?` (7 entries), and `now`.
   - Output: `Map<DateTime, DayDotStatus>` for 7 days.

3. Riverpod providers
   - `focusedWeekStartProvider` (state): the Monday for the current `focusedDay` of the calendar.
   - `weekSummariesProvider(weekStart)` (future): parallel fetch of 7 daily summaries using `SummaryService` (benefits from TTL).
   - `weekStatusProvider(weekStart)` (future): combines schedules + `weekSummariesProvider` to produce 7 statuses. Depends on `dailyCacheProvider` so today’s status recomputes immediately after logging.

4. UI widgets
   - `ProgressWeekCalendar` (new): encapsulates `TableCalendar` and marker rendering using `CalendarBuilders.markerBuilder`.
   - `DayDetailPopup` (new): overlay popup using existing `OverlayService.showFullScreenPopup` with `slideUp` animation.

5. Optional (reads)
   - `SessionReadService` (new) in `features/logging/services/` for read-only, cost-optimized day-range queries of medication/fluid sessions. Keeps write-services clean.

---

### Status Computation Logic

Let `date` be a day in the visible week. Normalize with `AppDateUtils.startOfDay(date)` for stable comparisons.

1) Future days: if `date > today`, status = `none`.
2) Today: if not yet “fully completed”, status = `today` (gold). If by the time of recomputation all scheduled items are completed (see 4), status flips to `complete`.
3) Past days with zero schedules: status = `none`.
4) Past days with schedules (or today once all are done):
   - Compute `scheduledMedCount = sum(schedule.reminderTimesOnDate(date).length for all medication schedules)`
   - Compute `scheduledFluidCount = fluidSchedule?.reminderTimesOnDate(date).length ?? 0`
   - Fetch `DailySummary? s = getDailySummary(date)`
   - Define `medOk = scheduledMedCount == 0 || s?.medicationTotalDoses == scheduledMedCount`
   - Define `fluidOk = scheduledFluidCount == 0 || s?.fluidSessionCount == scheduledFluidCount`
   - If `medOk && fluidOk`: `complete`, else `missed`

Notes:
- If no `DailySummary` exists but `scheduledMedCount + scheduledFluidCount > 0`, treat as `missed`.
- Today recomputation: `weekStatusProvider` depends on `dailyCacheProvider` so log operations (which update the cache) will invalidate today’s status and flip gold → green automatically once counts align.

---

### UI – Calendar

Component: `ProgressWeekCalendar` rendered at top of `ProgressScreen` body (under the `AppBar`).

Configuration:
```dart
TableCalendar(
  firstDay: DateTime.utc(2010, 1, 1),
  lastDay: DateTime.utc(2035, 12, 31),
  focusedDay: _focusedDay,                   // kept in StateProvider
  calendarFormat: CalendarFormat.week,       // single-row week
  startingDayOfWeek: StartingDayOfWeek.monday,
  headerStyle: const HeaderStyle(
    formatButtonVisible: false,
    titleCentered: false,                    // month + chevrons
  ),
  availableGestures: AvailableGestures.horizontalSwipe,
  shouldFillViewport: false,
  daysOfWeekStyle: DaysOfWeekStyle(
    weekendStyle: Theme.of(context).textTheme.labelMedium!,
  ),
  calendarStyle: CalendarStyle(
    markersAlignment: Alignment.bottomCenter,
    markersAutoAligned: true,
    todayDecoration: const BoxDecoration(shape: BoxShape.circle), // we’ll draw gold dot via marker, not decoration
    outsideDaysVisible: false,
    cellMargin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
  ),
  onPageChanged: (fd) => ref.read(focusedWeekStartProvider.notifier).state = AppDateUtils.startOfWeekMonday(fd),
  selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
  onDaySelected: (selected, focused) => _onDayTap(selected),
  calendarBuilders: CalendarBuilders(
    markerBuilder: (context, day, events) => WeekDotMarker(day: day, statuses: ref.watch(weekStatusProvider(AppDateUtils.startOfWeekMonday(ref.watch(focusedDayProvider))))),
  ),
)
```

Marker rendering (`WeekDotMarker`):
- Compute status for the given day from the map.
- Return a single `Container` with `width/height ~6–8`, `BoxShape.circle`, and color:
  - complete → green[500]
  - missed → red[500]
  - today → amber[600]
  - none → `SizedBox.shrink()` (no dot)
- Wrap in `Semantics` with appropriate label per accessibility requirement.

Styling rules: follow `ui_guidelines.md`, reuse theme color constants (add to `AppTheme` if needed): `appColors.success`, `appColors.danger`, `appColors.warning`.

---

### Popup – Day Detail

Trigger: `onDaySelected` in `ProgressWeekCalendar`.

Popup container: existing `OverlayService.showFullScreenPopup` with `slideUp` animation (200ms). Use a new `ProgressDayDetailPopup` widget:

Layout:
- Title row: `{Weekday, Month d}` + close button
- Summary pill(s):
  - “Medication: M of N doses” (if any scheduled)
  - “Fluid: X of Y sessions” (if any scheduled)
- Content:
  - Past/today: List of logged medication sessions (name, time, dose, completed) and fluid sessions (time, volume). Limit display to 50; paginate in future if needed.
  - Future: Planned schedules for that date (med cards per reminder time, fluid total planned volume/time windows). Read-only.

Data reads:
- Sessions (per-type) queried by date range: `>= startOfDay(date)` and `< endOfDay(date)`, `limit(50)`, ordered by `dateTime DESC`, leveraging Firestore offline cache.
- To compute “N scheduled” in the summary, reuse schedules in memory (`Schedule.reminderTimesOnDate(date)`).

Accessibility:
- `Semantics(liveRegion: true)` announce day summary when popup opens.

---

### Providers – Signatures & Behavior

```dart
// 1) Focused day and week
final focusedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());
final focusedWeekStartProvider = StateProvider<DateTime>((ref) {
  final day = ref.watch(focusedDayProvider);
  return AppDateUtils.startOfWeekMonday(day);
});

// 2) Fetch 7 daily summaries in parallel (cache-aware)
final weekSummariesProvider = FutureProvider.family<Map<DateTime, DailySummary?>, DateTime>((ref, weekStart) async {
  final user = ref.read(currentUserProvider);
  final pet = ref.read(primaryPetProvider);
  if (user == null || pet == null) return {};

  final summaryService = ref.read(summaryServiceProvider);
  final days = List<DateTime>.generate(7, (i) => weekStart.add(Duration(days: i)));
  final results = await Future.wait(days.map((d) => summaryService.getDailySummary(userId: user.id, petId: pet.id, date: d)));
  return {for (var i = 0; i < days.length; i++) days[i]: results[i]};
});

// 3) Compute statuses for 7 days
final weekStatusProvider = FutureProvider.family<Map<DateTime, DayDotStatus>, DateTime>((ref, weekStart) async {
  // When today’s cache changes (after logging), we want to recompute
  ref.watch(dailyCacheProvider); // dependency only

  final summaries = await ref.watch(weekSummariesProvider(weekStart).future);
  final meds = ref.watch(medicationSchedulesProvider) ?? [];
  final fluid = ref.watch(fluidScheduleProvider);
  final now = DateTime.now();

  Map<DateTime, DayDotStatus> out = {};
  for (int i = 0; i < 7; i++) {
    final date = AppDateUtils.startOfDay(weekStart.add(Duration(days: i)));
    if (date.isAfter(AppDateUtils.startOfDay(now))) {
      out[date] = DayDotStatus.none; // future
      continue;
    }

    final medScheduled = meds.fold<int>(0, (sum, s) => sum + s.reminderTimesOnDate(date).length);
    final fluidScheduled = fluid?.reminderTimesOnDate(date).length ?? 0;
    final scheduledTotal = medScheduled + fluidScheduled;

    if (scheduledTotal == 0) {
      out[date] = date.isAtSameMomentAs(AppDateUtils.startOfDay(now)) ? DayDotStatus.today : DayDotStatus.none;
      continue;
    }

    final s = summaries[date];
    if (date.isAtSameMomentAs(AppDateUtils.startOfDay(now))) {
      // Today: gold until all complete
      final medOk = medScheduled == 0 || (s?.medicationTotalDoses ?? 0) == medScheduled;
      final fluidOk = fluidScheduled == 0 || (s?.fluidSessionCount ?? 0) == fluidScheduled;
      out[date] = (medOk && fluidOk) ? DayDotStatus.complete : DayDotStatus.today;
      continue;
    }

    // Past
    if (s == null) {
      out[date] = DayDotStatus.missed; // scheduled but no summary → missed
      continue;
    }
    final medOk = medScheduled == 0 || s.medicationTotalDoses == medScheduled;
    final fluidOk = fluidScheduled == 0 || s.fluidSessionCount == fluidScheduled;
    out[date] = (medOk && fluidOk) ? DayDotStatus.complete : DayDotStatus.missed;
  }
  return out;
});
```

Notes:
- All comparisons use `AppDateUtils.startOfDay` for timezone/DST safety.
- Dependencies: adding `ref.watch(dailyCacheProvider)` ensures today’s status flips to green as soon as logs update the cache + summary.

---

### Services – Session Reads (popup)

Create `SessionReadService` (read-only):
```dart
class SessionReadService {
  const SessionReadService(this._firestore);
  final FirebaseFirestore _firestore;

  Future<List<MedicationSession>> getMedicationSessionsForDate({
    required String userId,
    required String petId,
    required DateTime date,
    int limit = 50,
  });

  Future<List<FluidSession>> getFluidSessionsForDate({
    required String userId,
    required String petId,
    required DateTime date,
    int limit = 50,
  });
}
```

Query pattern (cost-optimized):
- Path within `users/{userId}/pets/{petId}/medicationSessions` and `/fluidSessions`
- `where('dateTime', isGreaterThanOrEqualTo: startOfDay)` and `where('dateTime', isLessThan: endOfDay)`
- `orderBy('dateTime', descending: true).limit(50)`
- Relies on Firestore offline persistence → 0 network reads when cached.

Provider:
```dart
final sessionReadServiceProvider = Provider<SessionReadService>((ref) {
  return SessionReadService(FirebaseFirestore.instance);
});
```

---

### Integration – ProgressScreen

File: `lib/features/progress/screens/progress_screen.dart`
- Replace the current placeholder body when onboarding is completed with a `Column` containing:
  1) `ProgressWeekCalendar` (top)
  2) Placeholder/empty area for future analytics cards

Navigation/Popup:
- `onDaySelected` resolves `DayDotStatus` for that day and opens `ProgressDayDetailPopup(date)`.
- The popup queries via `SessionReadService` and composes schedule-derived counts for planned view.

---

### Dependency Update

Add to `pubspec.yaml`:
```yaml
dependencies:
  table_calendar: ^3.2.0
```
Initialize locales only if we later add `locale` customization (not required now). See docs: [table_calendar](https://pub.dev/packages/table_calendar).

---

### Cost & Performance

- Week render: up to 7 reads (daily summaries) on the first display or week change; subsequent renders hit SummaryService’s in-memory TTL (5 min) → 0 reads.
- Day detail popup: up to 2 reads (med + fluid sessions), both range queries, limited and cached.
- No real-time listeners; all reads are on demand and leverage Firestore cache.
- Today’s status flips green without extra reads via cache dependency.

---

### Accessibility
- Marker `Semantics` labels: “Completed day”, “Missed day”, “Today”, “No status”.
- Popup uses `Semantics(liveRegion: true)` to announce “Medication X of N, Fluid Y of Z for {date}”.
- Touch targets ≥ 48px; row height ~64–72.

---

### Edge Cases & Rules
- No schedules at all in week → only today shows gold; others show no dot.
- Mixed persona users (med + fluid): logic already accounts for type not scheduled.
- DST/timezone: normalize comparisons via `AppDateUtils.startOfDay` and `startOfWeekMonday`.
- Offline: calendar and popup render from cache when possible; summaries and sessions fetch from local cache first.
- Multi-device: startup cache warm + summary TTL reduce flicker.

---

### Testing Plan

1) Unit tests – status calculator
   - Inputs: synthetic schedules + synthetic summaries per day
   - Cases: future days, zero-schedule day, full complete, partial complete, today flipping gold→green by injecting cache change

2) Widget tests – calendar markers
   - Render `ProgressWeekCalendar` with a mocked provider map of statuses
   - Verify marker colors, semantics, and no-dot behavior for future days

3) Integration tests – popup reads
   - Use `fake_cloud_firestore` to seed sessions and verify range queries return expected lists and summary counts

---

### Phased Implementation Steps

Phase 1 – Foundations
1. Add dependency
   a) Open `pubspec.yaml` and add `table_calendar: ^3.2.0` under `dependencies`.
   b) Run `flutter pub get` and ensure it resolves without conflicts.
   c) Build once (`flutter analyze`) to confirm no breakages.

2. Add minimal model & helpers
   a) Create `lib/features/progress/models/day_dot_status.dart` with `enum DayDotStatus { none, today, complete, missed }`.
   b) In `lib/core/utils/date_utils.dart`, add `startOfWeekMonday(DateTime)` if missing (normalize to Monday 00:00).
   c) Add `isSameDay(DateTime a, DateTime b)` helper if not already present (thin wrapper around `table_calendar`’s util or our own).

3. Pure weekly calculator
   a) Create `lib/features/progress/services/week_status_calculator.dart` with a pure function:
      `Map<DateTime, DayDotStatus> computeWeekStatuses({required DateTime weekStart, required List<Schedule> medicationSchedules, required Schedule? fluidSchedule, required Map<DateTime, DailySummary?> summaries, required DateTime now});`
   b) Implement logic exactly as specified in “Status Computation Logic” (future→none, zero-schedule→today/none, today gold→green, past complete/missed using session counts).

4. Providers (skeleton)
   a) `focusedDayProvider = StateProvider<DateTime>((_) => DateTime.now());`
   b) `focusedWeekStartProvider` derives Monday from `focusedDayProvider`.
   c) `weekSummariesProvider(weekStart)` fetches 7 `DailySummary?` in `Future.wait` using `SummaryService`.
   d) `weekStatusProvider(weekStart)` combines schedules + summaries via `computeWeekStatuses`; add `ref.watch(dailyCacheProvider)` to recompute today on cache updates.

5. Unit tests (fast)
   a) Create `test/features/progress/week_status_calculator_test.dart`.
   b) Add 3–4 tests: future days → none, zero-schedule past → none, past complete vs missed, today gold then green (simulate by providing a `DailySummary` with matching counts).

Phase 2 – Calendar UI
6. Calendar widget
   a) Create `lib/features/progress/widgets/progress_week_calendar.dart` (ConsumerWidget).
   b) Accept callbacks: `onDaySelected(DateTime day)`, and read `focusedWeekStartProvider`.
   c) Render `TableCalendar` with:
      - `calendarFormat: CalendarFormat.week`
      - `startingDayOfWeek: StartingDayOfWeek.monday`
      - Minimal header (title + chevrons, no format button)
      - Row height ~64–72; `outsideDaysVisible: false`
   d) `onPageChanged` → update `focusedDayProvider` with the incoming month/week’s focused day; compute week start.
   e) `selectedDayPredicate` uses `isSameDay` against a `selectedDay` held in an internal `StateProvider` or parent.

7. Marker renderer with semantics
   a) Inside `calendarBuilders.markerBuilder`, read `weekStatusProvider(weekStart)`.
   b) For the given `day`, pick status and return a single circular dot (`8.0` size) or `SizedBox.shrink()` for `none`.
   c) Colors
   d) Wrap with `Semantics(label: 'Completed day' | 'Missed day' | 'Today' | 'No status')`.

8. Wire into screen
   a) Update `lib/features/progress/screens/progress_screen.dart` body (in the `hasCompletedOnboarding` branch) to render `ProgressWeekCalendar` at the top.
   b) Keep a placeholder `SliverList` / `Column` below for future analytics cards.
   c) Pass `onDaySelected` that calls a function `showProgressDayDetailPopup(context, day)`.

9. Widget sanity test
   a) Add a widget test ensuring the calendar renders and markerBuilder is called for 7 days.

Phase 3 – Day Detail Popup
10. Read-only session service
    a) Create `lib/features/logging/services/session_read_service.dart` with read-only methods:
       - `getMedicationSessionsForDate(userId, petId, date, {limit=50})`
       - `getFluidSessionsForDate(userId, petId, date, {limit=50})`
    b) Queries: date range `[startOfDay, endOfDay)`, `orderBy('dateTime', descending: true)`, `limit(50)`.
    c) Provider: `sessionReadServiceProvider`.

11. Popup widget
    a) Create `lib/features/progress/widgets/progress_day_detail_popup.dart`.
    b) Props: `date`.
    c) Internal: read `currentUserProvider`, `primaryPetProvider`, schedules, and call `SessionReadService` methods.
    d) Decide mode:
       - If `date > today` → planned view: list each schedule’s `reminderTimesOnDate(date)` with simple tiles (name/time/dose or fluid volume).
       - Else → logged view: group by treatment type; show list of sessions with time and brief details.
    e) Summary pills at top: “Medication: M of N doses”, “Fluid: X of Y sessions” using schedule counts + `DailySummary?` if available.
    f) Use `OverlayService.showFullScreenPopup` with `slideUp` animation and close button.
    g) Accessibility: `Semantics(liveRegion: true)` announces day summary on open.

12. Show/hide API
    a) Create `showProgressDayDetailPopup(BuildContext context, DateTime date)` helper that inserts the overlay with the widget and returns a `Future<void>`.
    b) In `ProgressWeekCalendar.onDaySelected`, call this helper.

13. Basic UI tests
    a) Add a widget test for the popup: with seeded fake sessions, verify tiles render and the summary text is correct.

Phase 4 – Polish & QA
14. Theming & constants
    a) If not already present, add success/danger/warning color getters in theme (or central constants). Otherwise, keep direct `Colors.*`.
    b) Ensure `ui_guidelines.md` spacing, typography and touch targets.

15. Linting & accessibility pass
    a) `flutter analyze` and fix any lints.
    b) Verify `Semantics` labels on markers and popup summary.

16. Unit + widget tests (finalize)
    a) Extend calculator tests for edge cases (mixed schedules, no summaries but scheduled → missed).
    b) Extend calendar widget tests to verify dot presence/absence for each status.

17. Manual QA checklist
    a) Swipe weeks left/right; verify up to 7 reads once per new week, then cached.
    b) Log treatments; confirm today flips gold → green without restart.
    c) Offline mode: open calendar and popup with cached data; no crashes.
    d) Future days: no dots; tapping shows planned schedules.
    e) Days with zero schedules: no dot; tapping shows an empty/planned state.
    f) Accessibility: talkback/VoiceOver announces markers and popup summary.


---

### Future Enhancements (deferred)
- Volume-based fluid adherence (compare actual vs scheduled volume).
- Month view with week paging history.
- Tap markers to filter by treatment type within popup.
- Export day as PDF (later, aligns with Insights/PDF exports).

---

### Acceptance Criteria
- Weekly calendar renders under `AppBar` with Monday→Sunday row.
- For each visible day, exactly one of: green/red/gold/no-dot per rules above.
- Tapping a day opens a blurred popup showing logged sessions (past/today) or planned schedules (future).
- Today shows gold until all scheduled items are completed, then flips to green without app restart.
- Reads are capped (≤7 per week render, ≤2 per popup), offline-friendly, no listeners.


