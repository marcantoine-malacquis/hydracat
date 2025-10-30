import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/l10n/app_localizations.dart';

void main() {
  group('Notification group summaries (en)', () {
    late AppLocalizations l10n;

    setUp(() {
      l10n = lookupAppLocalizations(const Locale('en'));
    });

    test('title formats with pet name', () {
      expect(l10n.notificationGroupSummaryTitle('Remy'), "Remy's Reminders");
    });

    test('medication-only pluralization', () {
      expect(
        l10n.notificationGroupSummaryMedicationOnly(1),
        '1 medication reminder',
      );
      expect(
        l10n.notificationGroupSummaryMedicationOnly(2),
        '2 medication reminders',
      );
    });

    test('fluid-only pluralization', () {
      expect(
        l10n.notificationGroupSummaryFluidOnly(1),
        '1 fluid therapy reminder',
      );
      expect(
        l10n.notificationGroupSummaryFluidOnly(3),
        '3 fluid therapy reminders',
      );
    });

    test('both medication and fluid counts', () {
      // Signature is (fluidCount, medCount)
      expect(
        l10n.notificationGroupSummaryBoth(1, 1),
        '1 medication, 1 fluid therapy',
      );
      expect(
        l10n.notificationGroupSummaryBoth(2, 3),
        '3 medications, 2 fluid therapies',
      );
    });
  });
}
