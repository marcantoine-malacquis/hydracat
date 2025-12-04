# HydraCat Firestore Schema - Comprehensive CKD Management

## Overview
This schema supports comprehensive CKD management while maintaining strict cost optimization through pre-aggregated summaries, efficient query patterns, and minimal real-time listeners.

## Implementation Status
✅ **Fully Implemented:**
- `devices` - FCM token management and daily wake-up notifications
- `users` - User profiles and authentication
- `pets` - Pet profiles and management
- `fluidSessions` - Fluid therapy logging
- `medicationSessions` - Medication logging
- `treatmentSummaries` - Daily/weekly/monthly aggregations
- `schedules` - Treatment scheduling
- `schedules/history` - Schedule version history tracking for accurate historical data

✅ **Fully Implemented:**
- `healthParameters` - Weight, appetite, symptoms tracking (hybrid symptom model with rawValue + severityScore)
- `labResults` - Bloodwork and lab test tracking (models, services, UI, Firestore rules, and indexes implemented)

🚧 **Planned/Not Yet Implemented:**
- `fluidInventory` - Fluid volume tracking
- `crossPetSummaries` - Premium multi-pet analytics

## Design Notes

### Treatment Summaries Nested Structure
The treatment summaries use a nested collection pattern:
```
treatmentSummaries/
  ├── daily/summaries/{YYYY-MM-DD}
  ├── weekly/summaries/{YYYY-Www}
  └── monthly/summaries/{YYYY-MM}
```

This design provides:
- **Organization**: Groups related summary types under one parent collection
- **Extensibility**: Easy to add new summary types (e.g., yearly) without cluttering pet subcollections
- **Query flexibility**: Can query across all summary types or target specific periods
- **Cost optimization**: Maintains the same read cost while improving structure

### Hybrid Symptom Tracking Model
Symptoms in `healthParameters` use a hybrid model that stores both raw user inputs and severity scores:
- **Raw Values**: User-entered data (episode counts for vomiting, enum strings for others)
- **Severity Scores**: Symptoms scored 0-3 scale for consistent analytics
  - 0: None/normal
  - 1: Mild
  - 2: Moderate
  - 3: Severe

This approach provides:
- **Medically Accurate Inputs**: Tailored inputs per symptom (episodes, stool quality, appetite fraction, etc.)
- **Unified Analytics**: All symptoms use the same 0-3 severity scale for charts and summaries
- **Data Preservation**: Raw values stored for future analysis and vet reports

### Monthly Summary Daily Arrays Optimization
Monthly summaries include per-day arrays for efficient month-view rendering without requiring 28-31 daily summary reads:
- **dailyVolumes**: Array of daily fluid volumes (ml) for each day [28-31 elements]
- **dailyGoals**: Array of daily fluid goals (ml) for each day [28-31 elements]
- **dailyScheduledSessions**: Array of scheduled fluid session counts for each day [28-31 elements]
- **dailyMedicationDoses**: Array of completed medication doses for each day [28-31 elements]
- **dailyMedicationScheduledDoses**: Array of scheduled medication doses for each day [28-31 elements]

Array indexing:
- Index = day of month - 1 (day 1 = index 0, day 31 = index 30)
- Arrays are fixed-length matching the month length (28, 29, 30, or 31 elements)
- Missing/empty days default to 0

This design enables:
- **1-read month view**: Entire month calendar rendered from single monthly summary document
- **31-bar charts**: Monthly charts displayed without additional queries
- **Cost optimization**: Reduces reads from 31 daily summaries to 1 monthly summary
- **Historical accuracy**: Arrays store point-in-time values even when schedules change mid-month

## Root Collections

### devices
```
devices/
├── {deviceId} (document)
│     ├── deviceId: string          (unique device identifier)
│     ├── userId: string?           (nullable - user ID if logged in)
│     ├── fcmToken: string?         (nullable - FCM token for push notifications)
│     ├── platform: string          (ios, android, web)
│     ├── hasFcmToken: boolean      (derived from fcmToken, for efficient querying)
│     ├── isActive: boolean         (false when token is invalid/expired)
│     ├── lastUsedAt: Timestamp     (update only once per session/day)
│     └── createdAt: Timestamp
```

**Purpose**: Tracks device registrations for FCM push notifications. Enables daily wake-up messages to schedule local notifications even when app hasn't been opened.

**Key Fields**:
- `hasFcmToken`: Automatically set based on `fcmToken` presence. Enables efficient composite queries.
- `isActive`: Set to `false` when FCM returns invalid token errors. Prevents sending to dead tokens.
- `userId`, `fcmToken`: Nullable to support devices before user login or token registration.

**Daily Wake-Up Query**:
```dart
// Used by Cloud Function to find devices for daily notification scheduling
Query activeDevices = db.collection('devices')
  .where('isActive', isEqualTo: true)
  .where('hasFcmToken', isEqualTo: true);
```

