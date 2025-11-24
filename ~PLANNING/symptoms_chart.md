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

### 1.1 Define symptom palette (`SymptomColors`) ✅ **COMPLETED**

**Objective**: Centralize a pastel color palette for symptoms, reusing injection-sites colors and a neutral “Other”.

**Implementation Status**: ✅ Completed

1. ✅ Added `lib/core/constants/symptom_colors.dart`:
   - ✅ Mapped each `SymptomType` key to a **fixed pastel color**:
     - `vomiting`: `0xFF9DCBBF` (pastel teal – `AppColors.primaryLight`)
     - `diarrhea`: `0xFFF0C980` (pastel amber – `AppColors.successLight`)
     - `lethargy`: `0xFFEDA08F` (pastel coral – `AppColors.warningLight`)
     - `suppressedAppetite`: `0xFFC4B5FD` (pastel lavender)
     - `constipation`: `0xFFA8D5E2` (soft aqua)
     - `injectionSiteReaction`: `0xFFF5C9A8` (soft peach)
   - ✅ Defined dedicated color for **"Other"** as `AppColors.textTertiary.withValues(alpha: 0.35)`
2. ✅ Exposed two APIs:
   - ✅ `Color colorForSymptom(String symptomKey)` – validates keys and returns mapped color or "Other"
   - ✅ `Color colorForOther()` – returns neutral color for grouped symptoms
3. ✅ Updated `ui_guidelines.md` "Charts & Graphs" section with symptom palette documentation
4. ✅ Updated `lib/core/theme/README.md` to reference `SymptomColors` in Core Files and Colors sections

### 1.2 Symptom ordering & "top 5 + Other" rules ✅ Completed

**Objective**: Have a deterministic, future-proof way to decide which symptoms are shown as individual segments.

**Priority Order** (from most important to least important):
1. lethargy
2. suppressed appetite
3. vomiting
4. injection-site reaction
5. constipation
6. diarrhea

**Implementation Notes**:
1. Define a **static priority list** of symptoms (in `SymptomType` or a small helper):
   - Use the priority order above: lethargy, suppressed appetite, vomiting, injection-site reaction, constipation, diarrhea.
2. For each chart bucket:
   - Compute a **global ranking over the visible range** (not per-bar) based on total counts:
     - Sum `count[period][symptom]` over all visible periods.
     - Sort by descending total, breaking ties by static priority.
   - Select **up to 5** symptoms to show as distinct segments (usually all 6 for now).
   - All remaining symptoms are summed into an **"Other"** slot.
3. Persist the **sorted visible list** and the "Other" index in the chart's view-model so bar construction and legend stay in sync.

**Status**: ⏸️ **Documentation only** - The actual ranking/selection logic will be implemented in section 2.6 (Aggregated chart data provider) when building the chart infrastructure.

### 1.3 Bucket model for the chart ✅ **COMPLETED**

**Objective**: Provide a generic data structure that all granularities can share.

**Implementation Status**: ✅ Completed

1. ✅ Added `SymptomBucket` model class in `lib/features/health/models/symptom_bucket.dart`:
   - ✅ Fields:
     - `DateTime start;` – inclusive start date of the bucket
     - `DateTime end;` – inclusive end date of the bucket
     - `Map<String, int> daysWithSymptom;` – symptom key → count of days where score > 0
     - `int daysWithAnySymptoms;` – count of days where any symptom was present
   - ✅ Computed getter:
     - `int get totalSymptomDays` – sum of all values in `daysWithSymptom`
   - ✅ Factory constructors:
     - `SymptomBucket.empty(DateTime date)` – creates empty single-day bucket
     - `SymptomBucket.forRange({required DateTime start, required DateTime end})` – creates empty multi-day bucket
   - ✅ Utility methods:
     - `copyWith()` – functional-style updates for bucket building
   - ✅ Immutability:
     - `@immutable` class with unmodifiable `daysWithSymptom` map
     - Proper `==`, `hashCode`, and `toString` overrides with value-based map comparison
2. ✅ Usage patterns documented:
   - **Week view**: Each bucket is a **single day**, so `start == end` (via `SymptomBucket.empty()`)
   - **Month view**: Each bucket represents a **week segment** in the displayed month (see 2.3), using `SymptomBucket.forRange()` for initialization
   - **Year view**: Each bucket represents a **calendar month** (start = first day, end = last day), populated from monthly summaries
3. ✅ Unit tests added in `test/features/health/models/symptom_bucket_test.dart`:
   - ✅ Constructor behavior and immutability validation
   - ✅ `totalSymptomDays` computation (empty, single, multiple symptoms)
   - ✅ Factory constructors with date normalization
   - ✅ `copyWith` functionality for all field combinations
   - ✅ Equality and hashCode (including map equality by value)
   - ✅ `toString` output verification

---

## 2. Data Providers & Aggregation Logic

### 2.1 New enum for symptoms granularity ✅ **COMPLETED**

**Objective**: Mirror `WeightGranularity` but scoped to symptoms.

**Implementation Status**: ✅ Completed

1. ✅ Created `SymptomGranularity` in `lib/features/health/models/symptom_granularity.dart`:
   - ✅ Cases: `week`, `month`, `year`.
   - ✅ `String get label` returning `"Week"`, `"Month"`, `"Year"` (used by UI).
   - ✅ Documentation explaining purpose and decoupling from weight domain.
   - ✅ Pattern matches `WeightGranularity` enum structure for consistency.
2. ✅ Unit tests added in `test/features/health/models/symptom_granularity_test.dart`:
   - ✅ Verification of all three enum values (`week`, `month`, `year`).
   - ✅ Tests for `label` getter returning correct strings for each case.
