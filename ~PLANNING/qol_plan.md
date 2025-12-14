# HydraCAT Quality of Life (QoL) Tracking - Implementation Plan

---

## Overview

Implement a scientifically-grounded, longitudinal quality of life tracking system for cats with CKD. The feature consists of a 14-question owner-reported assessment covering 5 equally-weighted domains (Vitality, Comfort, Emotional, Appetite, Treatment Burden), with automated scoring, trend visualization, and home screen integration.

**Key Characteristics:**
- 14 questions with question-specific 0-4 response scales (no generic labels)
- 7-day recall period for all questions
- ~2-3 minute completion time
- One assessment per day maximum (document ID = date)
- Free feature for all users (premium gating deferred to future iteration)
- Export functionality deferred to future comprehensive export feature

---

## 0. Coherence & Constraints

### Scientific Foundation

HydraCAT's QoL assessment is informed by published psychometric research on feline health-related quality of life, including:

- **Bijsmans et al. (2016)** - CatQoL: 16-item, 4-domain instrument validating owner-reported QoL assessment
- **Lorbach et al. (2022)** - VetMetrica: 20-item, 3-domain instrument demonstrating QoL measurement reliability
- **Wright et al. (2025)** - 13-item unidimensional CKD-specific instrument with strong psychometric properties

**Key Scientific Insights:**
- Owner-reported QoL assessment is valid and reliable for cats with CKD (Wright 2025, Bijsmans 2016)
- Multi-domain structure provides actionable clinical insights (Bijsmans 2016, Lorbach 2022)
- 7-day recall period balances reliability and caregiver burden (Wright 2025)
- Observable behaviors (energy, mood, appetite) have high factor loadings (Wright 2025: 0.73-0.94)
- Treatment burden significantly impacts QoL (Bijsmans 2016)

**Our Unique Contribution:**
- **Treatment Burden domain** is unique to HydraCAT (not in Wright 2025 or Lorbach 2022)
- Focus on **longitudinal tracking** vs snapshot assessment (complements clinical trial instruments)
- **5-domain structure** provides specific intervention guidance while maintaining overall score
- Optimized for **mobile app engagement** (2-3 minute completion, auto-advance UI)

### PRD Alignment
- Directly supports "Health Monitoring & Insights" pillar from PRD
- Provides emotionally meaningful tracking that reduces caregiver anxiety
- Vet-friendly data collection (shareable summaries for clinical discussions)
- No diagnostic claims - focuses on trends and observable behaviors only

### Firebase & CRUD Rules
- **One assessment per day**: Document ID = `YYYY-MM-DD` prevents duplicate daily entries
- **Batch writes**: Each save updates 4 documents atomically (assessment + daily/weekly/monthly summaries)
- **Cost-optimized reads**:
  - Home screen: 0 additional reads (uses cached latest assessment)
  - History screen: Paginated queries with `.limit(20)`
  - Trend analysis: Last 12 assessments maximum (~3 months)
  - Real-time listeners: None (use cache-first strategy with 5-minute TTL)
- **Summary-first analytics**: Weekly/monthly trend data computed from cached daily summaries, not full assessment history
- **Offline persistence**: Enabled for Firestore to reduce redundant reads

### Architecture Fit
- Reuses existing patterns from **symptoms tracking** (`HealthParameter`, `SymptomsService`, `SymptomsEntryDialog`)
- Leverages **fl_chart** library (already present) for radar and line charts
- Follows **domain-driven design** with feature folder: `lib/features/qol/`
- State management via **Riverpod** with cache-first strategy
- Integrates with existing **summary system** (daily/weekly/monthly summaries)
- Uses established **UI components** (HydraCard, HydraButton, HydraAppBar, etc.)

### Design Decisions from Clarifying Questions
1. **Home screen positioning**: QolHomeCard appears after treatment cards, before "More Insights" navigation section
2. **Empty state**: Show QolHomeCard from day 1 with CTA to encourage adoption
3. **Progress persistence**: Do NOT save in-progress assessments; show confirmation dialog on exit
4. **Edit access**: Primary via "Edit" button on detail screen; secondary via long-press on history cards
5. **Historical editing**: Allow editing any past assessment (no time restriction); preserve `createdAt`, update `updatedAt`
6. **Low confidence domains**: Display with dotted lines on radar chart at 50% opacity; show "Based on X/5 domains" badge
7. **Reverse scoring**: REMOVED - all questions use semantic scales where higher score = better QoL (no code reversal needed)
8. **Partial domain scores**: Show "Insufficient data" badge instead of unreliable numbers when <50% answered
9. **First-time experience**: No tutorial overlay; clear empty state messaging; success snackbar suggests weekly cadence
10. **Analytics timing**: `assessment_started` on screen open; `question_answered` on page advance (not every slider drag)
11. **Radar chart edge cases**: Fixed 0-100 scale; show empty pentagon if all null responses; abbreviated labels on compact variant

---

## 1. Finalized Question Set (14 Questions)

### Domain: Vitality (3 questions)

**Question ID**: `vitality_1`
**Order**: 0
**Text**: In the past 7 days, how would you describe your cat's overall energy level compared to their usual self?
**Response Scale**:
- 0 – Much lower than usual (very sleepy, hardly active)
- 1 – Lower than usual (noticeably less active)
- 2 – About the same as usual
- 3 – A bit higher than usual
- 4 – Much higher than usual (very lively and active)

**Question ID**: `vitality_2`
**Order**: 1
**Text**: In the past 7 days, how often did your cat get up, walk around, or explore on their own instead of staying in one place?
**Response Scale**:
- 0 – Almost never (stayed in one place most of the time)
- 1 – Rarely (only got up a few times each day)
- 2 – Sometimes (mixed between resting and moving)
- 3 – Often (regularly moved around during the day)
- 4 – Very often (frequently exploring or changing spots)

**Question ID**: `vitality_3`
**Order**: 2
**Text**: In the past 7 days, how often did your cat show interest in play, toys, or interacting with objects around them?
**Response Scale**:
- 0 – Never (showed no interest at all)
- 1 – Rarely (once or twice all week)
- 2 – Sometimes (a few times during the week)
- 3 – Often (regularly showed interest)
- 4 – Very often (frequently engaged with toys or play)

---

### Domain: Comfort (3 questions)

**Question ID**: `comfort_1`
**Order**: 3
**Text**: In the past 7 days, how comfortable did your cat seem when moving, jumping, or changing position?
**Response Scale**:
- 0 – Very uncomfortable (often struggled or seemed in pain)
- 1 – Uncomfortable (noticeable difficulty or stiffness)
- 2 – Somewhat comfortable (a little stiff but mostly coping)
- 3 – Comfortable (moves well with only mild issues)
- 4 – Very comfortable (moves freely with no visible problems)

**Question ID**: `comfort_2`
**Order**: 4
**Text**: In the past 7 days, how often did you notice signs like stiffness, limping, or hesitation to jump up or down?
**Response Scale**:
- 0 – Every day or almost every day
- 1 – Several times this week
- 2 – Once or twice this week
- 3 – Rarely (only once or twice this month)
- 4 – Not at all in the past 7 days

**Question ID**: `comfort_3`
**Order**: 5
**Text**: In the past 7 days, did your cat show signs of discomfort when using the litter box (straining, vocalizing, or spending a long time)?
**Scientific Rationale**: Wright 2025 excluded defecation issues due to ceiling effects, but Lorbach 2022 found cats with constipation had significantly lower comfort scores (P=0.0003). This refined wording focuses on observable discomfort rather than stool characteristics, aligning with HRQoL measurement principles.
**Response Scale**:
- 0 – Very often (showed clear discomfort most times)
- 1 – Often (frequently showed signs of discomfort)
- 2 – Sometimes (occasional signs of discomfort)
- 3 – Rarely (only once or twice this week)
- 4 – Not at all (used litter box comfortably all week)

**Question ID**: `comfort_4`
**Text**: In the past 7 days, how would you describe your cat's coat condition?
**Scientific Rationale**: Wright 2025 found coat condition had 0.67 factor loading - a moderate indicator of self-care and physical wellbeing.
**Response Scale**:
- 0 – Very dull, matted, or unkempt (not grooming properly)
- 1 – Noticeably less shiny or tidy than usual
- 2 – About the same as usual
- 3 – Healthy and well-groomed
- 4 – Exceptionally shiny and well-maintained
**Domain**: Comfort
**Implementation Consideration**: Medium effort, medium benefit. Defer to V2 based on user feedback and validation data.

---

### Domain: Emotional (3 questions)

**Question ID**: `emotional_1`
**Order**: 6
**Text**: In the past 7 days, how would you describe your cat's overall mood?
**Response Scale**:
- 0 – Very low (seemed miserable or very unhappy most of the time)
- 1 – Low (often seemed unhappy or dull)
- 2 – Neutral (neither especially unhappy nor especially happy)
- 3 – Generally happy (seemed content most of the time)
- 4 – Very happy (bright, cheerful, and engaged most of the time)

**Question ID**: `emotional_2`
**Order**: 7
**Text**: In the past 7 days, how often did your cat seek contact with you (coming to you, asking for attention, or being near you)?
**Response Scale**:
- 0 – Never (did not seek contact at all)
- 1 – Rarely (once a day or less)
- 2 – Sometimes (a few times a day)
- 3 – Often (regularly during the day)
- 4 – Very often (actively seeks you out many times a day)

**Question ID**: `emotional_3`
**Order**: 8
**Text**: In the past 7 days, how often did your cat hide away or seem more withdrawn than usual?
**Response Scale**:
- 0 – Much more than usual (hid or stayed away most of the time)
- 1 – More than usual (clearly hiding or withdrawn)
- 2 – About the same as usual
- 3 – Less than usual (slightly more visible and present)
- 4 – Much less than usual (very rarely hiding or withdrawn)

---

### Domain: Appetite (3 questions)

**Question ID**: `appetite_1`
**Order**: 9
**Text**: In the past 7 days, how would you describe your cat's appetite overall?
**Response Scale**:
- 0 – Almost no appetite (hardly eating anything)
- 1 – Very poor appetite (eating much less than usual)
- 2 – Reduced appetite (eating somewhat less than usual)
- 3 – Normal appetite (eating about their usual amount)
- 4 – Very good appetite (keen to eat, may ask for more)

**Question ID**: `appetite_2`
**Order**: 10
**Text**: In the past 7 days, how often did your cat finish most of their main meals?
**Response Scale**:
- 0 – Almost never (left most of each meal)
- 1 – Rarely (finished less than half of meals)
- 2 – Sometimes (finished about half of meals)
- 3 – Often (finished most meals)
- 4 – Almost always (finished nearly every meal)

