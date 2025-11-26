# HydraCat  New Symptom Tracking System (Hybrid Model)
## Implementation Plan

---

## Overview

Replace the current 0-10 uniform symptom scale with a **Hybrid Symptom Scoring Model** that provides:
- **User-facing input**: Tailored, medically accurate inputs per symptom (episodes, stool quality, appetite fraction, etc.)
- **Internal unified severity**: All symptoms normalized to 0-3 scale for consistent analytics and visualization

This aligns with the specification in `.cursor/reference/HydraCat_Symptom_Tracking_Spec.md` while maintaining the existing architecture patterns, cost-efficient Firestore operations, and chart infrastructure.

---

## Key Design Decisions

Based on clarification, the implementation follows these principles:

1. **Data Structure**: Single document per day with nested `{rawValue, severityScore}` structure per symptom
2. **Backward Compatibility**: Clean-slate implementation (no migration logic)
3. **Symptom Renaming**: "lethargy" � "energy" with inverted semantics
4. **Raw Value Types**: Typed model with per-symptom conversion functions
5. **Notes Placement**: Per-day notes (not per-symptom)
6. **Appetite Handling**: Keep separate `HealthParameter.appetite` field + symptom tracking
7. **Chart Strategy**: Hybrid approach - Week/Month views use severity scores (0-3) as segment heights, Year view uses frequency (day counts)
8. **Entry UI**: Number input for vomiting, segmented controls for enum-based symptoms
9. **Summary Storage**: Keep boolean flags + max severity scores
10. **Colors**: Keep existing `SymptomColors` palette (update only for energy if needed)

---

## Coherence & Constraints

### Alignment with PRD
- **Symptom Check-ins**: Direct implementation of comprehensive CKD monitoring requirements
- **Veterinary-Grade Quality**: Medically accurate inputs (episodes, stool quality) provide professional-ready data
- **Reduce Caregiver Stress**: Intuitive, symptom-specific inputs reduce cognitive load vs. abstract 0-10 scales

### Alignment with CRUD Rules
- **One doc per day**: Maintains `healthParameters/{YYYY-MM-DD}` pattern (no extra reads)
- **Summary-first analytics**: Charts use pre-aggregated daily/weekly/monthly summaries
- **Batched writes**: 4-doc batch (healthParameter + 3 summaries) unchanged
- **Cost profile**: Same read/write costs as current implementation

### Alignment with Existing Architecture
- **Reuses patterns**: Mirrors weight tracking and logging service patterns
- **Provider structure**: Existing `SymptomsService`, chart providers, and state management
- **UI components**: `LoggingPopupWrapper`, `HydraSlidingSegmentedControl`, number inputs
- **Chart infrastructure**: Stacked bar chart, buckets, and granularity system remain unchanged

---

## Phase 1  Data Model & Schema Updates

### Step 1.1: Create Symptom Data Models

**Objective**: Define typed models for symptom entries with rawValue + severityScore structure.

**Location**: `lib/features/health/models/`

**Files to Create**:

#### `symptom_entry.dart` - Core symptom entry model
```dart
import 'package:flutter/foundation.dart';

/// Represents a single symptom entry with raw value and computed severity
///
/// The raw value type varies by symptom:
/// - Vomiting: int (number of episodes, 0-10+)
/// - Diarrhea/Constipation/InjectionSite/Energy: String (enum value)
/// - Appetite: String (enum value)
///
/// Severity is always 0-3 for consistent analytics.
@immutable
class SymptomEntry {
  const SymptomEntry({
    required this.symptomType,
    required this.rawValue,
    required this.severityScore,
  });

  /// Factory constructor from JSON (Firestore format)
  factory SymptomEntry.fromJson(String symptomType, Map<String, dynamic> json) {
    return SymptomEntry(
      symptomType: symptomType,
      rawValue: json['rawValue'],
      severityScore: (json['severityScore'] as num).toInt(),
    );
  }

  /// Symptom type key (vomiting, diarrhea, etc.)
  final String symptomType;

  /// Raw user-entered value (int for vomiting, String for others)
  final dynamic rawValue;

  /// Computed severity score (0-3)
  final int severityScore;

  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'rawValue': rawValue,
      'severityScore': severityScore,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomEntry &&
          other.symptomType == symptomType &&
          other.rawValue == rawValue &&
          other.severityScore == severityScore;

  @override
  int get hashCode => Object.hash(symptomType, rawValue, severityScore);

  @override
  String toString() {
    return 'SymptomEntry(type: $symptomType, raw: $rawValue, severity: $severityScore)';
  }
}
```

#### `symptom_raw_value.dart` - Enum definitions for raw values
```dart
/// Enum for diarrhea stool quality
enum DiarrheaQuality {
  normal('Normal'),
  soft('Soft'),
  loose('Loose'),
  watery('Watery / liquid');

  const DiarrheaQuality(this.label);
  final String label;

  /// Convert to/from string for Firestore storage
  static DiarrheaQuality fromString(String value) {
    return DiarrheaQuality.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DiarrheaQuality.normal,
    );
  }
}

/// Enum for constipation straining level
enum ConstipationLevel {
  normal('Normal stooling'),
  mildStraining('Mild straining'),
  noStool('No stool'),
  painful('Painful/crying');

  const ConstipationLevel(this.label);
  final String label;

  static ConstipationLevel fromString(String value) {
    return ConstipationLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ConstipationLevel.normal,
    );
  }
}

/// Enum for appetite fraction
enum AppetiteFraction {
  all('All'),
  threeQuarters('�'),
  half('�'),
  quarter('�'),
  nothing('Nothing');

  const AppetiteFraction(this.label);
  final String label;

  static AppetiteFraction fromString(String value) {
    return AppetiteFraction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppetiteFraction.all,
    );
  }
}

/// Enum for injection site reaction
enum InjectionSiteReaction {
  none('None'),
  mildSwelling('Mild swelling'),
  visibleSwelling('Visible swelling'),
  redPainful('Red & painful');

  const InjectionSiteReaction(this.label);
  final String label;

  static InjectionSiteReaction fromString(String value) {
    return InjectionSiteReaction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InjectionSiteReaction.none,
    );
  }
}

/// Enum for energy level
enum EnergyLevel {
  normal('Normal energy'),
  slightlyReduced('Slightly reduced energy'),
  low('Low energy'),
  veryLow('Very low energy');

  const EnergyLevel(this.label);
  final String label;

  static EnergyLevel fromString(String value) {
    return EnergyLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EnergyLevel.normal,
    );
  }
}
```

**Implementation Notes**:
- Use `@immutable` for all models
- Enums store as `name` in Firestore (e.g., `"soft"`, not `"Soft"`)
- Proper `==`, `hashCode`, `toString` implementations
- Safe defaults in `fromString` methods

---

### Step 1.2: Update SymptomType Constants

**Objective**: Rename "lethargy" � "energy" throughout the codebase.

**Location**: `lib/features/health/models/symptom_type.dart`

