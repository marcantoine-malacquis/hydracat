## Symptoms Tracking Feature – Implementation Plan

---

## Overview

Add daily CKD symptom tracking (0–10 sliders per symptom) plus monthly trends, reusing the existing `healthParameters` collection and `treatmentSummaries` (daily/weekly/monthly) so that analytics are always based on pre-aggregated summaries and Firestore costs stay low.

---

## 0. Coherence & Constraints

- **Coherence with PRD**: Symptom tracking directly implements the PRD’s “Symptom Check-ins” requirement and supports comprehensive CKD monitoring and caregiver reassurance, without making medical interpretations.
- **Firestore & CRUD rules**:  
  - One **daily health snapshot** per pet in `healthParameters/{YYYY-MM-DD}` (no extra subcollections).  
  - **Summaries-first analytics** using `treatmentSummaries/daily|weekly|monthly/summaries` for long-range trends.  
  - **Cost control**: short-window reads from `healthParameters` (≤30 days), batched writes, no full-history queries.
- **Architecture fit**: Reuse the existing **health** module (`HealthParameter`, `WeightService`) and **summary** patterns (`SummaryService`, `LoggingService`, monthly summaries in `weight_service.dart`).
- **Your decisions from plan.md**:  
  1. Each symptom uses a **slider from N/A → 0 → 10** (0–10 severity scale).  
  2. Appetite is **not yet implemented** separately; for now “suppressed appetite” is a symptom.  
  3. Add a **“Symptoms” card** in the Progress insights list, leading to a new **Symptoms screen** under `features/health`, reusing the weight feature patterns.  
  4. Keep the **one-doc-per-day** `healthParameters/{YYYY-MM-DD}` pattern.  
  5. Store **both simple boolean-derived counts and a numeric “symptom score”** in daily/weekly/monthly summaries.  
  6. Use **daily data for recent windows** (e.g. last 30 days) and **weekly/monthly summaries** for longer ranges.  
  7. Keep summary update logic **in Flutter (client)** using batched writes.  
  8. Use **only summaries** for month+ analytics; fetch `healthParameters` only for short drill-down ranges.  
  9. Design for **summaries + short-window client-side filtering**, adding indexes later only if needed.  
  10. **Basic symptom tracking is free**; advanced analytics could be gated later if desired.  
  11. Add minimal, privacy-safe analytics events: `symptoms_log_created`, `symptoms_log_updated`.

---

## Free vs Premium Analytics Split

### Free Features (Core Symptom Tracking)

**Daily Logging & Basic Overview:**
- ✅ Daily symptom sliders (0–10 per symptom: vomiting, diarrhea, constipation, lethargy, suppressed appetite, injection site reaction)
- ✅ Per-day overall status indicator (computed from scores, displayed as "Good / Okay / Concerning")
- ✅ Daily notes field (500 char limit)
- ✅ Simple recent 30-day view (colored dots or mini-bars showing computed overall status or `symptomScoreAverage`)
- ✅ Basic monthly summary card on Progress screen:
  - "X concerning days / Y symptom-free days this month"
  - "Average symptom score: Z/10"
  - Simple counts derived from monthly summary docs

**Rationale**: These features provide essential daily tracking and basic reassurance without paywalling core care. Aligns with PRD's goal of supporting anxious caregivers with foundational monitoring tools.

### Premium Features (Advanced Analytics & Insights)

**Long-Range & Comparative Trends:**
- 🔒 **6–12+ month symptom history** with rich charts (line/area charts showing `symptomScoreAverage` or `symptomScoreTotal` over time)
- 🔒 **Month-to-month comparisons** ("September vs August" symptom burden)
- 🔒 **Before/after treatment change** analysis (compare symptom patterns before/after medication or fluid adjustments)
- 🔒 **"Worst 5 days"** lists for selected time ranges (drill-down into highest `symptomScoreTotal` days)

**Correlation Analytics (Symptoms ↔ Treatments & Labs):**
- 🔒 **Symptom vs treatment adherence** correlations:
  - Symptoms vs fluid therapy adherence (e.g., "On weeks with lower fluid adherence, symptom scores tended to be higher")
  - Symptoms vs medication adherence
  - Symptoms vs weight trends
- 🔒 **Symptom vs lab values** correlations (e.g., symptoms vs creatinine/BUN trends over time)
- 🔒 **Neutral, data-driven insights** (no medical claims, just pattern recognition)

**Advanced Drill-Down & Filtering:**
- 🔒 **Historical filtering** by specific symptom and severity (e.g., "Show all days with vomiting ≥ 7 in last 6 months")
- 🔒 **Symptom episode detection** (identify clusters of consecutive bad days)
- 🔒 **Detailed timeline views** (tap a month card → see day-by-day breakdown with all symptom scores)

**Vet-Ready Outputs & Exports:**
- 🔒 **PDF/printable reports** for vet visits:
  - Last 3–6 months symptom charts
  - Combined with fluid therapy and medication summaries
  - Professional formatting suitable for veterinary consultations
- 🔒 **CSV/data export** for power users (with clear privacy messaging)

**Customization & Power-User Features:**
- 🔒 **Custom symptoms** (user-defined symptoms with their own 0–10 sliders, included in all analytics)
- 🔒 **Per-symptom alert thresholds** (e.g., "Highlight days where vomiting ≥ 7")
- 🔒 **Saved views/presets** (e.g., "Pre-visit snapshot" showing last 30 days in vet-friendly format)