**Question ID**: `appetite_3`
**Order**: 11
**Text**: In the past 7 days, how interested was your cat in treats or favorite foods?
**Response Scale**:
- 0 – Not interested at all (refused or ignored them)
- 1 – Slightly interested (occasionally accepted, often refused)
- 2 – Moderately interested (accepted some, refused some)
- 3 – Very interested (usually keen to take them)
- 4 – Extremely interested (actively asks for or searches for them)

---

### Domain: Treatment Burden (2 questions)

**Question ID**: `treatment_1`
**Order**: 12
**Text**: In the past 7 days, how easy or difficult was it to give your cat their CKD treatments (subcutaneous fluids, pills, liquid medications, etc.)?
**Response Scale**:
- 0 – Extremely difficult (usually failed or very stressful for both)
- 1 – Difficult (needed a lot of effort or caused clear distress)
- 2 – Manageable (sometimes a struggle but usually possible)
- 3 – Easy (minor resistance but generally straightforward)
- 4 – Very easy (your cat accepts treatments calmly)

**Question ID**: `treatment_2`
**Order**: 13
**Text**: In the past 7 days, how stressed did your cat seem about treatments or being handled for their CKD care?
**Response Scale**:
- 0 – Extremely stressed (panics, fights, or freezes every time)
- 1 – Very stressed (clearly upset most times)
- 2 – Moderately stressed (shows some stress but copes)
- 3 – Slightly stressed (a bit tense but settles quickly)
- 4 – Not at all stressed (relaxed or only minimally bothered)

---

### Optional Refinement: "Appeared Tired" Clarity (P3 Priority)

Wright 2025 found "appeared tired" had the highest factor loading (0.94). This concept is partially covered by vitality_1 ("energy level"), but could be strengthened with more explicit "tiredness" language if validation data shows gaps. Defer to post-launch psychometric analysis.

---

## 2. Legal Safeguards & Compliance

### Required Attributions

**In Documentation** (README, about screen, website):
```
HydraCAT's Quality of Life assessment is informed by published psychometric
research on feline health-related quality of life, including studies by
Bijsmans et al. (2016), Lorbach et al. (2022), and Wright et al. (2025).
This tool is independently developed and is not affiliated with or endorsed
by the authors of these studies.
```

**In-App Disclaimer** (on every QoL screen footer):
```
This tool tracks quality of life trends over time for your reference.
It is not a diagnostic instrument and does not replace veterinary care.
Always consult your veterinarian for medical decisions.
```

### Legal Compliance Checklist

**Naming:**
- ✅ Use "HydraCAT Quality of Life Assessment" or "HydraCAT QoL"
- ❌ Do NOT use "CatQoL" (Bijsmans trademark)
- ❌ Do NOT use "VetMetrica" (proprietary)
- ❌ Do NOT use "Feline CKD HRQoL Questionnaire" (Wright title)

**Development Independence:**
- ✅ Document question development process (this plan serves as evidence)
- ✅ Maintain records of design decisions (documented in clarifying questions section)
- ✅ No verbatim copying of question wording (verified in comprehensive analysis: 8 of 14 questions have no direct Wright equivalent, 6 share concepts only)

**Risk Assessment:** LOW RISK
- Question wording is sufficiently distinct from all published instruments
- Multi-domain structure differs from Wright's unidimensional approach
- Treatment Burden domain is unique to HydraCAT
- Application context (consumer mobile app) differs from clinical trial instruments

### Optional Legal Review

**Recommendation:** Consider IP attorney consultation ($500-1000) before app store submission to obtain documented legal opinion. This provides:
- Written assurance of copyright compliance
- Evidence of due diligence if challenged
- Peace of mind for stakeholders

---

## 3. Data Model Design

### Phase 2.1: Core Models (Week 1, Day 1-2)

**Goal**: Create immutable data models for QoL assessments with validation and computed properties.

#### Step 2.1.1: QoL Domain Constants

**File**: `lib/features/qol/models/qol_domain.dart` (new)

**Implementation**:
- Create immutable `QolDomain` class with private constructor (follows `SymptomType` pattern)
- Define 5 domain string constants: `vitality`, `comfort`, `emotional`, `appetite`, `treatmentBurden`
- Provide `all` list in canonical order
- Create maps for display name keys, description keys, and question counts per domain
- Add `isValid()` helper method for validation
- No enum - use string constants for Firestore compatibility

**Testing**: Unit test validating all constants and helper methods.

---

#### Step 2.1.2: QoL Question Model with Response Labels

**File**: `lib/features/qol/models/qol_question.dart` (new)

**Implementation**:
- Create immutable `QolQuestion` class with fields:
  - `id` (String) - e.g., "vitality_1"
  - `domain` (String) - from QolDomain constants
  - `textKey` (String) - localization key for question text
  - `responseLabelKeys` (Map<int, String>) - localization keys for 0-4 response labels
  - `order` (int) - display order 0-13
- **IMPORTANT**: Remove `isReverseScored` flag (not needed with semantic scales)
- Define all 14 questions as compile-time constants in `QolQuestion.all` list
- Each question includes all 5 response label keys (e.g., `{0: 'qolVitality1Label0', 1: 'qolVitality1Label1', ...}`)
- Add helper methods: `getById(String id)`, `getByDomain(String domain)`
- Follow exact question set from Section 1 above

**Example**:
```dart
const QolQuestion(
  id: 'vitality_1',
  domain: QolDomain.vitality,
  textKey: 'qolQuestionVitality1',
  responseLabelKeys: {
    0: 'qolVitality1Label0',
    1: 'qolVitality1Label1',
    2: 'qolVitality1Label2',
    3: 'qolVitality1Label3',
    4: 'qolVitality1Label4',
  },
  order: 0,
),
```

**Testing**: Unit test verifying all 14 questions are defined correctly, IDs unique, domains valid, orders sequential.

---

#### Step 2.1.3: QoL Response Model

**File**: `lib/features/qol/models/qol_response.dart` (new)

**Implementation**:
- Create immutable `QolResponse` class with fields:
  - `questionId` (String)
  - `score` (int?) - null = "Not sure", 0-4 = severity
- Add `isAnswered` getter returning `score != null`
- Implement `fromJson` and `toJson` for Firestore serialization
- Override `==`, `hashCode`, and `toString`
- Simple value object - no complex logic

**Testing**: Unit test serialization, equality, null handling.

---

#### Step 2.1.4: QoL Assessment Model (Core)

**File**: `lib/features/qol/models/qol_assessment.dart` (new)

**Implementation**:
- Create immutable `QolAssessment` class with fields:
  - `id` (String) - UUID v4
  - `userId` (String)
  - `petId` (String)
  - `date` (DateTime) - normalized to midnight
  - `responses` (List<QolResponse>)
  - `createdAt` (DateTime)
  - `updatedAt` (DateTime?)
  - `completionDurationSeconds` (int?) - null if edited
- Add computed getters:
  - `documentId` - returns `YYYY-MM-DD` format using `AppDateUtils.formatDateForSummary()`
  - `isToday` - using `AppDateUtils.isToday()`
  - `isComplete` - true if answeredCount == 14
  - `answeredCount` - count of responses where `isAnswered == true`
  - `unansweredCount` - 14 - answeredCount
  - `answeredCountByDomain` (Map<String, int>) - per-domain counts
- Add domain scoring methods:
  - `getDomainScore(String domain)` returns `double?` (0-100 scale)
    - Returns null if <50% of domain questions answered (low confidence)
    - Calculate mean of answered items in domain (no reverse scoring needed!)
    - Convert 0-4 scale to 0-100: `(mean / 4.0) * 100.0`
  - `domainScores` getter returns Map<String, double?> for all 5 domains
  - `overallScore` getter returns `double?` (mean of valid domain scores, null if any domain has low confidence)
  - `scoreBand` getter returns String? ('veryGood', 'good', 'fair', 'low' based on overall score thresholds: ≥80, ≥60, ≥40, <40)
  - `hasLowConfidenceDomain` getter checks if any domain <50% answered
- Add validation method returning List<String> of errors:
  - Date not in future
  - All scores 0-4 or null
  - All questionIds valid
  - No duplicate questionIds
- Add factory constructors:
  - `QolAssessment.empty()` - creates blank assessment for given user/pet/date
  - `QolAssessment.fromJson()` - parses Firestore document (handle Timestamp conversion)
- Add instance methods:
  - `toJson()` - serializes to Firestore (include all fields, use Timestamp for dates)
  - `copyWith()` - using sentinel `_undefined` pattern for nullable fields
- Override `==`, `hashCode`, `toString` for all fields including responses list

**Testing**:
- Unit tests for domain score calculation with various completion percentages
- Low confidence detection (<50% threshold)
- Overall score calculation (requires all 5 domains valid)
- Score band classification
- Validation edge cases (future dates, invalid scores, duplicate responses)
- JSON serialization round-trip

---

#### Step 2.1.5: QoL Trend Summary Model

**File**: `lib/features/qol/models/qol_trend_summary.dart` (new)

**Implementation**:
- Lightweight immutable model for chart consumption (not stored in Firestore)
- Fields:
  - `date` (DateTime)
  - `domainScores` (Map<String, double>) - only valid scores (no nulls)
  - `overallScore` (double)
  - `assessmentId` (String?)
- Add helper methods:
  - `deltaOverall(QolTrendSummary other)` - returns difference in overall score
  - `deltaDomain(String domain, QolTrendSummary other)` - returns domain-specific delta (null if either missing)
- Override `==`, `hashCode`, `toString`
- Computed on-demand from `QolAssessment` list, never written to Firestore

**Testing**: Unit test delta calculations, equality.

---

#### Step 2.1.6: QoL Exceptions

**File**: `lib/features/qol/exceptions/qol_exceptions.dart` (new)

**Implementation**:
- Define custom exception classes:
  - `QolException` (base class) extending `Exception`
  - `QolValidationException` - for validation errors (invalid scores, future dates, etc.)
  - `QolServiceException` - for Firestore operation errors
- Each exception includes `message` field and `toString()` override
- Follow pattern from `lib/features/health/exceptions/health_exceptions.dart`

**Testing**: Not critical (simple exception classes), but can add basic instantiation tests.

---

### Phase 2.2: Daily Summary Integration (Week 1, Day 2-3)

**Goal**: Extend `DailySummary` model to include QoL fields for home screen and trend analysis without additional reads.

#### Step 2.2.1: Add QoL Fields to DailySummary Model

**File**: `lib/shared/models/daily_summary.dart` (modify)