### users
```
users/
└── {userId} (document from Firebase Auth)
      ├── email: string
      ├── displayName: string
      ├── subscriptionTier: string           ("free", "premium")
      ├── subscriptionStatus: string         ("active", "cancelled", "expired")
      ├── subscriptionExpiresAt: Timestamp   (null for free users)
      ├── primaryPetId: string              (for free users, null for premium)
      ├── notificationSettings: map
      ├── appVersion: string
      ├── createdAt: Timestamp
      ├── updatedAt: Timestamp
      │
      ├── crossPetSummaries (subcollection) - PREMIUM ONLY
      │     ├── {YYYY-MM} (monthly cross-pet summaries)
      │     │     ├── totalPets: number
      │     │     ├── aggregatedTreatmentDays: number
      │     │     ├── aggregatedMissedDays: number
      │     │     ├── longestStreakAcrossPets: number
      │     │     ├── totalFluidVolume: number
      │     │     ├── totalMedicationDoses: number
      │     │     ├── createdAt: Timestamp
      │     │     └── updatedAt: Timestamp
      │     │
      │     └── {YYYY-Www} (weekly cross-pet summaries)
      │           ├── totalPets: number
      │           ├── aggregatedTreatmentDays: number
      │           ├── aggregatedMissedDays: number
      │           ├── startDate: Timestamp
      │           ├── endDate: Timestamp
      │           ├── createdAt: Timestamp
      │           └── updatedAt: Timestamp
      │
      ├── fluidInventory (subcollection)
      │     └── {inventoryId}  # e.g., "main"
      │           ├── initialVolume: number       # volume entered at the start (ml)
      │           ├── remainingVolume: number     # updated after each session
      │           ├── thresholdVolume: number     # for triggering low-fluid notifications
      │           ├── lastUpdatedAt: Timestamp
      │           └── createdAt: Timestamp
      │
      └── pets (subcollection)
            │
            └── {petId} (auto-generated)
                  ├── id: string                      # petId (same as document ID)
                  ├── userId: string                  # owner's user ID
                  ├── name: string                    # pet's name
                  ├── ageYears: number               # pet's age in years
                  ├── weightKg: number               # optional, weight in kilograms
                  ├── breed: string                  # optional
                  ├── gender: string                 # optional: "male", "female"
                  ├── dateOfBirth: Timestamp         # optional
                  ├── photoUrl: string               # optional
                  ├── medicalInfo: map               # CKD medical information
                  │     ├── ckdDiagnosisDate: Timestamp    # optional
                  │     ├── ckdStage: number              # optional: 1-4
                  │     ├── vetName: string               # optional
                  │     └── latestLabResult: map?         # optional, denormalized snapshot of most recent lab result
                  │           ├── testDate: Timestamp          # date of most recent bloodwork
                  │           ├── creatinine: number?          # canonical value in mg/dL
                  │           ├── bun: number?                 # canonical value in mg/dL
                  │           ├── sdma: number?                # canonical value in µg/dL
                  │           ├── phosphorus: number?          # canonical value in mg/dL
                  │           ├── preferredUnitSystem: string? # "us" or "si" for UI display
                  │           └── labResultId: string?         # reference to source document in labResults subcollection
                  ├── lastFluidInjectionSite: string # optional, enum name for injection site rotation
                  ├── lastFluidSessionDate: Timestamp # optional, for injection site rotation tracking
                  ├── createdAt: Timestamp
                  └── updatedAt: Timestamp
                  │
                  ├── fluidSessions (subcollection)
                  │     │
                  │     └── {sessionId}
                  │           ├── id: string                      # session ID (UUID)
                  │           ├── petId: string                   # reference to pet
                  │           ├── userId: string                  # user who logged it
                  │           ├── dateTime: Timestamp             # when treatment occurred
                  │           ├── volumeGiven: number             # ml of fluid administered
                  │           ├── injectionSite: string           # required: enum name (e.g., "shoulderBladeLeft")
                  │           ├── stressLevel: string             # optional: "low", "medium", "high"
                  │           ├── notes: string                   # optional
                  │           ├── scheduleId: string              # optional, linked schedule
                  │           ├── scheduledTime: Timestamp        # optional, original scheduled time
                  │           ├── dailyGoalMl: number            # optional, goal at time of session
                  │           ├── calculatedFromWeight: boolean   # optional, whether volume calculated from weight
                  │           ├── initialBagWeightG: number      # optional, for weight calculator
                  │           ├── finalBagWeightG: number        # optional, for weight calculator
                  │           ├── createdAt: Timestamp           # when user logged it
                  │           └── updatedAt: Timestamp           # optional, last modification time
                  │
                  ├── medicationSessions (subcollection)
                  │     │
                  │     └── {sessionId}
                  │           ├── id: string                      # session ID (UUID)
                  │           ├── petId: string                   # reference to pet
                  │           ├── userId: string                  # user who logged it
                  │           ├── dateTime: Timestamp             # when treatment occurred
                  │           ├── medicationName: string
                  │           ├── dosageGiven: number             # actual dose given
                  │           ├── dosageScheduled: number         # prescribed dose
                  │           ├── medicationUnit: string          # "pills", "ml", "mg", "drops", etc.
                  │           ├── medicationStrengthAmount: string # optional, e.g., "2.5", "10"
                  │           ├── medicationStrengthUnit: string  # optional, e.g., "mg", "mgPerMl"
                  │           ├── customMedicationStrengthUnit: string # optional, for "other" strength unit
                  │           ├── completed: boolean              # true if given, false if missed
                  │           ├── notes: string                   # optional
                  │           ├── scheduleId: string              # optional, linked schedule
                  │           ├── scheduledTime: Timestamp        # optional, original scheduled time
                  │           ├── createdAt: Timestamp            # when user logged it
                  │           └── updatedAt: Timestamp            # optional, last modification time
                  │
                  ├── healthParameters (subcollection)
                  │     │
                  │     └── {YYYY-MM-DD} (date-based document ID)
                  │           ├── date: Timestamp            # date this health parameter is for
                  │           ├── weight: number             # kg, optional
                  │           ├── appetite: string           # all/3-4/half/1-4/nothing, optional
                  │           ├── symptoms: map              # per-symptom entries with rawValue + severityScore, optional
                  │           │     ├── vomiting: map
                  │           │     │     ├── rawValue: number     # number of episodes (0-10+)
                  │           │     │     └── severityScore: number # severity 0-3
                  │           │     ├── diarrhea: map
                  │           │     │     ├── rawValue: string     # enum: "normal", "soft", "loose", "watery"
                  │           │     │     └── severityScore: number # severity 0-3
                  │           │     ├── constipation: map
                  │           │     │     ├── rawValue: string     # enum: "normal", "mildStraining", "noStool", "painful"
                  │           │     │     └── severityScore: number # severity 0-3
                  │           │     ├── energy: map          # renamed from lethargy
                  │           │     │     ├── rawValue: string     # enum: "normal", "slightlyReduced", "low", "veryLow"
                  │           │     │     └── severityScore: number # severity 0-3
                  │           │     ├── suppressedAppetite: map
                  │           │     │     ├── rawValue: string     # enum: "all", "threeQuarters", "half", "quarter", "nothing"
                  │           │     │     └── severityScore: number # severity 0-3
                  │           │     └── injectionSiteReaction: map
                  │           │           ├── rawValue: string     # enum: "none", "mildSwelling", "visibleSwelling", "redPainful"
                  │           │           └── severityScore: number # severity 0-3
                  │           ├── hasSymptoms: boolean       # true if any symptom severityScore > 0, optional
                  │           ├── symptomScoreTotal: number  # sum of all present severity scores (0-18 for 6 symptoms × max 3 each), optional
                  │           ├── symptomScoreAverage: number # average of present severity scores (0-3), optional
                  │           ├── notes: string              # optional daily health notes
                  │           ├── createdAt: Timestamp
                  │           └── updatedAt: Timestamp
                  │
                  ├── labResults (subcollection) - **APPEND-ONLY**: Historical bloodwork tracking
                  │     │
                  │     └── {labId} (auto-generated)
                  │           ├── testDate: Timestamp        # date of bloodwork (IMMUTABLE after creation)
                  │           │
                  │           ├── values: map                # structured analyte storage with flexible units
                  │           │     │
                  │           │     # Canonical Analyzer Keys (standardized across app):
                  │           │     # - creatinine: Primary kidney function marker
                  │           │     # - bun: Blood urea nitrogen
                  │           │     # - sdma: Symmetric dimethylarginine
                  │           │     # - phosphorus: Phosphate levels
                  │           │     # - potassium, calcium, etc. (add as needed)
                  │           │     │
                  │           │     # Each analyte entry structure:
                  │           │     ├── creatinine: map?     # optional - only present if user entered
                  │           │     │     ├── value: number        # REQUIRED if key present - value as entered by user
                  │           │     │     ├── unit: string         # REQUIRED - unit user entered (e.g., "mg/dL", "µmol/L")
                  │           │     │     ├── valueSi: number?     # optional - canonical SI conversion (µmol/L for creatinine)
                  │           │     │     ├── valueUs: number?     # optional - canonical US conversion (mg/dL for creatinine)
                  │           │     │     └── enteredUnit: string? # optional redundant field if `unit` captures this
                  │           │     │
                  │           │     ├── bun: map?           # optional - same structure as creatinine
                  │           │     │     ├── value: number
                  │           │     │     ├── unit: string         # e.g., "mg/dL" (US) or "mmol/L" (SI)
                  │           │     │     ├── valueSi: number?     # mmol/L
                  │           │     │     └── valueUs: number?     # mg/dL
                  │           │     │
                  │           │     ├── sdma: map?          # optional - typically "µg/dL" (same in US/SI)
                  │           │     │     ├── value: number
                  │           │     │     └── unit: string
                  │           │     │
                  │           │     ├── phosphorus: map?    # optional - same dual-unit structure
                  │           │     │     ├── value: number
                  │           │     │     ├── unit: string         # e.g., "mg/dL" (US) or "mmol/L" (SI)
                  │           │     │     ├── valueSi: number?
                  │           │     │     └── valueUs: number?
                  │           │     │
                  │           │     # Future analytes (potassium, calcium, albumin, etc.) follow same pattern
                  │           │     ├── customAnalyteKey: map? # extendable without schema changes
                  │           │     │
                  │           │     └── unitMetadata: map?  # optional map storing user preferences
                  │           │           └── preferredUnitSystem: string? # "us" or "si" for display preference
                  │           │
                  │           ├── metadata: map?            # optional metadata for context
                  │           │     ├── panelType: string?  # e.g., "fullPanel", "miniPanel", "seniorPanel"
                  │           │     ├── enteredBy: string?  # userId/deviceId who entered the data
                  │           │     ├── source: string?     # "manual", "import", "vetUpload"
                  │           │     ├── irisStage: string?  # 1-4 if IRIS stage provided with the panel
                  │           │     └── vetNotes: string?   # free-form vet comments/notes
                  │           │
                  │           ├── bloodPressure: map?       # optional blood pressure reading
                  │           │     ├── systolic: number
                  │           │     └── diastolic: number
                  │           │
                  │           ├── urineSpecificGravity: map? # optional USG measurement
                  │           │     ├── value: number       # e.g., 1.030
                  │           │     └── unit: string?       # typically dimensionless or "g/mL"
                  │           │
                  │           ├── createdAt: Timestamp      # when record was created (IMMUTABLE)
                  │           └── updatedAt: Timestamp      # last modification time
                  │
                  ├── treatmentSummaries (subcollection)
                  │     │
                  │     ├── daily (document) - organizational container
                  │     │     │
                  │     │     └── summaries (subcollection)
                  │     │           │
                  │     │           └── {YYYY-MM-DD} (e.g., "2025-10-05")
                  │     │                 ├── date: Timestamp           # for consistent querying
                  │     │                 │
                  │     │                 # Fluid Therapy Summary
                  │     │                 ├── fluidTotalVolume: number  # total fluid given this day
                  │     │                 ├── fluidTreatmentDone: boolean
                  │     │                 ├── fluidSessionCount: number  # number of fluid sessions
                  │     │                 ├── fluidScheduledSessions: number  # scheduled fluid sessions
                  │     │                 ├── fluidDailyGoalMl: number  # daily goal (optional)
                  │     │                 │
                  │     │                 # Medication Summary
                  │     │                 ├── medicationTotalDoses: number      # total doses given
                  │     │                 ├── medicationScheduledDoses: number  # total doses scheduled
                  │     │                 ├── medicationMissedCount: number     # missed doses
                  │     │                 │
                  │     │                 # Overall Treatment Adherence
                  │     │                 ├── overallTreatmentDone: boolean     # true if primary treatments completed
                  │     │                 ├── overallStreak: number            # consecutive days of adherence
                  │     │                 │
                  │     │                 # Symptom Tracking Summary
                  │     │                 ├── hadVomiting: boolean              # vomiting present (severityScore > 0)
                  │     │                 ├── hadDiarrhea: boolean              # diarrhea present (severityScore > 0)
                  │     │                 ├── hadConstipation: boolean          # constipation present (severityScore > 0)
                  │     │                 ├── hadEnergy: boolean               # energy present (severityScore > 0, renamed from lethargy)
                  │     │                 ├── hadSuppressedAppetite: boolean    # suppressed appetite present (severityScore > 0)
                  │     │                 ├── hadInjectionSiteReaction: boolean # injection site reaction present (severityScore > 0)
                  │     │                 ├── vomitingMaxScore: number          # max vomiting severity (0-3, optional)
                  │     │                 ├── diarrheaMaxScore: number          # max diarrhea severity (0-3, optional)
                  │     │                 ├── constipationMaxScore: number      # max constipation severity (0-3, optional)
                  │     │                 ├── energyMaxScore: number            # max energy severity (0-3, optional, renamed from lethargyMaxScore)
                  │     │                 ├── suppressedAppetiteMaxScore: number # max suppressed appetite severity (0-3, optional)
                  │     │                 ├── injectionSiteReactionMaxScore: number # max injection site reaction severity (0-3, optional)
                  │     │                 ├── vomitingRawValue: number          # episode count (optional)
                  │     │                 ├── diarrheaRawValue: string          # enum name (optional, e.g., "soft", "loose")
                  │     │                 ├── constipationRawValue: string      # enum name (optional)
                  │     │                 ├── energyRawValue: string            # enum name (optional)
                  │     │                 ├── suppressedAppetiteRawValue: string # enum name (optional)
                  │     │                 ├── injectionSiteReactionRawValue: string # enum name (optional)
                  │     │                 ├── symptomScoreTotal: number         # sum of all present severity scores (0-18, optional)
                  │     │                 ├── symptomScoreAverage: number       # average of present severity scores (0-3, optional)
                  │     │                 ├── hasSymptoms: boolean              # true if any symptom severityScore > 0
                  │     │                 │
                  │     │                 ├── createdAt: Timestamp
                  │     │                 └── updatedAt: Timestamp
                  │     │
                  │     ├── weekly (document) - organizational container
                  │     │     │
                  │     │     └── summaries (subcollection)
                  │     │           │
                  │     │           └── {YYYY-Www} (e.g., "2025-W40")
                  │     │                 ├── startDate: Timestamp
                  │     │                 ├── endDate: Timestamp
                  │     │                 │
                  │     │                 # Fluid Therapy Summary
                  │     │                 ├── fluidTotalVolume: number
                  │     │                 ├── fluidTreatmentDays: number
                  │     │                 ├── fluidMissedDays: number
                  │     │                 ├── fluidTreatmentDone: boolean
                  │     │                 ├── fluidSessionCount: number
                  │     │                 ├── fluidScheduledSessions: number
                  │     │                 ├── fluidScheduledVolume: number    # optional, weekly scheduled volume
                  │     │                 │
                  │     │                 # Medication Summary
                  │     │                 ├── medicationTotalDoses: number
                  │     │                 ├── medicationScheduledDoses: number
                  │     │                 ├── medicationMissedCount: number
                  │     │                 ├── medicationAvgAdherence: number   # average adherence for the week
                  │     │                 │
                  │     │                 # Overall Treatment Summary
                  │     │                 ├── overallTreatmentDays: number
                  │     │                 ├── overallMissedDays: number
                  │     │                 ├── overallTreatmentDone: boolean
                  │     │                 │
                  │     │                 # Symptom Tracking Summary
                  │     │                 ├── daysWithVomiting: number              # days with vomiting (severityScore > 0)
                  │     │                 ├── daysWithDiarrhea: number              # days with diarrhea (severityScore > 0)
                  │     │                 ├── daysWithConstipation: number          # days with constipation (severityScore > 0)
                  │     │                 ├── daysWithEnergy: number                # days with energy (severityScore > 0, renamed from daysWithLethargy)
                  │     │                 ├── daysWithSuppressedAppetite: number    # days with suppressed appetite (severityScore > 0)
                  │     │                 ├── daysWithInjectionSiteReaction: number # days with injection site reaction (severityScore > 0)
                  │     │                 ├── daysWithAnySymptoms: number           # count of days this week where hasSymptoms == true
                  │     │                 ├── symptomScoreTotal: number             # sum of daily symptomScoreTotal over week (0-126 for 7 days × max 18 each, optional)
                  │     │                 ├── symptomScoreAverage: number           # average daily severity score across days with symptoms (0-3, optional)
                  │     │                 ├── symptomScoreMax: number               # max daily symptomScoreTotal in week (0-18, optional)
                  │     │                 │
                  │     │                 ├── createdAt: Timestamp
                  │     │                 └── updatedAt: Timestamp
                  │     │
                  │     └── monthly (document) - organizational container
                  │           │
                  │           └── summaries (subcollection)
                  │                 │
                  │                 └── {YYYY-MM} (e.g., "2025-10")
                  │                       ├── monthId: string              # "YYYY-MM" format
                  │                       ├── startDate: Timestamp
                  │                       ├── endDate: Timestamp
                  │                       │
                  │                       # Fluid Therapy Summary
                  │                       ├── fluidTotalVolume: number
                  │                       ├── fluidTreatmentDays: number
                  │                       ├── fluidMissedDays: number
                  │                       ├── fluidLongestStreak: number
                  │                       ├── fluidCurrentStreak: number
                  │                       ├── fluidTreatmentDone: boolean
                  │                       ├── fluidSessionCount: number
                  │                       ├── fluidScheduledSessions: number
                  │                       │
                  │                       # Fluid Daily Arrays (for month view optimization)
                  │                       ├── dailyVolumes: array<number>          # per-day volumes [28-31 elements]
                  │                       ├── dailyGoals: array<number>            # per-day goals [28-31 elements]
                  │                       ├── dailyScheduledSessions: array<number> # per-day scheduled sessions [28-31 elements]
                  │                       │
                  │                       # Medication Summary
                  │                       ├── medicationTotalDoses: number
                  │                       ├── medicationScheduledDoses: number
                  │                       ├── medicationMissedCount: number
                  │                       ├── medicationMonthlyAdherence: number
                  │                       ├── medicationLongestStreak: number
                  │                       ├── medicationCurrentStreak: number
                  │                       │
                  │                       # Medication Daily Arrays
                  │                       ├── dailyMedicationDoses: array<number>  # per-day completed doses [28-31 elements]
                  │                       ├── dailyMedicationScheduledDoses: array<number> # per-day scheduled doses [28-31 elements]
                  │                       │
                  │                       # Overall Treatment Summary
                  │                       ├── overallTreatmentDays: number
                  │                       ├── overallMissedDays: number
                  │                       ├── overallLongestStreak: number
                  │                       ├── overallCurrentStreak: number
                  │                       ├── overallTreatmentDone: boolean
                  │                       │
                  │                       # Weight Tracking
                  │                       ├── weightEntriesCount: number           # optional
                  │                       ├── weightLatest: number                 # optional, kg
                  │                       ├── weightLatestDate: Timestamp          # optional
                  │                       ├── weightFirst: number                  # optional, kg
                  │                       ├── weightFirstDate: Timestamp           # optional
                  │                       ├── weightAverage: number                # optional, kg
                  │                       ├── weightChange: number                 # optional, kg (change from previous month)
                  │                       ├── weightChangePercent: number          # optional, percentage
                  │                       ├── weightTrend: string                  # optional: "increasing", "stable", "decreasing"
                  │                       │
                  │                       # Symptom Tracking Summary
                  │                       ├── daysWithVomiting: number              # days with vomiting (severityScore > 0)
                  │                       ├── daysWithDiarrhea: number              # days with diarrhea (severityScore > 0)
                  │                       ├── daysWithConstipation: number          # days with constipation (severityScore > 0)
                  │                       ├── daysWithEnergy: number                # days with energy (severityScore > 0, renamed from daysWithLethargy)
                  │                       ├── daysWithSuppressedAppetite: number    # days with suppressed appetite (severityScore > 0)
                  │                       ├── daysWithInjectionSiteReaction: number # days with injection site reaction (severityScore > 0)
                  │                       ├── daysWithAnySymptoms: number             # count of days this month where hasSymptoms == true
                  │                       ├── symptomScoreTotal: number             # sum of daily symptomScoreTotal over month (0-558 for 31 days × max 18 each, optional)
                  │                       ├── symptomScoreAverage: number           # average daily severity score across days with symptoms (0-3, optional)
                  │                       ├── symptomScoreMax: number               # max daily symptomScoreTotal in month (0-18, optional)
                  │                       │
                  │                       ├── createdAt: Timestamp
                  │                       └── updatedAt: Timestamp
                  │
                  └── schedules (subcollection)
                        │
                        └── {scheduleId}
                              ├── id: string                 # schedule ID (same as document ID)
                              ├── treatmentType: string      # "fluid", "medication"
                              │
                              # Fluid Schedule Fields
                              ├── targetVolume: number       # ml, for fluid schedules only
                              ├── preferredLocation: string  # for fluid schedules only (enum name)
                              ├── needleGauge: string       # for fluid schedules only
                              │
                              # Medication Schedule Fields
                              ├── medicationName: string     # for medication schedules only
                              ├── targetDosage: number       # for medication schedules only
                              ├── medicationUnit: string     # "pills", "ml", "mg", "drops", "capsules", etc.
                              ├── medicationStrengthAmount: string  # optional, e.g., "2.5", "10"
                              ├── medicationStrengthUnit: string    # optional, e.g., "mg", "mgPerMl"
                              ├── customMedicationStrengthUnit: string # optional, for "other" strength unit
                              │
                              # Common Schedule Fields
                              ├── frequency: string          # "onceDaily", "twiceDaily", "thriceDaily", etc.
                              ├── reminderTimes: array       # array of Timestamp objects (DateTime values)
                              ├── isActive: boolean
                              ├── createdAt: Timestamp
                              ├── updatedAt: Timestamp
                              │
                              └── history (subcollection)    # Schedule version history
                                    │
                                    └── {millisecondsSinceEpoch} (document ID is effectiveFrom timestamp)
                                          ├── scheduleId: string              # parent schedule ID
                                          ├── effectiveFrom: Timestamp        # when this version became active
                                          ├── effectiveTo: Timestamp?         # when this version stopped (null if current)
                                          ├── treatmentType: string           # "fluid", "medication"
                                          ├── frequency: string               # treatment frequency
                                          ├── reminderTimesIso: array         # ["09:00:00", "21:00:00"] - ISO time strings
                                          │
                                          # Medication History Fields
                                          ├── medicationName: string?
                                          ├── targetDosage: number?
                                          ├── medicationUnit: string?
                                          ├── medicationStrengthAmount: string?
                                          ├── medicationStrengthUnit: string?
                                          ├── customMedicationStrengthUnit: string?
                                          │
                                          # Fluid History Fields
                                          ├── targetVolume: number?
                                          ├── preferredLocation: string?
                                          └── needleGauge: string?
```

