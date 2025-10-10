# Logging System Cost & Performance Optimisation

## 🚨 CRITICAL Opportunities (High ROI, Low/Moderate Complexity)

### 1) Quick‑log summary writes scale linearly with sessions
- **Status**: ✅ Implemented (aggregate writes + guardrail)
- **Files**: `lib/features/logging/services/logging_service.dart` (quickLogAllTreatments, _addMedicationSessionToBatch, _addFluidSessionToBatch)
- **Current**: For each generated session, we add 3 summary writes (daily/weekly/monthly) using `SetOptions(merge: true)` with `FieldValue.increment()`. With N sessions, this is `N session writes + 3N summary writes`.
- **Impact**: When quick‑logging multiple reminders (e.g., 6–12/day), summary writes dominate Firestore write count and cost. Also approaches the 500‑ops batch limit sooner.
- **Optimisation**: Aggregate summary deltas in memory for the whole quick‑log, then perform exactly 3 summary writes total (daily/weekly/monthly) for the batch, alongside the N session writes.
  - Resulting cost: `N session writes + 3 summary writes` (instead of `4N`).
  - This uses the same `FieldValue.increment()` map, but computed once from the union of all sessions.
- **Why safe**: Sessions are still written individually (full audit history). Summaries are, by design, additive aggregates—associativity holds.
- **Est. savings**: For 8 sessions/day: from 32 writes → 11 writes (~66% fewer writes during quick‑log).
- **Notes**: Keep single‑session flow as‑is (4 writes) to avoid complexity where benefit is small.
  - Added guardrail: If total ops would exceed Firestore’s 500 limit, chunk session writes across multiple batches; summaries are written once in the first batch.

### 2) Ensure composite index for duplicate detection query
- **Files**: `lib/features/logging/services/logging_service.dart:getTodaysMedicationSessions`
- **Status**: ✅ Verified in console; no additional index needed.
- **Index spec (current)**: `medicationSessions` composite on `medicationName` (eq), `dateTime` (desc), `__name__` (desc).
- **When to add another index**:
  - If we switch to `orderBy('dateTime', ascending: true)`.
  - If we add extra filters/orderBys (e.g., `completed == true`).
  - If we run a collection group query across all `medicationSessions`.
- **Action**: Document the index spec in the repo and keep a brief note near the query.

## ⚠️ HIGH‑Priority (Worth doing; moderate complexity or risk mitigation)

### 3) Batch size guardrails for quick‑log
- **Status**: ✅ Implemented
- **Files**: `lib/features/logging/services/logging_service.dart:quickLogAllTreatments`, `_commitQuickLogInChunks`
- **What we added**: If `N sessions + 3` exceeds Firestore’s 500‑op limit, we split writes into multiple batches; summaries are written once in the first batch only.
- **Threshold**: Uses total‑ops estimate (`totalSessions + 3`). Single‑batch path otherwise.

### 4) Timestamp storage consistency for sessions
- **Files**: `lib/features/logging/models/(medication_session|fluid_session).dart`
- **Current**: `dateTime` stored as ISO‑8601 string via `toIso8601String()`; queries compare strings (works lexicographically for ISO format). Parsing supports both Timestamp and String.
- **Trade‑off**: Strings work and are simple; Timestamps are more robust for time zones/DST and enable native range queries, but migration is required for existing docs.
- **Balanced recommendation**:
  - Short term: Keep strings to avoid migration. Standardise on UTC for all new writes (`toUtc().toIso8601String()`) and compute `startOfDay` in UTC for the duplicate‑check query for consistency.
  - Long term (only if needed): Migrate to Firestore `Timestamp` for session times; adjust query to use `Timestamp` range. Keep dual‑read parsing for backward compatibility.

## 🔧 MEDIUM‑Priority (Noticeable impact, low risk)

### 5) Zero‑read duplicate detection via enriched local cache
- **Status**: ✅ Implemented
- **Files**: `lib/features/logging/models/daily_summary_cache.dart`, `lib/features/logging/services/summary_cache_service.dart`, `lib/providers/logging_provider.dart`, `lib/features/logging/models/medication_session.dart`
- **What we added**:
  - Cache now stores `medicationRecentTimes: Map<String, List<String>>` (ISO strings) for today, bounded to last 8 entries per medication.
  - Cache service APIs: `getRecentTimesForMedication`, `isLikelyDuplicate` (±15min window).
  - Provider uses zero‑read window check; on match, returns a synthetic session and skips Firestore. Falls back to Firestore only when cache can’t decide.