**Implementation**:
- Add new fields to `DailySummary` class (following symptom pattern):
  - `qolOverallScore` (double?) - nullable, 0-100 scale
  - `qolVitalityScore` (double?) - nullable, 0-100 scale
  - `qolComfortScore` (double?) - nullable, 0-100 scale
  - `qolEmotionalScore` (double?) - nullable, 0-100 scale
  - `qolAppetiteScore` (double?) - nullable, 0-100 scale
  - `qolTreatmentBurdenScore` (double?) - nullable, 0-100 scale
  - `hasQolAssessment` (bool) - default false
- Update constructor to accept new fields with defaults (nulls for scores, false for boolean)
- Update `empty()` factory - new fields use constructor defaults
- Update `fromJson()` factory:
  - Parse all score fields with null safety: `(json['qolOverallScore'] as num?)?.toDouble()`
  - Parse boolean using existing `asBool()` helper
  - Backward compatible (missing fields = null/false)
- Update `toJson()` method:
  - Conditionally include score fields (only if non-null to save bytes)
  - Always include `hasQolAssessment` boolean
- Update `copyWith()` method using `_undefined` sentinel pattern for all nullable QoL fields
- Update `==`, `hashCode`, `toString` to include all new fields

**Firestore Schema Update**: Document in `.cursor/rules/firestore_schema.md` under daily summaries section.

**Testing**: Unit tests for serialization, copyWith with QoL fields, backward compatibility with old documents.

---

### Phase 2.3: Firebase Schema Documentation (Week 1, Day 3)

**Goal**: Document complete Firestore schema for QoL feature to maintain coherence.

#### Step 2.3.1: Update Firestore Schema Documentation

**File**: `.cursor/rules/firestore_schema.md` (modify)

**Implementation**:
- Add new collection documentation:
  ```
  users/{userId}/pets/{petId}/qolAssessments/{YYYY-MM-DD}
    - id: string (UUID v4)
    - userId: string
    - petId: string
    - date: Timestamp
    - responses: array[
        {questionId: string, score: int | null}
      ]
    - createdAt: Timestamp
    - updatedAt: Timestamp (optional)
    - completionDurationSeconds: int (optional, null if edited)
  ```
- Update existing daily summaries section with QoL fields (already done in Phase 2.2.1)
- Note cost optimization strategy: "QoL scores denormalized into daily summaries for zero-read home screen and trend display"

**Testing**: None (documentation only).

---

## 3. Service Layer Implementation

### Phase 3.1: QoL Scoring Service (Week 1, Day 3-4)

**Goal**: Create pure business logic service for scoring and trend calculations (no Firebase dependencies).

#### Step 3.1.1: Create QoL Scoring Service

**File**: `lib/features/qol/services/qol_scoring_service.dart` (new)

**Implementation**:
- Create `QolScoringService` class (no constructor parameters - pure functions)
- Implement methods:
  - `calculateDomainScore(String domain, List<QolResponse> responses)` returns `double?`
    - Get questions for domain using `QolQuestion.getByDomain()`
    - Filter responses to domain's questions
    - Return null if <50% answered
    - Calculate mean of answered scores (0-4 scale)
    - Convert to 0-100 scale: `(mean / 4.0) * 100.0`
    - **No reverse scoring logic** (all questions semantic)
  - `calculateOverallScore(QolAssessment assessment)` returns `double?`
    - Get all domain scores from assessment
    - Return null if any domain is null (low confidence)
    - Return mean of 5 valid domain scores
  - `TrendStability calculateTrendStability(List<QolTrendSummary> recentTrends)` returns enum
    - Enum values: `stable`, `improving`, `declining`
    - Requires ≥3 trend points
    - Use linear regression or simple slope calculation on overall scores
    - Threshold: slope >+5/month = improving, <-5/month = declining, else stable
  - `bool hasNotableChange(List<QolTrendSummary> recentTrends, String domain)`
    - Detects ≥15 point drop in domain score
    - Sustained across ≥2 consecutive assessments
    - Returns false if <3 trend points
  - `String? generateInterpretationMessage(QolTrendSummary current, QolTrendSummary? previous, BuildContext context)`
    - Returns localized interpretation key based on:
      - Overall score delta (previous → current)
      - Notable changes in specific domains
      - Trend stability
    - Return null if no previous assessment (first assessment case)
    - Examples: 'qolInterpretationStable', 'qolInterpretationImproving', 'qolInterpretationDeclining'

**Testing**:
- Unit tests for all scoring methods with various data scenarios
- Edge cases: all null responses, partial responses, exact 50% threshold, notable change detection
- Trend stability calculation with improving/declining/stable datasets

---

### Phase 3.2: QoL Service (Firebase CRUD) (Week 1, Day 4-5)

**Goal**: Implement Firebase CRUD operations with batch writes for cost optimization.

#### Step 3.2.1: Create QoL Service

**File**: `lib/features/qol/services/qol_service.dart` (new)

**Implementation**:
- Create `QolService` class with constructor accepting optional `FirebaseFirestore` and `AnalyticsService`
- Organize into sections (following `SymptomsService` pattern):
  - **Path Helpers** (private methods):
    - `_getQolAssessmentRef(String userId, String petId, DateTime date)` - returns DocumentReference using `AppDateUtils.formatDateForSummary()`
    - `_getDailySummaryRef(String userId, String petId, DateTime date)` - returns DocumentReference for daily summary
    - `_getWeeklySummaryRef(...)` and `_getMonthlySummaryRef(...)` - using `AppDateUtils` formatting
  - **Validation**:
    - `_validateAssessment(QolAssessment assessment)` - calls `assessment.validate()`, throws `QolValidationException` if errors
  - **CRUD Operations**:
    - `Future<void> saveAssessment(QolAssessment assessment)`:
      - Validate assessment
      - Create `WriteBatch`
      - Write/update 4 documents atomically:
        1. `qolAssessments/{YYYY-MM-DD}` - full assessment document
        2. `treatmentSummaries/daily/summaries/{YYYY-MM-DD}` - update QoL score fields and `hasQolAssessment = true`
        3. `treatmentSummaries/weekly/summaries/{YYYY-Www}` - currently no QoL aggregation (deferred)
        4. `treatmentSummaries/monthly/summaries/{YYYY-MM}` - currently no QoL aggregation (deferred)
      - For daily summary: set all domain scores + overall score + `hasQolAssessment` flag using `SetOptions(merge: true)`
      - Commit batch
      - Track analytics: `qol_assessment_completed` or `qol_assessment_updated` (check if document exists first)
      - Wrap in try-catch, throw `QolServiceException` on failure
    - `Future<QolAssessment?> getAssessment(String userId, String petId, DateTime date)`:
      - Query `qolAssessments/{YYYY-MM-DD}` document
      - Return null if doesn't exist
      - Parse with `QolAssessment.fromJson()`
      - Wrap in try-catch, throw `QolServiceException` on failure
    - `Future<List<QolAssessment>> getRecentAssessments(String userId, String petId, {int limit = 20, DateTime? startAfter})`:
      - Query qolAssessments collection
      - Order by `date` descending
      - Apply `.limit(limit)` (default 20 for cost optimization)
      - If `startAfter` provided, use `.startAfter([Timestamp.fromDate(startAfter)])` for pagination
      - Parse results to List<QolAssessment>
      - Wrap in try-catch, throw `QolServiceException` on failure
    - `Stream<QolAssessment?> watchLatestAssessment(String userId, String petId)`:
      - Query qolAssessments collection
      - Order by `date` descending
      - `.limit(1)` for cost efficiency
      - Return stream of snapshots mapped to QolAssessment or null
      - Used by home screen card for real-time updates (optional - may not use in V1)
    - `Future<void> updateAssessment(QolAssessment assessment)`:
      - Validate assessment
      - Fetch existing assessment to compare (for delta calculation if needed)
      - Use batch write to update assessment + daily summary
      - Set `updatedAt = DateTime.now()`
      - Set `completionDurationSeconds = null` (edited assessments lose duration)
      - Track analytics: `qol_assessment_updated`
      - Wrap in try-catch
    - `Future<void> deleteAssessment(String userId, String petId, DateTime date)`:
      - Create batch
      - Delete `qolAssessments/{YYYY-MM-DD}` document
      - Update daily summary: set all QoL fields to null, `hasQolAssessment = false`
      - Weekly/monthly summaries: no action in V1 (deferred)
      - Commit batch
      - Track analytics: `qol_assessment_deleted`
      - Wrap in try-catch
  - **Analytics Integration** (private methods):
    - `_trackAssessmentCompleted(QolAssessment assessment)` - fires analytics event with parameters:
      - `overall_score` (int) - rounded overall score
      - `completion_duration_seconds` (int?)
      - `answered_count` (int)
      - `has_low_confidence_domain` (bool)
    - `_trackAssessmentUpdated(QolAssessment assessment)` - simpler event, just timestamp
    - `_trackAssessmentDeleted(String date)` - simple event

**Testing**:
- Unit tests for CRUD operations (using mocked Firestore)
- Verify batch writes include all 4 documents
- Test error handling and exception throwing
- Verify analytics events fired at correct times

---

### Phase 3.3: Provider Integration (Week 2, Day 1-2)

**Goal**: Create Riverpod state management for QoL with cache-first strategy.

#### Step 3.3.1: Create QoL Provider

**File**: `lib/providers/qol_provider.dart` (new)

**Implementation**:
- Follow structure from `lib/providers/logging_provider.dart` (comprehensive example)
- Define service providers:
  - `qolServiceProvider` - provides `QolService` instance
  - `qolScoringServiceProvider` - provides `QolScoringService` instance
- Define state class `QolState`:
  - `currentAssessment` (QolAssessment?)
  - `recentAssessments` (List<QolAssessment>) - default empty list
  - `isLoading` (bool) - default false
  - `isSaving` (bool) - default false
  - `error` (String?)
  - `lastFetchTime` (DateTime?) - for cache TTL
  - Implement `copyWith()` using sentinel pattern