**Rationale**: Premium features provide deeper insights, correlations, and professional tools that add significant value for data-driven users and vet consultations, while keeping basic care accessible to all.

**Implementation Note**: For V1 implementation, focus on free features only. Premium features can be added later with feature flags/gating. The data model (summaries with `symptomScoreTotal`, `symptomScoreAverage`, per-symptom counts) already supports premium analytics without schema changes.

---

## Phase 1 – Data Model & Firestore Schema

### Step 1.1: Extend HealthParameter for Symptoms ✅ COMPLETED

**Goal**: Extend `healthParameters/{YYYY-MM-DD}` to store per-symptom 0–10 scores, while remaining compact and queryable.
**Existing model**: `HealthParameter` already stores `date`, `weight`, `appetite`, `symptoms` (string “good/okay/concerning”), `notes`, `createdAt`, `updatedAt`.

**Implementation Status**: ✅ **COMPLETED**

**New fields (Firestore schema)** under `users/{userId}/pets/{petId}/healthParameters/{YYYY-MM-DD}`:
  - Add per-symptom numeric scores (0–10, or absent = N/A):  
    - `symptoms: map` (optional) containing:
      - `vomiting: number` (int 0–10)  
      - `diarrhea: number` (int 0–10)  
      - `constipation: number` (int 0–10)  
      - `lethargy: number` (int 0–10)  
      - `suppressedAppetite: number` (int 0–10)  
      - `injectionSiteReaction: number` (int 0–10)
    - **Storage rule**:  
      - N/A → field **omitted** (no key in map).  
      - 0–10 → stored as integer.  
      - This keeps documents small and makes “has any symptom” checks easy.
  - Add derived helper flags (computed and stored):  
    - `hasSymptoms: boolean` – true if at least one symptom score > 0.  
    - `symptomScoreTotal: number` – sum of all present symptom scores (0–60 for 6 symptoms).  
    - `symptomScoreAverage: number` – average of present scores (0–10, nullable if no symptoms).

**Model changes – `HealthParameter`** (✅ Implemented):
  - ✅ Replaced `final String? symptoms;` with `final Map<String, int>? symptoms;`
  - ✅ Added computed stored fields: `hasSymptoms`, `symptomScoreTotal`, `symptomScoreAverage`
  - ✅ Updated `HealthParameter` constructor to accept new fields
  - ✅ Updated `create()` factory to:
    - Accept `Map<String, int>? symptoms` parameter
    - Validate symptom scores (0-10 range)
    - Automatically compute derived fields
  - ✅ Updated `fromFirestore` to parse `symptoms` map (Map<String, dynamic> → Map<String, int>), `symptomScoreTotal`, `symptomScoreAverage`, `hasSymptoms`
  - ✅ Updated `toJson()` to serialize symptoms map, omitting nulls and empty maps
  - ✅ Updated `copyWith()` to support updating `symptoms` map and computed fields (using `_undefined` sentinel pattern)
  - ✅ Updated `toString`, `==`, `hashCode` for new fields
  - ✅ Added helper methods: `_computeHasSymptoms`, `_computeSymptomScoreTotal`, `_computeSymptomScoreAverage`, `_validateSymptomScore`
  - ✅ Added computed getters as fallback: `computedHasSymptoms`, `computedSymptomScoreTotal`, `computedSymptomScoreAverage`

**Symptom Type Constants** (✅ Implemented):
  - ✅ Created `lib/features/health/models/symptom_type.dart` with constants for all 6 symptom keys
  - ✅ Added validation helper `isValid()` method

**Backward compatibility**:
  - ✅ Old string `symptoms` field is ignored when parsing (no mapping needed, per user preference)
  - ✅ Firestore rules already guard `healthParameters`; no structural rule changes needed

**Note**: Overall status ("good" | "okay" | "concerning") will be computed from numeric scores in the service/UI layer when needed, rather than stored as a separate field.

### Step 1.2: Update Firestore Schema Documentation ✅ COMPLETED

**Goal**: Keep `.cursor/rules/firestore_schema.md` aligned with the new symptom fields so future features stay coherent and cost-aware.

**Implementation Status**: ✅ **COMPLETED**

- ✅ Updated `.cursor/rules/firestore_schema.md` in the `healthParameters` section to reflect:
  - `symptoms: map # per-symptom 0–10 scores, optional` with the 6 keys (vomiting, diarrhea, constipation, lethargy, suppressedAppetite, injectionSiteReaction)
  - `hasSymptoms: boolean # true if any symptom score > 0, optional`  
  - `symptomScoreTotal: number # optional, sum of scores for that day (0-60)`  
  - `symptomScoreAverage: number # optional, average of present scores (0-10)`
- ✅ Schema reference is now in sync with the implementation and supports future cost audits.

---

## Phase 2 – Summary Documents for Symptom Trends

### Step 2.1: Add Daily Summary Fields for Symptoms ✅ COMPLETED

**Goal**: Mirror daily symptoms into `treatmentSummaries/daily/summaries` so month/week analytics never query full `healthParameters` history.

**Implementation Status**: ✅ **COMPLETED**

**Path**: `users/{userId}/pets/{petId}/treatmentSummaries/daily/summaries/{YYYY-MM-DD}`  
  (same pattern as existing treatment summaries).

