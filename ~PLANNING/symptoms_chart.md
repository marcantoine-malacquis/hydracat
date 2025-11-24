## Symptoms Chart – Implementation Plan

---

## 0. Goals, Scope & Constraints

- **Goal**: Add a **stacked vertical bar chart** to the `SymptomsScreen` to visualize, for each period:
  - The **number of days where each symptom score > 0**, with:
    - **Week view**: 1 bar per **day** (Mon–Sun)
    - **Month view**: 1 bar per **week** in that month
    - **Year view**: 1 bar per **month** in that year
  - Primary mode: **stacked bars for all symptoms** (top 4–5 visible, others grouped into “Other”).
  - Advanced mode: **single-symptom view** via a dropdown (`All`, then each symptom).
- **Metric**: For each symptom, per bucket (day/week/month) we use:
  - `count = number of days in that bucket where symptom score > 0`
  - Already supported by `DailySummary` + aggregated in `WeeklySummary` / `MonthlySummary`.
- **UX alignment**:
  - **Granularity selector** (Week/Month/Year) and **period header with chevrons** should feel like the weight screen.
  - Tooltips should reuse the **style and motion** of `FluidVolumeBarChart`’s tooltip, adapted for symptom counts.
  - Colors must follow `ui_guidelines` and the water/pastel theme.
- **Firestore & CRUD rules**:
  - Use **summary documents first** (daily/weekly/monthly) and TTL-cached reads in `SummaryService`.
  - Avoid full-history scans; keep reads bounded (≤31 daily summaries, ≤8 weekly summaries, ≤12 monthly summaries).
  - No real-time listeners for historical analytics views.

---

## 1. Data & Color Foundations

### 1.1 Define symptom palette (`SymptomColors`)

**Objective**: Centralize a pastel color palette for symptoms, reusing injection-sites colors and a neutral “Other”.

1. Add a new helper in `lib/core/constants/` (e.g. `symptom_colors.dart`):
   - Map each `SymptomType` key to a **fixed pastel color**, reusing:
     - `0xFF9DCBBF` (pastel teal – already used)
     - `0xFFC4B5FD` (pastel lavender)
     - `0xFFF0C980` (pastel amber)
     - `0xFFEDA08F` (pastel coral)
   - Add one additional soft hue (e.g. light aqua/blue derived from the primary palette) for the 5th visible symptom.
   - Define a dedicated color for **“Other”** as a soft neutral:
     - e.g. `AppColors.textTertiary.withOpacity(~0.35)` for the segment
     - slightly stronger outline for legend.
2. Expose two APIs:
   - `Color colorForSymptom(String symptomKey)`
   - `Color colorForOther()`
3. Update `ui_guidelines.md` “Charts & Graphs” section to reference the symptom palette for category charts.

### 1.2 Symptom ordering & “top 5 + Other” rules

**Objective**: Have a deterministic, future-proof way to decide which symptoms are shown as individual segments.

1. Define a **static priority list** of symptoms (in `SymptomType` or a small helper):
   - Example (can be tweaked): vomiting, diarrhea, lethargy, suppressed appetite, constipation, injection-site reaction.
2. For each chart bucket:
   - Compute a **global ranking over the visible range** (not per-bar) based on total counts:
     - Sum `count[period][symptom]` over all visible periods.
     - Sort by descending total, breaking ties by static priority.
   - Select **up to 5** symptoms to show as distinct segments (usually all 6 for now).
   - All remaining symptoms are summed into an **“Other”** slot.
3. Persist the **sorted visible list** and the “Other” index in the chart’s view-model so bar construction and legend stay in sync.

### 1.3 Bucket model for the chart

**Objective**: Provide a generic data structure that all granularities can share.

1. Add a small model class, e.g. `SymptomBucket` in `lib/features/health/models/`:
   - Fields:
     - `DateTime start;`
     - `DateTime end;`
     - `Map<String, int> daysWithSymptom; // symptomKey -> count`
     - `int daysWithAnySymptoms;`
   - Computed:
     - `int totalSymptomDays => daysWithSymptom.values.fold(0, (a, b) => a + b);`
2. For **week view**:
   - Each bucket is a **single day**, so `start == end`.
3. For **month view**:
   - Each bucket represents a **week segment** in the displayed month (see 2.3).
