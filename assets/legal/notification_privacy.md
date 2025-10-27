# Notification Privacy & Data Handling

Last updated: January 2025

## Overview

Hydracat uses notifications to help you stay on track with your pet's treatment schedule. We've designed our notification system with your privacy as our top priority.

## What We Collect

When you enable notifications, we store the following information **locally on your device only**:

- **Notification schedule data**: The times when reminders should appear
- **Treatment type**: Whether it's a medication or fluid therapy reminder (but not the specific medication names or dosages)
- **Pet identifier**: A reference to which pet the reminder is for
- **Notification status**: Whether a notification is scheduled, completed, or snoozed

**We do NOT collect or store**:
- Medication names or dosages
- Fluid therapy volumes
- Treatment details
- Any personally identifiable medical information

## Privacy-First Notification Content

All notifications use **generic, privacy-focused content**:

- **No medical details**: Notifications never show medication names, dosages, or fluid volumes
- **Generic titles**: "Medication reminder" or "Fluid therapy reminder"
- **Pet name only**: Notifications may include your pet's name (e.g., "Time for Fluffy's medication") but nothing else
- **Lock screen safe**: Safe to display on lock screens and notification centers without revealing sensitive information

## Where Your Data is Stored

**Local device only**: All notification data is stored exclusively in your device's local storage using SharedPreferences. This data:

- Never leaves your device
- Is never transmitted to our servers
- Is never shared with third parties
- Is never backed up to cloud services
- Remains completely private to you

## Data Retention

We automatically minimize the data we keep:

- **Daily cleanup**: Only today's notification schedule is retained
- **Automatic deletion**: Yesterday's notification data is automatically deleted each day at midnight
- **No long-term storage**: We don't keep historical notification data beyond the current day

## Your Control

You have complete control over your notification data:

### Settings You Can Manage
- **Enable/Disable notifications**: Master toggle to turn all notifications on or off
- **Weekly summaries**: Enable or disable weekly progress notifications
- **Snooze functionality**: Choose whether you can snooze reminders for 15 minutes
- **Permission control**: Manage system notification permissions via device settings

### Data Management
- **Clear notification data**: Cancel all scheduled notifications and clear stored data at any time via Settings → Notifications → Clear Notification Data
- **Logout behavior**: When you log out, all scheduled notifications are canceled and notification data is cleared (your preference settings are preserved for convenience)

## Platform Permissions

### iOS
- We request notification permission through Apple's standard permission dialog
- Permission can be changed at any time in iOS Settings → Notifications → Hydracat

### Android
- We request notification permission (required for Android 13+)
- Permission can be changed at any time in Android Settings → Apps → Hydracat → Notifications

## No Push Notifications

Hydracat uses **local notifications only**:

- Notifications are generated directly on your device
- No data is sent to external notification services (Firebase Cloud Messaging, Apple Push Notification Service, etc.)
- No notification servers can access your data
- Works completely offline

## Data Security

Even though your notification data never leaves your device, we still apply security best practices:

- **Data integrity checks**: We use checksums to detect if local data has been corrupted
- **Automatic reconciliation**: If data integrity issues are detected, we automatically clean up and rebuild from your treatment schedules
- **Error handling**: All operations fail gracefully without exposing sensitive information

## Compliance

Our notification system is designed to protect your privacy:

- **Minimal data collection**: We only collect what's necessary for core functionality
- **Purpose limitation**: Data is used exclusively for reminder notifications
- **User control**: You can delete all notification data at any time
- **Transparency**: This policy clearly explains what we do (and don't do) with your data

## Changes to This Policy

We may update this privacy policy from time to time. When we make changes:

- The "Last updated" date at the top will be updated
- Significant changes will be communicated through the app
- Continued use of notifications after changes constitutes acceptance

## Questions or Concerns

If you have questions about how we handle notification data, please contact us through the app's support channel or at [your support email].

---

*Your pet's health information is sensitive, and we treat it that way. Every design decision in our notification system prioritizes your privacy and security.*