**New fields** added to the daily summary model (✅ Implemented):
  - Per-symptom booleans (did the symptom appear at all?):  
    - ✅ `hadVomiting: boolean`  
    - ✅ `hadDiarrhea: boolean`  
    - ✅ `hadConstipation: boolean`  
    - ✅ `hadLethargy: boolean`  
    - ✅ `hadSuppressedAppetite: boolean`  
    - ✅ `hadInjectionSiteReaction: boolean`
  - Per-symptom daily max scores (optional but useful for drill-down):  
    - ✅ `vomitingMaxScore: number` (0–10, nullable)  
    - ✅ `diarrheaMaxScore: number` (0–10, nullable)  
    - ✅ `constipationMaxScore: number` (0–10, nullable)  
    - ✅ `lethargyMaxScore: number` (0–10, nullable)  
    - ✅ `suppressedAppetiteMaxScore: number` (0–10, nullable)  
    - ✅ `injectionSiteReactionMaxScore: number` (0–10, nullable)
  - Overall daily scores:  
    - ✅ `symptomScoreTotal: number` – copy from the daily `healthParameters` doc (nullable)  
    - ✅ `symptomScoreAverage: number` – copy from the daily doc (nullable)  
    - ✅ `hasSymptoms: boolean` – copy from daily doc (defaults to false)
    - ⏸️ `symptomStatus: string` – **DEFERRED** (may be added later, not implemented)

**Model changes – `DailySummary`** (✅ Implemented):
  - ✅ Added all symptom boolean fields with default value `false`
  - ✅ Added all symptom max score fields as nullable (`int?`)
  - ✅ Added `symptomScoreTotal`, `symptomScoreAverage` as nullable fields
  - ✅ Added `hasSymptoms` boolean field (defaults to `false`)
  - ✅ Updated constructor to accept all new fields with appropriate defaults
  - ✅ Updated `empty()` factory to initialize all symptom fields (booleans = false, nullable fields = null)
  - ✅ Updated `fromJson()` factory to parse all symptom fields with safe defaults and backward compatibility
  - ✅ Updated `toJson()` method to serialize all symptom fields (conditional inclusion for nullable fields)
  - ✅ Updated `copyWith()` method to support all symptom fields using `_undefined` sentinel pattern for nullable fields
  - ✅ Updated `==` operator and `hashCode` to include all new symptom fields
  - ✅ Updated `toString()` to include all symptom fields

**Firestore Schema Documentation** (✅ Updated):
  - ✅ Updated `.cursor/rules/firestore_schema.md` to document all new symptom fields in daily summaries section

**Note**: The `symptomStatus` field (computed overall status "good" | "okay" | "concerning") was excluded from this implementation and may be added later if needed.

**Update rule** (to be implemented in Phase 3):
  - Each write to `healthParameters/{YYYY-MM-DD}` (create or update) will trigger a **client-side batched update**:  
    - Read the current symptom scores from the in-memory `HealthParameter`.  
    - Compute booleans and max scores.  
    - Upsert the corresponding daily summary doc (create if missing, merge if existing) with the fields above.

### Step 2.2: Add Weekly & Monthly Symptom Aggregates ✅ COMPLETED

**Goal**: Store long-range symptom trends (counts and scores) in weekly/monthly summary docs.

**Implementation Status**: ✅ **COMPLETED**

**Paths** (already in use):  
  - Weekly: `.../treatmentSummaries/weekly/summaries/{YYYY-Www}`  
  - Monthly: `.../treatmentSummaries/monthly/summaries/{YYYY-MM}`

**New aggregated fields** added to weekly and monthly summary models (✅ Implemented):
  - Counts of days with each symptom:  
    - ✅ `daysWithVomiting: number`  
    - ✅ `daysWithDiarrhea: number`  
    - ✅ `daysWithConstipation: number`  
    - ✅ `daysWithLethargy: number`  
    - ✅ `daysWithSuppressedAppetite: number`  
    - ✅ `daysWithInjectionSiteReaction: number`
  - Aggregate scores:  
    - ✅ `symptomScoreTotal: number` – sum of daily `symptomScoreTotal` over the period (nullable)
    - ✅ `symptomScoreAverage: number` – average daily score across days with any symptoms (nullable)
    - ✅ `symptomScoreMax: number` – max daily `symptomScoreTotal` in the period (nullable)
  - Overall symptom day count:
    - ✅ `daysWithAnySymptoms: number` – count of days where `hasSymptoms == true` (added in Step 4.3, defaults to 0)
    - ⏸️ Counts by overall status (`daysGoodSymptoms`, `daysOkaySymptoms`, `daysConcerningSymptoms`) – **DEFERRED** (may be added later)

**Model changes – `WeeklySummary`** (✅ Implemented):
  - ✅ Added all 6 symptom day count fields with default value `0`
  - ✅ Added `daysWithAnySymptoms` field with default value `0` (added in Step 4.3)
  - ✅ Added 3 aggregate score fields (`symptomScoreTotal`, `symptomScoreAverage`, `symptomScoreMax`) as nullable
  - ✅ Updated constructor to accept all new fields with appropriate defaults
  - ✅ Updated `empty()` factory (fields use constructor defaults)
  - ✅ Updated `fromJson()` factory to parse all symptom fields with safe defaults and backward compatibility
  - ✅ Updated `toJson()` method to serialize all symptom fields (conditional inclusion for nullable fields)
  - ✅ Updated `copyWith()` method to support all symptom fields using `_undefined` sentinel pattern for nullable fields
  - ✅ Updated `==` operator and `hashCode` to include all new symptom fields
  - ✅ Updated `toString()` to include all symptom fields

