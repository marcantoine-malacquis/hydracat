# Notification System Explained

**Audience**: Future developers joining the project
**Purpose**: Understand how the notification system works without getting lost in technical details

---

## Layer 1: The Big Picture

### What problem does this solve?

Hydracat helps users manage chronic kidney disease (CKD) treatments for their pets. Pets need regular medications and fluid therapy at specific times each day. The notification system reminds users when it's time to give treatments, without revealing sensitive medical information on their lock screen.

### The user's journey

1. **User sets up a treatment schedule** (e.g., "Give medication at 8:00 AM and 6:00 PM daily")
2. **System schedules reminders** automatically when the app opens
3. **User gets notified** at the right times throughout the day
4. **User can snooze** reminders if they're busy (15 minutes)
5. **System sends follow-up** reminders if treatment wasn't logged (2 hours later)
6. **Weekly summary** shows how well they're doing with their pet's care

### Core principle: Privacy First

All notifications are intentionally **generic**. We NEVER show medication names, dosages, or medical details in notifications. Why? Because notifications appear on lock screens where others can see them. Instead, we show things like "Time for Luna's morning medication" - just enough to be helpful without compromising privacy.

---

## Layer 2: How the Pieces Fit Together

### The four main components

Think of the notification system like a restaurant kitchen:

1. **The Menu (NotificationSettings)**: What the user wants
   - Do they want notifications at all?
   - Do they want weekly summaries?
   - What time for end-of-day reminders?

2. **The Head Chef (ReminderService)**: Orchestrates everything
   - Reads the treatment schedules (the recipes)
   - Decides when to schedule notifications (timing the dishes)
   - Handles special cases (grace periods, follow-ups)

3. **The Kitchen Timer (ReminderPlugin)**: Actually triggers notifications
   - Interfaces with the phone's native notification system
   - Makes the phone buzz and show the notification

4. **The Recipe Book (NotificationIndexStore)**: Keeps track of what's scheduled
   - Records what notifications are active
   - Prevents duplicate reminders
   - Helps recover if the app crashes

### How data flows through the system

```
User's treatment schedules (stored in profile)
    ↓
ReminderService reads the schedules
    ↓
For each scheduled time, it asks: "Should I remind them?"
    ↓
If yes → Creates a notification via ReminderPlugin
    ↓
Records it in NotificationIndexStore
    ↓
Phone's system triggers the notification at the right time
```

---

## Layer 3: Key Design Decisions & Why They Matter

### 1. Offline-First Architecture

**Decision**: Never fetch data from the cloud (Firestore) when scheduling notifications. Only use data already cached in the app.

**Why**:
- Faster: No waiting for network requests
- Cheaper: Saves on Firebase costs
- More reliable: Works even with poor internet
- Simpler: Less code, fewer failure points

**How it works**: When users sign in or the app opens, their treatment schedules are already loaded into memory (profileProvider). The notification system just reads from that cache.

### 2. Idempotent Scheduling

**Decision**: It's always safe to schedule the same notification multiple times without creating duplicates.

**Why**: Apps can crash, users can force-close the app, or weird things happen. We need the system to be resilient.

**How it works**: Each notification gets a unique ID based on its content (user ID, pet ID, schedule ID, time, and type). If you try to schedule notification #12345 twice, the system just cancels the old one and creates it fresh. Same result every time.

### 3. Grace Period Logic

**Decision**: If someone opens the app 15 minutes late for an 8:00 AM reminder, we still show the notification immediately instead of skipping it.

**Why**: Life happens. People sleep through alarms or get busy. A late reminder is better than no reminder.

**The 30-minute rule**:
- **0-30 minutes late**: Fire the notification immediately when app opens
- **30+ minutes late**: Too late, skip it (considered "missed")

### 4. Follow-up Reminders

**Decision**: If a treatment time passes and the user hasn't logged it, send a gentle follow-up reminder 2 hours later.

**Why**: Sometimes people dismiss the first notification intending to do it in a few minutes, then forget. A second reminder helps without being annoying.

**Special handling**: If a follow-up would fire after 11:00 PM, we reschedule it for 8:00 AM the next day instead. We don't want to wake people up at midnight!

