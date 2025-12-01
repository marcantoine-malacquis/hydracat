# Progress Month View optimisation — dailyVolumes in monthly summary

Goal: move fluid month view (calendar dots + 31-bar chart) to read a single monthly summary doc containing per-day fields, removing 28–42 daily summary reads per cold month. No migration/back-compat needed.

## Phase 0: Data shape + guardrails ✅ COMPLETED

**Implementation Date**: 2025-12-01
**Status**: All acceptance criteria met, 20 tests passing

### What Was Implemented:

**Model Changes** (`lib/shared/models/monthly_summary.dart`):
- ✅ Added 3 new required list fields to `MonthlySummary`:
  - `dailyVolumes`: `List<int>` length = monthLength (28–31), index = day-1, ml per day, missing → 0
  - `dailyGoals`: `List<int>` same length, ml goal per day, missing → 0
  - `dailyScheduledSessions`: `List<int>` same length, count of scheduled fluid sessions per day, missing → 0
- ✅ Updated all model methods: constructor, `.empty()`, `fromJson()`, `toJson()`, `validate()`, `copyWith()`, `operator ==`, `hashCode`, `toString()`
- ✅ Added `parseIntList()` helper in `fromJson()` for robust deserialization:
  - Handles null/missing lists → defaults to zero-filled array
  - Auto-pads short lists with zeros
  - Auto-truncates long lists
  - Clamps all values to 0-5000 range during parsing
- ✅ Added `_listEquals()` helper for proper list equality comparison
- ✅ Comprehensive validation:
  - List length must match `daysInMonth` (28-31)
  - `dailyVolumes` and `dailyGoals`: 0-5000 ml bounds
  - `dailyScheduledSessions`: 0-10 bounds
  - Descriptive error messages with day numbers

**Tests** (`test/shared/models/monthly_summary_test.dart`):
- ✅ 20 comprehensive unit tests, all passing
- ✅ Serialization/deserialization roundtrip
- ✅ Null/missing list handling
- ✅ Padding/truncation edge cases
- ✅ Validation (length and bounds)
- ✅ Edge cases: leap years (29 days), 28/30/31-day months
- ✅ Value clamping (negative → 0, >5000 → 5000)
- ✅ copyWith, equality, hashCode correctness

**Documentation**:
- ✅ Updated `test/tests_index.md` with new test section

### Key Features:
- **Backward Compatible**: Missing/null lists default to zero-filled arrays
- **Robust**: Auto-adjusts list lengths, clamps extreme values
- **Type-Safe**: Strong validation with clear error messages
- **Well-Tested**: 100% test coverage for all edge cases

### Acceptance Criteria:
- ✅ Model compiles without errors (`flutter analyze` clean)
- ✅ All 20 tests pass
- ✅ Backward compatible with existing Firestore docs
- ✅ Validation catches invalid data
- ✅ Serialization roundtrip preserves data
- ✅ Edge cases handled (leap years, variable month lengths)
- ✅ No UI/write logic changes (deferred to Phase 1)

**Files Modified**:
- `lib/shared/models/monthly_summary.dart` - Model implementation
- `test/shared/models/monthly_summary_test.dart` - Comprehensive tests (new)
- `test/tests_index.md` - Test documentation

---

## Phase 1: Update write path to populate monthly summary ✅ COMPLETED
**Status**: LoggingService write path now populates per-day monthly arrays on fluid log + edit; helper + tests passing.

### What Was Implemented
- `lib/features/logging/services/logging_service.dart` now fetches daily totals via `_fetchDailyTotalsForMonthly` (reads the daily summary, applies the session delta, carries goal/scheduled counts) and existing monthly arrays via `_fetchMonthlyArrays` (pads/truncates/clamps values to month length and 0-5000 bounds).
- `_addFluidSessionToBatch` writes monthly summaries with `SetOptions(merge: true)`, using `MonthlyArrayHelper.updateDailyArrayValue` to overwrite `dailyVolumes`, `dailyGoals`, and `dailyScheduledSessions` for `date.day` with the recomputed totals. Handles missing docs and month length changes automatically.
- `updateFluidSession` uses the same flow with volume deltas and goal carry-over so edits always rewrite that day's entry; scheduled-count delta is zeroed on edits to avoid double counting. (No explicit delete flow yet; helpers are ready for reuse if added.)
- Adds a controlled +2 reads per fluid log/edit (daily summary + monthly summary) to guarantee array correctness across multiple sessions in a day.

### Helper & Tests
- `lib/features/logging/services/monthly_array_helper.dart`: pure Dart helper for resizing/clamping monthly arrays.
- `test/features/logging/services/monthly_array_helper_test.dart`: 22 unit tests covering initialization, padding/truncation, bounds, month-length variants, and repeated updates; documented in `test/tests_index.md`.

### Notes
- Quick-log batches still write monthly increments only (no daily array overwrite); add helper wiring there if month view needs quick-log support.

## Phase 2: Backfill helper (optional, single run)
- Add a dev-only helper (script or debug-only service function) to rebuild one month’s `daily*` arrays from daily summaries for a user/pet/month (reads 28–31 daily docs → writes one monthly doc). Keep behind assert/dev flag; not shipped.

## Phase 3: Read-side provider for month fluid data
- Model updates: extend `MonthlySummary` model to include the three lists with safe defaults (empty → zeroed).
- SummaryService: add parsing/serialization support for the new lists; keep TTL caching at 15 min.
- New provider: `monthlyFluidBucketsProvider(monthStart)` (Riverpod):
  - Fetch monthly summary via `SummaryService.getMonthlySummary`.
  - Build a list of per-day bucket objects: date, volumeMl, goalMl, scheduledCount, computed `isMissed = scheduledCount > 0 && volumeMl == 0 && day < today`.
  - Return null if monthly summary missing; otherwise always return the list (fallback flag can optionally switch to daily summaries, but plan to retire it).
- Add small pure-Dart tests for the builder to verify list sizing, padding, missed logic, today boundary.

## Phase 4: Wire to calendar dots and chart (month mode)
- Calendar dots (month mode only):
  - In `dateRangeStatusProvider`, when format == month, derive statuses from monthly buckets: complete (volume>0 && volume>=goal if you want stricter), missed (scheduled>0 && volume==0 && past), today special case when scheduled>0 && volume==0.
  - Week mode remains on `weekStatusProvider` (no change).
- Month 31-bar chart:
  - Add a month chart view model to transform monthly buckets into bar data (31 bars, hide beyond monthLength).
  - Render only in month format; week format keeps existing `FluidVolumeBarChart`.
- Respect CRUD rules: no session queries, single monthly doc read.

## Phase 5: Cleanup and toggles
- Remove redundant daily-summary fetches in month mode once the monthly-summary path is live.
- Update documentation/schema comments near SummaryService/model to describe new fields.

## Phase 6: Verification
- Unit tests: helper for list padding/overwrite, bucket builder missed-status logic, monthLength handling.
- Manual checks (you run):
  - Log fluids across several days; verify month view shows bars/dots correctly and Firestore shows one monthly read per new month.
  - Navigate to past/future months (no future nav beyond current); validate 28/29/30/31 handling.
  - Missed days: scheduled>0 and 0 volume show missed; today shows pending appropriately.
- Lint: run `flutter analyze` after implementation and fix any findings before manual UI testing.

## Notes
- Keep adherence to firebase_CRUDrules.md: no per-session scans; rely on pre-aggregated summaries; no real-time listeners on histories.
- Document field format in a short schema comment near SummaryService or model for future contributors.
