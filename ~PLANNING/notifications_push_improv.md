# ⚠️ DEPRECATED - See fcm_daily_wakeup_plan.md Instead

**This plan has been superseded by a simpler, industry-standard approach.**

This document outlined an over-engineered solution with Cloud Tasks, timezone calculations, and complex fallback logic. After analysis, we determined a much simpler approach is more appropriate.

**New plan:** `fcm_daily_wakeup_plan.md`

---

# ORIGINAL PLAN (For Reference Only)

# HydraCat Push Notification Enhancement  Implementation Plan

## Overview
Enhance the existing local notification system with a hybrid approach where the server schedules due-time notifications via Cloud Tasks, and an optional FCM data-only "seed" is sent only when the app hasn't checked in for 36–48 hours. This ensures users receive treatment reminders even if they don't open the app for multiple days.

**Architecture:** Hybrid (Server-orchestrated + local fallback)
- **Server due-time pushes (primary):** Cloud Tasks schedules per-occurrence notifications at exact due times.

- **Optional FCM data-only seed (fallback):** Sent only when inactivity >36–48h to let the app re-seed local notifications for the next 24h.
- **Result:** Reliable delivery without requiring daily app opens; offline/local fallback preserved.

**Key Principles:**
-  Build on existing local notifications (no replacement)
-  Server is source of truth; no per-send Firestore writes (cost-safe)
-  Timezone-safe using `timeZoneId` (IANA) rather than raw offsets (DST-safe)
-  Idempotency via stable `notificationId`; device-side dedup
-  Defensive fallbacks (Cloud Tasks → seed push on inactivity → app resume)
-  Comprehensive monitoring via Firebase Console; costs ~0 at small scale

---

## Technical Summary

### Problem Solved
**Current limitation:** If user doesn't open app for 48+ hours, no notifications scheduled
**Solution:** Server schedules per-occurrence due-time pushes (Cloud Tasks). If a device hasn't checked in for >36–48h, send a data-only seed to wake the app and re-seed local notifications for the next 24h.

### Architecture Changes

**Firestore Schema Updates (tiny):**
```
devices/{deviceId}:
  - deviceId: string (existing)
  - userId: string | null (existing)
  - fcmToken: string | null (existing)
  - hasFcmToken: boolean (NEW - true when valid token present)
  - platform: 'ios' | 'android' (existing)
  - timeZoneId: string (NEW - IANA, e.g., "Europe/Paris")
  - isActive: boolean (NEW - default true)
  - lastUsedAt: timestamp (existing; update ≤ daily)
  - createdAt: timestamp (existing)
```

Queries (server):
```
// Send to one user across devices
devices.where('userId', '==', userId).where('hasFcmToken', '==', true).where('isActive', '==', true)

// Cleanup on invalid token error
update device: { fcmToken: null, hasFcmToken: false, isActive: false }

// Do NOT use: where('fcmToken', '!=', null)
```

**Revised Server Flow (supersedes the old 7 AM silent push):**
```
When schedules are created/updated OR via a periodic worker:
  - Compute next 24 hours of occurrences in the user's timeZoneId
  - Enqueue one Cloud Task per occurrence (scheduleTime = due time UTC)

Cloud Task (at due time) -> HTTPS function sendDueNotification ->
  - Build idempotent FCM payload with stable notificationId
  - Send visible push (or data-only if you prefer app-side rendering)
  - On invalid/expired token: mark device inactive (single write)

Optional re-seed (inactivity fallback):
  - Daily/sparse Cloud Scheduler job finds devices with lastUsedAt >36–48h
  - Enqueue a data-only seed task for immediate delivery (or at local 00:05)
  - App wakes and re-seeds local notifications for the next 24h only
```

Note: The older offset-based hourly "7 AM silent push" approach below is kept for reference but is deprecated by the flow above.

**Operational guardrails:**
- Schedule only the next 24 hours on device while respecting iOS 64-pending cap; re-seed later.
- Use stable `notificationId` for idempotency and device-side dedup.
- Skip `lastSuccessfulFcmDate` for v1; rely on logs/metrics and `lastUsedAt` for inactivity.
- Avoid `where('fcmToken', '!=', null)`; use `hasFcmToken == true`.

**Cost Analysis (revised):**
- **FCM messages:** $0 (unlimited, free)
- **Cloud Functions + Cloud Tasks:** ~3–4 ops/user/day at small scale ≈ $0; low two-digit $/mo around 100K DAU
- **Firestore:** Near-zero (no per-send writes; only device updates and schedules)

---

## Prerequisites

Before starting implementation:
-  Existing local notification system working (Step 0.1-0.4 from reminder_plan.md completed)
-  Device token registration operational (DeviceTokenService implemented)
-  Firebase Messaging configured (firebase_messaging: ^16.0.0 in pubspec.yaml)
-  iOS APNs setup (Step 0.2 from reminder_plan.md) - Required for iOS FCM
  - If not completed: FCM will work on Android, iOS will rely on app resume fallback only

---

## Phase 0: Cloud Functions Infrastructure Setup

### Step 0.1: Initialize Cloud Functions project structure

**Goal:** Set up TypeScript-based Cloud Functions project with proper configuration

**Files to create/modify:**
- `functions/src/index.ts` (NEW - main entry point)
- `functions/src/scheduleDailyNotifications.ts` (NEW - scheduling logic)
- `functions/src/utils/timezoneUtils.ts` (NEW - timezone calculations)
- `functions/tsconfig.json` (NEW - TypeScript config)
- `functions/package.json` (MODIFY - add dependencies)
- `functions/.eslintrc.js` (EXISTING - verify config)

**Implementation details:**

1) **Install TypeScript and configure:**
```bash
cd functions
npm install --save-dev typescript @types/node
npm install firebase-admin@^12.6.0 firebase-functions@^6.0.1
```

2) **Create TypeScript config (`functions/tsconfig.json`):**
```json
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2017",
    "esModuleInterop": true
  },
  "compileOnSave": true,
  "include": [
    "src"
  ]
}
```

3) **Update package.json scripts:**
```json
{
  "scripts": {
    "lint": "eslint --ext .js,.ts .",
    "build": "tsc",
    "build:watch": "tsc --watch",
    "serve": "npm run build && firebase emulators:start --only functions",
    "shell": "npm run build && firebase functions:shell",
    "start": "npm run shell",
    "deploy": "npm run build && firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "engines": {
    "node": "18"
  },
  "main": "lib/index.js",
  "dependencies": {
    "firebase-admin": "^12.6.0",
    "firebase-functions": "^6.0.1"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "eslint": "^8.15.0",
    "eslint-config-google": "^0.14.0",
    "firebase-functions-test": "^3.1.0",
    "typescript": "^5.0.0"
  },
  "private": true
}
```

4) **Create source directory structure:**
```bash
mkdir -p functions/src/utils
```

**Testing:**
```bash
cd functions
npm run build
# Should compile successfully with no errors
```

**Commit message:** "chore: Set up TypeScript Cloud Functions infrastructure"

---

### Step 0.2: Create timezone utility functions
> Deprecated in favor of `timeZoneId` + Cloud Tasks (see Revised Server Flow). Kept for reference if you still want an hourly seed.

**Goal:** Calculate which timezone offsets are currently at 7 AM target time

**Files to create:**
- `functions/src/utils/timezoneUtils.ts` (NEW)

**Implementation:**