3. ✅ This keeps granularity type-safe and decoupled from the weight domain.

### 2.2 Base symptoms chart state (period + granularity + selection) ✅ **COMPLETED**

**Objective**: Centralize state so multiple widgets (header, segmented control, dropdown, chart) stay in sync.

**Implementation Status**: ✅ Completed

1. ✅ Added `SymptomsChartState` model and `SymptomsChartNotifier` in `lib/providers/symptoms_chart_provider.dart`:
   - ✅ State fields:
     - `DateTime focusedDate` – reference day inside the visible period (defaults to `DateTime.now()`)
     - `SymptomGranularity granularity` – current graph granularity (defaults to `SymptomGranularity.week`)
     - `String? selectedSymptomKey` – selected symptom key for single-symptom view (`null` => "All")
   - ✅ Derived getters:
     - `DateTime get weekStart` – uses `AppDateUtils.startOfWeekMonday(focusedDate)`
     - `DateTime get monthStart` – uses `DateTime(focusedDate.year, focusedDate.month)`
     - `DateTime get yearStart` – uses `DateTime(focusedDate.year)`
   - ✅ Helper booleans:
     - `bool get isOnCurrentWeek` – whether current week includes today
     - `bool get isOnCurrentMonth` – whether current month includes today
     - `bool get isOnCurrentYear` – whether current year includes today
     - `bool get isOnCurrentPeriod` – convenience getter that switches on granularity
   - ✅ Immutability:
     - `@immutable` class with `copyWith()` for functional updates
     - Proper `==`, `hashCode`, and `toString` overrides
2. ✅ Implemented `SymptomsChartNotifier` extending `StateNotifier<SymptomsChartState>`:
   - ✅ Constructor initializes with today's date, week granularity, and "All" symptoms
   - ✅ Public methods:
     - `setGranularity(SymptomGranularity g)` – normalizes `focusedDate` to period start and resets `selectedSymptomKey` to null
     - `previousPeriod()` – shifts by -1 period (week: -7 days, month: -1 month, year: -1 year)
     - `nextPeriod()` – shifts by +1 period with future clamping to prevent moving beyond today
     - `goToToday()` – sets `focusedDate` to today while preserving granularity and selection
     - `setSelectedSymptom(String? key)` – updates selected symptom key (null for "All")
   - ✅ Private helpers:
     - `_getPeriodAnchor()` – returns period start based on current granularity
     - `_normalizeFocusedDate()` – snaps date to period start for cleaner boundaries
     - `_shiftByGranularity()` – generic period shifting with month edge case handling
     - `_shiftMonth()` – handles day clamping when crossing month boundaries (e.g., Jan 31 → Feb 28/29)
     - `_clampToTodayIfFuture()` – prevents navigation to future periods
   - ✅ Debug logging for period changes and granularity switches
3. ✅ Exposed Riverpod provider:
   - ✅ `symptomsChartStateProvider` – `StateNotifierProvider.autoDispose` for automatic cleanup when Symptoms screen is not in use
   - ✅ Ready for consumption by UI widgets (header, segmented control, dropdown, chart) and aggregation providers (sections 2.3–2.6)

### 2.3 Week view buckets (1 bar per day) ✅ **COMPLETED**

**Objective**: Build 7 daily buckets using existing weekly summaries infrastructure with **0 extra reads**.

**Implementation Status**: ✅ Completed

1. ✅ Added pure function `buildWeeklySymptomBuckets` in `lib/providers/symptoms_chart_provider.dart`:
   - ✅ Takes `weekStart` (Monday at 00:00) and `Map<DateTime, DailySummary?>` from `weekSummariesProvider`
   - ✅ Iterates through 7 days (Mon-Sun) and builds one `SymptomBucket` per day
   - ✅ For each day:
     - ✅ Creates empty bucket using `SymptomBucket.empty(date)` if summary is null
     - ✅ If summary exists, maps all 6 symptom booleans (`hadVomiting`, `hadDiarrhea`, `hadConstipation`, `hadLethargy`, `hadSuppressedAppetite`, `hadInjectionSiteReaction`) to `daysWithSymptom` map with value `1` only when true (omits false symptoms to keep maps compact)
     - ✅ Sets `daysWithAnySymptoms` to `1` if `summary.hasSymptoms == true`, otherwise `0`
   - ✅ Returns fixed list of 7 buckets, ordered Monday → Sunday
   - ✅ Normalizes `weekStart` to start-of-day for safety
2. ✅ Added `weeklySymptomBucketsProvider` as `AutoDisposeProviderFamily<List<SymptomBucket>?, DateTime>`:
   - ✅ Watches `weekSummariesProvider(weekStart)` to consume existing cached data
   - ✅ Returns `null` while loading or on error, `List<SymptomBucket>` when data is available
   - ✅ Automatically recomputes when `weekSummariesProvider` changes (e.g., after logging new symptoms)
3. ✅ Cost validation:
   - ✅ **0 additional Firestore reads** - provider only consumes `weekSummariesProvider` which already adheres to CRUD rules and TTL caching
4. ✅ Unit tests added in `test/features/health/providers/weekly_symptom_buckets_provider_test.dart`:
   - ✅ Empty week (all null summaries) → 7 empty buckets
   - ✅ Single-day symptoms → correct bucket has symptom keys set to 1
   - ✅ Multiple symptoms on same day → bucket includes all present symptoms
   - ✅ Mixed week with different symptom combinations → correct ordering and per-day maps
   - ✅ Day with `hasSymptoms=false` → empty bucket
   - ✅ Correct ordering (Monday to Sunday) verification
   - ✅ Date normalization handling

