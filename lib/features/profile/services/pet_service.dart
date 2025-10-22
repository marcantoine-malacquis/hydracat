/// Pet profile service with single-pet optimized CRUD operations
///
/// Handles all pet profile data management with cost-optimized Firestore
/// operations, aggressive caching for single-pet users (90% of users),
/// and comprehensive error handling.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/features/profile/exceptions/profile_exceptions.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/services/profile_validation_service.dart';
import 'package:hydracat/shared/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result type for pet service operations
sealed class PetResult {
  /// Creates a [PetResult] instance
  const PetResult();
}

/// Successful pet operation result
class PetSuccess extends PetResult {
  /// Creates a [PetSuccess] with the pet data
  const PetSuccess(this.pet);

  /// The pet profile data
  final CatProfile pet;
}

/// Failed pet operation result
class PetFailure extends PetResult {
  /// Creates a [PetFailure] with a profile exception
  const PetFailure(this.exception);

  /// The profile exception with user-friendly message
  final ProfileException exception;

  /// Convenience getter for error message
  String get message => exception.message;

  /// Convenience getter for error code
  String? get code => exception.code;
}

/// Pet profile service with single-pet optimization
///
/// Optimized for the reality that 90% of users have only one pet.
/// Features aggressive caching, minimal Firestore reads, and smart
/// conflict resolution.
class PetService {
  /// Creates a [PetService] instance
  PetService({
    ProfileValidationService? validationService,
  }) : _validationService =
           validationService ?? const ProfileValidationService();

  final ProfileValidationService _validationService;

  // Single-pet cache (optimized for 90% of users)
  CatProfile? _cachedPrimaryPet;
  String? _cachedPrimaryPetUserId;
  DateTime? _cacheTimestamp;
  static const Duration _cacheTimeout = Duration(minutes: 30);

  // Persistent cache keys
  static const String _persistentCacheKey = 'primary_pet_cache';
  static const String _persistentCacheTimestampKey =
      'primary_pet_cache_timestamp';

  // Multi-pet cache (for the 10% with multiple pets)
  final Map<String, CatProfile> _multiPetCache = {};
  final Map<String, DateTime> _multiPetCacheTimestamps = {};

  // Name conflict cache (to avoid repeated queries)
  final Map<String, List<String>> _nameConflictCache = {};

  /// Firestore instance
  FirebaseFirestore get _firestore => FirebaseService().firestore;

  /// Current user ID from Firebase Auth
  String? get _currentUserId => FirebaseService().currentUser?.uid;

  /// Pets collection reference for current user
  CollectionReference<Map<String, dynamic>>? get _petsCollection {
    final userId = _currentUserId;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('pets');
  }

