import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/services/medication_database_service.dart';

/// Mock AssetBundle for testing
class MockAssetBundle extends Fake implements AssetBundle {
  MockAssetBundle(this._jsonData);

  final String _jsonData;
  bool _shouldThrowError = false;

  void enableThrowError() {
    _shouldThrowError = true;
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (_shouldThrowError) {
      throw Exception('Failed to load asset');
    }
    return _jsonData;
  }
}

void main() {
  group('MedicationDatabaseService', () {
    late MedicationDatabaseService service;
    late MockAssetBundle mockAssetBundle;

    final validJsonData = json.encode([
      {
'name': 'Benazepril',
        'form': 'tablet',
        'strength': '5',
        'unit': 'mg',
        'route': 'oral',
        'category': 'ACE_inhibitor',
        'brand_names': 'Fortekor',
      },
      {
'name': 'Aluminum hydroxide',
        'form': 'powder',
        'strength': 'variable',
        'unit': 'mg',
        'route': 'oral',
        'category': 'phosphate_binder',
        'brand_names': 'Various generics',
      },
      {
'name': 'Cerenia',
        'form': 'tablet',
        'strength': '16',
        'unit': 'mg',
        'route': 'oral',
        'category': 'antiemetic',
        'brand_names': 'Cerenia',
      },
    ]);

    setUp(() {
      mockAssetBundle = MockAssetBundle(validJsonData);
      service = MedicationDatabaseService(assetBundle: mockAssetBundle);
    });

    group('Initialization', () {
      test('starts uninitialized', () {
        expect(service.isInitialized, isFalse);
        expect(service.medicationCount, 0);
      });

      test('initializes successfully with valid JSON', () async {
        await service.initialize();

        expect(service.isInitialized, isTrue);
        expect(service.medicationCount, 3);
      });

      test('only initializes once on multiple calls', () async {
        await service.initialize();
        final firstCount = service.medicationCount;

        await service.initialize();
        expect(service.medicationCount, firstCount);
      });

      test('filters out invalid entries during initialization', () async {
        final invalidJsonData = json.encode([
          {
        'name': 'Valid Med',
            'form': 'tablet',
            'strength': '5',
            'unit': 'mg',
            'route': 'oral',
            'category': 'other',
            'brand_names': 'Brand',
          },
          {
'name': '',
            'form': 'unknown',
            'strength': 'abc',
            'unit': '',
            'route': 'oral',
            'category': 'other',
            'brand_names': '',
          },
        ]);

        final bundle = MockAssetBundle(invalidJsonData);
        final testService = MedicationDatabaseService(assetBundle: bundle);

        await testService.initialize();

        expect(testService.isInitialized, isTrue);
        expect(testService.medicationCount, 1); // Only valid entry
      });

      test('gracefully handles load failure', () async {
        mockAssetBundle.enableThrowError();

        await service.initialize();

        expect(service.isInitialized, isTrue);
        expect(service.medicationCount, 0);
      });

      test('gracefully handles JSON parse failure', () async {
        final invalidBundle = MockAssetBundle('invalid json {');
        final testService =
            MedicationDatabaseService(assetBundle: invalidBundle);

        await testService.initialize();

        expect(testService.isInitialized, isTrue);
        expect(testService.medicationCount, 0);
      });
    });

    group('searchMedications', () {
      setUp(() async {
        await service.initialize();
      });

      test('returns empty list for empty query', () {
        final results = service.searchMedications('');
        expect(results, isEmpty);
      });

      test('returns empty list for whitespace-only query', () {
        final results = service.searchMedications('   ');
        expect(results, isEmpty);
      });

      test('returns empty list when not initialized', () {
        final uninitializedService = MedicationDatabaseService(
          assetBundle: mockAssetBundle,
        );
        final results = uninitializedService.searchMedications('bena');
        expect(results, isEmpty);
      });

      test('performs case-insensitive contains matching on name', () {
        final results = service.searchMedications('bena');
        expect(results, hasLength(1));
        expect(results.first.medication.name, 'Benazepril');
      });

      test('performs case-insensitive contains matching on brand names', () {
        final results = service.searchMedications('fortekor');
        expect(results, hasLength(1));
        expect(results.first.medication.name, 'Benazepril');
      });

      test('matches medications by partial name', () {
        final results = service.searchMedications('nia');
        expect(results, hasLength(1));
        expect(results.first.medication.name, 'Cerenia');
      });

      test('returns multiple matches', () {
        final results = service.searchMedications('e');
        expect(results.length, greaterThan(1));
      });

      test('returns no results for non-matching query', () {
        final results = service.searchMedications('nonexistent');
        expect(results, isEmpty);
      });

      test(
        'sorts results by relevance - name starts with query first',
        () async {
        final largeJsonData = json.encode([
          {
        'name': 'Benazepril',
            'form': 'tablet',
            'strength': '5',
            'unit': 'mg',
            'route': 'oral',
            'category': 'ACE_inhibitor',
            'brand_names': 'Fortekor',
          },
          {
        'name': 'Another Bena Med',
            'form': 'tablet',
            'strength': '10',
            'unit': 'mg',
            'route': 'oral',
            'category': 'other',
            'brand_names': 'Brand',
          },
          {
        'name': 'Contains Bena',
            'form': 'tablet',
            'strength': '5',
            'unit': 'mg',
            'route': 'oral',
            'category': 'other',
            'brand_names': 'Brand',
          },
        ]);

        final bundle = MockAssetBundle(largeJsonData);
        final testService = MedicationDatabaseService(assetBundle: bundle);
        await testService.initialize();

          final results = testService.searchMedications('bena');
          expect(results.first.medication.name, 'Benazepril'); // Starts with query
        },
      );

      test('limits results to 10 entries', () async {
        final manyMeds = List.generate(
          20,
          (i) => {
        'name': 'Medication$i',
            'form': 'tablet',
            'strength': '5',
            'unit': 'mg',
            'route': 'oral',
            'category': 'other',
            'brand_names': 'Brand',
          },
        );

        final bundle = MockAssetBundle(json.encode(manyMeds));
        final testService = MedicationDatabaseService(assetBundle: bundle);
        await testService.initialize();

        final results = testService.searchMedications('medication');
        expect(results.length, lessThanOrEqualTo(10));
      });

      test('handles special characters in query', () {
        final results = service.searchMedications('ben@zepril');
        expect(results, isEmpty);
      });

      test('trims whitespace from query', () {
        final results = service.searchMedications('  benazepril  ');
        expect(results, hasLength(1));
        expect(results.first.medication.name, 'Benazepril');
      });

      test('performs alphabetical sort for equal relevance', () async {
        final alphabeticalData = json.encode([
          {
        'name': 'Zeta Med',
            'form': 'tablet',
            'strength': '5',
            'unit': 'mg',
            'route': 'oral',
            'category': 'other',
            'brand_names': 'test',
          },
          {
        'name': 'Alpha Med',
            'form': 'tablet',
            'strength': '5',
            'unit': 'mg',
            'route': 'oral',
            'category': 'other',
            'brand_names': 'test',
          },
        ]);

        final bundle = MockAssetBundle(alphabeticalData);
        final testService = MedicationDatabaseService(assetBundle: bundle);
        await testService.initialize();

        final results = testService.searchMedications('med');
        expect(results.first.medication.name, 'Alpha Med');
        expect(results.last.medication.name, 'Zeta Med');
      });
    });

    group('getMedicationByName', () {
      setUp(() async {
        await service.initialize();
      });

      test('returns medication with exact name match', () {
        final result = service.getMedicationByName('Benazepril');
        expect(result, isNotNull);
        expect(result!.name, 'Benazepril');
      });

      test('is case insensitive', () {
        final result = service.getMedicationByName('benazepril');
        expect(result, isNotNull);
        expect(result!.name, 'Benazepril');
      });

      test('returns null for non-existent medication', () {
        final result = service.getMedicationByName('Nonexistent');
        expect(result, isNull);
      });

      test('returns null when not initialized', () {
        final uninitializedService = MedicationDatabaseService(
          assetBundle: mockAssetBundle,
        );
        final result = uninitializedService.getMedicationByName('Benazepril');
        expect(result, isNull);
      });

      test(
        'returns first match if multiple medications with same name',
        () async {
        final duplicateData = json.encode([
          {
        'name': 'Benazepril',
            'form': 'tablet',
            'strength': '5',
            'unit': 'mg',
            'route': 'oral',
            'category': 'ACE_inhibitor',
            'brand_names': 'Fortekor',
          },
          {
        'name': 'Benazepril',
            'form': 'tablet',
            'strength': '10',
            'unit': 'mg',
            'route': 'oral',
            'category': 'ACE_inhibitor',
            'brand_names': 'Other Brand',
          },
        ]);

        final bundle = MockAssetBundle(duplicateData);
        final testService = MedicationDatabaseService(assetBundle: bundle);
        await testService.initialize();

          final result = testService.getMedicationByName('Benazepril');
          expect(result, isNotNull);
          expect(result!.name, 'Benazepril');
        },
      );

      test('does not match partial names', () {
        final result = service.getMedicationByName('Bena');
        expect(result, isNull);
      });
    });

    group('Error Handling', () {
      test('handles empty JSON array gracefully', () async {
        final emptyBundle = MockAssetBundle(json.encode([]));
        final testService = MedicationDatabaseService(assetBundle: emptyBundle);

        await testService.initialize();

        expect(testService.isInitialized, isTrue);
        expect(testService.medicationCount, 0);
      });

      test('handles malformed JSON entries gracefully', () async {
        final malformedData = json.encode([
          {
        'name': 'Valid Med',
            'form': 'tablet',
            'strength': '5',
            'unit': 'mg',
            'route': 'oral',
            'category': 'other',
            'brand_names': 'Brand',
          },
          {
            'unexpected_field': 'value',
          },
        ]);

        final bundle = MockAssetBundle(malformedData);
        final testService = MedicationDatabaseService(assetBundle: bundle);

        await testService.initialize();

        expect(testService.isInitialized, isTrue);
        // At least the valid entry should be loaded
        expect(testService.medicationCount, greaterThanOrEqualTo(1));
      });
    });

    group('Performance', () {
      test('search completes quickly on large dataset', () async {
        final largeMeds = List.generate(
          332,
          (i) => {
'name': 'Medication$i',
            'form': 'tablet',
            'strength': '${i % 10 + 1}',
            'unit': 'mg',
            'route': 'oral',
            'category': 'other',
            'brand_names': 'Brand$i',
          },
        );

        final bundle = MockAssetBundle(json.encode(largeMeds));
        final testService = MedicationDatabaseService(assetBundle: bundle);

        await testService.initialize();

        final stopwatch = Stopwatch()..start();
        testService.searchMedications('medication');
        stopwatch.stop();

        // Search should complete in less than 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}