**Model changes – `MonthlySummary`** (✅ Implemented):
  - ✅ Added all 6 symptom day count fields with default value `0`
  - ✅ Added `daysWithAnySymptoms` field with default value `0` (added in Step 4.3)
  - ✅ Added 3 aggregate score fields (`symptomScoreTotal`, `symptomScoreAverage`, `symptomScoreMax`) as nullable
  - ✅ Updated constructor to accept all new fields with appropriate defaults
  - ✅ Updated `empty()` factory (fields use constructor defaults)
  - ✅ Updated `fromJson()` factory to parse all symptom fields with safe defaults and backward compatibility
  - ✅ Updated `toJson()` method to serialize all symptom fields (conditional inclusion for nullable fields)
  - ✅ Updated `copyWith()` method to support all symptom fields using `_undefined` sentinel pattern for nullable fields
  - ✅ Updated `==` operator and `hashCode` to include all new symptom fields
  - ✅ Updated `toString()` to include all symptom fields

**Firestore Schema Documentation** (✅ Updated):
  - ✅ Updated `.cursor/rules/firestore_schema.md` to document all new symptom fields in weekly summaries section
  - ✅ Updated `.cursor/rules/firestore_schema.md` to document all new symptom fields in monthly summaries section

**Note**: Status counts (`daysGoodSymptoms`, `daysOkaySymptoms`, `daysConcerningSymptoms`) were deferred per user decision and may be added later if needed.

**Update strategy** (to be implemented in Phase 3):
  - When saving/updating a `HealthParameter` for date **D**:
    1. Compute the **delta** between the new and previous daily summary values for D (if an existing entry).  
    2. In a single `WriteBatch`, update:
       - `healthParameters/{D}`  
       - `treatmentSummaries/daily/summaries/{D}`  
       - `treatmentSummaries/weekly/summaries/{week(D)}`  
       - `treatmentSummaries/monthly/summaries/{month(D)}`  
    3. Weekly/monthly summaries are updated by incrementing/decrementing counts and scores based on the delta.
  - This mirrors the approach in `weight_service.dart` where monthly summaries are kept in sync with health parameters, avoiding re-aggregating full ranges.

---

## Phase 3 – Service Layer (Flutter)

### Step 3.1: Create SymptomsService ✅ COMPLETED

**Goal**: Encapsulate all symptom-related Firestore operations, mirroring `WeightService` structure.

**Location**: `lib/features/health/services/symptoms_service.dart`.

**Implementation Status**: ✅ **COMPLETED**

**Service Class Structure** (✅ Implemented):
  - ✅ Created `SymptomsService` class with constructor accepting optional `FirebaseFirestore` and `AnalyticsService`
  - ✅ Private fields: `_firestore`, `_analyticsService`
  - ✅ Organized into sections: Path Helpers, Validation, Daily Summary Updates, Weekly/Monthly Delta Logic, CRUD Operations

**Exception Classes** (✅ Implemented):
  - ✅ Added `SymptomValidationException extends HealthException` to `lib/features/health/exceptions/health_exceptions.dart`
  - ✅ Added `SymptomServiceException extends HealthException` to same file
  - ✅ Both follow the same pattern as existing `WeightValidationException` and `WeightServiceException`

**Path Helper Methods** (✅ Implemented):
  - ✅ `_getHealthParameterRef(String userId, String petId, DateTime date)` - Returns document reference for `healthParameters/{YYYY-MM-DD}` using `DateFormat('yyyy-MM-dd')`
  - ✅ `_getDailySummaryRef(String userId, String petId, DateTime date)` - Returns document reference using `AppDateUtils.formatDateForSummary()`
  - ✅ `_getWeeklySummaryRef(String userId, String petId, DateTime date)` - Returns document reference using `AppDateUtils.formatWeekForSummary()`
  - ✅ `_getMonthlySummaryRef(String userId, String petId, DateTime date)` - Returns document reference using `AppDateUtils.formatMonthForSummary()`

**Validation Methods** (✅ Implemented):
  - ✅ `_validateSymptomScores(Map<String, int>? symptoms)` - Validates all symptom scores are in 0-10 range, throws `SymptomValidationException` if invalid
  - ✅ `_validateNotes(String? notes)` - Ensures notes length ≤ 500 characters, throws `SymptomValidationException` if too long

**Daily Summary Update Logic** (✅ Implemented):
  - ✅ `_buildDailySummaryUpdates(HealthParameter newEntry, HealthParameter? oldEntry, DateTime date)` - Builds update map for daily summary document
    - Computes symptom boolean fields (`hadVomiting`, etc.) from symptom scores
    - Sets per-symptom max scores (for single day, max = current score)
    - Sets overall scores (`symptomScoreTotal`, `symptomScoreAverage`, `hasSymptoms`) from `newEntry`
    - Includes date, createdAt (if new entry), updatedAt fields
    - Uses `SetOptions(merge: true)` pattern for updates