```typescript
// functions/src/utils/timezoneUtils.ts

/**
 * Calculates which timezone offsets (in minutes) are currently at the target hour.
 *
 * Example: If current UTC time is 12:00 and target hour is 7:00 AM,
 * then timezone offset -300 (UTC-5, EST) is at 7:00 AM.
 *
 * @param targetHour - Target hour in 24-hour format (0-23), default 7 for 7:00 AM
 * @returns Array of timezone offsets in minutes (e.g., [-300, -240, -180])
 */
export function calculateTargetTimezoneOffsets(targetHour: number = 7): number[] {
  const now = new Date();
  const currentUTCHour = now.getUTCHours();

  // Calculate how many hours behind UTC the timezone needs to be
  // to be at the target hour right now
  let hoursOffset = currentUTCHour - targetHour;

  // Handle day boundary wrap-around
  // Example: If UTC is 02:00 and target is 07:00, offset is -5 (wraps to previous day)
  if (hoursOffset < -12) {
    hoursOffset += 24;
  } else if (hoursOffset > 12) {
    hoursOffset -= 24;
  }

  // Convert hours to minutes
  const offsetMinutes = hoursOffset * 60;

  // Return array of offsets within +/-30 minutes window to handle:
  // 1. Partial hour timezones (e.g., India UTC+5:30)
  // 2. Slight time drift
  // 3. DST transition edge cases
  const offsets: number[] = [];
  for (let adjustment = -30; adjustment <= 30; adjustment += 30) {
    offsets.push(offsetMinutes + adjustment);
  }

  return offsets;
}

/**
 * Converts timezone offset in minutes to human-readable string.
 *
 * @param offsetMinutes - Timezone offset in minutes (e.g., -300)
 * @returns Human-readable string (e.g., "UTC-5:00")
 */
export function formatTimezoneOffset(offsetMinutes: number): string {
  const hours = Math.floor(Math.abs(offsetMinutes) / 60);
  const minutes = Math.abs(offsetMinutes) % 60;
  const sign = offsetMinutes >= 0 ? '+' : '-';

  return `UTC${sign}${hours}:${minutes.toString().padStart(2, '0')}`;
}

/**
 * Validates that a timezone offset is reasonable.
 * Valid range: UTC-12:00 to UTC+14:00 (covers all inhabited timezones)
 *
 * @param offsetMinutes - Timezone offset to validate
 * @returns true if valid, false otherwise
 */
export function isValidTimezoneOffset(offsetMinutes: number): boolean {
  return offsetMinutes >= -720 && offsetMinutes <= 840; // -12h to +14h
}
```

**Testing:**
```typescript
// Test in functions shell
const { calculateTargetTimezoneOffsets } = require('./lib/utils/timezoneUtils');

// If current UTC time is 12:00, and target is 7:00 AM
// Should return offsets near -300 (UTC-5, like EST)
console.log(calculateTargetTimezoneOffsets(7));
// Output: [-330, -300, -270]
```

**Commit message:** "feat: Add timezone calculation utilities for Cloud Functions"

---

### Step 0.3: Implement main scheduling Cloud Function

**Goal:** Create hourly function that sends FCM to devices in target timezones

**Files to create:**
- `functions/src/scheduleDailyNotifications.ts` (NEW)
- `functions/src/index.ts` (MODIFY - export function)

**Implementation:**

```typescript
// functions/src/scheduleDailyNotifications.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  calculateTargetTimezoneOffsets,
  formatTimezoneOffset,
  isValidTimezoneOffset,
} from './utils/timezoneUtils';

// Initialize Firebase Admin (done once)
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function that runs every hour to send daily scheduling triggers.
 *
 * Flow:
 * 1. Calculate which timezone offsets are currently at 7:00 AM
 * 2. Query devices in those timezones
 * 3. Send FCM silent push to wake app and trigger scheduling
 * 4. Track success/failure for each device
 *
 * Runs at: Every hour on the hour (e.g., 00:00, 01:00, 02:00... UTC)
 * Cost: $0 (720 invocations/month within 2M free tier)
 */
export const scheduleDailyNotifications = functions
  .runWith({
    timeoutSeconds: 540, // 9 minutes max (well within 10-minute limit)
    memory: '256MB', // Sufficient for batched FCM sends
  })
  .pubsub.schedule('0 * * * *') // Every hour at :00 minutes
  .timeZone('UTC')
  .onRun(async (context) => {
    const startTime = Date.now();

    functions.logger.info('=== Daily Notification Scheduler Started ===');
    functions.logger.info(`Execution time: ${new Date().toISOString()}`);

    try {
      // Step 1: Calculate target timezone offsets for 7:00 AM
      const targetOffsets = calculateTargetTimezoneOffsets(7);
      functions.logger.info(`Target offsets for 7:00 AM: ${targetOffsets.map(formatTimezoneOffset).join(', ')}`);

      let totalDevices = 0;
      let totalSent = 0;
      let totalFailed = 0;
      let invalidTokensRemoved = 0;

      // Step 2: Process each timezone offset
      for (const offset of targetOffsets) {
        if (!isValidTimezoneOffset(offset)) {
          functions.logger.warn(`Skipping invalid timezone offset: ${offset}`);
          continue;
        }

        // Step 3: Query active devices in this timezone
        const devicesSnapshot = await db.collection('devices')
          .where('isActive', '==', true)
          .where('timezoneOffsetMinutes', '==', offset)
          .where('fcmToken', '!=', null)
          .get();

        const devicesInTimezone = devicesSnapshot.size;
        totalDevices += devicesInTimezone;

        if (devicesInTimezone === 0) {
          functions.logger.info(`No devices in timezone ${formatTimezoneOffset(offset)}`);
          continue;
        }

        functions.logger.info(`Found ${devicesInTimezone} devices in ${formatTimezoneOffset(offset)}`);

        // Step 4: Batch send FCM messages (500 per batch, FCM limit)
        const messages: admin.messaging.Message[] = [];
        const deviceDocs: FirebaseFirestore.QueryDocumentSnapshot[] = [];

        for (const deviceDoc of devicesSnapshot.docs) {
          const device = deviceDoc.data();

          // Skip if no FCM token (shouldn't happen due to query filter, but be safe)
          if (!device.fcmToken) {
            continue;
          }

          // Build silent background message
          const message: admin.messaging.Message = {
            token: device.fcmToken,
            data: {
              type: 'schedule_today',
              timestamp: new Date().toISOString(),
              deviceId: device.deviceId,
            },
            // iOS-specific configuration for silent push
            apns: {
              headers: {
                'apns-priority': '5', // Low priority (background processing)
                'apns-push-type': 'background',
              },
              payload: {
                aps: {
                  contentAvailable: true, // Wakes app in background
                  // NO alert, sound, or badge = completely silent
                },
              },
            },
            // Android-specific configuration
            android: {
              priority: 'high', // Required for background processing
              data: {
                type: 'schedule_today',
                timestamp: new Date().toISOString(),
              },
            },
          };

          messages.push(message);
          deviceDocs.push(deviceDoc);
        }

        // Step 5: Send in batches of 500
        const batchSize = 500;
        for (let i = 0; i < messages.length; i += batchSize) {
          const batch = messages.slice(i, i + batchSize);
          const batchDeviceDocs = deviceDocs.slice(i, i + batchSize);

          try {
            const response = await messaging.sendEach(batch);

            // Track successes
            totalSent += response.successCount;
            totalFailed += response.failureCount;

            // Step 6: Handle individual results
            const batch = db.batch();
            let batchOperations = 0;

            response.responses.forEach((result, index) => {
              const deviceDoc = batchDeviceDocs[index];

              if (result.success) {
                // Update last successful FCM date
                batch.update(deviceDoc.ref, {
                  lastSuccessfulFcmDate: admin.firestore.FieldValue.serverTimestamp(),
                });
                batchOperations++;
              } else {
                // Handle failure
                const error = result.error;
                const token = batch[index].token;

                functions.logger.warn(`FCM send failed for device ${deviceDoc.id}: ${error?.code}`);

                // Remove invalid tokens
                if (
                  error?.code === 'messaging/invalid-registration-token' ||
                  error?.code === 'messaging/registration-token-not-registered'
                ) {
                  batch.update(deviceDoc.ref, {
                    fcmToken: null,
                    isActive: false,
                  });
                  batchOperations++;
                  invalidTokensRemoved++;
                  functions.logger.info(`Removed invalid token for device ${deviceDoc.id}`);
                } else {
                  // Other error: track failure but keep trying
                  batch.update(deviceDoc.ref, {
                    lastFcmFailureDate: admin.firestore.FieldValue.serverTimestamp(),
                  });
                  batchOperations++;
                }
              }
            });

            // Commit Firestore updates if any
            if (batchOperations > 0) {
              await batch.commit();
            }

          } catch (error) {
            functions.logger.error(`Batch send failed for timezone ${formatTimezoneOffset(offset)}:`, error);
            totalFailed += batch.length;
          }
        }
      }

      // Step 7: Log final summary
      const duration = Date.now() - startTime;
      functions.logger.info('=== Daily Notification Scheduler Complete ===');
      functions.logger.info(`Total devices queried: ${totalDevices}`);
      functions.logger.info(`Messages sent successfully: ${totalSent}`);
      functions.logger.info(`Messages failed: ${totalFailed}`);
      functions.logger.info(`Invalid tokens removed: ${invalidTokensRemoved}`);
      functions.logger.info(`Execution duration: ${duration}ms`);

      return {
        success: true,
        totalDevices,
        totalSent,
        totalFailed,
        invalidTokensRemoved,
        durationMs: duration,
      };

    } catch (error) {
      functions.logger.error('Fatal error in scheduleDailyNotifications:', error);
      throw error; // Rethrow to mark function as failed in Firebase Console
    }
  });
```

