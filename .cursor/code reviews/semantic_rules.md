# Semantic Naming Rules & Conventions

> **Purpose**: Ensure all identifiers (variables, methods, classes) accurately reflect their purpose and behavior.
> **Last Updated**: October 31, 2025

## Table of Contents
1. [Boolean Naming Conventions](#boolean-naming-conventions)
2. [Method Naming Conventions](#method-naming-conventions)
3. [Variable Naming Best Practices](#variable-naming-best-practices)
4. [Class & File Naming](#class--file-naming)
5. [Refactoring Checklist](#refactoring-checklist)
6. [Real-World Examples from HydraCat Codebase](#real-world-examples-from-hydracat-codebase)
7. [Serialization & Data Transfer Patterns](#serialization--data-transfer-patterns)
8. [Consistency Within Files & Classes](#consistency-within-files--classes)
9. [Context-Dependent Naming Guidelines](#context-dependent-naming-guidelines)
10. [Safe Refactoring Process](#safe-refactoring-process)
11. [Trade-offs & Decision Making](#trade-offs--decision-making)
12. [Team Guidelines](#team-guidelines)
13. [Quick Reference](#quick-reference)

---

## Boolean Naming Conventions

### Required Prefixes

Boolean variables and getters **must** use one of these prefixes:

#### `is` - State/Identity Checks
Use for checking current state or type:

```dart
// ✅ Good
bool get isLoading => _loading;
bool get isInitialized => _initialized;
bool get isEnabled => _enabled;
bool get isAuthenticated => currentUser != null;
bool get isComplete => hasAllRequiredFields();
bool get isValid => validate().isEmpty;
bool get isOnline => connectivity == ConnectivityStatus.online;
bool get isToday => DateUtils.isSameDay(date, DateTime.now());

// ❌ Bad
bool get loading => _loading;           // Missing prefix
bool get initialized => _initialized;   // Missing prefix
bool get valid => validate().isEmpty;   // Missing prefix
```

#### `has` - Possession/Existence Checks
Use for checking existence of data or features:

```dart
// ✅ Good
bool get hasPetProfile => primaryPet != null;
bool get hasError => error != null;
bool get hasFluidSchedule => fluidSchedule != null;
bool get hasAnySessions => sessionCount > 0;
bool get hasCompleteData => requiredFields.every((f) => f != null);
bool get hasMedicationSchedules => medications.isNotEmpty;

// ❌ Bad
bool get petProfile => primaryPet != null;  // Missing prefix
bool get error => error != null;            // Missing prefix
bool get sessions => sessionCount > 0;      // Missing prefix
```

#### `should` - Conditional Logic/Decisions
Use for control flow and conditional rendering:

```dart
// ✅ Good
bool get shouldHideNavBar => routes.contains(currentRoute);
bool get shouldShowBanner => !isVerified && isAuthenticated;
bool get shouldRefresh => lastUpdate.isBefore(threshold);
bool get shouldEnableButton => !isLoading && hasValidData;

// ❌ Bad
final hideNavBar = routes.contains(currentRoute);  // Missing prefix
final showBanner = !isVerified;                    // Missing prefix
```

#### `can` - Permission/Capability Checks
Use for checking if an action is allowed:

```dart
// ✅ Good
bool get canScheduleNotifications => permissionGranted;
bool get canEdit => isOwner || isAdmin;
bool get canSubmit => form.isValid && !isLoading;
bool get canDelete => hasPermission('delete');

// ❌ Bad
bool get scheduleNotifications => permissionGranted;  // Missing prefix
bool get editAllowed => isOwner;                      // Wrong pattern
```

#### `was`/`did` - Past Actions/Events
Use for historical state checks:

```dart
// ✅ Good
bool get wasModified => updatedAt != null && updatedAt!.isAfter(createdAt);
bool get wasSuccessful => result.status == Status.success;
bool get didComplete => progress == 1.0;
bool get didTimeout => endTime.isAfter(deadline);

// ❌ Bad
bool get modified => updatedAt != null;  // Missing prefix
```

### Special Cases

```dart
// Negatives - avoid double negatives
// ✅ Good
bool get isEnabled => !_disabled;
bool get hasData => data != null;

// ❌ Bad
bool get isNotDisabled => !_disabled;  // Double negative
bool get notEmpty => data != null;     // Use hasData instead
```

---

## Method Naming Conventions

### Async Methods (Future/Stream)

#### Query/Fetch Operations (Non-mutating)
```dart
// ✅ Good - Start with get/fetch/load/find
Future<User> getUser(String id);
Future<List<Schedule>> fetchSchedules();
Future<Profile> loadProfile();
Future<Session?> findSessionById(String id);
Future<bool> checkPermission();
Future<int> countSessions();

// ❌ Bad - Unclear what they do
Future<User> user(String id);           // Not a verb
Future<List<Schedule>> schedules();     // Not a verb
Future<Profile> profile();              // Not a verb
```

#### Mutation Operations
```dart
// ✅ Good - Clear action verbs
Future<void> saveSession(Session session);
Future<void> updateProfile(Profile profile);
Future<void> deleteSchedule(String id);
Future<void> createNotification(Notification notif);
Future<void> removeCache();
Future<void> clearData();
Future<void> resetState();

// ❌ Bad - Unclear or ambiguous
Future<void> session(Session session);  // Not a verb
Future<void> profile(Profile profile);  // Not a verb
Future<void> data();                    // What happens to data?
```

#### Scheduling/Cancellation
```dart
// ✅ Good - Paired operations
Future<void> scheduleNotification(DateTime time);
Future<void> cancelNotification(int id);
Future<void> scheduleAll();
Future<void> cancelAll();

// ❌ Bad - Inconsistent naming
Future<void> scheduleNotification(DateTime time);
Future<void> removeNotification(int id);  // Should be cancel
```

#### Refresh/Reload
```dart
// ✅ Good
Future<void> refreshData();
Future<void> reloadProfile();
Future<void> syncWithServer();

// ❌ Bad
Future<void> getData();  // Is this fetch or refresh?
```

### Synchronous Methods

#### Void Methods (Side Effects)
```dart
// ✅ Good - Imperative verbs
void setLoading(bool value);
void clearError();
void resetForm();
void initializeState();
void dispose();
void notifyListeners();

// ❌ Bad
void loading(bool value);  // Not a verb
void error();              // What happens?
```

#### Getters (Already covered in Boolean section)
```dart
// Non-boolean getters
String get displayName => '$firstName $lastName';
int get totalCount => items.length;
DateTime get lastModified => _lastModified ?? createdAt;
```

### Method Naming Patterns by Purpose

| Purpose | Pattern | Example |
|---------|---------|---------|
| Retrieve data | `get*`, `fetch*`, `load*` | `getUser()`, `fetchSchedules()` |
| Create new | `create*`, `add*` | `createProfile()`, `addSession()` |
| Update existing | `update*`, `set*`, `modify*` | `updateProfile()`, `setEnabled()` |
| Delete/Remove | `delete*`, `remove*`, `clear*` | `deleteSession()`, `clearCache()` |
| Check/Validate | `check*`, `validate*`, `verify*` | `checkPermission()`, `validateForm()` |
| Convert/Transform | `to*`, `from*`, `parse*` | `toJson()`, `fromMap()`, `parseDate()` |
| Build/Construct | `build*`, `create*` | `buildWidget()`, `createInstance()` |

---

## Variable Naming Best Practices

### Avoid Generic Names

❌ **Generic names to avoid:**
```dart
final data = ...
final value = ...
final temp = ...
final flag = ...
final check = ...
final result = ...
final item = ...
```

✅ **Better alternatives:**
```dart
// Instead of: final data = jsonDecode(jsonString);
final notificationData = jsonDecode(jsonString);
final scheduleData = jsonDecode(jsonString);
final userData = jsonDecode(jsonString);

// Instead of: final data = docSnapshot.data();
final profileData = docSnapshot.data();
final sessionData = docSnapshot.data();

// Instead of: final result = await operation();
final saveResult = await operation();
final validationResult = await operation();
final queryResult = await operation();

// Instead of: final item = list.first;
final firstSchedule = list.first;
final primarySession = list.first;
```

### Context-Specific Naming

```dart
// ✅ Good - Specific to context
final fluidSchedule = await fetchSchedule(FluidType);
final medicationDosage = calculateDosage();
final notificationPermission = await checkPermission();
final userProfile = ref.read(profileProvider);

// ❌ Bad - Too generic
final schedule = await fetchSchedule(FluidType);
final dosage = calculateDosage();
final permission = await checkPermission();
final profile = ref.read(profileProvider);
```

### Collections Naming

```dart
// ✅ Good - Plural for collections
final sessions = <Session>[];
final schedules = <Schedule>[];
final notifications = <Notification>[];

// Qualified when needed
final pendingSessions = <Session>[];
final completedSchedules = <Schedule>[];
final unreadNotifications = <Notification>[];

// ❌ Bad
final sessionList = <Session>[];    // "List" suffix unnecessary
final scheduleArray = <Schedule>[]; // "Array" is not Dart terminology
final notif = <Notification>[];     // Don't abbreviate
```

### Private Variables

```dart
// ✅ Good - Clear intention
bool _isInitialized = false;
String? _cachedData;
Timer? _debounceTimer;
StreamSubscription? _subscription;

// ❌ Bad
bool _init = false;           // Abbreviation
String? _cache;               // Too generic
Timer? _t;                    // Single letter
StreamSubscription? _sub;     // Abbreviation
```

---

## Class & File Naming

### Classes

```dart
// ✅ Good - Nouns describing what they are
class NotificationSettings { }
class UserProfile { }
class FluidSession { }
class ScheduleService { }
class AuthProvider { }
class LoggingNotifier { }

// ❌ Bad
class NotificationHandle { }  // Unclear
class UserData { }            // Too generic
class FluidInfo { }           // Too vague
```

### Files

```dart
// ✅ Good - Match class names, snake_case
notification_settings.dart
user_profile.dart
fluid_session.dart
schedule_service.dart

// ❌ Bad
notificationSettings.dart     // Should be snake_case
user.dart                     // Too generic
fluid.dart                    // Too generic
```

### Enums

```dart
// ✅ Good - Singular noun
enum NotificationStatus { pending, sent, failed }
enum TreatmentType { fluid, medication }
enum IrisStage { stage1, stage2, stage3, stage4 }

// ❌ Bad
enum NotificationStatuses { }  // Should be singular
enum Types { }                 // Too generic
```

---

## Refactoring Checklist

Use this checklist when reviewing or refactoring code:

### 1. Boolean Variables
- [ ] All boolean variables/getters use appropriate prefix (`is`, `has`, `should`, `can`, `was`, `did`)
- [ ] No double negatives (e.g., `isNotDisabled`)
- [ ] Names accurately describe what they check

### 2. Methods
- [ ] Async methods start with action verbs (`get`, `fetch`, `load`, `save`, `update`, `delete`)
- [ ] Void methods use imperative verbs (`set`, `clear`, `reset`, `initialize`)
- [ ] Method names accurately describe what they do, not how they do it

### 3. Variables
- [ ] No generic names like `data`, `value`, `temp`, `flag`
- [ ] Context-specific naming (e.g., `scheduleData` not just `data`)
- [ ] Collections use plural names
- [ ] Private variables use `_` prefix and are well-named

### 4. Classes & Files
- [ ] Class names are nouns or noun phrases
- [ ] File names match class names in snake_case
- [ ] Services end with `Service`
- [ ] Providers end with `Provider` or `Notifier`

### 5. Documentation
- [ ] Updated doc comments to reflect new names
- [ ] Clear descriptions of purpose, not implementation
- [ ] Examples provided for complex APIs

### 6. Tests
- [ ] Updated test names to reflect refactored code
- [ ] Test descriptions are clear and specific

---

## Real-World Examples from HydraCat Codebase

### Example 1: Scoped Variable Names in Similar Methods

When you have multiple similar methods in the same file, use scoped prefixes to prevent confusion:

```dart
// ✅ Good - Clear which summary type each variable holds
Future<DailySummary?> getDailySummary(DateTime date) async {
  final docSnapshot = await _firestore.collection('daily_summaries').doc(dateStr).get();
  final dailySummaryData = docSnapshot.data();
  if (dailySummaryData == null) return null;
  return DailySummary.fromJson(dailySummaryData as Map<String, dynamic>);
}

Future<WeeklySummary?> getWeeklySummary(DateTime date) async {
  final docSnapshot = await _firestore.collection('weekly_summaries').doc(weekStr).get();
  final weeklySummaryData = docSnapshot.data();
  if (weeklySummaryData == null) return null;
  return WeeklySummary.fromJson(weeklySummaryData as Map<String, dynamic>);
}

Future<MonthlySummary?> getMonthlySummary(DateTime date) async {
  final docSnapshot = await _firestore.collection('monthly_summaries').doc(monthStr).get();
  final monthlySummaryData = docSnapshot.data();
  if (monthlySummaryData == null) return null;
  return MonthlySummary.fromJson(monthlySummaryData as Map<String, dynamic>);
}

// ❌ Bad - Confusing when copy-pasting or debugging
Future<DailySummary?> getDailySummary(DateTime date) async {
  final doc = await _firestore.collection('daily_summaries').doc(dateStr).get();
  final data = doc.data();  // Which type of data? Easy to mix up
  if (data == null) return null;
  return DailySummary.fromJson(data as Map<String, dynamic>);
}
```

**Why this matters:** In stack traces, seeing `dailySummaryData` immediately tells you which method failed. When refactoring, scoped names prevent copy-paste errors.

### Example 2: Navigation Bar Visibility Logic

```dart
// ✅ Good - Clear semantic meaning
final shouldHideNavBar = [
  '/profile/settings',
  '/profile/settings/notifications',
  '/profile/ckd',
  '/profile/fluid/create',
].contains(currentLocation);

bottomNavigationBar: shouldHideNavBar ? null : HydraNavigationBar(...);

// ❌ Bad - Misleading name
final isInProfileEditScreens = [  // Not all are "edit" screens!
  '/profile/settings',
  '/profile/settings/notifications',  // This is just viewing settings
  '/profile/ckd',
].contains(currentLocation);
```

**Lesson:** Names should describe **what they control**, not implementation details or incorrect assumptions about scope.

### Example 3: Boolean Getters for Treatment Summaries

```dart
// ✅ Good - Clear possession and state checks
class TreatmentSummary {
  bool get hasCompletedAllMedications => 
    medicationScheduledDoses > 0 && medicationMissedCount == 0;
  
  bool get hasReachedGoal => 
    givenMl >= goalMl && goalMl > 0;
}

// ❌ Bad - Missing prefixes
class TreatmentSummary {
  bool get allMedicationsCompleted =>  // Missing "has"
    medicationScheduledDoses > 0 && medicationMissedCount == 0;
  
  bool get reached =>  // Missing "has", unclear what was reached
    givenMl >= goalMl && goalMl > 0;
}
```

### Example 4: Logging Mode Capabilities

```dart
// ✅ Good - Appropriate prefixes for each check
enum LoggingMode {
  quickLog,
  manual;
  
  bool get canAdjustTime => this == LoggingMode.manual;
  bool get shouldShowOptionalFields => this == LoggingMode.manual;
  bool get isScheduleRequired => this == LoggingMode.quickLog;
}

// ❌ Bad - Inconsistent or missing prefixes
enum LoggingMode {
  quickLog,
  manual;
  
  bool get allowsTimeAdjustment => this == LoggingMode.manual;  // Use "can"
  bool get showsOptionalFields => this == LoggingMode.manual;   // Use "should"
  bool get requiresSchedule => this == LoggingMode.quickLog;    // Use "is" + passive
}
```

---

## Serialization & Data Transfer Patterns

### Firestore Document Patterns

When working with Firestore documents, use consistent naming:

```dart
// ✅ Good - Consistent pattern throughout the app
static DeviceToken? fromFirestore(DocumentSnapshot doc) {
  if (!doc.exists) return null;
  
  final tokenData = doc.data() as Map<String, dynamic>?;
  if (tokenData == null) return null;
  
  return DeviceToken(
    deviceId: tokenData['deviceId'] as String?,
    userId: tokenData['userId'] as String?,
    fcmToken: tokenData['fcmToken'] as String?,
  );
}

Map<String, dynamic> toFirestore({bool isUpdate = false}) {
  final tokenData = <String, dynamic>{
    'deviceId': deviceId,
    'userId': userId,
    'fcmToken': fcmToken,
  };
  
  if (!isUpdate) {
    tokenData['createdAt'] = FieldValue.serverTimestamp();
  }
  
  return tokenData;
}

// ❌ Bad - Generic "data" makes debugging harder
static DeviceToken? fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>?;  // Too generic
  return DeviceToken(
    deviceId: data['deviceId'],  // Which data? From where?
  );
}
```

### JSON Serialization Patterns

```dart
// ✅ Good - Context-specific naming
class Schedule {
  factory Schedule.fromJson(Map<String, dynamic> json) {
    final scheduleData = json;  // Or parse complex nested data
    return Schedule(
      id: scheduleData['id'] as String,
      petId: scheduleData['petId'] as String,
    );
  }
}

class NotificationIndex {
  Future<List<Entry>> loadIndex() async {
    final jsonString = await prefs.getString(key);
    final indexData = jsonDecode(jsonString) as Map<String, dynamic>;
    
    // Validate checksum
    if (!_validateChecksum(indexData)) {
      return [];
    }
    
    final entriesJson = indexData['entries'] as List<dynamic>;
    return entriesJson.map((e) => Entry.fromJson(e)).toList();
  }
  
  Future<void> saveIndex(List<Entry> entries) async {
    final indexPayload = {
      'checksum': _computeChecksum(entries),
      'entries': entries.map((e) => e.toJson()).toList(),
    };
    
    final jsonString = jsonEncode(indexPayload);
    await prefs.setString(key, jsonString);
  }
}

// ❌ Bad - Confusing when you have multiple data variables
Future<void> process() async {
  final data = jsonDecode(jsonString);  // Reading
  final data2 = buildPayload();         // Building
  final data3 = transform(data);        // Transforming
  // Which data is which?
}
```

**Pattern:** Use suffixes to distinguish purpose:
- `*Data` for read/deserialized data
- `*Payload` for write/serialized data  
- `*Json` for raw JSON strings
- `*Map` for Map representations

---

## Consistency Within Files & Classes

### The Copy-Paste Test

If you copy a code block and paste it elsewhere in the same file, **variable names should make it obvious what needs to change**.

```dart
// ✅ Good - Easy to spot what needs updating
Future<Schedule?> getSchedule(String scheduleId) async {
  final doc = await _firestore.collection('schedules').doc(scheduleId).get();
  if (!doc.exists) return null;
  
  final scheduleData = doc.data()!;
  scheduleData['id'] = doc.id;
  
  return Schedule.fromJson(scheduleData);
}

Future<List<Schedule>> getAllSchedules(String userId) async {
  final querySnapshot = await _firestore
    .collection('schedules')
    .where('userId', isEqualTo: userId)
    .get();
  
  final schedules = <Schedule>[];
  for (final doc in querySnapshot.docs) {
    final scheduleData = doc.data();
    scheduleData['id'] = doc.id;
    schedules.add(Schedule.fromJson(scheduleData));
  }
  
  return schedules;
}

// ❌ Bad - Easy to mix up when copy-pasting
Future<Schedule?> getSchedule(String scheduleId) async {
  final doc = await _firestore.collection('schedules').doc(scheduleId).get();
  final data = doc.data()!;  // Generic name
  return Schedule.fromJson(data);
}

Future<List<Medication>> getAllMedications(String userId) async {
  final doc = await _firestore  // Wrong! Should be querySnapshot
    .collection('medications')
    .where('userId', isEqualTo: userId)
    .get();
  
  final data = doc.data();  // Will fail - querySnapshot doesn't have .data()
  return Medication.fromJson(data);  // Bug introduced by copy-paste
}
```

### Consistency Across Related Methods

When methods work with the same data, use consistent naming:

```dart
// ✅ Good - Consistent naming across lifecycle
class OnboardingService {
  Future<OnboardingData?> loadOnboardingData(String userId) async {
    final dataJson = await _prefs.getString('onboarding_data_$userId');
    if (dataJson == null) return null;
    
    final onboardingData = OnboardingData.fromJson(dataJson);
    return onboardingData;
  }
  
  Future<void> saveOnboardingData(String userId, OnboardingData data) async {
    final onboardingData = data;  // Consistent with load
    final dataJson = jsonEncode(onboardingData.toJson());
    await _prefs.setString('onboarding_data_$userId', dataJson);
  }
  
  Future<void> clearOnboardingData(String userId) async {
    await _prefs.remove('onboarding_data_$userId');
  }
}

// ❌ Bad - Inconsistent naming makes pattern unclear
Future<OnboardingData?> loadOnboardingData(String userId) async {
  final json = await _prefs.getString('onboarding_data_$userId');
  final data = OnboardingData.fromJson(json);  // Called "data"
  return data;
}

Future<void> saveOnboardingData(String userId, OnboardingData data) async {
  final info = data;  // Now called "info"? Why?
  final str = jsonEncode(info.toJson());  // Now called "str"?
  await _prefs.setString('onboarding_data_$userId', str);
}
```

---

## Context-Dependent Naming Guidelines

### When to Add Context

Add context to variable names when:

#### 1. Multiple Similar Variables in Same Scope

```dart
// ✅ Good - Disambiguation needed
Future<void> syncUserAndPet(String userId, String petId) async {
  final userDoc = await _firestore.collection('users').doc(userId).get();
  final petDoc = await _firestore.collection('pets').doc(petId).get();
  
  final userData = userDoc.data();
  final petData = petDoc.data();
  
  // Clear which data belongs to which entity
}

// ❌ Bad - Confusing
Future<void> syncUserAndPet(String userId, String petId) async {
  final doc1 = await _firestore.collection('users').doc(userId).get();
  final doc2 = await _firestore.collection('pets').doc(petId).get();
  
  final data1 = doc1.data();  // Which is which?
  final data2 = doc2.data();
}
```

#### 2. Similar Methods in Same File

```dart
// ✅ Good - Context prevents confusion
class SummaryService {
  Future<DailySummary?> getDailySummary() {
    final dailySummaryData = ...;
  }
  
  Future<WeeklySummary?> getWeeklySummary() {
    final weeklySummaryData = ...;
  }
  
  Future<MonthlySummary?> getMonthlySummary() {
    final monthlySummaryData = ...;
  }
}
```

#### 3. Long-Lived Variables

```dart
// ✅ Good - Clear throughout entire function
Future<void> processComplexWorkflow() async {
  final scheduleData = await fetchSchedule();  // Used 50 lines later
  
  // ... lots of code ...
  
  await saveSchedule(scheduleData);  // Still clear what this is
}
```

### When Context Is Optional

You can omit context when:

#### 1. Very Short Scope

```dart
// ✅ Good - Scope is tiny, context obvious
final items = list.where((item) => item.isActive).toList();

// Acceptable when short
final data = jsonDecode(jsonString);
return Schedule.fromJson(data);  // Immediately used
```

#### 2. Type Makes It Obvious

```dart
// ✅ Good - Type annotation provides context
Future<void> updateProfile(Profile profile) async {
  final json = profile.toJson();  // Obviously profile JSON
  await _firestore.collection('profiles').doc(profile.id).set(json);
}
```

#### 3. Single Entity in Scope

```dart
// ✅ Good - Only one "schedule" in this method
Future<void> saveSchedule(Schedule schedule) async {
  final doc = _firestore.collection('schedules').doc(schedule.id);
  final data = schedule.toFirestore();  // Obviously schedule data
  await doc.set(data);
}
```

---

## Safe Refactoring Process

### Before You Start

1. **Run tests** to establish baseline: `flutter test`
2. **Check for lint errors**: `flutter analyze`
3. **Search for all usages** of the identifier: Use IDE's "Find Usages" or `grep`
4. **Verify search results** include all variants (getters, setters, constructors)

### During Refactoring

1. **Rename systematically** - don't skip any occurrences
2. **Update related names** - if you rename `data` to `scheduleData`, update related variables
3. **Fix line lengths** - longer names may exceed 80-character limit
4. **Update comments** that reference old names
5. **Check git diff** to ensure changes are what you expect

### After Refactoring

1. **Run analyzer** again: `flutter analyze` should show 0 issues
2. **Run tests**: `flutter test` - no new failures
3. **Check imports** - ensure refactored names didn't break imports
4. **Spot-check** hot reload in app - verify no runtime errors
5. **Review git diff** one more time before committing

### Refactoring Strategy

```bash
# 1. Audit phase - find all instances
grep -r "final data = " lib/

# 2. Categorize by priority
# High: Multiple in same file, confusing context
# Medium: Single usage but unclear
# Low: Very short scope, clear from context

# 3. Refactor file by file
# - Keeps git history clean
# - Easier to review
# - Safer to test incrementally

# 4. Verify after each file
flutter analyze
flutter test <specific_test_file>
```

### Common Pitfalls

❌ **Don't rename too many things at once**
- Refactor one category at a time (booleans, then methods, then variables)
- Commit after each category

❌ **Don't forget test files**
- Tests often have similar variable names
- Update test descriptions to match refactored code

❌ **Don't ignore line length warnings**
```dart
// Before: 72 characters
final data = DailySummary.fromJson(dailySummaryData as Map<String, dynamic>);

// After: 87 characters - exceeds limit!
final summary = DailySummary.fromJson(dailySummaryData as Map<String, dynamic>);

// Fixed: Break the line
final summary =
    DailySummary.fromJson(dailySummaryData as Map<String, dynamic>);
```

---

## Trade-offs & Decision Making

### Clarity vs. Brevity

**Guiding Principle:** When in doubt, choose clarity over brevity.

```dart
// ✅ Preferred - Clear but longer
final weeklySummaryData = docSnapshot.data();

// ⚠️ Acceptable in very short scope
final data = docSnapshot.data();
return Summary.fromJson(data);  // Immediately used

// ❌ Never acceptable - ambiguous
final d = docSnapshot.data();
final info = docSnapshot.data();
```

### When Longer Names Are Worth It

Longer names are **always** worth it when:

1. **Variable lives >10 lines** - Future you will thank present you
2. **Multiple similar variables exist** - Prevents confusion and bugs
3. **Debugging will be easier** - Stack traces show meaningful names
4. **Code is copy-pasted often** - Makes differences obvious
5. **Async/await involved** - Harder to trace flow, need clear names

### Performance Considerations

**Good news:** Variable name length has **zero** impact on:
- Runtime performance (names are stripped in compilation)
- App bundle size (names are minified in release builds)
- Memory usage (names don't exist at runtime)

**Only impact:** Slightly longer compile times (negligible) and code readability (massively positive).

---

## Team Guidelines

### Code Review Focus

When reviewing code, check for:

1. ✅ **Boolean variables** use proper prefixes
2. ✅ **Generic names** like `data`, `value`, `temp` are contextualized
3. ✅ **Method names** clearly describe what they do
4. ✅ **Consistency** within files and related classes
5. ✅ **Searchability** - can you grep for this identifier effectively?

### New Developer Onboarding

For developers new to the project:

1. **Read this document** before writing code
2. **Review existing code** for patterns (especially services and models)
3. **Ask questions** if a naming pattern seems unclear
4. **Suggest improvements** if you find confusing names

### When to Deviate

It's okay to deviate from these guidelines when:

1. **Flutter framework** uses different conventions (follow Flutter's lead)
2. **Third-party packages** require specific names (API contracts)
3. **Generated code** dictates names (json_serializable, freezed, etc.)
4. **Performance-critical** code needs micro-optimization (rare)

**Always comment why** you're deviating:

```dart
// ignore: avoid_generic_variable_name
// Using "data" to match Firestore DocumentSnapshot API
final data = doc.data();
```

---

## Quick Reference

### Most Common Patterns

```dart
// Boolean getters
bool get isX => ...     // State/identity
bool get hasX => ...    // Possession/existence  
bool get shouldX => ... // Conditional decisions
bool get canX => ...    // Permissions/capabilities
bool get wasX => ...    // Past actions

// Async methods
Future<T> getX()        // Retrieve single item
Future<List<T>> fetchX() // Retrieve multiple items
Future<void> saveX()    // Persist changes
Future<void> updateX()  // Modify existing
Future<void> deleteX()  // Remove item

// Sync methods
void setX()            // Assign value
void clearX()          // Remove/reset
void initializeX()     // Set up initial state
```

### Anti-Patterns to Avoid

❌ Generic: `data`, `value`, `temp`, `flag`, `check`, `result`
❌ Abbreviations: `notif`, `sched`, `auth`, `msg`
❌ Missing prefixes: `loading` (should be `isLoading`)
❌ Wrong prefix: `hasLoading` (should be `isLoading`)
❌ Double negatives: `isNotDisabled` (should be `isEnabled`)

---

## Maintenance

This document should be:
- **Reviewed**: Before starting new features
- **Updated**: When new patterns emerge
- **Referenced**: During code reviews
- **Shared**: With all team members

**Last Review Date**: October 31, 2025
**Next Review Date**: [Set based on team cadence]

---

## Document History

### October 31, 2025 - Major Update
Added comprehensive sections based on real refactoring work:
- **Real-World Examples**: 4 examples from actual codebase showing before/after
- **Serialization Patterns**: Firestore/JSON naming conventions with `*Data`, `*Payload`, `*Json` suffixes
- **Consistency Guidelines**: The "Copy-Paste Test" and consistency across related methods
- **Context-Dependent Naming**: When to add context vs. when it's optional
- **Safe Refactoring Process**: Step-by-step workflow with audit, categorize, refactor, verify phases
- **Trade-offs & Decision Making**: Clarity vs. brevity, performance considerations
- **Team Guidelines**: Code review focus, onboarding checklist, when to deviate

These additions make the document more practical and actionable for developers who are new to the project or Flutter/Dart in general.

