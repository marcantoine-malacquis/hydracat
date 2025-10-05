---
description: Ask clarifying questions
    - "**/*"

alwaysApply: false
---
After analysing the situation and looking at the relevant code, please come up with the most appropriate plan, following best practices, to fix this issue. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

After analysing the situation and looking at the relevant code, please ultrathink to come up with the most appropriate plan to fix this issue. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please ultrathink to come up with the most appropriate plan to achieve this. After analysing the situation and looking at the relevant code, please ask me any question you would need to feel confident about solving the issues. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please create a detailed plan of how you will achieve and implement this step.
Before you create the plan, please ask any and all questions you have in order to provide the most robust solution to handle edge cases and/or additional context that you might need to feel confident in proceeding with the implementation. When you do use clarifying questions, please do not use bullet points but rather letters within each numbered question if number requires bullet points. Before you ask me questions, please already have a look at all the existing files you would need to already have the context, use existing systems, ensure coherence and in case you already find the answer to your questions. Keep in mind that I want to have the best suited solution for my project while being in line with industry standards and app development best practices as much as possible. Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom solutions. Also, keep in mind the CRUD rules file (.cursor/rules/firebase_CRUDrules.md) to make sure to keep firebase costs to a minimum. Regarding database, I don't need to worry about backward compatibility since I will regularily delete the database anyway for testing. After implementation, don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please let me know if this makes sense or contradict itself, the prd, the CRUD rules or existing code. Coherence and app development best practices are extremely important. Let's me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself. After implementation, check for linting issues and, if you found any, fix them.

Please update and add only the important informations to remember about what we implemented in this step for future reference in 

Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom solutions.

Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Here is a conversation i had about those questions. Please review it and let me know what you agree with and what you would disagree with.


1. a) let's use SharedPreferences
b) yes, mirror the structure that will eventually be in the Firestore treatmentSummaryDaily document
2. it will be handled differently. On another screen (probably in Progress), the user will have the possibility to modify any of the previously inputed logging. We will implement that in the future.
3. no I don't think we need to track that beyond the immediate UI flow. It's simply for the user to be able to select wether they want to log fluid or medication.
4. Include only those 6 fields for now:
✅ date (cache validation)
✅ medicationSessionCount (logged status)
✅ fluidSessionCount (logged status)
✅ medicationNames (duplicate detection)
✅ totalMedicationDosesGiven (home screen adherence display)
✅ totalFluidVolumeGiven (home screen adherence display)
Don't include lastUpdatedAt (redundant with date, adds complexity) !
5. Let's use an hybrid approach if you think that would make sense.
Hybrid model: @immutable
class DailySummaryCache {
  final String date;
  final int medicationSessionCount;
  final int fluidSessionCount;
  final List<String> medicationNames;
  final double totalMedicationDosesGiven;
  final double totalFluidVolumeGiven;
  
  const DailySummaryCache({
    required this.date,
    required this.medicationSessionCount,
    required this.fluidSessionCount,
    required this.medicationNames,
    required this.totalMedicationDosesGiven,
    required this.totalFluidVolumeGiven,
  });
  
  // ✅ PURE validation - testable, no side effects
  /// Check if this cache is valid for the given date
  bool isValidFor(String targetDate) {
    return date == targetDate;
  }
  
  // ✅ DOMAIN logic - belongs in model
  /// Check if any sessions have been logged
  bool get hasAnySessions => 
      medicationSessionCount > 0 || fluidSessionCount > 0;
  
  /// Check if a specific medication has been logged
  bool hasMedicationLogged(String medicationName) => 
      medicationNames.contains(medicationName);
  
  /// Check if fluids have been logged
  bool get hasFluidSession => fluidSessionCount > 0;
  
  // ✅ FACTORY constructor - easy creation
  factory DailySummaryCache.empty(String date) {
    return DailySummaryCache(
      date: date,
      medicationSessionCount: 0,
      fluidSessionCount: 0,
      medicationNames: [],
      totalMedicationDosesGiven: 0.0,
      totalFluidVolumeGiven: 0.0,
    );
  }
  