```typescript
// functions/src/index.ts

// Import function triggers
import {scheduleDailyNotifications} from './scheduleDailyNotifications';

// Export functions
export {scheduleDailyNotifications};
```

**Testing (local - will configure emulator in next step):**
```bash
cd functions
npm run build
# Should compile successfully
```

**Commit message:** "feat: Implement hourly Cloud Function for FCM daily triggers"

---

## Phase 1: Firebase Emulator Setup & Local Testing

### Step 1.1: Configure Firebase Local Emulator Suite

**Goal:** Set up local testing environment to iterate quickly without deploying to production

**Files to create/modify:**
- `firebase.json` (MODIFY - add emulator config)
- `.firebaserc` (EXISTING - verify project aliases)

**Implementation:**

1) **Install Firebase CLI (if not already installed):**
```bash
npm install -g firebase-tools
firebase --version
# Should show version 12.0.0 or higher
```

2) **Login to Firebase:**
```bash
firebase login
# Opens browser for authentication
```

3) **Initialize emulators:**
```bash
firebase init emulators
# Select: Functions, Firestore, Authentication
# Use default ports or customize:
#   - Functions: 5001
#   - Firestore: 8080
#   - Auth: 9099
```

4) **Update firebase.json configuration:**
```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "ignore": [
        "node_modules",
        ".git",
        "firebase-debug.log",
        "firebase-debug.*.log"
      ],
      "predeploy": [
        "npm --prefix \"$RESOURCE_DIR\" run build"
      ]
    }
  ],
  "emulators": {
    "functions": {
      "port": 5001
    },
    "firestore": {
      "port": 8080
    },
    "auth": {
      "port": 9099
    },
    "pubsub": {
      "port": 8085
    },
    "ui": {
      "enabled": true,
      "port": 4000
    },
    "singleProjectMode": true
  }
}
```

5) **Start emulators:**
```bash
firebase emulators:start
```

**Expected output:**
```
  functions: Loaded functions definitions from source: scheduleDailyNotifications.
  functions[us-central1-scheduleDailyNotifications]: pubsub function initialized.
  All emulators ready! It is now safe to connect your app.


   All emulators ready! It is now safe to connect your app.
 i  View Emulator UI at http://127.0.0.1:4000


+-----------+----------------+-----------------------------------------+
| Emulator  | Host:Port      | View in Emulator UI                     |
+-----------+----------------+-----------------------------------------+
| Functions | 127.0.0.1:5001 | http://127.0.0.1:4000/functions         |
| Firestore | 127.0.0.1:8080 | http://127.0.0.1:4000/firestore         |
| Auth      | 127.0.0.1:9099 | http://127.0.0.1:4000/auth              |
| Pub/Sub   | 127.0.0.1:8085 | n/a                                     |
+-----------+----------------+-----------------------------------------+
```

6) **Open Emulator UI in browser:**
```
http://localhost:4000
```

**Troubleshooting:**
- **Port already in use:** Change ports in firebase.json
- **Functions not loading:** Run `cd functions && npm run build` first
- **Java not found:** Install Java 11+ for Firestore emulator

**Commit message:** "chore: Configure Firebase Local Emulator Suite for development"

---

### Step 1.2: Configure Flutter app to use emulators

**Goal:** Point development Flutter app to local emulators instead of production Firebase

**Files to modify:**
- `lib/main_development.dart` (MODIFY - add emulator config)

**Implementation:**

```dart
// lib/main_development.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/app/app.dart';
import 'package:hydracat/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() {
    // Configure emulators for development flavor
    if (kDebugMode) {
      _configureEmulators();
    }

    return const App();
  });
}

/// Configure Firebase emulators for local development.
///
/// IMPORTANT: Only call this in development flavor and debug mode.
/// Never call in production builds.
void _configureEmulators() {
  try {
    // Firestore emulator
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    debugPrint('[Emulator] Connected to Firestore emulator at localhost:8080');

    // Auth emulator
    FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    debugPrint('[Emulator] Connected to Auth emulator at localhost:9099');

    // Functions emulator
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    debugPrint('[Emulator] Connected to Functions emulator at localhost:5001');

    debugPrint('[Emulator] All emulators configured successfully');
  } catch (e) {
    debugPrint('[Emulator] Error configuring emulators: $e');
    debugPrint('[Emulator] Make sure emulators are running: firebase emulators:start');
  }
}
```

**Testing:**
```bash
# Terminal 1: Start emulators
firebase emulators:start

# Terminal 2: Run app in development flavor
flutter run --flavor development -t lib/main_development.dart
```

**Expected logs:**
```
[Emulator] Connected to Firestore emulator at localhost:8080
[Emulator] Connected to Auth emulator at localhost:9099
[Emulator] Connected to Functions emulator at localhost:5001
[Emulator] All emulators configured successfully
```

**Commit message:** "feat: Configure Flutter development app to use Firebase emulators"

---

### Step 1.3: Test Cloud Function manually via emulator

**Goal:** Verify Cloud Function executes correctly before deploying to production

**Prerequisites:**
- Emulators running (`firebase emulators:start`)
- Sample device data in Firestore emulator

**Implementation:**

1) **Seed test data in Firestore emulator:**

Open Emulator UI (http://localhost:4000), navigate to Firestore, and create test device documents:

```
Collection: devices
Document ID: test-device-1

{
  "deviceId": "test-device-1",
  "userId": "test-user-123",
  "fcmToken": "fake-token-for-testing-12345",
  "platform": "ios",
  "isActive": true,
  "timezoneOffsetMinutes": -300,  // EST (UTC-5)
  "lastUsedAt": [current timestamp],
  "createdAt": [current timestamp]
}
```

Add a few more with different timezones:
- Device 2: `timezoneOffsetMinutes: -240` (AST, UTC-4)
- Device 3: `timezoneOffsetMinutes: -420` (MST, UTC-7)
- Device 4: `timezoneOffsetMinutes: 0` (UTC)

2) **Manually trigger the Cloud Function:**

```bash
# In a new terminal (keep emulators running)
cd functions
npm run shell

# In the Firebase shell:
> scheduleDailyNotifications({})
```

3) **Verify execution in logs:**

Check the emulator terminal for output:
```
  functions[us-central1-scheduleDailyNotifications]: pubsub function initialized.
i  functions: Beginning execution of "scheduleDailyNotifications"
>  === Daily Notification Scheduler Started ===
>  Execution time: 2024-11-03T14:00:00.000Z
>  Target offsets for 7:00 AM: UTC-7:00, UTC-6:30, UTC-6:00
>  Found 1 devices in UTC-7:00
>  FCM send failed for device test-device-3: messaging/invalid-registration-token
>  (This is expected with fake tokens in emulator)
>  === Daily Notification Scheduler Complete ===
>  Total devices queried: 1
>  Messages sent successfully: 0
>  Messages failed: 1
>  Invalid tokens removed: 1
i  functions: Finished "scheduleDailyNotifications" in ~1500ms
```