## Schedule History

### Purpose
The `history` subcollection under each schedule tracks all changes to the schedule over time, enabling accurate display of historical reminder times and treatment details. This solves the problem of showing incorrect schedule data when viewing past dates in the calendar after a schedule has been modified.

### When History Entries Are Created
- **On Schedule Creation**: Initial snapshot saved with `effectiveFrom = createdAt`, `effectiveTo = null`
- **Before Schedule Update**: Current version saved with `effectiveTo = now`, new version saved with `effectiveFrom = now`
- **Document ID**: Uses `millisecondsSinceEpoch` of `effectiveFrom` for efficient chronological ordering

### Key Features
- **Changelog Pattern**: Immutable snapshots preserve exact schedule state at any point in time
- **Date Range Queries**: Each entry has `effectiveFrom` and `effectiveTo` timestamps defining validity period
- **ISO Time Strings**: Reminder times stored as "HH:mm:ss" strings to avoid timezone complications
- **Backward Compatible**: Falls back to current schedule if no history exists

### Query Patterns
```dart
// Get schedule state as it was on a specific date
Query historicalSchedule = schedule
  .collection('history')
  .where('effectiveFrom', isLessThanOrEqualTo: date)
  .orderBy('effectiveFrom', descending: true)
  .limit(1);

// Get all history for audit/debugging
Query allHistory = schedule
  .collection('history')
  .orderBy('effectiveFrom', descending: true);
```