4. For **year view**:
   - Each bucket represents a **calendar month** (start = first day, end = last day).

---

## 2. Data Providers & Aggregation Logic

### 2.1 New enum for symptoms granularity

**Objective**: Mirror `WeightGranularity` but scoped to symptoms.

1. Create `SymptomGranularity` in `lib/features/health/models/symptom_granularity.dart`:
   - Cases: `week`, `month`, `year`.
   - `String get label` returning `"Week"`, `"Month"`, `"Year"` (used by UI).
2. This keeps granularity type-safe and decoupled from the weight domain.

### 2.2 Base symptoms chart state (period + granularity + selection)

**Objective**: Centralize state so multiple widgets (header, segmented control, dropdown, chart) stay in sync.

1. Add a Riverpod `StateNotifier` + provider, e.g. `symptomsChartStateProvider` in `lib/providers/`:
   - State fields:
     - `DateTime focusedDate;  // reference day inside the visible period`
     - `SymptomGranularity granularity;`
     - `String? selectedSymptomKey; // null => "All"`
   - Derived:
     - For `week`: `weekStart = AppDateUtils.startOfWeekMonday(focusedDate)`
     - For `month`: `monthStart = DateTime(year, month, 1)`
     - For `year`: `yearStart = DateTime(year, 1, 1)`
2. Methods:
   - `setGranularity(SymptomGranularity g)` – snaps `focusedDate` if needed.
   - `previousPeriod()` / `nextPeriod()` – shift by:
     - week: ±7 days
     - month: ±1 month
     - year: ±1 year
   - `goToToday()`
   - `setSelectedSymptom(String? key)`

### 2.3 Week view buckets (1 bar per day)

**Objective**: Build 7 daily buckets using existing weekly summaries infrastructure with **0 extra reads**.

1. Data source:
   - Reuse `weekSummariesProvider(weekStart)` which already fetches 7 `DailySummary?` docs via `SummaryService.getDailySummary`.
2. Add a provider, e.g. `weeklySymptomBucketsProvider(weekStart)`:
   - Watch `weekSummariesProvider(weekStart)` and map each `DateTime -> DailySummary?` to a `SymptomBucket`:
     - For each day:
       - For each `SymptomType`:
         - `daysWithSymptom[symptom] = daily.hadX ? 1 : 0`
       - `daysWithAnySymptoms = daily.hasSymptoms ? 1 : 0`
   - Ensure precise handling of `null` (no daily summary = all zeros).
3. Cost:
   - No additional reads beyond those already done for the calendar, per CRUD rules.

### 2.4 Month view buckets (1 bar per week of the month)

**Objective**: Build 4–5 weekly buckets for the visible month using **daily summaries**, respecting cost limits.

1. Data source:
   - Use `SummaryService.getDailySummary()` for each day in the month (max 31 docs, TTL-cached).
2. Add a new provider, e.g. `monthlySymptomBucketsProvider(monthStart)`:
   - Generate all dates from `monthStart` to `monthEnd` (inclusive).
   - For each date, call `getDailySummary` in `Future.wait` (bounded 31 reads, cached for 15 minutes).
   - Group days into **week segments within the month**:
     - Use `AppDateUtils.startOfWeekMonday(day)` as the week anchor.
     - Maintain a map `weekStart -> SymptomBucket` but only include **days whose month matches `monthStart.month`** to avoid mixing months.
   - For each day added to a bucket:
     - For each symptom, if `daily.hadX == true`, increment `daysWithSymptom[X]` by 1.
     - If `daily.hasSymptoms == true`, increment `daysWithAnySymptoms` by 1.
3. Ordering:
   - Sort buckets by `weekStart` ascending.
4. Cost:
   - Max 31 daily summaries per month, fully within CRUD rules and similar to the planned “recent 30-day trends” feature.

### 2.5 Year view buckets (1 bar per month)

**Objective**: Build up to 12 monthly buckets using **monthly summaries only**.

1. Data source:
   - Use `SummaryService.getMonthlySummary()` for months from `yearStart` to `yearStart + 11 months`, stopping at now or at the max premium/free range later.
2. Add provider `yearlySymptomBucketsProvider(yearStart)`:
   - For each month in range:
     - Fetch `MonthlySummary?`.
     - Create a `SymptomBucket` with:
       - `start = first day of month`, `end = last day of month`.
       - `daysWithSymptom[...] = summary.daysWithX` (0 if summary is null).
       - `daysWithAnySymptoms = summary.daysWithAnySymptoms` (0 if null).
