alwaysApply: true
globs: ["**/*.dart"]

devices
│
├── {deviceId} (document)
│     ├── userId: string
│     ├── fcmToken: string
│     ├── platform: string          (ios, android, web)
│     ├── lastUsedAt: Timestamp     (update only once per session/day)
│     └── createdAt: Timestamp
│
users
│
└── {userId} (document from Firebase Auth)
      ├── email: string
      ├── displayName: string
      ├── notificationSettings: map
      ├── appVersion: string
      ├── createdAt: Timestamp
      ├── updatedAt: Timestamp
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
                  ├── birthdayOrAge: Timestamp       # optional
                  ├── photoURL: string              # optional
                  ├── createdAt: Timestamp
                  └── updatedAt: Timestamp
                  │
                  ├── weights (subcollection)
                  │     │
                  │     └── {weightId}
                  │           ├── date: Timestamp
                  │           ├── weight: number (kg)
                  │           ├── createdAt: Timestamp
                  │           └── updatedAt: Timestamp
                  │
                  ├── fluidSessions (subcollection)
                  │     │
                  │     └── {sessionId}
                  │           ├── dateTime: Timestamp
                  │           ├── volumeGiven: number (ml)
                  │           ├── notesOrComments: string  # optional
                  │           ├── stressLevel: string       # optional, e.g., low, medium, high
                  │           ├── injectionSite: string     # optional, e.g., left_flank, right_flank
                  │           ├── createdAt: Timestamp
                  │           └── updatedAt: Timestamp
                  │
                  ├── fluidSummaryDaily (subcollection)
                  │     │
                  │     └── {summaryId} (e.g., "2025-08-15")
                  │           ├── totalVolume: number
                  │           ├── treatmentDone: boolean
                  │           ├── missedDays: number (optional)
                  │           ├── streakCount: number        # current consecutive treatment days
                  │           ├── averageStressLevel: string # optional, aggregate of daily sessions
                  │           ├── lastInjectionSite: string  # optional, last site used today
                  │           ├── createdAt: Timestamp
                  │           └── lastUpdatedAt: Timestamp
                  │
                  ├── fluidSummaryWeekly (subcollection)
                  │     │
                  │     └── {summaryId} (e.g., "2025-W33")
                  │           ├── totalVolume: number
                  │           ├── treatmentDays: number
                  │           ├── missedDays: number
                  │           ├── startDate: Timestamp
                  │           ├── endDate: Timestamp
                  │           ├── averageStressLevel: string # optional, weekly aggregate
                  │           ├── createdAt: Timestamp
                  │           └── lastUpdatedAt: Timestamp
                  │
                  ├── fluidSummaryMonthly (subcollection)
                  │     │
                  │     └── {summaryId} (e.g., "2025-08")
                  │           ├── totalVolume: number
                  │           ├── treatmentDays: number
                  │           ├── missedDays: number
                  │           ├── dailyVolumes: map         # { "2025-08-01": 50, "2025-08-02": 40, ... }
                  │           ├── longestStreak: number
                  │           ├── currentStreak: number
                  │           ├── averageStressLevel: string # optional, monthly aggregate
                  │           ├── createdAt: Timestamp
                  │           └── lastUpdatedAt: Timestamp
                  │
                  └── schedules (subcollection)
                        │
                        └── {scheduleId}
                              ├── frequency: string       (daily, alternate_days, etc.)
                              ├── targetVolume: number    (ml)
                              ├── reminderTimes: array    (Timestamps or strings)
                              ├── createdAt: Timestamp
                              └── updatedAt: Timestamp
