import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/features/profile/exceptions/profile_exceptions.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/shared/models/schedule_dto.dart';

/// Service for managing treatment schedules in Firestore
class ScheduleService {
  /// Creates a [ScheduleService] instance
  const ScheduleService();

  /// Firestore instance
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Collection reference for schedules under a specific pet
  CollectionReference<Map<String, dynamic>> _schedulesCollection(
    String userId,
    String petId,
  ) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('schedules');
  }

  /// Creates a new schedule for a pet
  ///
  /// Returns the ID of the created schedule document
  Future<String> createSchedule({
    required String userId,
    required String petId,
    required ScheduleDto scheduleDto,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleService] Creating schedule for pet $petId',
        );
      }

      // Generate ID client-side to avoid two-write pattern
      final docRef = _schedulesCollection(userId, petId).doc();

      // Convert DTO to JSON and add ID and server timestamps
      final scheduleData = scheduleDto.toJson();
      final dataWithId = {
        ...scheduleData,
        'id': docRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Single write operation
      await docRef.set(dataWithId);

      if (kDebugMode) {
        debugPrint(
          '[ScheduleService] Successfully created schedule ${docRef.id}',
        );
      }

      return docRef.id;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[ScheduleService] Firebase error creating schedule: $e');
      }
      throw PetServiceException('Failed to create schedule: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScheduleService] Unexpected error creating schedule: $e');
      }
      throw PetServiceException('Failed to create schedule: $e');
    }
  }

  /// Creates multiple schedules in a single atomic batch operation
  ///
  /// This method is optimized for creating multiple schedules at once,
  /// reducing network round-trips and Firebase write costs.
  /// All schedules are created atomically - either all succeed or all fail.
  ///
  /// Returns a list of schedule IDs in the same order as the input data
  Future<List<String>> createSchedulesBatch({
    required String userId,
    required String petId,
    required List<ScheduleDto> scheduleDtos,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleService] Creating ${scheduleDtos.length} schedules '
          'in batch for pet $petId',
        );
      }

      // Create a batch write
      final batch = firestore.batch();
      final scheduleIds = <String>[];

      // Add all schedules to the batch
      for (final scheduleDto in scheduleDtos) {
        // Generate ID client-side
        final docRef = _schedulesCollection(userId, petId).doc();

        // Convert DTO to JSON and add ID and server timestamps
        final scheduleData = scheduleDto.toJson();
        final dataWithId = {
          ...scheduleData,
          'id': docRef.id,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Add to batch
        batch.set(docRef, dataWithId);
        scheduleIds.add(docRef.id);
      }

      // Commit all writes in a single network round-trip
      await batch.commit();

      if (kDebugMode) {
        debugPrint(
          '[ScheduleService] Successfully created ${scheduleIds.length} '
          'schedules in batch for pet $petId',
        );
      }

      return scheduleIds;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleService] Firebase error creating schedules batch: $e',
        );
      }
      throw PetServiceException(
        'Failed to create schedules batch: ${e.message}',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleService] Unexpected error creating schedules batch: $e',
        );
      }
      throw PetServiceException('Failed to create schedules batch: $e');
    }
  }

  /// Updates an existing schedule
  Future<void> updateSchedule({
    required String userId,
    required String petId,
    required String scheduleId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleService] Updating schedule $scheduleId for pet $petId',
        );
      }

      // Add updatedAt timestamp
      final updateData = {
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _schedulesCollection(userId, petId)
          .doc(scheduleId)
          .update(updateData);

      if (kDebugMode) {
        debugPrint(
          '[ScheduleService] Successfully updated schedule $scheduleId',
        );
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[ScheduleService] Firebase error updating schedule: $e');
      }
      throw PetServiceException('Failed to update schedule: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScheduleService] Unexpected error updating schedule: $e');
      }
      throw PetServiceException('Failed to update schedule: $e');
    }
  }

  /// Gets a specific schedule by ID
  Future<Schedule?> getSchedule({
    required String userId,
    required String petId,
    required String scheduleId,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleService] Getting schedule $scheduleId for pet $petId',
        );
      }

      final doc = await _schedulesCollection(userId, petId)
          .doc(scheduleId)
          .get();

      if (!doc.exists || doc.data() == null) {
        if (kDebugMode) {
          debugPrint('[ScheduleService] Schedule $scheduleId not found');
        }
        return null;
      }

      final scheduleData = doc.data()!;
      // Ensure the document has an ID field
      scheduleData['id'] = doc.id;

      return Schedule.fromJson(scheduleData);
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[ScheduleService] Firebase error getting schedule: $e');
      }
      throw PetServiceException('Failed to get schedule: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScheduleService] Unexpected error getting schedule: $e');
      }
      throw PetServiceException('Failed to get schedule: $e');
    }
  }

  /// Gets all schedules for a pet, optionally filtered by treatment type
  Future<List<Schedule>> getSchedules({
    required String userId,
    required String petId,
    TreatmentType? treatmentType,
    bool activeOnly = true,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleService] Getting schedules for pet $petId '
          '(type: $treatmentType, activeOnly: $activeOnly)',
        );
      }

      // Build query with where clauses only
      // (no orderBy to avoid composite index requirement)
      Query<Map<String, dynamic>> query = _schedulesCollection(userId, petId);

      // Filter by treatment type if specified
      if (treatmentType != null) {
        query = query.where('treatmentType', isEqualTo: treatmentType.name);
      }

      // Filter by active status if specified
      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }

      final querySnapshot = await query.get();

      final schedules = <Schedule>[];
      for (final doc in querySnapshot.docs) {
        try {
          final scheduleData = doc.data();
          // Ensure the document has an ID field
          scheduleData['id'] = doc.id;
          schedules.add(Schedule.fromJson(scheduleData));
        } on Exception catch (e) {
          if (kDebugMode) {
            debugPrint(
              '[ScheduleService] Error parsing schedule ${doc.id}: $e',
            );
          }
          // Continue processing other schedules
        }
      }

      // Sort schedules by creation date (newest first) in memory
      schedules.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (kDebugMode) {
        debugPrint(
          '[ScheduleService] Successfully retrieved ${schedules.length} '
          'schedules for pet $petId',
        );
      }

      return schedules;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[ScheduleService] Firebase error getting schedules: $e');
      }
      throw PetServiceException('Failed to get schedules: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScheduleService] Unexpected error getting schedules: $e');
      }
      throw PetServiceException('Failed to get schedules: $e');
    }
  }

  /// Gets the active fluid therapy schedule for a pet
  Future<Schedule?> getFluidSchedule({
    required String userId,
    required String petId,
  }) async {
    final schedules = await getSchedules(
      userId: userId,
      petId: petId,
      treatmentType: TreatmentType.fluid,
    );

    // Return the first active fluid schedule (should only be one)
    return schedules.isNotEmpty ? schedules.first : null;
  }

  /// Gets all active medication schedules for a pet
  Future<List<Schedule>> getMedicationSchedules({
    required String userId,
    required String petId,
  }) async {
    final schedules = await getSchedules(
      userId: userId,
      petId: petId,
      treatmentType: TreatmentType.medication,
    );

    return schedules;
  }

  /// Deactivates a schedule (soft delete)
  Future<void> deactivateSchedule({
    required String userId,
    required String petId,
    required String scheduleId,
  }) async {
    await updateSchedule(
      userId: userId,
      petId: petId,
      scheduleId: scheduleId,
      updates: {'isActive': false},
    );
  }

  /// Permanently deletes a schedule
  Future<void> deleteSchedule({
    required String userId,
    required String petId,
    required String scheduleId,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[ScheduleService] Deleting schedule $scheduleId for pet $petId',
        );
      }

      await _schedulesCollection(userId, petId)
          .doc(scheduleId)
          .delete();

      if (kDebugMode) {
        debugPrint(
          '[ScheduleService] Successfully deleted schedule $scheduleId',
        );
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[ScheduleService] Firebase error deleting schedule: $e');
      }
      throw PetServiceException('Failed to delete schedule: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScheduleService] Unexpected error deleting schedule: $e');
      }
      throw PetServiceException('Failed to delete schedule: $e');
    }
  }
}
