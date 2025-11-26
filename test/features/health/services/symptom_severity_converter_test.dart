import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/health/models/symptom_entry.dart';
import 'package:hydracat/features/health/models/symptom_raw_value.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';
import 'package:hydracat/features/health/services/symptom_severity_converter.dart';

void main() {
  group('SymptomSeverityConverter', () {
    group('vomitingToSeverity', () {
      test('returns 0 for 0 episodes', () {
        expect(SymptomSeverityConverter.vomitingToSeverity(0), 0);
      });

      test('returns 1 for 1 episode', () {
        expect(SymptomSeverityConverter.vomitingToSeverity(1), 1);
      });

      test('returns 2 for 2 episodes', () {
        expect(SymptomSeverityConverter.vomitingToSeverity(2), 2);
      });

      test('returns 3 for 3 episodes', () {
        expect(SymptomSeverityConverter.vomitingToSeverity(3), 3);
      });

      test('returns 3 for 5 episodes', () {
        expect(SymptomSeverityConverter.vomitingToSeverity(5), 3);
      });

      test('returns 3 for 10 episodes', () {
        expect(SymptomSeverityConverter.vomitingToSeverity(10), 3);
      });

      test('returns 3 for large episode counts', () {
        expect(SymptomSeverityConverter.vomitingToSeverity(20), 3);
      });

      test('returns 0 for negative episodes', () {
        expect(SymptomSeverityConverter.vomitingToSeverity(-1), 0);
      });
    });

    group('diarrheaToSeverity', () {
      test('returns 0 for normal', () {
        expect(
          SymptomSeverityConverter.diarrheaToSeverity(DiarrheaQuality.normal),
          0,
        );
      });

      test('returns 1 for soft', () {
        expect(
          SymptomSeverityConverter.diarrheaToSeverity(DiarrheaQuality.soft),
          1,
        );
      });

      test('returns 2 for loose', () {
        expect(
          SymptomSeverityConverter.diarrheaToSeverity(DiarrheaQuality.loose),
          2,
        );
      });

      test('returns 3 for watery', () {
        expect(
          SymptomSeverityConverter.diarrheaToSeverity(DiarrheaQuality.watery),
          3,
        );
      });
    });

    group('constipationToSeverity', () {
      test('returns 0 for normal', () {
        expect(
          SymptomSeverityConverter.constipationToSeverity(
            ConstipationLevel.normal,
          ),
          0,
        );
      });

      test('returns 1 for mildStraining', () {
        expect(
          SymptomSeverityConverter.constipationToSeverity(
            ConstipationLevel.mildStraining,
          ),
          1,
        );
      });

      test('returns 2 for noStool', () {
        expect(
          SymptomSeverityConverter.constipationToSeverity(
            ConstipationLevel.noStool,
          ),
          2,
        );
      });

      test('returns 3 for painful', () {
        expect(
          SymptomSeverityConverter.constipationToSeverity(
            ConstipationLevel.painful,
          ),
          3,
        );
      });
    });

    group('appetiteToSeverity', () {
      test('returns 0 for all', () {
        expect(
          SymptomSeverityConverter.appetiteToSeverity(AppetiteFraction.all),
          0,
        );
      });

      test('returns 1 for threeQuarters', () {
        expect(
          SymptomSeverityConverter.appetiteToSeverity(
            AppetiteFraction.threeQuarters,
          ),
          1,
        );
      });

      test('returns 2 for half', () {
        expect(
          SymptomSeverityConverter.appetiteToSeverity(AppetiteFraction.half),
          2,
        );
      });

      test('returns 3 for quarter', () {
        expect(
          SymptomSeverityConverter.appetiteToSeverity(
            AppetiteFraction.quarter,
          ),
          3,
        );
      });

      test('returns 3 for nothing', () {
        expect(
          SymptomSeverityConverter.appetiteToSeverity(
            AppetiteFraction.nothing,
          ),
          3,
        );
      });
    });

    group('injectionSiteToSeverity', () {
      test('returns 0 for none', () {
        expect(
          SymptomSeverityConverter.injectionSiteToSeverity(
            InjectionSiteReaction.none,
          ),
          0,
        );
      });

      test('returns 1 for mildSwelling', () {
        expect(
          SymptomSeverityConverter.injectionSiteToSeverity(
            InjectionSiteReaction.mildSwelling,
          ),
          1,
        );
      });

      test('returns 2 for visibleSwelling', () {
        expect(
          SymptomSeverityConverter.injectionSiteToSeverity(
            InjectionSiteReaction.visibleSwelling,
          ),
          2,
        );
      });

      test('returns 3 for redPainful', () {
        expect(
          SymptomSeverityConverter.injectionSiteToSeverity(
            InjectionSiteReaction.redPainful,
          ),
          3,
        );
      });
    });

    group('energyToSeverity', () {
      test('returns 0 for normal', () {
        expect(
          SymptomSeverityConverter.energyToSeverity(EnergyLevel.normal),
          0,
        );
      });

      test('returns 1 for slightlyReduced', () {
        expect(
          SymptomSeverityConverter.energyToSeverity(
            EnergyLevel.slightlyReduced,
          ),
          1,
        );
      });

      test('returns 2 for low', () {
        expect(
          SymptomSeverityConverter.energyToSeverity(EnergyLevel.low),
          2,
        );
      });

      test('returns 3 for veryLow', () {
        expect(
          SymptomSeverityConverter.energyToSeverity(EnergyLevel.veryLow),
          3,
        );
      });
    });

    group('createEntry', () {
      group('vomiting', () {
        test('creates entry with correct severity for 0 episodes', () {
          final entry = SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.vomiting,
            rawValue: 0,
          );
          expect(entry.symptomType, SymptomType.vomiting);
          expect(entry.rawValue, 0);
          expect(entry.severityScore, 0);
        });

        test('creates entry with correct severity for 2 episodes', () {
          final entry = SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.vomiting,
            rawValue: 2,
          );
          expect(entry.symptomType, SymptomType.vomiting);
          expect(entry.rawValue, 2);
          expect(entry.severityScore, 2);
        });

        test('creates entry with correct severity for 5 episodes', () {
          final entry = SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.vomiting,
            rawValue: 5,
          );
          expect(entry.symptomType, SymptomType.vomiting);
          expect(entry.rawValue, 5);
          expect(entry.severityScore, 3);
        });
      });

      group('diarrhea', () {
        test('creates entry from enum value', () {
          final entry = SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.diarrhea,
            rawValue: DiarrheaQuality.soft,
          );
          expect(entry.symptomType, SymptomType.diarrhea);
          expect(entry.rawValue, DiarrheaQuality.soft);
          expect(entry.severityScore, 1);
        });

        test('creates entry from string name', () {
          final entry = SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.diarrhea,
            rawValue: 'loose',
          );
          expect(entry.symptomType, SymptomType.diarrhea);
          expect(entry.rawValue, 'loose');
          expect(entry.severityScore, 2);
        });

        test('creates entry with severity 3 for watery', () {
          final entry = SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.diarrhea,
            rawValue: DiarrheaQuality.watery,
          );
          expect(entry.severityScore, 3);
        });
      });

      group('constipation', () {
        test('creates entry from enum value', () {
          final entry = SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.constipation,
            rawValue: ConstipationLevel.mildStraining,
          );
          expect(entry.symptomType, SymptomType.constipation);
          expect(entry.rawValue, ConstipationLevel.mildStraining);
          expect(entry.severityScore, 1);
        });

        test('creates entry from string name', () {
          final entry = SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.constipation,
            rawValue: 'painful',
          );
          expect(entry.symptomType, SymptomType.constipation);
          expect(entry.rawValue, 'painful');
          expect(entry.severityScore, 3);
        });
      });

      group('suppressedAppetite', () {
        test('creates entry from enum value', () {
          final entry = SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.suppressedAppetite,
            rawValue: AppetiteFraction.half,
          );
          expect(entry.symptomType, SymptomType.suppressedAppetite);
          expect(entry.rawValue, AppetiteFraction.half);
          expect(entry.severityScore, 2);
        });

        test('creates entry from string name', () {
          final entry = SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.suppressedAppetite,
            rawValue: 'nothing',
          );
          expect(entry.symptomType, SymptomType.suppressedAppetite);
          expect(entry.rawValue, 'nothing');
          expect(entry.severityScore, 3);
        });

        test('creates entry with severity 3 for quarter', () {
          final entry = SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.suppressedAppetite,
            rawValue: AppetiteFraction.quarter,
          );
          expect(entry.severityScore, 3);
        });
      });

      group('injectionSiteReaction', () {
        test('creates entry from enum value', () {
          final entry = SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.injectionSiteReaction,
            rawValue: InjectionSiteReaction.visibleSwelling,
          );
          expect(entry.symptomType, SymptomType.injectionSiteReaction);
          expect(entry.rawValue, InjectionSiteReaction.visibleSwelling);
          expect(entry.severityScore, 2);
        });

        test('creates entry from string name', () {
          final entry = SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.injectionSiteReaction,
            rawValue: 'mildSwelling',
          );
          expect(entry.symptomType, SymptomType.injectionSiteReaction);
          expect(entry.rawValue, 'mildSwelling');
          expect(entry.severityScore, 1);
        });
      });

      group('energy', () {
        test('creates entry from enum value', () {
          final entry = SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.energy,
            rawValue: EnergyLevel.low,
          );
          expect(entry.symptomType, SymptomType.energy);
          expect(entry.rawValue, EnergyLevel.low);
          expect(entry.severityScore, 2);
        });

        test('creates entry from string name', () {
          final entry = SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.energy,
            rawValue: 'veryLow',
          );
          expect(entry.symptomType, SymptomType.energy);
          expect(entry.rawValue, 'veryLow');
          expect(entry.severityScore, 3);
        });
      });

      group('error handling', () {
        test('throws ArgumentError for unknown symptom type', () {
          expect(
            () => SymptomSeverityConverter.createEntry(
              symptomType: 'unknownSymptom',
              rawValue: 1,
            ),
            throwsA(isA<ArgumentError>()),
          );
        });

      test('throws ArgumentError with helpful message', () {
        expect(
          () => SymptomSeverityConverter.createEntry(
            symptomType: 'invalidType',
            rawValue: 1,
          ),
          throwsA(
            predicate<ArgumentError>(
              (e) => e.toString().contains('Unknown symptom type'),
            ),
          ),
        );
      });
      });

      group('SymptomEntry properties', () {
        test('creates entry with all required properties', () {
          final entry = SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.vomiting,
            rawValue: 3,
          );

          expect(entry, isA<SymptomEntry>());
          expect(entry.symptomType, isNotEmpty);
          expect(entry.rawValue, isNotNull);
          expect(entry.severityScore, isNotNull);
          expect(entry.severityScore, greaterThanOrEqualTo(0));
          expect(entry.severityScore, lessThanOrEqualTo(3));
        });

        test('preserves rawValue exactly as provided', () {
          final entry = SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.diarrhea,
            rawValue: DiarrheaQuality.loose,
          );

          expect(entry.rawValue, DiarrheaQuality.loose);
        });

        test('preserves string rawValue exactly as provided', () {
          final entry = SymptomSeverityConverter.createEntry(
            symptomType: SymptomType.diarrhea,
            rawValue: 'loose',
          );

          expect(entry.rawValue, 'loose');
        });
      });
    });
  });
}