3. Range limits:
   - For now: up to **12 months from yearStart**.
   - Later: enforce free vs premium gating if needed (e.g. only last 30–90 days visible for free).
4. Cost:
   - Up to 12 monthly summary reads per year view, TTL-cached for 15 minutes.

### 2.6 Aggregated chart data provider

**Objective**: Expose a single provider that the chart widget can depend on, abstracting away granularity & period.

1. Add `symptomsChartDataProvider` as a `Provider.autoDispose` that:
   - Reads `symptomsChartStateProvider` for `granularity` and `focusedDate`.
   - Switches:
     - `week` → `weeklySymptomBucketsProvider(weekStart)`
     - `month` → `monthlySymptomBucketsProvider(monthStart)`
     - `year` → `yearlySymptomBucketsProvider(yearStart)`
   - Computes:
     - `List<SymptomBucket> buckets`
     - Global ranking and visible symptoms (`visibleSymptoms`, `otherSymptomKey`).
2. This provider returns a small view-model struct, e.g. `SymptomsChartViewModel`:
   - `List<SymptomBucket> buckets;`
   - `List<String> visibleSymptoms; // ordered`
   - `bool hasOther;`

---

## 3. Chart Widget (fl_chart) – Stacked Bars & Tooltips

### 3.1 Widget structure & placement

**Objective**: Implement a reusable `SymptomsStackedBarChart` widget in the health feature.

1. Add a new widget file, e.g. `lib/features/health/widgets/symptoms_stacked_bar_chart.dart`.
2. Public API:
   - `class SymptomsStackedBarChart extends ConsumerWidget` with:
     - `final SymptomGranularity granularity;`
     - `final String? selectedSymptomKey; // null => All`
   - Internally reads `symptomsChartDataProvider`.

### 3.2 Mapping buckets to `BarChartGroupData`

**Objective**: Consistently turn `SymptomBucket`s into fl_chart bar groups for stacked/all vs single-symptom mode.

1. For **All mode** (`selectedSymptomKey == null`):
   - For each bucket index `i`:
     - Compute the **stack segments** (values normalized to chart Y scale):
       - For each `visibleSymptom` (up to 5):
         - `toY = daysWithSymptom[symptomKey].toDouble()`
       - Optionally an “Other” segment with:
         - `otherCount = bucket.totalSymptomDays - sum(visibleSymptoms counts)`
         - If `otherCount > 0`, add a final segment colored as “Other”.
     - Use **BarChartRodStackItem** segments inside one `BarChartRodData` per group.
2. For **single-symptom mode**:
   - Each bucket has a single rod with:
     - `toY = daysWithSymptom[selectedSymptomKey]` as double.
     - Color: `SymptomColors.colorForSymptom(selectedSymptomKey)`.
3. Y-axis:
   - `maxY` = max segment height across visible buckets + ~10–20% headroom.
   - Y-axis labels: small integers (0, 1, 2, …) with minimal reserved width to “not take too much place”.

### 3.3 Visual styling & alignment

**Objective**: Match the aesthetics and interaction quality of existing charts.

1. Layout:
   - Use a fixed height similar to `FluidVolumeBarChart` (~200px).
   - `alignment: BarChartAlignment.spaceAround` for even spacing.
   - Slightly rounded bar corners (e.g. radius 8–10) to stay soft and in line with water theme.
2. Colors:
   - Apply solid colors for stacked segments (no gradients) for clarity.
   - Optional subtle gradient for the **selected symptom** in single mode (similar to weight/fluid charts).
3. Grid & borders:
   - Show **light grid lines** on Y-axis only (using `AppColors.border` with low opacity).
   - No top/right borders; bottom + left only (mirroring `WeightLineChart`).
4. X-axis labels:
   - Week: show short day labels (`Mon`, `Tue`, …), mirroring `WeightLineChart` logic.
   - Month: show week numbers or start dates (`W1`, `W2`, etc., or `3–9`, `10–16`).
   - Year: show 3-letter months (`Jan`, `Feb`, …).

### 3.4 Tooltip design & behavior

**Objective**: Reuse the feel of `FluidVolumeBarChart` tooltips, adapted to textual breakdowns.