**Weekly/Monthly Summary Delta Logic** (✅ Implemented):
  - ✅ `_buildWeeklySummaryDeltas(DailySummary? oldDaily, DailySummary newDaily)` - Computes delta updates for weekly summaries
  - ✅ `_buildMonthlySummaryDeltas(DailySummary? oldDaily, DailySummary newDaily)` - Reuses weekly delta logic (same computation)
  - ✅ Delta computation logic:
    - For each symptom boolean field: increments/decrements `daysWithX` counts based on changes (e.g., `daysWithVomiting`)
    - For `daysWithAnySymptoms`: increments/decrements based on `hasSymptoms` boolean changes (added in Step 4.3)
    - For `symptomScoreTotal`: computes delta using `FieldValue.increment()` for atomic updates
    - For `symptomScoreMax`: handled separately in `saveSymptoms()` after reading current summary
    - For `symptomScoreAverage`: set directly from daily summary (can be refined later)
  - ✅ Uses `FieldValue.increment()` for atomic updates to avoid race conditions

**CRUD Operations** (✅ Implemented):
  - ✅ `Future<HealthParameter?> getDailyHealth(String userId, String petId, DateTime date)` - Fetches existing health parameter for a date, returns null if not found, handles exceptions with `SymptomServiceException`
  - ✅ `Future<void> saveSymptoms({required String userId, required String petId, required DateTime date, Map<String, int>? symptoms, String? notes})` - Main method for saving/updating symptoms:
    - Validates inputs (scores and notes)
    - Normalizes date to start of day
    - Creates `HealthParameter` using `HealthParameter.create()` (automatically computes derived fields)
    - Preserves existing weight/appetite data if present
    - Fetches existing `HealthParameter` and `DailySummary` to compute deltas
    - Creates `WriteBatch` updating 4 documents atomically:
      1. `healthParameters/{YYYY-MM-DD}` - Individual entry
      2. `treatmentSummaries/daily/summaries/{YYYY-MM-DD}` - Daily summary
      3. `treatmentSummaries/weekly/summaries/{YYYY-Www}` - Weekly summary
      4. `treatmentSummaries/monthly/summaries/{YYYY-MM}` - Monthly summary
    - Handles max score updates for weekly/monthly summaries (reads current summary first)
    - Sets `startDate`/`endDate` for weekly/monthly summaries if creating new documents
    - Commits batch transaction
    - Handles exceptions and rethrows with `SymptomServiceException`
  - ✅ `Future<void> clearSymptoms(String userId, String petId, DateTime date)` - Clears symptoms by calling `saveSymptoms()` with `symptoms: null`
  - ✅ `Future<List<HealthParameter>> getRecentHealth({required String userId, required String petId, int limit = 30, bool symptomsOnly = false})` - Cost-optimized query:
    - Orders by `date` descending
    - Applies `where('hasSymptoms', isEqualTo: true)` filter if `symptomsOnly == true`
    - Limits results to `limit` (default 30, within CRUD rules)
    - Converts results to `HealthParameter` objects using tearoff syntax
    - Handles exceptions with `SymptomServiceException`

**Analytics Integration** (✅ Implemented):
  - ✅ Wired analytics events in `saveSymptoms()` method:
    - `symptoms_log_created`: Fired when a day that previously had no symptoms gets its first symptom entry
    - `symptoms_log_updated`: Fired when an existing symptoms entry is edited
    - Event parameters (excluding `symptom_status` as per user decision):
      - `symptom_count` - Number of symptoms with score > 0
      - `total_score` - Daily `symptomScoreTotal` (if present)
      - `has_injection_site_reaction` - Boolean flag
    - Analytics only logged if `_analyticsService` is provided

**Score Computation**:
  - ✅ Score computation (total, average, hasSymptoms) is handled by `HealthParameter.create()` factory method, no separate helper methods needed
  - ✅ Overall status ("good" | "okay" | "concerning") computation is completely deferred (not implemented)

**Implementation Notes**:
  - ✅ Follows same patterns as `WeightService` and `LoggingService` for consistency
  - ✅ Uses delta-based updates for weekly/monthly summaries to avoid re-aggregating full ranges
  - ✅ All Firestore operations use proper error handling with custom exceptions
  - ✅ Batch writes ensure atomic updates across all 4 document types
  - ✅ All linting issues resolved (flutter analyze passes)

### Step 3.2: Integrate with Summary & Logging Patterns ✅ COMPLETED

**Goal**: Reuse existing summary path helpers and caching patterns where appropriate.

**Implementation Status**: ✅ **COMPLETED** (integrated into Step 3.1)

- ✅ Path helpers implemented internally in `SymptomsService`:
  - `_getDailySummaryRef`, `_getWeeklySummaryRef`, `_getMonthlySummaryRef` using `AppDateUtils` formatting utilities
  - Follows same patterns as `SummaryService` / `LoggingService` for consistency
- ✅ Symptom-specific logic kept in `SymptomsService` for encapsulation
- ⏸️ Optional in-memory cache can be added later if needed for repeated summary reads

### Step 3.3: Wire Analytics Events ✅ COMPLETED

**Goal**: Track minimal, privacy-safe analytics for symptom logging.

**Implementation Status**: ✅ **COMPLETED** (integrated into Step 3.1)

- ✅ Analytics events wired in `saveSymptoms()` method using `AnalyticsService`:
  - `symptoms_log_created`: Fired when a day that previously had no symptoms (or no entry) gets its first symptom entry
  - `symptoms_log_updated`: Fired when an existing symptoms entry is edited