**Changes**:
```dart
class SymptomType {
  // ... existing constants ...

  /// Energy level symptom (formerly lethargy)
  static const String energy = 'energy';  // Changed from 'lethargy'

  /// List of all valid symptom type keys
  static const List<String> all = [
    vomiting,
    diarrhea,
    constipation,
    energy,  // Changed from lethargy
    suppressedAppetite,
    injectionSiteReaction,
  ];
}
```

**Global Find & Replace**:
- Find: `SymptomType.lethargy` � Replace: `SymptomType.energy`
- Find: `'lethargy'` (in symptom context) � Replace: `'energy'`
- Find: `hadLethargy` � Replace: `hadEnergy` (in summary models)
- Find: `lethargyMaxScore` � Replace: `energyMaxScore`
- Find: `daysWithLethargy` � Replace: `daysWithEnergy`

**Files to Update**:
- `lib/features/health/models/symptom_type.dart` 
- `lib/shared/models/daily_summary.dart`
- `lib/shared/models/weekly_summary.dart`
- `lib/shared/models/monthly_summary.dart`
- `lib/core/constants/symptom_colors.dart`
- `lib/features/health/services/symptoms_service.dart`
- `lib/features/health/widgets/symptoms_entry_dialog.dart`
- `lib/features/health/widgets/symptoms_stacked_bar_chart.dart`
- `lib/providers/symptoms_chart_provider.dart`
- All test files referencing lethargy

**Semantic Note**:
- Old: High score = more lethargic (0 = normal, 10 = very lethargic)
- New: High score = lower energy (0 = normal energy, 3 = very low energy)
- Both use "higher number = worse condition" so chart behavior remains consistent

**Status**: ✅ **COMPLETED**
- All `SymptomType` constants updated to use `energy` instead of `lethargy`
- All summary models updated (`hadEnergy`, `energyMaxScore`, `daysWithEnergy`)
- `SymptomColors` updated to reference `SymptomType.energy`
- Core codebase references updated throughout services, widgets, and providers
- Test files updated to use new naming (minor variable name updates may remain but core functionality complete)

---

### Step 1.3: Update HealthParameter Model

**Objective**: Change symptoms map structure from `Map<String, int>` to `Map<String, SymptomEntry>`.

**Location**: `lib/features/health/models/health_parameter.dart`

**Current Structure**:
```dart
symptoms: {
  "vomiting": 3,           // int (0-10)
  "diarrhea": 5,           // int (0-10)
}
```

**New Structure**:
```dart
symptoms: {
  "vomiting": {
    "rawValue": 3,         // int episodes
    "severityScore": 3     // 0-3 scale
  },
  "diarrhea": {
    "rawValue": "loose",   // enum string
    "severityScore": 2     // 0-3 scale
  }
}
```

**Implementation (Done)**:

1. **Change field type**:
```dart
/// Per-symptom entries with raw values and severity scores (optional)
/// Map of symptom type keys to SymptomEntry objects
/// Keys: vomiting, diarrhea, constipation, energy,
/// suppressedAppetite, injectionSiteReaction
final Map<String, SymptomEntry>? symptoms;
```

2. **Update factory constructor**:
```dart
factory HealthParameter.create({
  required DateTime date,
  double? weight,
  String? appetite,
  Map<String, SymptomEntry>? symptoms,  // Changed type
  String? notes,
}) {
  // Compute derived fields using severityScore from each entry
  final hasSymptoms = _computeHasSymptoms(symptoms);
  final symptomScoreTotal = _computeSymptomScoreTotal(symptoms);
  final symptomScoreAverage = _computeSymptomScoreAverage(symptoms);

  return HealthParameter(
    date: DateTime(date.year, date.month, date.day),
    weight: weight,
    appetite: appetite,
    symptoms: symptoms,
    hasSymptoms: hasSymptoms,
    symptomScoreTotal: symptomScoreTotal,
    symptomScoreAverage: symptomScoreAverage,
    notes: notes,
    createdAt: DateTime.now(),
  );
}
```

3. **Update helper methods** (use `severityScore` instead of raw int):
```dart
static bool? _computeHasSymptoms(Map<String, SymptomEntry>? symptoms) {
  if (symptoms == null || symptoms.isEmpty) return false;
  return symptoms.values.any((entry) => entry.severityScore > 0);
}

static int? _computeSymptomScoreTotal(Map<String, SymptomEntry>? symptoms) {
  if (symptoms == null || symptoms.isEmpty) return null;
  return symptoms.values.fold<int>(
    0,
    (total, entry) => total + entry.severityScore,
  );
}

static double? _computeSymptomScoreAverage(Map<String, SymptomEntry>? symptoms) {
  if (symptoms == null || symptoms.isEmpty) return null;
  final entries = symptoms.values.toList();
  if (entries.isEmpty) return null;
  final total = entries.fold<int>(0, (acc, entry) => acc + entry.severityScore);
  return total / entries.length;
}
```

4. **Update fromFirestore**:
```dart
factory HealthParameter.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>?;
  if (data == null) {
    throw ArgumentError('Document data is null');
  }

  // Parse symptoms map (new nested structure)
  Map<String, SymptomEntry>? symptomsMap;
  if (data['symptoms'] != null && data['symptoms'] is Map) {
    final symptomsData = data['symptoms'] as Map<String, dynamic>;
    final result = <String, SymptomEntry>{};
    for (final entry in symptomsData.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        result[entry.key] = SymptomEntry.fromJson(
          entry.key,
          value,
        );
      } else if (value is Map) {
        // Fallback for Map<dynamic, dynamic> from Firestore
        result[entry.key] = SymptomEntry.fromJson(
          entry.key,
          Map<String, dynamic>.from(value as Map),
        );
      }
    }
    if (result.isNotEmpty) {
      symptomsMap = result;
    }
  }

  return HealthParameter(
    // ... existing fields ...
    symptoms: symptomsMap,
    // ... rest of fields ...
  );
}
```

5. **Update toJson**:
```dart
Map<String, dynamic> toJson() {
  // Serialize symptoms map with nested structure
  Map<String, dynamic>? symptomsJson;
  final symptomsValue = symptoms;
  if (symptomsValue != null && symptomsValue.isNotEmpty) {
    symptomsJson = <String, dynamic>{};
    for (final entry in symptomsValue.entries) {
      symptomsJson[entry.key] = entry.value.toJson();
    }
  }

  return {
    'date': Timestamp.fromDate(date),
    if (weight != null) 'weight': weight,
    if (appetite != null) 'appetite': appetite,
    if (symptomsJson != null) 'symptoms': symptomsJson,
    if (hasSymptoms != null) 'hasSymptoms': hasSymptoms,
    if (symptomScoreTotal != null) 'symptomScoreTotal': symptomScoreTotal,
    if (symptomScoreAverage != null) 'symptomScoreAverage': symptomScoreAverage,
    if (notes != null) 'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
  };
}
```

6. **Update equality check**:
```dart
static bool _mapEquals(Map<String, SymptomEntry>? a, Map<String, SymptomEntry>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (a[key] != b[key]) return false;
  }
  return true;
}
```

