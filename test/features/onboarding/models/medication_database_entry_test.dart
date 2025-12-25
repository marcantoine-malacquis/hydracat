import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/onboarding/models/brand_name.dart';
import 'package:hydracat/features/onboarding/models/medication_database_entry.dart';

void main() {
  group('MedicationDatabaseEntry', () {
    group('Constructor', () {
      test('creates entry with all fields', () {
        const entry = MedicationDatabaseEntry(
          name: 'Benazepril',
          form: 'tablet',
          strength: '5',
          unit: 'mg',
          route: 'oral',
          category: 'ACE_inhibitor',
          brandNames: [BrandName(name: 'Fortekor', primary: true)],
        );

        expect(entry.name, 'Benazepril');
        expect(entry.form, 'tablet');
        expect(entry.strength, '5');
        expect(entry.unit, 'mg');
        expect(entry.route, 'oral');
        expect(entry.category, 'ACE_inhibitor');
        expect(
          entry.brandNames,
          const [BrandName(name: 'Fortekor', primary: true)],
        );
      });
    });

    group('fromJson', () {
      test('parses valid JSON correctly', () {
        final json = {
          'name': 'Aluminum hydroxide',
          'form': 'powder',
          'strength': 'variable',
          'unit': 'mg',
          'route': 'oral',
          'category': 'phosphate_binder',
          'brand_names': 'Various generics',
        };

        final entry = MedicationDatabaseEntry.fromJson(json);

        expect(entry.name, 'Aluminum hydroxide');
        expect(entry.form, 'powder');
        expect(entry.strength, 'variable');
        expect(entry.unit, 'mg');
        expect(entry.route, 'oral');
        expect(entry.category, 'phosphate_binder');
        expect(entry.brandNames.length, 1);
        expect(entry.brandNames.first.name, 'Various generics');
        expect(entry.brandNames.first.primary, true);
      });

      test('handles missing optional fields with empty strings', () {
        final json = {
          'name': 'Test Med',
          'form': 'tablet',
          'strength': '10',
          'unit': 'mg',
          'route': 'oral',
          'category': 'other',
        };

        final entry = MedicationDatabaseEntry.fromJson(json);

        expect(entry.brandNames, isEmpty);
      });

      test('handles null values with empty strings', () {
        final json = {
          'name': null,
          'form': null,
          'strength': null,
          'unit': null,
          'route': null,
          'category': null,
          'brand_names': null,
        };

        final entry = MedicationDatabaseEntry.fromJson(json);

        expect(entry.name, '');
        expect(entry.form, '');
        expect(entry.strength, '');
        expect(entry.unit, '');
        expect(entry.route, '');
        expect(entry.category, '');
        expect(entry.brandNames, isEmpty);
      });
    });

    group('displayName', () {
      test('formats name with strength and form for numeric strength', () {
        const entry = MedicationDatabaseEntry(
          name: 'Benazepril',
          form: 'tablet',
          strength: '5',
          unit: 'mg',
          route: 'oral',
          category: 'ACE_inhibitor',
          brandNames: [BrandName(name: 'Fortekor', primary: true)],
        );

        expect(entry.displayName, 'Benazepril 5mg tablet');
      });

      test('omits strength for variable strength medications', () {
        const entry = MedicationDatabaseEntry(
          name: 'Aluminum hydroxide',
          form: 'powder',
          strength: 'variable',
          unit: 'mg',
          route: 'oral',
          category: 'phosphate_binder',
          brandNames: [BrandName(name: 'Various', primary: true)],
        );

        expect(entry.displayName, 'Aluminum hydroxide powder');
      });

      test('handles different form types', () {
        const capsuleEntry = MedicationDatabaseEntry(
name: 'Test Med',
          form: 'capsule',
          strength: '10',
          unit: 'mg',
          route: 'oral',
          category: 'other',
          brandNames: [],
        );

        expect(capsuleEntry.displayName, 'Test Med 10mg capsule');

        const liquidEntry = MedicationDatabaseEntry(
name: 'Liquid Med',
          form: 'liquid',
          strength: '2.5',
          unit: 'mg/mL',
          route: 'oral',
          category: 'other',
          brandNames: [],
        );

        expect(liquidEntry.displayName, 'Liquid Med 2.5mg/mL liquid');
      });
    });

    group('searchableText', () {
      test('returns lowercase name and brand names', () {
        const entry = MedicationDatabaseEntry(
          name: 'Benazepril',
          form: 'tablet',
          strength: '5',
          unit: 'mg',
          route: 'oral',
          category: 'ACE_inhibitor',
          brandNames: [BrandName(name: 'Fortekor', primary: true)],
        );

        expect(entry.searchableText, 'benazepril fortekor');
      });

      test('handles empty brand names', () {
        const entry = MedicationDatabaseEntry(
          name: 'TestMed',
          form: 'tablet',
          strength: '10',
          unit: 'mg',
          route: 'oral',
          category: 'other',
          brandNames: [],
        );

        expect(entry.searchableText, 'testmed');
      });

      test('converts mixed case to lowercase', () {
        const entry = MedicationDatabaseEntry(
          name: 'MyMedication',
          form: 'tablet',
          strength: '5',
          unit: 'mg',
          route: 'oral',
          category: 'other',
          brandNames: [BrandName(name: 'BrandName', primary: true)],
        );

        expect(entry.searchableText, 'mymedication brandname');
      });
    });

    group('hasVariableStrength', () {
      test('returns true for "variable" strength', () {
        const entry = MedicationDatabaseEntry(
          name: 'Test',
          form: 'powder',
          strength: 'variable',
          unit: 'mg',
          route: 'oral',
          category: 'other',
          brandNames: [],
        );

        expect(entry.hasVariableStrength, isTrue);
      });

      test('returns true for "VARIABLE" strength (case insensitive)', () {
        const entry = MedicationDatabaseEntry(
          name: 'Test',
          form: 'powder',
          strength: 'VARIABLE',
          unit: 'mg',
          route: 'oral',
          category: 'other',
          brandNames: [],
        );

        expect(entry.hasVariableStrength, isTrue);
      });

      test('returns false for numeric strength', () {
        const entry = MedicationDatabaseEntry(
          name: 'Test',
          form: 'tablet',
          strength: '5',
          unit: 'mg',
          route: 'oral',
          category: 'other',
          brandNames: [],
        );

        expect(entry.hasVariableStrength, isFalse);
      });
    });

    group('validate', () {
      test('returns empty list for valid entry', () {
        const entry = MedicationDatabaseEntry(
          name: 'Benazepril',
          form: 'tablet',
          strength: '5',
          unit: 'mg',
          route: 'oral',
          category: 'ACE_inhibitor',
          brandNames: [BrandName(name: 'Fortekor', primary: true)],
        );

        final errors = entry.validate();
        expect(errors, isEmpty);
      });

      test('returns error for empty name', () {
        const entry = MedicationDatabaseEntry(
          name: '',
          form: 'tablet',
          strength: '5',
          unit: 'mg',
          route: 'oral',
          category: 'other',
          brandNames: [],
        );

        final errors = entry.validate();
        expect(errors, contains('Name is required'));
      });

      test('returns error for empty form', () {
        const entry = MedicationDatabaseEntry(
          name: 'Test',
          form: '',
          strength: '5',
          unit: 'mg',
          route: 'oral',
          category: 'other',
          brandNames: [],
        );

        final errors = entry.validate();
        expect(errors, contains('Form is required'));
      });

      test('returns error for invalid form', () {
        const entry = MedicationDatabaseEntry(
          name: 'Test',
          form: 'unknown',
          strength: '5',
          unit: 'mg',
          route: 'oral',
          category: 'other',
          brandNames: [],
        );

        final errors = entry.validate();
        expect(errors, contains('Invalid form: "unknown"'));
      });

      test('returns error for empty strength', () {
        const entry = MedicationDatabaseEntry(
          name: 'Test',
          form: 'tablet',
          strength: '',
          unit: 'mg',
          route: 'oral',
          category: 'other',
          brandNames: [],
        );

        final errors = entry.validate();
        expect(errors, contains('Strength is required'));
      });

      test('returns error for non-numeric non-variable strength', () {
        const entry = MedicationDatabaseEntry(
          name: 'Test',
          form: 'tablet',
          strength: 'abc',
          unit: 'mg',
          route: 'oral',
          category: 'other',
          brandNames: [],
        );

        final errors = entry.validate();
        expect(
          errors,
          contains('Strength must be numeric or "variable", got "abc"'),
        );
      });

      test('returns error for empty unit', () {
        const entry = MedicationDatabaseEntry(
          name: 'Test',
          form: 'tablet',
          strength: '5',
          unit: '',
          route: 'oral',
          category: 'other',
          brandNames: [],
        );

        final errors = entry.validate();
        expect(errors, contains('Unit is required'));
      });

      test('returns multiple errors for multiple invalid fields', () {
        const entry = MedicationDatabaseEntry(
          name: '',
          form: 'unknown',
          strength: 'abc',
          unit: '',
          route: 'oral',
          category: 'other',
          brandNames: [],
        );

        final errors = entry.validate();
        expect(errors.length, greaterThan(1));
      });

      test('accepts variable strength', () {
        const entry = MedicationDatabaseEntry(
          name: 'Test',
          form: 'powder',
          strength: 'variable',
          unit: 'mg',
          route: 'oral',
          category: 'other',
          brandNames: [],
        );

        final errors = entry.validate();
        expect(errors, isEmpty);
      });

      test('accepts all valid form types', () {
        const validForms = [
          'tablet',
          'powder',
          'liquid',
          'capsule',
          'oral_solution',
          'gel',
          'transdermal',
        ];

        for (final form in validForms) {
          final entry = MedicationDatabaseEntry(
    name: 'Test',
            form: form,
            strength: '5',
            unit: 'mg',
            route: 'oral',
            category: 'other',
            brandNames: const [],
          );

          final errors = entry.validate();
          expect(errors, isEmpty, reason: 'Form "$form" should be valid');
        }
      });
    });

    group('toJson', () {
      test('serializes to JSON correctly', () {
        const entry = MedicationDatabaseEntry(
          name: 'Benazepril',
          form: 'tablet',
          strength: '5',
          unit: 'mg',
          route: 'oral',
          category: 'ACE_inhibitor',
          brandNames: [BrandName(name: 'Fortekor', primary: true)],
        );

        final json = entry.toJson();

        expect(json['name'], 'Benazepril');
        expect(json['form'], 'tablet');
        expect(json['strength'], '5');
        expect(json['unit'], 'mg');
        expect(json['route'], 'oral');
        expect(json['category'], 'ACE_inhibitor');
        expect(json['brand_names'], [
          {'name': 'Fortekor', 'primary': true},
        ]);
      });
    });

    group('Equality and HashCode', () {
      test('equal entries have same hashCode', () {
        const entry1 = MedicationDatabaseEntry(
          name: 'Benazepril',
          form: 'tablet',
          strength: '5',
          unit: 'mg',
          route: 'oral',
          category: 'ACE_inhibitor',
          brandNames: [BrandName(name: 'Fortekor', primary: true)],
        );

        const entry2 = MedicationDatabaseEntry(
name: 'Benazepril',
          form: 'tablet',
          strength: '5',
          unit: 'mg',
          route: 'oral',
          category: 'ACE_inhibitor',
          brandNames: [BrandName(name: 'Fortekor', primary: true)],
        );

        expect(entry1, equals(entry2));
        expect(entry1.hashCode, equals(entry2.hashCode));
      });

      test('different entries are not equal', () {
        const entry1 = MedicationDatabaseEntry(
          name: 'Benazepril',
          form: 'tablet',
          strength: '5',
          unit: 'mg',
          route: 'oral',
          category: 'ACE_inhibitor',
          brandNames: [BrandName(name: 'Fortekor', primary: true)],
        );

        const entry2 = MedicationDatabaseEntry(
          name: 'Amlodipine',
          form: 'tablet',
          strength: '5',
          unit: 'mg',
          route: 'oral',
          category: 'ACE_inhibitor',
          brandNames: [BrandName(name: 'Fortekor', primary: true)],
        );

        expect(entry1, isNot(equals(entry2)));
      });
    });

    group('toString', () {
      test('includes all fields', () {
        const entry = MedicationDatabaseEntry(
          name: 'Benazepril',
          form: 'tablet',
          strength: '5',
          unit: 'mg',
          route: 'oral',
          category: 'ACE_inhibitor',
          brandNames: [BrandName(name: 'Fortekor', primary: true)],
        );

        final string = entry.toString();

        expect(string, contains('name: Benazepril'));
        expect(string, contains('form: tablet'));
        expect(string, contains('strength: 5'));
        expect(string, contains('unit: mg'));
        expect(string, contains('route: oral'));
        expect(string, contains('category: ACE_inhibitor'));
        expect(string, contains('brandNames:'));
        expect(string, contains('Fortekor'));
      });
    });
  });
}
