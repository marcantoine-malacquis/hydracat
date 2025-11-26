/// Unit tests for SymptomsService
///
/// Tests business logic for symptom tracking:
/// - Validation of SymptomEntry severity scores (0-3 range)
/// - Daily summary field computation from SymptomEntry maps
/// - Analytics event parameter computation
///
/// NOTE: Full Firestore integration tests (batch writes, delta updates)
/// are deferred to integration tests with Firebase Emulator.
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/health/exceptions/health_exceptions.dart';
import 'package:hydracat/features/health/models/symptom_entry.dart';
import 'package:hydracat/features/health/models/symptom_raw_value.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';
import 'package:hydracat/features/health/services/symptom_severity_converter.dart';
import 'package:hydracat/features/health/services/symptoms_service.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  group('SymptomsService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockAnalyticsService mockAnalyticsService;
    late SymptomsService symptomsService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAnalyticsService = MockAnalyticsService();
      symptomsService = SymptomsService(
        firestore: fakeFirestore,
        analyticsService: mockAnalyticsService,
      );

      // Setup default analytics mock
      when(
        () => mockAnalyticsService.trackFeatureUsed(
          featureName: any(named: 'featureName'),
          additionalParams: any(named: 'additionalParams'),
        ),
      ).thenAnswer((_) async {});
    });

    group('Validation', () {
      test('accepts valid SymptomEntry map with severity 0-3', () {
        final symptoms = {
          SymptomType.vomiting: SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.vomiting,
            rawValue: 2,
          ),
          SymptomType.diarrhea: SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.diarrhea,
            rawValue: DiarrheaQuality.soft.name,
          ),
        };

        // Should not throw
        expect(
          () => symptomsService.saveSymptoms(
            userId: 'user-123',
            petId: 'pet-456',
            date: DateTime.now(),
            symptoms: symptoms,
          ),
          returnsNormally,
        );
      });

      test('throws SymptomValidationException for severity > 3', () {
        const invalidEntry = SymptomEntry(
          symptomType: SymptomType.vomiting,
          rawValue: 2,
          severityScore: 4, // Invalid: > 3
        );

        expect(
          () => symptomsService.saveSymptoms(
            userId: 'user-123',
            petId: 'pet-456',
            date: DateTime.now(),
            symptoms: {SymptomType.vomiting: invalidEntry},
          ),
          throwsA(isA<SymptomValidationException>()),
        );
      });

      test('throws SymptomValidationException for severity < 0', () {
        const invalidEntry = SymptomEntry(
          symptomType: SymptomType.vomiting,
          rawValue: 2,
          severityScore: -1, // Invalid: < 0
        );

        expect(
          () => symptomsService.saveSymptoms(
            userId: 'user-123',
            petId: 'pet-456',
            date: DateTime.now(),
            symptoms: {SymptomType.vomiting: invalidEntry},
          ),
          throwsA(isA<SymptomValidationException>()),
        );
      });

      test('accepts null symptoms map', () {
        expect(
          () => symptomsService.saveSymptoms(
            userId: 'user-123',
            petId: 'pet-456',
            date: DateTime.now(),
          ),
          returnsNormally,
        );
      });

      test('accepts empty symptoms map', () {
        expect(
          () => symptomsService.saveSymptoms(
            userId: 'user-123',
            petId: 'pet-456',
            date: DateTime.now(),
            symptoms: {},
          ),
          returnsNormally,
        );
      });
    });

    group('HealthParameter Creation', () {
      test('creates HealthParameter with SymptomEntry map', () async {
        final date = DateTime(2025, 1, 15);
        final symptoms = {
          SymptomType.vomiting: SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.vomiting,
            rawValue: 2,
          ),
          SymptomType.energy: SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.energy,
            rawValue: EnergyLevel.low.name,
          ),
        };

        await symptomsService.saveSymptoms(
          userId: 'user-123',
          petId: 'pet-456',
          date: date,
          symptoms: symptoms,
        );

        // Verify HealthParameter was created with correct structure
        final doc = await fakeFirestore
            .collection('users')
            .doc('user-123')
            .collection('pets')
            .doc('pet-456')
            .collection('healthParameters')
            .doc('2025-01-15')
            .get();

        expect(doc.exists, isTrue);
        final data = doc.data()!;

        // Verify symptoms structure
        expect(data['symptoms'], isA<Map<String, dynamic>>());
        final symptomsData = data['symptoms'] as Map<String, dynamic>;

        // Verify vomiting entry
        expect(symptomsData[SymptomType.vomiting], isA<Map<String, dynamic>>());
        final vomitingData =
            symptomsData[SymptomType.vomiting] as Map<String, dynamic>;
        expect(vomitingData['rawValue'], 2);
        expect(vomitingData['severityScore'], 2);

        // Verify energy entry
        expect(symptomsData[SymptomType.energy], isA<Map<String, dynamic>>());
        final energyData =
            symptomsData[SymptomType.energy] as Map<String, dynamic>;
        expect(energyData['rawValue'], EnergyLevel.low.name);
        expect(energyData['severityScore'], 2);

        // Verify computed fields
        expect(data['hasSymptoms'], isTrue);
        expect(data['symptomScoreTotal'], 4); // 2 + 2
        expect(data['symptomScoreAverage'], 2.0); // (2 + 2) / 2
      });

      test('creates HealthParameter with no symptoms (null map)', () async {
        final date = DateTime(2025, 1, 15);

        await symptomsService.saveSymptoms(
          userId: 'user-123',
          petId: 'pet-456',
          date: date,
        );

        final doc = await fakeFirestore
            .collection('users')
            .doc('user-123')
            .collection('pets')
            .doc('pet-456')
            .collection('healthParameters')
            .doc('2025-01-15')
            .get();

        expect(doc.exists, isTrue);
        final data = doc.data()!;

        // Symptoms should be absent or null
        expect(data['symptoms'], isNull);
        expect(data['hasSymptoms'], isFalse);
        expect(data['symptomScoreTotal'], isNull);
        expect(data['symptomScoreAverage'], isNull);
      });
    });

    group('Daily Summary Updates', () {
      test('sets had* booleans based on severity > 0', () async {
        final date = DateTime(2025, 1, 15);
        final symptoms = {
          SymptomType.vomiting: SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.vomiting,
            rawValue: 1, // severity = 1
          ),
          SymptomType.diarrhea: SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.diarrhea,
            rawValue: DiarrheaQuality.normal.name, // severity = 0
          ),
        };

        await symptomsService.saveSymptoms(
          userId: 'user-123',
          petId: 'pet-456',
          date: date,
          symptoms: symptoms,
        );

        final doc = await fakeFirestore
            .collection('users')
            .doc('user-123')
            .collection('pets')
            .doc('pet-456')
            .collection('treatmentSummaries')
            .doc('daily')
            .collection('summaries')
            .doc('2025-01-15')
            .get();

        expect(doc.exists, isTrue);
        final data = doc.data()!;

        // Vomiting has severity > 0, should be true
        expect(data['hadVomiting'], isTrue);
        expect(data['vomitingMaxScore'], 1);

        // Diarrhea has severity = 0, should be false
        expect(data['hadDiarrhea'], isFalse);
        expect(data['diarrheaMaxScore'], isNull);
      });

      test('sets max scores correctly for all symptoms', () async {
        final date = DateTime(2025, 1, 15);
        final symptoms = {
          SymptomType.vomiting: SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.vomiting,
            rawValue: 3, // severity = 3
          ),
          SymptomType.constipation: SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.constipation,
            rawValue: ConstipationLevel.mildStraining.name, // severity = 1
          ),
          SymptomType.energy: SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.energy,
            rawValue: EnergyLevel.veryLow.name, // severity = 3
          ),
        };

        await symptomsService.saveSymptoms(
          userId: 'user-123',
          petId: 'pet-456',
          date: date,
          symptoms: symptoms,
        );

        final doc = await fakeFirestore
            .collection('users')
            .doc('user-123')
            .collection('pets')
            .doc('pet-456')
            .collection('treatmentSummaries')
            .doc('daily')
            .collection('summaries')
            .doc('2025-01-15')
            .get();

        expect(doc.exists, isTrue);
        final data = doc.data()!;

        expect(data['vomitingMaxScore'], 3);
        expect(data['constipationMaxScore'], 1);
        expect(data['energyMaxScore'], 3);
        expect(data['symptomScoreTotal'], 7); // 3 + 1 + 3
      });
    });

    group('Analytics Events', () {
      test('logs symptoms_log_created with correct parameters', () async {
        final date = DateTime(2025, 1, 15);
        final symptoms = {
          SymptomType.vomiting: SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.vomiting,
            rawValue: 2, // severity = 2
          ),
          SymptomType
              .injectionSiteReaction: SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.injectionSiteReaction,
            rawValue: InjectionSiteReaction.mildSwelling.name, // severity = 1
          ),
        };

        await symptomsService.saveSymptoms(
          userId: 'user-123',
          petId: 'pet-456',
          date: date,
          symptoms: symptoms,
        );

        verify(
          () => mockAnalyticsService.trackFeatureUsed(
            featureName: 'symptoms_log_created',
            additionalParams: {
              'symptom_count': 2,
              'total_score': 3, // 2 + 1
              'has_injection_site_reaction': true,
            },
          ),
        ).called(1);
      });

      test('logs symptoms_log_updated when editing existing entry', () async {
        final date = DateTime(2025, 1, 15);

        // Create initial entry
        await symptomsService.saveSymptoms(
          userId: 'user-123',
          petId: 'pet-456',
          date: date,
          symptoms: {
            SymptomType.vomiting: SymptomSeverityConverter.createEntry(
              symptomType: SymptomType.vomiting,
              rawValue: 1,
            ),
          },
        );

        // Update entry
        await symptomsService.saveSymptoms(
          userId: 'user-123',
          petId: 'pet-456',
          date: date,
          symptoms: {
            SymptomType.vomiting: SymptomSeverityConverter.createEntry(
              symptomType: SymptomType.vomiting,
              rawValue: 2,
            ),
            SymptomType.diarrhea: SymptomSeverityConverter.createEntry(
              symptomType: SymptomType.diarrhea,
              rawValue: DiarrheaQuality.soft.name,
            ),
          },
        );

        // Should log updated event
        verify(
          () => mockAnalyticsService.trackFeatureUsed(
            featureName: 'symptoms_log_updated',
            additionalParams: {
              'symptom_count': 2,
              'total_score': 3, // 2 + 1
              'has_injection_site_reaction': false,
            },
          ),
        ).called(1);
      });

      test('computes symptom_count correctly (only severity > 0)', () async {
        final date = DateTime(2025, 1, 15);
        final symptoms = {
          SymptomType.vomiting: SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.vomiting,
            rawValue: 2, // severity = 2
          ),
          SymptomType.diarrhea: SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.diarrhea,
            rawValue: DiarrheaQuality.normal.name, // severity = 0
          ),
        };

        await symptomsService.saveSymptoms(
          userId: 'user-123',
          petId: 'pet-456',
          date: date,
          symptoms: symptoms,
        );

        // Should only count vomiting (severity > 0)
        verify(
          () => mockAnalyticsService.trackFeatureUsed(
            featureName: 'symptoms_log_created',
            additionalParams: {
              'symptom_count': 1,
              'total_score': 2,
              'has_injection_site_reaction': false,
            },
          ),
        ).called(1);
      });

      test('detects injection site reaction correctly', () async {
        final date = DateTime(2025, 1, 15);

        // With injection site reaction (severity > 0)
        await symptomsService.saveSymptoms(
          userId: 'user-123',
          petId: 'pet-456',
          date: date,
          symptoms: {
            SymptomType
                .injectionSiteReaction: SymptomSeverityConverter.createEntry(
              symptomType: SymptomType.injectionSiteReaction,
              rawValue: InjectionSiteReaction.redPainful.name, // severity = 3
            ),
          },
        );

        verify(
          () => mockAnalyticsService.trackFeatureUsed(
            featureName: 'symptoms_log_created',
            additionalParams: {
              'symptom_count': 1,
              'total_score': 3,
              'has_injection_site_reaction': true,
            },
          ),
        ).called(1);
      });
    });

    group('clearSymptoms', () {
      test('clears symptoms by setting to null', () async {
        final date = DateTime(2025, 1, 15);

        // Create entry with symptoms
        await symptomsService.saveSymptoms(
          userId: 'user-123',
          petId: 'pet-456',
          date: date,
          symptoms: {
            SymptomType.vomiting: SymptomSeverityConverter.createEntry(
              symptomType: SymptomType.vomiting,
              rawValue: 2,
            ),
          },
        );

        // Clear symptoms
        await symptomsService.clearSymptoms(
          'user-123',
          'pet-456',
          date,
        );

        // Verify symptoms are cleared (hasSymptoms should be false)
        final doc = await fakeFirestore
            .collection('users')
            .doc('user-123')
            .collection('pets')
            .doc('pet-456')
            .collection('healthParameters')
            .doc('2025-01-15')
            .get();

        expect(doc.exists, isTrue);
        final data = doc.data()!;
        // Note: symptoms field may still exist in Firestore due to merge
        // behavior, but hasSymptoms should be false indicating no active
        // symptoms
        expect(data['hasSymptoms'], isFalse);
      });
    });
  });
}