**Note**: No changes needed to `symptomScoreTotal` or `symptomScoreAverage` fields - they still use 0-3 severity scores, just computed from the new structure.

---

### Step 1.4: Update Summary Models (Daily/Weekly/Monthly)

**Objective**: Rename lethargy fields to energy in all summary models.

**Locations**:
- `lib/shared/models/daily_summary.dart`
- `lib/shared/models/weekly_summary.dart`
- `lib/shared/models/monthly_summary.dart`

**Changes Required**:

#### DailySummary
```dart
// Rename fields:
this.hadEnergy = false,              // was hadLethargy
this.energyMaxScore,                 // was lethargyMaxScore

// Constructor params:
bool hadEnergy = false,
int? energyMaxScore,

// fromJson:
hadEnergy: asBool(json['hadEnergy']),
energyMaxScore: (json['energyMaxScore'] as num?)?.toInt(),

// toJson:
'hadEnergy': hadEnergy,
if (energyMaxScore != null) 'energyMaxScore': energyMaxScore,
```

#### WeeklySummary & MonthlySummary
```dart
// Rename fields:
this.daysWithEnergy = 0,             // was daysWithLethargy

// Constructor params:
int daysWithEnergy = 0,

// fromJson:
daysWithEnergy: (json['daysWithEnergy'] as num?)?.toInt() ?? 0,

// toJson:
'daysWithEnergy': daysWithEnergy,
```

**Important**: Update `copyWith`, `==`, `hashCode`, and `toString` methods in all three models.

**Max Score Semantics**:
- Max severity still stored (0-3 scale)
- Higher score = worse condition (consistent with current implementation)
- No semantic changes needed beyond renaming

**Status**: ✅ **COMPLETED**
- `DailySummary`, `WeeklySummary`, and `MonthlySummary` now use `hadEnergy`, `energyMaxScore`, and `daysWithEnergy` consistently in fields, constructors, JSON, and helpers.
- `SymptomsService` and symptom bucket/chart tests have been updated to rely on the new energy fields and 0-3 severity semantics.

---

### Step 1.5: Update Firestore Schema Documentation

**Objective**: Document the new nested symptom structure and energy field rename.

**Location**: `.cursor/rules/firestore_schema.md`

**Update healthParameters section**:
```yaml
symptoms: map # optional, per-symptom entries with raw values and severity
  vomiting: map
    rawValue: number # number of episodes (0-10+)
    severityScore: number # severity 0-3
  diarrhea: map
    rawValue: string # enum: "normal", "soft", "loose", "watery"
    severityScore: number # severity 0-3
  constipation: map
    rawValue: string # enum: "normal", "mildStraining", "noStool", "painful"
    severityScore: number # severity 0-3
  energy: map # renamed from lethargy
    rawValue: string # enum: "normal", "slightlyReduced", "low", "veryLow"
    severityScore: number # severity 0-3
  suppressedAppetite: map
    rawValue: string # enum: "all", "threeQuarters", "half", "quarter", "nothing"
    severityScore: number # severity 0-3
  injectionSiteReaction: map
    rawValue: string # enum: "none", "mildSwelling", "visibleSwelling", "redPainful"
    severityScore: number # severity 0-3
```

**Update summary sections**: Replace all `hadLethargy`/`lethargyMaxScore`/`daysWithLethargy` with energy equivalents.

**Status**: ✅ **COMPLETED**
- `healthParameters` symptoms section updated to document nested `rawValue` + `severityScore` structure for all six symptoms.
- Daily/weekly/monthly summary sections updated to use `hadEnergy`, `energyMaxScore`, and `daysWithEnergy` fields.
- All score ranges updated from 0-10 to 0-3 severity scale throughout the documentation.
- Added "Hybrid Symptom Tracking Model" section to Design Notes explaining the rawValue + severityScore approach.
- Implementation status updated to show `healthParameters` as fully implemented.

---

## Phase 2  Symptom Conversion Logic

### Step 2.1: Create Severity Conversion Functions

**Objective**: Implement pure conversion functions mapping raw values � severity scores (0-3).

**Location**: `lib/features/health/services/symptom_severity_converter.dart` (new file)

**Implementation**:
```dart
/// Pure functions for converting raw symptom values to 0-3 severity scores
///
/// Each symptom type has a dedicated conversion function following the
/// medical guidelines in the spec.
class SymptomSeverityConverter {
  SymptomSeverityConverter._(); // Prevent instantiation

  /// Convert vomiting episodes to severity (0-3)
  ///
  /// Conversion table:
  /// - 0 episodes � 0 (none)
  /// - 1 episode � 1 (mild)
  /// - 2 episodes � 2 (moderate)
  /// - e3 episodes � 3 (severe)
  static int vomitingToSeverity(int episodes) {
    if (episodes <= 0) return 0;
    if (episodes == 1) return 1;
    if (episodes == 2) return 2;
    return 3; // 3 or more
  }

  /// Convert diarrhea quality to severity (0-3)
  ///
  /// Conversion table:
  /// - normal � 0
  /// - soft � 1
  /// - loose � 2
  /// - watery � 3
  static int diarrheaToSeverity(DiarrheaQuality quality) {
    return switch (quality) {
      DiarrheaQuality.normal => 0,
      DiarrheaQuality.soft => 1,
      DiarrheaQuality.loose => 2,
      DiarrheaQuality.watery => 3,
    };
  }

  /// Convert constipation level to severity (0-3)
  ///
  /// Conversion table:
  /// - normal � 0
  /// - mildStraining � 1
  /// - noStool � 2
  /// - painful � 3
  static int constipationToSeverity(ConstipationLevel level) {
    return switch (level) {
      ConstipationLevel.normal => 0,
      ConstipationLevel.mildStraining => 1,
      ConstipationLevel.noStool => 2,
      ConstipationLevel.painful => 3,
    };
  }

  /// Convert appetite fraction to severity (0-3)
  ///
  /// Conversion table:
  /// - all � 0
  /// - � � 1
  /// - � � 2
  /// - � or nothing � 3
  static int appetiteToSeverity(AppetiteFraction fraction) {
    return switch (fraction) {
      AppetiteFraction.all => 0,
      AppetiteFraction.threeQuarters => 1,
      AppetiteFraction.half => 2,
      AppetiteFraction.quarter => 3,
      AppetiteFraction.nothing => 3,
    };
  }

  /// Convert injection site reaction to severity (0-3)
  ///
  /// Conversion table:
  /// - none � 0
  /// - mildSwelling � 1
  /// - visibleSwelling � 2
  /// - redPainful � 3
  static int injectionSiteToSeverity(InjectionSiteReaction reaction) {
    return switch (reaction) {
      InjectionSiteReaction.none => 0,
      InjectionSiteReaction.mildSwelling => 1,
      InjectionSiteReaction.visibleSwelling => 2,
      InjectionSiteReaction.redPainful => 3,
    };
  }

  /// Convert energy level to severity (0-3)
  ///
  /// Conversion table:
  /// - normal � 0
  /// - slightlyReduced � 1
  /// - low � 2
  /// - veryLow � 3
  static int energyToSeverity(EnergyLevel level) {
    return switch (level) {
      EnergyLevel.normal => 0,
      EnergyLevel.slightlyReduced => 1,
      EnergyLevel.low => 2,
      EnergyLevel.veryLow => 3,
    };
  }

  /// Create a SymptomEntry from raw value, automatically computing severity
  ///
  /// This is the main public API for creating symptom entries.
  static SymptomEntry createEntry({
    required String symptomType,
    required dynamic rawValue,
  }) {
    final severity = _computeSeverity(symptomType, rawValue);
    return SymptomEntry(
      symptomType: symptomType,
      rawValue: rawValue,
      severityScore: severity,
    );
  }

  /// Internal: Compute severity from raw value based on symptom type
  static int _computeSeverity(String symptomType, dynamic rawValue) {
    switch (symptomType) {
      case SymptomType.vomiting:
        return vomitingToSeverity(rawValue as int);
      case SymptomType.diarrhea:
        final quality = rawValue is String
            ? DiarrheaQuality.fromString(rawValue)
            : rawValue as DiarrheaQuality;
        return diarrheaToSeverity(quality);
      case SymptomType.constipation:
        final level = rawValue is String
            ? ConstipationLevel.fromString(rawValue)
            : rawValue as ConstipationLevel;
        return constipationToSeverity(level);
      case SymptomType.suppressedAppetite:
        final fraction = rawValue is String
            ? AppetiteFraction.fromString(rawValue)
            : rawValue as AppetiteFraction;
        return appetiteToSeverity(fraction);
      case SymptomType.injectionSiteReaction:
        final reaction = rawValue is String
            ? InjectionSiteReaction.fromString(rawValue)
            : rawValue as InjectionSiteReaction;
        return injectionSiteToSeverity(reaction);
      case SymptomType.energy:
        final level = rawValue is String
            ? EnergyLevel.fromString(rawValue)
            : rawValue as EnergyLevel;
        return energyToSeverity(level);
      default:
        throw ArgumentError('Unknown symptom type: $symptomType');
    }
  }
}
```

