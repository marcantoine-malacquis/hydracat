# Weight Tracking Feature - Optimized Implementation Plan

## Overview
Implement weight tracking for pets with optimal Firestore usage from day one, following all Firebase CRUD rules while maintaining excellent UX.

**Expected Usage**: 2-3 weight entries per month per pet
**Lifetime Data**: ~30 entries/year → ~450 entries over 15 years

---

## Schema Design - OPTIMIZED DUAL APPROACH

### 1. Individual Weight Records (Existing Schema - Keep As-Is)
```
users/{userId}/pets/{petId}/healthParameters/{YYYY-MM-DD}
  ├── weight: number (kg, optional)
  ├── appetite: string (optional)
  ├── symptoms: string (optional)
  ├── notes: string (optional)
  ├── createdAt: Timestamp
  └── updatedAt: Timestamp
```

**Purpose**: 
- Source of truth for individual weight entries
- Supports editing/deleting specific entries
- Allows multiple health parameters per day

**Query Strategy**:
- ✅ Use pagination (`.limit(50)`)
- ✅ Filter for non-null weights only
- ✅ One-time reads (`.get()`), not listeners
- ✅ Cache results in memory

---

### 2. Weight Summary in Monthly Aggregations (NEW - RECOMMENDED)

**Add to existing monthly treatment summaries**:

```
users/{userId}/pets/{petId}/treatmentSummaries/monthly/summaries/{YYYY-MM}
  ├── [existing treatment fields...]
  │
  # Weight Tracking Summary (NEW FIELDS)
  ├── weightEntriesCount: number        # number of weight entries this month
  ├── weightLatest: number              # most recent weight value (kg)
  ├── weightLatestDate: Timestamp       # when latest weight was recorded
  ├── weightFirst: number               # first weight of the month (kg)
  ├── weightFirstDate: Timestamp        # date of first entry
  ├── weightAverage: number             # average weight for the month
  ├── weightChange: number              # delta from previous month (kg)
  ├── weightChangePercent: number       # percentage change
  └── weightTrend: string              # "increasing", "stable", "decreasing"
```

**Benefits**:
- 📊 **Graph Rendering**: Read 12 docs for 1-year graph instead of 30+ individual entries
- 💰 **Cost Optimization**: 12 reads vs 30+ reads (60% reduction)
- 🚀 **Performance**: Faster graph rendering with pre-aggregated data
- 📈 **Insights**: Quick stats without extra queries ("Lost 0.2kg this month")
- ✅ **CRUD Compliant**: Follows "Use summary documents for analytics" rule

**Trade-offs**:
- Slightly more complex write logic (acceptable - already doing this for treatments)
- 4-6 extra fields per monthly summary (negligible storage cost)

---

## Query Patterns - Cost Optimized

### Pattern 1: Graph Rendering (Primary Use Case)

```dart
// ✅ BEST: Use monthly summaries for graph (12 reads for 1 year)
Future<List<WeightDataPoint>> getWeightGraphData({
  required String userId,
  required String petId,
  int months = 12,
}) async {
  final query = _firestore
    .collection('users')
    .doc(userId)
    .collection('pets')
    .doc(petId)
    .collection('treatmentSummaries')
    .doc('monthly')
    .collection('summaries')
    .where('weightEntriesCount', isGreaterThan: 0)  // Only months with weight data
    .orderBy('weightEntriesCount')  // Required for where clause
    .orderBy('startDate', descending: true)
    .limit(months);

  final snapshot = await query.get();  // One-time read
  
  return snapshot.docs.map((doc) {
    final data = doc.data();
    return WeightDataPoint(
      date: (data['weightLatestDate'] as Timestamp).toDate(),
      weight: data['weightLatest'] as double,
      isAverage: false,
    );
  }).toList();
}

// Cost: 12 reads for 1-year graph ✅
// Latency: Fast (12 docs vs 30+ docs)
```

### Pattern 2: Detailed History List (Secondary Use Case)

```dart
// ✅ OPTIMIZED: Paginated query for full weight history
Future<WeightHistoryPage> getWeightHistory({
  required String userId,
  required String petId,
  DocumentSnapshot? startAfter,
  int pageSize = 50,
}) async {
  Query query = _firestore
    .collection('users')
    .doc(userId)
    .collection('pets')
    .doc(petId)
    .collection('healthParameters')
    .where('weight', isNotEqualTo: null)  // Only entries with weight
    .orderBy('weight')  // Required for where clause
    .orderBy('createdAt', descending: true)
    .limit(pageSize);

  if (startAfter != null) {
    query = query.startAfterDocument(startAfter);
  }

  final snapshot = await query.get();
  
  return WeightHistoryPage(
    entries: snapshot.docs.map((doc) => WeightEntry.fromFirestore(doc)).toList(),
    lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    hasMore: snapshot.docs.length == pageSize,
  );
}

// Cost: 50 reads for initial page, 50 reads per "Load More"
// Most users will never scroll past first page (50 entries = ~20 months)
```

### Pattern 3: Latest Weight (Quick Stat)

```dart
// ✅ BEST: Use current month's summary (1 read)
Future<double?> getLatestWeight({
  required String userId,
  required String petId,
}) async {
  final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
  
  final doc = await _firestore
    .collection('users')
    .doc(userId)
    .collection('pets')
    .doc(petId)
    .collection('treatmentSummaries')
    .doc('monthly')
    .collection('summaries')
    .doc(currentMonth)
    .get();

  if (!doc.exists || doc.data()?['weightLatest'] == null) {
    // Fallback: check previous month (1 more read)
    final previousMonth = DateFormat('yyyy-MM').format(
      DateTime.now().subtract(Duration(days: 31))
    );
    
    final prevDoc = await _firestore
      .collection('users')
      .doc(userId)
      .collection('pets')
      .doc(petId)
      .collection('treatmentSummaries')
      .doc('monthly')
      .collection('summaries')
      .doc(previousMonth)
      .get();
    
    return prevDoc.data()?['weightLatest'] as double?;
  }

  return doc.data()?['weightLatest'] as double?;
}

// Cost: 1-2 reads (instead of querying all healthParameters)
```

---

## Write Strategy - Batch Operations

### When User Logs Weight

```dart
Future<void> logWeight({
  required String userId,
  required String petId,
  required DateTime date,
  required double weightKg,
  String? notes,
}) async {
  final batch = _firestore.batch();
  final dateString = DateFormat('yyyy-MM-dd').format(date);
  final monthString = DateFormat('yyyy-MM').format(date);

  // 1. Write individual health parameter (source of truth)
  final healthParamRef = _firestore
    .collection('users')
    .doc(userId)
    .collection('pets')
    .doc(petId)
    .collection('healthParameters')
    .doc(dateString);

  batch.set(healthParamRef, {
    'weight': weightKg,
    'notes': notes,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  // 2. Update monthly summary
  final monthlySummaryRef = _firestore
    .collection('users')
    .doc(userId)
    .collection('pets')
    .doc(petId)
    .collection('treatmentSummaries')
    .doc('monthly')
    .collection('summaries')
    .doc(monthString);

  // Fetch current month's summary to calculate deltas
  final currentSummary = await monthlySummaryRef.get();
  final previousWeight = currentSummary.data()?['weightLatest'] as double?;
  
  final weightChange = previousWeight != null ? weightKg - previousWeight : 0.0;
  final weightChangePercent = previousWeight != null 
    ? ((weightKg - previousWeight) / previousWeight) * 100 
    : 0.0;

  batch.set(monthlySummaryRef, {
    'weightEntriesCount': FieldValue.increment(1),
    'weightLatest': weightKg,
    'weightLatestDate': Timestamp.fromDate(date),
    'weightChange': weightChange,
    'weightChangePercent': weightChangePercent,
    'weightTrend': _calculateTrend(weightChange),
    'updatedAt': FieldValue.serverTimestamp(),
    
    // First entry of the month
    if (currentSummary.data()?['weightFirst'] == null) {
      'weightFirst': weightKg,
      'weightFirstDate': Timestamp.fromDate(date),
    }
  }, SetOptions(merge: true));

  await batch.commit();
}

// Cost: 2 writes per weight entry (reasonable)
// Reads: 1 read to fetch current summary for delta calculation
```

---

## Caching Strategy

### In-Memory Cache for Graph Data

```dart
class WeightCacheService {
  static WeightGraphCache? _graphCache;
  static DateTime? _graphCacheTimestamp;
  static const _cacheDuration = Duration(hours: 1);

  static Future<List<WeightDataPoint>> getCachedGraphData({
    required String userId,
    required String petId,
  }) async {
    // Return cached data if fresh
    if (_graphCache != null &&
        _graphCacheTimestamp != null &&
        DateTime.now().difference(_graphCacheTimestamp!) < _cacheDuration &&
        _graphCache!.userId == userId &&
        _graphCache!.petId == petId) {
      debugPrint('[WeightCache] Serving from cache');
      return _graphCache!.dataPoints;
    }

    // Fetch fresh data
    debugPrint('[WeightCache] Cache miss - fetching from Firestore');
    final data = await WeightService.getWeightGraphData(
      userId: userId,
      petId: petId,
    );

    // Update cache
    _graphCache = WeightGraphCache(
      userId: userId,
      petId: petId,
      dataPoints: data,
    );
    _graphCacheTimestamp = DateTime.now();

    return data;
  }

  static void invalidateCache() {
    _graphCache = null;
    _graphCacheTimestamp = null;
  }
}
```

**Cache Invalidation**:
- When new weight is logged
- When weight entry is edited/deleted
- After 1 hour (automatic refresh)

---

## UI Implementation Guidelines

### Weight Screen Layout

**RECOMMENDED: Floating Action Button (FAB)**

```
┌─────────────────────────────────────┐
│  Weight Tracking                    │
├─────────────────────────────────────┤
│                                     │
│  Current: 4.2 kg                    │
│  Change: ↓ 0.1 kg this month        │
│                                     │
│  ┌───────────────────────────────┐  │
│  │                               │  │
│  │    [Line Graph: 12 months]    │  │ ← Monthly summaries (12 reads)
│  │                               │  │
│  └───────────────────────────────┘  │
│                                     │
│  Recent Entries                     │
│  ┌───────────────────────────────┐  │
│  │ Nov 5, 2025  │ 4.2 kg  │ Edit │  │
│  │ Oct 28, 2025 │ 4.3 kg  │ Edit │  │ ← Paginated list (50 per page)
│  │ Oct 15, 2025 │ 4.25 kg │ Edit │  │
│  │ ...                            │  │
│  │ [Load More]                    │  │ ← Pagination
│  └───────────────────────────────┘  │
│                                     │
│                                  [+]│ ← FAB stays visible on scroll
└─────────────────────────────────────┘
```

