import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/l10n/app_localizations.dart';

void main() {
  group('A11y notification localizations', () {
    test('medication a11y title/body interpolate petName', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final title = l10n.notificationMedicationTitleA11y('Remy');
      final body = l10n.notificationMedicationBodyA11y('Remy');
      expect(title, contains('Remy'));
      expect(title.toLowerCase(), contains('treatment reminder'));
      expect(body, contains('Remy'));
      expect(body.toLowerCase(), contains("it's time"));
    });

    test('fluid a11y title/body interpolate petName', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final title = l10n.notificationFluidTitleA11y('Remy');
      final body = l10n.notificationFluidBodyA11y('Remy');
      expect(title, contains('Remy'));
      expect(title.toLowerCase(), contains('fluid'));
      expect(body, contains('Remy'));
      expect(body.toLowerCase(), contains('fluid'));
    });

    test('followup a11y title/body interpolate petName', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final title = l10n.notificationFollowupTitleA11y('Remy');
      final body = l10n.notificationFollowupBodyA11y('Remy');
      expect(title, contains('Remy'));
      expect(body, contains('Remy'));
      expect(body.toLowerCase(), contains('treatment'));
    });
  });
}