### Example Timeline
```
Nov 1-10:  Benazepril 2.5mg twice daily (9am, 9pm)
Nov 11-20: Benazepril 5mg once daily (10am)        ← Schedule updated
Nov 21+:   Benazepril 5mg twice daily (8am, 8pm)   ← Schedule updated again

History entries:
├── {timestamp-nov-1}  → effectiveFrom: Nov 1,  effectiveTo: Nov 11
├── {timestamp-nov-11} → effectiveFrom: Nov 11, effectiveTo: Nov 21
└── {timestamp-nov-21} → effectiveFrom: Nov 21, effectiveTo: null (current)
```

When viewing calendar for Nov 5, query returns first entry showing 9am/9pm times.
When viewing calendar for Nov 15, query returns second entry showing 10am time.

## Query Patterns for Cost Optimization

### Free Users (30-day limitation)
```dart
// Daily summaries for recent period
Query recentSummaries = pet
  .collection('treatmentSummaries')
  .doc('daily')
  .collection('summaries')
  .where('date', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
  .orderBy('date', descending: true)
  .limit(30);

// Recent sessions (when detail needed)
Query recentFluidSessions = pet.collection('fluidSessions')
  .where('dateTime', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
  .orderBy('dateTime', descending: true)
  .limit(20);
```