**Expected behavior:**
-  Function executes without crashing
-  Calculates correct timezone offsets
-  Queries devices collection
-  Attempts to send FCM (fails with fake tokens, that's OK)
-  Updates device documents (removes invalid token)

**Troubleshooting:**
- **"Collection not found":** Verify devices collection exists in emulator
- **"Function not found":** Run `npm run build` in functions directory
- **Timeout:** Check function logs for errors, increase timeout if needed

**Commit message:** "test: Verify Cloud Function executes correctly in local emulator"

---

## Phase 2: Flutter App Integration - Background Handler

### Step 2.1: Update devices collection with new fields
> Note: Use `timeZoneId` (IANA) and `hasFcmToken` instead of `timezoneOffsetMinutes` and avoid `lastSuccessfulFcmDate` for v1.

**Goal:** Add timezone detection and tracking fields to device registration

**Files to modify:**
- `lib/features/notifications/models/device_token.dart` (MODIFY - add fields)
- `lib/features/notifications/services/device_token_service.dart` (MODIFY - detect & save timezone)

**Implementation:**

```dart
// lib/features/notifications/models/device_token.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class DeviceToken {
  const DeviceToken({
    required this.deviceId,
    required this.platform,
    required this.lastUsedAt,
    required this.createdAt,
    this.userId,
    this.fcmToken,
    this.isActive = true, // NEW
    this.timezoneOffsetMinutes, // NEW
    this.lastSuccessfulFcmDate, // NEW
    this.lastFcmFailureDate, // NEW
  });

  final String deviceId;
  final String? userId;
  final String? fcmToken;
  final String platform;
  final DateTime lastUsedAt;
  final DateTime createdAt;

  // NEW FIELDS for FCM scheduling
  final bool isActive;
  final int? timezoneOffsetMinutes;
  final DateTime? lastSuccessfulFcmDate;
  final DateTime? lastFcmFailureDate;

  // ... existing methods ...

  /// Converts to Firestore document format.
  Map<String, dynamic> toFirestore({required bool isUpdate}) {
    final data = <String, dynamic>{
      'deviceId': deviceId,
      'platform': platform,
      'isActive': isActive, // NEW
    };

    if (!isUpdate) {
      data['createdAt'] = Timestamp.fromDate(createdAt);
    }

    if (userId != null) {
      data['userId'] = userId;
    } else {
      data['userId'] = null;
    }

    if (fcmToken != null) {
      data['fcmToken'] = fcmToken;
    } else {
      data['fcmToken'] = null;
    }

    // NEW: Always include timezone if available
    if (timezoneOffsetMinutes != null) {
      data['timezoneOffsetMinutes'] = timezoneOffsetMinutes;
    }

    // Always update lastUsedAt
    data['lastUsedAt'] = FieldValue.serverTimestamp();

    return data;
  }

  /// Creates from Firestore document.
  factory DeviceToken.fromFirestore(Map<String, dynamic> data) {
    return DeviceToken(
      deviceId: data['deviceId'] as String,
      userId: data['userId'] as String?,
      fcmToken: data['fcmToken'] as String?,
      platform: data['platform'] as String,
      isActive: data['isActive'] as bool? ?? true, // NEW
      timezoneOffsetMinutes: data['timezoneOffsetMinutes'] as int?, // NEW
      lastUsedAt: (data['lastUsedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSuccessfulFcmDate: (data['lastSuccessfulFcmDate'] as Timestamp?)?.toDate(), // NEW
      lastFcmFailureDate: (data['lastFcmFailureDate'] as Timestamp?)?.toDate(), // NEW
    );
  }

  // ... rest of existing code ...
}
```

```dart
// lib/features/notifications/services/device_token_service.dart
// Add timezone detection method

/// Detects the device's current timezone offset in minutes.
///
/// Returns offset from UTC in minutes (e.g., -300 for EST/UTC-5).
/// Positive values are east of UTC, negative values are west.
///
/// Example offsets:
/// - EST (UTC-5): -300
/// - PST (UTC-8): -480
/// - GMT (UTC+0): 0
/// - IST (UTC+5:30): 330
int _detectTimezoneOffsetMinutes() {
  final now = DateTime.now();
  final offset = now.timeZoneOffset;

  final offsetMinutes = offset.inMinutes;

  _devLog('Detected timezone offset: ${offset.inHours}h ${offset.inMinutes % 60}min '
         '($offsetMinutes minutes from UTC)');

  return offsetMinutes;
}

// Update registerDevice() method to include timezone

Future<void> registerDevice(String userId) async {
  try {
    _currentUserId = userId;

    final deviceId = await getOrCreateDeviceId();

    String? fcmToken;
    try {
      fcmToken = await _messaging.getToken();
    } on Exception catch (e) {
      _devLog('Warning: Failed to get FCM token: $e');
    }

    // Check throttling (existing code)...

    // Detect timezone offset
    final timezoneOffsetMinutes = _detectTimezoneOffsetMinutes();

    final platform = Platform.isIOS ? 'ios' : 'android';

    final deviceToken = DeviceToken(
      deviceId: deviceId,
      platform: platform,
      lastUsedAt: DateTime.now(),
      createdAt: DateTime.now(),
      userId: userId,
      fcmToken: fcmToken,
      isActive: true, // NEW - default to active
      timezoneOffsetMinutes: timezoneOffsetMinutes, // NEW
    );

    _devLog('Registering device in Firestore...');
    _devLog('  Device ID: ${deviceId.substring(0, 8)}...');
    _devLog('  User ID: ${userId.substring(0, 8)}...');
    _devLog('  Platform: $platform');
    _devLog('  Timezone offset: $timezoneOffsetMinutes minutes');
    final tokenDisplay = fcmToken != null ? '${fcmToken.substring(0, 20)}...' : 'null';
    _devLog('  FCM Token: $tokenDisplay');

    final isUpdate = lastToken != null && lastToken.isNotEmpty;
    await _firestore
        .collection('devices')
        .doc(deviceId)
        .set(
          deviceToken.toFirestore(isUpdate: isUpdate),
          SetOptions(merge: true),
        );

    await prefs.setString(lastTokenKey, fcmToken ?? '');
    await prefs.setString(
      lastRegistrationKey,
      DateTime.now().toIso8601String(),
    );

    _devLog('Device registered successfully');
  } on Exception catch (e, stackTrace) {
    // ... existing error handling ...
  }
}
```

**Testing:**
```bash
# Run app, sign in
flutter run --flavor development -t lib/main_development.dart

# Check logs for:
# "Detected timezone offset: -5h 0min (-300 minutes from UTC)"
# "Timezone offset: -300 minutes"

# Verify in Firestore emulator:
# devices/{deviceId} should have:
#   - isActive: true
#   - timezoneOffsetMinutes: -300 (or your local offset)
```

**Commit message:** "feat: Add timezone detection and FCM tracking fields to device registration"

---

### Step 2.2: Create Firestore composite index

**Goal:** Enable efficient queries for device targeting (isActive + hasFcmToken [+ userId])
Use this instead of `fcmToken != null` or raw timezone offset checks.

**Files to modify:**
- `firestore.indexes.json` (MODIFY - add composite index)

**Implementation:**

```json
// firestore.indexes.json

{
  "indexes": [
    {
      "collectionGroup": "devices",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "hasFcmToken", "order": "ASCENDING" },
        { "fieldPath": "userId", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

**Deployment:**

```bash
# Deploy index to Firebase (both dev and prod projects)

# Development project
firebase use hydracattest
firebase deploy --only firestore:indexes

# Production project (when ready)
firebase use myckdapp
firebase deploy --only firestore:indexes
```

**Index creation takes 5-10 minutes. Check status:**
```bash
firebase firestore:indexes
```

**Expected output:**
```
+-------------+------------------+---------------------------+-------+
| Index Name  | Collection Group | Fields                    | State |
+-------------+------------------+---------------------------+-------+
| devices_idx | devices          | isActive ASC              | READY |
|             |                  | hasFcmToken ASC           |       |
|             |                  | userId ASC                |       |
+-------------+------------------+---------------------------+-------+
```

**Note:** Index is created automatically in emulator, but must be explicitly deployed to production.

**Commit message:** "feat: Add Firestore composite index for FCM device queries"

---

### Step 2.3: Implement FCM background message handler

**Goal:** Handle FCM silent push when app is in background/terminated, trigger scheduling

**Files to create/modify:**
- `lib/shared/services/fcm_background_handler.dart` (NEW - top-level function)
- `lib/shared/services/firebase_service.dart` (MODIFY - register handler)
- `lib/main.dart` (MODIFY - register handler before runApp)

**Implementation:**

```dart
// lib/shared/services/fcm_background_handler.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/notifications/services/reminder_plugin.dart';
import 'package:hydracat/features/notifications/services/reminder_service.dart';
import 'package:hydracat/firebase_options.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// CRITICAL: Must be top-level function (not inside class).
/// This is called when app is in background or terminated.
///
/// iOS: App has ~30 seconds to complete execution.
/// Android: More lenient, but still time-limited.
///
/// IMPORTANT: This function runs in an isolate separate from the main app.
/// It cannot access existing providers or state. Must initialize everything.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase (required for background execution)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize timezone (required for scheduling)
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.local);

  // Initialize ReminderPlugin (required for scheduling)
  final reminderPlugin = ReminderPlugin();
  await reminderPlugin.initialize();

  _devLog('');
  _devLog('===================================================');
  _devLog('=== FCM BACKGROUND HANDLER - Message received ===');
  _devLog('===================================================');
  _devLog('Timestamp: ${DateTime.now().toIso8601String()}');
  _devLog('Message data: ${message.data}');
  _devLog('');

  final messageType = message.data['type'];

  if (messageType == 'schedule_today') {
    _devLog('Type: schedule_today (daily scheduling trigger)');

    try {
      // Get current user and pet from cached data
      final userId = await _getCachedUserId();
      final petId = await _getCachedPrimaryPetId();

      if (userId == null || petId == null) {
        _devLog('L No cached user/pet found, skipping scheduling');
        _devLog('User must open app to trigger initial scheduling');
        _devLog('PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP');
        return;
      }

      _devLog(' Cached user/pet found:');
      _devLog('  User ID: ${userId.substring(0, 8)}...');
      _devLog('  Pet ID: ${petId.substring(0, 8)}...');

      // Create ProviderContainer for background execution
      // This is isolated from main app's container
      final container = ProviderContainer();

      try {
        // Load cached profile data (offline-first, no Firestore reads)
        _devLog('Loading cached profile data...');
        await container.read(profileProvider.notifier).loadFromCache();
        _devLog(' Profile cache loaded');

        // Schedule today's notifications
        _devLog('Calling scheduleAllForToday()...');
        final reminderService = ReminderService();

        // Set 25-second timeout (iOS gives ~30 seconds max)
        final result = await Future.any([
          reminderService.scheduleAllForToday(userId, petId, container),
          Future.delayed(const Duration(seconds: 25), () {
            throw TimeoutException('Scheduling timed out after 25 seconds');
          }),
        ]);

        _devLog(' Scheduling complete:');
        _devLog('  Scheduled: ${result["scheduled"]}');
        _devLog('  Immediate: ${result["immediate"]}');
        _devLog('  Missed: ${result["missed"]}');
        _devLog('  Errors: ${result["errors"]?.length ?? 0}');

        // Track analytics
        await FirebaseCrashlytics.instance.log(
          'FCM background scheduling: ${result["scheduled"]} notifications, '
          'trigger source: fcm_background',
        );

        _devLog('PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP');
      } finally {
        // Always dispose container to free resources
        container.dispose();
      }
    } catch (e, stackTrace) {
      _devLog('ERROR during background scheduling: $e');
      _devLog('Stack trace: $stackTrace');

      // Report to Crashlytics (non-fatal)
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'FCM background scheduling failed',
        fatal: false,
      );

      _devLog('===================================================');
    }
  } else {
    _devLog('Unknown message type: $messageType, ignoring');
    _devLog('===================================================');
  }
}

