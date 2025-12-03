# Lab Values Implementation Plan

Detailed plan to implement lab-result tracking per the schema review recommendations. Organized in phased steps that fit short Cursor/Claude Code work sessions.

---

## Phase 0 – Discovery & Alignment

1. **Confirm product expectations**
   - Re-read `.cursor/rules/firestore_schema.md`, PRD, and CRUD rules to ensure cost-saving measures align with new writes.
   - Validate UX touchpoints: onboarding, CKD profile, future analytics (calendar, summaries).
   - Capture product decision that all users (free + premium) now have full history access—remove any legacy 30-day gating from requirements and future rule changes.
   - Outcome: list of flows needing lab history (input, edit, view, analytics) plus confirmation that history must be available to every user tier.

2. **Inventory current data usage**
   - Locate every reference to `medicalInfo.labValues` (already found in onboarding/profile/services/tests) and note they all assume a single inline entry.
   - Document that current UI widgets (`LabValuesInput`, `LabValueDisplayWithGauge`), validators (`ProfileValidationService`, onboarding), and test builders all depend on this single value pattern.
   - Create a doc comment section in this planning file summarizing touchpoints for cross-reference in later phases.

---

## Phase 1 – Schema & Rules (Docs only, no code yet)

1. **Finalize Firestore structure**
   - Document final shape for `pets/{petId}/labResults/{labId}` including analytes, `values` map, metadata (`panelType`, `enteredBy`, `source`, `vetNotes`, `createdAt`, `updatedAt`).
   - Adopt future-proof structured analyzer storage: every `labResults` doc has a `values` map like
     ```
     "values": {
       "creatinine": { "value": 2.5, "unit": "mg/dL" },
       "bun": { "value": 60, "unit": "mg/dL" },
       "sdma": { "value": 15, "unit": "µg/dL" }
     }
     ```
     Optionally extend entries with `valueSi`, `valueUs`, or `enteredUnit` if/when dual-unit storage is required. Clients always convert to the canonical unit internally but Firestore captures what users entered.
   - Update schema doc to clarify canonical analyzer keys, how optional analytes fit in the `values` map, and how unit metadata enables toggling without schema churn.
   - Define denormalized snapshot field on pet (`medicalInfo.latestLabResult`) to cache last entry (store canonical values + preferred unit system to keep UI snappy).

2. **Security & indexes plan**
   - Describe rule updates: owner-only access already exists, but note need to validate immutable fields (prevent retro edits) using `resource.data` vs `request`.
   - Specify Firestore indexes required (per-pet orderBy testDate desc, optional composite for cross-pet dashboards).
   - No code change yet; just capture in doc for future PR.

Deliverable: updated text in `.cursor/rules/firestore_schema.md` + checklist for rule/index modifications when implementing.

---

## Phase 2 – Data Models & Services

1. **Create Dart models**
   - New immutable `LabResult` model (in `lib/features/profile/models/medical_info.dart` or dedicated file) with analytes, metadata, converters.
   - Each analyte stored as a `LabMeasurement` object (`value`, `unit`, optional `valueSi/valueUs`, `enteredUnit`); wrap them in a `Map<String, LabMeasurement>` to mirror Firestore’s `values` map.
   - Add helper to convert Firestore docs (`fromFirestore`/`toFirestore`) that handles the nested map structure and unit conversions when needed.
   - Introduce `LatestLabSummary` model (timestamp + values) if keeping `medicalInfo.labValues`.

2. **Update repositories/services**
   - Extend `PetService` (and any other Firestore data services) with:
     - `Future<LabResult> createLabResult(petId, LabResultInput)` (writes to subcollection + updates denormalized snapshot in batch/transaction). Ensure inputs capture unit selection so the `values` map records the user-entered unit.
     - `Stream<List<LabResult>> watchLabResults(petId, {limit})`.
   - Add caching/in-memory storage if needed, mirroring other subcollections.
   - Update validation services to include new structure (ensuring analyte > 0, date rules, etc.).

3. **Testing approach**
   - Plan unit tests for serialization + validation.
   - Note requirement to update existing tests that assumed `LabValues` only lived on `MedicalInfo`.

---

## Phase 3 – Onboarding Flow Integration

1. **Data gathering**
   - Keep current `LabValuesInput` UI; ensure it emits `LabValueData` plus optional vet notes once new fields available.