### Premium Users (unlimited access)
```dart
// Monthly summaries for long-term trends
Query monthlySummaries = pet
  .collection('treatmentSummaries')
  .doc('monthly')
  .collection('summaries')
  .orderBy('startDate', descending: true)
  .limit(12); // Last 12 months

// Cross-pet analytics
Query crossPetMonthlies = user.collection('crossPetSummaries')
  .orderBy('createdAt', descending: true)
  .limit(12);

// Recent sessions per treatment type (for detailed reports)
Query recentFluidSessions = pet.collection('fluidSessions')
  .orderBy('dateTime', descending: true)
  .limit(20); // Last 20 fluid sessions

Query recentMedicationSessions = pet.collection('medicationSessions')
  .orderBy('dateTime', descending: true)
  .limit(20); // Last 20 medication sessions
```

### Real-time Listeners (Cost-Optimized)
```dart
// Only listen to today's summary and current pet profile
StreamSubscription todaySummaryListener = pet
  .collection('treatmentSummaries')
  .doc('daily')
  .collection('summaries')
  .doc(todayDateString)
  .snapshots()
  .listen((doc) => updateHomeScreen(doc));

StreamSubscription petProfileListener = pet
  .snapshots()
  .listen((doc) => updatePetInfo(doc));
```

## Security Rules Considerations

