import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages profile-related caching operations
///
/// This handler is responsible for:
/// - Caching primary pet ID for background FCM handler access
/// - Handling cache failures silently (non-critical operations)
class ProfileCacheManager {
  /// Caches primary pet ID in SharedPreferences for background FCM handler
  ///
  /// This allows the FCM background handler to access the pet ID even when
  /// the app is not running. Failures are logged but not thrown as this is
  /// a non-critical operation.
  ///
  /// Parameters:
  /// - [petId]: The pet ID to cache
  ///
  /// Returns: void (all errors logged silently)
  Future<void> cachePrimaryPetId(String petId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_primary_pet_id', petId);
      if (kDebugMode) {
        debugPrint(
          '[ProfileCacheManager] Cached primary pet ID for background access',
        );
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[ProfileCacheManager] Failed to cache pet ID: $e');
      }
      // Non-critical, don't throw
    }
  }
}