### 2.4 Month view buckets (1 bar per week of the month) ✅ **COMPLETED**

**Objective**: Build 4–5 weekly buckets for the visible month using **daily summaries**, respecting cost limits.

**Implementation Status**: ✅ Completed

1. ✅ Added pure function `buildMonthlySymptomBuckets` in `lib/providers/symptoms_chart_provider.dart`:
   - ✅ Takes `monthStart` (first day of month at 00:00) and `Map<DateTime, DailySummary?>` for all days in the month
   - ✅ Normalizes `monthStart` to first day of month at start-of-day
   - ✅ Computes `monthEnd` using `AppDateUtils.endOfMonth()`
   - ✅ Iterates through all days in the month (up to 31 days)
   - ✅ For each day:
     - ✅ Only processes days where `currentDate.month == monthStart.month` to avoid mixing months
     - ✅ Computes `weekStart = AppDateUtils.startOfWeekMonday(currentDate)` as the week anchor
     - ✅ Maintains a `Map<DateTime, SymptomBucket>` keyed by `weekStart`
     - ✅ Creates new bucket using `SymptomBucket.forRange()` if week segment doesn't exist
     - ✅ Extends bucket's `end` date when adding further days to the same week segment
     - ✅ For each symptom boolean that is `true`, increments `daysWithSymptom[symptomKey]` by 1
     - ✅ If `daily.hasSymptoms == true`, increments `daysWithAnySymptoms` by 1
   - ✅ After processing all days, sorts buckets by `start` date ascending and returns as `List<SymptomBucket>`
   - ✅ Documentation explains why daily summaries are used (not weekly summaries) for correct "weeks of the month" visualization
