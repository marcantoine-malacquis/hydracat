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
import 'package:hydracat/features/profile/models/lab_result.dart';
import 'package:hydracat/features/profile/models/latest_lab_summary.dart';
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
        final errorMessages = validationResult.errors
            .map((e) => e.message)
            .toList();
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
    debugPrint(
      '[PetService] getPrimaryPet: Starting (forceRefresh=$forceRefresh)',
    );
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('[PetService] getPrimaryPet: No userId, returning null');
      return null;
    }

    debugPrint('[PetService] getPrimaryPet: userId=$userId');

    // Check memory cache first (90% of calls return here)
    if (!forceRefresh && _isPrimaryCacheValid(userId)) {
      debugPrint(
        '[PetService] getPrimaryPet: Returning from memory cache: '
        '${_cachedPrimaryPet?.name}',
      );
      return _cachedPrimaryPet;
    }

    // Check persistent cache if memory cache is invalid
    if (!forceRefresh) {
      debugPrint('[PetService] getPrimaryPet: Checking persistent cache...');
      final persistentPet = await _loadFromPersistentCache(userId);
      if (persistentPet != null) {
        debugPrint(
          '[PetService] getPrimaryPet: Found in persistent cache: '
          '${persistentPet.name}',
        );
        // Load into memory cache
        _cachedPrimaryPet = persistentPet;
        _cachedPrimaryPetUserId = userId;
        _cacheTimestamp = DateTime.now();
        return persistentPet;
      }
      debugPrint('[PetService] getPrimaryPet: Not in persistent cache');
    }

    try {
      debugPrint('[PetService] getPrimaryPet: Querying Firestore...');
      // Get user's pets (typically just 1 for 90% of users)
      final petsQuery = await _petsCollection!
          .orderBy('createdAt', descending: false)
          .limit(1) // Only need the first pet for primary
          .get();

      debugPrint(
        '[PetService] getPrimaryPet: Query returned '
        '${petsQuery.docs.length} docs',
      );

      if (petsQuery.docs.isEmpty) {
        debugPrint('[PetService] getPrimaryPet: No pets found');
        return null;
      }

      // Cache the primary pet
      final petDoc = petsQuery.docs.first;
      debugPrint('[PetService] getPrimaryPet: Parsing pet document...');
      final pet = CatProfile.fromJson({
        ...petDoc.data(),
        'id': petDoc.id,
      });

      debugPrint(
        '[PetService] getPrimaryPet: Successfully parsed pet: ${pet.name}',
      );

      // Update both memory and persistent cache
      _cachedPrimaryPet = pet;
      _cachedPrimaryPetUserId = userId;
      _cacheTimestamp = DateTime.now();

      // Save to persistent cache (fire and forget)
      unawaited(_saveToPersistentCache(pet, userId));

      debugPrint('[PetService] getPrimaryPet: Returning pet: ${pet.name}');
      return pet;
    } on FirebaseException catch (e) {
      debugPrint(
        '[PetService] getPrimaryPet: FirebaseException: '
        '${e.code} - ${e.message}',
      );

      // Try to return persistent cache as fallback
      final persistentPet = await _loadFromPersistentCache(userId);
      if (persistentPet != null) {
        debugPrint(
          '[PetService] getPrimaryPet: Returning fallback from persistent '
          'cache: ${persistentPet.name}',
        );
        _cachedPrimaryPet = persistentPet;
        _cachedPrimaryPetUserId = userId;
        _cacheTimestamp = DateTime.now();
      } else {
        debugPrint('[PetService] getPrimaryPet: No fallback available');
      }

      return persistentPet;
    } on Object catch (e, stackTrace) {
      debugPrint('[PetService] getPrimaryPet: Unexpected error: $e');
      debugPrint('[PetService] getPrimaryPet: Stack trace: $stackTrace');
      rethrow;
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
        final errorMessages = validationResult.errors
            .map((e) => e.message)
            .toList();
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
      final cacheReadyData = _prepareForPersistentCache(pet.toJson());
      final petJson = json.encode(cacheReadyData);
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

  /// Converts Firestore-specific objects into JSON-safe values before caching.
  Map<String, dynamic> _prepareForPersistentCache(
    Map<String, dynamic> data,
  ) {
    return data.map(
      (key, value) => MapEntry(key, _convertCacheValue(value)),
    );
  }

  /// Recursively converts values into primitives encodable by json.encode.
  dynamic _convertCacheValue(dynamic value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }

    if (value is DateTime) {
      return value.toIso8601String();
    }

    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }

    if (value is Iterable) {
      return value.map(_convertCacheValue).toList();
    }

    if (value is Map) {
      return value.map(
        (key, dynamic nestedValue) => MapEntry(
          key.toString(),
          _convertCacheValue(nestedValue),
        ),
      );
    }

    return value.toString();
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

  /// Updates the cached weight without a Firestore read
  ///
  /// This is an optimization for weight tracking - since WeightService
  /// already updates Firestore, we just need to sync our cache.
  /// Also updates persistent cache to maintain consistency across app restarts.
  void updateCachedWeight(double? weightKg) {
    if (_cachedPrimaryPet != null) {
      _cachedPrimaryPet = _cachedPrimaryPet!.copyWith(
        weightKg: weightKg,
        updatedAt: DateTime.now(),
      );
      _cacheTimestamp = DateTime.now();

      // Also update persistent cache (fire and forget)
      if (_cachedPrimaryPetUserId != null) {
        unawaited(
          _saveToPersistentCache(
            _cachedPrimaryPet!,
            _cachedPrimaryPetUserId!,
          ),
        );
      }
    }
  }

  // ========== Lab Results Methods ==========

  /// Creates a new lab result and updates the denormalized snapshot
  ///
  /// Uses a batch write to atomically:
  /// 1. Create the lab result document in the labResults subcollection
  /// 2. Update the pet's medicalInfo.latestLabResult denormalized snapshot
  ///
  /// The denormalized snapshot provides instant UI access without querying
  /// the subcollection (cost optimization).
  Future<PetResult> createLabResult({
    required String petId,
    required LabResult labResult,
    String? preferredUnitSystem,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const PetFailure(
          PetServiceException('Must be logged in to create lab results'),
        );
      }

      // Validate the lab result
      final validationErrors = labResult.validate();
      if (validationErrors.isNotEmpty) {
        return PetFailure(
          ProfileValidationException(validationErrors),
        );
      }

      // Ensure the lab result belongs to the correct pet
      if (labResult.petId != petId) {
        return const PetFailure(
          PetServiceException('Lab result pet ID does not match'),
        );
      }

      // Get the pet to verify ownership
      final pet = await getPet(petId);
      if (pet == null) {
        return const PetFailure(PetNotFoundException());
      }

      if (pet.userId != userId) {
        return const PetFailure(PetServiceException.permission());
      }

      // Check if we should update the latest lab result
      // Only update if:
      // 1. No existing latest exists (first lab result), OR
      // 2. The new result's testDate is more recent than
      // the current latest's testDate
      final currentLatest = pet.medicalInfo.latestLabResult;
      final shouldUpdateLatest =
          currentLatest == null ||
          labResult.testDate.isAfter(currentLatest.testDate) ||
          labResult.testDate.isAtSameMomentAs(currentLatest.testDate);

      // Use batch write for atomicity
      final batch = _firestore.batch();

      // 1. Create lab result document in subcollection (always create)
      final labResultRef = _petsCollection!
          .doc(petId)
          .collection('labResults')
          .doc(labResult.id);

      batch.set(labResultRef, labResult.toJson());

      // 2. Update pet document with latest lab summary only
      // if this is the new latest
      final petRef = _petsCollection!.doc(petId);
      if (shouldUpdateLatest) {
        // Create denormalized summary for the pet document
        final latestSummary = _createLatestLabSummary(
          labResult,
          preferredUnitSystem,
        );

        // Prepare batch update
        final updateData = <String, dynamic>{
          'medicalInfo.latestLabResult': latestSummary.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Auto-update pet's current IRIS stage if lab result has one
        if (labResult.metadata?.irisStage != null) {
          updateData['medicalInfo.irisStage'] =
              labResult.metadata!.irisStage!.name;
        }

        batch.update(petRef, updateData);

        // Commit the batch
        await batch.commit();

        // Update cache with new latestLabResult and IRIS stage
        // (only if we updated it)
        if (_cachedPrimaryPet?.id == petId) {
          _cachedPrimaryPet = _cachedPrimaryPet!.copyWith(
            medicalInfo: _cachedPrimaryPet!.medicalInfo.copyWith(
              latestLabResult: latestSummary,
              irisStage:
                  labResult.metadata?.irisStage ??
                  _cachedPrimaryPet!.medicalInfo.irisStage,
            ),
            updatedAt: DateTime.now(),
          );
          _cacheTimestamp = DateTime.now();

          // Save to persistent cache (fire and forget)
          unawaited(_saveToPersistentCache(_cachedPrimaryPet!, userId));
        }

        // Update multi-pet cache if present
        if (_multiPetCache.containsKey(petId)) {
          _multiPetCache[petId] = _multiPetCache[petId]!.copyWith(
            medicalInfo: _multiPetCache[petId]!.medicalInfo.copyWith(
              latestLabResult: latestSummary,
              irisStage:
                  labResult.metadata?.irisStage ??
                  _multiPetCache[petId]!.medicalInfo.irisStage,
            ),
            updatedAt: DateTime.now(),
          );
          _multiPetCacheTimestamps[petId] = DateTime.now();
        }
      } else {
        // Still update updatedAt timestamp even if we don't update
        // latestLabResult
        batch.update(petRef, {
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Commit the batch
        await batch.commit();
      }

      return PetSuccess(pet);
    } on FirebaseException catch (e) {
      return PetFailure(ProfileExceptionMapper.mapFirestoreException(e));
    } on Exception catch (e) {
      return PetFailure(ProfileExceptionMapper.mapGenericException(e));
    }
  }

  /// Helper to create a denormalized lab summary from a full LabResult
  ///
  /// CRITICAL: Stores the user-entered value with the preferredUnitSystem.
  /// The actual unit for each analyte is derived at display time using
  /// getDefaultUnit(analyte, preferredUnitSystem).
  ///
  /// This works because the unit toggle applies to ALL values:
  /// - preferredUnitSystem='us' → creatinine in mg/dL, BUN in mg/dL
  /// - preferredUnitSystem='si' → creatinine in µmol/L, BUN in mmol/L
  /// - SDMA always in µg/dL regardless of system
  ///
  /// Example:
  /// If user enters Creatinine=120 in SI units:
  /// - LabResult stores: {value: 120, unit: "µmol/L", valueUs: null, valueSi: null}
  /// - LatestLabSummary stores: {creatinine: 120, preferredUnitSystem: "si"}
  /// - Display derives: unit = getDefaultUnit('creatinine', 'si') = "µmol/L"
  /// - Gauge uses: getLabReferenceRange('creatinine', 'µmol/L') = SI range (53-141)
  LatestLabSummary _createLatestLabSummary(
    LabResult labResult,
    String? preferredUnitSystem,
  ) {
    // Extract the entered values directly (NOT valueUs/valueSi - those are null)
    final creatinineValue = labResult.creatinine?.value;
    final bunValue = labResult.bun?.value;
    final sdmaValue = labResult.sdma?.value;
    final phosphorusValue = labResult.phosphorus?.value;

    return LatestLabSummary(
      testDate: labResult.testDate,
      labResultId: labResult.id,
      creatinine: creatinineValue,
      bun: bunValue,
      sdma: sdmaValue,
      phosphorus: phosphorusValue,
      preferredUnitSystem: preferredUnitSystem ?? 'us',
    );
  }

  /// Watches lab results for a pet (realtime stream)
  ///
  /// Returns a stream of lab results ordered by test date (most recent first).
  /// Useful for displaying lab history in the UI.
  Stream<List<LabResult>> watchLabResults(
    String petId, {
    int limit = 20,
  }) {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _petsCollection!
        .doc(petId)
        .collection('labResults')
        .orderBy('testDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return LabResult.fromJson({
              ...doc.data(),
              'id': doc.id,
            });
          }).toList();
        });
  }

  /// Gets lab results for a pet (paginated)
  ///
  /// Returns a list of lab results ordered by test date (most recent first).
  /// Supports pagination with [startAfter] parameter.
  Future<List<LabResult>> getLabResults(
    String petId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    try {
      var query = _petsCollection!
          .doc(petId)
          .collection('labResults')
          .orderBy('testDate', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final labResultsQuery = await query.get();

      return labResultsQuery.docs.map((doc) {
        return LabResult.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    } on FirebaseException catch (e) {
      debugPrint('Error getting lab results: ${e.message}');
      return [];
    }
  }

  /// Gets a specific lab result by ID
  ///
  /// Useful for viewing detailed information about a single lab result.
  Future<LabResult?> getLabResult(String petId, String labResultId) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    try {
      final labResultDoc = await _petsCollection!
          .doc(petId)
          .collection('labResults')
          .doc(labResultId)
          .get();

      if (!labResultDoc.exists) {
        return null;
      }

      return LabResult.fromJson({
        ...labResultDoc.data()!,
        'id': labResultDoc.id,
      });
    } on FirebaseException catch (e) {
      debugPrint('Error getting lab result $labResultId: ${e.message}');
      return null;
    }
  }

  /// Deletes a lab result
  ///
  /// This will:
  /// - Delete the lab result document from the subcollection
  /// - Update the denormalized latestLabResult field if necessary
  /// - Clear the field if no results remain
  Future<PetResult> deleteLabResult({
    required String petId,
    required String labResultId,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const PetFailure(
          PetServiceException('Must be logged in to delete lab results'),
        );
      }

      // Get the pet to verify ownership
      final pet = await getPet(petId);
      if (pet == null) {
        return const PetFailure(PetNotFoundException());
      }

      if (pet.userId != userId) {
        return const PetFailure(PetServiceException.permission());
      }

      // Get the lab result to check if it's the latest
      final labResultToDelete = await getLabResult(petId, labResultId);
      if (labResultToDelete == null) {
        return const PetFailure(
          PetServiceException('Lab result not found'),
        );
      }

      final batch = _firestore.batch();

      // 1. Delete the lab result document
      final labResultRef = _petsCollection!
          .doc(petId)
          .collection('labResults')
          .doc(labResultId);
      batch.delete(labResultRef);

      // 2. Check if we're deleting the latest result
      final currentLatest = pet.medicalInfo.latestLabResult;
      final isDeletingLatest =
          currentLatest != null && currentLatest.labResultId == labResultId;

      if (isDeletingLatest) {
        // Fetch remaining lab results to find the new latest
        final remainingResults = await _petsCollection!
            .doc(petId)
            .collection('labResults')
            .orderBy('testDate', descending: true)
            .limit(2) // Get top 2 (first will be the one we're deleting)
            .get();

        final petRef = _petsCollection!.doc(petId);

        // Find the new latest (skip the one we're deleting)
        LabResult? newLatest;
        for (final doc in remainingResults.docs) {
          if (doc.id != labResultId) {
            newLatest = LabResult.fromJson({
              ...doc.data(),
              'id': doc.id,
            });
            break;
          }
        }

        if (newLatest != null) {
          // Update with new latest
          final newLatestSummary = _createLatestLabSummary(
            newLatest,
            // Infer unit system from the result
            newLatest.creatinine?.unit == 'µmol/L' ? 'si' : 'us',
          );

          batch.update(petRef, {
            'medicalInfo.latestLabResult': newLatestSummary.toJson(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Update cache
          if (_cachedPrimaryPet?.id == petId) {
            _cachedPrimaryPet = _cachedPrimaryPet!.copyWith(
              medicalInfo: _cachedPrimaryPet!.medicalInfo.copyWith(
                latestLabResult: newLatestSummary,
              ),
              updatedAt: DateTime.now(),
            );
            _cacheTimestamp = DateTime.now();
          }

          // Update multi-pet cache if present
          if (_multiPetCache.containsKey(petId)) {
            _multiPetCache[petId] = _multiPetCache[petId]!.copyWith(
              medicalInfo: _multiPetCache[petId]!.medicalInfo.copyWith(
                latestLabResult: newLatestSummary,
              ),
              updatedAt: DateTime.now(),
            );
            _multiPetCacheTimestamps[petId] = DateTime.now();
          }
        } else {
          // No results remain, clear the latest field
          batch.update(petRef, {
            'medicalInfo.latestLabResult': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Update cache
          if (_cachedPrimaryPet?.id == petId) {
            _cachedPrimaryPet = _cachedPrimaryPet!.copyWith(
              medicalInfo: _cachedPrimaryPet!.medicalInfo.copyWith(
                latestLabResult: null,
              ),
              updatedAt: DateTime.now(),
            );
            _cacheTimestamp = DateTime.now();
          }

          // Update multi-pet cache if present
          if (_multiPetCache.containsKey(petId)) {
            _multiPetCache[petId] = _multiPetCache[petId]!.copyWith(
              medicalInfo: _multiPetCache[petId]!.medicalInfo.copyWith(
                latestLabResult: null,
              ),
              updatedAt: DateTime.now(),
            );
            _multiPetCacheTimestamps[petId] = DateTime.now();
          }
        }
      }

      // Commit the batch
      await batch.commit();

      return PetSuccess(pet);
    } on FirebaseException catch (e) {
      debugPrint('Error deleting lab result: ${e.message}');
      return PetFailure(
        PetServiceException('Failed to delete lab result: ${e.message}'),
      );
    } on Exception catch (e) {
      debugPrint('Error deleting lab result: $e');
      return PetFailure(
        PetServiceException('Failed to delete lab result: $e'),
      );
    }
  }
}
