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

🚧 **Planned/Not Yet Implemented:**
- `labResults` - Bloodwork and lab test tracking
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
                  │     └── vetName: string               # optional
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
                  ├── labResults (subcollection)
                  │     │
                  │     └── {labId} (auto-generated)
                  │           ├── testDate: Timestamp        # date of bloodwork
                  │           ├── creatinine: number         # mg/dL, optional
                  │           ├── bun: number               # mg/dL, optional
                  │           ├── phosphorus: number        # mg/dL, optional
                  │           ├── bloodPressure: map        # {systolic: number, diastolic: number}, optional
                  │           ├── urineSpecificGravity: number # optional
                  │           ├── irisStage: string         # 1, 2, 3, 4, optional
                  │           ├── vetNotes: string          # optional
                  │           ├── createdAt: Timestamp
                  │           └── updatedAt: Timestamp
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