**Use `HydraFab` widget** (already exists in codebase):
- Always visible regardless of scroll position
- Consistent with app's existing patterns
- Accessible from anywhere on the screen

**Why FAB is preferred**:
- ✅ Always accessible (no scrolling needed)
- ✅ Follows Material Design patterns
- ✅ Consistent with existing HydraCat UI (uses `HydraFab`)
- ✅ Doesn't take up layout space
- ✅ Primary action pattern (perfect for "add" actions)

### Performance Optimizations

1. **Graph**:
   - Use monthly summaries (12 reads)
   - Cache for 1 hour
   - Refresh only when new entry added

2. **Stats Card**:
   - Use current month summary (1 read)
   - Show: current weight, monthly change, trend

3. **History List**:
   - Paginate at 50 entries
   - Most users never scroll (first page = ~20 months)
   - "Load More" button for older data

4. **Offline Support**:
   - Enable Firestore persistence
   - Cache works offline automatically

---

## Cost Analysis

### Scenario: User with 3 years of data (90 entries)

**With Current Schema Only (Non-optimized)**:
- Graph rendering: 90 reads
- Latest weight: 1 read (single query)
- History list: 90 reads (if they view all)
- **Total per screen load**: 91-181 reads

**With Optimized Approach (Recommended)**:
- Graph rendering: 12 reads (monthly summaries)
- Latest weight: 1 read (current month summary)
- History list: 50 reads (first page only, most users stop here)
- **Total per screen load**: 13-63 reads

**Savings**: 70-118 reads per screen load (60-65% reduction) ✅

### Long-term (15 years, 450 entries)

**Non-optimized**: 451+ reads per screen load  
**Optimized**: 13-63 reads per screen load  
**Savings**: 85-90% reduction ✅

---

## DETAILED IMPLEMENTATION PLAN

---

## Phase 0: Foundation - Models & Data Structures ✅ COMPLETED

### Step 0.1: Create HealthParameter Model ✅ COMPLETED

**Goal**: Create immutable model for healthParameters collection (weight, appetite, symptoms, notes)

**Files to create**:
- `lib/features/health/models/health_parameter.dart` (NEW)

**Implementation**:

Create the model with:
- Immutable @immutable class
- Factory constructor `HealthParameter.create()` for new entries
- Factory constructor `HealthParameter.fromFirestore()` for deserialization
- `toJson()` for Firestore serialization
- Validation in factory constructors
- `copyWith()` for updates
- Document ID as `YYYY-MM-DD` format

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Health parameter data for a specific date
///
/// Tracks daily health metrics including weight, appetite, symptoms.
/// Stored in Firestore: `healthParameters/{YYYY-MM-DD}`
@immutable
class HealthParameter {
  const HealthParameter({
    required this.date,
    required this.createdAt,
    this.weight,
    this.appetite,
    this.symptoms,
    this.notes,
    this.updatedAt,
  });

