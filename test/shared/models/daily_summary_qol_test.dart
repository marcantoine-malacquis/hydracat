import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/models/daily_summary.dart';

void main() {
  group('DailySummary QoL Integration', () {
    final testDate = DateTime(2025, 1, 15);

    group('constructor with QoL fields', () {
      test('should create summary with QoL scores', () {
        final summary = DailySummary(
          date: testDate,
          overallStreak: 0,
          medicationTotalDoses: 0,
          medicationScheduledDoses: 0,
          medicationMissedCount: 0,
          fluidTotalVolume: 0,
          fluidTreatmentDone: false,
          fluidSessionCount: 0,
          fluidScheduledSessions: 0,
          overallTreatmentDone: false,
          createdAt: DateTime.now(),
          qolOverallScore: 75,
          qolVitalityScore: 80,
          qolComfortScore: 70,
          qolEmotionalScore: 75,
          qolAppetiteScore: 72,
          qolTreatmentBurdenScore: 78,
          hasQolAssessment: true,
        );

        expect(summary.qolOverallScore, 75);
        expect(summary.qolVitalityScore, 80);
        expect(summary.qolComfortScore, 70);
        expect(summary.qolEmotionalScore, 75);
        expect(summary.qolAppetiteScore, 72);
        expect(summary.qolTreatmentBurdenScore, 78);
        expect(summary.hasQolAssessment, isTrue);
      });

      test(
        'should default QoL scores to null and hasQolAssessment to false',
        () {
        final summary = DailySummary(
          date: testDate,
          overallStreak: 0,
          medicationTotalDoses: 0,
          medicationScheduledDoses: 0,
          medicationMissedCount: 0,
          fluidTotalVolume: 0,
          fluidTreatmentDone: false,
          fluidSessionCount: 0,
          fluidScheduledSessions: 0,
          overallTreatmentDone: false,
          createdAt: DateTime.now(),
        );

        expect(summary.qolOverallScore, isNull);
        expect(summary.qolVitalityScore, isNull);
        expect(summary.qolComfortScore, isNull);
        expect(summary.qolEmotionalScore, isNull);
        expect(summary.qolAppetiteScore, isNull);
        expect(summary.qolTreatmentBurdenScore, isNull);
        expect(summary.hasQolAssessment, isFalse);
      });
    });

    group('empty factory', () {
      test('should create empty summary with null QoL scores', () {
        final summary = DailySummary.empty(testDate);

        expect(summary.qolOverallScore, isNull);
        expect(summary.qolVitalityScore, isNull);
        expect(summary.qolComfortScore, isNull);
        expect(summary.qolEmotionalScore, isNull);
        expect(summary.qolAppetiteScore, isNull);
        expect(summary.qolTreatmentBurdenScore, isNull);
        expect(summary.hasQolAssessment, isFalse);
      });
    });

    group('fromJson', () {
      test('should parse QoL fields when present', () {
        final json = {
          'date': testDate.toIso8601String(),
          'overallStreak': 0,
          'medicationTotalDoses': 0,
          'medicationScheduledDoses': 0,
          'medicationMissedCount': 0,
          'fluidTotalVolume': 0,
          'fluidTreatmentDone': false,
          'fluidSessionCount': 0,
          'fluidScheduledSessions': 0,
          'overallTreatmentDone': false,
          'createdAt': DateTime.now().toIso8601String(),
          'qolOverallScore': 75.5,
          'qolVitalityScore': 80,
          'qolComfortScore': 70,
          'qolEmotionalScore': 75,
          'qolAppetiteScore': 72,
          'qolTreatmentBurdenScore': 78,
          'hasQolAssessment': true,
        };

        final summary = DailySummary.fromJson(json);

        expect(summary.qolOverallScore, 75.5);
        expect(summary.qolVitalityScore, 80);
        expect(summary.qolComfortScore, 70);
        expect(summary.qolEmotionalScore, 75);
        expect(summary.qolAppetiteScore, 72);
        expect(summary.qolTreatmentBurdenScore, 78);
        expect(summary.hasQolAssessment, isTrue);
      });

      test('should handle missing QoL fields (backward compatible)', () {
        final json = {
          'date': testDate.toIso8601String(),
          'overallStreak': 0,
          'medicationTotalDoses': 0,
          'medicationScheduledDoses': 0,
          'medicationMissedCount': 0,
          'fluidTotalVolume': 0,
          'fluidTreatmentDone': false,
          'fluidSessionCount': 0,
          'fluidScheduledSessions': 0,
          'overallTreatmentDone': false,
          'createdAt': DateTime.now().toIso8601String(),
          // QoL fields intentionally omitted
        };

        final summary = DailySummary.fromJson(json);

        expect(summary.qolOverallScore, isNull);
        expect(summary.qolVitalityScore, isNull);
        expect(summary.qolComfortScore, isNull);
        expect(summary.qolEmotionalScore, isNull);
        expect(summary.qolAppetiteScore, isNull);
        expect(summary.qolTreatmentBurdenScore, isNull);
        expect(summary.hasQolAssessment, isFalse);
      });

      test('should handle integer QoL scores (convert to double)', () {
        final json = {
          'date': testDate.toIso8601String(),
          'overallStreak': 0,
          'medicationTotalDoses': 0,
          'medicationScheduledDoses': 0,
          'medicationMissedCount': 0,
          'fluidTotalVolume': 0,
          'fluidTreatmentDone': false,
          'fluidSessionCount': 0,
          'fluidScheduledSessions': 0,
          'overallTreatmentDone': false,
          'createdAt': DateTime.now().toIso8601String(),
          'qolOverallScore': 75, // integer
          'hasQolAssessment': 1, // truthy value
        };

        final summary = DailySummary.fromJson(json);

        expect(summary.qolOverallScore, 75);
        expect(summary.hasQolAssessment, isTrue);
      });
    });

    group('toJson', () {
      test('should serialize QoL fields when present', () {
        final summary = DailySummary(
          date: testDate,
          overallStreak: 0,
          medicationTotalDoses: 0,
          medicationScheduledDoses: 0,
          medicationMissedCount: 0,
          fluidTotalVolume: 0,
          fluidTreatmentDone: false,
          fluidSessionCount: 0,
          fluidScheduledSessions: 0,
          overallTreatmentDone: false,
          createdAt: DateTime.now(),
          qolOverallScore: 75,
          qolVitalityScore: 80,
          hasQolAssessment: true,
        );

        final json = summary.toJson();

        expect(json['qolOverallScore'], 75);
        expect(json['qolVitalityScore'], 80);
        expect(json['hasQolAssessment'], isTrue);
      });

      test('should omit null QoL scores (save bytes)', () {
        final summary = DailySummary(
          date: testDate,
          overallStreak: 0,
          medicationTotalDoses: 0,
          medicationScheduledDoses: 0,
          medicationMissedCount: 0,
          fluidTotalVolume: 0,
          fluidTreatmentDone: false,
          fluidSessionCount: 0,
          fluidScheduledSessions: 0,
          overallTreatmentDone: false,
          createdAt: DateTime.now(),
          // QoL scores are null
        );

        final json = summary.toJson();

        expect(json.containsKey('qolOverallScore'), isFalse);
        expect(json.containsKey('qolVitalityScore'), isFalse);
        expect(json.containsKey('qolComfortScore'), isFalse);
        expect(json.containsKey('qolEmotionalScore'), isFalse);
        expect(json.containsKey('qolAppetiteScore'), isFalse);
        expect(json.containsKey('qolTreatmentBurdenScore'), isFalse);
        expect(json['hasQolAssessment'], isFalse);
      });
    });

    group('copyWith', () {
      test('should update QoL fields', () {
        final original = DailySummary.empty(testDate);

        final updated = original.copyWith(
          qolOverallScore: 80,
          qolVitalityScore: 85,
          hasQolAssessment: true,
        );

        expect(updated.qolOverallScore, 80);
        expect(updated.qolVitalityScore, 85);
        expect(updated.hasQolAssessment, isTrue);

        // Other scores remain null
        expect(updated.qolComfortScore, isNull);
        expect(updated.qolEmotionalScore, isNull);
      });

      test('should handle null QoL scores with sentinel pattern', () {
        final original = DailySummary(
          date: testDate,
          overallStreak: 0,
          medicationTotalDoses: 0,
          medicationScheduledDoses: 0,
          medicationMissedCount: 0,
          fluidTotalVolume: 0,
          fluidTreatmentDone: false,
          fluidSessionCount: 0,
          fluidScheduledSessions: 0,
          overallTreatmentDone: false,
          createdAt: DateTime.now(),
          qolOverallScore: 75,
          hasQolAssessment: true,
        );

        // Explicitly set to null using sentinel pattern
        final updated = original.copyWith(
          qolOverallScore: null,
        );

        expect(updated.qolOverallScore, isNull);
        expect(updated.hasQolAssessment, isTrue); // Unchanged
      });

      test('should preserve QoL fields when not specified', () {
        final original = DailySummary(
          date: testDate,
          overallStreak: 0,
          medicationTotalDoses: 0,
          medicationScheduledDoses: 0,
          medicationMissedCount: 0,
          fluidTotalVolume: 0,
          fluidTreatmentDone: false,
          fluidSessionCount: 0,
          fluidScheduledSessions: 0,
          overallTreatmentDone: false,
          createdAt: DateTime.now(),
          qolOverallScore: 75,
          qolVitalityScore: 80,
          hasQolAssessment: true,
        );

        final updated = original.copyWith(
          overallStreak: 5,
          // QoL fields not specified
        );

        expect(updated.qolOverallScore, 75);
        expect(updated.qolVitalityScore, 80);
        expect(updated.hasQolAssessment, isTrue);
        expect(updated.overallStreak, 5);
      });
    });

    group('equality', () {
      test('should be equal when QoL fields match', () {
        final summary1 = DailySummary(
          date: testDate,
          overallStreak: 0,
          medicationTotalDoses: 0,
          medicationScheduledDoses: 0,
          medicationMissedCount: 0,
          fluidTotalVolume: 0,
          fluidTreatmentDone: false,
          fluidSessionCount: 0,
          fluidScheduledSessions: 0,
          overallTreatmentDone: false,
          createdAt: testDate,
          qolOverallScore: 75,
          hasQolAssessment: true,
        );

        final summary2 = DailySummary(
          date: testDate,
          overallStreak: 0,
          medicationTotalDoses: 0,
          medicationScheduledDoses: 0,
          medicationMissedCount: 0,
          fluidTotalVolume: 0,
          fluidTreatmentDone: false,
          fluidSessionCount: 0,
          fluidScheduledSessions: 0,
          overallTreatmentDone: false,
          createdAt: testDate,
          qolOverallScore: 75,
          hasQolAssessment: true,
        );

        expect(summary1, equals(summary2));
        expect(summary1.hashCode, equals(summary2.hashCode));
      });

      test('should not be equal when QoL scores differ', () {
        final summary1 = DailySummary.empty(testDate).copyWith(
          qolOverallScore: 75,
        );

        final summary2 = DailySummary.empty(testDate).copyWith(
          qolOverallScore: 80,
        );

        expect(summary1, isNot(equals(summary2)));
      });

      test('should not be equal when hasQolAssessment differs', () {
        final summary1 = DailySummary.empty(testDate).copyWith(
          hasQolAssessment: true,
        );

        final summary2 = DailySummary.empty(testDate).copyWith(
          hasQolAssessment: false,
        );

        expect(summary1, isNot(equals(summary2)));
      });
    });

    group('toString', () {
      test('should include QoL fields in string representation', () {
        final summary = DailySummary.empty(testDate).copyWith(
          qolOverallScore: 75,
          qolVitalityScore: 80,
          hasQolAssessment: true,
        );

        final str = summary.toString();

        expect(str, contains('qolOverallScore: 75.0'));
        expect(str, contains('qolVitalityScore: 80.0'));
        expect(str, contains('hasQolAssessment: true'));
      });
    });

    group('serialization round-trip', () {
      test('should preserve all QoL fields through toJson -> fromJson', () {
        final original = DailySummary(
          date: testDate,
          overallStreak: 0,
          medicationTotalDoses: 0,
          medicationScheduledDoses: 0,
          medicationMissedCount: 0,
          fluidTotalVolume: 0,
          fluidTreatmentDone: false,
          fluidSessionCount: 0,
          fluidScheduledSessions: 0,
          overallTreatmentDone: false,
          createdAt: testDate,
          qolOverallScore: 75.5,
          qolVitalityScore: 80,
          qolComfortScore: 70,
          qolEmotionalScore: 75,
          qolAppetiteScore: 72,
          qolTreatmentBurdenScore: 78,
          hasQolAssessment: true,
        );

        final json = original.toJson();
        final deserialized = DailySummary.fromJson(json);

        expect(deserialized.qolOverallScore, original.qolOverallScore);
        expect(deserialized.qolVitalityScore, original.qolVitalityScore);
        expect(deserialized.qolComfortScore, original.qolComfortScore);
        expect(deserialized.qolEmotionalScore, original.qolEmotionalScore);
        expect(deserialized.qolAppetiteScore, original.qolAppetiteScore);
        expect(
          deserialized.qolTreatmentBurdenScore,
          original.qolTreatmentBurdenScore,
        );
        expect(deserialized.hasQolAssessment, original.hasQolAssessment);
      });
    });
  });
}