### Premium Feature Protection
```javascript
// In Firestore Security Rules
function isPremiumUser() {
  return resource.data.subscriptionStatus == 'active' && 
         resource.data.subscriptionExpiresAt > request.time;
}

function isRecentData(timestamp) {
  return timestamp > request.time - duration.days(30);
}

// Allow free users only recent data
allow read: if isOwner(resource) &&
               (isPremiumUser() || isRecentData(resource.data.date));
```

## Lab Results: Security Rules & Indexes

### Security Rules Requirements

#### Owner-Only Access
Lab results contain sensitive medical data and must be strictly protected:

```javascript
// In firestore.rules for labResults subcollection
match /users/{userId}/pets/{petId}/labResults/{labId} {
  // Helper function to check ownership
  function isOwner() {
    return request.auth != null && request.auth.uid == userId;
  }

  // Helper function to validate lab result structure
  function isValidLabResult(data) {
    return data.keys().hasAll(['testDate', 'values', 'createdAt']) &&
           data.testDate is timestamp &&
           data.values is map &&
           data.createdAt is timestamp &&
           // Ensure at least one analyte is present
           data.values.size() > 0 &&
           // Validate numeric values are positive
           validateAnalyteValues(data.values);
  }

  // Helper to validate analyte values
  function validateAnalyteValues(values) {
    // For each analyte present, ensure value > 0 and unit is a string
    return values.keys().all(key =>
      (!values[key].keys().hasAll(['value']) ||
       (values[key].value is number && values[key].value >= 0)) &&
      (!values[key].keys().hasAll(['unit']) || values[key].unit is string)
    );
  }

  // Read: Owner only
  allow read: if isOwner();

  // Create: Owner only, with validation
  allow create: if isOwner() &&
                   isValidLabResult(request.resource.data);

  // Update: Owner only, with immutability checks
  allow update: if isOwner() &&
                   isValidLabResult(request.resource.data) &&
                   // Prevent modification of immutable fields
                   request.resource.data.testDate == resource.data.testDate &&
                   request.resource.data.createdAt == resource.data.createdAt;

  // Delete: Owner only (consider making append-only by removing this)
  allow delete: if isOwner();
}
```