- Create `QolNotifier extends StateNotifier<QolState>`:
  - Constructor accepts `Ref`, initializes with `const QolState(isLoading: true)`
  - In `_init()` method: call `loadRecentAssessments()` to populate cache
  - Implement methods:
    - `Future<void> loadRecentAssessments({bool forceRefresh = false})`:
      - Check cache freshness: if `lastFetchTime` exists and <5 minutes old and not forced, return early
      - Set `isLoading = true`
      - Get userId from `currentUserProvider`, petId from `selectedPetIdProvider` (or `primaryPetProvider`)
      - Call `_service.getRecentAssessments(userId, petId, limit: 20)`
      - Update state: `recentAssessments`, `currentAssessment = assessments.firstOrNull`, `isLoading = false`, `lastFetchTime = now`
      - Track analytics: `qol_history_loaded` with count parameter
      - On error: set error message, `isLoading = false`
    - `Future<void> saveAssessment(QolAssessment assessment)`:
      - Set `isSaving = true, error = null`
      - Call `_service.saveAssessment(assessment)`
      - Update local state optimistically: prepend assessment to recentAssessments list, set as currentAssessment
      - Set `isSaving = false`
      - Track analytics (delegated to service)
      - On error: set error, `isSaving = false`, rethrow
    - `Future<void> updateAssessment(QolAssessment assessment)`:
      - Similar to save, but replace in list instead of prepend
      - Track analytics
    - `Future<void> deleteAssessment(String assessmentId)`:
      - Find assessment in list, call service delete
      - Remove from local state
      - Update currentAssessment if needed
      - Track analytics
    - `List<QolTrendSummary> getTrendData({int limit = 12})`:
      - Take first `limit` assessments from recentAssessments
      - Filter to only those with valid overall score
      - Map to `QolTrendSummary` objects
      - Return list (used by trend charts)
    - `void clearError()` - sets error to null
- Define main provider:
  - `qolProvider` - `StateNotifierProvider<QolNotifier, QolState>`
- Define selector providers for granular rebuilds:
  - `isLoadingQolProvider` - selects `isLoading`
  - `isSavingQolProvider` - selects `isSaving`
  - `qolErrorProvider` - selects `error`
  - `currentQolAssessmentProvider` - selects `currentAssessment` (used by home screen card!)
  - `recentQolAssessmentsProvider` - selects `recentAssessments`
  - `qolTrendDataProvider` - calls `getTrendData()` on notifier

**Cache Strategy**:
- On app startup: Load last 20 assessments into memory
- 5-minute TTL: Reuse cached data if recent
- Optimistic updates: Immediately reflect saves/updates in local state
- Pull-to-refresh: Force cache invalidation

**Testing**:
- Provider unit tests (following `test/providers/dashboard_provider_flexible_meds_test.dart` pattern)
- Test cache lifecycle, TTL, optimistic updates
- Test state transitions during CRUD operations

---

## 4. UI/UX Implementation

### Phase 4.1: Navigation & Routing (Week 2, Day 2)

**Goal**: Add QoL routes to app router and navigation entry points.

#### Step 4.1.1: Add QoL Routes to Router

**File**: `lib/app/router.dart` (modify)

**Implementation**:
- Add routes after profile routes (around line 340):
  ```dart
  GoRoute(
    path: '/profile/qol',
    name: 'profile-qol',
    pageBuilder: (context, state) => AppPageTransitions.bidirectionalSlide(
      child: const QolHistoryScreen(),
      key: state.pageKey,
    ),
    routes: [
      GoRoute(
        path: 'new',
        name: 'profile-qol-new',
        pageBuilder: (context, state) => AppPageTransitions.bidirectionalSlide(
          child: const QolQuestionnaireScreen(),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: 'edit/:assessmentId',
        name: 'profile-qol-edit',
        pageBuilder: (context, state) {
          final assessmentId = state.pathParameters['assessmentId']!;
          return AppPageTransitions.bidirectionalSlide(
            child: QolQuestionnaireScreen(assessmentId: assessmentId),
            key: state.pageKey,
          );
        },
      ),
      GoRoute(
        path: 'detail/:assessmentId',
        name: 'profile-qol-detail',
        pageBuilder: (context, state) {
          final assessmentId = state.pathParameters['assessmentId']!;
          return AppPageTransitions.bidirectionalSlide(
            child: QolDetailScreen(assessmentId: assessmentId),
            key: state.pageKey,
          );
        },
      ),
    ],
  ),
  ```
- Use `AppPageTransitions.bidirectionalSlide()` for consistent transitions
- Nested routes for new/edit/detail

**Testing**: Manual navigation testing.

---

#### Step 4.1.2: Add Navigation Tile to Profile Screen

**File**: `lib/features/profile/screens/profile_screen.dart` (modify)

**Implementation**:
- Add navigation tile in profile screen after "Medication Schedule" tile (around line 150):
  ```dart
  ProfileNavigationTile(
    icon: Icons.favorite_outline,
    title: l10n.qolNavigationTitle,
    subtitle: l10n.qolNavigationSubtitle,
    onTap: () => context.push('/profile/qol'),
  ),
  ```
- Uses existing `ProfileNavigationTile` widget
- Icon: `Icons.favorite_outline` (represents wellbeing/health)

**Localization keys needed**: `qolNavigationTitle`, `qolNavigationSubtitle`

**Testing**: Manual navigation testing.

---

### Phase 4.2: Questionnaire UI (Week 2, Day 3-5)

**Goal**: Build single-question-per-screen questionnaire with auto-advance and progress tracking.

#### Step 4.2.1: Create Question Card Widget

**File**: `lib/features/qol/widgets/qol_question_card.dart` (new)

**Implementation**:
- Create `QolQuestionCard extends StatelessWidget`
- Constructor parameters:
  - `question` (QolQuestion) - required
  - `currentResponse` (int?) - null or 0-4
  - `onResponseSelected` (ValueChanged<int?>) - callback
- Build method:
  - Column layout with cross-axis stretch
  - **Domain badge** at top:
    - Chip with domain display name (from localization)
    - Background: `AppColors.primaryLight.withOpacity(0.2)`
    - Text color: `AppColors.primary`
  - **Question text** (large, centered):
    - Fetch localized text using `context.l10n.translate(question.textKey)`
    - Style: `AppTextStyles.h1`, center aligned
  - **Recall period reminder**:
    - Text: "In the past 7 days..." (localized)
    - Style: `AppTextStyles.caption`, `AppColors.textSecondary`, centered
  - **Response options** (5 cards for scores 4→0, displayed top to bottom):
    - Use `List.generate(5, (index) {...})` with `score = 4 - index` (highest first)
    - Each option: `HydraCard` with `onTap` callback
    - Inside card: Row with Radio + label text
    - Selected state: Border with `AppColors.primary` at 2px width, bold text
    - Label text: Fetch using `context.l10n.translate(question.responseLabelKeys[score]!)`
    - Padding: `AppSpacing.md` inside card, `AppSpacing.sm` between cards
  - **"Not sure" option** at bottom:
    - Similar HydraCard but different styling (gray border when selected)
    - Radio for null value
    - Label: localized "Not sure / Unable to observe this week"
  - Spacer at bottom for flexible spacing

**Key difference from analysis doc**: Uses question-specific labels instead of generic labels.

**Testing**: Widget test for rendering, selection state, callback firing.

---

#### Step 4.2.2: Create Questionnaire Screen

**File**: `lib/features/qol/screens/qol_questionnaire_screen.dart` (new)

**Implementation**:
- Create `QolQuestionnaireScreen extends ConsumerStatefulWidget`
- Constructor parameter: `assessmentId` (String?) - null for new, date string for edit
- State class `_QolQuestionnaireScreenState`:
  - Fields:
    - `_pageController` (PageController)
    - `_responses` (Map<String, int?>) - maps questionId to score
    - `_selectedDate` (DateTime)
    - `_startTime` (DateTime) - for completion duration tracking
    - `_currentQuestionIndex` (int) - default 0
    - `_isLoading` (bool) - default false
    - `_errorMessage` (String?)
  - `initState()`:
    - Initialize page controller
    - If `assessmentId` provided (edit mode), load existing assessment and pre-fill responses
    - Set `_selectedDate` from existing assessment or today
    - Record `_startTime = DateTime.now()`
  - `dispose()`:
    - Dispose page controller
  - Method: `_handleResponseSelected(String questionId, int? score)`:
    - Update `_responses[questionId] = score`
    - Call `setState()`
    - Haptic feedback: `HapticFeedback.selectionClick()`
    - Auto-advance after 300ms delay (unless last question):
      ```dart
      Future.delayed(Duration(milliseconds: 300), () {
        if (_currentQuestionIndex < 13) {
          _pageController.nextPage(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
      ```
  - Method: `Future<void> _saveAssessment()`:
    - Get userId from `ref.read(currentUserProvider)!.uid`
    - Get petId from `ref.read(primaryPetProvider)!.id`
    - Calculate `completionDuration = DateTime.now().difference(_startTime)`
    - Build `responses` list from `_responses` map
    - Create `QolAssessment` instance (use existing ID if editing, new UUID if new)
    - Set `setState(() => _isLoading = true)`
    - Call `ref.read(qolProvider.notifier).saveAssessment(assessment)` (or `updateAssessment` if editing)
    - On success:
      - Navigate to detail screen: `context.go('/profile/qol/detail/${assessment.documentId}')`
    - On error:
      - Set error message, `_isLoading = false`
      - Show error snackbar
  - Method: `Future<bool> _confirmDiscard()`:
    - Count answered questions
    - If 0 answered, return true (allow exit)
    - If >0 answered, show confirmation dialog:
      - Title: "Discard progress?"
      - Message: "You've answered X of 14 questions. Exit without saving?"
      - Actions: "Keep editing" (returns false), "Discard" (returns true)
    - Return dialog result
  - Override `build()`:
    - Wrap in `WillPopScope` with `onWillPop: _confirmDiscard` for back button handling
    - Return `AppScaffold` with:
      - AppBar:
        - Title: "QoL Assessment" or "Edit Assessment" (localized)
        - Leading: IconButton with back arrow, calls `_confirmDiscard()` before popping
      - Body: Column with:
        - **Linear progress indicator** at top:
          - `LinearProgressIndicator` with `value = (_currentQuestionIndex + 1) / 14`
          - Colors: `backgroundColor: AppColors.border`, `color: AppColors.primary`
        - **PageView** (expanded):
          - Controller: `_pageController`
          - Physics: `NeverScrollableScrollPhysics()` (swipe disabled, only button/auto navigation)
          - `onPageChanged`: updates `_currentQuestionIndex`
          - Item builder: renders `QolQuestionCard` for each question in order
          - Passes current response and callback
        - **Bottom navigation bar** (SafeArea):
          - Row with:
            - "Previous" button (if not first question): `HydraButton.secondary`, calls `_pageController.previousPage()`
            - Spacer
            - "Complete" button (if last question): `HydraButton.primary`, shows loading spinner if saving, calls `_saveAssessment()`
          - Padding: `AppSpacing.md`

**Progress persistence decision**: Do NOT save to Firestore (per clarifying questions). Use `WillPopScope` for discard confirmation only.

**Testing**: Widget test for question navigation, auto-advance, save flow, discard confirmation.

---

### Phase 4.3: Results Visualization (Week 3, Day 1-3)