/// Helper: Get cached user ID from SharedPreferences.
/// Returns null if not found (user must sign in first).
Future<String?> _getCachedUserId() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cached_user_id');
  } catch (e) {
    _devLog('Error reading cached user ID: $e');
    return null;
  }
}

/// Helper: Get cached primary pet ID from SharedPreferences.
/// Returns null if not found (user must complete onboarding first).
Future<String?> _getCachedPrimaryPetId() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cached_primary_pet_id');
  } catch (e) {
    _devLog('Error reading cached pet ID: $e');
    return null;
  }
}

/// Log messages (visible in device logs and Firebase Console).
void _devLog(String message) {
  if (kDebugMode) {
    debugPrint('[FCM Background] $message');
  }
}

/// Timeout exception for background execution limits.
class TimeoutException implements Exception {
  TimeoutException(this.message);
  final String message;

  @override
  String toString() => 'TimeoutException: $message';
}
```

```dart
// lib/main.dart - Register handler BEFORE runApp()

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hydracat/shared/services/fcm_background_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // CRITICAL: Register background message handler BEFORE runApp()
  // This must be done at the top level of main()
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize timezone
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.local);

  // ... rest of main() ...

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

**Testing:**

```bash
# Terminal 1: Start emulators
firebase emulators:start

# Terminal 2: Run app
flutter run --flavor development -t lib/main_development.dart

# Terminal 3: Trigger function manually
cd functions
npm run shell
> scheduleDailyNotifications({})

# Expected: App logs show background handler executing
# Check device logs for:
# "[FCM Background] =-> FCM BACKGROUND HANDLER - Message received"
# "[FCM Background]  Scheduling complete: Scheduled: X"
```

**Important iOS note:** Background execution won't work in iOS Simulator. Test on physical device.

**Commit message:** "feat: Implement FCM background message handler for daily scheduling"

---

### Step 2.4: Cache user/pet IDs for background access

**Goal:** Store user and pet IDs in SharedPreferences so background handler can access them

**Files to modify:**
- `lib/providers/auth_provider.dart` (MODIFY - cache user ID on sign-in)
- `lib/providers/profile_provider.dart` (MODIFY - cache pet ID when set)

**Implementation:**

```dart
// lib/providers/auth_provider.dart

// Add caching methods

/// Caches user ID in SharedPreferences for background FCM handler access.
Future<void> _cacheUserId(String userId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user_id', userId);
    _devLog('Cached user ID for background access');
  } catch (e) {
    _devLog('Failed to cache user ID: $e');
    // Non-critical, don't throw
  }
}

/// Clears cached user ID from SharedPreferences on sign-out.
Future<void> _clearCachedUserId() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user_id');
    await prefs.remove('cached_primary_pet_id'); // Also clear pet ID
    _devLog('Cleared cached user/pet IDs');
  } catch (e) {
    _devLog('Failed to clear cached IDs: $e');
  }
}

// Update sign-in methods to cache user ID

Future<UserCredential?> signInWithEmailPassword(
  String email,
  String password,
) async {
  // ... existing sign-in logic ...

  if (credential.user != null) {
    await _cacheUserId(credential.user!.uid); // NEW
  }

  return credential;
}

Future<UserCredential?> signInWithGoogle() async {
  // ... existing sign-in logic ...

  if (credential.user != null) {
    await _cacheUserId(credential.user!.uid); // NEW
  }

  return credential;
}

Future<UserCredential?> signInWithApple() async {
  // ... existing sign-in logic ...

  if (credential.user != null) {
    await _cacheUserId(credential.user!.uid); // NEW
  }

  return credential;
}

// Update sign-out to clear cache

Future<void> signOut() async {
  _devLog('Signing out user...');

  try {
    await _clearCachedUserId(); // NEW - clear before sign-out

    // ... existing sign-out logic ...
  } catch (e, stackTrace) {
    // ... existing error handling ...
  }
}
```

```dart
// lib/providers/profile_provider.dart

/// Caches primary pet ID in SharedPreferences for background FCM handler access.
Future<void> _cachePrimaryPetId(String petId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_primary_pet_id', petId);
    _devLog('Cached primary pet ID for background access');
  } catch (e) {
    _devLog('Failed to cache pet ID: $e');
    // Non-critical, don't throw
  }
}

// Update setPrimaryPet to cache pet ID

Future<void> setPrimaryPet(CatProfile pet) async {
  _devLog('Setting primary pet: ${pet.name}');

  try {
    await _cachePrimaryPetId(pet.id); // NEW - cache immediately

    // ... existing setPrimaryPet logic ...
  } catch (e, stackTrace) {
    // ... existing error handling ...
  }
}
```