**Testing**:
- Unit test all conversion functions with boundary cases
- Verify severity always in 0-3 range
- Test `createEntry` with all symptom types

---

### Step 2.2: Unit Tests for Conversion Logic

**Location**: `test/features/health/services/symptom_severity_converter_test.dart`

**Test Coverage**:
```dart
void main() {
  group('SymptomSeverityConverter', () {
    group('vomitingToSeverity', () {
      test('returns 0 for 0 episodes', () {
        expect(SymptomSeverityConverter.vomitingToSeverity(0), 0);
      });

      test('returns 1 for 1 episode', () {
        expect(SymptomSeverityConverter.vomitingToSeverity(1), 1);
      });

      test('returns 2 for 2 episodes', () {
        expect(SymptomSeverityConverter.vomitingToSeverity(2), 2);
      });

      test('returns 3 for 3+ episodes', () {
        expect(SymptomSeverityConverter.vomitingToSeverity(3), 3);
        expect(SymptomSeverityConverter.vomitingToSeverity(5), 3);
        expect(SymptomSeverityConverter.vomitingToSeverity(10), 3);
      });
    });

    // Similar groups for each symptom type...

    group('createEntry', () {
      test('creates vomiting entry with correct severity', () {
        final entry = SymptomSeverityConverter.createEntry(
          symptomType: SymptomType.vomiting,
          rawValue: 2,
        );
        expect(entry.severityScore, 2);
        expect(entry.rawValue, 2);
      });

      test('creates diarrhea entry from enum', () {
        final entry = SymptomSeverityConverter.createEntry(
          symptomType: SymptomType.diarrhea,
          rawValue: DiarrheaQuality.soft,
        );
        expect(entry.severityScore, 1);
      });

      test('creates diarrhea entry from string', () {
        final entry = SymptomSeverityConverter.createEntry(
          symptomType: SymptomType.diarrhea,
          rawValue: 'soft',
        );
        expect(entry.severityScore, 1);
      });

      // Test all symptom types...
    });
  });
}
```

**Status**: ✅ **COMPLETED**
- `SymptomSeverityConverter` class created with all 6 conversion functions
- Comprehensive unit tests created with 49 test cases covering all conversion methods and boundary conditions
- All tests pass successfully
- No linter errors or warnings
- Code follows existing patterns and includes proper documentation

---

## Phase 3  Service Layer Updates

**Status**: ✅ **COMPLETED**
- `SymptomsService.saveSymptoms` updated to accept `Map<String, SymptomEntry>?`
- Validation logic updated to validate 0-3 severity range
- Daily summary builder uses `severityScore` from `SymptomEntry`
- Analytics events updated to work with new structure
- Comprehensive unit tests created (14 test cases)
- All tests pass successfully
- Fixed variable naming (`oldHadLethargy` → `oldHadEnergy`)

### Step 3.1: Update SymptomsService

**Objective**: Adapt service to work with new SymptomEntry structure.

**Location**: `lib/features/health/services/symptoms_service.dart`

**Key Changes**:

1. **Update method signature**:
```dart
Future<void> saveSymptoms({
  required String userId,
  required String petId,
  required DateTime date,
  Map<String, SymptomEntry>? symptoms,  // Changed type
  String? notes,
}) async {
  // ... validation ...

  // Create HealthParameter (uses new structure)
  final healthParam = HealthParameter.create(
    date: date,
    symptoms: symptoms,
    notes: notes,
  );

  // ... rest of method unchanged ...
}
```

2. **Update validation** (no changes needed - severity is pre-computed):
```dart
void _validateSymptomScores(Map<String, SymptomEntry>? symptoms) {
  if (symptoms == null) return;
  for (final entry in symptoms.entries) {
    final severity = entry.value.severityScore;
    if (severity < 0 || severity > 3) {  // Changed from 0-10 to 0-3
      throw SymptomValidationException(
        'Severity score must be 0-3, got: $severity for ${entry.key}',
      );
    }
  }
}
```

3. **Update daily summary builder** (use severityScore):
```dart
Map<String, dynamic> _buildDailySummaryUpdates(
  HealthParameter newEntry,
  HealthParameter? oldEntry,
  DateTime date,
) {
  final symptoms = newEntry.symptoms ?? {};

  return {
    'date': Timestamp.fromDate(date),
    // Symptom booleans (based on severity > 0)
    'hadVomiting': (symptoms[SymptomType.vomiting]?.severityScore ?? 0) > 0,
    'hadDiarrhea': (symptoms[SymptomType.diarrhea]?.severityScore ?? 0) > 0,
    'hadConstipation': (symptoms[SymptomType.constipation]?.severityScore ?? 0) > 0,
    'hadEnergy': (symptoms[SymptomType.energy]?.severityScore ?? 0) > 0,  // Renamed
    'hadSuppressedAppetite': (symptoms[SymptomType.suppressedAppetite]?.severityScore ?? 0) > 0,
    'hadInjectionSiteReaction': (symptoms[SymptomType.injectionSiteReaction]?.severityScore ?? 0) > 0,

    // Max scores (single day, so max = current severity)
    if (symptoms[SymptomType.vomiting] != null)
      'vomitingMaxScore': symptoms[SymptomType.vomiting]!.severityScore,
    // ... similar for other symptoms, using renamed energy field ...

    // Overall scores
    if (newEntry.symptomScoreTotal != null)
      'symptomScoreTotal': newEntry.symptomScoreTotal,
    if (newEntry.symptomScoreAverage != null)
      'symptomScoreAverage': newEntry.symptomScoreAverage,
    'hasSymptoms': newEntry.hasSymptoms ?? false,

    // Timestamps
    'updatedAt': FieldValue.serverTimestamp(),
    if (oldEntry == null) 'createdAt': FieldValue.serverTimestamp(),
  };
}
```

