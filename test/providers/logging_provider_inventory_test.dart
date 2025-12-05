import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/inventory/models/fluid_inventory.dart';
import 'package:hydracat/features/inventory/models/inventory_state.dart';
import 'package:hydracat/features/inventory/services/inventory_service.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/services/logging_service.dart';
import 'package:hydracat/features/logging/services/summary_cache_service.dart';
import 'package:hydracat/features/logging/services/summary_service.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/features/profile/services/pet_service.dart';
import 'package:hydracat/features/profile/services/schedule_service.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/connectivity_provider.dart';
import 'package:hydracat/providers/inventory_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoggingService extends Mock implements LoggingService {}

class _MockSummaryCacheService extends Mock implements SummaryCacheService {}

class _MockSummaryService extends Mock implements SummaryService {}

class _MockInventoryService extends Mock implements InventoryService {}

class _MockAnalyticsService extends Mock implements AnalyticsService {}

class _MockPetService extends Mock implements PetService {}

class _MockScheduleService extends Mock implements ScheduleService {}

class _TestProfileNotifier extends ProfileNotifier {
  _TestProfileNotifier(
    Ref ref,
    ProfileState initialState,
    PetService petService,
    ScheduleService scheduleService,
  ) : super(petService, scheduleService, ref) {
    state = initialState;
  }

