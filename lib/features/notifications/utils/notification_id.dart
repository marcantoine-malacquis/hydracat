import 'dart:convert';

import 'package:hydracat/features/notifications/models/scheduled_notification_entry.dart';

/// Utility for generating deterministic notification IDs using FNV-1a hashing.
///
/// **Why deterministic IDs?**
/// - Enables idempotent scheduling (safe to retry operations)
/// - Allows cancellation by parameters without storing mapping
/// - Supports reconciliation after app restart/crash
///
/// **Android constraint**: Notification IDs must be 31-bit positive integers
/// (max value: 2,147,483,647). This utility generates IDs in this range by
/// applying a bit mask to the hash result.
///
/// **Collision probability**: With FNV-1a 32-bit hash masked to 31 bits,
/// the probability of collision is approximately 1 in 2 billion for random
/// inputs. In practice, with realistic app usage (thousands of notifications),
/// collisions are extremely unlikely.
///
/// **Algorithm**: FNV-1a (Fowler-Noll-Vo hash, variant 1a)
/// - Fast, simple, non-cryptographic hash
/// - Good distribution properties
/// - Deterministic (same inputs always produce same output)
/// - Widely used for hash tables and checksums
/// - Already used in NotificationIndexStore for data integrity
///
/// Example usage:
/// ```dart
/// final id = generateNotificationId(
///   userId: 'user_abc123',
///   petId: 'pet_xyz789',
///   scheduleId: 'sched_medication_001',
///   timeSlot: '08:00',
///   kind: 'initial',
/// );
///
/// // Use with ScheduledNotificationEntry
/// final entry = ScheduledNotificationEntry(
///   notificationId: id,
///   scheduleId: 'sched_medication_001',
///   treatmentType: 'medication',
///   timeSlotISO: '08:00',
///   kind: 'initial',
/// );
/// ```

/// Generates a deterministic notification ID from input parameters.
///
/// Creates a stable 31-bit positive integer by hashing the concatenation of
/// all input parameters using FNV-1a algorithm.
///
/// **Parameters**:
/// - [userId]: User ID (must be non-empty)
/// - [petId]: Pet ID (must be non-empty)
/// - [scheduleId]: Schedule ID (must be non-empty)
/// - [timeSlot]: Time in "HH:mm" format (00:00 to 23:59)
/// - [kind]: Notification kind ("initial", "followup", or "snooze")
///
/// **Returns**: 31-bit positive integer suitable for Android/iOS notifications
///
/// **Throws**:
/// - [ArgumentError] if any parameter is empty
/// - [ArgumentError] if [timeSlot] is not in valid "HH:mm" format
/// - [ArgumentError] if [kind] is not a valid notification kind
///
/// **Deterministic behavior**: Calling this function multiple times with the
/// same parameters will always produce the same ID. This is critical for
/// idempotent scheduling operations.
///
/// Example:
/// ```dart
/// // Same inputs always produce same ID
/// final id1 = generateNotificationId(
///   userId: 'user1',
///   petId: 'pet1',
///   scheduleId: 'sched1',
///   timeSlot: '08:00',
///   kind: 'initial',
/// );
/// final id2 = generateNotificationId(
///   userId: 'user1',
///   petId: 'pet1',
///   scheduleId: 'sched1',
///   timeSlot: '08:00',
///   kind: 'initial',
/// );
/// assert(id1 == id2); // Always true
///
/// // Different inputs produce different IDs
/// final id3 = generateNotificationId(
///   userId: 'user1',
///   petId: 'pet1',
///   scheduleId: 'sched1',
///   timeSlot: '08:00',
///   kind: 'followup', // Different kind
/// );
/// assert(id1 != id3); // Almost always true (collision probability ~1 in 2B)
/// ```
int generateNotificationId({
  required String userId,
  required String petId,
  required String scheduleId,
  required String timeSlot,
  required String kind,
}) {
  // Validate non-empty parameters
  if (userId.isEmpty) {
    throw ArgumentError('userId must not be empty');
  }
  if (petId.isEmpty) {
    throw ArgumentError('petId must not be empty');
  }
  if (scheduleId.isEmpty) {
    throw ArgumentError('scheduleId must not be empty');
  }
  if (timeSlot.isEmpty) {
    throw ArgumentError('timeSlot must not be empty');
  }
  if (kind.isEmpty) {
    throw ArgumentError('kind must not be empty');
  }

  // Validate timeSlot format using existing validation
  if (!ScheduledNotificationEntry.isValidTimeSlot(timeSlot)) {
    throw ArgumentError(
      'timeSlot must be in "HH:mm" format (00:00 to 23:59), got: "$timeSlot"',
    );
  }

  // Validate kind using existing validation
  if (!ScheduledNotificationEntry.isValidKind(kind)) {
    throw ArgumentError(
      'kind must be "initial", "followup", or "snooze", got: "$kind"',
    );
  }

  // Create composite string using pipe delimiter
  // Format: "userId|petId|scheduleId|timeSlot|kind"
  final composite = '$userId|$petId|$scheduleId|$timeSlot|$kind';

  // Compute FNV-1a hash
  final hash = _fnv1aHash32(composite);

  // Mask to 31 bits to ensure positive integer
  // Android notification IDs must be in range: 0 to 2,147,483,647
  // 0x7FFFFFFF = 0111 1111 1111 1111 1111 1111 1111 1111 (31 bits set)
  final notificationId = hash & 0x7FFFFFFF;

  return notificationId;
}

/// Computes FNV-1a hash (32-bit) for a given string.
///
/// FNV-1a (Fowler-Noll-Vo hash, variant 1a) is a simple, fast,
/// non-cryptographic hash function with good distribution properties.
///
/// **Algorithm**:
/// 1. Initialize hash with offset basis (2166136261)
/// 2. For each byte in input:
///    a. XOR hash with byte
///    b. Multiply hash by FNV prime (16777619)
/// 3. Return 32-bit unsigned hash
///
/// **References**:
/// - http://www.isthe.com/chongo/tech/comp/fnv/
/// - https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function
///
/// **Note**: This is the same algorithm used in NotificationIndexStore
/// for checksum computation and data integrity validation.
///
/// Returns: 32-bit unsigned integer hash value.
int _fnv1aHash32(String input) {
  // FNV-1a constants for 32-bit hash
  const fnvPrime = 16777619;
  const fnvOffsetBasis = 2166136261;

  var hash = fnvOffsetBasis;

  // Convert string to UTF-8 bytes and hash each byte
  final bytes = utf8.encode(input);
  for (final byte in bytes) {
    // XOR with byte (order matters for FNV-1a)
    hash ^= byte;
    // Multiply by FNV prime, keeping as 32-bit unsigned
    hash = (hash * fnvPrime) & 0xFFFFFFFF;
  }

  return hash;
}
