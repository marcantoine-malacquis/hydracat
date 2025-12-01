import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/utils/symptom_descriptor_utils.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';

void main() {
  group('SymptomDescriptorUtils', () {
    group('getSymptomLabel', () {
      test('returns correct label for vomiting', () {
        expect(
          SymptomDescriptorUtils.getSymptomLabel(SymptomType.vomiting),
          'Vomiting',
        );
      });

      test('returns correct label for diarrhea', () {
        expect(
          SymptomDescriptorUtils.getSymptomLabel(SymptomType.diarrhea),
          'Diarrhea',
        );
      });

      test('returns correct label for constipation', () {
        expect(
          SymptomDescriptorUtils.getSymptomLabel(SymptomType.constipation),
          'Constipation',
        );
      });

      test('returns correct label for energy', () {
        expect(
          SymptomDescriptorUtils.getSymptomLabel(SymptomType.energy),
          'Energy',
        );
      });

      test('returns correct label for suppressed appetite', () {
        expect(
          SymptomDescriptorUtils.getSymptomLabel(
            SymptomType.suppressedAppetite,
          ),
          'Suppressed Appetite',
        );
      });

      test('returns correct label for injection site reaction', () {
        expect(
          SymptomDescriptorUtils.getSymptomLabel(
            SymptomType.injectionSiteReaction,
          ),
          'Injection Site Reaction',
        );
      });

      test('returns key as fallback for unknown symptom', () {
        expect(
          SymptomDescriptorUtils.getSymptomLabel('unknownSymptom'),
          'unknownSymptom',
        );
      });
    });

    group('formatRawValueDescriptor', () {
      group('vomiting', () {
        test('formats 1 episode correctly', () {
          expect(
            SymptomDescriptorUtils.formatRawValueDescriptor(
              SymptomType.vomiting,
              1,
            ),
            '1 episode',
          );
        });

        test('formats multiple episodes correctly', () {
          expect(
            SymptomDescriptorUtils.formatRawValueDescriptor(
              SymptomType.vomiting,
              3,
            ),
            '3 episodes',
          );
        });

        test('formats 0 episodes correctly', () {
          expect(
            SymptomDescriptorUtils.formatRawValueDescriptor(
              SymptomType.vomiting,
              0,
            ),
            '0 episodes',
          );
        });

        test('formats 10+ episodes correctly', () {
          expect(
            SymptomDescriptorUtils.formatRawValueDescriptor(
              SymptomType.vomiting,
              10,
            ),
            '10 episodes',
          );
        });

        test('returns null for invalid type', () {
          expect(
            SymptomDescriptorUtils.formatRawValueDescriptor(
              SymptomType.vomiting,
              'invalid',
            ),
            null,
          );
        });
      });

      group('diarrhea', () {
        test('formats normal correctly', () {
          expect(
            SymptomDescriptorUtils.formatRawValueDescriptor(
              SymptomType.diarrhea,
              'normal',
            ),
            'Normal',
          );
        });

        test('formats soft correctly', () {
          expect(
            SymptomDescriptorUtils.formatRawValueDescriptor(
              SymptomType.diarrhea,
              'soft',
            ),
            'Soft',
          );
        });

        test('formats loose correctly', () {
          expect(
            SymptomDescriptorUtils.formatRawValueDescriptor(
              SymptomType.diarrhea,
              'loose',
            ),
            'Loose',
          );
        });

        test('formats watery correctly', () {
          expect(
            SymptomDescriptorUtils.formatRawValueDescriptor(
              SymptomType.diarrhea,
              'watery',
            ),
            'Watery / liquid',
          );
        });

        test('returns null for invalid type', () {
          expect(
            SymptomDescriptorUtils.formatRawValueDescriptor(
              SymptomType.diarrhea,
              123,
            ),
            null,
          );
        });
      });

      group('constipation', () {
        test('formats normal correctly', () {
          expect(
            SymptomDescriptorUtils.formatRawValueDescriptor(
              SymptomType.constipation,
              'normal',
            ),
            'Normal stooling',
          );
        });

        test('formats mild straining correctly', () {
          expect(
            SymptomDescriptorUtils.formatRawValueDescriptor(
              SymptomType.constipation,
              'mildStraining',
            ),
            'Mild straining',
          );
        });
      });

      group('suppressedAppetite', () {
        test('formats all correctly', () {
          expect(
            SymptomDescriptorUtils.formatRawValueDescriptor(
              SymptomType.suppressedAppetite,
              'all',
            ),
            'All',
          );
        });

        test('formats half correctly', () {
          expect(
            SymptomDescriptorUtils.formatRawValueDescriptor(
              SymptomType.suppressedAppetite,
              'half',
            ),
            '½',
          );
        });
      });

      group('injectionSiteReaction', () {
        test('formats none correctly', () {
          expect(
            SymptomDescriptorUtils.formatRawValueDescriptor(
              SymptomType.injectionSiteReaction,
              'none',
            ),
            'None',
          );
        });

        test('formats visible swelling correctly', () {
          expect(
            SymptomDescriptorUtils.formatRawValueDescriptor(
              SymptomType.injectionSiteReaction,
              'visibleSwelling',
            ),
            'Visible swelling',
          );
        });
      });

      group('energy', () {
        test('formats normal correctly', () {
          expect(
            SymptomDescriptorUtils.formatRawValueDescriptor(
              SymptomType.energy,
              'normal',
            ),
            'Normal energy',
          );
        });

        test('formats low correctly', () {
          expect(
            SymptomDescriptorUtils.formatRawValueDescriptor(
              SymptomType.energy,
              'low',
            ),
            'Low energy',
          );
        });
      });

      test('returns null for null raw value', () {
        expect(
          SymptomDescriptorUtils.formatRawValueDescriptor(
            SymptomType.vomiting,
            null,
          ),
          null,
        );
      });

      test('returns null for unknown symptom key', () {
        expect(
          SymptomDescriptorUtils.formatRawValueDescriptor(
            'unknownSymptom',
            'someValue',
          ),
          null,
        );
      });
    });
  });
}
