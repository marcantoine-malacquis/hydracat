# HydraCat Firestore Schema - Comprehensive CKD Management

## Overview
This schema supports comprehensive CKD management while maintaining strict cost optimization through pre-aggregated summaries, efficient query patterns, and minimal real-time listeners.

## Root Collections

### devices
```
devices/
├── {deviceId} (document)
│     ├── userId: string
│     ├── fcmToken: string
│     ├── platform: string          (ios, android, web)
│     ├── lastUsedAt: Timestamp     (update only once per session/day)
│     └── createdAt: Timestamp
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
                  ├── treatmentSummaryDaily (subcollection)
                  │     │
                  │     └── {YYYY-MM-DD} (date-based document ID)
                  │           ├── date: Timestamp           # for consistent querying
                  │           │
                  │           # Fluid Therapy Summary
                  │           ├── fluidTotalVolume: number  # total fluid given this day
                  │           ├── fluidTreatmentDone: boolean
                  │           ├── fluidSessionCount: number  # number of fluid sessions
                  │           ├── fluidAvgStressLevel: string # low/medium/high
                  │           ├── fluidLastInjectionSite: string
                  │           │
                  │           # Medication Summary
                  │           ├── medicationTotalDoses: number      # total doses given
                  │           ├── medicationScheduledDoses: number  # total doses scheduled
                  │           ├── medicationAdherence: number       # percentage (0.0-1.0)
                  │           ├── medicationMissedCount: number     # missed doses
                  │           │
                  │           # Health Parameters Summary (from healthParameters collection)
                  │           ├── weightRecorded: boolean
                  │           ├── appetiteRecorded: boolean
                  │           ├── symptomsRecorded: boolean
                  │           │
                  │           # Overall Treatment Adherence
                  │           ├── overallTreatmentDone: boolean     # true if primary treatments completed
                  │           ├── overallStreak: number            # consecutive days of adherence
                  │           ├── overallAdherence: number         # combined adherence score (0.0-1.0)
                  │           │
                  │           ├── createdAt: Timestamp
                  │           └── updatedAt: Timestamp
                  │
                  ├── treatmentSummaryWeekly (subcollection)
                  │     │
                  │     └── {YYYY-Www} (e.g., "2025-W33")
                  │           ├── startDate: Timestamp
                  │           ├── endDate: Timestamp
                  │           │
                  │           # Fluid Therapy Summary
                  │           ├── fluidTotalVolume: number
                  │           ├── fluidTreatmentDays: number
                  │           ├── fluidMissedDays: number
                  │           ├── fluidAvgStressLevel: string
                  │           │
                  │           # Medication Summary
                  │           ├── medicationTotalDoses: number
                  │           ├── medicationScheduledDoses: number
                  │           ├── medicationAvgAdherence: number   # average adherence for the week
                  │           │
                  │           # Overall Treatment Summary
                  │           ├── overallTreatmentDays: number
                  │           ├── overallMissedDays: number
                  │           ├── overallAvgAdherence: number
                  │           │
                  │           ├── createdAt: Timestamp
                  │           └── updatedAt: Timestamp
                  │
                  ├── treatmentSummaryMonthly (subcollection)
                  │     │
                  │     └── {YYYY-MM} (e.g., "2025-08")
                  │           ├── startDate: Timestamp
                  │           ├── endDate: Timestamp
                  │           │
                  │           # Fluid Therapy Summary
                  │           ├── fluidTotalVolume: number
                  │           ├── fluidTreatmentDays: number
                  │           ├── fluidMissedDays: number
                  │           ├── fluidLongestStreak: number
                  │           ├── fluidCurrentStreak: number
                  │           ├── fluidDailyVolumes: map          # { "01": 50, "02": 40, ... }
                  │           │
                  │           # Medication Summary
                  │           ├── medicationTotalDoses: number
                  │           ├── medicationScheduledDoses: number
                  │           ├── medicationMonthlyAdherence: number
                  │           ├── medicationLongestStreak: number
                  │           ├── medicationCurrentStreak: number
                  │           │
                  │           # Health Monitoring Summary
                  │           ├── weightEntriesCount: number
                  │           ├── appetiteEntriesCount: number
                  │           ├── symptomsEntriesCount: number
                  │           │
                  │           # Overall Treatment Summary
                  │           ├── overallTreatmentDays: number
                  │           ├── overallMissedDays: number
                  │           ├── overallLongestStreak: number
                  │           ├── overallCurrentStreak: number
                  │           ├── overallMonthlyAdherence: number
                  │           │
                  │           ├── createdAt: Timestamp
                  │           └── updatedAt: Timestamp
                  │
                  └── schedules (subcollection)
                        │
                        └── {scheduleId}
                              ├── treatmentType: string      # "fluid", "medication"
                              ├── medicationName: string     # only for medication schedules
                              ├── frequency: string          # daily, alternate_days, twice_daily, etc.
                              ├── targetVolume: number       # ml, for fluid schedules
                              ├── targetDosage: number       # for medication schedules
                              ├── reminderTimes: array       # array of time strings
                              ├── isActive: boolean
                              ├── createdAt: Timestamp
                              └── updatedAt: Timestamp
```

## Query Patterns for Cost Optimization

### Free Users (30-day limitation)
```dart
// Daily summaries for recent period
Query recentSummaries = pet.collection('treatmentSummaryDaily')
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
Query monthlySummaries = pet.collection('treatmentSummaryMonthly')
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
  .collection('treatmentSummaryDaily')
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
2. Update daily summary (`treatmentSummaryDaily/{YYYY-MM-DD}`)
3. Update weekly summary if needed (`treatmentSummaryWeekly/{YYYY-Www}`)
4. Update monthly summary if needed (`treatmentSummaryMonthly/{YYYY-MM}`)
5. Update cross-pet summaries for premium users

### Cost-Efficient Batch Operations
```dart
WriteBatch batch = FirebaseFirestore.instance.batch();

// Add session
batch.set(sessionRef, sessionData);

// Update daily summary
batch.update(dailySummaryRef, {
  'fluidTotalVolume': FieldValue.increment(volumeGiven),
  'fluidTreatmentDone': true,
  'updatedAt': FieldValue.serverTimestamp(),
});

// Update weekly summary
batch.update(weeklySummaryRef, {
  'fluidTotalVolume': FieldValue.increment(volumeGiven),
  'updatedAt': FieldValue.serverTimestamp(),
});

await batch.commit();
```


This schema maintains your excellent cost optimization principles while supporting comprehensive CKD management, premium features, and future expansion capabilities.