**Goal**: Display completed assessment with radar chart, domain breakdown, and interpretation.

#### Step 4.3.1: Create Radar Chart Widget

**File**: `lib/features/qol/widgets/qol_radar_chart.dart` (new)

**Implementation**:
- Create `QolRadarChart extends StatelessWidget`
- Constructor parameters:
  - `assessment` (QolAssessment) - required
  - `isCompact` (bool) - default false (for home screen variant)
- Build method:
  - Get domain scores from assessment
  - Convert to `RadarEntry` list (one per domain, in canonical order)
  - If all scores null (all "Not sure"), show empty state message
  - Return `HydraCard` containing:
    - Title (if not compact): "Quality of Life Profile" (localized)
    - `RadarChart` from fl_chart:
      - Height: 280 if full-size, 180 if compact
      - `radarShape: RadarShape.polygon`
      - 5 tick marks (0, 25, 50, 75, 100)
      - Tick text style: `AppTextStyles.small` with `AppColors.textTertiary`
      - Border: `AppColors.border` at 1px
      - Grid lines: `AppColors.border.withOpacity(0.5)`
      - Domain labels on axes:
        - Full-size: Use full domain names (e.g., "Vitality")
        - Compact: Use abbreviations (e.g., "Vital.", "Comf.", "Emot.", "Appe.", "Treat.")
        - Get from localization
      - Data set:
        - Fill color: `AppColors.primary.withOpacity(0.2)`
        - Border color: `AppColors.primary` at 2px width
        - **Low confidence domains**: Use dotted border style (`BorderSide.strokeAlign`) and 0.5 opacity
        - Entry radius: 3px dots at vertices
    - Legend below chart (if not compact):
      - Wrap layout with domain name + score pairs
      - Color indicators (circles) in `AppColors.primary`
      - Show "Insufficient data" for low-confidence domains
- Helper method `_getScoreBandColor(String? band)`:
  - 'veryGood' → `AppColors.success`
  - 'good' → `AppColors.primary`
  - 'fair' → `AppColors.warning`
  - 'low' → `AppColors.error`
  - null → `AppColors.textSecondary`

**Low confidence visual treatment**: Dotted line, reduced opacity (per clarifying questions).

**Testing**: Widget test for rendering, compact vs full variants.

---

#### Step 4.3.2: Create Score Summary Card Widget

**File**: `lib/features/qol/widgets/qol_score_summary_card.dart` (new)

**Implementation**:
- Create `QolScoreSummaryCard extends StatelessWidget`
- Constructor parameter: `assessment` (QolAssessment)
- Build `HydraCard` with:
  - Large overall score display:
    - Circle with score number (e.g., "78")
    - Background color based on score band
    - Size: 100px diameter
  - Score band label below (e.g., "Good")
  - Badge showing "Based on X/5 domains" if any domain has low confidence:
    - Small chip with info icon
    - Tappable to show explanation dialog
  - Assessment date below
  - "X/14 questions answered" indicator if incomplete

**Testing**: Widget test for rendering with various score levels.

---

#### Step 4.3.3: Create Interpretation Card Widget

**File**: `lib/features/qol/widgets/qol_interpretation_card.dart` (new)

**Implementation**:
- Create `QolInterpretationCard extends ConsumerWidget`
- Constructor parameter: `assessment` (QolAssessment)
- In build:
  - Get previous assessment from provider (second item in `recentQolAssessmentsProvider`)
  - If no previous, show message: "Complete another assessment to see trends"
  - If previous exists:
    - Calculate delta (current vs previous) using scoring service
    - Generate interpretation message using `qolScoringServiceProvider.generateInterpretationMessage()`
    - Display in `HydraInfoCard` (type based on trend: success/info/warning)
    - Message examples:
      - Stable: "Your cat's quality of life has remained stable since last assessment."
      - Improving: "Your cat's comfort and vitality scores have improved. Great progress!"
      - Declining: "Quality of life scores are lower than last week. Consider discussing recent changes with your vet."
    - Include disclaimer footer: "These trends are observational only. Contact your vet if concerned."

**Testing**: Widget test with various trend scenarios.

---

#### Step 4.3.4: Create Detail Screen

**File**: `lib/features/qol/screens/qol_detail_screen.dart` (new)

**Implementation**:
- Create `QolDetailScreen extends ConsumerWidget`
- Constructor parameter: `assessmentId` (String) - YYYY-MM-DD format
- In build:
  - Get assessment from `recentQolAssessmentsProvider` by documentId
  - Return `AppScaffold` with:
    - AppBar: Title "QoL Results", back button, optional "Edit" action button
    - Body: `SingleChildScrollView` with column:
      - `QolScoreSummaryCard(assessment)` - hero card with overall score
      - Spacing
      - `QolRadarChart(assessment, isCompact: false)` - full radar chart
      - Spacing
      - **Domain breakdown section**:
        - Title: "Domain Scores"
        - List of 5 domain cards (HydraCard each):
          - Domain name
          - Score (or "Insufficient data" if <50% answered)
          - "X/Y questions answered" indicator
          - Progress bar (0-100 scale) with color based on score
      - Spacing
      - `QolInterpretationCard(assessment)` - trend interpretation
      - Spacing
      - **Action buttons row**:
        - "Edit" button (secondary): Navigate to edit screen
        - "View History" button (primary): Navigate to history screen
    - Floating action button: "Share" (deferred to future export feature - show placeholder)

**Edit button**: Primary access point for editing (per clarifying questions).

**Testing**: Widget test for rendering, navigation.

---

### Phase 4.4: History & Trends (Week 3, Day 3-4)

**Goal**: Display historical assessments and trend charts.

#### Step 4.4.1: Create Trend Line Chart Widget

**File**: `lib/features/qol/widgets/qol_trend_line_chart.dart` (new)

**Implementation**:
- Create `QolTrendLineChart extends ConsumerWidget`
- In build:
  - Get trend data from `qolTrendDataProvider` (last 12 assessments with valid scores)
  - If <2 assessments, show empty state: "Need at least 2 assessments to see trends"
  - Return `HydraCard` with:
    - Title: "QoL Trends"
    - `LineChart` from fl_chart:
      - Height: 240px
      - X-axis: Dates (formatted as "MMM d")
      - Y-axis: 0-100 scale with 25-point intervals
      - Grid: Horizontal lines only, `AppColors.border.withOpacity(0.5)`
      - Line data:
        - Overall score line (primary): `AppColors.primary`, 3px width, rounded caps, dots at data points, filled area below at 0.1 opacity
        - Optional: Individual domain lines (togglable) with different colors
      - Touch tooltip:
        - Background: `AppColors.surface` with border
        - Shows date + overall score + domain scores
        - Rounded corners: `AppBorderRadius.sm`
      - Border: All sides with `AppColors.border`
      - Fixed Y-axis range: 0-100 (never auto-scale per clarifying questions)

**Testing**: Widget test for rendering, empty state.

---

#### Step 4.4.2: Create History Screen

**File**: `lib/features/qol/screens/qol_history_screen.dart` (new)

**Implementation**:
- Create `QolHistoryScreen extends ConsumerWidget`
- In build:
  - Get assessments from `recentQolAssessmentsProvider`
  - Get loading state from `isLoadingQolProvider`
  - Return `AppScaffold` with:
    - AppBar: Title "Quality of Life", back button
    - Body: `RefreshIndicator` wrapping:
      - If loading and empty list: Show loading spinner
      - If empty list (after loading): Show empty state with:
        - Large icon (`Icons.favorite_border`, 64px, `AppColors.textTertiary`)
        - Title: "Track Your Cat's Quality of Life"
        - Message: "Complete assessments weekly to identify trends and share insights with your vet."
        - Button: "Start First Assessment" → navigate to questionnaire
      - If has assessments: `ListView.builder`:
        - Padding: `AppSpacing.lg`
        - Item builder: `_QolHistoryCard` for each assessment
        - Each card shows:
          - Date (large)
          - Overall score badge (colored by score band)
          - Trend indicator (arrow up/down/stable compared to previous)
          - Tap: Navigate to detail screen
          - Long-press: Show context menu with "Edit" and "Delete" options
    - FAB: `HydraFab` with "Add" icon → navigate to new questionnaire
  - `onRefresh`: Call `ref.read(qolProvider.notifier).loadRecentAssessments(forceRefresh: true)`

**History card long-press**: Secondary access point for editing (per clarifying questions).

**Testing**: Widget test for empty state, list rendering, navigation.

---

### Phase 4.5: Home Screen Integration (Week 3, Day 4-5)

**Goal**: Display latest QoL radar chart on home screen for visibility.

#### Step 4.5.1: Create Home Card Widget

**File**: `lib/features/home/widgets/qol_home_card.dart` (new)

**Implementation**:
- Create `QolHomeCard extends ConsumerWidget`
- In build:
  - Get latest assessment from `currentQolAssessmentProvider`
  - If null, show empty state:
    - `HydraCard` with:
      - Title row: "Quality of Life" + favorite icon (outline)
      - Message: "Track your cat's wellbeing over time"
      - Button: "Start Assessment" (secondary, small) → navigate to questionnaire
  - If assessment exists:
    - `HydraCard` with `onTap` → navigate to detail screen:
      - Header row:
        - Title: "Quality of Life"
        - Overall score badge (colored chip with percentage)
      - Date: "Assessed on [date]" (caption style)
      - Spacing
      - Compact radar chart: `QolRadarChart(assessment, isCompact: true)` at 180px height
      - Spacing
      - Footer row (right-aligned): "View History" text button → navigate to history
- Track analytics on card view: `qol_home_card_viewed` (fire in `initState` or `didChangeDependencies`)
- Track analytics on tap: `qol_home_card_tapped`

**Cost optimization**: Uses cached assessment from provider (loaded on app startup), no additional Firestore reads.

**Testing**: Widget test for empty and populated states.

---

#### Step 4.5.2: Integrate into Home Screen

**File**: `lib/features/home/screens/home_screen.dart` (modify)

**Implementation**:
- Locate the `_Dashboard` widget (around line 102)
- Find the main scrollable content area where cards are rendered
- Add `QolHomeCard()` after treatment cards (WaterDropProgressCard, medication cards) and before navigation cards
- Typical insertion point: After fluid/medication progress widgets, before "More Insights" section
- Spacing: Use consistent `AppSpacing.lg` between cards

**Position rationale**: QoL is core tracking (not navigation), so appears with other health tracking cards but after urgent treatments.

**Testing**: Manual test - verify card appears, taps navigate correctly, empty state works.

---

## 5. Localization

### Phase 5.1: Add Localization Keys (Week 3, Day 5 - Week 4, Day 1)