  @override
  Future<bool> refreshPrimaryPet() async {
    return true;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(<Schedule>[]);
    registerFallbackValue(<FluidSession>[]);
    registerFallbackValue(
      FluidSession.create(
        petId: 'fallback',
        userId: 'fallback',
        dateTime: DateTime.now(),
        volumeGiven: 1,
        injectionSite: FluidLocation.shoulderBladeMiddle,
      ),
    );
  });

  group('LoggingNotifier - inventory deduction', () {
    late _MockLoggingService loggingService;
    late _MockSummaryCacheService cacheService;
    late _MockSummaryService summaryService;
    late _MockInventoryService inventoryService;
    late _MockAnalyticsService analyticsService;
    late AppUser user;
    late CatProfile pet;
    late FluidSession session;

    setUp(() {
      loggingService = _MockLoggingService();
      cacheService = _MockSummaryCacheService();
      summaryService = _MockSummaryService();
      inventoryService = _MockInventoryService();
      analyticsService = _MockAnalyticsService();

      user = const AppUser(
        id: 'user-123',
        emailVerified: true,
      );

      final now = DateTime.now();
      pet = CatProfile(
        id: 'pet-456',
        userId: user.id,
        name: 'Mochi',
        ageYears: 5,
        createdAt: now,
        updatedAt: now,
      );

      session = FluidSession.create(
        petId: pet.id,
        userId: user.id,
        dateTime: now,
        volumeGiven: 50,
        injectionSite: FluidLocation.shoulderBladeMiddle,
      );

      when(
        () => loggingService.logFluidSession(
          userId: any(named: 'userId'),
          petId: any(named: 'petId'),
          session: any(named: 'session'),
          todaysSchedules: any(named: 'todaysSchedules'),
          recentSessions: any(named: 'recentSessions'),
          updateInventory: any(named: 'updateInventory'),
          inventoryEnabledAt: any(named: 'inventoryEnabledAt'),
        ),
      ).thenAnswer((_) async => session.id);

      when(
        () => cacheService.getTodaySummary(any(), any()),
      ).thenAnswer((_) async => null);
      when(
        () => cacheService.updateCacheWithFluidSession(
          userId: any(named: 'userId'),
          petId: any(named: 'petId'),
          volumeGiven: any(named: 'volumeGiven'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => cacheService.removeCachedFluidSession(
          session: any(named: 'session'),
        ),
      ).thenAnswer((_) async {});
      when(() => summaryService.clearAllCaches()).thenAnswer((_) async {});
      when(
        () => inventoryService.checkThresholdAndNotify(
          userId: any(named: 'userId'),
          petId: any(named: 'petId'),
          petName: any(named: 'petName'),
          inventory: any(named: 'inventory'),
          schedules: any(named: 'schedules'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => analyticsService.trackSessionDeletion(
          treatmentType: any(named: 'treatmentType'),
          volume: any(named: 'volume'),
          inventoryAdjusted: any(named: 'inventoryAdjusted'),
        ),
      ).thenAnswer((_) async {});
    });

    ProviderContainer buildContainer({
      required Stream<InventoryState?> inventoryStream,
      required ProfileState profileState,
    }) {
      return ProviderContainer(
        overrides: [
          loggingProvider.overrideWith(
            (ref) => LoggingNotifier.test(
              loggingService,
              cacheService,
              ref,
            ),
          ),
          currentUserProvider.overrideWithValue(user),
          primaryPetProvider.overrideWithValue(pet),
          isConnectedProvider.overrideWith((ref) => true),
          inventoryProvider.overrideWith((ref) => inventoryStream),
          profileProvider.overrideWith(
            (ref) => _TestProfileNotifier(
              ref,
              profileState,
              _MockPetService(),
              _MockScheduleService(),
            ),
          ),
          summaryServiceProvider.overrideWithValue(summaryService),
          inventoryServiceProvider.overrideWithValue(inventoryService),
          analyticsServiceDirectProvider.overrideWithValue(analyticsService),
        ],
      );
    }

    test(
      'waits for inventory load and passes deduction flags',
      () async {
        final controller = StreamController<InventoryState?>();
        final activation = DateTime.now().subtract(const Duration(hours: 1));
        final inventory = FluidInventory(
          id: 'main',
          remainingVolume: 2000,
          initialVolume: 2000,
          reminderSessionsLeft: 10,
          lastRefillDate: activation,
          refillCount: 1,
          inventoryEnabledAt: activation,
          createdAt: activation,
          updatedAt: activation,
        );
        final inventoryState = InventoryState(
          inventory: inventory,
          sessionsLeft: 10,
          estimatedEndDate: null,
          displayVolume: inventory.remainingVolume,
          displayPercentage: 1,
          isNegative: false,
          overageVolume: 0,
        );

        final container = buildContainer(
          inventoryStream: controller.stream,
          profileState: ProfileState(primaryPet: pet),
        );

        // Emit inventory after logFluidSession starts to simulate loading.
        await Future.microtask(() => controller.add(inventoryState));

        final result = await container
            .read(loggingProvider.notifier)
            .logFluidSession(session: session);

        expect(result, isTrue);
        verify(
          () => loggingService.logFluidSession(
            userId: user.id,
            petId: pet.id,
            session: any(named: 'session'),
            todaysSchedules: any(named: 'todaysSchedules'),
            recentSessions: any(named: 'recentSessions'),
            updateInventory: true,
            inventoryEnabledAt: activation,
          ),
        ).called(1);
      },
    );

    test(
      'skips deduction when inventory is disabled/null',
      () async {
        final container = buildContainer(
          inventoryStream: Stream<InventoryState?>.value(null),
          profileState: ProfileState(primaryPet: pet),
        );

        final result = await container
            .read(loggingProvider.notifier)
            .logFluidSession(session: session);

        expect(result, isTrue);
        verify(
          () => loggingService.logFluidSession(
            userId: user.id,
            petId: pet.id,
            session: any(named: 'session'),
            todaysSchedules: any(named: 'todaysSchedules'),
            recentSessions: any(named: 'recentSessions'),
          ),
        ).called(1);
      },
    );

    test(
      'passes inventoryEnabledAt for gating older sessions',
      () async {
        final activation = DateTime.now();
        final inventory = FluidInventory(
          id: 'main',
          remainingVolume: 1500,
          initialVolume: 1500,
          reminderSessionsLeft: 8,
          lastRefillDate: activation,
          refillCount: 1,
          inventoryEnabledAt: activation,
          createdAt: activation,
          updatedAt: activation,
        );
        final inventoryState = InventoryState(
          inventory: inventory,
          sessionsLeft: 8,
          estimatedEndDate: null,
          displayVolume: inventory.remainingVolume,
          displayPercentage: 1,
          isNegative: false,
          overageVolume: 0,
        );

        // Use a session before activation to ensure the timestamp is forwarded.
        final oldSession = session.copyWith(
          dateTime: activation.subtract(const Duration(days: 1)),
        );

        final container = buildContainer(
          inventoryStream: Stream<InventoryState?>.value(inventoryState),
          profileState: ProfileState(primaryPet: pet),
        );

        final result = await container
            .read(loggingProvider.notifier)
            .logFluidSession(session: oldSession);

        expect(result, isTrue);
        verify(
          () => loggingService.logFluidSession(
            userId: user.id,
            petId: pet.id,
            session: any(named: 'session'),
            todaysSchedules: any(named: 'todaysSchedules'),
            recentSessions: any(named: 'recentSessions'),
            updateInventory: true,
            inventoryEnabledAt: activation,
          ),
        ).called(1);
      },
    );

    test(
      'waits for inventory load before restoring on delete',
      () async {
        final controller = StreamController<InventoryState?>();
        addTearDown(controller.close);

        final activation = DateTime.now().subtract(const Duration(hours: 1));
        final inventory = FluidInventory(
          id: 'main',
          remainingVolume: 1000,
          initialVolume: 1000,
          reminderSessionsLeft: 5,
          lastRefillDate: activation,
          refillCount: 1,
          inventoryEnabledAt: activation,
          createdAt: activation,
          updatedAt: activation,
        );
        final inventoryState = InventoryState(
          inventory: inventory,
          sessionsLeft: 5,
          estimatedEndDate: null,
          displayVolume: inventory.remainingVolume,
          displayPercentage: 1,
          isNegative: false,
          overageVolume: 0,
        );

        when(
          () => loggingService.deleteFluidSession(
            userId: any(named: 'userId'),
            petId: any(named: 'petId'),
            session: any(named: 'session'),
            updateInventory: any(named: 'updateInventory'),
            inventoryEnabledAt: any(named: 'inventoryEnabledAt'),
          ),
        ).thenAnswer((_) async {});

        final container = buildContainer(
          inventoryStream: controller.stream,
          profileState: ProfileState(primaryPet: pet),
        );

        final deleteFuture = container
            .read(loggingProvider.notifier)
            .deleteFluidSession(session: session);

        await Future.microtask(() => controller.add(inventoryState));

        final result = await deleteFuture;

        expect(result, isTrue);
        verify(
          () => loggingService.deleteFluidSession(
            userId: user.id,
            petId: pet.id,
            session: any(named: 'session'),
            updateInventory: true,
            inventoryEnabledAt: activation,
          ),
        ).called(1);
      },
    );
  });
}