4. **Update analytics events** (updated to use severityScore):
```dart
// Updated analytics code to work with SymptomEntry:
final symptomMap = finalEntry.symptoms;
final symptomCount = symptomMap?.values
        .where((entry) => entry.severityScore > 0)
        .length ??
    0;
final hasInjectionSiteReaction =
    symptomMap?[SymptomType.injectionSiteReaction] != null &&
    symptomMap![SymptomType.injectionSiteReaction]!.severityScore > 0;

await _analyticsService?.trackFeatureUsed(
  featureName: isNewEntry ? 'symptoms_log_created' : 'symptoms_log_updated',
  additionalParams: {
    'symptom_count': symptomCount,
    if (finalEntry.symptomScoreTotal != null)
      'total_score': finalEntry.symptomScoreTotal,
    'has_injection_site_reaction': hasInjectionSiteReaction,
  },
);
```

**Note**: Delta logic for weekly/monthly summaries remains unchanged - it operates on boolean flags and severity scores, which are still computed the same way.

**Test File Created**: `test/features/health/services/symptoms_service_test.dart`
- 14 comprehensive test cases covering validation, HealthParameter creation, daily summary updates, analytics events, and clearSymptoms
- Uses `fake_cloud_firestore` for Firestore operations
- All tests pass successfully

---

## Phase 4  UI Components (Entry Dialog)

### Step 4.1: Create Symptom Input Widgets

**Objective**: Build tailored input widgets for each symptom type.

**Location**: `lib/features/health/widgets/` (multiple files)

#### File 1: `symptom_number_input.dart` - For vomiting episodes
```dart
/// Number input widget for vomiting episodes
///
/// Allows users to enter 0-10+ episodes with +/- buttons and direct input.
class SymptomNumberInput extends StatelessWidget {
  const SymptomNumberInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.minValue = 0,
    this.maxValue = 99,
    this.enabled = true,
  });

  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;
  final int minValue;
  final int maxValue;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            // N/A toggle
            Checkbox(
              value: value != null,
              onChanged: enabled
                  ? (checked) => onChanged(checked == true ? 0 : null)
                  : null,
            ),
            const Text('N/A'),
            const SizedBox(width: AppSpacing.md),
            if (value != null) ...[
              // Decrement button
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: enabled && value! > minValue
                    ? () => onChanged(value! - 1)
                    : null,
              ),
              // Value display
              SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: value.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  enabled: enabled,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (text) {
                    final parsed = int.tryParse(text);
                    if (parsed != null && parsed >= minValue && parsed <= maxValue) {
                      onChanged(parsed);
                    }
                  },
                ),
              ),
              // Increment button
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: enabled && value! < maxValue
                    ? () => onChanged(value! + 1)
                    : null,
              ),
              Text('episodes', style: AppTextStyles.caption),
            ],
          ],
        ),
      ],
    );
  }
}
```

#### File 2: `symptom_enum_input.dart` - For enum-based symptoms
```dart
/// Enum input widget using segmented control
///
/// Used for diarrhea, constipation, appetite, injection site, and energy.
class SymptomEnumInput<T extends Enum> extends StatelessWidget {
  const SymptomEnumInput({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.getLabel,
    this.enabled = true,
  });

  final String label;
  final T? value;
  final List<T> options;
  final ValueChanged<T?> onChanged;
  final String Function(T) getLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTextStyles.body),
            const SizedBox(width: AppSpacing.sm),
            Checkbox(
              value: value != null,
              onChanged: enabled
                  ? (checked) => onChanged(checked == true ? options.first : null)
                  : null,
            ),
            const Text('N/A', style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (value != null)
          HydraSlidingSegmentedControl<T>(
            value: value!,
            segments: Map.fromEntries(
              options.map((option) => MapEntry(
                option,
                Text(getLabel(option), style: AppTextStyles.caption),
              )),
            ),
            onChanged: enabled ? (newValue) => onChanged(newValue) : null,
          ),
      ],
    );
  }
}
```

**Usage Example**:
```dart
// Vomiting (number input)
SymptomNumberInput(
  label: 'Vomiting',
  value: _vomitingEpisodes,
  onChanged: (value) => setState(() => _vomitingEpisodes = value),
)

// Diarrhea (enum input)
SymptomEnumInput<DiarrheaQuality>(
  label: 'Diarrhea',
  value: _diarrheaQuality,
  options: DiarrheaQuality.values,
  getLabel: (quality) => quality.label,
  onChanged: (value) => setState(() => _diarrheaQuality = value),
)
```

---

### Step 4.2: Rewrite SymptomsEntryDialog

**Status**: ✅ **COMPLETED**

**Objective**: Replace 6 sliders with tailored inputs using new widgets.

**Location**: `lib/features/health/widgets/symptoms_entry_dialog.dart`

**State Fields** (replace `Map<String, int?>` with typed fields):
```dart
class _SymptomsEntryDialogState extends State<SymptomsEntryDialog> {
  late DateTime _selectedDate;
  late TextEditingController _notesController;
  late FocusNode _notesFocusNode;

  // Typed symptom values (null = N/A)
  int? _vomitingEpisodes;
  DiarrheaQuality? _diarrheaQuality;
  ConstipationLevel? _constipationLevel;
  AppetiteFraction? _appetiteFraction;
  InjectionSiteReaction? _injectionSiteReaction;
  EnergyLevel? _energyLevel;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final existingEntry = widget.existingEntry;
    _selectedDate = existingEntry?.date ?? DateTime.now();
    _notesController = TextEditingController(text: existingEntry?.notes ?? '');
    _notesFocusNode = FocusNode();

    // Pre-fill from existing entry
    if (existingEntry?.symptoms != null) {
      final symptoms = existingEntry!.symptoms!;
      _vomitingEpisodes = symptoms[SymptomType.vomiting]?.rawValue as int?;

      final diarrheaRaw = symptoms[SymptomType.diarrhea]?.rawValue;
      if (diarrheaRaw is String) {
        _diarrheaQuality = DiarrheaQuality.fromString(diarrheaRaw);
      }

      // ... similar for other symptoms ...
    }
  }

  // ... dispose, etc. ...
}
```