  // ✅ COPY methods - immutability support
  DailySummaryCache copyWithSession({
    required String? medicationName,
    double? dosageGiven,
    double? volumeGiven,
  }) {
    return DailySummaryCache(
      date: date,
      medicationSessionCount: medicationName != null 
          ? medicationSessionCount + 1 
          : medicationSessionCount,
      fluidSessionCount: volumeGiven != null 
          ? fluidSessionCount + 1 
          : fluidSessionCount,
      medicationNames: medicationName != null && !medicationNames.contains(medicationName)
          ? [...medicationNames, medicationName]
          : medicationNames,
      totalMedicationDosesGiven: totalMedicationDosesGiven + (dosageGiven ?? 0.0),
      totalFluidVolumeGiven: totalFluidVolumeGiven + (volumeGiven ?? 0.0),
    );
  }
  
  // JSON serialization
  Map<String, dynamic> toJson() => {
    'date': date,
    'medicationSessionCount': medicationSessionCount,
    'fluidSessionCount': fluidSessionCount,
    'medicationNames': medicationNames,
    'totalMedicationDosesGiven': totalMedicationDosesGiven,
    'totalFluidVolumeGiven': totalFluidVolumeGiven,
  };
  
  factory DailySummaryCache.fromJson(Map<String, dynamic> json) {
    return DailySummaryCache(
      date: json['date'] as String,
      medicationSessionCount: json['medicationSessionCount'] as int,
      fluidSessionCount: json['fluidSessionCount'] as int,
      medicationNames: (json['medicationNames'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      totalMedicationDosesGiven: (json['totalMedicationDosesGiven'] as num).toDouble(),
      totalFluidVolumeGiven: (json['totalFluidVolumeGiven'] as num).toDouble(),
    );
  }
}

The service layer (phase 2)
class DailyCacheService {
  final SharedPreferences _prefs;
  
  // ❌ Service does NOT duplicate model validation
  // ✅ Service adds time-aware logic using model's pure validation
  
  /// Get cached summary if valid for today, null otherwise
  Future<DailySummaryCache?> getTodaySummary(String userId, String petId) async {
    final key = _buildKey(userId, petId);
    final jsonString = _prefs.getString(key);
    
    if (jsonString == null) return null;
    
    final cache = DailySummaryCache.fromJson(jsonDecode(jsonString));
    
    // ✅ Use model's pure validation with current date
    final today = AppDateUtils.formatDateForSummary(DateTime.now());
    if (!cache.isValidFor(today)) {
      // Cache is expired, clean it up
      await _prefs.remove(key);
      return null;
    }
    
    return cache;
  }
  
  /// Clear all caches that are not for today (run on app startup)
  Future<void> clearExpiredCaches() async {
    final today = AppDateUtils.formatDateForSummary(DateTime.now());
    final keys = _prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    
    for (final key in keys) {
      final jsonString = _prefs.getString(key);
      if (jsonString != null) {
        final cache = DailySummaryCache.fromJson(jsonDecode(jsonString));
        
        // ✅ Reuse model's validation
        if (!cache.isValidFor(today)) {
          await _prefs.remove(key);
        }
      }
    }
  }
  
  /// Update cache with new session data
  Future<void> updateCache({
    required String userId,
    required String petId,
    String? medicationName,
    double? dosageGiven,
    double? volumeGiven,
  }) async {
    final today = AppDateUtils.formatDateForSummary(DateTime.now());
    final existing = await getTodaySummary(userId, petId);
    
    final updated = existing?.copyWithSession(
      medicationName: medicationName,
      dosageGiven: dosageGiven,
      volumeGiven: volumeGiven,
    ) ?? DailySummaryCache.empty(today).copyWithSession(
      medicationName: medicationName,
      dosageGiven: dosageGiven,
      volumeGiven: volumeGiven,
    );
    
    final key = _buildKey(userId, petId);
    await _prefs.setString(key, jsonEncode(updated.toJson()));
  }
  
  String _buildKey(String userId, String petId) => 
      '${_keyPrefix}${userId}_${petId}';
  
  static const _keyPrefix = 'daily_cache_';
}

Why This Hybrid Approach Wins
1. Best of Both Worlds
Model responsibilities:

✅ Pure validation logic (isValidFor(targetDate))
✅ Domain queries (hasAnySessions, hasMedicationLogged)
✅ Data transformations (copyWithSession)

Service responsibilities:

✅ Time-aware operations (getting "today's" date)
✅ Storage persistence (SharedPreferences interaction)
✅ Cache lifecycle management (cleanup, expiration)

Please let me know if this makes sense or contradict itself, the prd, the CRUD rules or existing code. Coherence and app development best practices are extremely important. Let's me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.