2. ✅ Added `monthlySymptomBucketsProvider` as `AutoDisposeFutureProviderFamily<List<SymptomBucket>?, DateTime>`:
   - ✅ Normalizes `monthStart` to first day of month at start-of-day
   - ✅ Generates all dates from `monthStart` to `monthEnd` (inclusive)
   - ✅ Fetches daily summaries in parallel using `Future.wait` with `SummaryService.getDailySummary()`
   - ✅ Builds `Map<DateTime, DailySummary?>` from results
   - ✅ Delegates to `buildMonthlySymptomBuckets()` for aggregation
   - ✅ Returns `null` while loading or on error, `List<SymptomBucket>` (4-6 buckets) when data is available
   - ✅ Watches `dailyCacheProvider` for reactivity (automatically recomputes when today's cache updates)
   - ✅ Includes debug logging for fetch operations
3. ✅ Cost validation:
   - ✅ **At most 31 Firestore reads per month** (one per day), TTL-cached for 5 minutes
   - ✅ Fully within CRUD rules and similar to the planned "recent 30-day trends" feature
   - ✅ Only fetched when user views that month; no background polling
   - ✅ Documentation describes Firestore cost characteristics and alignment with `firebase_CRUDrules.md`
4. ✅ Unit tests added in `test/features/health/providers/monthly_symptom_buckets_provider_test.dart`:
   - ✅ Empty month (all null summaries) → 4-6 empty buckets (depending on how weeks fall)
   - ✅ Single-day symptoms → correct bucket has symptom keys with count 1
   - ✅ Multiple days in same week segment → bucket accumulates counts correctly
   - ✅ Weeks spanning two months → days from adjacent months are correctly excluded
   - ✅ Months with 28, 30, and 31 days → correct handling of different month lengths
   - ✅ Day with `hasSymptoms=false` → bucket correctly excludes that day from symptom counts
   - ✅ Correct ordering (buckets sorted by start date ascending)
   - ✅ Date normalization handling
   - ✅ Mixed month with various symptom combinations → correct aggregation across multiple buckets

### 2.5 Year view buckets (1 bar per month) ✅ **COMPLETED**

**Objective**: Build up to 12 monthly buckets using **monthly summaries only**.

**Implementation Status**: ✅ Completed

1. ✅ Added pure function `buildYearlySymptomBuckets` in `lib/providers/symptoms_chart_provider.dart`:
   - ✅ Takes `yearStart` (first day of year at 00:00) and `Map<DateTime, MonthlySummary?>` keyed by month start date
   - ✅ Iterates through months from `yearStart` to `yearStart + 11 months`, stopping at current month if in the future
   - ✅ For each month:
     - ✅ Computes `monthStart = DateTime(year, month, 1)` and `monthEnd = AppDateUtils.endOfMonth(monthStart)`
     - ✅ Gets `MonthlySummary?` from the map
     - ✅ If summary is null, creates empty bucket using `SymptomBucket.forRange(start: monthStart, end: monthEnd)`
     - ✅ If summary exists, creates bucket with:
       - ✅ `start = summary.startDate`, `end = summary.endDate`
       - ✅ `daysWithSymptom` map populated from summary fields:
         - ✅ `SymptomType.vomiting` → `summary.daysWithVomiting`
         - ✅ `SymptomType.diarrhea` → `summary.daysWithDiarrhea`
         - ✅ `SymptomType.constipation` → `summary.daysWithConstipation`
         - ✅ `SymptomType.lethargy` → `summary.daysWithLethargy`
         - ✅ `SymptomType.suppressedAppetite` → `summary.daysWithSuppressedAppetite`
         - ✅ `SymptomType.injectionSiteReaction` → `summary.daysWithInjectionSiteReaction`
       - ✅ Only includes symptom keys with count > 0 in the map (keeps it compact)
       - ✅ `daysWithAnySymptoms = summary.daysWithAnySymptoms`
   - ✅ Returns sorted list of buckets (by `start` date ascending)
   - ✅ Documentation explains purpose, parameters, return value, and usage example
2. ✅ Added `yearlySymptomBucketsProvider` as `AutoDisposeFutureProviderFamily<List<SymptomBucket>?, DateTime>`:
   - ✅ Normalizes `yearStart` to `DateTime(yearStart.year, 1, 1)` at start-of-day
   - ✅ Gets `user` and `pet` from `currentUserProvider` and `primaryPetProvider` (returns `null` if either is null)
   - ✅ Generates list of month dates (up to 12 months, stopping at current month if future):
     - ✅ Iterates from month 1 to 12, computing `monthDate = DateTime(year, month, 1)`
     - ✅ Stops if `monthDate` is after current month
   - ✅ Fetches monthly summaries in parallel using `Future.wait` with `SummaryService.getMonthlySummary()`
   - ✅ Builds `Map<DateTime, MonthlySummary?>` from results
   - ✅ Delegates to `buildYearlySymptomBuckets()` for aggregation
   - ✅ Returns `null` while loading or on error, `List<SymptomBucket>` (up to 12 buckets) when data is available
   - ✅ Watches `dailyCacheProvider` for reactivity (automatically recomputes when today's cache updates)
   - ✅ Includes debug logging for fetch operations and summary counts
3. ✅ Range limits:
   - ✅ For now: up to **12 months from yearStart**, stopping at current month if future
   - ✅ Later: enforce free vs premium gating if needed (e.g. only last 30–90 days visible for free)
4. ✅ Cost validation:
   - ✅ **Up to 12 Firestore reads per year view**, TTL-cached for 15 minutes (handled by `SummaryService`)
   - ✅ Fully within CRUD rules and similar to the planned "recent 30-day trends" feature
   - ✅ Only fetched when user views that year; no background polling
   - ✅ Documentation describes Firestore cost characteristics and alignment with `firebase_CRUDrules.md`
5. ✅ Unit tests added in `test/features/health/providers/yearly_symptom_buckets_provider_test.dart`:
   - ✅ Empty year (all null summaries) → 12 empty buckets (or fewer if stopping at current month)
   - ✅ Single-month symptoms → correct bucket has symptom keys with counts
   - ✅ Multiple months with various symptom combinations → correct aggregation across months
   - ✅ Partial year (year that includes future months) → stops at current month, doesn't create future buckets
   - ✅ Missing summaries (some months null, some with data) → correct handling of nulls
   - ✅ Date normalization → verify correct month start/end dates
   - ✅ Correct ordering → buckets sorted by start date ascending
   - ✅ Using summary dates → bucket uses summary's `startDate` and `endDate`
   - ✅ Only including symptoms with count > 0 → map is compact
   - ✅ Leap year February → correct handling of leap year edge case
   - ✅ All 6 symptom types → comprehensive symptom coverage

### 2.6 Aggregated chart data provider ✅ **COMPLETED**

**Objective**: Expose a single provider that the chart widget can depend on, abstracting away granularity & period.

**Implementation Status**: ✅ Completed

1. ✅ Added `SymptomsChartViewModel` class in `lib/providers/symptoms_chart_provider.dart`:
   - ✅ Immutable view-model struct with:
     - ✅ `List<SymptomBucket> buckets` - list of symptom buckets for the current period
     - ✅ `List<String> visibleSymptoms` - ordered list of top symptom keys (up to 5) to render as individual stacked segments
     - ✅ `bool hasOther` - whether an "Other" segment is needed for symptoms not in `visibleSymptoms`
   - ✅ Includes proper equality, hashCode, and toString implementations
   - ✅ Documentation explains how chart widget should consume the view-model
2. ✅ Implemented symptom ranking helpers:
   - ✅ Static priority order constant `_symptomPriorityOrder` with order: lethargy, suppressedAppetite, vomiting, injectionSiteReaction, constipation, diarrhea
   - ✅ Private function `_buildVisibleSymptoms()` that:
     - ✅ Aggregates symptom counts across all buckets
     - ✅ Sorts by total count (descending) with static priority as tie-breaker
     - ✅ Returns top 5 symptoms (or fewer if fewer exist)
   - ✅ Private function `_hasOtherSymptoms()` that determines if symptoms not in `visibleSymptoms` have non-zero counts
3. ✅ Added `symptomsChartDataProvider` as `Provider.autoDispose<SymptomsChartViewModel?>`:
   - ✅ Reads `symptomsChartStateProvider` for `granularity` and period anchors (`weekStart`, `monthStart`, `yearStart`)
   - ✅ Switches based on granularity:
     - ✅ `week` → watches `weeklySymptomBucketsProvider(weekStart)` (returns `List<SymptomBucket>?` directly)
     - ✅ `month` → watches `monthlySymptomBucketsProvider(monthStart)` (returns `AsyncValue`, extracts via `valueOrNull`)
     - ✅ `year` → watches `yearlySymptomBucketsProvider(yearStart)` (returns `AsyncValue`, extracts via `valueOrNull`)
   - ✅ Returns `null` while data is loading or if an error occurs
   - ✅ When buckets are available:
     - ✅ Computes `visibleSymptoms` using `_buildVisibleSymptoms()`
     - ✅ Computes `hasOther` using `_hasOtherSymptoms()`
     - ✅ Returns `SymptomsChartViewModel` with buckets, visibleSymptoms, and hasOther
   - ✅ Includes debug logging for granularity, bucket count, visible symptoms, and hasOther flag
   - ✅ Fully documented with usage examples
4. ✅ Unit tests added in `test/features/health/providers/symptoms_chart_data_provider_test.dart`:
   - ✅ Week granularity tests:
     - ✅ Returns null when buckets are null (loading state)
     - ✅ Returns view model with empty buckets
     - ✅ Computes visible symptoms from buckets correctly
   - ✅ Month granularity tests:
     - ✅ Returns null when buckets are null (loading state)
     - ✅ Returns view model with monthly buckets
   - ✅ Year granularity tests:
     - ✅ Returns null when buckets are null (loading state)
     - ✅ Returns view model with yearly buckets
   - ✅ Top-5 + Other logic tests:
     - ✅ Selects top 5 symptoms by count when more than 5 exist
     - ✅ Uses static priority as tie-breaker when counts are equal
     - ✅ Sets hasOther to false when all symptoms are visible
     - ✅ Sets hasOther to true when symptoms are not in visible list
   - ✅ SymptomsChartViewModel tests:
     - ✅ Correct equality and hashCode implementation
     - ✅ Different equality for different visible symptoms
   - ✅ All 13 tests passing

---

## 3. Chart Widget (fl_chart) – Stacked Bars & Tooltips

### 3.1 Widget structure & placement ✅ **COMPLETED**

**Objective**: Implement a reusable `SymptomsStackedBarChart` widget in the health feature.

**Implementation Status**: ✅ Completed

1. ✅ Added `lib/features/health/widgets/symptoms_stacked_bar_chart.dart`:
   - ✅ Created `SymptomsStackedBarChart` as a `ConsumerWidget`
   - ✅ Public API with `granularity` and `selectedSymptomKey` props
   - ✅ Internally watches `symptomsChartDataProvider` and `symptomsChartStateProvider`
2. ✅ State handling:
   - ✅ Loading state: shows centered spinner with fixed height (200px) matching `FluidVolumeBarChart`
   - ✅ Empty state: displays "No symptom data for this period" message when buckets are empty or all zero
   - ✅ Non-empty state: renders full BarChart widget with stacked/single-symptom modes (implemented in section 3.2)
3. ✅ Internal structure:
   - ✅ Private helper `_buildChartBody()` for main chart area (now fully implemented in section 3.2)
   - ✅ Private helper `_buildLegendPlaceholder()` for legend area (ready for section 3.5)
   - ✅ Column layout with Expanded chart area and legend placeholder below
4. ✅ Styling alignment:
   - ✅ Fixed height of 200px matching `FluidVolumeBarChart`
   - ✅ Top padding of 12px consistent with existing charts
   - ✅ Uses `AppTextStyles` and `AppColors` for consistent typography and colors
   - ✅ Chart body now renders full BarChart widget (section 3.2 complete)
5. ✅ Documentation:
   - ✅ Comprehensive class documentation explaining widget purpose and usage
   - ✅ Example code showing how to construct from chart state
   - ✅ References to providers and state structure

### 3.2 Mapping buckets to `BarChartGroupData` ✅ **COMPLETED**

**Objective**: Consistently turn `SymptomBucket`s into fl_chart bar groups for stacked/all vs single-symptom mode.

**Implementation Status**: ✅ Completed

1. ✅ **All mode** (`selectedSymptomKey == null`):
   - ✅ Implemented `_buildStackedBarGroup()` method that:
     - Iterates through `viewModel.buckets` with index `i`
     - For each bucket, builds stacked segments:
       - Loops through `viewModel.visibleSymptoms` (top 5) in order
       - For each visible symptom with count > 0, creates `BarChartRodStackItem(fromY, toY, color)` with accumulating `runningTotal`
       - Computes "Other" count as `bucket.totalSymptomDays - sum(visibleSymptoms counts)`
       - Adds "Other" segment when `otherCount > 0` using `SymptomColors.colorForOther()`
     - Creates single `BarChartRodData` per group with `rodStackItems` containing all segments
     - Handles empty buckets with transparent placeholder
2. ✅ **Single-symptom mode**:
   - ✅ Implemented `_buildSingleSymptomBarGroup()` method that:
     - Creates a single `BarChartRodData` per bucket with:
       - `toY = daysWithSymptom[selectedSymptomKey] ?? 0` converted to double
       - `color: SymptomColors.colorForSymptom(selectedSymptomKey)`
       - Consistent width (40px) and border radius (8px)
3. ✅ **Y-axis configuration**:
   - ✅ Implemented `_computeMaxY()` method that:
     - For stacked mode: finds max `bucket.totalSymptomDays` across all buckets
     - For single-symptom mode: finds max count for selected symptom across buckets
     - Adds 15% headroom: `maxY * 1.15`
     - Ensures minimum of 1.0 for empty data
   - ✅ Implemented `_computeYAxisInterval()` for nice intervals (1, 2, 5, 10, etc.)
   - ✅ Configured `leftTitles` to show integer labels only (0, 1, 2, …) with reserved size 30px
4. ✅ **Bar group building**:
   - ✅ Implemented `_buildBarGroups()` that switches between stacked and single-symptom modes
   - ✅ All helper methods properly handle edge cases (empty buckets, zero counts)

### 3.3 Visual styling & alignment ✅ **PARTIALLY COMPLETED**

**Objective**: Match the aesthetics and interaction quality of existing charts.

**Implementation Status**: ✅ Partially completed (basic styling done, gradients deferred)

1. ✅ **Layout**:
   - ✅ Fixed height of 200px matching `FluidVolumeBarChart`
   - ✅ `alignment: BarChartAlignment.spaceAround` for even spacing
   - ✅ Rounded bar corners with radius 8px (via `BorderRadius.circular(8)`)
   - ✅ Bar width: 40px for consistent appearance
2. ✅ **Colors**:
   - ✅ Applied solid colors for stacked segments using `SymptomColors.colorForSymptom()`
   - ✅ No gradients (keeps clarity for stacked view)
   - ⏸️ Subtle gradient for selected symptom in single mode deferred (can be added later if desired)
3. ✅ **Grid & borders**:
   - ✅ Light horizontal grid lines only using `AppColors.border.withValues(alpha: 0.3)`
   - ✅ Borders: bottom + left only (no top/right), matching `WeightLineChart` pattern
   - ✅ Grid intervals computed via `_computeYAxisInterval()` for clean spacing
4. ✅ **X-axis labels**:
   - ✅ Implemented `_formatXAxisLabel()` method that formats based on granularity:
     - Week: Short day abbreviations using `DateFormat('EEE')` (Mon, Tue, …)
     - Month: Week ranges showing start-end day (e.g., "3-9", "10-16")
     - Year: 3-letter month abbreviations using `DateFormat('MMM')` (Jan, Feb, …)
   - ✅ Labels styled with `AppTextStyles.caption` and `AppColors.textSecondary`
   - ✅ Reserved size 30px for bottom titles

### 3.4 Tooltip design & behavior ✅ **COMPLETED**

**Objective**: Reuse the feel of `FluidVolumeBarChart` tooltips, adapted to textual breakdowns.

**Implementation Status**: ✅ Completed

1. ✅ **Interaction**:
   - ✅ Converted widget to `ConsumerStatefulWidget` with local touch state (`_touchedBarGroupIndex`, `_touchPosition`).
   - ✅ Implemented `_buildTouchData()` with `BarTouchData` using `handleBuiltInTouches: false` and custom `touchCallback`, matching `FluidVolumeBarChart` pattern.
   - ✅ On tap: stores `touchedBarGroupIndex` and `touchPosition` in state with haptic feedback (`HapticFeedback.selectionClick()`).
   - ✅ On tap up/cancel: clears touch state.
   - ✅ Triggered scale/opacity animation via `TweenAnimationBuilder` (0.9 → 1.0 scale, 160ms duration, `Curves.easeOutCubic`).
2. ✅ **Tooltip contents**:
   - ✅ Line 1: **period label** formatted via `_formatTooltipPeriodLabel()`:
     - ✅ Week view: `EEE dd MMM` format (e.g., "Mon 15 Jan").
     - ✅ Month view: "Week of Nov 3–9" format with start/end days.
     - ✅ Year view: `MMM yyyy` format (e.g., "Mar 2025").
   - ✅ Line 2: **total symptom days** display: `Total symptom days: X`.
   - ✅ Following lines: per-symptom breakdown via `_buildSymptomTooltipRows()`:
     - ✅ Stacked mode: shows visible symptoms (top 5) + "Other" if applicable, each with colored dot indicator and count (e.g., "Vomiting: 3 days").
     - ✅ Single-symptom mode: shows only selected symptom with period label and count.
3. ✅ **Styling**:
   - ✅ Card: white background, 8px radius, soft shadow matching `_TooltipCard` in `FluidVolumeBarChart`.
   - ✅ Arrow: small triangle using `Icons.change_history`, rotated ±90 degrees, positioned left/right based on bar index (left half → tooltip on right, right half → tooltip on left).
   - ✅ Font: `AppTextStyles.body` (bold, 13px) for period label, `AppTextStyles.caption` (11px) for total days and symptom rows, using `AppColors.textPrimary` and `textSecondary`.
4. ✅ **Positioning and overlay**:
   - ✅ Wrapped chart in `Stack` with tooltip overlay layer.
   - ✅ Smart positioning: tooltip appears on right for left half of bars, left for right half to avoid off-screen overflow.
   - ✅ Positioned relative to touch point (`_touchPosition.dx + 8` or `screenWidth - _touchPosition.dx + 8`).
   - ✅ Vertical offset: `_touchPosition.dy - 40` to position above touch point.
5. ✅ **Edge cases and accessibility**:
   - ✅ Guards against stale indices (checks `_touchedBarGroupIndex < viewModel.buckets.length`).
   - ✅ Empty/zero buckets: no tooltip shown when `totalSymptomDays == 0` or selected symptom count is 0.
   - ✅ Added `Semantics` label via `_buildTooltipSemanticsLabel()` for screen reader support.
   - ✅ TODO added for future widget tests covering tooltip behavior.

### 3.5 Legend ✅ **COMPLETED**

**Objective**: Help users interpret colors without clutter.

**Implementation Status**: ✅ Completed

1. ✅ Added `_LegendItem` data class in `lib/features/health/widgets/symptoms_stacked_bar_chart.dart`:
   - ✅ Fields: `label` (String) and `color` (Color)
   - ✅ Immutable data class for legend item representation
2. ✅ Implemented `_buildLegendItems()` helper method:
   - ✅ **Stacked mode**: Aggregates total days across all buckets for each symptom in `viewModel.visibleSymptoms`; includes symptom in legend if total days > 0
   - ✅ **Stacked mode "Other"**: Computes "Other" count per bucket (totalSymptomDays minus visible symptoms) and includes "Other" legend item if aggregate total > 0
   - ✅ **Single-symptom mode**: Shows only the selected symptom if it has any non-zero data across buckets
   - ✅ Maintains ordering: visible symptoms in `viewModel.visibleSymptoms` order, with "Other" at the end when present
3. ✅ Replaced `_buildLegendPlaceholder()` with full legend implementation:
   - ✅ Early returns `SizedBox.shrink()` if no legend items (edge case handling)
   - ✅ Uses `Wrap` widget with `spacing: AppSpacing.md`, `runSpacing: AppSpacing.sm`, and `alignment: WrapAlignment.center` for responsive layout
   - ✅ Each legend chip is a `Container` with:
     - ✅ Background color: `item.color.withValues(alpha: 0.1)` (subtle tint)
     - ✅ Border: `item.color.withValues(alpha: 0.3)` with 8px border radius
     - ✅ Row containing: 12x12 colored circle dot + symptom name text
     - ✅ Text styled with `AppTextStyles.caption`, `AppColors.textSecondary`, and `FontWeight.w500`
   - ✅ Stable keys: `ValueKey('symptom-legend-${item.label}')` for widget tests
4. ✅ Layout adjustments:
   - ✅ Restructured chart layout: chart area (200px fixed height) in `SizedBox`, legend below in `Column` (not constrained by fixed height)
   - ✅ Legend padding: `EdgeInsets.only(top: AppSpacing.lg)` for proper spacing from chart
5. ✅ Styling consistency:
   - ✅ Matches injection sites donut chart legend styling (chip design, spacing, colors)
   - ✅ Reuses `_getSymptomLabel()` for legend labels (same as tooltip text)
   - ✅ Colors match chart segments: `SymptomColors.colorForSymptom()` for specific symptoms, `SymptomColors.colorForOther()` for "Other"
6. ✅ Accessibility:
   - ✅ Wrapped entire legend `Wrap` in `Semantics` widget with label "Symptoms legend"
   - ✅ Ready for widget tests (keys and structure in place)

---

## 4. Symptoms Screen Integration & Controls

### 4.1 Extend SymptomsScreen layout ✅ **COMPLETED**

**Objective**: Replace the pure empty state with chart + history while preserving FAB and initial message.

**Implementation Status**: ✅ Completed

1. ✅ Updated `SymptomsScreen` body:
   - ✅ Replaced hard-coded `_buildEmptyState()` call with conditional `_buildBody()` method
   - ✅ Implemented `_hasAnySymptomData()` helper that checks:
     - Current month summary `daysWithAnySymptoms > 0` via `currentMonthSymptomsSummaryProvider`
     - Chart buckets with `totalSymptomDays > 0` via `symptomsChartDataProvider`
   - ✅ Conditional branching:
     - If **no symptom data** → shows existing empty state (preserves first-time user experience)
     - If **data exists** → shows analytics layout with chart and placeholder controls
2. ✅ Created analytics layout scaffold (`_buildAnalyticsLayout()`):
   - ✅ Period header placeholder (`_buildGraphHeader()`) - ready for section 4.3
   - ✅ Granularity selector placeholder (`_buildGranularitySelector()`) - ready for section 4.2
   - ✅ Chart section with `SymptomsStackedBarChart` widget fully integrated
   - ✅ Optional summary placeholder (commented out for future use)
3. ✅ Maintained existing FAB behavior:
   - ✅ `_scrollController`, `_handleScroll`, and `_showFab` logic unchanged
   - ✅ `HydraExtendedFab` continues to hide/show on scroll as before
4. ✅ Styling alignment:
   - ✅ Uses `AppSpacing.md` for padding matching WeightScreen pattern
   - ✅ Column layout with consistent spacing between header, controls, and chart
   - ✅ All imports added: providers, models, and chart widget

### 4.2 Granularity selector (reuse HydraSlidingSegmentedControl) ✅ **COMPLETED**

**Objective**: Match the weight screen's segmented control for Week/Month/Year.

**Implementation Status**: ✅ Completed

1. ✅ Added `_buildGranularitySelector` method in `SymptomsScreen`:
   - ✅ Uses `HydraSlidingSegmentedControl<SymptomGranularity>` matching `WeightScreen` pattern
   - ✅ Reads current granularity from `symptomsChartStateProvider`
   - ✅ Configures three segments: Week, Month, Year with `Text` labels
   - ✅ Wrapped in `SizedBox(width: double.infinity)` for full-width layout
2. ✅ Wired `onChanged` callback:
   - ✅ Triggers `HapticFeedback.selectionClick()` for tactile feedback
   - ✅ Calls `ref.read(symptomsChartStateProvider.notifier).setGranularity(newGranularity)`
   - ✅ `SymptomsChartNotifier.setGranularity()` automatically resets `selectedSymptomKey` to `null` when switching granularities (already implemented in section 2.2)
3. ✅ Added required imports:
   - ✅ `package:flutter/services.dart` for `HapticFeedback`
   - ✅ `package:hydracat/features/health/models/symptom_granularity.dart` for `SymptomGranularity`
   - ✅ `package:hydracat/shared/widgets/inputs/hydra_sliding_segmented_control.dart` for `HydraSlidingSegmentedControl`
4. ✅ Widget tests added in `test/features/health/screens/symptoms_screen_granularity_selector_test.dart`:
   - ✅ Verifies all three segments (Week, Month, Year) render correctly
   - ✅ Tests that tapping Month segment updates granularity state
   - ✅ Tests that tapping Year segment updates granularity state
   - ✅ Verifies `selectedSymptomKey` resets to null when granularity changes

### 4.3 Period header (chevrons + Today) ✅ **COMPLETED**

**Objective**: Provide consistent navigation between periods.

**Implementation Status**: ✅ Completed

1. ✅ Added `_buildGraphHeader` method in `SymptomsScreen`:
   - ✅ Left/right chevrons:
     - ✅ Left chevron calls `previousPeriod()` on the symptoms chart notifier
     - ✅ Right chevron calls `nextPeriod()` and is disabled when `isOnCurrentPeriod` is `true`
     - ✅ Both chevrons trigger `HapticFeedback.selectionClick()` on tap
     - ✅ Tooltips added for accessibility ("Previous week", "Next week", "Cannot view future")
   - ✅ Period label formatting:
     - ✅ Week: `_formatWeekLabel()` shows `MMM d–d, yyyy` range (e.g., "Nov 3-9, 2025") with cross-month handling
     - ✅ Month: `DateFormat('MMMM yyyy')` format (e.g., "November 2025")
     - ✅ Year: `yearStart.year.toString()` format (e.g., "2025")
   - ✅ "Today" button:
     - ✅ Visible only when `!isOnCurrentPeriod`
     - ✅ Calls `goToToday()` on tap with haptic feedback
     - ✅ Styled with `AppTextStyles.buttonSecondary` and `AppColors.primary`
2. ✅ Layout matches weight screen pattern:
   - ✅ Row layout with chevrons, period label, `Spacer()`, and conditional Today button
   - ✅ Period label uses `AppTextStyles.body` with `FontWeight.w500`
   - ✅ Proper spacing with `AppSpacing.xs` between elements
3. ✅ Added required imports:
   - ✅ `package:intl/intl.dart` for `DateFormat`
4. ✅ Widget tests added in `test/features/health/screens/symptoms_screen_granularity_selector_test.dart`:
   - ✅ Period label formatting tests for week, month, and year granularities
   - ✅ Left chevron navigation test (calls `previousPeriod()`)
   - ✅ Right chevron disabled/enabled state tests based on `isOnCurrentPeriod`
   - ✅ Right chevron navigation test (calls `nextPeriod()` when enabled)
   - ✅ Today button visibility tests (hidden on current period, visible otherwise)
   - ✅ Today button functionality test (calls `goToToday()`)

### 4.4 Symptom selection dropdown (All vs single symptom) ✅ **COMPLETED**

**Objective**: Allow advanced users to focus on a single symptom.

**Implementation Status**: ✅ Completed

1. ✅ Added `_buildSymptomSelector()` method in `SymptomsScreen`:
   - ✅ Positioned below the granularity selector and above the chart section in `_buildAnalyticsLayout()`
   - ✅ Uses `CustomDropdown<String?>` widget for consistent styling with other dropdowns in the app
   - ✅ Left-aligned with fixed width (200px) for consistent layout
   - ✅ Includes "All symptoms" option (maps to `selectedSymptomKey = null`)
   - ✅ Includes all 6 symptom options in static priority order: lethargy, suppressedAppetite, vomiting, injectionSiteReaction, constipation, diarrhea
   - ✅ Labels match chart widget labels via `_getSymptomLabel()` helper method for consistency
2. ✅ State wiring:
   - ✅ Reads current `selectedSymptomKey` from `symptomsChartStateProvider` to set dropdown value
   - ✅ `onChanged` callback calls `setSelectedSymptom(newKeyOrNull)` with haptic feedback
   - ✅ Chart widget already receives `selectedSymptomKey` via `_buildChartSection()` (no changes needed)
3. ✅ Chart behavior verified:
   - ✅ `null` → stacked mode (all symptoms shown as stacked bars)
   - ✅ non-null → single-symptom mode (only selected symptom shown)
4. ✅ State interactions:
   - ✅ Changing granularity (Week/Month/Year) resets `selectedSymptomKey` to `null` (existing behavior in `setGranularity()`)
   - ✅ Period navigation (chevrons, Today) preserves `selectedSymptomKey` (no reset on navigation)
5. ✅ Widget tests added in `test/features/health/screens/symptoms_screen_granularity_selector_test.dart`:
   - ✅ Dropdown rendering verification
   - ✅ "All symptoms" option visibility
   - ✅ Dropdown interaction and opening
   - ✅ Selecting a symptom updates `selectedSymptomKey` correctly
   - ✅ Selecting "All symptoms" sets `selectedSymptomKey` to `null`
   - ✅ Changing granularity resets `selectedSymptomKey` to `null`
   - ✅ Period navigation preserves `selectedSymptomKey` (does not reset)

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
   - [x] Implement `SymptomGranularity` enum.
   - [x] Implement `SymptomBucket` model.
   - [x] Add `SymptomColors` helper + update `ui_guidelines`.
2. **Providers & Aggregation**
   - [x] Implement `symptomsChartStateProvider` (focused date, granularity, selection).
   - [x] Implement weekly buckets provider (`weeklySymptomBucketsProvider`).
   - [x] Implement monthly buckets provider (`monthlySymptomBucketsProvider`).
   - [x] Implement yearly buckets provider (`yearlySymptomBucketsProvider`).
   - [x] Implement unified `symptomsChartDataProvider` with top-5 + Other logic.
3. **Chart Widget**
   - [x] Create `SymptomsStackedBarChart` widget structure and placement (section 3.1).
   - [x] Implement stacked vs single-symptom rendering (section 3.2).
   - [x] Implement basic visual styling and alignment (section 3.3 - layout, colors, grid, borders, x-axis labels).
   - [x] Implement tooltips matching existing chart styling (section 3.4).
   - [x] Implement legend matching existing chart styling (section 3.5).
4. **Screen Integration**
   - [x] Extend `SymptomsScreen` to show chart instead of only empty state when data exists.
   - [x] Add Week/Month/Year segmented control wired to chart state.
   - [x] Add period header with chevrons + Today button.
   - [x] Add symptom selection dropdown and wire to chart.
5. **Performance & Testing**
   - [ ] Sanity-check Firestore read patterns in debug logs.
   - [x] Add unit tests for aggregation/top-5 logic.
   - [ ] Add at least one widget test for chart rendering.
   - [x] Run `flutter analyze` and `flutter test` before manual UX testing.

Once this plan is implemented, we’ll have a cohesive, low-cost symptom visualization that feels native to HydraCat’s existing analytics and UI patterns, and can be extended later with premium, long-range analytics without changing the underlying data model.