**Testing:**

```bash
# Run app, sign in, complete onboarding
flutter run --flavor development -t lib/main_development.dart

# Verify SharedPreferences contains cached IDs:
# Android: adb shell run-as com.hydracat.hydracat cat /data/data/com.hydracat.hydracat/shared_prefs/FlutterSharedPreferences.xml
# iOS: Xcode > Window > Devices and Simulators > [Device] > Show Container > AppData > Library > Preferences

# Should see:
# cached_user_id: "abc123..."
# cached_primary_pet_id: "xyz789..."
```

**Commit message:** "feat: Cache user and pet IDs for FCM background handler access"

---

## Phase 3: Production Deployment & Testing

### Step 3.1: Deploy to development Firebase project (hydracattest)

**Goal:** Deploy Cloud Function to development project for real-world testing

**Prerequisites:**
-  All previous steps completed
-  Firestore composite index created (Step 2.2)
-  At least one test device registered with timezone offset

**Implementation:**

1) **Switch to development Firebase project:**
```bash
firebase use hydracattest
firebase projects:list  # Verify you're on correct project
```

2) **Build and deploy Cloud Function:**
```bash
cd functions
npm run build  # Compile TypeScript

# Deploy only the function (not Firestore rules/indexes)
firebase deploy --only functions:scheduleDailyNotifications
```

**Expected output:**
```
=== Deploying to 'hydracattest'...

i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
i  functions: ensuring required API cloudbuild.googleapis.com is enabled...
  functions: required API cloudfunctions.googleapis.com is enabled
  functions: required API cloudbuild.googleapis.com is enabled
i  functions: preparing codebase default for deployment
i  functions: packaged /Users/you/hydracat/functions (XX MB) for uploading
  functions: functions folder uploaded successfully
i  functions: creating Node.js 18 function scheduleDailyNotifications(us-central1)...
  functions[scheduleDailyNotifications(us-central1)] Successful create operation.
Function URL (scheduleDailyNotifications(us-central1)): https://us-central1-hydracattest.cloudfunctions.net/scheduleDailyNotifications

  Deploy complete!
```

3) **Verify deployment in Firebase Console:**
- Open https://console.firebase.google.com/project/hydracattest/functions
- Should see `scheduleDailyNotifications` function listed
- Status: Active
- Trigger: Cloud Pub/Sub (scheduled)
- Schedule: `0 * * * *` (every hour)

4) **Verify function is scheduled:**
```bash
firebase functions:log --only scheduleDailyNotifications --limit 5
```

**Troubleshooting:**
- **Permission denied:** Run `firebase login` and ensure you have Owner/Editor role
- **Build failed:** Check `functions/package.json` for dependency issues
- **Deployment timeout:** Increase timeout with `--timeout 540s` flag

**Commit message:** "deploy: Deploy scheduleDailyNotifications function to hydracattest project"

---

### Step 3.2: Test end-to-end with development app

**Goal:** Verify full flow from Cloud Function -> FCM -> App background handler -> Scheduling

**Testing procedure:**

**Test 1: Manual function trigger (immediate)**

```bash
# Trigger function manually to test immediately
firebase functions:shell

# In the shell:
> scheduleDailyNotifications({})

# Check logs:
> .exit
firebase functions:log --only scheduleDailyNotifications --limit 20
```

**Expected logs:**
```
=== Daily Notification Scheduler Started ===
Execution time: 2024-11-03T14:30:00.000Z
Target offsets for 7:00 AM: UTC-7:30, UTC-7:00, UTC-6:30
Found 1 devices in UTC-7:00
Messages sent successfully: 1
Messages failed: 0
Invalid tokens removed: 0
Execution duration: 1234ms
=== Daily Notification Scheduler Complete ===
```

**Test 2: Wait for scheduled execution**

```bash
# Functions run every hour at :00 minutes
# Wait until next hour boundary (e.g., 15:00, 16:00, 17:00)

# At :05 past the hour, check logs:
firebase functions:log --only scheduleDailyNotifications --limit 20

# Should see automatic execution logs
```

**Test 3: Verify app receives FCM and schedules notifications**

```bash
# Run app on physical device (not simulator for iOS)
flutter run --flavor development -t lib/main_development.dart --release

# Force close app (swipe away)

# Wait for next hourly function execution

# Check device logs (after function runs):
# iOS: Xcode > Window > Devices and Simulators > [Device] > Open Console
# Android: adb logcat | grep "FCM Background"

# Expected logs on device:
# [FCM Background] =-> FCM BACKGROUND HANDLER - Message received
# [FCM Background] Type: schedule_today (daily scheduling trigger)
# [FCM Background]  Cached user/pet found
# [FCM Background] Calling scheduleAllForToday()...
# [FCM Background]  Scheduling complete: Scheduled: X
```

**Test 4: Verify local notifications scheduled**

```bash
# Open app (brings to foreground)

# In debug console or Xcode logs, look for:
# [Notifications Dev] Found X pending notifications

# Or use debug panel if you have one:
# Navigate to Profile > Debug Panel > "Show Pending Notifications"
```

**Test 5: Multi-day absence simulation**

```bash
# Day 1: Open app, sign in, complete onboarding (8 AM)
# Force close app

# Day 1, 7 AM next day: Cloud Function runs
# Expected: App woken in background, notifications scheduled for Day 2

# Day 2: Don't open app at all
# Expected: Still receive notifications throughout Day 2

# Day 2, 7 AM next day: Cloud Function runs again
# Expected: Day 3 notifications scheduled

# Day 3: Don't open app
# Expected: Still receive notifications throughout Day 3

# Result: Successfully solved 48+ hour absence problem! 
```

**Success criteria:**
-  Cloud Function executes every hour without errors
-  FCM messages sent to devices in target timezones
-  App wakes in background and schedules notifications
-  Notifications appear at correct times
-  Works for 3+ days without opening app

**Commit message:** "test: Verify end-to-end FCM daily scheduling flow in development"

---

### Step 3.3: Monitor for 3-7 days in development

**Goal:** Ensure stability and catch edge cases before production deployment

**Monitoring checklist:**

**Daily checks (first 3 days):**
1. Check Cloud Function execution logs:
   ```bash
   firebase functions:log --only scheduleDailyNotifications --limit 50
   ```
   -  No errors or crashes
   -  Execution time <2 seconds
   -  Success rate >95%

2. Check Firebase Console metrics:
   - Navigate to: Firebase Console -> Functions -> scheduleDailyNotifications
   - Metrics to monitor:
     - Invocations: Should be ~24/day (once per hour)
     - Errors: Should be 0 or very low
     - Execution time: Should be <2000ms average
     - Memory usage: Should be <128MB

3. Check Firestore usage:
   - Navigate to: Firebase Console -> Firestore -> Usage
   - Metrics to monitor:
     - Reads: Should be <5000/day (depends on user count)
     - Writes: Should be <1000/day (mostly device updates)
     - Cost: Should be $0.00

4. Check FCM delivery:
   - Test with your own device
   - Force close app, wait for next hour
   - Verify notification scheduling works

**Weekly checks (after first 3 days):**
1. Review Crashlytics for any background handler errors
2. Check device collection for inactive devices (isActive: false)
3. Verify timezone offset distribution (are users global as expected?)

**Red flags to watch for:**
-  Function execution time >5 seconds (investigate query performance)
-  Error rate >5% (investigate FCM token issues)
-  Many devices marked inactive (investigate APNs setup on iOS)
-  Firestore reads >10K/day with <100 users (investigate query efficiency)

**If all checks pass for 7 days -> Proceed to production deployment**

**Commit message:** "chore: Complete 7-day monitoring period in development environment"

---

### Step 3.4: Deploy to production Firebase project (myckdapp)

**Goal:** Deploy Cloud Function to production for all users

**Prerequisites:**
-  7-day monitoring in development passed
-  No critical issues found
-  Composite index deployed to production (Step 2.2)

**Implementation:**

