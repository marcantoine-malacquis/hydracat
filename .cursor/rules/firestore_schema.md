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

🚧 **Planned/Not Yet Implemented:**
- `healthParameters` - Weight, appetite, symptoms tracking (UI placeholder exists)
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
                  ├── petName: string
                  ├── isPrimary: boolean               # true for primary pet (free users), false otherwise
                  ├── birthdayOrAge: Timestamp         # optional
                  ├── photoURL: string                # optional
                  ├── createdAt: Timestamp
                  └── updatedAt: Timestamp
                  │
                  ├── fluidSessions (subcollection)
                  │     │
                  │     └── {sessionId}
                  │           ├── dateTime: Timestamp
                  │           ├── volumeGiven: number (ml)
                  │           ├── notesOrComments: string    # optional
                  │           ├── stressLevel: string       # optional: low, medium, high
                  │           ├── injectionSite: string     # optional: left_flank, right_flank, etc.
                  │           ├── createdAt: Timestamp
                  │           └── updatedAt: Timestamp
                  │
                  ├── medicationSessions (subcollection)
                  │     │
                  │     └── {sessionId}
                  │           ├── dateTime: Timestamp
                  │           ├── medicationName: string
                  │           ├── dosageGiven: number        # actual dose given
                  │           ├── dosageScheduled: number    # prescribed dose
                  │           ├── administrationMethod: string # oral, liquid, injection, topical
                  │           ├── completed: boolean         # true if given, false if missed
                  │           ├── notesOrComments: string    # optional
                  │           ├── createdAt: Timestamp
                  │           └── updatedAt: Timestamp
                  │
                  ├── healthParameters (subcollection)
                  │     │
                  │     └── {YYYY-MM-DD} (date-based document ID)
                  │           ├── weight: number             # kg, optional
                  │           ├── appetite: string           # all/3-4/half/1-4/nothing, optional
                  │           ├── symptoms: string           # good/okay/concerning, optional
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
                  │     │                 ├── createdAt: Timestamp
                  │     │                 └── updatedAt: Timestamp
                  │     │
                  │     └── monthly (document) - organizational container
                  │           │
                  │           └── summaries (subcollection)
                  │                 │
                  │                 └── {YYYY-MM} (e.g., "2025-10")
                  │                       ├── startDate: Timestamp
                  │                       ├── endDate: Timestamp
                  │                       │
                  │                       # Fluid Therapy Summary
                  │                       ├── fluidTotalVolume: number
                  │                       ├── fluidTreatmentDays: number
                  │                       ├── fluidMissedDays: number
                  │                       ├── fluidLongestStreak: number
                  │                       ├── fluidCurrentStreak: number
                  │                       │
                  │                       # Medication Summary
                  │                       ├── medicationTotalDoses: number
                  │                       ├── medicationScheduledDoses: number
                  │                       ├── medicationMissedCount: number
                  │                       ├── medicationMonthlyAdherence: number
                  │                       ├── medicationLongestStreak: number
                  │                       ├── medicationCurrentStreak: number
                  │                       │
                  │                       # Overall Treatment Summary
                  │                       ├── overallTreatmentDays: number
                  │                       ├── overallMissedDays: number
                  │                       ├── overallLongestStreak: number
                  │                       ├── overallCurrentStreak: number
                  │                       ├── overallTreatmentDone: boolean
                  │                       │
                  │                       ├── createdAt: Timestamp
                  │                       └── updatedAt: Timestamp
                  │
                  └── schedules (subcollection)
                        │
                        └── {scheduleId}
                              ├── treatmentType: string      # "fluid", "medication"
                              │
                              # Fluid Schedule Fields
                              ├── targetVolume: number       # ml, for fluid schedules only
                              ├── preferredLocation: string  # for fluid schedules only
                              ├── needleGauge: string       # for fluid schedules only
                              │
                              # Medication Schedule Fields
                              ├── medicationName: string     # for medication schedules only
                              ├── targetDosage: string       # "1", "1/2", "2.5" - preserve original format
                              ├── medicationUnit: string     # "pills", "ml", "mg", "drops", "capsules", etc.
                              │
                              # Common Schedule Fields
                              ├── frequency: string          # "onceDaily", "twiceDaily", "thriceDaily", etc.
                              ├── reminderTimes: array       # ["08:00", "20:00"] - time strings in HH:MM format
                              ├── isActive: boolean
                              ├── createdAt: Timestamp
                              └── updatedAt: Timestamp
```

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

await batch.commit();
```


This schema maintains your excellent cost optimization principles while supporting comprehensive CKD management, premium features, and future expansion capabilities.
