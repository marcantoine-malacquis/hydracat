import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/health/models/symptom_bucket.dart';
import 'package:hydracat/features/health/models/symptom_granularity.dart';
import 'package:hydracat/features/health/models/symptom_type.dart';
import 'package:hydracat/providers/symptoms_chart_provider.dart';

void main() {
  group('symptomsChartDataProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Week granularity', () {
      test('should return null when buckets are null (loading)', () {
        final weekStart = AppDateUtils.startOfWeekMonday(DateTime(2025, 10, 6));

        final testContainer = ProviderContainer(
          overrides: [
            symptomsChartStateProvider.overrideWith(
              (ref) => SymptomsChartNotifier()
                ..state = SymptomsChartState(
                  focusedDate: weekStart,
                ),
            ),
            weeklySymptomBucketsProvider.overrideWith(
              (ref, weekStart) => null,
            ),
          ],
        );

        addTearDown(testContainer.dispose);

        final viewModel = testContainer.read(symptomsChartDataProvider);

        expect(viewModel, isNull);
      });

      test('should return view model with empty buckets', () {
        final weekStart = AppDateUtils.startOfWeekMonday(DateTime(2025, 10, 6));
        final emptyBuckets = List.generate(
          7,
          (i) => SymptomBucket.empty(weekStart.add(Duration(days: i))),
        );

        final testContainer = ProviderContainer(
          overrides: [
            symptomsChartStateProvider.overrideWith(
              (ref) => SymptomsChartNotifier()
                ..state = SymptomsChartState(
                  focusedDate: weekStart,
                ),
            ),
            weeklySymptomBucketsProvider.overrideWith(
              (ref, weekStart) => emptyBuckets,
            ),
          ],
        );

        addTearDown(testContainer.dispose);

        final viewModel = testContainer.read(symptomsChartDataProvider);

        expect(viewModel, isNotNull);
        expect(viewModel!.buckets, equals(emptyBuckets));
        expect(viewModel.visibleSymptoms, isEmpty);
        expect(viewModel.hasOther, isFalse);
      });

      test('should compute visible symptoms from buckets', () {
        final weekStart = AppDateUtils.startOfWeekMonday(DateTime(2025, 10, 6));
        final buckets = [
          SymptomBucket.empty(weekStart).copyWith(
            daysWithSymptom: {
              SymptomType.energy: 1,
              SymptomType.vomiting: 1,
            },
            daysWithAnySymptoms: 1,
          ),
          SymptomBucket.empty(weekStart.add(const Duration(days: 1))).copyWith(
            daysWithSymptom: {
              SymptomType.energy: 1,
              SymptomType.diarrhea: 1,
            },
            daysWithAnySymptoms: 1,
          ),
          // Rest are empty
          ...List.generate(
            5,
            (i) => SymptomBucket.empty(weekStart.add(Duration(days: i + 2))),
          ),
        ];

        final testContainer = ProviderContainer(
          overrides: [
            symptomsChartStateProvider.overrideWith(
              (ref) => SymptomsChartNotifier()
                ..state = SymptomsChartState(
                  focusedDate: weekStart,
                ),
            ),
            weeklySymptomBucketsProvider.overrideWith(
              (ref, weekStart) => buckets,
            ),
          ],
        );

        addTearDown(testContainer.dispose);

        final viewModel = testContainer.read(symptomsChartDataProvider);

        expect(viewModel, isNotNull);
        expect(viewModel!.buckets.length, 7);
        // energy appears 2 times, vomiting 1, diarrhea 1
        // Should be ordered by count: energy, then vomiting/diarrhea
        // With tie-breaker: energy (priority 0), vomiting (priority 2),
        // diarrhea (priority 5)
        expect(viewModel.visibleSymptoms.length, 3);
        expect(viewModel.visibleSymptoms[0], SymptomType.energy);
        expect(viewModel.visibleSymptoms[1], SymptomType.vomiting);
        expect(viewModel.visibleSymptoms[2], SymptomType.diarrhea);
        expect(viewModel.hasOther, isFalse);
      });
    });

    group('Month granularity', () {
      test('should return null when buckets are null (loading)', () {
        final monthStart = DateTime(2025, 10);

        final testContainer = ProviderContainer(
          overrides: [
            symptomsChartStateProvider.overrideWith(
              (ref) => SymptomsChartNotifier()
                ..state = SymptomsChartState(
                  focusedDate: monthStart,
                  granularity: SymptomGranularity.month,
                ),
            ),
            monthlySymptomBucketsProvider.overrideWith(
              (ref, _) => Future<List<SymptomBucket>?>.value(),
            ),
          ],
        );

        addTearDown(testContainer.dispose);

        final viewModel = testContainer.read(symptomsChartDataProvider);

        expect(viewModel, isNull);
      });

      test('should return view model with monthly buckets', () async {
        final monthStart = DateTime(2025, 10);
        final buckets = [
          SymptomBucket.forRange(
            start: monthStart,
            end: monthStart.add(const Duration(days: 6)),
          ).copyWith(
            daysWithSymptom: {
              SymptomType.vomiting: 2,
            },
            daysWithAnySymptoms: 2,
          ),
        ];

        final testContainer = ProviderContainer(
          overrides: [
            symptomsChartStateProvider.overrideWith(
              (ref) => SymptomsChartNotifier()
                ..state = SymptomsChartState(
                  focusedDate: monthStart,
                  granularity: SymptomGranularity.month,
                ),
            ),
            monthlySymptomBucketsProvider.overrideWith(
              (ref, _) => Future.value(buckets),
            ),
          ],
        );

        addTearDown(testContainer.dispose);

        // Wait for the FutureProvider to resolve
        await testContainer.read(
          monthlySymptomBucketsProvider(monthStart).future,
        );

        final viewModel = testContainer.read(symptomsChartDataProvider);

        expect(viewModel, isNotNull);
        expect(viewModel!.buckets, equals(buckets));
        expect(viewModel.visibleSymptoms, [SymptomType.vomiting]);
        expect(viewModel.hasOther, isFalse);
      });
    });

    group('Year granularity', () {
      test('should return null when buckets are null (loading)', () {
        final yearStart = DateTime(2025);

        final testContainer = ProviderContainer(
          overrides: [
            symptomsChartStateProvider.overrideWith(
              (ref) => SymptomsChartNotifier()
                ..state = SymptomsChartState(
                  focusedDate: yearStart,
                  granularity: SymptomGranularity.year,
                ),
            ),
            yearlySymptomBucketsProvider.overrideWith(
              (ref, _) => Future.value(),
            ),
          ],
        );

        addTearDown(testContainer.dispose);

        final viewModel = testContainer.read(symptomsChartDataProvider);

        expect(viewModel, isNull);
      });

      test('should return view model with yearly buckets', () async {
        final yearStart = DateTime(2025);
        final buckets = [
          SymptomBucket.forRange(
            start: DateTime(2025),
            end: DateTime(2025, 1, 31),
          ).copyWith(
            daysWithSymptom: {
              SymptomType.energy: 5,
            },
            daysWithAnySymptoms: 5,
          ),
        ];

        final testContainer = ProviderContainer(
          overrides: [
            symptomsChartStateProvider.overrideWith(
              (ref) => SymptomsChartNotifier()
                ..state = SymptomsChartState(
                  focusedDate: yearStart,
                  granularity: SymptomGranularity.year,
                ),
            ),
            yearlySymptomBucketsProvider.overrideWith(
              (ref, _) => Future.value(buckets),
            ),
          ],
        );

        addTearDown(testContainer.dispose);

        // Wait for the FutureProvider to resolve
        await testContainer.read(
          yearlySymptomBucketsProvider(yearStart).future,
        );

        final viewModel = testContainer.read(symptomsChartDataProvider);

        expect(viewModel, isNotNull);
        expect(viewModel!.buckets, equals(buckets));
        expect(viewModel.visibleSymptoms, [SymptomType.energy]);
        expect(viewModel.hasOther, isFalse);
      });
    });

    group('Top-5 + Other logic', () {
      test('should select top 5 symptoms by count', () {
        final weekStart = AppDateUtils.startOfWeekMonday(DateTime(2025, 10, 6));
        // Create buckets with 6 different symptoms, with varying counts
        final buckets = [
          SymptomBucket.empty(weekStart).copyWith(
            daysWithSymptom: {
              SymptomType.energy: 10, // Highest count
              SymptomType.suppressedAppetite: 8,
              SymptomType.vomiting: 6,
              SymptomType.injectionSiteReaction: 4,
              SymptomType.constipation: 2,
              SymptomType.diarrhea: 1, // Lowest count - should be in Other
            },
            daysWithAnySymptoms: 10,
          ),
          // Rest are empty
          ...List.generate(
            6,
            (i) => SymptomBucket.empty(weekStart.add(Duration(days: i + 1))),
          ),
        ];

        final testContainer = ProviderContainer(
          overrides: [
            symptomsChartStateProvider.overrideWith(
              (ref) => SymptomsChartNotifier()
                ..state = SymptomsChartState(
                  focusedDate: weekStart,
                ),
            ),
            weeklySymptomBucketsProvider.overrideWith(
              (ref, weekStart) => buckets,
            ),
          ],
        );

        addTearDown(testContainer.dispose);

        final viewModel = testContainer.read(symptomsChartDataProvider);

        expect(viewModel, isNotNull);
        expect(viewModel!.visibleSymptoms.length, 5);
        // Should be ordered by count: energy, suppressedAppetite, vomiting,
        // injectionSiteReaction, constipation
        expect(viewModel.visibleSymptoms[0], SymptomType.energy);
        expect(viewModel.visibleSymptoms[1], SymptomType.suppressedAppetite);
        expect(viewModel.visibleSymptoms[2], SymptomType.vomiting);
        expect(
          viewModel.visibleSymptoms[3],
          SymptomType.injectionSiteReaction,
        );
        expect(viewModel.visibleSymptoms[4], SymptomType.constipation);
        // diarrhea should be in Other
        expect(
          viewModel.visibleSymptoms,
          isNot(contains(SymptomType.diarrhea)),
        );
        expect(viewModel.hasOther, isTrue);
      });

      test('should use static priority as tie-breaker', () {
        final weekStart = AppDateUtils.startOfWeekMonday(DateTime(2025, 10, 6));
        // Create buckets where multiple symptoms have the same count
        final buckets = [
          SymptomBucket.empty(weekStart).copyWith(
            daysWithSymptom: {
              SymptomType.vomiting: 5, // Same count as energy
              SymptomType.energy:
                  5, // Same count as vomiting, but higher priority
              SymptomType.diarrhea: 5, // Same count, lowest priority
            },
            daysWithAnySymptoms: 5,
          ),
          // Rest are empty
          ...List.generate(
            6,
            (i) => SymptomBucket.empty(weekStart.add(Duration(days: i + 1))),
          ),
        ];

        final testContainer = ProviderContainer(
          overrides: [
            symptomsChartStateProvider.overrideWith(
              (ref) => SymptomsChartNotifier()
                ..state = SymptomsChartState(
                  focusedDate: weekStart,
                ),
            ),
            weeklySymptomBucketsProvider.overrideWith(
              (ref, weekStart) => buckets,
            ),
          ],
        );

        addTearDown(testContainer.dispose);

        final viewModel = testContainer.read(symptomsChartDataProvider);

        expect(viewModel, isNotNull);
        expect(viewModel!.visibleSymptoms.length, 3);
        // With same counts, should be ordered by static priority:
        // energy (priority 0), vomiting (priority 2),
        // diarrhea (priority 5)
        expect(viewModel.visibleSymptoms[0], SymptomType.energy);
        expect(viewModel.visibleSymptoms[1], SymptomType.vomiting);
        expect(viewModel.visibleSymptoms[2], SymptomType.diarrhea);
      });

      test('should set hasOther to false when all symptoms are visible', () {
        final weekStart = AppDateUtils.startOfWeekMonday(DateTime(2025, 10, 6));
        // Create buckets with only 3 symptoms (all should be visible)
        final buckets = [
          SymptomBucket.empty(weekStart).copyWith(
            daysWithSymptom: {
              SymptomType.energy: 3,
              SymptomType.vomiting: 2,
              SymptomType.diarrhea: 1,
            },
            daysWithAnySymptoms: 3,
          ),
          // Rest are empty
          ...List.generate(
            6,
            (i) => SymptomBucket.empty(weekStart.add(Duration(days: i + 1))),
          ),
        ];

        final testContainer = ProviderContainer(
          overrides: [
            symptomsChartStateProvider.overrideWith(
              (ref) => SymptomsChartNotifier()
                ..state = SymptomsChartState(
                  focusedDate: weekStart,
                ),
            ),
            weeklySymptomBucketsProvider.overrideWith(
              (ref, weekStart) => buckets,
            ),
          ],
        );

        addTearDown(testContainer.dispose);

        final viewModel = testContainer.read(symptomsChartDataProvider);

        expect(viewModel, isNotNull);
        expect(viewModel!.visibleSymptoms.length, 3);
        expect(viewModel.hasOther, isFalse);
      });

      test(
        'should set hasOther to true when symptoms are not in visible list',
        () {
          final weekStart = AppDateUtils.startOfWeekMonday(
            DateTime(2025, 10, 6),
          );
          // Create buckets with 6 symptoms, but only 5 will be visible
          final buckets = [
            SymptomBucket.empty(weekStart).copyWith(
              daysWithSymptom: {
                SymptomType.energy: 10,
                SymptomType.suppressedAppetite: 9,
                SymptomType.vomiting: 8,
                SymptomType.injectionSiteReaction: 7,
                SymptomType.constipation: 6,
                SymptomType.diarrhea: 5, // This will be in Other
              },
              daysWithAnySymptoms: 10,
            ),
            // Rest are empty
            ...List.generate(
              6,
              (i) => SymptomBucket.empty(weekStart.add(Duration(days: i + 1))),
            ),
          ];

          final testContainer = ProviderContainer(
            overrides: [
              symptomsChartStateProvider.overrideWith(
                (ref) => SymptomsChartNotifier()
                  ..state = SymptomsChartState(
                    focusedDate: weekStart,
                  ),
              ),
              weeklySymptomBucketsProvider.overrideWith(
                (ref, weekStart) => buckets,
              ),
            ],
          );

          addTearDown(testContainer.dispose);

          final viewModel = testContainer.read(symptomsChartDataProvider);

          expect(viewModel, isNotNull);
          expect(viewModel!.visibleSymptoms.length, 5);
          expect(
            viewModel.visibleSymptoms,
            isNot(contains(SymptomType.diarrhea)),
          );
          expect(viewModel.hasOther, isTrue);
        },
      );
    });

    group('SymptomsChartViewModel', () {
      test('should have correct equality and hashCode', () {
        final buckets1 = [
          SymptomBucket.empty(DateTime(2025, 10)).copyWith(
            daysWithSymptom: {SymptomType.energy: 1},
            daysWithAnySymptoms: 1,
          ),
        ];
        final buckets2 = [
          SymptomBucket.empty(DateTime(2025, 10)).copyWith(
            daysWithSymptom: {SymptomType.energy: 1},
            daysWithAnySymptoms: 1,
          ),
        ];

        final viewModel1 = SymptomsChartViewModel(
          buckets: buckets1,
          visibleSymptoms: const [SymptomType.energy],
          hasOther: false,
        );
        final viewModel2 = SymptomsChartViewModel(
          buckets: buckets2,
          visibleSymptoms: const [SymptomType.energy],
          hasOther: false,
        );

        expect(viewModel1, equals(viewModel2));
        expect(viewModel1.hashCode, equals(viewModel2.hashCode));
      });

      test('should have different equality for different visible symptoms', () {
        final buckets = [
          SymptomBucket.empty(DateTime(2025, 10)).copyWith(
            daysWithSymptom: {SymptomType.energy: 1},
            daysWithAnySymptoms: 1,
          ),
        ];

        final viewModel1 = SymptomsChartViewModel(
          buckets: buckets,
          visibleSymptoms: const [SymptomType.energy],
          hasOther: false,
        );
        final viewModel2 = SymptomsChartViewModel(
          buckets: buckets,
          visibleSymptoms: const [SymptomType.vomiting],
          hasOther: false,
        );

        expect(viewModel1, isNot(equals(viewModel2)));
      });
    });
  });
}