2. **Persisting first result**
   - Modify `OnboardingData.toCatProfile` (or final submission flow) to:
     - Build `LabResultInput` when lab data entered.
     - After creating pet profile, call new service method to write the lab result.
     - Update returned profile with refreshed `medicalInfo.latestLabSummary`.
   - Consider use of transaction/batch with profile creation to keep consistency if onboarding writes both.

3. **Validation updates**
   - Ensure onboarding validation errors still trigger for missing bloodwork date, positive numbers, etc.
   - Add coverage for new metadata fields if introduced (e.g., `panelType` optional).

4. **Manual testing steps (for later)**
   - Document steps the user should run (since we won’t run app): onboarding with lab inputs, confirm Firestore writes to both pet doc and `labResults`.

---

## Phase 4 – Profile Screen Enhancements

1. **Viewing history**
   - Add new UI section (likely in `CkdProfileScreen`) that lists past lab results (table/list). Reuse `LabValueDisplayWithGauge` for each entry.
   - Provide “View all labs” navigation if history grows (future backlog).

2. **Adding/updating labs**
   - When user taps “Edit lab values,” present form that either:
     - Adds a new `LabResult` entry (preferred, append-only).
     - Optionally allows editing the latest entry before finalizing (if requirement).
   - After save:
     - Call `createLabResult`.
     - Refresh profile provider to pull updated snapshot + list.

3. **State management**
   - Update Riverpod providers/selectors to expose:
     - `AsyncValue<List<LabResult>> labResultsProvider`.
     - Derived `latestLabResult` for display mode.
   - Ensure caching/refresh logic consistent with other profile data.

4. **UX details**
   - Display metadata (test date, vet notes).
   - Provide empty state guidelines (e.g., “No lab history yet. Add first result.”).

---

## Phase 5 – Backend Rules & Index Implementation

1. **Firestore rules**
   - Update `firestore.rules` to:
     - Keep owner read/write but enforce immutability for `testDate` and `createdAt`.
     - Validate analyte structure (numbers >= 0, optional map entries).
   - Add rule-level helper `isValidLabResult(data)` per CRUD guidelines.

2. **Indexes** ✅ COMPLETED
   - ✅ Updated `firestore.indexes.json` with required composite index:
     ```json
     {
       "collectionGroup": "labResults",
       "queryScope": "COLLECTION",
       "fields": [
         {
           "fieldPath": "testDate",
           "order": "DESCENDING"
         }
       ]
     }
     ```
   - **Manual deployment required**: After implementing the lab results feature in code, deploy the indexes using:
     ```bash
     firebase deploy --only firestore:indexes
     ```
   - **Note**: The index enables efficient queries for retrieving lab results sorted by test date (most recent first).
   - **Optional future enhancement**: A cross-pet query index using `metadata.enteredBy` and `testDate` is documented in the schema for premium analytics features.

3. **CI considerations**
   - Ensure new rule references covered by tests or manual verification plan.

---

## Phase 6 – Data Migration / Backfill

1. **One-time script**
   - Write Dart/Cloud Function script in `/scripts` to:
     - Iterate pets.
     - If `medicalInfo.labValues` populated, create a single `labResults` doc with that data (plus fallback metadata).
     - Set denormalized snapshot to new summary format.
   - Respect CRUD rules: use batched writes, limit throughput.

2. **Verification steps**
   - Collect before/after counts.
   - Provide instructions to run script manually (since automation may be out of scope now).

---

## Phase 7 – QA, Docs, & Handoff

1. **Testing checklist (for user to run)**
   - Onboarding with labs → Firestore entries exist.
   - Editing labs from profile → new history entry + UI refresh.
   - Viewing history, ensuring sorted order and gauge display.
   - Offline/poor network scenarios (ensure optimistic UI/caching).

2. **Documentation updates**
   - Update `.cursor/rules/firestore_schema.md` with final schema.
   - Document provider usage and new service APIs in relevant README/ARCH doc.
   - Add quick-start snippet on how to query lab history for analytics.

3. **Post-implementation validations**
   - Run `flutter analyze` (per instructions) after code changes.
   - Confirm approach matches industry standards (append-only historical data + denormalized latest summary).

---

## Open Questions / Follow-Ups

- Do we require edit/delete capabilities for historical lab entries, or should they be immutable?
- Any future analytes or integrations (e.g., CSV import) we should keep in mind for schema flexibility?
- Should lab entries feed into treatment summaries automatically (future task)?

Capture answers in this doc before implementation to avoid rework.