1) **Switch to production Firebase project:**
```bash
firebase use myckdapp
firebase projects:list  # Verify you're on production
```

2) **Deploy Firestore composite index (if not done already):**
```bash
firebase deploy --only firestore:indexes

# Wait 5-10 minutes for index to build
firebase firestore:indexes  # Check status
```

3) **Deploy Cloud Function:**
```bash
cd functions
npm run build
firebase deploy --only functions:scheduleDailyNotifications
```

4) **Verify deployment:**
```bash
# Check function exists
firebase functions:list | grep scheduleDailyNotifications

# Check first execution logs (wait until next hour)
firebase functions:log --only scheduleDailyNotifications --limit 20
```

5) **Monitor production for first 24 hours:**
- Check Firebase Console every 2-3 hours
- Watch for errors or unexpected behavior
- Monitor Firestore usage and costs

**Rollback procedure (if issues found):**
```bash
# Delete function from production
firebase functions:delete scheduleDailyNotifications

# Confirm deletion
# Users will fall back to app resume scheduling (existing behavior)
```

**Success criteria:**
-  Function deploys without errors
-  First 24 hours show no critical issues
-  Firestore costs remain $0
-  Users report improved notification reliability

**Commit message:** "deploy: Deploy scheduleDailyNotifications to production (myckdapp)"

---

## Phase 4: Analytics & Monitoring (Optional but Recommended)

### Step 4.1: Add comprehensive analytics tracking

**Goal:** Track FCM delivery success rates and scheduling trigger sources

**Files to modify:**
- `lib/providers/analytics_provider.dart` (MODIFY - add new events)
- `lib/features/notifications/services/reminder_service.dart` (MODIFY - track trigger source)

**Implementation:**

```dart
// lib/providers/analytics_provider.dart

// Add new analytics methods

/// Tracks when notifications are scheduled via different trigger sources.
Future<void> trackNotificationsScheduled({
  required String triggerSource, // 'fcm_background', 'app_resume', 'manual'
  required int notificationCount,
  required int durationMs,
}) async {
  await _analytics.logEvent(
    name: 'notifications_scheduled',
    parameters: {
      'trigger_source': triggerSource,
      'notification_count': notificationCount,
      'duration_ms': durationMs,
    },
  );
}

/// Tracks when FCM background scheduling fails.
Future<void> trackFcmBackgroundSchedulingFailed({
  required String errorReason,
}) async {
  await _analytics.logEvent(
    name: 'fcm_background_scheduling_failed',
    parameters: {
      'error_reason': errorReason,
    },
  );
}

/// Tracks when FCM daily trigger is received.
Future<void> trackFcmDailyTriggerReceived() async {
  await _analytics.logEvent(
    name: 'fcm_daily_trigger_received',
  );
}
```

```dart
// lib/features/notifications/services/reminder_service.dart

// Update scheduleAllForToday to track trigger source

Future<Map<String, dynamic>> scheduleAllForToday(
  String userId,
  String petId,
  WidgetRef ref,
) async {
  final startTime = DateTime.now();
  _devLog('scheduleAllForToday called for userId=$userId, petId=$petId');

  // Detect trigger source
  final triggerSource = _detectTriggerSource();

  try {
    // ... existing scheduling logic ...

    final duration = DateTime.now().difference(startTime);

    // Track analytics
    try {
      await ref.read(analyticsServiceDirectProvider).trackNotificationsScheduled(
        triggerSource: triggerSource,
        notificationCount: scheduledCount,
        durationMs: duration.inMilliseconds,
      );
    } catch (e) {
      _devLog('Analytics tracking failed: $e');
      // Don't fail scheduling if analytics fails
    }

    return result;
  } catch (e, stackTrace) {
    // ... existing error handling ...
  }
}

/// Detects what triggered the scheduling call.
String _detectTriggerSource() {
  // Check if app is in background (indicates FCM trigger)
  final lifecycleState = WidgetsBinding.instance.lifecycleState;

  if (lifecycleState == AppLifecycleState.detached ||
      lifecycleState == AppLifecycleState.paused) {
    return 'fcm_background';
  }

  if (lifecycleState == AppLifecycleState.resumed) {
    return 'app_resume';
  }

  return 'manual';
}
```

**Testing:**
```bash
# Run app, trigger scheduling in different ways
flutter run --flavor development -t lib/main_development.dart

# Check Firebase Analytics DebugView:
# https://console.firebase.google.com/project/hydracattest/analytics/debugview

# Should see events:
# - notifications_scheduled (trigger_source: fcm_background)
# - notifications_scheduled (trigger_source: app_resume)
# - fcm_daily_trigger_received
```

**Commit message:** "feat: Add comprehensive analytics for FCM scheduling monitoring"

---

## Phase 5: Documentation & Cleanup

### Step 5.1: Update notification plan with FCM implementation summary

**Goal:** Document completed FCM enhancement in reminder_plan.md

**Files to modify:**
- `~PLANNING/DONE/reminder_plan.md` (MODIFY - add Phase X for FCM)

**Add new section:**

```markdown
## Phase X: FCM Daily Scheduling Enhancement   COMPLETED

### Step X.1: Cloud Functions infrastructure setup   COMPLETED
**Status**: Fully complete

** Completed**:
1)  TypeScript Cloud Functions project initialized
2)  Timezone calculation utilities created
3)  Hourly Cloud Function implemented (single function, all timezones)
4)  Firebase Local Emulator Suite configured
5)  Functions tested locally before deployment

**Implementation Summary**:
- Single hourly Cloud Function handles all global timezones
- Runs at :00 of each hour UTC
- Calculates target timezone offsets dynamically
- Sends FCM silent push to devices in target timezones
- Cost: $0/month (within free tier for up to 1M users)

### Step X.2: Flutter app integration   COMPLETED
**Status**: Fully complete

** Completed**:
1)  Added timezone detection to device registration
2)  Added isActive, timezoneOffsetMinutes tracking fields
3)  Created Firestore composite index for efficient queries
4)  Implemented FCM background message handler
5)  Cached user/pet IDs for background access
6)  Added 25-second timeout for iOS background limits

**Implementation Summary**:
- Background handler wakes app when FCM received
- Loads cached profile data (no Firestore reads)
- Calls scheduleAllForToday() in background
- Defensive programming with timeout safety
- Multiple fallback layers (FCM -> app resume -> manual)

### Step X.3: Production deployment   COMPLETED
**Status**: Deployed to both projects

** Completed**:
1)  Deployed to hydracattest (development project)
2)  Monitored for 7 days with no critical issues
3)  Deployed to myckdapp (production project)
4)  Monitoring shows 99%+ delivery success rate

**Production Metrics** (first 30 days):
- Cloud Function invocations: 720/month (as expected)
- FCM delivery rate: 99.2%
- Average execution time: 1.2 seconds
- Firestore cost: $0.00
- Cloud Function cost: $0.00
- Total cost: $0.00

**Result**: Successfully solved multi-day absence problem! 
Users now receive notifications even if they don't open app for days.
```

**Commit message:** "docs: Document FCM enhancement implementation in reminder_plan.md"

---

### Step 5.2: Create operations runbook

**Goal:** Document procedures for monitoring and troubleshooting production

**Files to create:**
- `~PLANNING/fcm_operations_runbook.md` (NEW)

**Content:**

