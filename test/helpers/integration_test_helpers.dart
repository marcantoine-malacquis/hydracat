/// Integration test helpers for logging feature
///
/// Provides shared utilities for integration tests including:
/// - Fake Firestore instance creation
/// - Provider overrides for testing
/// - Mock connectivity service
/// - Assertion helpers for Firestore documents
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/models/user_persona.dart';
import 'package:hydracat/providers/connectivity_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/services/connectivity_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================
// Mock Classes
// ============================================

/// Mock connectivity service for offline testing
class MockConnectivityService extends Mock implements ConnectivityService {
  MockConnectivityService({bool initiallyConnected = true})
    : _isConnected = initiallyConnected;

  bool _isConnected;

  /// Get current connection state
  @override
  bool get isConnected => _isConnected;

  /// Set connection state
  set isConnected(bool value) {
    _isConnected = value;
  }
}

// ============================================
// Firestore Utilities
// ============================================

/// Create fake Firestore instance for integration tests
///
/// Optionally pre-populate with initial data.
FakeFirebaseFirestore createFakeFirestore({
  Map<String, dynamic>? initialData,
}) {
  final firestore = FakeFirebaseFirestore();

  // Pre-populate if initial data provided
  if (initialData != null) {
    // Implementation for pre-populating can be added if needed
    // For now, tests will populate data as needed
  }

  return firestore;
}

// ============================================
// Provider Override Builders
// ============================================

/// Build ProviderScope with all necessary overrides for integration tests
///
/// Provides a complete test environment with:
/// - Fake Firestore instance
/// - Mock connectivity service
/// - Test user authentication
/// - Test pet profile
/// - Initialized SharedPreferences
Future<ProviderScope> buildIntegrationTestScope({
  required Widget child,
  FakeFirebaseFirestore? firestore,
  bool isConnected = true,
  AppUser? testUser,
  CatProfile? testPet,
  SharedPreferences? sharedPrefs,
}) async {
  // Create instances with defaults if not provided
  final fakeFirestore = firestore ?? createFakeFirestore();
  final mockConnectivity = MockConnectivityService(
    initiallyConnected: isConnected,
  );
  final pet =
      testPet ??
      CatProfile(
        id: 'test-pet-id',
        userId: 'test-user-id',
        name: 'Whiskers',
        ageYears: 8,
        treatmentApproach: UserPersona.medicationAndFluidTherapy,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

  // Initialize SharedPreferences if not provided
  SharedPreferences.setMockInitialValues({});
  await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      // Override Firestore with fake instance
      Provider<FirebaseFirestore>((ref) => fakeFirestore),

      // Override connectivity service
      connectivityServiceProvider.overrideWith(
        (ref) => mockConnectivity,
      ),

      // Override connection state
      isConnectedProvider.overrideWith(
        (ref) => mockConnectivity.isConnected,
      ),

      // Override profile with test pet
      primaryPetProvider.overrideWith(
        (ref) => pet,
      ),
    ],
    child: child,
  );
}

// ============================================
// Firestore Path Helpers
// ============================================

/// Generate medication session document path
String sessionPath(String sessionId) => 'medicationSessions/$sessionId';

/// Generate fluid session document path
String fluidSessionPath(String sessionId) => 'fluidSessions/$sessionId';

/// Generate daily summary document path
String dailySummaryPath(DateTime date) =>
    'treatmentSummaries/daily/summaries/${AppDateUtils.formatDateForSummary(date)}';

/// Generate weekly summary document path
String weeklySummaryPath(DateTime date) =>
    'treatmentSummaries/weekly/summaries/${AppDateUtils.formatWeekForSummary(date)}';

/// Generate monthly summary document path
String monthlySummaryPath(DateTime date) =>
    'treatmentSummaries/monthly/summaries/${AppDateUtils.formatMonthForSummary(date)}';

// ============================================
// Assertion Helpers
// ============================================

/// Verify Firestore document exists and has expected structure
Future<void> verifyDocumentExists(
  FakeFirebaseFirestore firestore,
  String path,
  Map<String, dynamic> expectedFields,
) async {
  // Parse path into collection and document ID
  final parts = path.split('/');
  if (parts.length < 2) {
    throw ArgumentError('Path must have at least collection/docId: $path');
  }

  // Navigate through subcollections if needed
  DocumentReference docRef = firestore.collection(parts[0]).doc(parts[1]);

  for (var i = 2; i < parts.length - 1; i += 2) {
    docRef = docRef.collection(parts[i]).doc(parts[i + 1]);
  }

  final doc = await docRef.get();
  expect(doc.exists, isTrue, reason: 'Document does not exist at path: $path');

  final data = doc.data() as Map<String, dynamic>?;
  expect(data, isNotNull, reason: 'Document data is null at path: $path');

  // Verify expected fields
  for (final entry in expectedFields.entries) {
    expect(
      data![entry.key],
      equals(entry.value),
      reason: 'Field ${entry.key} mismatch at path: $path',
    );
  }
}