**Goal**: Add ~150 localization keys to support all UI text.

**File**: `lib/l10n/app_en.arb` (modify)

**Implementation**:
- Add keys organized by category (approximate counts):

**Navigation (2 keys)**:
- `qolNavigationTitle`: "Quality of Life"
- `qolNavigationSubtitle`: "Track your cat's wellbeing over time"

**Screen Titles (5 keys)**:
- `qolQuestionnaireTitle`: "QoL Assessment"
- `qolQuestionnaireEditTitle`: "Edit Assessment"
- `qolHistoryTitle`: "Quality of Life"
- `qolResultsTitle`: "QoL Results"
- `qolTrendChartTitle`: "QoL Trends"

**Domain Names (10 keys)**:
- `qolDomainVitality`: "Vitality"
- `qolDomainVitalityDesc`: "Energy and activity levels"
- `qolDomainComfort`: "Comfort"
- `qolDomainComfortDesc`: "Physical comfort and mobility"
- `qolDomainEmotional`: "Emotional Wellbeing"
- `qolDomainEmotionalDesc`: "Mood and social behavior"
- `qolDomainAppetite`: "Appetite"
- `qolDomainAppetiteDesc`: "Interest in food and eating"
- `qolDomainTreatmentBurden`: "Treatment Burden"
- `qolDomainTreatmentBurdenDesc`: "Stress from CKD care"

**Question Texts (14 keys)**: Use exact wording from Section 1
- `qolQuestionVitality1`: "In the past 7 days, how would you describe your cat's overall energy level compared to their usual self?"
- `qolQuestionVitality2`: "In the past 7 days, how often did your cat get up, walk around, or explore on their own instead of staying in one place?"
- `qolQuestionVitality3`: "In the past 7 days, how often did your cat show interest in play, toys, or interacting with objects around them?"
- [... continue for all 14 questions ...]

**Response Labels (70 keys)**: 5 labels per question × 14 questions
- Format: `qolVitality1Label0`, `qolVitality1Label1`, ... `qolVitality1Label4`
- Use exact label text from Section 1 question set
- Example for vitality_1:
  - `qolVitality1Label0`: "Much lower than usual (very sleepy, hardly active)"
  - `qolVitality1Label1`: "Lower than usual (noticeably less active)"
  - `qolVitality1Label2`: "About the same as usual"
  - `qolVitality1Label3`: "A bit higher than usual"
  - `qolVitality1Label4`: "Much higher than usual (very lively and active)"
- **IMPORTANT**: comfort_3 labels updated per Wright 2025 analysis:
  - `qolComfort3Label0`: "Very often (showed clear discomfort most times)"
  - `qolComfort3Label1`: "Often (frequently showed signs of discomfort)"
  - `qolComfort3Label2`: "Sometimes (occasional signs of discomfort)"
  - `qolComfort3Label3`: "Rarely (only once or twice this week)"
  - `qolComfort3Label4`: "Not at all (used litter box comfortably all week)"
- [... continue for all remaining questions ...]

**Score Bands (4 keys)**:
- `qolScoreBandVeryGood`: "Very Good"
- `qolScoreBandGood`: "Good"
- `qolScoreBandFair`: "Fair"
- `qolScoreBandLow`: "Low"

**UI Labels (25 keys)**:
- `qolRecallPeriod`: "In the past 7 days..."
- `qolNotSure`: "Not sure / Unable to observe this week"
- `qolRadarChartTitle`: "Quality of Life Profile"
- `qolDomainScoresTitle`: "Domain Scores"
- `qolQuestionsAnswered`: "{answered} / {total} questions answered" (with parameters)
- `qolBasedOnDomains`: "Based on {count} of 5 domains" (with parameter)
- `qolInsufficientData`: "Insufficient data"
- `qolLowConfidenceExplanation`: "This domain has less than 50% of questions answered, so the score may not be reliable."
- `qolOverallScore`: "Overall Score"
- `qolAssessedOn`: "Assessed on {date}" (with parameter)
- `qolComparedToLast`: "vs. last assessment"
- `qolNeedMoreData`: "Complete at least 2 assessments to see trends"
- ... (continue for all UI elements)

**Actions (8 keys)**:
- `qolStartAssessment`: "Start Assessment"
- `qolStartFirstAssessment`: "Start First Assessment"
- `qolContinue`: "Continue"
- `qolPrevious`: "Previous"
- `qolComplete`: "Complete"
- `qolSave`: "Save"
- `edit`: "Edit" (may already exist)
- `viewHistory`: "View History" (may already exist)

**Empty States (6 keys)**:
- `qolEmptyStateTitle`: "Track Your Cat's Quality of Life"
- `qolEmptyStateMessage`: "Complete assessments weekly to identify trends and share insights with your vet."
- `qolHistoryEmptyMessage`: "No assessments yet. Start your first one to begin tracking."
- `qolHomeCardEmptyMessage`: "Track your cat's wellbeing over time"
- `qolFirstAssessmentMessage`: "This is your baseline. Complete another in 7 days to see trends."

**Interpretation Messages (10 keys)**:
- `qolInterpretationStable`: "Your cat's quality of life has remained stable since the last assessment."
- `qolInterpretationImproving`: "Quality of life scores have improved. Great progress!"
- `qolInterpretationDeclining`: "Quality of life scores are lower than last week. Consider discussing recent changes with your veterinarian."
- `qolInterpretationNotableDropComfort`: "Comfort scores have dropped notably. You may want to discuss pain management with your vet."
- `qolInterpretationNotableDropAppetite`: "Appetite scores are significantly lower. Monitor eating habits closely."
- ... (add more specific interpretation variants)

**Errors & Confirmations (8 keys)**:
- `qolSaveError`: "Failed to save assessment. Please try again."
- `qolLoadError`: "Unable to load assessments. Check your connection."
- `qolDeleteConfirmTitle`: "Delete Assessment?"
- `qolDeleteConfirmMessage`: "This will permanently delete the assessment from {date}."
- `qolDiscardTitle`: "Discard progress?"
- `qolDiscardMessage`: "You've answered {count} of 14 questions. Exit without saving?"
- `qolKeepEditing`: "Keep editing"
- `qolDiscard`: "Discard"

**Disclaimers & Attributions (3 keys)**:
- `qolDisclaimer`: "This tool tracks quality of life trends over time for your reference. It is not a diagnostic instrument and does not replace veterinary care. Always consult your veterinarian for medical decisions."
- `qolTrendDisclaimer`: "These trends are observational only. Consult your vet for medical guidance."
- `qolScientificAttribution`: "HydraCAT's Quality of Life assessment is informed by published psychometric research on feline health-related quality of life, including studies by Bijsmans et al. (2016), Lorbach et al. (2022), and Wright et al. (2025). This tool is independently developed and is not affiliated with or endorsed by the authors of these studies."

**Total Estimate**: ~150 keys (70 for response labels + 14 for questions + ~66 for UI/messages)

**Note**: Scientific attribution should appear in app settings/about screen, not on every QoL screen.

**Testing**: Generate localization files (`dart run build_runner build`), verify no missing keys at runtime.

---

## 6. Analytics Integration

### Phase 6.1: Update Analytics Documentation (Week 4, Day 1)

**Goal**: Document all QoL analytics events for tracking and debugging.

**File**: `.cursor/reference/analytics_list.md` (modify)

**Implementation**:
- Add new section: "Quality of Life Tracking Events"
- Document events:
  - `qol_assessment_started` - fired when questionnaire screen opens
  - `qol_assessment_completed` - fired on save with parameters:
    - `overall_score` (int)
    - `completion_duration_seconds` (int)
    - `answered_count` (int)
    - `has_low_confidence_domain` (bool)
  - `qol_assessment_updated` - fired when editing existing assessment
  - `qol_assessment_deleted` - fired when user deletes assessment
  - `qol_history_viewed` - fired when history screen opens
  - `qol_detail_viewed` - fired when detail screen opens, with parameter:
    - `assessment_date` (string)
  - `qol_trends_viewed` - fired when trend chart displayed, with parameter:
    - `assessment_count` (int)
  - `qol_home_card_viewed` - fired when home card appears (once per session)
  - `qol_home_card_tapped` - fired when user taps home card
  - `qol_question_answered` - fired on page advance (not every slider drag), with parameters:
    - `question_id` (string)
    - `domain` (string)
    - `score` (int or null)

**Testing**: None (documentation only).

---

## 7. Testing

### Phase 7.1: Unit Tests (Week 4, Day 2)

**Goal**: Achieve 80%+ coverage for models, services, and providers.

**Files to create**:
- `test/features/qol/models/qol_assessment_test.dart`
- `test/features/qol/models/qol_response_test.dart`
- `test/features/qol/models/qol_domain_test.dart`
- `test/features/qol/models/qol_question_test.dart`
- `test/features/qol/services/qol_scoring_service_test.dart`
- `test/features/qol/services/qol_service_test.dart`
- `test/features/qol/providers/qol_provider_test.dart`

**Key test cases**:
- **QolAssessment**:
  - Domain score calculation with various completion percentages (30%, 50%, 70%, 100%)
  - Low confidence detection (exactly 50% threshold, just under, just over)
  - Overall score requires all 5 domains valid
  - Score band classification (boundary cases: 39.9→40, 59.9→60, 79.9→80)
  - Validation: future dates rejected, scores outside 0-4 rejected, duplicate questions rejected
  - JSON serialization round-trip with all field types
- **QolScoringService**:
  - calculateDomainScore with partial responses
  - calculateOverallScore with missing domains
  - Trend stability calculation (improving/declining/stable datasets)
  - Notable change detection (≥15 point drop, sustained ≥2 assessments)
- **QolService** (with mocked Firestore):
  - Batch writes include all 4 documents (assessment + 3 summaries)
  - Error handling throws QolServiceException
  - Analytics events fired at correct times
- **QolProvider**:
  - Cache lifecycle (TTL, force refresh)
  - Optimistic updates (save/update/delete)
  - State transitions during loading/saving
  - Error handling

**Testing**: Run `flutter test` to verify all pass.

---

### Phase 7.2: Widget Tests (Week 4, Day 2-3)

**Goal**: Test key UI components in isolation.

**Files to create**:
- `test/features/qol/widgets/qol_question_card_test.dart`
- `test/features/qol/widgets/qol_radar_chart_test.dart`
- `test/features/qol/widgets/qol_score_summary_card_test.dart`
- `test/features/qol/widgets/qol_home_card_test.dart`

**Key test cases**:
- **QolQuestionCard**:
  - Renders all 5 response options + "Not sure"
  - Selection state updates correctly
  - Callback fires with correct score
  - Uses question-specific labels (not generic)