#### Immutability Enforcement
Key fields should be immutable after creation:
- `testDate`: Cannot be changed (prevents backdating/forward-dating historical records)
- `createdAt`: Cannot be changed (audit trail integrity)
- Consider making `labResults` **append-only** by removing delete permissions

#### Validation Rules
- All analyte values must be non-negative numbers
- `testDate` must be a valid timestamp (cannot be in the future)
- At least one analyte must be present in the `values` map
- Unit fields must be non-empty strings

### Required Firestore Indexes

#### Per-Pet Lab History Query
**Purpose**: Retrieve lab results for a specific pet, sorted by test date (most recent first)

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

**Query Pattern**:
```dart
// Get recent lab results for a pet
Query labHistory = pet
  .collection('labResults')
  .orderBy('testDate', descending: true)
  .limit(20);
```

#### Optional: Cross-Pet Lab Queries (Premium Feature)
**Purpose**: Query lab results across all pets for a user (future premium analytics)

```json
{
  "collectionGroup": "labResults",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    {
      "fieldPath": "metadata.enteredBy",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "testDate",
      "order": "DESCENDING"
    }
  ]
}
```

**Query Pattern**:
```dart
// Get all lab results for user's pets (premium feature)
Query allUserLabs = db.collectionGroup('labResults')
  .where('metadata.enteredBy', isEqualTo: userId)
  .orderBy('testDate', descending: true)
  .limit(50);
```

### Index Deployment
Add these indexes to `firestore.indexes.json`:

```json
{
  "indexes": [
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
  ]
}
```

Deploy with:
```bash
firebase deploy --only firestore:indexes
```

### Access Pattern Notes
- **No 30-day limitation for lab results**: All users (free + premium) have access to complete lab history
- **Denormalized latest result**: `medicalInfo.latestLabResult` provides instant access without subcollection query
- **Query cost optimization**: Most UI screens use the denormalized snapshot; full history only loaded on-demand

## Data Aggregation Strategy

### Daily Summary Updates
When a session is logged:
1. Write to session collection (`fluidSessions`, `medicationSessions`)
2. Update daily summary (`treatmentSummaries/daily/summaries/{YYYY-MM-DD}`)
3. Update weekly summary (`treatmentSummaries/weekly/summaries/{YYYY-Www}`)
4. Update monthly summary (`treatmentSummaries/monthly/summaries/{YYYY-MM}`)
   - Includes updating daily arrays (`dailyVolumes`, `dailyGoals`, `dailyScheduledSessions`, etc.)
   - Arrays are updated atomically by reading current array, modifying specific index, and writing back
5. Update cross-pet summaries for premium users (future)

### Cost-Efficient Batch Operations
```dart
WriteBatch batch = FirebaseFirestore.instance.batch();

// Add session
batch.set(sessionRef, sessionData);

// Update daily summary
final dailyRef = pet
  .collection('treatmentSummaries')
  .doc('daily')
  .collection('summaries')
  .doc(dateString);

batch.set(dailyRef, {
  'fluidTotalVolume': FieldValue.increment(volumeGiven),
  'fluidTreatmentDone': true,
  'updatedAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));

// Update weekly summary
final weeklyRef = pet
  .collection('treatmentSummaries')
  .doc('weekly')
  .collection('summaries')
  .doc(weekString);

batch.set(weeklyRef, {
  'fluidTotalVolume': FieldValue.increment(volumeGiven),
  'updatedAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));

// Update monthly summary with arrays
// Note: Monthly array updates require reading current array first,
// then updating specific index
final monthlyRef = pet
  .collection('treatmentSummaries')
  .doc('monthly')
  .collection('summaries')
  .doc(monthString);

// Arrays updated by MonthlyArrayHelper with per-day granularity
batch.set(monthlyRef, {
  'fluidTotalVolume': FieldValue.increment(volumeGiven),
  'dailyVolumes': updatedDailyVolumesArray,  // Modified at index (day-1)
  'dailyGoals': updatedDailyGoalsArray,      // Modified at index (day-1)
  'updatedAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));

await batch.commit();
```