**Build Method** (replace sliders with new widgets):
```dart
@override
Widget build(BuildContext context) {
  return LoggingPopupWrapper(
    title: widget.existingEntry == null ? 'Log Symptoms' : 'Edit Symptoms',
    onClose: () => OverlayService.hide(),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date selector (unchanged)
          _buildDateSelector(),
          const SizedBox(height: AppSpacing.lg),

          // Vomiting (number input)
          SymptomNumberInput(
            label: 'Vomiting',
            value: _vomitingEpisodes,
            onChanged: (value) => setState(() => _vomitingEpisodes = value),
            enabled: !_isSaving,
          ),
          const SizedBox(height: AppSpacing.md),

          // Diarrhea (enum input)
          SymptomEnumInput<DiarrheaQuality>(
            label: 'Diarrhea',
            value: _diarrheaQuality,
            options: DiarrheaQuality.values,
            getLabel: (quality) => quality.label,
            onChanged: (value) => setState(() => _diarrheaQuality = value),
            enabled: !_isSaving,
          ),
          const SizedBox(height: AppSpacing.md),

          // Constipation (enum input)
          SymptomEnumInput<ConstipationLevel>(
            label: 'Constipation',
            value: _constipationLevel,
            options: ConstipationLevel.values,
            getLabel: (level) => level.label,
            onChanged: (value) => setState(() => _constipationLevel = value),
            enabled: !_isSaving,
          ),
          const SizedBox(height: AppSpacing.md),

          // Energy (enum input)
          SymptomEnumInput<EnergyLevel>(
            label: 'Energy',
            value: _energyLevel,
            options: EnergyLevel.values,
            getLabel: (level) => level.label,
            onChanged: (value) => setState(() => _energyLevel = value),
            enabled: !_isSaving,
          ),
          const SizedBox(height: AppSpacing.md),

          // Suppressed Appetite (enum input)
          SymptomEnumInput<AppetiteFraction>(
            label: 'Appetite',
            value: _appetiteFraction,
            options: AppetiteFraction.values,
            getLabel: (fraction) => fraction.label,
            onChanged: (value) => setState(() => _appetiteFraction = value),
            enabled: !_isSaving,
          ),
          const SizedBox(height: AppSpacing.md),

          // Injection Site Reaction (enum input)
          SymptomEnumInput<InjectionSiteReaction>(
            label: 'Injection Site Reaction',
            value: _injectionSiteReaction,
            options: InjectionSiteReaction.values,
            getLabel: (reaction) => reaction.label,
            onChanged: (value) => setState(() => _injectionSiteReaction = value),
            enabled: !_isSaving,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Notes field (unchanged)
          _buildNotesField(),
          const SizedBox(height: AppSpacing.md),

          // Error message (unchanged)
          if (_errorMessage != null) _buildErrorMessage(),

          // Save button
          _buildSaveButton(),
        ],
      ),
    ),
  );
}
```

**Save Method** (convert to SymptomEntry):
```dart
Future<void> _handleSave() async {
  setState(() {
    _isSaving = true;
    _errorMessage = null;
  });

  try {
    final user = ref.read(currentUserProvider);
    final pet = ref.read(primaryPetProvider);

    if (user == null || pet == null) {
      throw Exception('User or pet not found');
    }

    // Build symptoms map using converter
    final symptoms = <String, SymptomEntry>{};

    if (_vomitingEpisodes != null) {
      symptoms[SymptomType.vomiting] = SymptomSeverityConverter.createEntry(
        symptomType: SymptomType.vomiting,
        rawValue: _vomitingEpisodes,
      );
    }

    if (_diarrheaQuality != null) {
      symptoms[SymptomType.diarrhea] = SymptomSeverityConverter.createEntry(
        symptomType: SymptomType.diarrhea,
        rawValue: _diarrheaQuality!.name,  // Store enum name
      );
    }

    if (_constipationLevel != null) {
      symptoms[SymptomType.constipation] = SymptomSeverityConverter.createEntry(
        symptomType: SymptomType.constipation,
        rawValue: _constipationLevel!.name,
      );
    }

    if (_energyLevel != null) {
      symptoms[SymptomType.energy] = SymptomSeverityConverter.createEntry(
        symptomType: SymptomType.energy,
        rawValue: _energyLevel!.name,
      );
    }

    if (_appetiteFraction != null) {
      symptoms[SymptomType.suppressedAppetite] = SymptomSeverityConverter.createEntry(
        symptomType: SymptomType.suppressedAppetite,
        rawValue: _appetiteFraction!.name,
      );
    }

    if (_injectionSiteReaction != null) {
      symptoms[SymptomType.injectionSiteReaction] = SymptomSeverityConverter.createEntry(
        symptomType: SymptomType.injectionSiteReaction,
        rawValue: _injectionSiteReaction!.name,
      );
    }

    // Save via service
    await symptomsService.saveSymptoms(
      userId: user.uid,
      petId: pet.id,
      date: _selectedDate,
      symptoms: symptoms.isEmpty ? null : symptoms,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    // Invalidate cache
    ref.invalidate(currentMonthSymptomsSummaryProvider);

    // Close dialog
    if (mounted) {
      OverlayService.hide();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Symptoms saved successfully')),
      );
    }
  } on SymptomValidationException catch (e) {
    setState(() {
      _errorMessage = e.message;
      _isSaving = false;
    });
  } catch (e) {
    setState(() {
      _errorMessage = 'Failed to save symptoms. Please try again.';
      _isSaving = false;
    });
  }
}
```

**Implementation Summary**:
- ✅ Updated imports to include new models and widgets
- ✅ Replaced `Map<String, int?>` state with 6 individual typed fields
- ✅ Updated `initState()` with safe enum deserialization from Firestore
- ✅ Rewrote `_save()` method to create `SymptomEntry` objects using `SymptomSeverityConverter`
- ✅ Replaced 6 identical sliders with symptom-specific inputs:
  - Vomiting: `SymptomNumberInput` (0-20 episodes)
  - Diarrhea/Constipation/Energy/Appetite/Injection Site: `SymptomEnumInput<T>` with appropriate enum types
- ✅ Removed obsolete `_getSymptomLabel()` helper and `_SymptomSlider` widget class (99 lines)
- ✅ Updated class documentation to describe hybrid tracking system
- ✅ Fixed all linting issues - flutter analyze: **No issues found!**
- ✅ All existing functionality preserved (error handling, validation, provider invalidation, analytics)

---

## Phase 5  Chart & Visualization Updates

### Step 5.1: Update Symptom Colors (Energy)

**Objective**: Update color mapping for energy (if needed).

**Location**: `lib/core/constants/symptom_colors.dart`

**Changes**:
```dart
class SymptomColors {
  SymptomColors._();

  /// Color mapping for each symptom type
  static const Map<String, Color> _symptomColors = {
    SymptomType.vomiting: Color(0xFF9DCBBF),           // Pastel teal
    SymptomType.diarrhea: Color(0xFFF0C980),           // Pastel amber
    SymptomType.energy: Color(0xFFEDA08F),             // Pastel coral (was lethargy)
    SymptomType.suppressedAppetite: Color(0xFFC4B5FD), // Pastel lavender
    SymptomType.constipation: Color(0xFFA8D5E2),       // Soft aqua
    SymptomType.injectionSiteReaction: Color(0xFFF5C9A8), // Soft peach
  };

  // ... rest unchanged ...
}
```