  /// Factory constructor to create new health parameter
  factory HealthParameter.create({
    required DateTime date,
    double? weight,
    String? appetite,
    String? symptoms,
    String? notes,
  }) {
    return HealthParameter(
      date: DateTime(date.year, date.month, date.day),
      weight: weight,
      appetite: appetite,
      symptoms: symptoms,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  /// Factory constructor from Firestore document
  factory HealthParameter.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HealthParameter(
      date: _parseDate(data['date']),
      weight: data['weight'] != null ? (data['weight'] as num).toDouble() : null,
      appetite: data['appetite'] as String?,
      symptoms: data['symptoms'] as String?,
      notes: data['notes'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestampNullable(data['updatedAt']),
    );
  }

  /// Date this health parameter is for (normalized to start of day)
  final DateTime date;

  /// Weight in kilograms (optional)
  final double? weight;

  /// Appetite assessment (optional)
  /// Values: "all", "3-4", "half", "1-4", "nothing"
  final String? appetite;

  /// Symptoms assessment (optional)
  /// Values: "good", "okay", "concerning"
  final String? symptoms;

  /// Optional notes (max 500 characters)
  final String? notes;

  /// When this parameter was first created
  final DateTime createdAt;

  /// When this parameter was last updated
  final DateTime? updatedAt;

  /// Document ID for Firestore (YYYY-MM-DD format)
  String get documentId => DateFormat('yyyy-MM-dd').format(date);

  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      if (weight != null) 'weight': weight,
      if (appetite != null) 'appetite': appetite,
      if (symptoms != null) 'symptoms': symptoms,
      if (notes != null) 'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Create a copy with updated fields
  HealthParameter copyWith({
    DateTime? date,
    double? weight,
    String? appetite,
    String? symptoms,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthParameter(
      date: date ?? this.date,
      weight: weight ?? this.weight,
      appetite: appetite ?? this.appetite,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper parsers
  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static DateTime? _parseTimestampNullable(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return null;
  }
}
```

**Testing**:
```bash
flutter analyze
# Should pass with no errors
```

---

### Step 0.2: Create WeightDataPoint Model ✅ COMPLETED

**Goal**: Create model for graph data points from monthly summaries

**Files to create**:
- `lib/features/health/models/weight_data_point.dart` (NEW)

**Implementation**:

Simple immutable model for graph rendering:

```dart
import 'package:flutter/foundation.dart';

/// Data point for weight graph visualization
///
/// Represents a single point on the weight trend line graph.
/// Can represent either a single weight entry or a monthly average.
@immutable
class WeightDataPoint {
  const WeightDataPoint({
    required this.date,
    required this.weightKg,
    this.isAverage = false,
  });

  /// Date of this weight measurement
  final DateTime date;

  /// Weight value in kilograms
  final double weightKg;

  /// Whether this is an average value (from monthly summary)
  /// or a single entry (from healthParameters)
  final bool isAverage;

  /// Weight in pounds (for display)
  double get weightLbs => weightKg * 2.20462;

  @override
  String toString() => 'WeightDataPoint(date: $date, kg: $weightKg, avg: $isAverage)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightDataPoint &&
          other.date == date &&
          other.weightKg == weightKg &&
          other.isAverage == isAverage;

  @override
  int get hashCode => Object.hash(date, weightKg, isAverage);
}
```

**Testing**:
```bash
flutter analyze
# Should pass with no errors
```

---

### Step 0.3: Update MonthlySummary Model with Weight Fields ✅ COMPLETED

**Goal**: Add weight tracking fields to existing monthly summary model

**Files to modify**:
- `lib/shared/models/monthly_summary.dart` (MODIFY)

**Implementation**:

Add weight fields to the `MonthlySummary` class:

1. Add fields to constructor parameters (around line 17-41):
```dart
const MonthlySummary({
  // ... existing fields ...
  required super.createdAt,
  super.updatedAt,
  // ADD THESE NEW FIELDS:
  this.weightEntriesCount = 0,
  this.weightLatest,
  this.weightLatestDate,
  this.weightFirst,
  this.weightFirstDate,
  this.weightAverage,
  this.weightChange,
  this.weightChangePercent,
  this.weightTrend,
});
```

2. Add field declarations (after existing fields, around line 198):
```dart
/// Number of weight entries logged this month
final int weightEntriesCount;

/// Most recent weight value (kg)
final double? weightLatest;

/// Date when latest weight was recorded
final DateTime? weightLatestDate;

/// First weight of the month (kg)
final double? weightFirst;

/// Date of first weight entry this month
final DateTime? weightFirstDate;

/// Average weight for the month (kg)
final double? weightAverage;

/// Change from previous month (kg)
/// Positive = gained, negative = lost
final double? weightChange;

/// Percentage change from previous month
final double? weightChangePercent;

/// Trend indicator: "increasing", "stable", "decreasing"
final String? weightTrend;
```

3. Update `empty()` factory constructor (around line 54-80):
```dart
factory MonthlySummary.empty(DateTime monthDate) {
  // ... existing code ...
  return MonthlySummary(
    // ... existing parameters ...
    overallCurrentStreak: 0,
    // ADD THESE:
    weightEntriesCount: 0,
    weightLatest: null,
    weightLatestDate: null,
    weightFirst: null,
    weightFirstDate: null,
    weightAverage: null,
    weightChange: null,
    weightChangePercent: null,
    weightTrend: null,
  );
}
```

4. Update `fromJson()` factory constructor (around line 86-132):
```dart
factory MonthlySummary.fromJson(Map<String, dynamic> json) {
  // ... existing parsing logic ...
  return MonthlySummary(
    // ... existing parameters ...
    updatedAt: TreatmentSummaryBase.parseDateTimeNullable(json['updatedAt']),
    // ADD THESE:
    weightEntriesCount: (json['weightEntriesCount'] as num?)?.toInt() ?? 0,
    weightLatest: (json['weightLatest'] as num?)?.toDouble(),
    weightLatestDate: TreatmentSummaryBase.parseDateTimeNullable(json['weightLatestDate']),
    weightFirst: (json['weightFirst'] as num?)?.toDouble(),
    weightFirstDate: TreatmentSummaryBase.parseDateTimeNullable(json['weightFirstDate']),
    weightAverage: (json['weightAverage'] as num?)?.toDouble(),
    weightChange: (json['weightChange'] as num?)?.toDouble(),
    weightChangePercent: (json['weightChangePercent'] as num?)?.toDouble(),
    weightTrend: json['weightTrend'] as String?,
  );
}
```

5. Update `toJson()` method (around line 229-254):
```dart
@override
Map<String, dynamic> toJson() {
  return {
    // ... existing fields ...
    'updatedAt': updatedAt?.toIso8601String(),
    // ADD THESE:
    'weightEntriesCount': weightEntriesCount,
    if (weightLatest != null) 'weightLatest': weightLatest,
    if (weightLatestDate != null) 'weightLatestDate': weightLatestDate!.toIso8601String(),
    if (weightFirst != null) 'weightFirst': weightFirst,
    if (weightFirstDate != null) 'weightFirstDate': weightFirstDate!.toIso8601String(),
    if (weightAverage != null) 'weightAverage': weightAverage,
    if (weightChange != null) 'weightChange': weightChange,
    if (weightChangePercent != null) 'weightChangePercent': weightChangePercent,
    if (weightTrend != null) 'weightTrend': weightTrend,
  };
}
```

6. Update `copyWith()` method (around line 334-387):
```dart
MonthlySummary copyWith({
  // ... existing parameters ...
  DateTime? updatedAt,
  // ADD THESE:
  int? weightEntriesCount,
  double? weightLatest,
  DateTime? weightLatestDate,
  double? weightFirst,
  DateTime? weightFirstDate,
  double? weightAverage,
  double? weightChange,
  double? weightChangePercent,
  String? weightTrend,
}) {
  return MonthlySummary(
    // ... existing assignments ...
    updatedAt: updatedAt ?? this.updatedAt,
    // ADD THESE:
    weightEntriesCount: weightEntriesCount ?? this.weightEntriesCount,
    weightLatest: weightLatest ?? this.weightLatest,
    weightLatestDate: weightLatestDate ?? this.weightLatestDate,
    weightFirst: weightFirst ?? this.weightFirst,
    weightFirstDate: weightFirstDate ?? this.weightFirstDate,
    weightAverage: weightAverage ?? this.weightAverage,
    weightChange: weightChange ?? this.weightChange,
    weightChangePercent: weightChangePercent ?? this.weightChangePercent,
    weightTrend: weightTrend ?? this.weightTrend,
  );
}
```

7. Update `==` operator (around line 390-408):
```dart
@override
bool operator ==(Object other) {
  if (identical(this, other)) return true;

  return other is MonthlySummary &&
      // ... existing comparisons ...
      other.overallCurrentStreak == overallCurrentStreak &&
      // ADD THESE:
      other.weightEntriesCount == weightEntriesCount &&
      other.weightLatest == weightLatest &&
      other.weightLatestDate == weightLatestDate &&
      other.weightFirst == weightFirst &&
      other.weightFirstDate == weightFirstDate &&
      other.weightAverage == weightAverage &&
      other.weightChange == weightChange &&
      other.weightChangePercent == weightChangePercent &&
      other.weightTrend == weightTrend &&
      super == other;
}
```

8. Update `hashCode` (around line 410-428):
```dart
@override
int get hashCode {
  return Object.hash(
    super.hashCode,
    // ... existing fields ...
    overallCurrentStreak,
    // ADD THESE:
    weightEntriesCount,
    weightLatest,
    weightLatestDate,
    weightFirst,
    weightFirstDate,
    weightAverage,
    weightChange,
    weightChangePercent,
    weightTrend,
  );
}
```

9. Update `toString()` (around line 430-457):
```dart
@override
String toString() {
  return 'MonthlySummary('
      // ... existing fields ...
      'updatedAt: $updatedAt, '
      // ADD THESE:
      'weightEntriesCount: $weightEntriesCount, '
      'weightLatest: $weightLatest, '
      'weightLatestDate: $weightLatestDate, '
      'weightFirst: $weightFirst, '
      'weightFirstDate: $weightFirstDate, '
      'weightAverage: $weightAverage, '
      'weightChange: $weightChange, '
      'weightChangePercent: $weightChangePercent, '
      'weightTrend: $weightTrend'
      ')';
}
```

**Testing**:
```bash
flutter analyze
# Should pass with no errors
```

---

## Phase 1: Backend Services - Weight CRUD Operations ✅ COMPLETED

### Step 1.1: Create WeightService Foundation ✅ COMPLETED

**Goal**: Create service with Firestore references and basic structure

**Files to create**:
- `lib/features/health/services/weight_service.dart` (NEW)
- `lib/features/health/exceptions/health_exceptions.dart` (NEW)

**Implementation**:

First, create the exceptions file:

```dart
// lib/features/health/exceptions/health_exceptions.dart

/// Base exception for health-related operations
class HealthException implements Exception {
  const HealthException(this.message);
  final String message;
  
  @override
  String toString() => 'HealthException: $message';
}

/// Exception for weight validation failures
class WeightValidationException extends HealthException {
  const WeightValidationException(super.message);
}

/// Exception for weight service operations
class WeightServiceException extends HealthException {
  const WeightServiceException(super.message);
}
```

Then create the service foundation:

```dart
// lib/features/health/services/weight_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/health/exceptions/health_exceptions.dart';
import 'package:hydracat/features/health/models/health_parameter.dart';
import 'package:hydracat/features/health/models/weight_data_point.dart';
import 'package:hydracat/features/profile/services/profile_validation_service.dart';
import 'package:hydracat/shared/models/monthly_summary.dart';
import 'package:intl/intl.dart';

/// Service for weight tracking operations
///
/// Handles CRUD operations for weight entries with:
/// - Batch writes to healthParameters and monthly summaries
/// - Validation using ProfileValidationService
/// - Cost-optimized queries
/// - Cache invalidation
class WeightService {
  WeightService({
    FirebaseFirestore? firestore,
    ProfileValidationService? validationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _validationService = validationService ?? const ProfileValidationService();

  final FirebaseFirestore _firestore;
  final ProfileValidationService _validationService;

  // ============================================
  // PRIVATE HELPERS - Firestore Paths
  // ============================================

  /// Gets health parameter document reference
  ///
  /// Path: users/{userId}/pets/{petId}/healthParameters/{YYYY-MM-DD}
  DocumentReference _getHealthParameterRef(
    String userId,
    String petId,
    DateTime date,
  ) {
    final docId = DateFormat('yyyy-MM-dd').format(date);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('healthParameters')
        .doc(docId);
  }

  /// Gets monthly summary document reference
  ///
  /// Path: users/{userId}/pets/{petId}/treatmentSummaries/monthly/summaries/{YYYY-MM}
  DocumentReference _getMonthlySummaryRef(
    String userId,
    String petId,
    DateTime date,
  ) {
    final docId = DateFormat('yyyy-MM').format(date);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('treatmentSummaries')
        .doc('monthly')
        .collection('summaries')
        .doc(docId);
  }

  /// Gets pet document reference
  ///
  /// Path: users/{userId}/pets/{petId}
  DocumentReference _getPetRef(
    String userId,
    String petId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId);
  }

  // ============================================
  // VALIDATION
  // ============================================

  /// Validates weight value
  void _validateWeight(double weightKg) {
    final result = _validationService.validateWeight(weightKg);
    if (!result.isValid) {
      final errorMessages = result.errors.map((e) => e.message).join(', ');
      throw WeightValidationException(errorMessages);
    }
  }

  /// Validates notes length
  void _validateNotes(String? notes) {
    if (notes != null && notes.length > 500) {
      throw WeightValidationException('Notes must be 500 characters or less');
    }
  }

  // ============================================
  // HELPER: Calculate Weight Trend
  // ============================================

  /// Calculates trend from weight change
  String _calculateTrend(double change) {
    if (change > 0.1) return 'increasing';
    if (change < -0.1) return 'decreasing';
    return 'stable';
  }

  // Placeholder for future methods
  // Will add: logWeight, updateWeight, deleteWeight, getWeightHistory, getWeightGraphData
}
```

**Testing**:
```bash
flutter analyze
# Should pass with no errors
```

---

### Step 1.2: Implement logWeight Method ✅ COMPLETED

**Goal**: Implement create operation with batch writes

**Files to modify**:
- `lib/features/health/services/weight_service.dart` (MODIFY)

**Implementation**:

Add the `logWeight` method to `WeightService` class:

```dart
// ADD THIS METHOD to WeightService class

/// Logs a new weight entry
///
/// Writes to:
/// 1. healthParameters/{YYYY-MM-DD} - individual entry
/// 2. treatmentSummaries/monthly/summaries/{YYYY-MM} - monthly summary
/// 3. pets/{petId} - updates CatProfile.weightKg
///
/// Throws:
/// - [WeightValidationException] if validation fails
/// - [WeightServiceException] if Firestore operation fails
Future<void> logWeight({
  required String userId,
  required String petId,
  required DateTime date,
  required double weightKg,
  String? notes,
}) async {
  try {
    if (kDebugMode) {
      debugPrint('[WeightService] Logging weight: ${weightKg}kg on ${date.toString()}');
    }

    // Validate inputs
    _validateWeight(weightKg);
    _validateNotes(notes);

    final normalizedDate = AppDateUtils.startOfDay(date);
    final batch = _firestore.batch();

    // 1. Write health parameter
    final healthParamRef = _getHealthParameterRef(userId, petId, normalizedDate);
    batch.set(
      healthParamRef,
      {
        'weight': weightKg,
        if (notes != null) 'notes': notes,
        'date': Timestamp.fromDate(normalizedDate),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // 2. Update monthly summary
    final monthlySummaryRef = _getMonthlySummaryRef(userId, petId, normalizedDate);
    
    // Fetch current summary to calculate deltas
    final currentSummaryDoc = await monthlySummaryRef.get();
    final hasExistingData = currentSummaryDoc.exists &&
        currentSummaryDoc.data()?['weightLatest'] != null;

    final previousWeight = hasExistingData
        ? (currentSummaryDoc.data()!['weightLatest'] as num).toDouble()
        : null;

    final weightChange = previousWeight != null ? weightKg - previousWeight : 0.0;
    final weightChangePercent = previousWeight != null
        ? ((weightKg - previousWeight) / previousWeight) * 100
        : 0.0;

    final summaryUpdates = <String, dynamic>{
      'weightEntriesCount': FieldValue.increment(1),
      'weightLatest': weightKg,
      'weightLatestDate': Timestamp.fromDate(normalizedDate),
      'weightChange': weightChange,
      'weightChangePercent': weightChangePercent,
      'weightTrend': _calculateTrend(weightChange),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Set first weight of month if not exists
    if (!hasExistingData ||
        currentSummaryDoc.data()!['weightFirst'] == null) {
      summaryUpdates['weightFirst'] = weightKg;
      summaryUpdates['weightFirstDate'] = Timestamp.fromDate(normalizedDate);
    }

    batch.set(monthlySummaryRef, summaryUpdates, SetOptions(merge: true));

    // 3. Update pet profile with latest weight
    final petRef = _getPetRef(userId, petId);
    batch.update(petRef, {
      'weightKg': weightKg,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Commit batch
    await batch.commit();

    if (kDebugMode) {
      debugPrint('[WeightService] Weight logged successfully');
    }
  } on WeightValidationException {
    rethrow;
  } on FirebaseException catch (e) {
    if (kDebugMode) {
      debugPrint('[WeightService] Firebase error: ${e.message}');
    }
    throw WeightServiceException('Failed to log weight: ${e.message}');
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[WeightService] Unexpected error: $e');
    }
    throw WeightServiceException('Failed to log weight: $e');
  }
}
```

**Testing**:
```bash
flutter analyze
# Should pass with no errors
```

---

### Step 1.3: Implement updateWeight Method ✅ COMPLETED

**Goal**: Implement update operation with delta calculations

**Files to modify**:
- `lib/features/health/services/weight_service.dart` (MODIFY)

**Implementation**:

Add the `updateWeight` method:

```dart
// ADD THIS METHOD to WeightService class

/// Updates an existing weight entry
///
/// Recalculates monthly summary based on deltas.
/// Also updates CatProfile.weightKg if this is the most recent entry.
///
/// Throws:
/// - [WeightValidationException] if validation fails
/// - [WeightServiceException] if Firestore operation fails
Future<void> updateWeight({
  required String userId,
  required String petId,
  required DateTime oldDate,
  required double oldWeightKg,
  required DateTime newDate,
  required double newWeightKg,
  String? newNotes,
}) async {
  try {
    if (kDebugMode) {
      debugPrint('[WeightService] Updating weight from ${oldWeightKg}kg to ${newWeightKg}kg');
    }

    // Validate new inputs
    _validateWeight(newWeightKg);
    _validateNotes(newNotes);

    final normalizedOldDate = AppDateUtils.startOfDay(oldDate);
    final normalizedNewDate = AppDateUtils.startOfDay(newDate);
    final isSameDate = normalizedOldDate.isAtSameMomentAs(normalizedNewDate);
    final isSameMonth = normalizedOldDate.year == normalizedNewDate.year &&
        normalizedOldDate.month == normalizedNewDate.month;

    final batch = _firestore.batch();

    // 1. If date changed, delete old entry
    if (!isSameDate) {
      final oldHealthParamRef = _getHealthParameterRef(userId, petId, normalizedOldDate);
      batch.delete(oldHealthParamRef);

      // Decrement old month's count if different month
      if (!isSameMonth) {
        final oldMonthlySummaryRef = _getMonthlySummaryRef(userId, petId, normalizedOldDate);
        batch.update(oldMonthlySummaryRef, {
          'weightEntriesCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // 2. Write/update new entry
    final newHealthParamRef = _getHealthParameterRef(userId, petId, normalizedNewDate);
    batch.set(
      newHealthParamRef,
      {
        'weight': newWeightKg,
        if (newNotes != null) 'notes': newNotes,
        'date': Timestamp.fromDate(normalizedNewDate),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // 3. Update monthly summary for new date
    final newMonthlySummaryRef = _getMonthlySummaryRef(userId, petId, normalizedNewDate);
    final currentSummaryDoc = await newMonthlySummaryRef.get();
    
    final previousWeight = currentSummaryDoc.exists &&
            currentSummaryDoc.data()!['weightLatest'] != null
        ? (currentSummaryDoc.data()!['weightLatest'] as num).toDouble()
        : null;

    final weightChange = previousWeight != null ? newWeightKg - previousWeight : 0.0;
    final weightChangePercent = previousWeight != null
        ? ((newWeightKg - previousWeight) / previousWeight) * 100
        : 0.0;

    batch.set(
      newMonthlySummaryRef,
      {
        if (!isSameMonth || !isSameDate) 'weightEntriesCount': FieldValue.increment(1),
        'weightLatest': newWeightKg,
        'weightLatestDate': Timestamp.fromDate(normalizedNewDate),
        'weightChange': weightChange,
        'weightChangePercent': weightChangePercent,
        'weightTrend': _calculateTrend(weightChange),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // 4. Update pet profile with latest weight (always update to newest entry)
    final petRef = _getPetRef(userId, petId);
    batch.update(petRef, {
      'weightKg': newWeightKg,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Commit batch
    await batch.commit();

    if (kDebugMode) {
      debugPrint('[WeightService] Weight updated successfully');
    }
  } on WeightValidationException {
    rethrow;
  } on FirebaseException catch (e) {
    if (kDebugMode) {
      debugPrint('[WeightService] Firebase error: ${e.message}');
    }
    throw WeightServiceException('Failed to update weight: ${e.message}');
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[WeightService] Unexpected error: $e');
    }
    throw WeightServiceException('Failed to update weight: $e');
  }
}
```

**Testing**:
```bash
flutter analyze
# Should pass with no errors
```

---

### Step 1.4: Implement deleteWeight and Query Methods ✅ COMPLETED

**Goal**: Complete CRUD with delete and read operations

**Files to modify**:
- `lib/features/health/services/weight_service.dart` (MODIFY)

**Implementation**:

Add these methods:

```dart
// ADD THESE METHODS to WeightService class

/// Deletes a weight entry
///
/// Updates monthly summary count and CatProfile if needed.
///
/// Throws:
/// - [WeightServiceException] if Firestore operation fails
Future<void> deleteWeight({
  required String userId,
  required String petId,
  required DateTime date,
}) async {
  try {
    if (kDebugMode) {
      debugPrint('[WeightService] Deleting weight for ${date.toString()}');
    }

    final normalizedDate = AppDateUtils.startOfDay(date);
    final batch = _firestore.batch();

    // 1. Delete health parameter
    final healthParamRef = _getHealthParameterRef(userId, petId, normalizedDate);
    batch.delete(healthParamRef);

    // 2. Decrement monthly summary count
    final monthlySummaryRef = _getMonthlySummaryRef(userId, petId, normalizedDate);
    batch.update(monthlySummaryRef, {
      'weightEntriesCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 3. Update CatProfile.weightKg to most recent remaining entry
    // Query for most recent weight (excluding the one being deleted)
    final recentWeightQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('healthParameters')
        .where('weight', isNotEqualTo: null)
        .orderBy('weight')
        .orderBy('date', descending: true)
        .limit(2) // Get 2 to find next most recent
        .get();

    // Find the most recent entry that's not the one being deleted
    double? newLatestWeight;
    for (final doc in recentWeightQuery.docs) {
      final docDate = (doc.data()['date'] as Timestamp).toDate();
      if (!AppDateUtils.isSameDay(docDate, normalizedDate)) {
        newLatestWeight = (doc.data()['weight'] as num).toDouble();
        break;
      }
    }

    final petRef = _getPetRef(userId, petId);
    if (newLatestWeight != null) {
      batch.update(petRef, {
        'weightKg': newLatestWeight,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // No more weight entries, set to null
      batch.update(petRef, {
        'weightKg': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Commit batch
    await batch.commit();

    if (kDebugMode) {
      debugPrint('[WeightService] Weight deleted successfully');
    }
  } on FirebaseException catch (e) {
    if (kDebugMode) {
      debugPrint('[WeightService] Firebase error: ${e.message}');
    }
    throw WeightServiceException('Failed to delete weight: ${e.message}');
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[WeightService] Unexpected error: $e');
    }
    throw WeightServiceException('Failed to delete weight: $e');
  }
}

/// Gets paginated weight history
///
/// Returns up to [limit] entries, optionally starting after [startAfterDoc].
/// Filters for documents with non-null weight values only.
Future<List<HealthParameter>> getWeightHistory({
  required String userId,
  required String petId,
  DocumentSnapshot? startAfterDoc,
  int limit = 50,
}) async {
  try {
    Query query = _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('healthParameters')
        .where('weight', isNotEqualTo: null)
        .orderBy('weight')
        .orderBy('date', descending: true)
        .limit(limit);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => HealthParameter.fromFirestore(doc))
        .toList();
  } on FirebaseException catch (e) {
    if (kDebugMode) {
      debugPrint('[WeightService] Failed to fetch weight history: ${e.message}');
    }
    throw WeightServiceException('Failed to fetch weight history: ${e.message}');
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[WeightService] Unexpected error: $e');
    }
    throw WeightServiceException('Failed to fetch weight history: $e');
  }
}

/// Gets weight graph data from monthly summaries
///
/// Returns data points for the last [months] months that have weight data.
/// Uses monthly summaries for optimal performance.
Future<List<WeightDataPoint>> getWeightGraphData({
  required String userId,
  required String petId,
  int months = 12,
}) async {
  try {
    final query = _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('treatmentSummaries')
        .doc('monthly')
        .collection('summaries')
        .where('weightEntriesCount', isGreaterThan: 0)
        .orderBy('weightEntriesCount')
        .orderBy('startDate', descending: true)
        .limit(months);

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final weightLatest = (data['weightLatest'] as num).toDouble();
      final weightLatestDate = (data['weightLatestDate'] as Timestamp).toDate();

      return WeightDataPoint(
        date: weightLatestDate,
        weightKg: weightLatest,
        isAverage: false,
      );
    }).toList();
  } on FirebaseException catch (e) {
    if (kDebugMode) {
      debugPrint('[WeightService] Failed to fetch graph data: ${e.message}');
    }
    throw WeightServiceException('Failed to fetch graph data: ${e.message}');
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[WeightService] Unexpected error: $e');
    }
    throw WeightServiceException('Failed to fetch graph data: $e');
  }
}

/// Gets latest weight from most recent monthly summary
///
/// Checks current month first, falls back to previous month.
/// Returns null if no weight data exists.
Future<double?> getLatestWeight({
  required String userId,
  required String petId,
}) async {
  try {
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    
    final currentMonthRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('treatmentSummaries')
        .doc('monthly')
        .collection('summaries')
        .doc(currentMonth);

    final doc = await currentMonthRef.get();

    if (doc.exists && doc.data()?['weightLatest'] != null) {
      return (doc.data()!['weightLatest'] as num).toDouble();
    }

    // Fallback to previous month
    final previousMonth = DateFormat('yyyy-MM').format(
      DateTime.now().subtract(const Duration(days: 31)),
    );

    final prevDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .collection('treatmentSummaries')
        .doc('monthly')
        .collection('summaries')
        .doc(previousMonth)
        .get();

    if (prevDoc.exists && prevDoc.data()?['weightLatest'] != null) {
      return (prevDoc.data()!['weightLatest'] as num).toDouble();
    }

    return null;
  } on FirebaseException catch (e) {
    if (kDebugMode) {
      debugPrint('[WeightService] Failed to fetch latest weight: ${e.message}');
    }
    throw WeightServiceException('Failed to fetch latest weight: ${e.message}');
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[WeightService] Unexpected error: $e');
    }
    throw WeightServiceException('Failed to fetch latest weight: $e');
  }
}
```

**Testing**:
```bash
flutter analyze
# Should pass with no errors
```

---

### Step 1.5: Implement Weight Caching Service ✅ COMPLETED

**Goal**: Add in-memory caching to reduce repeated Firebase reads for graph data

**Files to create**:
- `lib/features/health/services/weight_cache_service.dart` (NEW)

**Files to modify**:
- `lib/providers/weight_provider.dart` (will modify in Step 2.2 to use cache)

**Implementation**:

Create the caching service following the strategy from the schema design:

```dart
// lib/features/health/services/weight_cache_service.dart

import 'package:flutter/foundation.dart';
import 'package:hydracat/features/health/models/weight_data_point.dart';

/// In-memory cache for weight graph data
///
/// Reduces Firebase reads by caching graph data for 1 hour.
/// Cache is invalidated when:
/// - User logs new weight
/// - User edits existing weight
/// - User deletes weight entry
/// - Cache expires (1 hour)
class WeightCacheService {
  WeightCacheService._();

  static WeightGraphCache? _graphCache;
  static DateTime? _graphCacheTimestamp;
  static const _cacheDuration = Duration(hours: 1);

  /// Gets cached graph data or returns null if cache miss
  ///
  /// Cache is valid if:
  /// - Cache exists
  /// - Cache is for same user and pet
  /// - Cache is less than 1 hour old
  static List<WeightDataPoint>? getCachedGraphData({
    required String userId,
    required String petId,
  }) {
    // Check if cache exists and is valid
    if (_graphCache == null || _graphCacheTimestamp == null) {
      if (kDebugMode) {
        debugPrint('[WeightCache] Cache miss - no cache exists');
      }
      return null;
    }

    // Check if cache is for same user/pet
    if (_graphCache!.userId != userId || _graphCache!.petId != petId) {
      if (kDebugMode) {
        debugPrint('[WeightCache] Cache miss - different user/pet');
      }
      return null;
    }

    // Check if cache is still fresh
    final age = DateTime.now().difference(_graphCacheTimestamp!);
    if (age >= _cacheDuration) {
      if (kDebugMode) {
        debugPrint('[WeightCache] Cache miss - expired (age: ${age.inMinutes}m)');
      }
      return null;
    }

    if (kDebugMode) {
      debugPrint('[WeightCache] Cache hit - age: ${age.inMinutes}m');
    }
    return _graphCache!.dataPoints;
  }

  /// Stores graph data in cache
  static void setCachedGraphData({
    required String userId,
    required String petId,
    required List<WeightDataPoint> dataPoints,
  }) {
    _graphCache = WeightGraphCache(
      userId: userId,
      petId: petId,
      dataPoints: dataPoints,
    );
    _graphCacheTimestamp = DateTime.now();

    if (kDebugMode) {
      debugPrint('[WeightCache] Cached ${dataPoints.length} data points');
    }
  }

  /// Invalidates the cache
  ///
  /// Call this after:
  /// - Adding new weight
  /// - Updating existing weight
  /// - Deleting weight entry
  static void invalidateCache() {
    if (_graphCache != null) {
      if (kDebugMode) {
        debugPrint('[WeightCache] Cache invalidated');
      }
    }
    _graphCache = null;
    _graphCacheTimestamp = null;
  }

  /// Checks if cache exists and is valid
  static bool hasCachedData({
    required String userId,
    required String petId,
  }) {
    return getCachedGraphData(userId: userId, petId: petId) != null;
  }

  /// Gets cache age in minutes (returns null if no cache)
  static int? getCacheAgeMinutes() {
    if (_graphCacheTimestamp == null) return null;
    return DateTime.now().difference(_graphCacheTimestamp!).inMinutes;
  }
}

/// Cache container for weight graph data
@immutable
class WeightGraphCache {
  const WeightGraphCache({
    required this.userId,
    required this.petId,
    required this.dataPoints,
  });

  final String userId;
  final String petId;
  final List<WeightDataPoint> dataPoints;
}
```

**Testing**:
```bash
flutter analyze
# Should pass with no errors
```

**Note**: The actual integration of this cache service into `WeightProvider` will be done in Step 2.2 when we create the provider. The provider's `loadInitialData()` method will:
1. Check cache first using `WeightCacheService.getCachedGraphData()`
2. If cache hit, use cached data for graph (skip Firebase read)
3. If cache miss, fetch from Firebase and store in cache
4. After any write operation (log/update/delete), call `WeightCacheService.invalidateCache()`

**Cost Impact**:
- First visit: 12 reads (graph data)
- Subsequent visits within 1 hour: 0 reads for graph (cached)
- After logging weight: Cache invalidated, next visit fetches fresh data
- **Savings**: 12 reads saved per screen revisit within cache window

---

## Phase 2: UI Components - Weight Entry Dialog ✅ COMPLETED

### Step 2.1: Create WeightEntryDialog Widget ✅ COMPLETED

**Goal**: Create dialog for adding/editing weight entries

**Files to create**:
- `lib/features/health/widgets/weight_entry_dialog.dart` (NEW)

**Implementation**:

Create the dialog widget following existing dialog patterns:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_animations.dart';
import 'package:hydracat/core/theme/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/health/models/health_parameter.dart';
import 'package:hydracat/providers/weight_unit_provider.dart';
import 'package:intl/intl.dart';

/// Dialog for adding or editing weight entries
///
/// Supports:
/// - Add mode (existingEntry == null)
/// - Edit mode (existingEntry != null)
/// - Date selection (backdate allowed, future dates blocked)
/// - Weight input with unit conversion (kg/lbs)
/// - Optional notes field (max 500 chars, expands when used)
/// - Validation using ProfileValidationService
class WeightEntryDialog extends ConsumerStatefulWidget {
  /// Creates a [WeightEntryDialog]
  const WeightEntryDialog({
    this.existingEntry,
    super.key,
  });

  /// Existing entry for edit mode (null for add mode)
  final HealthParameter? existingEntry;

  @override
  ConsumerState<WeightEntryDialog> createState() => _WeightEntryDialogState();
}

class _WeightEntryDialogState extends ConsumerState<WeightEntryDialog> {
  late final TextEditingController _weightController;
  late final TextEditingController _notesController;
  late final FocusNode _notesFocusNode;
  
  late DateTime _selectedDate;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    _selectedDate = widget.existingEntry?.date ?? DateTime.now();
    _notesFocusNode = FocusNode();
    
    // Initialize weight controller
    final currentUnit = ref.read(weightUnitProvider);
    final existingWeight = widget.existingEntry?.weight;
    final displayWeight = existingWeight != null
        ? (currentUnit == 'kg' ? existingWeight : existingWeight * 2.20462)
        : null;
    
    _weightController = TextEditingController(
      text: displayWeight?.toStringAsFixed(2) ?? '',
    );
    
    _notesController = TextEditingController(
      text: widget.existingEntry?.notes ?? '',
    );

    _notesFocusNode.addListener(() {
      setState(() {}); // Rebuild to show/hide counter
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  /// Validates and returns weight in kg (or null if invalid)
  double? _getValidatedWeightKg() {
    final text = _weightController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a weight';
      });
      return null;
    }

    final value = double.tryParse(text);
    if (value == null) {
      setState(() {
        _errorMessage = 'Please enter a valid number';
      });
      return null;
    }

    final currentUnit = ref.read(weightUnitProvider);
    final weightKg = currentUnit == 'kg' ? value : value / 2.20462;

    // Validate range (0-15kg)
    if (weightKg <= 0 || weightKg > 15) {
      setState(() {
        _errorMessage = 'Weight must be between 0.5 and 15 kg (1.1 - 33 lbs)';
      });
      return null;
    }

    return weightKg;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _save() {
    final weightKg = _getValidatedWeightKg();
    if (weightKg == null) return;

    final notes = _notesController.text.trim();
    if (notes.length > 500) {
      setState(() {
        _errorMessage = 'Notes must be 500 characters or less';
      });
      return;
    }

    // Return result
    Navigator.of(context).pop({
      'date': _selectedDate,
      'weightKg': weightKg,
      'notes': notes.isEmpty ? null : notes,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingEntry != null;
    final currentUnit = ref.watch(weightUnitProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(isEditMode ? 'Edit Weight' : 'Add Weight'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      DateFormat('MMM dd, yyyy').format(_selectedDate),
                      style: AppTextStyles.body,
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Weight input
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              autofocus: !isEditMode,
              decoration: InputDecoration(
                labelText: 'Weight',
                hintText: currentUnit == 'kg' ? 'e.g., 4.2' : 'e.g., 9.3',
                suffixText: currentUnit,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Notes field (expandable)
            TextField(
              controller: _notesController,
              focusNode: _notesFocusNode,
              maxLength: 500,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g., "After vet visit", "Before fluids"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                counter: AnimatedOpacity(
                  opacity: _notesFocusNode.hasFocus ? 1.0 : 0.0,
                  duration: AppAnimations.getDuration(
                    context,
                    const Duration(milliseconds: 200),
                  ),
                  child: Text('${_notesController.text.length}/500'),
                ),
              ),
              minLines: _notesController.text.isNotEmpty ? 3 : 1,
              maxLines: 5,
              onChanged: (_) {
                setState(() {}); // Update counter
              },
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEditMode ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
```

**Testing**:
```bash
flutter analyze
# Should pass with no errors
```

---

### Step 2.2: Create WeightProvider ✅ COMPLETED

**Goal**: Create Riverpod provider for weight state management

**Files to create**:
- `lib/providers/weight_provider.dart` (NEW)

**Implementation**:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/health/exceptions/health_exceptions.dart';
import 'package:hydracat/features/health/models/health_parameter.dart';
import 'package:hydracat/features/health/models/weight_data_point.dart';
import 'package:hydracat/features/health/services/weight_cache_service.dart';
import 'package:hydracat/features/health/services/weight_service.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';

/// Provider for WeightService instance
final weightServiceProvider = Provider<WeightService>((ref) {
  return WeightService();
});

/// State class for weight data
@immutable
class WeightState {
  const WeightState({
    this.graphData = const [],
    this.historyEntries = const [],
    this.latestWeight,
    this.isLoading = false,
    this.error,
    this.hasMore = true,
  });

  final List<WeightDataPoint> graphData;
  final List<HealthParameter> historyEntries;
  final double? latestWeight;
  final bool isLoading;
  final String? error;
  final bool hasMore;

  WeightState copyWith({
    List<WeightDataPoint>? graphData,
    List<HealthParameter>? historyEntries,
    double? latestWeight,
    bool? isLoading,
    String? error,
    bool? hasMore,
  }) {
    return WeightState(
      graphData: graphData ?? this.graphData,
      historyEntries: historyEntries ?? this.historyEntries,
      latestWeight: latestWeight ?? this.latestWeight,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Notifier for managing weight state
class WeightNotifier extends StateNotifier<WeightState> {
  WeightNotifier(this._service, this._ref) : super(const WeightState());

  final WeightService _service;
  final Ref _ref;

  /// Loads initial data (graph + latest weight + first page of history)
  ///
  /// Uses cache for graph data to minimize Firebase reads:
  /// - Check cache first for graph data
  /// - If cache hit: use cached data (0 reads)
  /// - If cache miss: fetch from Firebase and cache (12 reads)
  /// - Always fetch latest weight and history (not cached)
  Future<void> loadInitialData() async {
    final authState = _ref.read(authProvider);
    final currentPet = _ref.read(profileProvider).currentPet;

    if (authState.user == null || currentPet == null) {
      state = state.copyWith(
        error: 'No user or pet selected',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = authState.user!.uid;
      final petId = currentPet.id;

      // Try to get graph data from cache first
      final cachedGraphData = WeightCacheService.getCachedGraphData(
        userId: userId,
        petId: petId,
      );

      List<WeightDataPoint> graphData;
      if (cachedGraphData != null) {
        // Cache hit - use cached data
        if (kDebugMode) {
          debugPrint('[WeightProvider] Using cached graph data');
        }
        graphData = cachedGraphData;
      } else {
        // Cache miss - fetch from Firebase
        if (kDebugMode) {
          debugPrint('[WeightProvider] Fetching graph data from Firebase');
        }
        graphData = await _service.getWeightGraphData(
          userId: userId,
          petId: petId,
        );
        
        // Store in cache for next time
        WeightCacheService.setCachedGraphData(
          userId: userId,
          petId: petId,
          dataPoints: graphData,
        );
      }

      // Fetch latest weight and history (not cached)
      final results = await Future.wait([
        _service.getLatestWeight(
          userId: userId,
          petId: petId,
        ),
        _service.getWeightHistory(
          userId: userId,
          petId: petId,
          limit: 50,
        ),
      ]);

      state = state.copyWith(
        graphData: graphData,
        latestWeight: results[0] as double?,
        historyEntries: results[1] as List<HealthParameter>,
        hasMore: (results[1] as List<HealthParameter>).length == 50,
        isLoading: false,
      );
    } on HealthException catch (e) {
      state = state.copyWith(
        error: e.message,
        isLoading: false,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WeightProvider] Error loading data: $e');
      }
      state = state.copyWith(
        error: 'Failed to load weight data',
        isLoading: false,
      );
    }
  }

  /// Loads more history entries (pagination)
  Future<void> loadMoreHistory() async {
    if (state.isLoading || !state.hasMore) return;

    final authState = _ref.read(authProvider);
    final currentPet = _ref.read(profileProvider).currentPet;

    if (authState.user == null || currentPet == null) return;
    if (state.historyEntries.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      final moreEntries = await _service.getWeightHistory(
        userId: authState.user!.uid,
        petId: currentPet.id,
        limit: 50,
      );

      state = state.copyWith(
        historyEntries: [...state.historyEntries, ...moreEntries],
        hasMore: moreEntries.length == 50,
        isLoading: false,
      );
    } on HealthException catch (e) {
      state = state.copyWith(
        error: e.message,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load more entries',
        isLoading: false,
      );
    }
  }

  /// Logs a new weight entry
  ///
  /// Invalidates cache after successful write to ensure fresh data on next load.
  Future<bool> logWeight({
    required DateTime date,
    required double weightKg,
    String? notes,
  }) async {
    final authState = _ref.read(authProvider);
    final currentPet = _ref.read(profileProvider).currentPet;

    if (authState.user == null || currentPet == null) {
      state = state.copyWith(error: 'No user or pet selected');
      return false;
    }

    try {
      await _service.logWeight(
        userId: authState.user!.uid,
        petId: currentPet.id,
        date: date,
        weightKg: weightKg,
        notes: notes,
      );

      // Invalidate cache since data changed
      WeightCacheService.invalidateCache();

      // Reload data (will fetch fresh from Firebase)
      await loadInitialData();
      return true;
    } on HealthException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to log weight');
      return false;
    }
  }

  /// Updates an existing weight entry
  ///
  /// Invalidates cache after successful write to ensure fresh data on next load.
  Future<bool> updateWeight({
    required DateTime oldDate,
    required double oldWeightKg,
    required DateTime newDate,
    required double newWeightKg,
    String? newNotes,
  }) async {
    final authState = _ref.read(authProvider);
    final currentPet = _ref.read(profileProvider).currentPet;

    if (authState.user == null || currentPet == null) {
      state = state.copyWith(error: 'No user or pet selected');
      return false;
    }

    try {
      await _service.updateWeight(
        userId: authState.user!.uid,
        petId: currentPet.id,
        oldDate: oldDate,
        oldWeightKg: oldWeightKg,
        newDate: newDate,
        newWeightKg: newWeightKg,
        newNotes: newNotes,
      );

      // Invalidate cache since data changed
      WeightCacheService.invalidateCache();

      // Reload data (will fetch fresh from Firebase)
      await loadInitialData();
      return true;
    } on HealthException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update weight');
      return false;
    }
  }

  /// Deletes a weight entry
  ///
  /// Invalidates cache after successful write to ensure fresh data on next load.
  Future<bool> deleteWeight({required DateTime date}) async {
    final authState = _ref.read(authProvider);
    final currentPet = _ref.read(profileProvider).currentPet;

    if (authState.user == null || currentPet == null) {
      state = state.copyWith(error: 'No user or pet selected');
      return false;
    }

    try {
      await _service.deleteWeight(
        userId: authState.user!.uid,
        petId: currentPet.id,
        date: date,
      );

      // Invalidate cache since data changed
      WeightCacheService.invalidateCache();

      // Reload data (will fetch fresh from Firebase)
      await loadInitialData();
      return true;
    } on HealthException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete weight');
      return false;
    }
  }
}

/// Provider for weight state
final weightProvider = StateNotifierProvider<WeightNotifier, WeightState>((ref) {
  return WeightNotifier(
    ref.watch(weightServiceProvider),
    ref,
  );
});
```

**Testing**:
```bash
flutter analyze
# Should pass with no errors
```

---

## Phase 3: UI Components - Weight Screen Foundation

### Step 3.1: Add fl_chart Dependency ✅ COMPLETED

**Goal**: Add fl_chart package for line graph rendering

**Files to modify**:
- `pubspec.yaml` (MODIFY)

**Implementation**:

Add fl_chart to dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # ... existing dependencies ...
  fl_chart: ^1.1.1  # ADD THIS LINE
```

Then run:
```bash
flutter pub get
```

**Testing**:
```bash
flutter pub get
# Should complete successfully
```

---

### Step 3.2: Create WeightScreen with Empty State ✅ COMPLETED

**Goal**: Create weight screen scaffold with empty state (before graph implementation)

**Files to create**:
- `lib/features/health/screens/weight_screen.dart` (REPLACE existing placeholder)

**Implementation**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/theme/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/health/widgets/weight_entry_dialog.dart';
import 'package:hydracat/providers/weight_provider.dart';
import 'package:hydracat/providers/weight_unit_provider.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_fab.dart';
import 'package:intl/intl.dart';

/// Screen for viewing and managing weight tracking
///
/// Features:
/// - Stats card showing current weight and monthly change
/// - Line graph showing weight trend over last 12 months
/// - Paginated history list with edit/delete actions
/// - Empty state for first-time users
/// - FAB for adding new weight entries
class WeightScreen extends ConsumerStatefulWidget {
  /// Creates a [WeightScreen]
  const WeightScreen({super.key});

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen> {
  @override
  void initState() {
    super.initState();
    // Load data on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(weightProvider.notifier).loadInitialData();
    });
  }

  Future<void> _showAddWeightDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const WeightEntryDialog(),
    );

    if (result != null && mounted) {
      final success = await ref.read(weightProvider.notifier).logWeight(
        date: result['date'] as DateTime,
        weightKg: result['weightKg'] as double,
        notes: result['notes'] as String?,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weight logged successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weightState = ref.watch(weightProvider);
    final currentUnit = ref.watch(weightUnitProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Weight'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: weightState.isLoading && weightState.historyEntries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : weightState.historyEntries.isEmpty
              ? _buildEmptyState()
              : _buildContentView(weightState, currentUnit),
      floatingActionButton: HydraFab(
        onPressed: _showAddWeightDialog,
        icon: Icons.add,
        label: 'Add Weight',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_weight,
              size: 80,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Track Your Pet\'s Weight',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Start monitoring weight changes to help manage your pet\'s CKD. '
              'Regular weighing helps you and your vet track progress.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: _showAddWeightDialog,
              icon: const Icon(Icons.add),
              label: const Text('Log Your First Weight'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentView(WeightState state, String currentUnit) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats card
          _buildStatsCard(state, currentUnit),
          
          const SizedBox(height: AppSpacing.lg),

          // Graph placeholder (will implement in next step)
          _buildGraphPlaceholder(),

          const SizedBox(height: AppSpacing.lg),

          // History list
          _buildHistorySection(state, currentUnit),
        ],
      ),
    );
  }

  Widget _buildStatsCard(WeightState state, String currentUnit) {
    if (state.latestWeight == null) {
      return const SizedBox.shrink();
    }

    final displayWeight = currentUnit == 'kg'
        ? state.latestWeight!
        : state.latestWeight! * 2.20462;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Weight',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${displayWeight.toStringAsFixed(2)} $currentUnit',
            style: AppTextStyles.h1,
          ),
          // TODO: Add monthly change indicator
        ],
      ),
    );
  }

  Widget _buildGraphPlaceholder() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Text(
          'Weight Graph\n(Next Step)',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildHistorySection(WeightState state, String currentUnit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Entries',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: AppSpacing.md),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.historyEntries.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final entry = state.historyEntries[index];
            final displayWeight = currentUnit == 'kg'
                ? entry.weight!
                : entry.weight! * 2.20462;

            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM dd, yyyy').format(entry.date),
                          style: AppTextStyles.body,
                        ),
                        if (entry.notes != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            entry.notes!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '${displayWeight.toStringAsFixed(2)} $currentUnit',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showEditWeightDialog(entry),
                    tooltip: 'Edit',
                  ),
                ],
              ),
            );
          },
        ),
        if (state.hasMore) ...[
          const SizedBox(height: AppSpacing.md),
          Center(
            child: OutlinedButton(
              onPressed: () => ref.read(weightProvider.notifier).loadMoreHistory(),
              child: const Text('Load More'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showEditWeightDialog(entry) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => WeightEntryDialog(existingEntry: entry),
    );

    if (result != null && mounted) {
      final success = await ref.read(weightProvider.notifier).updateWeight(
        oldDate: entry.date,
        oldWeightKg: entry.weight!,
        newDate: result['date'] as DateTime,
        newWeightKg: result['weightKg'] as double,
        newNotes: result['notes'] as String?,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weight updated successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }
}
```

**Testing**:
```bash
flutter analyze
# Should pass with no errors

# Run the app and navigate to weight screen
# Should see empty state if no data
# Should be able to add first weight entry
```

---

### Step 3.3: Implement Weight Graph with fl_chart ✅ COMPLETED

**Goal**: Replace graph placeholder with actual line chart with clean Y-axis intervals

**Files created**:
- `lib/features/health/widgets/weight_line_chart.dart` (235 lines)
- `lib/features/health/widgets/weight_stat_card.dart` (63 lines)

**Files modified**:
- `lib/features/health/screens/weight_screen.dart`

**Key Features Implemented**:
- Smooth curved line with `preventCurveOverShooting` (prevents dips between equal values)
- Clean Y-axis intervals (0.25, 0.5, 1.0 kg) using "nice interval" algorithm
- Y-axis labels without unit suffix (just numbers like "4.00", "4.25")
- Minimum 0.5kg Y-axis range for meaningful scale
- Touch tooltips with date and weight
- WeightStatCard for single data point (shows value + date + encouragement)
- Empty state handling

**Implementation details**:

**Core Chart Features**:
```dart
// Nice interval calculation for clean Y-axis
double _calculateNiceInterval(double rawInterval) {
  final magnitude = pow(10, (log(rawInterval) / ln10).floor()).toDouble();
  final normalized = rawInterval / magnitude;
  
  final nice = normalized <= 0.15 ? 0.1
      : normalized <= 0.35 ? 0.25
      : normalized <= 0.75 ? 0.5
      : normalized <= 1.5 ? 1.0
      : normalized <= 3.0 ? 2.0
      : 5.0;
  
  return nice * magnitude;
}

// Y-axis with clean intervals and aligned range
final rawInterval = (yMax - yMin) / 4;
final niceInterval = _calculateNiceInterval(rawInterval);
final alignedMin = (yMin / niceInterval).floor() * niceInterval;
final alignedMax = (yMax / niceInterval).ceil() * niceInterval;

// Chart configuration
LineChartBarData(
  spots: spots,
  isCurved: true,
  preventCurveOverShooting: true,  // Prevents dips between equal values
  color: AppColors.primary,
  barWidth: 3,
  // ...
)

// Y-axis labels (no unit - cleaner)
                getTitlesWidget: (value, meta) {
                  return Text(
    value.toStringAsFixed(2),  // e.g., "4.00", "4.25"
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  );
}
```
*See actual implementation in `lib/features/health/widgets/weight_line_chart.dart`*

**WeightStatCard for single data point**:
```dart
// lib/features/health/widgets/weight_stat_card.dart
// Shows large weight value, date, and "Log more weights to see trends" message
// Used when only 1 monthly summary exists
```

**Weight Screen Integration**:
- Cardless layout (removed white card wrapper for more horizontal space)
- Controls and chart directly on background
- Conditional rendering: empty state → stat card (1 point) → line chart (2+ points)
- Chart receives `granularity` parameter for adaptive X-axis labels

**Critical Fixes Applied**:
1. Added `startDate` field to monthly summaries when logging weights
2. Set `startDate` check: `currentData?['startDate'] == null` (handles existing treatment-only summaries)
3. Created Firebase composite indexes for all queries
4. Fixed curve overshooting with `preventCurveOverShooting: true`
5. Added comma (`,`) decimal separator support for European locales

**Testing**: ✅ All passed - clean intervals, no overshooting, tooltips functional

---

### Step 3.4: Add Week/Month/Year Views with Period Navigation ✅ COMPLETED

**Goal**: Allow users to switch granularity (Week / Month / Year) and navigate between periods with arrows while keeping Firestore costs minimal.

**Files created**:
- `lib/features/health/models/weight_granularity.dart` (24 lines)

**Files modified**:
- `lib/features/health/services/weight_service.dart` (+150 lines)
- `lib/features/health/services/weight_cache_service.dart` (complete rewrite for per-period caching)
- `lib/providers/weight_provider.dart` (+120 lines)
- `lib/features/health/screens/weight_screen.dart` (+120 lines)
- `lib/features/health/widgets/weight_line_chart.dart` (+10 lines)

**UX/Controls Implemented**:
- ✅ Segmented control: `Week | Month | Year` (default Year, teal when selected)
- ✅ Toggles positioned ABOVE date navigation (saves space, better hierarchy)
- ✅ Left/Right chevrons to navigate periods (4px spacing for compactness)
- ✅ Right chevron disabled at current period (prevents future navigation)
- ✅ "Today" button appears when not on current period (quick jump)
- ✅ Period labels: "Nov 4-10, 2025" / "November 2025" / "2025" (full month names)
- ✅ Session-only persistence (resets to Year on screen re-open)
- ✅ Haptic feedback on all interactions
- ✅ Cardless layout (controls + chart on background, no white card wrapper)

**Data/CRUD Implementation**:
- ✅ Added `hasWeight: true` to healthParameters on write
- ✅ Uses `FieldValue.delete()` for cleaner data model
- ✅ Efficient queries with `hasWeight` equality filter + date range

**Firebase Index Created**:
- Collection: `healthParameters` (collection group)
- Fields: `hasWeight` Asc, `date` Asc

**Service – Implemented Read APIs**:

```dart
// Week view: Mon 00:00 inclusive .. next Mon 00:00 exclusive
Future<List<WeightDataPoint>> getWeightGraphDataWeek({
  required String userId,
  required String petId,
  required DateTime weekStart, // normalized to Monday 00:00
});

// Month view: 1st 00:00 inclusive .. 1st of next month 00:00 exclusive
Future<List<WeightDataPoint>> getWeightGraphDataMonth({
  required String userId,
  required String petId,
  required DateTime monthStart, // normalized to YYYY-MM-01 00:00
});

// Existing Year view stays the same (monthly summaries)
```

**Provider – Implemented State & Methods**:

```dart
// lib/features/health/models/weight_granularity.dart
enum WeightGranularity { week, month, year }

// lib/providers/weight_provider.dart
class WeightState {  
  final WeightGranularity granularity;           // default: year
  final DateTime periodStart;                    // aligned to granularity
  // ...existing fields
}

// WeightNotifier methods
void setGranularity(WeightGranularity g);       // Changes view + loads current period
void nextPeriod();                               // Navigate forward
void previousPeriod();                           // Navigate backward  
void goToToday();                                // Jump to current period
bool get isOnCurrentPeriod;                      // Check if viewing current period
Future<void> loadGraphDataForPeriod();          // Loads data with cache
```

**Caching Implementation**:
- ✅ Map-based cache: `Map<String, _CachedPeriodData> _caches`
- ✅ Cache key: `userId|petId|granularity|periodStartISO`
- ✅ TTL: 30 minutes per period
- ✅ Invalidation: clears all periods on write operations
- ✅ Navigation: cached periods = 0 reads when returning

**UI Implementation**:
```dart
// Cardless layout - no Container wrapper
SingleChildScrollView(
  padding: EdgeInsets.all(AppSpacing.md),  // 16px
    child: Column(
      children: [
      _buildGranularitySelector(state),     // Week|Month|Year (teal selected)
      SizedBox(height: AppSpacing.sm),      // 8px
      _buildGraphHeader(state),             // [<] Label [>] Today (4px spacing)
      SizedBox(height: AppSpacing.md),      // 16px
      [Chart or Empty State or Stat Card]
    ],
  ),
)

// Period labels: Full month names, no wrapping
Week:  "Nov 4-10, 2025"
Month: "November 2025" (maxLines: 1, overflow: visible)
Year:  "2025"

// X-axis labels adapt per granularity
Week:  EEE (Mon, Tue...)
Month: d (1, 2, 3...)
Year:  MMM (Jan, Feb...)
```

**Firebase Indexes Created**:
1. `summaries` collection: `weightEntriesCount` Asc, `startDate` Desc
2. `healthParameters` collection group: `hasWeight` Asc, `date` Asc

**Performance Results**:
- Year: 12 reads (monthly summaries)
- Month: ≤31 reads (filtered by hasWeight)
- Week: ≤7 reads (filtered by hasWeight)
- Cached navigation: 0 reads (30-min TTL)

**Layout Optimizations**:
- Removed card wrapper (+34px horizontal space)
- Reduced chevron spacing to 4px (AppSpacing.xs)
- Full month names display without wrapping
- No overflow errors

**Testing**: ✅ All passed - navigation works, caching effective, no layout overflow

---

## Phase 4: Additional Features & Polish

### Step 4.1: Add Delete Functionality

**Goal**: Add swipe-to-delete and confirmation dialog for weight entries

**Files to modify**:
- `lib/features/health/screens/weight_screen.dart` (MODIFY)

**Implementation**:

Update the history list item builder in `_buildHistorySection()`:

```dart
// REPLACE the ListView.separated itemBuilder in _buildHistorySection() with:

itemBuilder: (context, index) {
  final entry = state.historyEntries[index];
  final displayWeight = currentUnit == 'kg'
      ? entry.weight!
      : entry.weight! * 2.20462;

  return Dismissible(
    key: Key('weight_${entry.date.millisecondsSinceEpoch}'),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.delete,
        color: Colors.white,
      ),
    ),
    confirmDismiss: (direction) => _confirmDelete(context),
    onDismissed: (direction) => _deleteWeight(entry.date),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(entry.date),
                  style: AppTextStyles.body,
                ),
                if (entry.notes != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    entry.notes!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${displayWeight.toStringAsFixed(2)} $currentUnit',
            style: AppTextStyles.h3,
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _showEditWeightDialog(entry),
            tooltip: 'Edit',
          ),
        ],
      ),
    ),
  );
},
```

Add these methods to `_WeightScreenState`:

```dart
// ADD these methods to _WeightScreenState class:

Future<bool> _confirmDelete(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Weight Entry'),
      content: const Text(
        'Are you sure you want to delete this weight entry? '
        'This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  ) ?? false;
}

Future<void> _deleteWeight(DateTime date) async {
  final success = await ref.read(weightProvider.notifier).deleteWeight(
    date: date,
  );

  if (mounted) {
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weight entry deleted'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: ${ref.read(weightProvider).error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

**Testing**:
```bash
flutter analyze
# Should pass with no errors

# Run the app
# Swipe left on a weight entry
# Confirm deletion
# Entry should be removed and graph updated
```

---

### Step 4.2: Add Weight Change Indicator to Stats Card

**Goal**: Show monthly weight change with trend arrow

**Files to modify**:
- `lib/features/health/screens/weight_screen.dart` (MODIFY)

**Implementation**:

```dart
// UPDATE _buildStatsCard() method to show change indicator:

Widget _buildStatsCard(WeightState state, String currentUnit) {
  if (state.latestWeight == null) {
    return const SizedBox.shrink();
  }

  final displayWeight = currentUnit == 'kg'
      ? state.latestWeight!
      : state.latestWeight! * 2.20462;

  // Get change from graph data (compare last 2 points)
  double? change;
  String? trend;
  if (state.graphData.length >= 2) {
    final sorted = [...state.graphData]..sort((a, b) => a.date.compareTo(b.date));
    final latest = sorted.last.weightKg;
    final previous = sorted[sorted.length - 2].weightKg;
    
    change = currentUnit == 'kg' 
        ? latest - previous 
        : (latest - previous) * 2.20462;
    
    if (change > 0.1) {
      trend = 'increasing';
    } else if (change < -0.1) {
      trend = 'decreasing';
    } else {
      trend = 'stable';
    }
  }

  return Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Weight',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${displayWeight.toStringAsFixed(2)} $currentUnit',
              style: AppTextStyles.h1,
            ),
            if (change != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(
                trend == 'increasing' 
                    ? Icons.trending_up 
                    : trend == 'decreasing' 
                        ? Icons.trending_down 
                        : Icons.trending_flat,
                color: trend == 'increasing' 
                    ? Colors.orange 
                    : trend == 'decreasing' 
                        ? Colors.blue 
                        : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${change >= 0 ? "+" : ""}${change.toStringAsFixed(2)} $currentUnit',
                style: AppTextStyles.body.copyWith(
                  color: trend == 'increasing' 
                      ? Colors.orange 
                      : trend == 'decreasing' 
                          ? Colors.blue 
                          : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        if (change != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'from previous month',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    ),
  );
}
```

**Testing**:
```bash
flutter analyze
# Should pass with no errors

# Run the app
# Add weights across different months
# Stats card should show change with trend indicator
```

---

## Phase 5: Firestore Rules & Navigation

### Step 5.1: Update Firestore Security Rules

**Goal**: Add validation rules for healthParameters collection

**Files to modify**:
- `firestore.rules` (MODIFY)

**Implementation**:

Add these rules inside the `pets/{petId}` match block:

```javascript
// ADD this inside match /users/{userId} { match /pets/{petId} { ... } }

// HEALTH PARAMETERS
match /healthParameters/{dateId} {
  allow read: if request.auth.uid == userId;
  allow write: if request.auth.uid == userId && validateHealthParameter();
  
  function validateHealthParameter() {
    // Validate weight if present
    return !request.resource.data.keys().hasAny(['weight']) ||
           (request.resource.data.weight is number &&
            request.resource.data.weight > 0 &&
            request.resource.data.weight <= 15);
  }
}
```

Deploy rules:
```bash
firebase deploy --only firestore:rules
```

**Testing**:
```bash
firebase deploy --only firestore:rules
# Should deploy successfully
```

---

### Step 5.2: Add Navigation to Weight Screen

**Goal**: Add weight tracking link to profile screen

**Files to modify**:
- `lib/features/profile/screens/profile_screen.dart` (MODIFY)

**Implementation**:

Add a navigation tile in the profile screen (find a suitable location in the existing list):

```dart
// ADD this tile in the profile screen's list of options:

ListTile(
  leading: const Icon(Icons.monitor_weight),
  title: const Text('Weight Tracking'),
  subtitle: const Text('Monitor weight changes'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WeightScreen(),
      ),
    );
  },
),
```

**Testing**:
```bash
flutter analyze
# Should pass with no errors

# Run the app
# Navigate to Profile screen
# Tap "Weight Tracking"
# Should navigate to weight screen
```

---

## Phase 6: Final Testing & Lint Fixes

### Step 6.1: Run Complete Analysis

**Goal**: Fix all linter errors and warnings

**Testing**:
```bash
flutter analyze
# Fix any errors or warnings that appear
```

Common issues to check:
- Unused imports
- Missing `const` constructors
- Type annotations
- Documentation comments

---

### Step 6.2: Manual Testing Checklist

**Test all user flows**:

1. **Empty State**:
   - Navigate to weight screen with no data
   - Should see onboarding card
   - Tap "Log Your First Weight"
   - Dialog should open

2. **Add Weight**:
   - Fill in weight value
   - Select date (try backdating)
   - Add notes (optional)
   - Save
   - Should see success message
   - Weight should appear in list
   - Stats card should update

3. **Edit Weight**:
   - Tap edit icon on entry
   - Modify values
   - Save
   - Should see updated values
   - Graph should update

4. **Delete Weight**:
   - Swipe left on entry
   - Confirm deletion
   - Entry should be removed
   - Graph should update

5. **Graph**:
   - Add multiple weights over different months
   - Graph should render smoothly
   - Touch data points
   - Tooltips should appear

6. **Pagination**:
   - Add 50+ weight entries
   - Scroll to bottom
   - Tap "Load More"
   - More entries should load

7. **Unit Conversion**:
   - Go to settings
   - Change weight unit (kg ↔ lbs)
   - Return to weight screen
   - All values should convert correctly

8. **CatProfile Sync**:
   - Add a weight entry
   - Check profile screen
   - Latest weight should update on pet profile

9. **Cache Behavior** (verify cost optimization):
   - Open weight screen (fresh session)
   - Check console logs: should see "Fetching graph data from Firebase"
   - Navigate away and return immediately
   - Check console logs: should see "Using cached graph data"
   - Add a new weight entry
   - Check console logs: should see "Cache invalidated"
   - Return to weight screen
   - Check console logs: should see "Fetching graph data from Firebase" (cache was invalidated)
   - Wait 60+ minutes with app open
   - Return to weight screen
   - Check console logs: should see "Cache miss - expired"

---

### Step 6.3: Fix Any Remaining Issues

**Fix linter errors**:

After running `flutter analyze`, fix any remaining issues:

```bash
flutter analyze
# Address all errors and warnings
# Re-run until clean
```

---

## IMPLEMENTATION COMPLETE

**Summary of what was built**:

✅ **Phase 0**: Foundation models and MonthlySummary updates  
✅ **Phase 1**: WeightService with full CRUD operations + caching  
✅ **Phase 2**: WeightEntryDialog and WeightProvider with cache integration  
✅ **Phase 3**: WeightScreen with fl_chart line graph  
✅ **Phase 4**: Delete functionality and stats indicators  
✅ **Phase 5**: Firestore rules and navigation integration  
✅ **Phase 6**: Testing and lint fixes  

**Key Features Delivered**:
- Cost-optimized Firebase queries (monthly summaries for graphs)
- In-memory caching with 1-hour TTL (further reduces reads)
- Full CRUD operations (add, edit, delete weight entries)
- Beautiful line graph with fl_chart
- Unit conversion (kg/lbs) respecting user preferences
- Auto-sync with CatProfile.weightKg
- Pagination for history list
- Empty state for first-time users
- Swipe-to-delete with confirmation
- Touch tooltips on graph
- Weight change indicators with trends
- Comprehensive validation and error handling

**Performance Metrics**:
- **First visit**: 12 reads for 12-month graph (vs 30+ without optimization)
- **Subsequent visits within 1 hour**: 0 reads for graph (cached)
- **After write operation**: Cache invalidated, fresh data fetched
- **Overall reduction**: 60-90% fewer Firebase reads
- Instant UI updates via batch writes
- Offline support via Firestore persistence

**Caching Strategy**:
- Graph data cached for 1 hour
- Automatic cache invalidation on add/edit/delete
- Per-user-per-pet cache isolation
- Debug logging for cache hits/misses

---

## Firestore Rules Updates

Add to security rules:

```javascript
match /users/{userId}/pets/{petId}/healthParameters/{dateId} {
  allow read, write: if request.auth.uid == userId;
  
  // Validate weight format
  allow write: if !request.resource.data.keys().hasAny(['weight']) ||
                  (request.resource.data.weight is number &&
                   request.resource.data.weight > 0 &&
                   request.resource.data.weight < 100);  // kg, reasonable max
}
```

---

## Key Takeaways

✅ **Follow Firebase CRUD Rules**:
- Use summary documents for analytics (monthly aggregations)
- Paginate all queries (`.limit()`)
- Cache results to avoid re-reads
- Use one-time reads, not real-time listeners

✅ **Optimal Schema**:
- Keep individual entries as source of truth
- Add weight summaries to existing monthly aggregations
- Minimal storage overhead, massive query savings

✅ **Performance**:
- 60-90% reduction in reads
- Fast graph rendering (12 docs vs 90+ docs)
- Excellent offline support

✅ **Maintainability**:
- Leverages existing summary infrastructure
- Follows established patterns (same as treatment tracking)
- Clean separation: detailed records + aggregated analytics

---

## Next Steps

1. **Review & Approve**: Get sign-off on schema additions
2. **Update Models**: Add weight fields to MonthlySummary model
3. **Implement Service**: Create WeightService with optimized queries
4. **Build UI**: Implement weight screen with graph + list
5. **Test**: Verify performance with realistic data volumes
6. **Deploy**: Roll out to production

**Estimated Effort**: 2-3 days for complete implementation
**Firestore Cost Impact**: Minimal (actually reduces costs via aggregation)
**User Experience**: Excellent (fast loading, offline support)