This schema maintains your excellent cost optimization principles while supporting comprehensive CKD management, premium features, and future expansion capabilities.

---

## Lab Results Implementation Checklist

This checklist tracks the implementation of the `labResults` feature from schema to production. Refer to `~PLANNING/lab_values_implementation.md` for detailed phase breakdowns.

**Status**: Phases 1-5 complete ✅ | Core functionality fully implemented | QA and testing in progress

### Phase 1: Schema & Rules (Documentation) ✅
- [x] Finalize Firestore structure for `labResults` subcollection
- [x] Define denormalized snapshot field (`medicalInfo.latestLabResult`)
- [x] Document canonical analyzer keys and unit handling
- [x] Document security rules requirements
- [x] Specify required Firestore indexes

### Phase 2: Data Models & Services ✅
- [x] Create `LabResult` model with analytes and metadata
- [x] Create `LabMeasurement` model for individual analyte values
- [x] Add Firestore converters (`fromFirestore`/`toFirestore`)
- [x] Create `LatestLabSummary` model for denormalized field
- [x] Extend `PetService` with `createLabResult()` method
- [x] Extend `PetService` with `watchLabResults()` stream
- [x] Extend `PetService` with `getLabResults()` paginated method
- [x] Extend `PetService` with `getLabResult()` single result method
- [x] Update `MedicalInfo` model to include `latestLabResult` field
- [x] Add validation methods to all new models
- [ ] Write unit tests for models and serialization (deferred to Phase 7)
- [ ] Update existing tests that assumed inline `LabValues` (deferred to Phase 7)

### Phase 3: Onboarding Flow Integration ✅
- [x] Ensure `LabValuesInput` widget captures all required fields
- [x] Modify `OnboardingData.toCatProfile` to build `LabResultInput`
- [x] Update onboarding submission to write first lab result to subcollection
- [x] Update onboarding to set `medicalInfo.latestLabResult` snapshot
- [x] Use transaction/batch for atomic profile + lab result creation
- [x] Update onboarding validation for new structure
- [ ] Add test coverage for new metadata fields (deferred to Phase 7)

### Phase 4: Profile Screen Enhancements ✅
- [x] Add UI section in `CkdProfileScreen` to display lab history list
- [x] Reuse `LabValueDisplayWithGauge` for each entry
- [x] Implement "Add new lab result" flow
- [x] Implement "Edit lab values" functionality (append-only vs edit decision)
- [x] Update Riverpod providers with `labResultsProvider`
- [x] Add derived `latestLabResult` selector
- [x] Display metadata (test date, vet notes, panel type)
- [x] Implement empty state UI ("No lab history yet")

### Phase 5: Backend Rules & Index Implementation ✅
- [x] Update `firestore.rules` with `labResults` rules from schema doc
- [x] Add `isValidLabResult()` helper function to rules
- [x] Enforce immutability for `testDate` and `createdAt`
- [x] Update `firestore.indexes.json` with required indexes
- [x] Deploy rules: `firebase deploy --only firestore:rules`
- [x] Deploy indexes: `firebase deploy --only firestore:indexes`
- [ ] Test rules with unit tests or manual verification (deferred to Phase 7)

### Phase 6: Data Migration / Backfill ⏸️
- [ ] Write migration script to convert inline `medicalInfo.labValues` to subcollection (may not be needed if feature launched before production)
- [ ] Script should create single `labResults` doc with fallback metadata
- [ ] Script should update `medicalInfo.latestLabResult` denormalized field
- [ ] Use batched writes (respect Firestore limits: 500 writes/batch)
- [ ] Implement throttling to avoid rate limits
- [ ] Collect before/after counts for verification
- [ ] Document manual execution steps
- [ ] Run migration on development environment first
- [ ] Verify data integrity before production migration

### Phase 7: QA, Docs, & Handoff ⏳
- [ ] User testing: Onboarding with labs → verify Firestore writes
- [ ] User testing: Edit labs from profile → verify new history entry
- [ ] User testing: View lab history → verify sorting and display
- [ ] User testing: Offline/poor network scenarios
- [ ] Run `flutter analyze` after all code changes
- [x] Update `.cursor/rules/firestore_schema.md` (updated to reflect implementation status)
- [ ] Document provider usage in relevant architecture docs
- [ ] Add quick-start snippet for querying lab history
- [ ] Verify analytics events are tracked (if applicable)
- [ ] Update `.cursor/reference/analytics_list.md` (if applicable)

### Open Questions to Resolve Before Implementation
- [ ] **Edit/Delete**: Should lab entries be immutable (append-only) or editable?
- [ ] **Future Analytes**: Any additional analytes to plan for (potassium, calcium, etc.)?
- [ ] **CSV Import**: Will users import lab results from files? (affects metadata schema)
- [ ] **Treatment Summaries**: Should lab entries feed into treatment summaries automatically?
- [ ] **Unit System Default**: Should app default to US or SI units based on user location?
- [ ] **Validation**: Should app validate analyte values against clinical ranges?

### Implementation Notes
- **Cost Optimization**: Most reads use denormalized `latestLabResult`; full history loaded on-demand
- **All Users Access**: No 30-day limitation; free and premium users see complete lab history
- **Append-Only Pattern**: Consider making `labResults` immutable to preserve audit trail
- **Unit Flexibility**: Store both entered unit and canonical conversions for future unit toggling
- **Batched Writes**: Always use transactions/batches when updating pet doc + subcollection together