- **QolRadarChart**:
  - Renders 5 domains
  - Empty state for all null responses
  - Compact variant has abbreviated labels
  - Low confidence domains have dotted lines
- **QolHomeCard**:
  - Empty state shows CTA button
  - Populated state shows radar chart
  - Tap navigates to detail screen

**Testing**: Run `flutter test` to verify rendering and interactions.

---

### Phase 7.3: Integration Tests (Week 4, Day 3)

**Goal**: Test complete user flows end-to-end.

**File**: `test/features/qol/integration/qol_flow_test.dart` (new)

**Test scenarios**:
1. Complete full 14-question assessment from start to finish
2. Edit existing assessment and verify changes saved
3. View history screen with multiple assessments
4. View detail screen with radar chart and interpretation
5. Home screen card displays latest assessment
6. Delete assessment and verify removed from history

**Testing**: Run integration tests with test Firestore instance.

---

### Phase 7.4: Update Test Index (Week 4, Day 3)

**File**: `test/tests_index.md` (modify)

**Implementation**:
- Add new section: "QoL Feature Tests"
- List all 11 new test files with brief descriptions
- Document total test count and coverage percentage

**Testing**: None (documentation only).

---

## 8. Documentation & Launch

### Phase 8.1: Firestore Indexes (Week 4, Day 4)

**Goal**: Create composite indexes for efficient QoL queries.

**File**: `firestore.indexes.json` (modify)

**Implementation**:
- Add indexes:
  ```json
  {
    "collectionGroup": "qolAssessments",
    "queryScope": "COLLECTION",
    "fields": [
      { "fieldPath": "petId", "order": "ASCENDING" },
      { "fieldPath": "date", "order": "DESCENDING" }
    ]
  }
  ```
- Deploy to Firebase Console or via Firebase CLI

**Testing**: Verify queries work without "index required" errors.

---

### Phase 8.2: Final Documentation Updates (Week 4, Day 4)

**Files to update**:
- `~PLANNING/qol_plan.md` - Mark as DONE, move to `~PLANNING/DONE/`
- `.cursor/reference/analytics_list.md` - Already updated in Phase 6.1
- `test/tests_index.md` - Already updated in Phase 7.4
- `.cursor/rules/firestore_schema.md` - Already updated throughout implementation

**Testing**: None (documentation only).

---

### Phase 8.3: Pre-Launch Checklist (Week 4, Day 4-5)

**Manual QA**:
- [ ] Run `flutter analyze` - zero errors
- [ ] Run `flutter test` - all tests pass
- [ ] Test on iOS device - navigation, charts render correctly
- [ ] Test on Android device - navigation, charts render correctly
- [ ] Verify offline mode - cached data displays, saves queue correctly
- [ ] Test with fresh account - onboarding flow, first assessment, empty states
- [ ] Test with existing account - migration, existing data preserved
- [ ] Verify Firebase costs - check read/write counts in console, ensure batch writes working
- [ ] Verify analytics - events firing in Firebase Analytics console
- [ ] Test all navigation paths - profile → QoL → history → detail → edit → back
- [ ] Test home screen card - appears correctly, taps navigate
- [ ] Test error states - network failure, validation errors, Firestore errors
- [ ] Test edge cases - all "Not sure" responses, partial completion, discard confirmation

**Performance checks**:
- [ ] Home screen loads with QoL card in <500ms (using cached data)
- [ ] Questionnaire navigation feels instant (<100ms between questions)
- [ ] Radar chart renders smoothly (no jank)
- [ ] History screen scrolls smoothly with 20+ assessments

**Accessibility**:
- [ ] All interactive elements have minimum 44px touch targets
- [ ] Color contrast meets WCAG AA standards
- [ ] VoiceOver/TalkBack announce labels correctly (iOS/Android)

---

### Phase 8.4: Launch (Week 4, Day 5)

**Steps**:
1. Merge feature branch to main
2. Tag release version (e.g., `v1.5.0-qol`)
3. Deploy to production Firestore (ensure indexes created)
4. Monitor Firebase console for first 24 hours:
   - Check error rates in Crashlytics
   - Verify analytics events appearing
   - Monitor read/write counts (should be ~2 writes per save, minimal reads)
5. Prepare user-facing announcement:
   - In-app notification or feature discovery popup (optional)
   - Update app store description to mention QoL tracking
   - Social media announcement (if applicable)

---

## 9. Scientific Validation Roadmap

### Phase 9.1: Internal Psychometric Analysis (Post-Launch)

**Goal**: Build your own evidence base to strengthen scientific validity and legal protection.

**Why This Matters:**
- Independent validation data provides the strongest legal protection
- Demonstrates your instrument's validity without relying on external studies
- Enables continuous improvement based on real-world usage
- Supports future publication or peer review if desired

### Validation Timeline

**Phase 1: Usage Data Collection (0-6 months post-launch)**

**Metrics to Track:**
- Total assessments completed (target: 500+ within 6 months)
- Completion rate (percentage of started assessments finished)
- Per-question response distribution (identify ceiling/floor effects)
- "Not sure" response frequency per question (identify unclear questions)
- Domain score distributions (mean, SD, range)
- Overall score distribution
- User feedback on question clarity (via support tickets, ratings)

**Tools:**
- Firebase Analytics (already integrated)
- Firestore queries for aggregated data
- User feedback forms (optional)

---

**Phase 2: Reliability Analysis (6-12 months)**

**Internal Consistency:**
- Calculate Cronbach's α for each domain (target: α > 0.70 indicates good reliability)
- Assess interitem correlations within domains
- Identify problematic items (low correlation with domain total)

**Test-Retest Reliability (if feasible):**
- Identify users who completed assessments 3-7 days apart with no reported health changes
- Calculate intraclass correlation coefficients (ICC)
- Target: ICC > 0.75 indicates good stability

**Analysis Methods:**
- Export anonymized assessment data
- Use statistical software (R, Python pandas, SPSS)
- Document methodology for transparency

---

**Phase 3: Construct Validity (6-12 months)**

**Known-Groups Validity:**
- Compare QoL scores across IRIS stages (if available in user data)
  - Hypothesis: IRIS stage 3-4 cats should have lower scores than stage 1-2
- Compare users who report "cat is doing well" vs "cat is struggling"
- Statistical test: Mann-Whitney U or Kruskal-Wallis

**Convergent Validity:**
- Correlate QoL domains with related concepts:
  - Vitality domain vs treatment adherence (hypothesis: positive correlation)
  - Appetite domain vs weight trends (hypothesis: positive correlation)
  - Treatment Burden domain vs medication complexity (hypothesis: negative correlation)

**Face Validity:**
- Survey subset of users: "Do these questions capture what's important about your cat's quality of life?"
- Veterinarian feedback (if partnerships established)

---

**Phase 4: Responsiveness to Change (12+ months)**

**Minimum Clinically Important Difference (MCID):**
- Identify assessment pairs where user reported "cat got better" or "cat got worse"
- Calculate mean change in QoL score for "better" group
- Determine threshold (e.g., 10-point change) that corresponds to meaningful improvement
- This becomes YOUR evidence-based threshold for "notable change" detection

**Sensitivity to Interventions:**
- Track QoL changes after:
  - Starting new medications
  - Increasing fluid therapy volume
  - IRIS stage progression
- Document trends (even without control group, trends are informative)

---

**Phase 5: Publication Opportunity (18+ months, optional)**

**If Validation Data is Strong:**
- Publish findings in open-access veterinary journal
- Title example: "Validation of a Mobile App-Based Quality of Life Instrument for Cats with Chronic Kidney Disease"
- This establishes YOUR tool as independently validated
- Strengthens legal position (you're not copying, you're contributing)

**Benefits:**
- Academic credibility
- Marketing differentiation ("Scientifically validated QoL tracking")
- Veterinary community awareness
- Legal protection (clear evidence of independent development)

**Costs:**
- Time investment (manuscript writing, peer review process)
- Potential publication fee ($500-2000 for open access)
- Statistical consultant (optional, $1000-3000)

---

**Phase 6: Continuous Improvement (Ongoing)**

**Question Refinement:**
- If Phase 2 analysis reveals problematic items (low α, ceiling effects), consider:
  - Rewording for clarity
  - Adding coat condition question (deferred from V1)
  - Removing items that don't contribute to domain reliability

**Comparison with Published Instruments:**
- Compare your domain score distributions with Wright 2025 findings
- Look for convergence (strengthens validity) or divergence (investigate causes)

**User-Driven Enhancements:**
- Track most requested features via analytics and support
- Prioritize changes that enhance scientific rigor, not just convenience

---

### Validation Milestones & Success Criteria