### 5. Privacy-First Content

**Decision**: Generic notification text only. No medical details, ever.

**Why**:
- **Lock screen visibility**: Neighbors, friends, visitors can see notifications
- **User choice**: Let users decide who knows about their pet's medical condition
- **Medical sensitivity**: Health data (even for pets) deserves respect
- **Compliance mindset**: Follows the same principles as GDPR/HIPAA

**What we show**:
-  Pet name ("Luna", "Max")
-  Time context ("morning", "evening")
-  Generic treatment type ("medication", "fluid therapy")
-  Encouraging language

**What we NEVER show**:
- L Medication names ("Benazepril", "Enalapril")
- L Dosages ("5mg", "10ml")
- L Medical details ("subcutaneous fluids", "injection site")

### 6. Deterministic IDs

**Decision**: Every notification ID is calculated using a special math formula (FNV-1a hash) based on the user, pet, schedule, time, and type.

**Why**:
- Same inputs always produce same ID
- Enables idempotent scheduling (see #2)
- Can cancel a notification later without storing a lookup table
- If the app crashes and restarts, it calculates the same IDs and can reconcile

**Real-world analogy**: Like a barcode generated from product information. Scan the same product twice, get the same barcode.

### 7. Data Integrity with Checksums

**Decision**: The notification index (list of scheduled notifications) includes a checksum to detect corruption.

**Why**:
- Phones can crash, battery can die, storage can corrupt
- Better to detect corrupted data early than silently fail later
- If checksum doesn't match, we know something's wrong and can rebuild

**How it works**: Like a receipt total. Add up all the scheduled notifications, generate a unique fingerprint. Later, regenerate the fingerprint and compare. If they match, data is intact.

### 8. User Permissions & Settings

**Decision**: Two separate gates: system permission AND user setting must both be enabled.

**Why**:
- **System permission**: Required by iOS/Android for any notifications
- **User setting**: Lets users disable notifications temporarily without losing permission
- Users might want notifications off during vacation but granted for later

**The logic**:
```
Can show notifications? = (System permission granted) AND (User enabled in settings)
```

---

## Layer 4: The User Experience Flow in Detail

### Scenario: Morning medication reminder at 8:00 AM

**7:55 AM - User is using the app**
- ReminderService checks: "Are there any schedules for today?"
- Finds: "8:00 AM - Medication for Luna"
- Creates notification entry and schedules it
- Records in NotificationIndexStore

**8:00 AM - Notification fires**
- Phone buzzes
- Shows: "Time for Luna's morning medication 💊"
- User sees: Option to snooze (if enabled in settings)

**User taps notification**
- App opens to the treatment logging screen
- User logs the treatment
- ReminderService cancels any follow-up reminders for this treatment

### Scenario: User opens app at 8:20 AM (20 minutes late)

**Grace period activated**
- System checks: "Scheduled for 8:00, now 8:20, difference = 20 minutes"
- 20 minutes < 30 minutes (grace period)
- Decision: Fire immediately
- User sees notification right away

### Scenario: User opens app at 9:00 AM (60 minutes late)

**Missed reminder**
- System checks: "Scheduled for 8:00, now 9:00, difference = 60 minutes"
- 60 minutes > 30 minutes (grace period)
- Decision: Missed, don't schedule
- User gets a follow-up reminder at 10:00 AM instead (2 hours after original time)

### Scenario: Weekly summary

**Every Monday at 9:00 AM**
- System sends: "Luna's weekly progress: Great job this week! ✨"
- Shows adherence stats (how many treatments logged vs missed)
- Encourages the user to keep up the good work

### Scenario: User disabled notifications in settings

**Any time**
- System checks: "Notifications enabled? No."
- Skips all scheduling
- No notifications fire
- Can re-enable later without losing permission

---

## Layer 5: Important Implementation Details

### When notifications get scheduled

Notifications are scheduled at these moments:
1. **App startup** (after user signs in)
2. **App resume** from background
3. **After onboarding** completion
4. **After profile changes** (new schedule added/edited)

This ensures notifications are always up-to-date with the user's current schedules.

### What happens each day

**Daily lifecycle**:
1. **Morning** (when app opens): Schedule all today's reminders
2. **Throughout day**: Notifications fire at scheduled times
3. **End of day** (optional): Summary notification showing missed treatments
4. **Midnight cleanup**: Old notifications from yesterday are cleared

### Storage strategy

**Local storage (phone)**:
- User notification settings (SharedPreferences)
- Notification index (what's scheduled today)
- Device ID (for future push notification support)

**NOT stored**:
- Treatment schedules (comes from Firestore via profile cache)
- Historical notification data (not needed)

**Why this design**: Keeps the notification system lightweight and fast. We only store the minimal data needed to function.

### Platform differences (iOS vs Android)

The system handles platform differences automatically:

**iOS**:
- Requests permission via Firebase Messaging
- Shows permission dialog with sound/badge options
- Uses provisional authorization when available

**Android**:
- Android 13+ requires explicit permission request
- Uses notification channels for different types
- Handles "permanently denied" state differently

Developers don't need to worry about these differences - the system abstracts them away.

### Error handling philosophy

**Fail gracefully, never crash**:
- If scheduling fails, log to Crashlytics but continue
- If index is corrupted, rebuild from scratch
- If permission denied, show helpful message to user
- Never let notification issues break the rest of the app

**Privacy in errors**:
Even error logs never contain medication names or dosages. Only operational IDs (user ID, pet ID, schedule ID) are logged for debugging.

---

## Layer 6: Common Questions

### Why not use push notifications (Firebase Cloud Messaging)?

**Current approach**: Local notifications (scheduled on the phone)
**Future possibility**: Push notifications for weekly summaries or motivational messages

**Reasons for local-first**:
- More reliable (works offline)
- Faster (no network delay)
- Cheaper (no Firebase function costs)
- Simpler (less infrastructure)

The system is designed to support push notifications later if needed. Device token service is already implemented for future use.

### What if the user has multiple pets? (Premium feature)

The architecture already supports this! Each notification includes:
- User ID
- Pet ID
- Schedule ID

When multi-pet support launches, the system just needs to loop through all pets instead of just the primary pet. Everything else works the same.

### Why not store notification history?

**Decision**: Don't track past notifications, only current day.

**Reasoning**:
- Adherence tracking happens in treatment logs (different feature)
- Historical notification data isn't useful for the user
- Keeps storage small and system fast
- Privacy: Less data = less privacy risk

### How does snooze work?

When user snoozes a notification:
1. Original notification is canceled
2. New notification scheduled for +15 minutes from now
3. Recorded as "snooze" type in index
4. After 15 minutes, notification fires again

Users can snooze multiple times if needed. Each snooze just reschedules for another 15 minutes.

### What happens if the app is killed/force-closed?

**Notifications still fire!** Once scheduled, they're handled by the phone's operating system, not the app. The app could be completely closed and notifications still appear.

When the app reopens, it reconciles (checks what should be scheduled vs what actually is scheduled) and fixes any discrepancies.

---

## Summary for Quick Reference

**Main concepts**:
- Privacy-first notification content (generic only, no medical details)
- Offline-first architecture (no cloud fetches)
- Idempotent scheduling (safe to retry)
- Grace period (30 minutes for late reminders)
- Follow-ups (2 hours after initial)
- Data integrity with checksums

**Main components**:
- `ReminderService`: Orchestrator (schedules everything)
- `ReminderPlugin`: Interface to phone's notification system
- `NotificationIndexStore`: Tracks what's scheduled
- `NotificationSettings`: User preferences
- Permission system: Manages iOS/Android permissions

**When to schedule**:
- App startup/resume
- After onboarding
- After profile changes

**Storage**:
- Settings → SharedPreferences (local)
- Index → SharedPreferences (local, per-day)
- Schedules → Come from profile cache (already loaded)

**Testing tip**: Most services use singletons but are exposed via Riverpod providers, making them easy to mock in tests.

---

**Last updated**: 2025-11-01
**Status**: Production-ready (9.5/10 according to code review)
