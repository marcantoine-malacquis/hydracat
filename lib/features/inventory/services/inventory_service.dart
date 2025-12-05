import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/features/inventory/models/fluid_inventory.dart';
import 'package:hydracat/features/inventory/models/inventory_calculations.dart';
import 'package:hydracat/features/notifications/services/reminder_plugin.dart';
import 'package:hydracat/features/notifications/utils/notification_id.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service layer for fluid inventory operations.
class InventoryService {
  /// Creates an InventoryService with optional injected dependencies.
  InventoryService({
    FirebaseFirestore? firestore,
    ReminderPlugin? reminderPlugin,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _reminderPlugin = reminderPlugin ?? ReminderPlugin();

  final FirebaseFirestore _firestore;
  final ReminderPlugin _reminderPlugin;

  /// Watch the main inventory document for a user.
  Stream<FluidInventory?> watchInventory(String userId) {
    final ref = _getInventoryRef(userId);
    return ref.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        if (kDebugMode) {
          debugPrint(
            '[InventoryService] No inventory document exists for user $userId',
          );
        }
        return null;
      }

      try {
        final inventory = FluidInventory.fromJson(snapshot.data()!);
        if (kDebugMode) {
          debugPrint(
            '[InventoryService] Successfully loaded inventory: '
            '${inventory.remainingVolume}mL remaining',
          );
        }
        return inventory;
      } on Object catch (e, stack) {
        if (kDebugMode) {
          debugPrint('[InventoryService] ERROR parsing inventory: $e');
          debugPrint('[InventoryService] Stack: $stack');
          debugPrint('[InventoryService] Data: ${snapshot.data()}');
        }
        return null;
      }
    });
  }

  /// Create initial inventory and first refill entry in a single transaction.
  Future<void> createInventory({
    required String userId,
    required double volumeAdded,
    required int reminderSessionsLeft,
  }) async {
    final inventoryRef = _getInventoryRef(userId);
    final refillRef = _getRefillsCollectionRef(userId).doc();

    await _firestore.runTransaction((transaction) async {
      final timestamp = FieldValue.serverTimestamp();

      transaction
        ..set(inventoryRef, {
          'id': 'main',
          'remainingVolume': volumeAdded,
          'initialVolume': volumeAdded,
          'reminderSessionsLeft': reminderSessionsLeft,
          'lastRefillDate': timestamp,
          'refillCount': 1,
          'inventoryEnabledAt': timestamp,
          'lastThresholdNotificationSentAt': null,
          'createdAt': timestamp,
          'updatedAt': timestamp,
        })
        ..set(refillRef, {
          'id': refillRef.id,
          'volumeAdded': volumeAdded,
          'totalAfterRefill': volumeAdded,
          'isReset': true,
          'reminderSessionsLeft': reminderSessionsLeft,
          'refillDate': timestamp,
          'createdAt': timestamp,
          'updatedAt': timestamp,
        });
    });

    if (kDebugMode) {
      debugPrint('[InventoryService] Inventory created: +$volumeAdded mL');
    }
  }

  /// Add a refill to existing inventory using a transaction for freshness.
  Future<void> addRefill({
    required String userId,
    required double volumeAdded,
    required int reminderSessionsLeft,
    required bool isReset,
  }) async {
    final inventoryRef = _getInventoryRef(userId);
    final refillRef = _getRefillsCollectionRef(userId).doc();

    await _firestore.runTransaction((transaction) async {
      final inventorySnap = await transaction.get(inventoryRef);
      if (!inventorySnap.exists || inventorySnap.data() == null) {
        throw Exception('Inventory not found');
      }

      final currentVolume = (inventorySnap.data()!['remainingVolume'] as num)
          .toDouble();
      final newTotal = isReset ? volumeAdded : currentVolume + volumeAdded;
      final timestamp = FieldValue.serverTimestamp();

      transaction
        ..update(inventoryRef, {
          'remainingVolume': newTotal,
          'initialVolume': newTotal,
          'reminderSessionsLeft': reminderSessionsLeft,
          'lastRefillDate': timestamp,
          'refillCount': FieldValue.increment(1),
          'lastThresholdNotificationSentAt': null,
          'updatedAt': timestamp,
        })
        ..set(refillRef, {
          'id': refillRef.id,
          'volumeAdded': volumeAdded,
          'totalAfterRefill': newTotal,
          'isReset': isReset,
          'reminderSessionsLeft': reminderSessionsLeft,
          'refillDate': timestamp,
          'createdAt': timestamp,
          'updatedAt': timestamp,
        });
    });

    if (kDebugMode) {
      debugPrint(
        '[InventoryService] Refill added: +$volumeAdded mL '
        '(reset: $isReset)',
      );
    }
  }

  /// Manually adjust inventory volume (tap-to-edit).
  ///
  /// If [averageVolumePerSession] is provided and the new volume rises above
  /// the computed threshold, the notification flag is cleared to re-arm alerts.
  Future<void> updateVolume({
    required String userId,
    required FluidInventory inventory,
    required double newVolume,
    double? averageVolumePerSession,
  }) async {
    final inventoryRef = _getInventoryRef(userId);
    final updates = <String, dynamic>{
      'remainingVolume': newVolume,
      'initialVolume': math.max(inventory.initialVolume, newVolume),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (averageVolumePerSession != null) {
      final thresholdVolume =
          inventory.reminderSessionsLeft * averageVolumePerSession;
      if (newVolume >= thresholdVolume) {
        updates['lastThresholdNotificationSentAt'] = null;
      }
    }

    await inventoryRef.update(updates);

    if (kDebugMode) {
      debugPrint(
        '[InventoryService] Volume adjusted to $newVolume mL '
        '(threshold cleared: '
        '${updates.containsKey('lastThresholdNotificationSentAt')})',
      );
    }
  }

  /// Compute metrics and send a low-inventory notification if needed.
  Future<void> checkThresholdAndNotify({
    required String userId,
    required String petId,
    required String petName,
    required FluidInventory inventory,
    required List<Schedule> schedules,
  }) async {
    final calculations = calculateMetrics(
      inventory: inventory,
      schedules: schedules,
    );

    if (calculations.averageVolumePerSession <= 0) {
      return; // No active schedules to derive threshold
    }

    final thresholdVolume =
        inventory.reminderSessionsLeft * calculations.averageVolumePerSession;
    final remaining = inventory.remainingVolume;
    final inventoryRef = _getInventoryRef(userId);

    // Clear flag if we are back above threshold
    if (inventory.lastThresholdNotificationSentAt != null &&
        remaining >= thresholdVolume) {
      await inventoryRef.update({
        'lastThresholdNotificationSentAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        debugPrint(
          '[InventoryService] Threshold flag cleared (above threshold)',
        );
      }
      return;
    }

    // If still above threshold, nothing to do
    if (remaining >= thresholdVolume) {
      return;
    }

    // Already notified and still below threshold, skip duplicate
    if (inventory.lastThresholdNotificationSentAt != null) {
      return;
    }

    await _scheduleInventoryNotification(
      userId: userId,
      petId: petId,
      petName: petName,
      inventory: inventory,
      calculations: calculations,
    );

    await inventoryRef.update({
      'lastThresholdNotificationSentAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (kDebugMode) {
      debugPrint('[InventoryService] Threshold notification recorded');
    }
  }

  /// Calculate inventory metrics based on current schedules.
  InventoryCalculations calculateMetrics({
    required FluidInventory inventory,
    required List<Schedule> schedules,
  }) {
    final fluidSchedules = schedules.where((schedule) {
      return schedule.isActive &&
          schedule.isFluidTherapy &&
          schedule.targetVolume != null &&
          schedule.reminderTimes.isNotEmpty;
    }).toList();

    var totalDailyVolume = 0.0;
    var totalSessionsPerDay = 0;

    for (final schedule in fluidSchedules) {
      final sessionsPerDay = schedule.reminderTimes.length;
      final volumePerDay = schedule.targetVolume! * sessionsPerDay;
      totalDailyVolume += volumePerDay;
      totalSessionsPerDay += sessionsPerDay;
    }

    final averageVolumePerSession = totalSessionsPerDay > 0
        ? totalDailyVolume / totalSessionsPerDay
        : 0.0;

    final safeRemaining = math.max(0, inventory.remainingVolume);

    final sessionsLeft = averageVolumePerSession > 0
        ? (safeRemaining / averageVolumePerSession).floor()
        : 0;

    final daysRemaining = totalDailyVolume > 0
        ? (safeRemaining / totalDailyVolume).floor()
        : 0;

    final estimatedEndDate = totalDailyVolume > 0
        ? DateTime.now().add(Duration(days: daysRemaining))
        : null;

    return InventoryCalculations(
      sessionsLeft: sessionsLeft,
      estimatedEndDate: estimatedEndDate,
      averageVolumePerSession: averageVolumePerSession,
      totalDailyVolume: totalDailyVolume,
    );
  }

  Future<void> _scheduleInventoryNotification({
    required String userId,
    required String petId,
    required String petName,
    required FluidInventory inventory,
    required InventoryCalculations calculations,
  }) async {
    try {
      final notificationId = generateInventoryNotificationId(
        userId: userId,
        petId: petId,
      );

      final remainingMl = inventory.remainingVolume.toInt();
      final sessionsLeft = calculations.sessionsLeft;

      const title = 'Fluid Inventory Low';
      final body =
          'Only $remainingMl mL left (~$sessionsLeft sessions) for $petName';

      final payload = jsonEncode({
        'type': 'inventory_low',
        'userId': userId,
        'petId': petId,
        'petName': petName,
        'remainingMl': remainingMl,
        'sessionsLeft': sessionsLeft,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final scheduledTime = tz.TZDateTime.now(
        tz.local,
      ).add(const Duration(seconds: 1));

      await _reminderPlugin.showZoned(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        channelId: ReminderPlugin.channelIdFluidReminders,
        payload: payload,
        groupId: 'inventory_alerts',
        threadIdentifier: 'inventory_alerts',
      );

      if (kDebugMode) {
        debugPrint(
          '[InventoryService] Low inventory notification scheduled: '
          '$remainingMl mL, $sessionsLeft sessions left for $petName',
        );
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[InventoryService] Failed to schedule notification: $e');
      }
    }
  }

  DocumentReference<Map<String, dynamic>> _getInventoryRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('fluidInventory')
        .doc('main');
  }

  CollectionReference<Map<String, dynamic>> _getRefillsCollectionRef(
    String userId,
  ) {
    return _getInventoryRef(userId).collection('refills');
  }
}