- ✅ Event parameters (all anonymized and safe):
  - `symptom_count` – number of symptoms with score > 0
  - `total_score` – daily `symptomScoreTotal` (if present)
  - `has_injection_site_reaction` – boolean (useful for future correlations with fluid therapy)
  - ⏸️ `symptom_status` – **EXCLUDED** per user decision (status computation completely deferred)

---

## Phase 4 – UI/UX Implementation

### Step 4.1a: Build Symptoms Entry Dialog (Full-Screen Popup) ✅ COMPLETED

**Goal**: Create a full-screen popup dialog for logging symptoms with 0–10 sliders per symptom, status, and notes.

**Implementation Status**: ✅ **COMPLETED**

- **Dialog pattern** (✅ Implemented):
  - ✅ Uses `LoggingPopupWrapper` for consistent styling (header with title/close button, scrollable content area).  
  - ✅ Location: `lib/features/health/widgets/symptoms_entry_dialog.dart`.
  - ✅ Dialog is displayed via `OverlayService.showFullScreenPopup()` (called from parent screen, not within dialog itself).
- **Dialog content** (✅ Implemented):
  - ✅ Title: "Log Symptoms" (or "Edit Symptoms" for edit mode).
  - ✅ Date selector (today by default) reusing date handling patterns from `weight_entry_dialog.dart`:
    - `InkWell` container with calendar icon
    - `DateFormat('MMM dd, yyyy')` for display
    - `showDatePicker` with past dates only (no future dates)
  - ✅ For each symptom (`vomiting`, `diarrhea`, `constipation`, `lethargy`, `suppressed appetite`, `injection site reaction`):
    - ✅ `_SymptomSlider` helper widget with:
      - Label (display name) for each symptom
      - N/A toggle switch (when enabled, slider is active; when disabled, value is `null`)
      - Discrete slider with 10 divisions (0-10 range)
      - Current value display (shows "N/A" or numeric value 0-10)
      - Under the hood: `null` (N/A) vs `0–10` int stored in `_symptomScores` map
    - ⏸️ Textual feedback under slider ("No symptom", "Mild", "Severe") – **DEFERRED** per user decision
  - ⏸️ Overall status indicator ("Good / Okay / Concerning") – **DEFERRED** per user decision
  - ✅ Notes field (multi-line text, 500 char limit, expandable like weight entry dialog):
    - `TextField` with `maxLength: 500`
    - `minLines: 1, maxLines: 5`
    - Character counter shown when focused (animated opacity)
  - ✅ Primary button: "Save symptoms" (or "Save" in edit mode):
    - Calls `SymptomsService.saveSymptoms()` with userId/petId from providers
    - Shows loading state during save (disabled button with `CircularProgressIndicator`)
    - On success: dismisses popup via `OverlayService.hide()` and shows success snackbar
    - On error: displays error message below notes field
- **Edit mode support** (✅ Implemented):
  - ✅ Dialog accepts optional `existingEntry: HealthParameter?` parameter (similar to `WeightEntryDialog`).  
  - ✅ Pre-fills symptom scores and notes from existing entry when provided.  
  - ✅ Date initialized from existing entry or today.
  - Note: Edit functionality will be accessed from the calendar (see Step 4.2 note below), not from the symptoms screen itself.
- **State Management** (✅ Implemented):
  - ✅ `_selectedDate: DateTime` - initialized from existing entry or today
  - ✅ `_symptomScores: Map<String, int?>` - tracks each symptom's score (null = N/A, 0-10 = severity)
  - ✅ `_notesController: TextEditingController` - for notes field
  - ✅ `_notesFocusNode: FocusNode` - for expandable notes field
  - ✅ `_isSaving: bool` - loading state during save
  - ✅ `_errorMessage: String?` - validation error display
- **Provider Integration** (✅ Implemented):
  - ✅ Uses `currentUserProvider` to get userId
  - ✅ Uses `primaryPetProvider` to get petId
  - ✅ Both providers accessed via `ref.read()` in save method
- **Error Handling** (✅ Implemented):
  - ✅ Handles `SymptomValidationException` (validation errors)
  - ✅ Handles `SymptomServiceException` (service errors)
  - ✅ Handles generic `Exception` (fallback for unexpected errors)
  - ✅ Error messages displayed below notes field with error styling

### Step 4.1b: Build Minimal Symptoms Screen (V1) ✅ COMPLETED

**Goal**: Create a minimal Symptoms screen with just a FAB button for adding symptoms entries.

**Implementation Status**: ✅ **COMPLETED**

- **Screen location** (✅ Implemented):
  - ✅ `lib/features/health/screens/symptoms_screen.dart`
- **Entry point**:
  - Screen is reached via a **"Symptoms" card** in the Progress insights list (see 4.3).