**Note**: No functional changes needed - just update the map key from `lethargy` to `energy`.

---

### Step 5.2: Implement Hybrid Chart Strategy

**Objective**: Implement severity-based rendering for Week/Month views, frequency-based for Year view.

**Location**: `lib/providers/symptoms_chart_provider.dart` and bucket builders

#### Hybrid Chart Approach:

**Week/Month Views (Daily Buckets)**:
- Each bar represents **one day**
- Segment height = **severity score (0-3)** for that symptom on that day
- Total bar height = sum of all symptom severities for that day
- Uses `maxScore` fields from daily summaries (e.g., `vomitingMaxScore`, `diarrheaMaxScore`)

**Year View (Monthly Buckets)**:
- Each bar represents **one month**
- Segment height = **number of days** the symptom appeared in that month
- Uses `daysWithSymptom` counts from weekly/monthly summaries

#### Changes Required:

**1. Update bucket data structure** (if needed):
```dart
class SymptomBucket {
  // Existing fields for year view (frequency)
  final Map<String, int> daysWithSymptom;  // For year view

  // New fields for week/month views (severity)
  final Map<String, int> severityScores;   // For week/month views (0-3 per symptom)

  // ... other fields ...
}
```

**2. Update bucket builders for Week/Month**:
```dart
// Example: Daily bucket builder (for week/month views)
SymptomBucket _buildDailyBucket(DailySummary summary) {
  return SymptomBucket(
    date: summary.date,
    // Severity scores for rendering
    severityScores: {
      if (summary.vomitingMaxScore != null)
        SymptomType.vomiting: summary.vomitingMaxScore!,
      if (summary.diarrheaMaxScore != null)
        SymptomType.diarrhea: summary.diarrheaMaxScore!,
      if (summary.constipationMaxScore != null)
        SymptomType.constipation: summary.constipationMaxScore!,
      if (summary.energyMaxScore != null)
        SymptomType.energy: summary.energyMaxScore!,
      if (summary.suppressedAppetiteMaxScore != null)
        SymptomType.suppressedAppetite: summary.suppressedAppetiteMaxScore!,
      if (summary.injectionSiteReactionMaxScore != null)
        SymptomType.injectionSiteReaction: summary.injectionSiteReactionMaxScore!,
    },
    // Day counts (not used for rendering week/month, but kept for consistency)
    daysWithSymptom: {...},
  );
}
```

**3. Update chart rendering logic**:
```dart
// In symptoms_stacked_bar_chart.dart

// For Week/Month views: use severityScores
double _getSegmentHeight(SymptomBucket bucket, String symptomKey, ChartGranularity granularity) {
  if (granularity == ChartGranularity.year) {
    // Year view: use day counts (frequency)
    return (bucket.daysWithSymptom[symptomKey] ?? 0).toDouble();
  } else {
    // Week/Month views: use severity scores (0-3)
    return (bucket.severityScores[symptomKey] ?? 0).toDouble();
  }
}
```

**4. Update tooltips** based on granularity:
```dart
// Week/Month tooltip: show severity
Text('${symptomLabel}: Severity ${bucket.severityScores[symptomKey]}')

// Year tooltip: show day count
Text('${symptomLabel}: ${bucket.daysWithSymptom[symptomKey]} days')
```

---

### Step 5.3: Update Chart Axis & Scaling

**Objective**: Ensure Y-axis scaling is appropriate for hybrid chart strategy.

**Location**: `lib/features/health/widgets/symptoms_stacked_bar_chart.dart`

**Changes**:

**Week/Month Views**:
- Y-axis max = highest total severity across all days (sum of all symptom severities)
- Typical range: 0-18 (6 symptoms × max severity 3)
- Actual range depends on logged symptoms

**Year View**:
- Y-axis max = highest day count across all months
- Typical range: 0-31 (max days in a month)

**Implementation**:
```dart
double _calculateYAxisMax(List<SymptomBucket> buckets, ChartGranularity granularity) {
  if (granularity == ChartGranularity.year) {
    // Year view: max day count
    return buckets.fold<double>(0, (max, bucket) {
      final totalDays = bucket.daysWithSymptom.values.fold<int>(0, (sum, days) => sum + days);
      return totalDays > max ? totalDays.toDouble() : max;
    });
  } else {
    // Week/Month views: max total severity
    return buckets.fold<double>(0, (max, bucket) {
      final totalSeverity = bucket.severityScores.values.fold<int>(0, (sum, severity) => sum + severity);
      return totalSeverity > max ? totalSeverity.toDouble() : max;
    });
  }
}
```

**Verification**:
- Week/Month bars show varying heights based on daily symptom severity
- Year bars show varying heights based on symptom frequency
- Y-axis labels appropriate for each view
- Tooltips show correct metrics (severity vs day count)

**Status**: ✅ **COMPLETED** (2025-01-26)
- Updated `buildWeeklySymptomBuckets()` to use severity scores from `maxScore` fields
- Updated `buildMonthlySymptomBuckets()` to use severity scores from `maxScore` fields
- Year bucket builder remains unchanged (already using frequency correctly)
- Added `_getTotalLabel()` and `_getSymptomRowLabel()` helper methods to chart widget
- Updated tooltip card to display granularity-aware labels
- Updated semantics label builder for accessibility
- Added `formattedLabel` field to `_SymptomTooltipRow` for custom formatting
- Updated all tooltip instantiation points to use new helper methods
- Updated weekly bucket tests with severity score assertions (2 new tests)
- Updated monthly bucket tests with severity score assertions (4 tests)
- All tests pass: 18/18 bucket tests ✅
- `flutter analyze` clean: No issues found ✅
- Implementation approach: Reused existing `daysWithSymptom` field with context-dependent semantics

---

---

## Phase 6  Testing & Polish

### Step 6.1: Unit Tests

**Files to Create/Update**:

1. **Model Tests**:
   - `test/features/health/models/symptom_entry_test.dart` (new)
   - `test/features/health/models/symptom_raw_value_test.dart` (new)

2. **Conversion Tests**:
   - `test/features/health/services/symptom_severity_converter_test.dart` (new)

3. **Service Tests**:
   - `test/features/health/services/symptoms_service_test.dart` (update)

**Key Test Cases**:
- All severity conversion functions with boundary values
- SymptomEntry serialization/deserialization
- Enum `fromString` methods with invalid inputs
- HealthParameter with nested symptom structure
- Service validation with 0-3 severity range

---

### Step 6.2: Widget Tests

**Files to Create/Update**:

1. **Input Widget Tests**:
   - `test/features/health/widgets/symptom_number_input_test.dart` (new)
   - `test/features/health/widgets/symptom_enum_input_test.dart` (new)

2. **Dialog Tests**:
   - `test/features/health/widgets/symptoms_entry_dialog_test.dart` (update)