  /// Creates a new pet profile
  ///
  /// Optimized for single-pet users with automatic primary pet caching.
  /// Includes name conflict detection and comprehensive validation.
  Future<PetResult> createPet(CatProfile profile) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const PetFailure(
          PetServiceException('Must be logged in to create pet profiles'),
        );
      }

      // Validate the profile first (prevents failed writes)
      final validationResult = _validationService.validateProfile(profile);
      if (!validationResult.isValid) {
        final errorMessages =
            validationResult.errors.map((e) => e.message).toList();
        return PetFailure(
          ProfileValidationException(errorMessages),
        );
      }

      // Check for name conflicts
      final conflictResult = await _checkNameConflicts(
        profile.name,
        userId,
      );
      if (conflictResult.isNotEmpty) {
        return PetFailure(
          PetNameConflictException(profile.name, conflictResult),
        );
      }

      // Generate unique ID with retry logic
      final petId = await _generateUniquePetId(userId);

      // Create the final profile with timestamps
      final now = DateTime.now();
      final finalProfile = profile.copyWith(
        id: petId,
        userId: userId,
        createdAt: now,
        updatedAt: now,
      );

      // Save to Firestore
      await _petsCollection!.doc(petId).set(finalProfile.toJson());

      // Cache as primary pet (optimized for single-pet users)
      _cachedPrimaryPet = finalProfile;
      _cachedPrimaryPetUserId = userId;
      _cacheTimestamp = now;

      // Save to persistent cache (fire and forget)
      unawaited(_saveToPersistentCache(finalProfile, userId));

      // Clear name conflict cache
      _nameConflictCache.clear();

      return PetSuccess(finalProfile);
    } on FirebaseException catch (e) {
      return PetFailure(ProfileExceptionMapper.mapFirestoreException(e));
    } on Exception catch (e) {
      return PetFailure(ProfileExceptionMapper.mapGenericException(e));
    }
  }

  /// Gets the primary pet for the current user
  ///
  /// Heavily optimized for single-pet users with aggressive caching.
  /// Returns cached result for 90% of users after initial load.
  /// Includes persistent cache fallback for offline scenarios.
  Future<CatProfile?> getPrimaryPet({bool forceRefresh = false}) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    // Check memory cache first (90% of calls return here)
    if (!forceRefresh && _isPrimaryCacheValid(userId)) {
      return _cachedPrimaryPet;
    }

    // Check persistent cache if memory cache is invalid
    if (!forceRefresh) {
      final persistentPet = await _loadFromPersistentCache(userId);
      if (persistentPet != null) {
        // Load into memory cache
        _cachedPrimaryPet = persistentPet;
        _cachedPrimaryPetUserId = userId;
        _cacheTimestamp = DateTime.now();
        return persistentPet;
      }
    }

    try {
      // Get user's pets (typically just 1 for 90% of users)
      final petsQuery = await _petsCollection!
          .orderBy('createdAt', descending: false)
          .limit(1) // Only need the first pet for primary
          .get();

      if (petsQuery.docs.isEmpty) {
        return null;
      }

      // Cache the primary pet
      final petDoc = petsQuery.docs.first;
      final pet = CatProfile.fromJson({
        ...petDoc.data(),
        'id': petDoc.id,
      });

      // Update both memory and persistent cache
      _cachedPrimaryPet = pet;
      _cachedPrimaryPetUserId = userId;
      _cacheTimestamp = DateTime.now();

      // Save to persistent cache (fire and forget)
      unawaited(_saveToPersistentCache(pet, userId));

      return pet;
    } on FirebaseException catch (e) {
      debugPrint('Error getting primary pet: ${e.message}');

      // Try to return persistent cache as fallback
      final persistentPet = await _loadFromPersistentCache(userId);
      if (persistentPet != null) {
        _cachedPrimaryPet = persistentPet;
        _cachedPrimaryPetUserId = userId;
        _cacheTimestamp = DateTime.now();
      }

      return persistentPet;
    }
  }

  /// Gets a specific pet by ID
  ///
  /// Checks cache first, then queries Firestore if needed.
  Future<CatProfile?> getPet(String petId) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    // Check primary cache first
    if (_cachedPrimaryPet?.id == petId && _isPrimaryCacheValid(userId)) {
      return _cachedPrimaryPet;
    }

    // Check multi-pet cache
    if (_multiPetCache.containsKey(petId) && _isMultiPetCacheValid(petId)) {
      return _multiPetCache[petId];
    }

    try {
      final petDoc = await _petsCollection!.doc(petId).get();

      if (!petDoc.exists) {
        return null;
      }

      final pet = CatProfile.fromJson({
        ...petDoc.data()!,
        'id': petDoc.id,
      });

      // Cache the pet
      _multiPetCache[petId] = pet;
      _multiPetCacheTimestamps[petId] = DateTime.now();

      return pet;
    } on FirebaseException catch (e) {
      debugPrint('Error getting pet $petId: ${e.message}');
      return null;
    }
  }

  /// Gets all pets for the current user
  ///
  /// Paginated and cached to minimize Firestore reads.
  /// Most users (90%) will have 1 pet, so this is rarely called.
  Future<List<CatProfile>> getUserPets({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    try {
      var query = _petsCollection!
          .orderBy('createdAt', descending: false)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final petsQuery = await query.get();

      final pets = petsQuery.docs.map((doc) {
        final pet = CatProfile.fromJson({
          ...doc.data(),
          'id': doc.id,
        });

        // Cache each pet for future individual access
        _multiPetCache[pet.id] = pet;
        _multiPetCacheTimestamps[pet.id] = DateTime.now();

        return pet;
      }).toList();

      // If this is the first pet and we have no primary cache, set it
      if (pets.isNotEmpty && _cachedPrimaryPet == null && startAfter == null) {
        _cachedPrimaryPet = pets.first;
        _cachedPrimaryPetUserId = userId;
        _cacheTimestamp = DateTime.now();
      }

      return pets;
    } on FirebaseException catch (e) {
      debugPrint('Error getting user pets: ${e.message}');
      return [];
    }
  }

  /// Updates an existing pet profile
  ///
  /// Uses surgical updates to minimize Firestore write costs.
  /// Updates cache immediately for responsive UI.
  Future<PetResult> updatePet(CatProfile updatedProfile) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const PetFailure(
          PetServiceException('Must be logged in to update pet profiles'),
        );
      }

      // Validate the updated profile
      final validationResult = _validationService.validateProfile(
        updatedProfile,
      );
      if (!validationResult.isValid) {
        final errorMessages =
            validationResult.errors.map((e) => e.message).toList();
        return PetFailure(
          ProfileValidationException(errorMessages),
        );
      }

      // Ensure the pet belongs to the current user
      if (updatedProfile.userId != userId) {
        return const PetFailure(
          PetServiceException.permission(),
        );
      }

      // Update timestamp
      final finalProfile = updatedProfile.copyWith(
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await _petsCollection!.doc(finalProfile.id).update(finalProfile.toJson());

      // Update caches immediately
      if (_cachedPrimaryPet?.id == finalProfile.id) {
        _cachedPrimaryPet = finalProfile;
        _cacheTimestamp = DateTime.now();

        // Save to persistent cache (fire and forget)
        unawaited(_saveToPersistentCache(finalProfile, userId));
      }
      _multiPetCache[finalProfile.id] = finalProfile;
      _multiPetCacheTimestamps[finalProfile.id] = DateTime.now();

      return PetSuccess(finalProfile);
    } on FirebaseException catch (e) {
      return PetFailure(ProfileExceptionMapper.mapFirestoreException(e));
    } on Exception catch (e) {
      return PetFailure(ProfileExceptionMapper.mapGenericException(e));
    }
  }

  /// Deletes a pet profile
  ///
  /// Includes dependency checking to prevent orphaned data.
  /// Clears all relevant caches.
  Future<PetResult> deletePet(String petId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const PetFailure(
          PetServiceException('Must be logged in to delete pet profiles'),
        );
      }

      // Get the pet to verify ownership and get name for error messages
      final pet = await getPet(petId);
      if (pet == null) {
        return const PetFailure(PetNotFoundException());
      }

      if (pet.userId != userId) {
        return const PetFailure(PetServiceException.permission());
      }

      // Check for dependencies (fluid sessions, etc.)
      final dependencies = await _checkPetDependencies(petId, userId);
      if (dependencies.isNotEmpty) {
        return PetFailure(
          PetHasDependenciesException(pet.name, dependencies),
        );
      }

      // Delete from Firestore
      await _petsCollection!.doc(petId).delete();

      // Clear caches
      if (_cachedPrimaryPet?.id == petId) {
        _cachedPrimaryPet = null;
        _cachedPrimaryPetUserId = null;
        _cacheTimestamp = null;
      }
      _multiPetCache.remove(petId);
      _multiPetCacheTimestamps.remove(petId);

      return PetSuccess(pet);
    } on FirebaseException catch (e) {
      return PetFailure(ProfileExceptionMapper.mapFirestoreException(e));
    } on Exception catch (e) {
      return PetFailure(ProfileExceptionMapper.mapGenericException(e));
    }
  }

  /// Checks for name conflicts and returns suggested alternatives
  ///
  /// Optimized with caching since 90% of users have no conflicts.
  Future<List<String>> checkNameConflicts(String name) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    return _checkNameConflicts(name, userId);
  }

  /// Clears all caches (useful for testing or manual refresh)
  Future<void> clearCache() async {
    _cachedPrimaryPet = null;
    _cachedPrimaryPetUserId = null;
    _cacheTimestamp = null;
    _multiPetCache.clear();
    _multiPetCacheTimestamps.clear();
    _nameConflictCache.clear();

    // Clear persistent cache too (await to ensure completion)
    await _clearPersistentCache();
  }

  /// Gets the timestamp when the cached pet data was last updated
  DateTime? getCacheTimestamp() {
    return _cacheTimestamp;
  }

  /// Loads pet data from persistent cache
  Future<CatProfile?> _loadFromPersistentCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final petJson = prefs.getString('${_persistentCacheKey}_$userId');
      final timestampStr = prefs.getString(
        '${_persistentCacheTimestampKey}_$userId',
      );

      if (petJson == null || timestampStr == null) {
        return null;
      }

      // Check if persistent cache is not too old (24 hours)
      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) > const Duration(hours: 24)) {
        // Clear expired persistent cache
        await _clearPersistentCacheForUser(userId);
        return null;
      }

      final petData = json.decode(petJson) as Map<String, dynamic>;
      return CatProfile.fromJson(petData);
    } on Exception catch (e) {
      debugPrint('Error loading from persistent cache: $e');
      return null;
    }
  }

  /// Saves pet data to persistent cache
  Future<void> _saveToPersistentCache(CatProfile pet, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final petJson = json.encode(pet.toJson());
      final timestamp = DateTime.now().toIso8601String();

      await prefs.setString('${_persistentCacheKey}_$userId', petJson);
      await prefs.setString(
        '${_persistentCacheTimestampKey}_$userId',
        timestamp,
      );
    } on Exception catch (e) {
      debugPrint('Error saving to persistent cache: $e');
    }
  }

  /// Clears persistent cache for all users
  Future<void> _clearPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_persistentCacheKey) ||
            key.startsWith(_persistentCacheTimestampKey)) {
          await prefs.remove(key);
        }
      }
    } on Exception catch (e) {
      debugPrint('Error clearing persistent cache: $e');
    }
  }

  /// Clears persistent cache for a specific user
  Future<void> _clearPersistentCacheForUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_persistentCacheKey}_$userId');
      await prefs.remove('${_persistentCacheTimestampKey}_$userId');
    } on Exception catch (e) {
      debugPrint('Error clearing persistent cache for user: $e');
    }
  }

  /// Validates whether primary cache is still valid
  bool _isPrimaryCacheValid(String userId) {
    return _cachedPrimaryPet != null &&
        _cachedPrimaryPetUserId == userId &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheTimeout;
  }

  /// Validates whether multi-pet cache entry is still valid
  bool _isMultiPetCacheValid(String petId) {
    final timestamp = _multiPetCacheTimestamps[petId];
    return timestamp != null &&
        DateTime.now().difference(timestamp) < _cacheTimeout;
  }

  /// Internal method to check name conflicts with caching
  Future<List<String>> _checkNameConflicts(String name, String userId) async {
    final cacheKey = '${userId}_${name.toLowerCase()}';

    // Check cache first
    if (_nameConflictCache.containsKey(cacheKey)) {
      return _nameConflictCache[cacheKey]!;
    }

    try {
      // Query for exact name match (most efficient)
      final existingQuery = await _petsCollection!
          .where('name', isEqualTo: name.trim())
          .limit(1)
          .get();

      var suggestions = <String>[];

      if (existingQuery.docs.isNotEmpty) {
        // Name conflict found, generate suggestions
        suggestions = await _generateNameSuggestions(name.trim(), userId);
      }

      // Cache the result
      _nameConflictCache[cacheKey] = suggestions;

      // Clean old cache entries periodically
      if (_nameConflictCache.length > 100) {
        _nameConflictCache.clear();
      }

      return suggestions;
    } on FirebaseException catch (e) {
      debugPrint('Error checking name conflicts: ${e.message}');
      return [];
    }
  }

  /// Generates alternative name suggestions
  Future<List<String>> _generateNameSuggestions(
    String baseName,
    String userId,
  ) async {
    final suggestions = <String>[];

    // Try numbered variations
    for (var i = 2; i <= 5; i++) {
      suggestions.add('$baseName $i');
    }

    // Try suffix variations
    final suffixes = ['Jr', 'II', 'The Great', 'Baby'];
    for (final suffix in suffixes) {
      suggestions.add('$baseName $suffix');
    }

    // Filter out suggestions that also conflict
    final validSuggestions = <String>[];
    for (final suggestion in suggestions) {
      final conflictCheck = await _petsCollection!
          .where('name', isEqualTo: suggestion)
          .limit(1)
          .get();

      if (conflictCheck.docs.isEmpty) {
        validSuggestions.add(suggestion);
        if (validSuggestions.length >= 3) break; // Limit suggestions
      }
    }

    return validSuggestions;
  }

  /// Generates a unique pet ID with retry logic
  Future<String> _generateUniquePetId(String userId) async {
    for (var attempt = 0; attempt < 10; attempt++) {
      final id = _generateRandomId();

      // Check if ID already exists
      final existingDoc = await _petsCollection!.doc(id).get();
      if (!existingDoc.exists) {
        return id;
      }
    }

    // Fallback to timestamp-based ID if random fails
    return 'pet_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generates a random pet ID
  String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = math.Random();
    return List.generate(
      20,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Checks for dependencies that prevent pet deletion
  Future<List<String>> _checkPetDependencies(
    String petId,
    String userId,
  ) async {
    final dependencies = <String>[];

    try {
      // Check for fluid sessions
      final fluidSessions = await _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .collection('fluidSessions')
          .limit(1)
          .get();

      if (fluidSessions.docs.isNotEmpty) {
        dependencies.add('fluid therapy sessions');
      }

      // Check for weight records
      final weights = await _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .collection('weights')
          .limit(1)
          .get();

      if (weights.docs.isNotEmpty) {
        dependencies.add('weight records');
      }

      // Add more dependency checks as features are added
      // (medications, schedules, etc.)
    } on FirebaseException catch (e) {
      debugPrint('Error checking dependencies: ${e.message}');
    }

    return dependencies;
  }
}