| Milestone | Timeline | Success Criteria | Action if Not Met |
|-----------|----------|------------------|-------------------|
| 500 assessments completed | 6 months | ≥500 unique assessments | Increase user acquisition, in-app prompts |
| Domain reliability (Cronbach's α) | 6 months | α > 0.70 for all 5 domains | Review low-performing items, consider rewording |
| Known-groups validity | 12 months | Significant difference (p<0.05) between health groups | Investigate scoring algorithm, gather more data |
| MCID identified | 12 months | Clear threshold for meaningful change | Continue data collection, refine criteria |
| Publication draft complete | 18 months | Manuscript submitted to journal | Optional - not required for success |

---

## 10. Future Iterations (Deferred)

### Phase 10.1: Export Functionality (Future)

**Scope**: Comprehensive export feature covering multiple health insights (QoL + symptoms + lab values + treatment adherence).

**QoL-Specific Components**:
- PDF report generation with radar charts and trend lines
- CSV export of raw assessment data
- Image export of individual charts (radar chart, trend lines)
- Shareable summary for vet visits (last 3-6 months)

**Dependencies**: Requires `pdf`, `printing`, `share_plus` packages.

**Estimated Effort**: 2 weeks (covers all health data exports, not just QoL).

---

### Phase 10.2: Premium Feature Gating (Future)

**Scope**: Differentiate free vs premium tiers for QoL feature.

**Free Tier**:
- Current snapshot + latest radar chart
- Last 30 days history
- Basic trend chart

**Premium Tier**:
- Unlimited history (all assessments)
- 12+ month trend analysis
- Notable change detection alerts
- Correlation analysis (QoL vs treatment adherence)
- Vet-ready export features

**Implementation**: Add feature flags to `QolHistoryScreen` and `QolTrendLineChart`, check premium status from provider.

**Estimated Effort**: 3-4 days (infrastructure already exists from other premium features).

---

### Phase 10.3: Advanced Analytics (Future)

**Potential Features**:
- MCID calculation (Minimum Clinically Important Difference) for personalized thresholds
- Correlation analysis: QoL vs fluid adherence, QoL vs medication adherence, QoL vs lab values
- Predictive insights: "Based on trends, your cat's QoL may decline if..."
- Customizable assessment frequency reminders (weekly/biweekly)
- Multi-pet comparison (for households with multiple CKD cats)

**Dependencies**: Requires ML/AI infrastructure, larger dataset for training.

**Estimated Effort**: 6-8 weeks (major feature addition).

---

## 11. Cost Optimization Summary

**Firestore Operations per QoL Assessment**:
- **Writes**: 4 documents (1 assessment + 3 summaries) = **4 writes** per save
- **Reads**:
  - Home screen: **0 reads** (uses cached `currentAssessment` from startup load)
  - History screen: **20 reads** (paginated, limit=20, cached for 5 minutes)
  - Detail screen: **0 reads** (uses cached assessment from history)
  - Trend chart: **0 reads** (computed from cached `recentAssessments`)

**Estimated Monthly Cost (100 active users, 1 assessment/week)**:
- Writes: 100 users × 4 assessments/month × 4 writes = **1,600 writes/month** (~$0.05)
- Reads: 100 users × 4 app opens/day × 30 days = **12,000 reads/month** (~$0.04)
- **Total QoL feature cost**: ~**$0.09/month** for 100 users

**Cost is negligible** thanks to:
- Batch writes (4 docs in 1 operation)
- Cache-first strategy (5-min TTL)
- Denormalized scores in daily summaries (eliminates reads for home screen)
- Pagination (limit=20)
- No real-time listeners

---

## 12. Implementation Timeline Summary

**Week 1**: Data Models & Service Layer
- Days 1-2: Core models (QolDomain, QolQuestion, QolResponse, QolAssessment, exceptions)
- Days 2-3: Daily summary integration, schema documentation
- Days 3-4: QolScoringService (pure logic)
- Days 4-5: QolService (Firebase CRUD)

**Week 2**: State Management & Questionnaire UI
- Days 1-2: QolProvider (Riverpod state management)
- Day 2: Navigation & routing setup
- Days 3-5: Questionnaire UI (question card, screen, auto-advance, progress)

**Week 3**: Visualization & Integration
- Days 1-3: Results UI (radar chart, score card, interpretation, detail screen)
- Days 3-4: History & trends (history screen, trend line chart)
- Days 4-5: Home screen integration (QolHomeCard, home screen modification)

**Week 4**: Polish & Launch
- Day 1: Localization (~150 keys)
- Days 2-3: Testing (unit, widget, integration)
- Days 4-5: Documentation, QA, launch

**Total Estimated Timeline**: 4 weeks (1 senior developer, full-time)

---

## 13. Success Metrics

**Adoption Metrics** (Track in Firebase Analytics):
- % of users who complete ≥1 assessment (target: 40% within 30 days of launch)
- % of users who complete ≥2 assessments (target: 25% - indicates engagement)
- Average assessments per active user per month (target: 2-3)

**Engagement Metrics**:
- Average completion time (target: 2-3 minutes as designed)
- Drop-off rate by question number (identify problematic questions)
- Home card tap-through rate (target: 15%+)

**Data Quality Metrics**:
- % of assessments with all 14 questions answered (target: 70%+)
- % of assessments with low confidence domains (target: <30%)
- Average "Not sure" responses per assessment (target: <3)

**Business Metrics** (for future premium tier):
- QoL history views by premium vs free users
- Export feature usage (when implemented)
- Correlation: Users with ≥3 QoL assessments → premium conversion rate

---

## 14. Risk Mitigation

**Technical Risks**:
- **Radar chart rendering performance**: Mitigation - Use fl_chart (proven library), limit data points, test on low-end devices
- **Firestore batch write limits**: Mitigation - 4 docs per batch is well within 500-doc limit, no risk
- **Cache staleness**: Mitigation - 5-minute TTL with force refresh on pull-to-refresh

**UX Risks**:
- **Question fatigue** (14 questions): Mitigation - Auto-advance, progress bar, 2-3 min completion time, one-tap responses
- **Ambiguous questions**: Mitigation - User testing before launch, iterate based on feedback
- **Low completion rate**: Mitigation - Empty state encouragement, home card visibility, success messaging

**Data Risks**:
- **Spurious correlations** (users seeing false patterns): Mitigation - Clear disclaimers, trend interpretation messages emphasize observational nature
- **Over-interpretation** (users diagnosing from scores): Mitigation - No diagnostic language, disclaimer on every screen, vet consultation messaging

---

## Appendix A: File Checklist

**New Files to Create** (30 files):

**Models (5)**:
- `lib/features/qol/models/qol_assessment.dart`
- `lib/features/qol/models/qol_response.dart`
- `lib/features/qol/models/qol_domain.dart`
- `lib/features/qol/models/qol_question.dart`
- `lib/features/qol/models/qol_trend_summary.dart`

**Services (2)**:
- `lib/features/qol/services/qol_service.dart`
- `lib/features/qol/services/qol_scoring_service.dart`

**Screens (3)**:
- `lib/features/qol/screens/qol_questionnaire_screen.dart`
- `lib/features/qol/screens/qol_history_screen.dart`
- `lib/features/qol/screens/qol_detail_screen.dart`

**Widgets (6)**:
- `lib/features/qol/widgets/qol_question_card.dart`
- `lib/features/qol/widgets/qol_radar_chart.dart`
- `lib/features/qol/widgets/qol_trend_line_chart.dart`
- `lib/features/qol/widgets/qol_score_summary_card.dart`
- `lib/features/qol/widgets/qol_interpretation_card.dart`
- `lib/features/home/widgets/qol_home_card.dart`

**Exceptions (1)**:
- `lib/features/qol/exceptions/qol_exceptions.dart`

**Providers (1)**:
- `lib/providers/qol_provider.dart`

**Tests (11)**:
- `test/features/qol/models/qol_assessment_test.dart`
- `test/features/qol/models/qol_response_test.dart`
- `test/features/qol/models/qol_domain_test.dart`
- `test/features/qol/models/qol_question_test.dart`
- `test/features/qol/services/qol_scoring_service_test.dart`
- `test/features/qol/services/qol_service_test.dart`
- `test/features/qol/providers/qol_provider_test.dart`
- `test/features/qol/widgets/qol_question_card_test.dart`
- `test/features/qol/widgets/qol_radar_chart_test.dart`
- `test/features/qol/widgets/qol_score_summary_card_test.dart`
- `test/features/qol/widgets/qol_home_card_test.dart`
- `test/features/qol/integration/qol_flow_test.dart`

**Documentation (1)**:
- (This file will be moved to `~PLANNING/DONE/` after completion)

---

**Modified Files** (7 files):

- `lib/app/router.dart` - Add QoL routes
- `lib/features/profile/screens/profile_screen.dart` - Add navigation tile
- `lib/features/home/screens/home_screen.dart` - Add QolHomeCard
- `lib/shared/models/daily_summary.dart` - Add QoL score fields
- `lib/l10n/app_en.arb` - Add ~150 localization keys
- `.cursor/reference/analytics_list.md` - Add QoL analytics events
- `test/tests_index.md` - Add QoL test files
- `.cursor/rules/firestore_schema.md` - Document QoL collection schema
- `firestore.indexes.json` - Add composite indexes

---

## Appendix B: Wright 2025 Study Integration

**Date Updated**: December 14, 2025

This implementation plan has been updated to incorporate findings from Wright et al. (2025) "The new Health-Related Quality of Life in Feline Chronic Kidney Disease Questionnaire demonstrates reliability and validity for use in feline clinical trials."

### Key Changes Made:

**1. Refined comfort_3 Question (Section 1)**
- **Old**: "How normal were your cat's bowel movements (straining, effort, stool consistency)?"
- **New**: "In the past 7 days, did your cat show signs of discomfort when using the litter box (straining, vocalizing, or spending a long time)?"
- **Rationale**: Focuses on observable discomfort rather than stool characteristics, addressing Wright's concern about ceiling effects while maintaining support from Lorbach 2022 findings (P=0.0003)

**2. Added Scientific Foundation Section (Section 0)**
- Documents three foundational studies (Bijsmans 2016, Lorbach 2022, Wright 2025)
- Highlights HydraCAT's unique Treatment Burden domain
- Explains multi-domain vs unidimensional approach
- Establishes scientific credibility without claiming affiliation

**3. Added Legal Safeguards Section (Section 2)**
- Required attributions for documentation and app
- Legal compliance checklist (naming, independence documentation)
- Risk assessment confirmation (LOW RISK)
- Optional IP attorney consultation recommendation

**4. Documented Future Enhancements (Section 1.1)**
- Coat condition question (P2 priority) - Wright 2025 factor loading 0.67
- "Appeared tired" refinement (P3 priority) - Wright 2025 factor loading 0.94
- Both deferred to post-launch validation based on user data

**5. Updated Localization (Section 5)**
- New comfort_3 response labels reflecting discomfort frequency
- Added scientific attribution key for settings/about screen
- Updated disclaimer text for legal compliance

**6. Added Scientific Validation Roadmap (Section 9)**
- 6-phase validation plan (usage data → reliability → validity → MCID → publication → continuous improvement)
- Concrete milestones with success criteria
- Timeline: 0-18+ months post-launch
- Provides legal protection through independent evidence base

### Scientific Validity Confirmation:

**Coverage of Wright 2025's 13 Items:**
- ✅ 8 of 14 HydraCAT questions have NO direct Wright equivalent (demonstrates independence)
- ✅ 6 questions share concepts but use different wording (low legal risk)
- ✅ HydraCAT captures high-loading Wright items:
  - Difficulty jumping (0.79) → comfort_1, comfort_2
  - Moving slowly (0.87) → vitality_1, vitality_2
  - Active (0.81) → vitality_1, vitality_2, vitality_3
  - Appeared happy (0.79) → emotional_1
  - Hidden/alone (0.73) → emotional_3
  - Appeared tired (0.94) → partially covered by vitality_1
  - Less interest in food (0.75) → appetite_1, appetite_2, appetite_3

**Legal Risk Assessment**: **LOW**
- Questions sufficiently distinct from all published instruments
- Multi-domain structure differs from Wright's unidimensional approach
- Treatment Burden domain unique to HydraCAT
- Application context (consumer mobile app) differs from clinical trials
- Independent development process documented

**Next Actions**:
- None required for V1 implementation
- Post-launch: Begin Phase 1 validation data collection (Section 9)
- Optional: IP attorney consultation before app store submission ($500-1000)

---

**End of Implementation Plan**