**Key Test Cases**:
- Number input increment/decrement
- Enum input N/A toggle
- Dialog pre-fill from existing entry
- Save button creates correct SymptomEntry map
- Conversion functions called correctly

---

### Step 6.3: Integration Tests (Manual)

**Test Scenarios**:

1. **Basic Logging**:
   - Open symptoms dialog
   - Enter vomiting episodes (e.g., 2)
   - Select diarrhea quality (e.g., "Soft")
   - Save and verify success

2. **Mixed Symptoms**:
   - Log multiple symptoms simultaneously
   - Verify all appear in daily summary
   - Check chart displays correct day counts

3. **Editing**:
   - Log symptoms for a day
   - Edit same day with different values
   - Verify raw values and severity updated

4. **Chart Verification**:
   - Log symptoms over multiple days
   - View week/month/year charts
   - Verify bar heights match day counts
   - Tap bars and check tooltip day counts

5. **Edge Cases**:
   - Log only N/A values (should save as no symptoms)
   - Log vomiting with 0 episodes (severity 0, no bar)
   - Log 10+ vomiting episodes (severity capped at 3)

---

### Step 6.4: Run Flutter Analyze & Fix Linting

**Command**: `flutter analyze`

**Expected Issues**:
- Unused imports (remove)
- Missing documentation comments (add)
- Prefer const constructors (add const where possible)
- File names should be snake_case (verify)

**Process**:
1. Run `flutter analyze` 2. Fix all errors (red)
3. Fix all warnings (yellow)
4. Fix all info messages (blue)
5. Re-run until clean

---

### Step 6.5: Documentation Updates

**Files to Update**:

1. **Analytics Documentation**:
   - `.cursor/reference/analytics_list.md`
   - Verify `symptoms_log_created` and `symptoms_log_updated` events
   - No parameter changes needed (still uses severity scores)

2. **Architecture Documentation** (if exists):
   - Document hybrid model approach
   - Reference severity conversion functions
   - Note 0-3 scale for all symptoms

---

## Future Enhancements (Post-MVP)

### Enhancement 1: Display Raw Values in Tooltips
- Fetch health parameters for tooltip dates
- Show "3 vomiting episodes" instead of "3 days"
- Show "Soft stool" instead of "Severity 1"

### Enhancement 2: Symptom Insights
- "You logged vomiting 5 times this month, all after meals"
- "Diarrhea episodes decreased since medication change"

### Enhancement 3: Export to PDF (Premium)
- Include raw values in vet reports
- Show both symptom counts and detailed entries

---

## Implementation Checklist

### Phase 1: Data Model & Schema 
- [x] Create `SymptomEntry` model
- [x] Create `symptom_raw_value.dart` with all enums
- [x] Update `SymptomType` constants (lethargy � energy)
- [x] Global find & replace lethargy � energy
- [x] Update `HealthParameter` model (nested structure)
- [x] Update `DailySummary` model (rename lethargy fields)
- [x] Update `WeeklySummary` model (rename lethargy fields)
- [x] Update `MonthlySummary` model (rename lethargy fields)
- [x] Update Firestore schema documentation
- [ ] Run `dart run build_runner build` (if using code generation)

### Phase 2: Conversion Logic 
- [x] Create `SymptomSeverityConverter` class
- [x] Implement all 6 conversion functions
- [x] Write unit tests for all conversions
- [x] Verify all tests pass

### Phase 3: Service Layer 
- [x] Update `SymptomsService.saveSymptoms` signature
- [x] Update validation (0-3 range)
- [x] Update daily summary builder (use severityScore)
- [x] Verify analytics events work unchanged
- [x] Update service unit tests
- [x] Verify all tests pass

### Phase 4: UI Components (Dialog: ✅ Complete)
- [x] Create `SymptomNumberInput` widget
- [x] Create `SymptomEnumInput` widget
- [x] Rewrite `SymptomsEntryDialog` with new inputs
- [x] Update save method (create SymptomEntry map)
- [ ] Test dialog with all symptom combinations
- [x] Write widget tests for input widgets
- [ ] Write widget tests for updated dialog

### Phase 5: Chart Updates ✅
- [x] Update `SymptomColors` (lethargy → energy) - Already complete
- [x] Update bucket data structure - No changes needed, reused existing with context-dependent semantics
- [x] Update bucket builders for Week/Month (use maxScore from daily summaries)
- [x] Update chart rendering logic (hybrid: severity for week/month, frequency for year)
- [x] Update Y-axis scaling - No changes needed, existing logic works for both
- [x] Update tooltips based on granularity
- [x] Update chart labels (Lethargy → Energy) - Already complete from earlier phase
- [x] Test week/month views (severity-based) - Added new tests
- [x] Test year view (frequency-based) - Existing tests pass, unchanged behavior
- [x] Verify tooltip displays correct metrics - Verified via helper methods and tests

### Phase 6: Testing & Polish 
- [x] Run all unit tests - Bucket tests pass (18/18 for weekly/monthly)
- [ ] Run all widget tests
- [x] Run `flutter analyze` and fix all issues - No issues found!
- [ ] Manual testing (all scenarios in 6.3)
- [ ] Update analytics documentation
- [ ] Code review and cleanup

---

## Success Criteria

This implementation is complete when:

1.  All 6 symptoms have tailored input UIs (number input for vomiting, enums for others)
2.  Raw values stored in Firestore with computed severity scores (0-3)
3.  Charts display day counts correctly with 0-3 scale
4.  "Energy" symptom replaces "lethargy" throughout the app
5.  All existing chart functionality preserved (stacked bars, tooltips, legend, navigation)
6.  Firestore costs unchanged (same batch writes, same reads)
7.  All unit tests pass
8.  All widget tests pass
9.  `flutter analyze` produces no errors, warnings, or info messages
10.  Manual testing validates all user flows

---

## Estimated Development Time

- **Phase 1 (Data Model)**: 2-3 hours
- **Phase 2 (Conversion Logic)**: 1-2 hours
- **Phase 3 (Service Layer)**: 1-2 hours
- **Phase 4 (UI Components)**: 3-4 hours
- **Phase 5 (Chart Updates)**: 1 hour
- **Phase 6 (Testing & Polish)**: 2-3 hours

**Total**: 10-15 hours across multiple work sessions

---

## Dependencies

-  Existing symptoms tracking implementation
-  `HealthParameter`, summary models
-  `SymptomsService`, chart providers
-  `LoggingPopupWrapper`, `HydraSlidingSegmentedControl`
-  Chart infrastructure (buckets, stacked bar chart)

---

## Risk Assessment

**Low Risk**:
- Clean-slate implementation (no backward compatibility)
- No schema structure changes (still single doc per day)
- Reuses existing patterns and infrastructure
- Well-defined conversion logic from spec

**Mitigation**:
- Comprehensive unit tests for all conversions
- Widget tests for new input components
- Manual testing before marking complete
- Database resets available for testing

---

**Document Status**: Ready for Implementation
**Created**: 2025-01-26
**Specification Reference**: `.cursor/reference/HydraCat_Symptom_Tracking_Spec.md`