- **Impact**: Eliminates most duplicate‑check reads for frequently logged meds while preserving correctness.
- **Notes**: Cache remains ephemeral (per‑day); no migrations.

### 6) Cache today/this‑week/this‑month summaries for active views
- **Status**: ✅ Implemented (in‑memory TTL cache)
- **Files**: `lib/features/logging/services/summary_service.dart`
- **What we added**: In‑memory TTL caches for daily (5m), weekly (15m), monthly (15m) keyed by user/pet/date. Methods return cached values when valid, falling back to Firestore on miss.
- **Impact**: Reduces repeated reads while navigating analytics; no data model changes.

### 7) `getTodaySummary` cache‑only mode for light UI
- **Status**: ✅ Implemented
- **Files**: `lib/features/logging/services/summary_service.dart:getTodaySummary`
- **What we added**: Optional `lightweight: true` parameter. When cache exists, builds a lightweight `DailySummary` from cache (counts/totals) with 0 reads; otherwise falls back to Firestore.
- **Impact**: Saves a read on cold start and simple displays; default behavior unchanged when `lightweight` is false.

## 💡 LOW‑Priority (Polish/consistency)

### 8) Server timestamps for `createdAt/updatedAt` in sessions
- **Status**: ✅ Implemented (service-level override)
- **Files**: `lib/features/logging/services/logging_service.dart`
- **What we added**: Session writes now flow through `_buildSessionCreateData`, which sets `createdAt` if missing and always sets `updatedAt` using `FieldValue.serverTimestamp()`.
- **Impact**: Consistent audit timestamps across devices; no model changes.

### 9) Implementation notes for future history screens
- **When building history lists**: follow rules in `@firebase_CRUDrules.md`:
  - Use `.limit()` and paginate with `startAfter`.
  - Filter precisely by `petId` (already implicit in path), date ranges, and medication when needed.
  - Avoid `snapshots()` on full history; at most listen to the most recent 1–5 docs if live updates are necessary.

---

## Compliance with `@firebase_CRUDrules.md`
- **Paginate large queries**: No current history list fetching; add pagination when implemented (Low‑9).
- **Avoid unnecessary re‑reads**: Daily cache implemented; extend with `lastLoggedAt` (Medium‑5). Consider weekly/monthly caching (Medium‑6).
- **Restrict real‑time listeners**: None detected in logging flows—good.
- **Filter precisely**: Duplicate query filters by medication + date and limits 10—good; ensure composite index (Critical‑2).
- **No full‑history fetch for analytics**: Summaries are used for analytics—good.
- **Offline persistence**: Enabled in `FirebaseService`—good.
- **Batch writes**: All writes use `WriteBatch`—good; aggregate quick‑log summaries (Critical‑1).
- **Avoid tiny frequent writes**: Incremental summary writes are batched; aggregation further reduces count (Critical‑1).

---

## Implementation Priority
- **Phase 1 (Critical)**
  1) Aggregate quick‑log summary increments to 3 writes total — ✅ Done
  2) Add composite index for duplicate detection query
- **Phase 2 (High)**
  3) Add batch safety chunking when near 500 operations — ✅ Done
  4) Standardise on UTC for session `dateTime` strings (no migration)
- **Phase 3 (Polish)**
  5) Enrich cache with `lastLoggedAt` per medication
  6) Add weekly/monthly lightweight cache with TTL
  7) Add `lightweight` mode to `getTodaySummary`
  8) Prefer server timestamps for session audit fields

---

## Test & Verification Plan
- Quick‑log with 8–12 generated sessions: verify writes reduced to `N + 3` and summaries correct.
- Duplicate detection with/without cache: ensure 0‑read fast path works; fallbacks capped to 10 reads.
- Batch limit test: simulate 120+ reminders, verify chunking and idempotent outcome.
- Mixed time zones: with UTC standardisation, ensure daily filters still correct at midnight boundaries.
- Weekly/monthly cache TTL: repeated openings of analytics views don’t trigger extra reads within TTL.

---

## File Pointers (for reference)
- `lib/features/logging/services/logging_service.dart`: quick‑log batching, duplicate query, summary increment builders.
- `lib/providers/logging_provider.dart`: cache lifecycle, offline handling, duplicate check flow.
- `lib/features/logging/services/summary_cache_service.dart`: SharedPreferences cache schema.
- `lib/features/logging/services/summary_service.dart`: daily/weekly/monthly reads.
- `lib/shared/models/(daily|weekly|monthly)_summary.dart`: models for summaries.
