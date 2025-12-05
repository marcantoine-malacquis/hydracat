import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/inventory/models/inventory_state.dart';
import 'package:hydracat/features/inventory/services/inventory_service.dart';
import 'package:hydracat/features/notifications/providers/notification_provider.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';

/// Provider for InventoryService singleton.
final Provider<InventoryService> inventoryServiceProvider =
    Provider<InventoryService>((ref) {
      final reminderPlugin = ref.watch(reminderPluginProvider);
      return InventoryService(reminderPlugin: reminderPlugin);
    });

/// Stream of inventory state for the current user (null when not enabled).
///
/// Uses autoDispose for proper memory management. Logging operations properly
/// handle async state via AsyncValue.when() instead of relying on cached data.
final AutoDisposeStreamProvider<InventoryState?> inventoryProvider =
    StreamProvider.autoDispose<InventoryState?>((ref) {
      final user = ref.watch(currentUserProvider);
      if (user == null) return Stream.value(null);

      final inventoryService = ref.watch(inventoryServiceProvider);
      final profileState = ref.watch(profileProvider);

      // Gather active fluid schedules (current implementation stores a single
      // fluid schedule).
      final schedules = <Schedule>[];
      if (profileState.fluidSchedule != null) {
        schedules.add(profileState.fluidSchedule!);
      }

      return inventoryService.watchInventory(user.id).map((inventory) {
        if (inventory == null) return null;

        final calculations = inventoryService.calculateMetrics(
          inventory: inventory,
          schedules: schedules,
        );

        final safeInitial = inventory.initialVolume <= 0
            ? 1.0
            : inventory.initialVolume;
        final remaining = inventory.remainingVolume;

        return InventoryState(
          inventory: inventory,
          sessionsLeft: calculations.sessionsLeft,
          estimatedEndDate: calculations.estimatedEndDate,
          displayVolume: math.max(0, remaining),
          displayPercentage: math.min(
            1,
            math.max(0, remaining / safeInitial),
          ),
          isNegative: remaining < 0,
          overageVolume: remaining < 0 ? remaining.abs() : 0,
        );
      });
    });

/// Convenience flag for whether inventory tracking is enabled.
final AutoDisposeProvider<bool> inventoryEnabledProvider =
    Provider.autoDispose<bool>((ref) {
      return ref.watch(inventoryProvider).valueOrNull != null;
    });
