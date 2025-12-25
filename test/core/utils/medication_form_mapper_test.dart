import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/utils/medication_form_mapper.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';

void main() {
  group('MedicationFormMapper', () {
    group('mapFormToUnit', () {
      test('maps tablet to pills', () {
        final result = MedicationFormMapper.mapFormToUnit('tablet');
        expect(result, MedicationUnit.pills);
      });

      test('maps capsule to capsules', () {
        final result = MedicationFormMapper.mapFormToUnit('capsule');
        expect(result, MedicationUnit.capsules);
      });

      test('maps powder to portions', () {
        final result = MedicationFormMapper.mapFormToUnit('powder');
        expect(result, MedicationUnit.portions);
      });

      test('maps liquid to milliliters', () {
        final result = MedicationFormMapper.mapFormToUnit('liquid');
        expect(result, MedicationUnit.milliliters);
      });

      test('maps oral_solution to milliliters', () {
        final result = MedicationFormMapper.mapFormToUnit('oral_solution');
        expect(result, MedicationUnit.milliliters);
      });

      test('maps gel to portions', () {
        final result = MedicationFormMapper.mapFormToUnit('gel');
        expect(result, MedicationUnit.portions);
      });

      test('maps transdermal to portions', () {
        final result = MedicationFormMapper.mapFormToUnit('transdermal');
        expect(result, MedicationUnit.portions);
      });

      test('returns null for unknown form', () {
        final result = MedicationFormMapper.mapFormToUnit('unknown');
        expect(result, isNull);
      });

      test('returns null for empty string', () {
        final result = MedicationFormMapper.mapFormToUnit('');
        expect(result, isNull);
      });

      test('is case insensitive', () {
        expect(
          MedicationFormMapper.mapFormToUnit('TABLET'),
          MedicationUnit.pills,
        );
        expect(
          MedicationFormMapper.mapFormToUnit('Capsule'),
          MedicationUnit.capsules,
        );
        expect(
          MedicationFormMapper.mapFormToUnit('POWDER'),
          MedicationUnit.portions,
        );
      });

      test('handles whitespace', () {
        expect(
          MedicationFormMapper.mapFormToUnit('  tablet  '),
          MedicationUnit.pills,
        );
        expect(
          MedicationFormMapper.mapFormToUnit(' liquid '),
          MedicationUnit.milliliters,
        );
      });

      test('maps all valid forms from database', () {
        final validForms = {
          'tablet': MedicationUnit.pills,
          'capsule': MedicationUnit.capsules,
          'powder': MedicationUnit.portions,
          'liquid': MedicationUnit.milliliters,
          'oral_solution': MedicationUnit.milliliters,
          'gel': MedicationUnit.portions,
          'transdermal': MedicationUnit.portions,
        };

        for (final entry in validForms.entries) {
          final result = MedicationFormMapper.mapFormToUnit(entry.key);
          expect(
            result,
            entry.value,
            reason: 'Form "${entry.key}" should map to ${entry.value}',
          );
        }
      });
    });

    group('mapUnitToStrengthUnit', () {
      test('maps mg to mg', () {
        final result = MedicationFormMapper.mapUnitToStrengthUnit('mg');
        expect(result, MedicationStrengthUnit.mg);
      });

      test('maps ml to mg (liquid form indicator)', () {
        final result = MedicationFormMapper.mapUnitToStrengthUnit('ml');
        expect(result, MedicationStrengthUnit.mg);
      });

      test('maps g to g', () {
        final result = MedicationFormMapper.mapUnitToStrengthUnit('g');
        expect(result, MedicationStrengthUnit.g);
      });

      test('maps mg/ml to mgPerMl', () {
        final result = MedicationFormMapper.mapUnitToStrengthUnit('mg/ml');
        expect(result, MedicationStrengthUnit.mgPerMl);
      });

      test('maps mcg to mcg', () {
        final result = MedicationFormMapper.mapUnitToStrengthUnit('mcg');
        expect(result, MedicationStrengthUnit.mcg);
      });

      test('maps mcg/ml to mcgPerMl', () {
        final result = MedicationFormMapper.mapUnitToStrengthUnit('mcg/ml');
        expect(result, MedicationStrengthUnit.mcgPerMl);
      });

      test('maps mg/g to mgPerG', () {
        final result = MedicationFormMapper.mapUnitToStrengthUnit('mg/g');
        expect(result, MedicationStrengthUnit.mgPerG);
      });

      test('maps mcg/g to mcgPerG', () {
        final result = MedicationFormMapper.mapUnitToStrengthUnit('mcg/g');
        expect(result, MedicationStrengthUnit.mcgPerG);
      });

      test('maps iu to iu', () {
        final result = MedicationFormMapper.mapUnitToStrengthUnit('iu');
        expect(result, MedicationStrengthUnit.iu);
      });

      test('maps iu/ml to iuPerMl', () {
        final result = MedicationFormMapper.mapUnitToStrengthUnit('iu/ml');
        expect(result, MedicationStrengthUnit.iuPerMl);
      });

      test('maps % to percent', () {
        final result = MedicationFormMapper.mapUnitToStrengthUnit('%');
        expect(result, MedicationStrengthUnit.percent);
      });

      test('returns null for unknown unit', () {
        final result = MedicationFormMapper.mapUnitToStrengthUnit('unknown');
        expect(result, isNull);
      });

      test('returns null for empty string', () {
        final result = MedicationFormMapper.mapUnitToStrengthUnit('');
        expect(result, isNull);
      });

      test('is case insensitive', () {
        expect(
          MedicationFormMapper.mapUnitToStrengthUnit('MG'),
          MedicationStrengthUnit.mg,
        );
        expect(
          MedicationFormMapper.mapUnitToStrengthUnit('Mcg'),
          MedicationStrengthUnit.mcg,
        );
        expect(
          MedicationFormMapper.mapUnitToStrengthUnit('MG/ML'),
          MedicationStrengthUnit.mgPerMl,
        );
      });

      test('handles whitespace', () {
        expect(
          MedicationFormMapper.mapUnitToStrengthUnit('  mg  '),
          MedicationStrengthUnit.mg,
        );
        expect(
          MedicationFormMapper.mapUnitToStrengthUnit(' mg/ml '),
          MedicationStrengthUnit.mgPerMl,
        );
      });

      test('maps all valid units from database', () {
        final validUnits = {
          'mg': MedicationStrengthUnit.mg,
          'ml': MedicationStrengthUnit.mg,
          'g': MedicationStrengthUnit.g,
          'mg/ml': MedicationStrengthUnit.mgPerMl,
          'mcg': MedicationStrengthUnit.mcg,
          'mcg/ml': MedicationStrengthUnit.mcgPerMl,
          'mg/g': MedicationStrengthUnit.mgPerG,
          'mcg/g': MedicationStrengthUnit.mcgPerG,
          'iu': MedicationStrengthUnit.iu,
          'iu/ml': MedicationStrengthUnit.iuPerMl,
          '%': MedicationStrengthUnit.percent,
        };

        for (final entry in validUnits.entries) {
          final result = MedicationFormMapper.mapUnitToStrengthUnit(entry.key);
          expect(
            result,
            entry.value,
            reason: 'Unit "${entry.key}" should map to ${entry.value}',
          );
        }
      });
    });

    group('Edge Cases', () {
      test('mapFormToUnit handles special characters gracefully', () {
        expect(MedicationFormMapper.mapFormToUnit('tab@let'), isNull);
        expect(MedicationFormMapper.mapFormToUnit('powder!'), isNull);
      });

      test('mapUnitToStrengthUnit handles special characters gracefully', () {
        expect(MedicationFormMapper.mapUnitToStrengthUnit('mg@ml'), isNull);
        expect(MedicationFormMapper.mapUnitToStrengthUnit('mcg!'), isNull);
      });

      test('mapFormToUnit handles very long strings', () {
        final longString = 'tablet' * 100;
        expect(MedicationFormMapper.mapFormToUnit(longString), isNull);
      });

      test('mapUnitToStrengthUnit handles very long strings', () {
        final longString = 'mg' * 100;
        expect(MedicationFormMapper.mapUnitToStrengthUnit(longString), isNull);
      });
    });

    group('Integration with Database Values', () {
      test('correctly maps common CKD medication forms', () {
        // Phosphate binders
        expect(
          MedicationFormMapper.mapFormToUnit('powder'),
          MedicationUnit.portions,
        );

        // ACE inhibitors
        expect(
          MedicationFormMapper.mapFormToUnit('tablet'),
          MedicationUnit.pills,
        );

        // Antiemetics
        expect(
          MedicationFormMapper.mapFormToUnit('liquid'),
          MedicationUnit.milliliters,
        );

        // Topical treatments
        expect(
          MedicationFormMapper.mapFormToUnit('gel'),
          MedicationUnit.portions,
        );
        expect(
          MedicationFormMapper.mapFormToUnit('transdermal'),
          MedicationUnit.portions,
        );
      });

      test('correctly maps common CKD medication units', () {
        // Standard oral medications
        expect(
          MedicationFormMapper.mapUnitToStrengthUnit('mg'),
          MedicationStrengthUnit.mg,
        );

        // Liquid concentrations
        expect(
          MedicationFormMapper.mapUnitToStrengthUnit('mg/ml'),
          MedicationStrengthUnit.mgPerMl,
        );

        // Topical concentrations
        expect(
          MedicationFormMapper.mapUnitToStrengthUnit('mg/g'),
          MedicationStrengthUnit.mgPerG,
        );

        // Vitamin supplements
        expect(
          MedicationFormMapper.mapUnitToStrengthUnit('iu'),
          MedicationStrengthUnit.iu,
        );
      });
    });
  });
}
