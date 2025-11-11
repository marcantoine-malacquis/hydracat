import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/l10n/app_localizations.dart';

/// Tests for notification action button accessibility labels.
///
/// Verifies that action button labels use full, descriptive text suitable
/// for screen readers (VoiceOver on iOS, TalkBack on Android).
///
/// Requirements:
/// - Labels must be clear and unambiguous without visual context
/// - Labels must use full words (no abbreviations like "min")
/// - Labels must meet minimum length for screen reader clarity
///
/// See: reminder_plan.md, Step 11.2: Notification actions accessibility
void main() {
  group('Notification Action Accessibility', () {
    test('Action labels use full descriptive text', () {
      final l10n = lookupAppLocalizations(const Locale('en'));

      // Verify "Log treatment now" (not "Log now")
      expect(l10n.notificationActionLogNow, contains('treatment'));
      expect(l10n.notificationActionLogNow, contains('now'));
    });

    test('Action labels meet minimum length for screen readers', () {
      final l10n = lookupAppLocalizations(const Locale('en'));

      // Minimum 15 characters for clear screen reader announcement
      expect(
        l10n.notificationActionLogNow.length,
        greaterThanOrEqualTo(15),
        reason: 'Min 15 chars for screen reader clarity',
      );
    });

    test('Action labels are not empty', () {
      final l10n = lookupAppLocalizations(const Locale('en'));

      expect(l10n.notificationActionLogNow, isNotEmpty);
    });

    test('Action labels use natural language patterns', () {
      final l10n = lookupAppLocalizations(const Locale('en'));

      // "Log treatment now" - verb + object + adverb pattern
      final logNow = l10n.notificationActionLogNow.toLowerCase();
      expect(
        logNow.contains('log') || logNow.contains('record'),
        isTrue,
        reason: 'Log action should contain action verb',
      );
    });

    test('Action labels do not contain technical jargon', () {
      final l10n = lookupAppLocalizations(const Locale('en'));

      // Ensure no abbreviations that might confuse screen readers
      final logNow = l10n.notificationActionLogNow.toLowerCase();

      expect(
        logNow,
        isNot(matches(RegExp(r'\b(min|sec|hr|hrs)\b'))),
        reason: 'Log action should not contain time abbreviations',
      );
    });
  });
}