- **Layout for Symptoms screen (V1)** (✅ Implemented):
  - ✅ App bar: "Symptoms" with back button, consistent with health/weight screens:
    - `AppBar` with title "Symptoms"
    - Leading `IconButton` with `Icons.arrow_back_ios` (size 20)
    - `backgroundColor: Theme.of(context).colorScheme.inversePrimary`
    - Back button uses `context.pop()` for navigation
  - ✅ Body: Empty state (no charts/trends in V1):
    - `_buildEmptyState()` method with:
      - Large icon (`Icons.medical_services`, size 80) with primary color at 50% opacity
      - Title: "Track Your Pet's Symptoms" (using `AppTextStyles.h2`)
      - Description text about symptom tracking for CKD management (using `AppTextStyles.body` with `AppColors.textSecondary`)
      - "Log Your First Symptom" button that opens the dialog
    - Wrapped in `SingleChildScrollView` for scroll handling
  - ✅ **Floating Action Button**: "Add Symptoms" (using `HydraExtendedFab`, matching the weight screen pattern):
    - `HydraExtendedFab` with:
      - `icon: Icons.add`
      - `label: 'Add Symptoms'`
      - `backgroundColor: AppColors.primary`
      - `foregroundColor: AppColors.textPrimary`
      - `elevation: 0`
      - `useGlassEffect: true`
    - On press: Opens `SymptomsEntryDialog` via `OverlayService.showFullScreenPopup()`:
      - `_showAddSymptomsDialog()` method calls `OverlayService.showFullScreenPopup()`
      - `child: const SymptomsEntryDialog()` (no existing entry for add mode)
      - `animationType: OverlayAnimationType.slideUp`
    - ✅ FAB visibility: Hide when scrolling down, show when scrolling up (implemented):
      - `ScrollController` with `_handleScroll()` listener
      - Tracks `ScrollDirection.reverse` (hide) and `ScrollDirection.forward` (show)
      - `_showFab` boolean state controls FAB visibility
      - `floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling`
- **State Management** (✅ Implemented):
  - ✅ `ScrollController? _scrollController` - for scroll-based FAB visibility
  - ✅ `bool _showFab = true` - controls FAB visibility
  - ✅ Proper disposal of `ScrollController` in `dispose()`
- **Future**: Trends and history views will be added in a later phase once symptom logging is working.

**Note**: Symptom entries can be edited, but editing will be handled from the calendar (where fluid/medication entries are also edited), not from the symptoms screen itself. The V1 focus is on getting symptom logging working correctly.

### Step 4.2: Add Short-Term Trends (Recent 30 Days) - DEFERRED

**Goal**: Show a quick, low-cost overview of recent symptom burden using at most 30 `healthParameters` docs.

**Feature Tier**: ✅ **Free** (basic reassurance for all users)

**Status**: ⏸️ **Deferred to later phase** - Will be implemented after symptom logging is working correctly.

- On the Symptoms screen, add a simple **recent trend section**:
  - A compact chart or list summarizing the last 30 days, based on `getRecentHealth`.  
  - For V1, this might just be:
    - A row of colored dots or simple mini-bars per day showing computed overall status or normalized daily `symptomScoreAverage`.  
  - This uses **only a single 30-doc query**, which fits CRUD rules.

**Note**: Long-range trends (6+ months), comparative views, and correlation analytics are **Premium features** (see Free vs Premium section) and out of scope for V1.

### Step 4.3: Integrate Symptoms Card on Progress Screen - FREE ✅ COMPLETED

**Goal**: Surface symptom trends via a new card in the Progress insights list, driven purely by summaries.

**Feature Tier**: ✅ **Free** (basic monthly summary for all users)

**Implementation Status**: ✅ **COMPLETED**

- **Data Model Updates** (✅ Implemented):
  - ✅ Added `daysWithAnySymptoms: int` field to `MonthlySummary` model (defaults to 0)
  - ✅ Added `daysWithAnySymptoms: int` field to `WeeklySummary` model (defaults to 0) for symmetry
  - ✅ Updated all model methods: constructor, `empty()`, `fromJson()`, `toJson()`, `copyWith()`, `==`, `hashCode`, `toString()`
  - ✅ Added helper getter `hadSymptomsThisMonth` to `MonthlySummary` for future UI use
  - ✅ Updated Firestore schema documentation (`.cursor/rules/firestore_schema.md`) to document `daysWithAnySymptoms` in both weekly and monthly summaries sections

- **Symptom Aggregation Logic** (✅ Implemented):
  - ✅ Extended `_buildWeeklySummaryDeltas()` in `SymptomsService` to increment/decrement `daysWithAnySymptoms` based on `DailySummary.hasSymptoms` changes
  - ✅ Logic automatically applies to both weekly and monthly summaries (monthly delegates to weekly)
  - ✅ Uses `FieldValue.increment()` for atomic updates to avoid race conditions

- **Data Access Provider** (✅ Implemented):
  - ✅ Created `currentMonthSymptomsSummaryProvider` in `lib/providers/progress_provider.dart`
  - ✅ Provider watches `dailyCacheProvider` for automatic invalidation after symptom logs
  - ✅ Fetches current month's `MonthlySummary` using `SummaryService.getMonthlySummary()` (0-1 Firestore reads with 15-minute TTL cache)
  - ✅ Returns `null` early if user or pet is unavailable

- **Card placement** (✅ Implemented):
  - ✅ Added **"Symptoms"** `NavigationCard` to Progress screen insights list (below Weight card)
  - ✅ Uses `Icons.medical_services` icon
  - ✅ Reuses existing `NavigationCard` component for consistency

- **Card content** (✅ Implemented):
  - ✅ Metadata derived from `currentMonthSymptomsSummaryProvider`:
    - **Loading state**: "Loading symptom data…"
    - **No summary/error**: "No symptoms logged yet this month"
    - **With data**: "This month: X days with symptoms" (with proper pluralization: "day" vs "days")
  - ✅ Card shows dynamic count based on `summary.daysWithAnySymptoms` from monthly summary

