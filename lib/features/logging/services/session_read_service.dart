import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/logging/services/logging_service.dart';

/// Read-only service for querying treatment sessions by date.
///
/// Optimized for cost and offline cache usage. Does not modify sessions.
/// For write operations, use [LoggingService].
///
/// ## Cost Characteristics
///
/// - First view of a day: Up to 2 network reads (medication + fluid queries)
/// - Subsequent views: 0 reads (served from Firestore offline cache)
/// - Each query limited to 50 results to prevent large reads
///
/// ## Usage
///
/// ```dart
/// final service = ref.read(sessionReadServiceProvider);
/// final date = DateTime(2025, 10, 15);
///
/// // Get medication sessions for a specific date
/// final medSessions = await service.getMedicationSessionsForDate(
///   userId: 'user-id',
///   petId: 'pet-id',
///   date: date,
/// );
///
/// // Get both session types in parallel
/// final (meds, fluids) = await service.getAllSessionsForDate(
///   userId: 'user-id',
///   petId: 'pet-id',
///   date: date,
/// );
/// ```
///
/// ## Separation from LoggingService
///
/// This service is separate from [LoggingService] because:
/// - LoggingService handles complex write operations with validation/batching
/// - Read operations have different patterns (queries vs batch writes)
/// - Separation of concerns keeps both services focused and testable
class SessionReadService {
  /// Creates a session read service
  const SessionReadService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Gets medication sessions for a specific date.
  ///
  /// Returns all medication sessions where dateTime falls within the
  /// specified [date] (between 00:00:00 and 23:59:59).
  ///
  /// Results are ordered by dateTime descending (most recent first).
  /// The query is limited to [limit] results to prevent large reads.
  ///
  /// ## Cost
  ///
  /// - First call: 1 network read (or fewer if no sessions exist)
  /// - Subsequent calls: 0 reads (served from Firestore offline cache)
  ///
  /// ## Parameters
  ///
  /// - [userId]: The user ID who owns the sessions
  /// - [petId]: The pet ID for which to fetch sessions
  /// - [date]: The date to query (time portion is ignored)
  /// - [limit]: Maximum number of sessions to return (default: 50)
  ///
  /// ## Returns
  ///
  /// A list of [MedicationSession] objects ordered by dateTime descending.
  /// Returns an empty list if no sessions are found for the date.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final sessions = await service.getMedicationSessionsForDate(
  ///   userId: 'user-123',
  ///   petId: 'pet-456',
  ///   date: DateTime(2025, 10, 15),
  ///   limit: 50,
  /// );
  /// ```
  Future<List<MedicationSession>> getMedicationSessionsForDate({
    required String userId,
    required String petId,
    required DateTime date,
    int limit = 50,
  }) async {
    final startOfDay = AppDateUtils.startOfDay(date);
    final endOfDay = AppDateUtils.endOfDay(date);

    final query = _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('medicationSessions')
        .where(
          'dateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('dateTime', descending: true)
        .limit(limit);

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => MedicationSession.fromJson(doc.data()))
        .toList();
  }

  /// Gets fluid sessions for a specific date.
  ///
  /// Returns all fluid sessions where dateTime falls within the
  /// specified [date] (between 00:00:00 and 23:59:59).
  ///
  /// Results are ordered by dateTime descending (most recent first).
  /// The query is limited to [limit] results to prevent large reads.
  ///
  /// ## Cost
  ///
  /// - First call: 1 network read (or fewer if no sessions exist)
  /// - Subsequent calls: 0 reads (served from Firestore offline cache)
  ///
  /// ## Parameters
  ///
  /// - [userId]: The user ID who owns the sessions
  /// - [petId]: The pet ID for which to fetch sessions
  /// - [date]: The date to query (time portion is ignored)
  /// - [limit]: Maximum number of sessions to return (default: 50)
  ///
  /// ## Returns
  ///
  /// A list of [FluidSession] objects ordered by dateTime descending.
  /// Returns an empty list if no sessions are found for the date.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final sessions = await service.getFluidSessionsForDate(
  ///   userId: 'user-123',
  ///   petId: 'pet-456',
  ///   date: DateTime(2025, 10, 15),
  ///   limit: 50,
  /// );
  /// ```
  Future<List<FluidSession>> getFluidSessionsForDate({
    required String userId,
    required String petId,
    required DateTime date,
    int limit = 50,
  }) async {
    final startOfDay = AppDateUtils.startOfDay(date);
    final endOfDay = AppDateUtils.endOfDay(date);

    final query = _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('fluidSessions')
        .where(
          'dateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('dateTime', descending: true)
        .limit(limit);

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => FluidSession.fromJson(doc.data()))
        .toList();
  }

  /// Gets both medication and fluid sessions for a date in parallel.
  ///
  /// This is more efficient than calling [getMedicationSessionsForDate] and
  /// [getFluidSessionsForDate] separately as it executes both queries
  /// simultaneously.
  ///
  /// Returns a record with (medicationSessions, fluidSessions).
  ///
  /// ## Cost
  ///
  /// - First call: Up to 2 network reads (one per query type)
  /// - Subsequent calls: 0 reads (both queries served from cache)
  ///
  /// ## Parameters
  ///
  /// - [userId]: The user ID who owns the sessions
  /// - [petId]: The pet ID for which to fetch sessions
  /// - [date]: The date to query (time portion is ignored)
  /// - [limit]: Maximum number of sessions per type (default: 50)
  ///
  /// ## Returns
  ///
  /// A record `(List<MedicationSession>, List<FluidSession>)` where:
  /// - First element is the list of medication sessions
  /// - Second element is the list of fluid sessions
  /// Both lists are ordered by dateTime descending.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final (medSessions, fluidSessions) =
  ///     await service.getAllSessionsForDate(
  ///   userId: 'user-123',
  ///   petId: 'pet-456',
  ///   date: DateTime(2025, 10, 15),
  /// );
  ///
  /// print('Found ${medSessions.length} medication sessions');
  /// print('Found ${fluidSessions.length} fluid sessions');
  /// ```
  Future<(List<MedicationSession>, List<FluidSession>)> getAllSessionsForDate({
    required String userId,
    required String petId,
    required DateTime date,
    int limit = 50,
  }) async {
    final results = await Future.wait([
      getMedicationSessionsForDate(
        userId: userId,
        petId: petId,
        date: date,
        limit: limit,
      ),
      getFluidSessionsForDate(
        userId: userId,
        petId: petId,
        date: date,
        limit: limit,
      ),
    ]);

    return (
      results[0] as List<MedicationSession>,
      results[1] as List<FluidSession>,
    );
  }
}

/// Provider for [SessionReadService].
///
/// Provides read-only access to treatment sessions.
/// Shares the same Firestore instance as other services.
///
/// ## Usage
///
/// ```dart
/// // In a ConsumerWidget or ConsumerStatefulWidget
/// final service = ref.read(sessionReadServiceProvider);
/// final sessions = await service.getMedicationSessionsForDate(
///   userId: user.id,
///   petId: pet.id,
///   date: selectedDate,
/// );
/// ```
final sessionReadServiceProvider = Provider<SessionReadService>((ref) {
  return SessionReadService(FirebaseFirestore.instance);
});