1. Interaction:
   - Use `BarTouchData` with `handleBuiltInTouches: false` and custom `touchCallback`, like `FluidVolumeBarChart`.
   - On tap:
     - Store `touchedBarGroupIndex` and `touchPosition` in state.
     - Trigger a small scale/opacity animation for the tooltip card.
2. Tooltip contents:
   - Line 1: **period label**:
     - Week view: `EEE dd MMM` for that day.
     - Month view: “Week of Nov 3–9”.
     - Year view: “Mar 2025”.
   - Line 2: **total symptom days in that bucket**, e.g. `Total symptom days: 7`.
   - Following lines: per-symptom breakdown:
     - Example: `Vomiting: 3 days`, `Diarrhea: 1 day`, `Lethargy: 2 days`, `Other: 1 day`.
   - In single-symptom mode:
     - Period label + e.g. `Vomiting: 3 days`.
3. Styling:
   - Card: white background, 8px radius, soft shadow (same as `_TooltipCard` in `FluidVolumeBarChart`).
   - Arrow: small triangle using `Icons.change_history`, pointing towards the bar, left/right based on bar index to avoid off-screen overflow.
   - Font: `AppTextStyles.body`/`caption` with `AppColors.textPrimary` and `textSecondary`.

### 3.5 Legend

**Objective**: Help users interpret colors without clutter.

1. Position a legend under the chart:
   - `Wrap` of chips, each showing:
     - Colored dot/square
     - Name: `Vomiting`, `Diarrhea`, etc., plus optional `(top)` note in debug mode only (not in UI).
2. “Other”:
   - Use the dedicated neutral color and label “Other”.
3. Responsiveness:
   - Ensure legend items wrap nicely on small screens, consistent with injection-sites donut legend.

---

## 4. Symptoms Screen Integration & Controls

### 4.1 Extend SymptomsScreen layout

**Objective**: Replace the pure empty state with chart + history while preserving FAB and initial message.

1. Update `SymptomsScreen` body:
   - Instead of always calling `_buildEmptyState()`, branch:
     - If **no symptom data at all** (e.g. `currentMonthSymptomsSummaryProvider` reports `daysWithAnySymptoms == 0` and week buckets all zero) → show the existing empty state plus a CTA to log symptoms.
     - Else:
       - Show:
         1. Period header (chevrons + “Today” button) reusing weight patterns.
         2. Week/Month/Year segmented control.
         3. Symptom dropdown (“All” + symptoms).
         4. The `SymptomsStackedBarChart`.
         5. (Optional later) A small textual summary below.
2. Maintain the existing FAB behavior (`HydraExtendedFab`) unchanged.

### 4.2 Granularity selector (reuse HydraSlidingSegmentedControl)

**Objective**: Match the weight screen’s segmented control for Week/Month/Year.

1. Add a `_buildGranularitySelector` method similar to `WeightScreen._buildGranularitySelector`, but using `SymptomGranularity` and `symptomsChartStateProvider`.
2. When the user taps a segment:
   - Call `symptomsChartStateNotifier.setGranularity(newGranularity)`.
   - Optionally reset `selectedSymptomKey` to `null` to avoid confusing state when switching scales.

### 4.3 Period header (chevrons + Today)

**Objective**: Provide consistent navigation between periods.

1. Add `_buildGraphHeader` to `SymptomsScreen`:
   - Left/right chevrons:
     - Call `previousPeriod()` / `nextPeriod()` on the symptoms chart notifier.
     - Disable right chevron when the period includes “today” (similar to weight screen’s `isOnCurrentPeriod`).
   - Period label:
     - Week: show `MMM d–d, yyyy` range.
     - Month: `MMMM yyyy`.
     - Year: `yyyy`.
   - “Today” button:
     - Visible only when not on the current period.
     - Calls `goToToday()`.
2. Provide mild haptic feedback (`HapticFeedback.selectionClick()`) on period changes, matching existing patterns.

### 4.4 Symptom selection dropdown (All vs single symptom)

**Objective**: Allow advanced users to focus on a single symptom.

1. Add a small dropdown next to the period label or under the segmented control:
   - Options:
     - `All` (maps to `selectedSymptomKey = null`)
     - Names for each `SymptomType` in the static priority order.