- **Navigation** (✅ Implemented):
  - ✅ Tapping the card navigates to `/progress/symptoms` route
  - ✅ Route added to `lib/app/router.dart` using `AppPageTransitions.bidirectionalSlide` for consistency
  - ✅ Route name: `progress-symptoms`
  - ✅ Wired to `SymptomsScreen` component

- **Refresh Integration** (✅ Implemented):
  - ✅ Added `currentMonthSymptomsSummaryProvider` to Progress screen refresh handler invalidation list
  - ✅ Ensures card updates after pull-to-refresh

**Note**: Advanced analytics (correlations, long-range charts, vet exports) are **Premium features** and will be added later with feature gating.

### Step 4.4: Future-Friendly UX Notes

- The numeric 0–10 scale supports:
  - Later addition of **custom symptoms** (store in the `symptoms` map with dynamic keys) - **Premium feature**.  
  - More advanced “symptom burden” visuals without changing the underlying schema - **Premium feature** (long-range charts, correlations).

**Implementation Strategy**: Design the data model and summary structure to support premium features from the start, but implement only free features in V1. Premium features can be added later with feature flags/gating without requiring schema migrations.

---

## Phase 5 – Firestore Indexes & Cost Considerations

### Step 5.1: Index Strategy (On-Demand)

**Goal**: Only add indexes when real query patterns demand them, to keep maintenance low.

- **Indexes (to add only if needed)**:
  - Collection group `healthParameters`:
    - Composite index on `petId` + `date` (if used) + `hasSymptoms` for “recent symptom days” queries.  
  - For now, avoid premature indexing of individual symptom scores; rely on:
    - Short-range (≤30 days) reads + in-memory filtering.  
    - Summary docs for all long-range analytics.
### Step 5.2: Read/Write Cost Profile

- **Reads**:
- Daily logging: 0–1 reads (if you fetch existing doc) + 3 summary updates done **without** reading full summary histories (delta approach).  
  - Trends:
    - Recent: ≤30 reads from `healthParameters`.  
    - Monthly/weekly views: 1–12 reads from `treatmentSummaries/weekly|monthly/summaries`.
- **Writes**:
  - Per save/edit: 1 `healthParameters` doc + up to 3 summary docs in a single `WriteBatch`, fully aligned with the CRUD guideline on batching and avoiding tiny scattered writes.

---

## Phase 6 – Testing & Edge Cases

### Step 6.1: Unit Tests

- **Unit tests**:
  - `SymptomsService` score computation (total, average, hasSymptoms) for various slider configurations.  
  - Summary update logic: given old vs new daily entries, ensure weekly/monthly counts and scores are updated correctly via deltas.

### Step 6.2: Integration Tests

- **Integration tests** (similar to existing logging/weight tests):
  - Creating a first symptoms entry for a day also creates/updates daily, weekly, monthly summary docs with expected fields.  
  - Editing a day from “no symptoms” to “severe symptoms” correctly adjusts summary counts.  
  - Editing sliders back to N/A or 0 reduces counts and scores as expected.

### Step 6.3: UX Edge Cases

- **UX edge cases**:
  - Offline: writes are queued; last-write-wins semantics apply exactly as with weight tracking.  
  - Multiple edits same day: the last saved slider values define the final daily state and thus the summaries.  
  - No symptoms selected (all N/A/0): `hasSymptoms = false`, score fields null or 0, and daily/weekly/monthly summaries reflect “no symptoms” for that day.

---

## 7. High-Level Implementation Order (Checklist View)

1. **Phase 1 – Data model & schema**  
   - [x] Update `HealthParameter` to support `symptoms` map, helper flags and scores. ✅  
   - [x] Update `firestore_schema.md` to reflect new fields. ✅
2. **Phase 2 – Summaries**  
   - [x] Extend daily summary model with per-symptom booleans/max scores and overall scores. ✅  
   - [x] Extend weekly/monthly summaries with counts and aggregated scores. ✅  
   - [x] Implement delta-based summary updates in the same WriteBatch as `healthParameters`. ✅
3. **Phase 3 – Service layer**  
   - [x] Implement `SymptomsService` with CRUD, batching, and score helpers. ✅  
   - [x] Reuse summary path helpers / patterns; wire minimal analytics events. ✅
4. **Phase 4 – UI/UX**  
   - [x] Build `SymptomsEntryDialog` (full-screen popup using `LoggingPopupWrapper` with sliders, notes, save flow). ✅  
   - [x] Build minimal `SymptomsScreen` (app bar + FAB button to open dialog). ✅  
   - [x] Add the Symptoms card to the Progress screen, powered by summaries. ✅  
   - [ ] (Deferred) Add recent 30-day trends to Symptoms screen.
5. **Phase 5 – Indexes & costs**  
   - [ ] Review real query patterns; add targeted indexes only if needed.  
   - [ ] Verify read/write counts match CRUD expectations during manual testing.
6. **Phase 6 – Testing & polish**  
   - [ ] Add unit tests for score computation and summary deltas.  
   - [ ] Add integration tests for end-to-end logging + summaries.  
   - [ ] Run `flutter analyze` and `flutter test`, fix all issues before manual UX testing.

This phased breakdown mirrors the structure used in `progressBar_fluid.md`, making it easy to implement symptoms tracking step by step while staying aligned with your existing architecture and Firestore cost rules.