```markdown
# FCM Daily Scheduling - Operations Runbook

## Overview
This document provides procedures for monitoring and troubleshooting the FCM daily scheduling system in production.

## Normal Operations

### Daily Health Check
1. Check Cloud Function execution (Firebase Console -> Functions -> scheduleDailyNotifications)
   - Expected invocations: ~24/day (once per hour)
   - Expected errors: 0-1% error rate acceptable
   - Expected execution time: <2000ms average

2. Check Firestore usage (Firebase Console -> Firestore -> Usage)
   - Expected reads: <50K/day (depends on user count)
   - Expected writes: <10K/day
   - Expected cost: $0.00

3. Check FCM delivery (Firebase Console -> Cloud Messaging)
   - Expected delivery rate: >95%

### Weekly Review
1. Review Crashlytics for background handler errors
2. Check device collection for trends:
   - How many devices marked inactive?
   - Timezone distribution (global vs regional)
3. Review analytics for trigger source distribution:
   - fcm_background: Should be primary source
   - app_resume: Backup source
   - manual: Minimal

## Troubleshooting

### Issue: Cloud Function not executing
**Symptoms:** No logs in Firebase Console, no FCM messages sent

**Resolution:**
1. Check function status: `firebase functions:list`
2. Check Cloud Scheduler status (Cloud Console -> Cloud Scheduler)
3. Redeploy if needed: `firebase deploy --only functions:scheduleDailyNotifications`

### Issue: High error rate (>5%)
**Symptoms:** Many "FCM send failed" errors in logs

**Resolution:**
1. Check error codes in logs
2. If "invalid-registration-token": Normal cleanup, function handles automatically
3. If "quota-exceeded": Contact Firebase support (very unlikely)
4. If "service-unavailable": Temporary FCM outage, will self-resolve

### Issue: Users not receiving notifications
**Symptoms:** User reports missing reminders

**Diagnosis:**
1. Check if user's device in Firestore devices collection
2. Check device.isActive and device.fcmToken values
3. Check device.lastSuccessfulFcmDate (should update daily)
4. Check user's timezone matches Cloud Function targeting

**Resolution:**
- If fcmToken null: User needs to reinstall app or grant notification permission
- If isActive false: Device marked inactive due to repeated failures, will reactivate on next app open
- If timezone wrong: Will self-correct on next app open (timezone re-detected)

### Issue: High Firestore costs
**Symptoms:** Unexpected Firestore charges

**Diagnosis:**
1. Check Firestore usage dashboard for read/write breakdown
2. Check if composite index is active (firebase firestore:indexes)

**Resolution:**
- If index missing: Redeploy index (Step 2.2)
- If excessive reads: Check Cloud Function query logic
- If excessive writes: Check device update frequency

### Issue: iOS background handler not executing
**Symptoms:** Android works, iOS doesn't

**Diagnosis:**
1. Check if APNs token is null in device document
2. Check iOS APNs setup (reminder_plan.md Step 0.2)
3. Check device logs for background handler execution

**Resolution:**
- If APNs null: Complete Apple Developer setup (reminder_plan.md APPENDIX)
- If Low Power Mode: User must disable or open app manually
- If background refresh disabled: User must enable in Settings

## Rollback Procedures

### Rollback Cloud Function
If critical issues found in production:
```bash
firebase use myckdapp
firebase functions:delete scheduleDailyNotifications
```

**Impact:** Users fall back to app resume scheduling (original behavior)

### Re-enable After Rollback
1. Fix issue in development (hydracattest)
2. Test for 3-7 days
3. Redeploy to production

## Scaling Considerations

### At 10K users
- No changes needed
- Still within free tier

### At 100K users
- No changes needed
- Still within free tier

### At 1M users
- Consider upgrading Cloud Function memory if execution time increases
- Monitor Firestore query performance
- Still $0-5/month cost

## Contact Information
- Firebase Support: https://firebase.google.com/support
- Cloud Functions Documentation: https://firebase.google.com/docs/functions
```

**Commit message:** "docs: Create operations runbook for FCM daily scheduling"

---

## Testing Checklist

Use this checklist to verify each phase before moving to the next:

### Phase 0: Cloud Functions Setup
- [ ] Step 0.1: TypeScript compiles without errors (`npm run build`)
- [ ] Step 0.2: Timezone utilities return correct offsets
- [ ] Step 0.3: Cloud Function code compiles and exports successfully

### Phase 1: Emulator Setup
- [ ] Step 1.1: Emulators start successfully
- [ ] Step 1.2: Flutter app connects to emulators
- [ ] Step 1.3: Cloud Function executes in emulator without errors

### Phase 2: Flutter Integration
- [ ] Step 2.1: Device registration includes timezone offset
- [ ] Step 2.2: Firestore composite index created and READY
- [ ] Step 2.3: Background handler executes when FCM received
- [ ] Step 2.4: User/pet IDs cached in SharedPreferences

### Phase 3: Production Deployment
- [ ] Step 3.1: Cloud Function deploys to hydracattest
- [ ] Step 3.2: End-to-end flow works (Function -> FCM -> App -> Scheduling)
- [ ] Step 3.3: 7-day monitoring shows no critical issues
- [ ] Step 3.4: Cloud Function deploys to myckdapp

### Phase 4: Analytics (Optional)
- [ ] Step 4.1: Analytics events tracked in Firebase DebugView

### Phase 5: Documentation
- [ ] Step 5.1: Reminder plan updated with FCM implementation
- [ ] Step 5.2: Operations runbook created

---

## Cost Summary

**Monthly costs at different scales:**

| User Count | FCM Messages | Cloud Function Invocations | Firestore Reads | Total Cost |
|------------|--------------|---------------------------|-----------------|------------|
| 1K users   | 30K          | 720                       | 3K              | **$0.00**  |
| 10K users  | 300K         | 720                       | 30K             | **$0.00**  |
| 100K users | 3M           | 720                       | 300K            | **$0.00**  |
| 1M users   | 30M          | 720                       | 3M              | **$2-5**   |

**Free tier limits:**
- FCM: Unlimited (completely free)
- Cloud Functions: 2M invocations/month, 400K GB-seconds/month
- Firestore: 50K reads/day (1.5M/month)

**Conclusion:** Cost is $0 for foreseeable future (well within free tier for 100K+ users)

---

## Success Metrics

Track these metrics to measure FCM enhancement success:

**Primary Metrics:**
-  Multi-day absence problem solved (users receive notifications without opening app)
-  Notification delivery rate >95%
-  Background scheduling success rate >90%
-  Cost remains $0/month

**Secondary Metrics:**
- Trigger source distribution (fcm_background should dominate)
- Average execution time <2 seconds
- Error rate <5%
- User reports of improved reliability

---

## Next Steps After Completion

**Future Enhancements (Optional):**
1. **Weekly Summary Push Notifications** (estimated 2-3 days)
   - Add second Cloud Function for Monday 9 AM summaries
   - Rich notification content with adherence stats
   - Cost: Still $0

2. **Multi-Device Sync** (estimated 3-5 days)
   - Silent push to cancel notifications on Device B when logged on Device A
   - Requires device query by userId
   - Cost: $1-2/month at scale

3. **Re-engagement Campaigns** (estimated 5-7 days)
   - Identify users who haven't opened app in 7+ days
   - Send supportive check-in push
   - Requires Cloud Firestore triggers
   - Cost: $2-5/month at scale

**Recommendation:** Monitor current FCM implementation for 30 days before adding enhancements.

---

## Appendix: Common Issues & Solutions

### iOS: Background handler not executing

**Cause:** iOS Low Power Mode or Background App Refresh disabled

**Solution:**
- User must disable Low Power Mode
- User must enable Background App Refresh: Settings -> General -> Background App Refresh -> Hydracat (ON)
- Alternative: User opens app manually (existing fallback)

### Android: Notifications delayed despite FCM

**Cause:** Aggressive battery optimization on Xiaomi, Huawei, OnePlus devices

**Solution:**
- Add battery optimization prompt in notification settings (future enhancement)
- Guide users to disable battery optimization for Hydracat
- Alternative: Users open app daily (existing behavior)

### Cloud Function: Execution time >5 seconds

**Cause:** Too many devices in single timezone

**Solution:**
- Increase function memory (256MB -> 512MB)
- Add batching optimization for very large user bases
- Cost impact: Minimal ($0 -> $2-5/month)

### Firestore: Index not building

**Cause:** Firestore indexes can take 10-30 minutes to build

**Solution:**
- Wait 30 minutes, check status: `firebase firestore:indexes`
- If still building after 1 hour, contact Firebase support
- Alternative: Test in emulator while waiting (indexes instant in emulator)

---

**End of Implementation Plan**

This plan provides step-by-step guidance for implementing FCM daily scheduling enhancement. Each step is designed for a single work session with frequent commits.

**Estimated total implementation time:** 3-5 days
**Estimated testing period:** 7 days in development
**Estimated total project duration:** 2 weeks

**Questions?** Refer to Firebase documentation or create a GitHub issue.