2. Hook it to `symptomsChartStateProvider`:
   - `onChanged` → `setSelectedSymptom(newKeyOrNull)`.
3. Chart behavior:
   - The chart widget reads `selectedSymptomKey`:
     - `null` → stacked mode.
     - non-null → single-symptom non-stacked mode.

---

## 5. Performance, Analytics & Testing

### 5.1 Firestore cost & performance review

**Objective**: Validate that all views stay within CRUD rules.

1. **Week view**:
   - Uses `weekSummariesProvider` → **7 daily summaries**, cached; no new reads for chart.
2. **Month view**:
   - At most 31 daily summaries via `SummaryService.getDailySummary`, TTL-cached.
   - Only fetched when user views that month; no background polling.
3. **Year view**:
   - At most 12 monthly summary docs via `getMonthlySummary`, TTL-cached.
4. All queries are **bounded** (no “fetch all history”) and reuse summary docs, aligning with `firebase_CRUDrules.md`.

### 5.2 Analytics hooks (optional V1)

**Objective**: Capture minimal usage signals for future UX tuning (optional, non-blocking).

1. Consider adding a **featureUsed** analytics event when:
   - User first opens the Symptoms chart.
   - User switches granularity (week/month/year).
   - User uses the single-symptom dropdown.
2. Events:
   - `featureName: 'symptoms_chart_viewed'`, with params like `granularity` and number of buckets.
   - `featureName: 'symptoms_chart_symptom_selected'` with `symptom_key`.
3. Keep payloads small and non-sensitive; use `AnalyticsService.trackFeatureUsed`.

### 5.3 Testing strategy

**Objective**: Ensure correctness of aggregations and resilience to edge cases.

1. **Unit tests**:
   - For bucket builders (`weeklySymptomBucketsProvider` logic as pure functions):
     - Given a map of `DateTime -> DailySummary`, assert correct per-day bucket counts.
   - For month and year aggregation helpers:
     - Verify correct handling of:
       - Weeks spanning months.
       - Months with 28/29/30/31 days.
       - Missing summaries (null).
   - For top-5 + Other logic:
     - Given synthetic counts, verify `visibleSymptoms` ordering and “Other” count.
2. **Widget tests**:
   - Snapshot tests for:
     - Week view with mixed symptoms.
     - Month view with several weeks.
     - Single-symptom mode.
   - Verify tooltip rendering for a tapped bar (at least basic presence & text).
3. **Manual testing (run by you)**:
   - Log multiple symptom days with varied combinations.
   - Check:
     - Week view: bars per day look intuitive.
     - Month view: weekly bars sum to expected counts.
     - Year view: monthly bars reflect `daysWithAnySymptoms`.
   - Verify FAB, navigation, and dropdown behavior.

---

## 6. Implementation Checklist (High-Level)

1. **Foundations**
   - [ ] Implement `SymptomGranularity` enum.
   - [ ] Implement `SymptomBucket` model.
   - [ ] Add `SymptomColors` helper + update `ui_guidelines`.
2. **Providers & Aggregation**
   - [ ] Implement `symptomsChartStateProvider` (focused date, granularity, selection).
   - [ ] Implement weekly, monthly, and yearly buckets providers.
   - [ ] Implement unified `symptomsChartDataProvider` with top-5 + Other logic.
3. **Chart Widget**
   - [ ] Create `SymptomsStackedBarChart` widget using `fl_chart`.
   - [ ] Implement stacked vs single-symptom rendering.
   - [ ] Implement tooltips and legend matching existing chart styling.
4. **Screen Integration**
   - [ ] Extend `SymptomsScreen` to show chart instead of only empty state when data exists.
   - [ ] Add Week/Month/Year segmented control wired to chart state.
   - [ ] Add period header with chevrons + Today button.
   - [ ] Add symptom selection dropdown and wire to chart.
5. **Performance & Testing**
   - [ ] Sanity-check Firestore read patterns in debug logs.
   - [ ] Add unit tests for aggregation/top-5 logic.
   - [ ] Add at least one widget test for chart rendering.
   - [ ] Run `flutter analyze` and `flutter test` before manual UX testing.

Once this plan is implemented, we’ll have a cohesive, low-cost symptom visualization that feels native to HydraCat’s existing analytics and UI patterns, and can be extended later with premium, long-range analytics without changing the underlying data model.


