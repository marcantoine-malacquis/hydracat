Current Firestore ruleset integrated via the Firestore console

rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // ─────────────────────────────
    // DEFAULT: DENY EVERYTHING
    // ─────────────────────────────
    match /{document=**} {
      allow read, write: if false;
    }

    // ─────────────────────────────
    // DEVICES COLLECTION
    // ─────────────────────────────
    match /devices/{deviceId} {
      // Only the owning user can access their device doc
      allow read, write: if request.auth != null
                         && request.auth.uid == resource.data.userId;
    }

    // ─────────────────────────────
    // USERS COLLECTION
    // ─────────────────────────────
    match /users/{userId} {
      // Only the authenticated owner can access their user doc
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;

      // Helper function to check if user is premium
      function isPremium() {
        return resource.data.subscriptionStatus == 'active'
               && resource.data.subscriptionExpiresAt > request.time;
      }

      // Cascade rule for all subcollections
      match /{subCollection=**}/{docId} {
        allow read, write: if request.auth != null
                           && request.auth.uid == userId;
      }

      // ─────────────────────────────
      // CROSS-PET SUMMARIES (Premium only)
      // ─────────────────────────────
      match /crossPetSummaries/{summaryId} {
        allow read: if request.auth.uid == userId && isPremium();
        allow write: if false; // only server/cloud functions should write
      }

      // ─────────────────────────────
      // PETS SUBCOLLECTION
      // ─────────────────────────────
      match /pets/{petId} {
        allow read, write: if request.auth != null
                           && request.auth.uid == userId;

        // FLUID SESSIONS
        match /fluidSessions/{sessionId} {
          allow read, write: if request.auth.uid == userId;
        }

        // MEDICATION SESSIONS
        match /medicationSessions/{sessionId} {
          allow read, write: if request.auth.uid == userId;
        }

        // HEALTH PARAMETERS
        match /healthParameters/{dateId} {
          allow read, write: if request.auth.uid == userId;
        }

        // LAB RESULTS
        match /labResults/{labId} {
          allow read, write: if request.auth.uid == userId;
        }

        // DAILY TREATMENT SUMMARIES
        match /treatmentSummaryDaily/{dayId} {
          allow read: if request.auth.uid == userId;
          allow write: if false; // only written by server
        }

        // WEEKLY TREATMENT SUMMARIES
        match /treatmentSummaryWeekly/{weekId} {
          allow read: if request.auth.uid == userId;
          allow write: if false; // only written by server
        }

        // MONTHLY TREATMENT SUMMARIES
        match /treatmentSummaryMonthly/{monthId} {
          allow read: if request.auth.uid == userId;
          allow write: if false; // only written by server
        }

        // SCHEDULES
        match /schedules/{scheduleId} {
          allow read, write: if request.auth.uid == userId;
        }
      }
    }
  }
}