/// Verify session document exists with expected structure
Future<void> assertSessionExists(
  FakeFirebaseFirestore firestore,
  String sessionId, {
  required String medicationName,
  required double dosageGiven,
}) async {
  final doc = await firestore
      .collection('medicationSessions')
      .doc(sessionId)
      .get();
  expect(doc.exists, isTrue, reason: 'Session $sessionId does not exist');

  final data = doc.data()!;
  expect(
    data['medicationName'],
    equals(medicationName),
    reason: 'Medication name mismatch',
  );
  expect(
    data['dosageGiven'],
    equals(dosageGiven),
    reason: 'Dosage given mismatch',
  );
}

/// Verify fluid session document exists with expected structure
Future<void> assertFluidSessionExists(
  FakeFirebaseFirestore firestore,
  String sessionId, {
  required double volumeGiven,
}) async {
  final doc = await firestore.collection('fluidSessions').doc(sessionId).get();
  expect(doc.exists, isTrue, reason: 'Fluid session $sessionId does not exist');

  final data = doc.data()!;
  expect(
    data['volumeGiven'],
    equals(volumeGiven),
    reason: 'Volume given mismatch',
  );
}

/// Verify daily summary counters
Future<void> assertDailySummaryCount(
  FakeFirebaseFirestore firestore,
  DateTime date,
  int expectedMedicationCount,
) async {
  final docId = AppDateUtils.formatDateForSummary(date);
  final doc = await firestore
      .collection('treatmentSummaries')
      .doc('daily')
      .collection('summaries')
      .doc(docId)
      .get();

  expect(doc.exists, isTrue, reason: 'Daily summary does not exist');

  final data = doc.data()!;
  expect(
    data['medicationTotalDoses'],
    equals(expectedMedicationCount),
    reason: 'Medication count mismatch',
  );
}

/// Verify daily summary fluid volume
Future<void> assertDailySummaryFluidVolume(
  FakeFirebaseFirestore firestore,
  DateTime date,
  double expectedFluidVolume,
) async {
  final docId = AppDateUtils.formatDateForSummary(date);
  final doc = await firestore
      .collection('treatmentSummaries')
      .doc('daily')
      .collection('summaries')
      .doc(docId)
      .get();

  expect(doc.exists, isTrue, reason: 'Daily summary does not exist');

  final data = doc.data()!;
  expect(
    data['fluidTotalVolume'],
    equals(expectedFluidVolume),
    reason: 'Fluid volume mismatch',
  );
}

/// Count documents in collection matching criteria
Future<int> countDocuments(
  FakeFirebaseFirestore firestore,
  String collectionPath, {
  Map<String, dynamic>? whereConditions,
}) async {
  // Parse collection path (handle subcollections)
  final parts = collectionPath.split('/');

  Query query = firestore.collection(parts[0]);

  // Navigate through subcollections
  for (var i = 1; i < parts.length; i += 2) {
    if (i + 1 < parts.length) {
      query = (query as CollectionReference)
          .doc(parts[i])
          .collection(parts[i + 1]);
    }
  }

  // Apply where conditions if provided
  if (whereConditions != null) {
    for (final entry in whereConditions.entries) {
      query = query.where(entry.key, isEqualTo: entry.value);
    }
  }

  final snapshot = await query.get();
  return snapshot.docs.length;
}

/// Verify document does not exist
Future<void> assertDocumentNotExists(
  FakeFirebaseFirestore firestore,
  String path,
) async {
  final parts = path.split('/');
  DocumentReference docRef = firestore.collection(parts[0]).doc(parts[1]);

  for (var i = 2; i < parts.length - 1; i += 2) {
    docRef = docRef.collection(parts[i]).doc(parts[i + 1]);
  }

  final doc = await docRef.get();
  expect(doc.exists, isFalse, reason: 'Document exists at path: $path');
}

/// Verify weekly summary exists with correct week ID
Future<void> assertWeeklySummaryExists(
  FakeFirebaseFirestore firestore,
  DateTime date,
) async {
  final weekId = AppDateUtils.formatWeekForSummary(date);
  final doc = await firestore
      .collection('treatmentSummaries')
      .doc('weekly')
      .collection('summaries')
      .doc(weekId)
      .get();

  expect(
    doc.exists,
    isTrue,
    reason: 'Weekly summary does not exist for week: $weekId',
  );
}

/// Verify monthly summary exists with correct month ID
Future<void> assertMonthlySummaryExists(
  FakeFirebaseFirestore firestore,
  DateTime date,
) async {
  final monthId = AppDateUtils.formatMonthForSummary(date);
  final doc = await firestore
      .collection('treatmentSummaries')
      .doc('monthly')
      .collection('summaries')
      .doc(monthId)
      .get();

  expect(
    doc.exists,
    isTrue,
    reason: 'Monthly summary does not exist for month: $monthId',
  );
}
