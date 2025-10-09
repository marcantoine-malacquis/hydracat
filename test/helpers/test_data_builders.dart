/// Test data builders for logging feature tests
///
/// Provides builder classes for creating test data with sensible defaults
/// and fluent API for readability.
// ignore_for_file: avoid_returning_this

library;

import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/schedule.dart';

// Global counter to ensure unique IDs even in same millisecond
int _globalIdCounter = 0;

/// Builder for creating [MedicationSession] test instances
class MedicationSessionBuilder {
  /// Creates a medication session builder with sensible defaults
  MedicationSessionBuilder() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _id = 'test-med-session-$timestamp-${_globalIdCounter++}';
    _petId = 'test-pet-id';
    _userId = 'test-user-id';
    _dateTime = DateTime(2024, 1, 15, 8);
    _medicationName = 'Amlodipine';
    _dosageGiven = 1.0;
    _dosageScheduled = 1.0;
    _medicationUnit = 'pills';
    _completed = true;
    _createdAt = DateTime(2024, 1, 15, 8);
  }

  /// Creates a completed medication session builder
  factory MedicationSessionBuilder.completed() {
    return MedicationSessionBuilder()
      ..asCompleted(completed: true)
      ..withDosageGiven(1);
  }

  /// Creates a missed medication session builder
  factory MedicationSessionBuilder.missed() {
    return MedicationSessionBuilder()
      ..asCompleted(completed: false)
      ..withDosageGiven(0);
  }

  /// Creates a partial dose medication session builder
  factory MedicationSessionBuilder.partial() {
    return MedicationSessionBuilder()
      ..asCompleted(completed: true)
      ..withDosageGiven(0.5)
      ..withDosageScheduled(1);
  }

  late String _id;
  late String _petId;
  late String _userId;
  late DateTime _dateTime;
  late String _medicationName;
  late double _dosageGiven;
  late double _dosageScheduled;
  late String _medicationUnit;
  late bool _completed;
  late DateTime _createdAt;
  String? _medicationStrengthAmount;
  String? _medicationStrengthUnit;
  String? _customMedicationStrengthUnit;
  String? _notes;
  String? _scheduleId;
  DateTime? _scheduledTime;
  DateTime? _syncedAt;
  DateTime? _updatedAt;

  /// Sets the session ID
  MedicationSessionBuilder withId(String id) {
    _id = id;
    return this;
  }

  /// Sets the pet ID
  MedicationSessionBuilder withPetId(String petId) {
    _petId = petId;
    return this;
  }

  /// Sets the user ID
  MedicationSessionBuilder withUserId(String userId) {
    _userId = userId;
    return this;
  }

  /// Sets the date/time
  MedicationSessionBuilder withDateTime(DateTime dateTime) {
    _dateTime = dateTime;
    return this;
  }

  /// Sets the medication name
  MedicationSessionBuilder withMedicationName(String name) {
    _medicationName = name;
    return this;
  }

  /// Sets the dosage given
  MedicationSessionBuilder withDosageGiven(double dosage) {
    _dosageGiven = dosage;
    return this;
  }

  /// Sets the dosage scheduled
  MedicationSessionBuilder withDosageScheduled(double dosage) {
    _dosageScheduled = dosage;
    return this;
  }

  /// Sets the medication unit
  MedicationSessionBuilder withMedicationUnit(String unit) {
    _medicationUnit = unit;
    return this;
  }

  /// Sets the medication strength
  MedicationSessionBuilder withStrength(String amount, String unit) {
    _medicationStrengthAmount = amount;
    _medicationStrengthUnit = unit;
    return this;
  }

  /// Sets custom medication strength unit
  MedicationSessionBuilder withCustomStrengthUnit(String unit) {
    _customMedicationStrengthUnit = unit;
    return this;
  }

  /// Sets the completed status
  MedicationSessionBuilder asCompleted({required bool completed}) {
    _completed = completed;
    return this;
  }

  /// Sets notes
  MedicationSessionBuilder withNotes(String notes) {
    _notes = notes;
    return this;
  }

  /// Sets schedule ID
  MedicationSessionBuilder withScheduleId(String? scheduleId) {
    _scheduleId = scheduleId;
    return this;
  }

  /// Sets scheduled time
  MedicationSessionBuilder withScheduledTime(DateTime? scheduledTime) {
    _scheduledTime = scheduledTime;
    return this;
  }

  /// Sets created at timestamp
  MedicationSessionBuilder withCreatedAt(DateTime createdAt) {
    _createdAt = createdAt;
    return this;
  }

  /// Sets synced at timestamp
  MedicationSessionBuilder withSyncedAt(DateTime? syncedAt) {
    _syncedAt = syncedAt;
    return this;
  }

  /// Sets updated at timestamp
  MedicationSessionBuilder withUpdatedAt(DateTime? updatedAt) {
    _updatedAt = updatedAt;
    return this;
  }

  /// Builds the medication session
  MedicationSession build() {
    return MedicationSession(
      id: _id,
      petId: _petId,
      userId: _userId,
      dateTime: _dateTime,
      medicationName: _medicationName,
      dosageGiven: _dosageGiven,
      dosageScheduled: _dosageScheduled,
      medicationUnit: _medicationUnit,
      medicationStrengthAmount: _medicationStrengthAmount,
      medicationStrengthUnit: _medicationStrengthUnit,
      customMedicationStrengthUnit: _customMedicationStrengthUnit,
      completed: _completed,
      notes: _notes,
      scheduleId: _scheduleId,
      scheduledTime: _scheduledTime,
      createdAt: _createdAt,
      syncedAt: _syncedAt,
      updatedAt: _updatedAt,
    );
  }
}

/// Builder for creating [FluidSession] test instances
class FluidSessionBuilder {
  /// Creates a fluid session builder with sensible defaults
  FluidSessionBuilder() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _id = 'test-fluid-session-$timestamp-${_globalIdCounter++}';
    _petId = 'test-pet-id';
    _userId = 'test-user-id';
    _dateTime = DateTime(2024, 1, 15, 8);
    _volumeGiven = 100.0;
    _createdAt = DateTime(2024, 1, 15, 8);
  }

  /// Creates a builder with high volume
  factory FluidSessionBuilder.highVolume() {
    return FluidSessionBuilder()..withVolumeGiven(200);
  }

  /// Creates a builder with low volume
  factory FluidSessionBuilder.lowVolume() {
    return FluidSessionBuilder()..withVolumeGiven(50);
  }

  late String _id;
  late String _petId;
  late String _userId;
  late DateTime _dateTime;
  late double _volumeGiven;
  late DateTime _createdAt;
  FluidLocation? _injectionSite;
  String? _stressLevel;
  String? _notes;
  String? _scheduleId;
  DateTime? _scheduledTime;
  DateTime? _syncedAt;
  DateTime? _updatedAt;

  /// Sets the session ID
  FluidSessionBuilder withId(String id) {
    _id = id;
    return this;
  }

  /// Sets the pet ID
  FluidSessionBuilder withPetId(String petId) {
    _petId = petId;
    return this;
  }

  /// Sets the user ID
  FluidSessionBuilder withUserId(String userId) {
    _userId = userId;
    return this;
  }

  /// Sets the date/time
  FluidSessionBuilder withDateTime(DateTime dateTime) {
    _dateTime = dateTime;
    return this;
  }

  /// Sets the volume given
  FluidSessionBuilder withVolumeGiven(double volume) {
    _volumeGiven = volume;
    return this;
  }

  /// Sets the injection site
  FluidSessionBuilder withInjectionSite(FluidLocation? site) {
    _injectionSite = site;
    return this;
  }

  /// Sets the stress level
  FluidSessionBuilder withStressLevel(String? level) {
    _stressLevel = level;
    return this;
  }

  /// Sets notes
  FluidSessionBuilder withNotes(String notes) {
    _notes = notes;
    return this;
  }

  /// Sets schedule ID
  FluidSessionBuilder withScheduleId(String? scheduleId) {
    _scheduleId = scheduleId;
    return this;
  }

  /// Sets scheduled time
  FluidSessionBuilder withScheduledTime(DateTime? scheduledTime) {
    _scheduledTime = scheduledTime;
    return this;
  }

  /// Sets created at timestamp
  FluidSessionBuilder withCreatedAt(DateTime createdAt) {
    _createdAt = createdAt;
    return this;
  }

  /// Sets synced at timestamp
  FluidSessionBuilder withSyncedAt(DateTime? syncedAt) {
    _syncedAt = syncedAt;
    return this;
  }

  /// Sets updated at timestamp
  FluidSessionBuilder withUpdatedAt(DateTime? updatedAt) {
    _updatedAt = updatedAt;
    return this;
  }

  /// Builds the fluid session
  FluidSession build() {
    return FluidSession(
      id: _id,
      petId: _petId,
      userId: _userId,
      dateTime: _dateTime,
      volumeGiven: _volumeGiven,
      injectionSite: _injectionSite,
      stressLevel: _stressLevel,
      notes: _notes,
      scheduleId: _scheduleId,
      scheduledTime: _scheduledTime,
      createdAt: _createdAt,
      syncedAt: _syncedAt,
      updatedAt: _updatedAt,
    );
  }
}

/// Builder for creating [Schedule] test instances
class ScheduleBuilder {
  /// Creates a schedule builder with sensible defaults
  ScheduleBuilder() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _id = 'test-schedule-$timestamp-${_globalIdCounter++}';
    _treatmentType = TreatmentType.medication;
    _frequency = TreatmentFrequency.onceDaily;
    _isActive = true;
    _reminderTimes = [DateTime(2024, 1, 15, 8)];
    _createdAt = DateTime(2024, 1, 15);
    _updatedAt = DateTime(2024, 1, 15);
  }

  /// Creates a medication schedule builder
  factory ScheduleBuilder.medication(String medicationName) {
    return ScheduleBuilder()
      ..withMedicationName(medicationName)
      ..withTargetDosage(1)
      ..withMedicationUnit('pills');
  }

  /// Creates a fluid schedule builder
  factory ScheduleBuilder.fluid() {
    return ScheduleBuilder()
      ..withTreatmentType(TreatmentType.fluid)
      ..withTargetVolume(100)
      ..withPreferredLocation(FluidLocation.shoulderBladeLeft);
  }

  /// Creates a schedule with reminder today
  factory ScheduleBuilder.withReminderToday() {
    final now = DateTime.now();
    return ScheduleBuilder()..withReminderTime(now);
  }

  late String _id;
  late TreatmentType _treatmentType;
  late TreatmentFrequency _frequency;
  late bool _isActive;
  late List<DateTime> _reminderTimes;
  late DateTime _createdAt;
  late DateTime _updatedAt;
  String? _medicationName;
  double? _targetDosage;
  String? _medicationUnit;
  String? _medicationStrengthAmount;
  String? _medicationStrengthUnit;
  String? _customMedicationStrengthUnit;
  double? _targetVolume;
  FluidLocation? _preferredLocation;

  /// Sets the schedule ID
  ScheduleBuilder withId(String id) {
    _id = id;
    return this;
  }

  /// Sets the active status
  ScheduleBuilder withIsActive({required bool isActive}) {
    _isActive = isActive;
    return this;
  }

  /// Sets the treatment type
  ScheduleBuilder withTreatmentType(TreatmentType type) {
    _treatmentType = type;
    return this;
  }

  /// Sets the medication name
  ScheduleBuilder withMedicationName(String name) {
    _medicationName = name;
    return this;
  }

  /// Sets the target dosage
  ScheduleBuilder withTargetDosage(double dosage) {
    _targetDosage = dosage;
    return this;
  }

  /// Sets the medication unit
  ScheduleBuilder withMedicationUnit(String unit) {
    _medicationUnit = unit;
    return this;
  }

  /// Sets the medication strength
  ScheduleBuilder withStrength(String amount, String unit) {
    _medicationStrengthAmount = amount;
    _medicationStrengthUnit = unit;
    return this;
  }

  /// Sets custom medication strength unit
  ScheduleBuilder withCustomStrengthUnit(String unit) {
    _customMedicationStrengthUnit = unit;
    return this;
  }

  /// Sets the target volume
  ScheduleBuilder withTargetVolume(double volume) {
    _targetVolume = volume;
    return this;
  }

  /// Sets the preferred location
  ScheduleBuilder withPreferredLocation(FluidLocation location) {
    _preferredLocation = location;
    return this;
  }

  /// Sets a single reminder time
  ScheduleBuilder withReminderTime(DateTime dateTime) {
    _reminderTimes = [dateTime];
    return this;
  }

  /// Sets multiple reminder times
  ScheduleBuilder withReminderTimes(List<DateTime> times) {
    _reminderTimes = times;
    return this;
  }

  /// Builds the schedule
  Schedule build() {
    return Schedule(
      id: _id,
      treatmentType: _treatmentType,
      frequency: _frequency,
      isActive: _isActive,
      reminderTimes: _reminderTimes,
      createdAt: _createdAt,
      updatedAt: _updatedAt,
      medicationName: _medicationName,
      targetDosage: _targetDosage,
      medicationUnit: _medicationUnit,
      medicationStrengthAmount: _medicationStrengthAmount,
      medicationStrengthUnit: _medicationStrengthUnit,
      customMedicationStrengthUnit: _customMedicationStrengthUnit,
      targetVolume: _targetVolume,
      preferredLocation: _preferredLocation,
    );
  }
}

// ============================================
// Integration Test Extensions
// ============================================

/// Extension methods for integration-specific test scenarios
extension ScheduleBuilderIntegrationExtensions on ScheduleBuilder {
  /// Creates schedule with today's reminder at specified time
  ///
  /// Used for integration tests that need schedules matching today's date.
  static ScheduleBuilder withTodaysReminder({
    String? medicationName,
    int hour = 8,
    int minute = 0,
  }) {
    final now = DateTime.now();
    final reminderTime = DateTime(now.year, now.month, now.day, hour, minute);

    return ScheduleBuilder()
      ..withReminderTimes([reminderTime])
      ..withIsActive(isActive: true)
      ..withMedicationName(medicationName ?? 'Amlodipine')
      ..withTargetDosage(2.5)
      ..withMedicationUnit('mg');
  }

  /// Creates schedule with multiple reminders for today
  ///
  /// Used for quick-log testing with multiple reminder times.
  static ScheduleBuilder withMultipleReminders(
    List<int> hours, {
    String? medicationName,
  }) {
    final now = DateTime.now();
    final reminderTimes = hours
        .map(
          (hour) => DateTime(now.year, now.month, now.day, hour),
        )
        .toList();

    return ScheduleBuilder()
      ..withReminderTimes(reminderTimes)
      ..withIsActive(isActive: true)
      ..withMedicationName(medicationName ?? 'Amlodipine')
      ..withTargetDosage(2.5)
      ..withMedicationUnit('mg');
  }

  /// Creates fluid schedule with today's reminder
  static ScheduleBuilder withFluidTodaysReminder({
    int hour = 8,
    int minute = 0,
    double targetVolume = 100.0,
  }) {
    final now = DateTime.now();
    final reminderTime = DateTime(now.year, now.month, now.day, hour, minute);

    // Use fluid factory constructor to set treatment type
    return ScheduleBuilder.fluid()
      ..withReminderTimes([reminderTime])
      ..withTargetVolume(targetVolume)
      ..withIsActive(isActive: true);
  }
}

/// Extension methods for medication session integration tests
extension MedicationSessionBuilderIntegrationExtensions
    on MedicationSessionBuilder {
  /// Creates session for duplicate detection testing
  ///
  /// Session will be within ±15 minute window for duplicate testing.
  static MedicationSessionBuilder forDuplicateTest(
    DateTime baseTime, {
    int minuteOffset = 10,
  }) {
    return MedicationSessionBuilder()
      ..withDateTime(baseTime.add(Duration(minutes: minuteOffset)))
      ..withMedicationName('Amlodipine')
      ..withDosageGiven(1);
  }

  /// Creates session pre-filled from schedule data
  ///
  /// Used for testing schedule-to-session conversion.
  static MedicationSessionBuilder fromSchedule(Schedule schedule) {
    if (schedule.treatmentType != TreatmentType.medication) {
      throw ArgumentError('Schedule must be medication type');
    }

    final reminderTime = schedule.reminderTimes.first;

    return MedicationSessionBuilder()
      ..withMedicationName(schedule.medicationName!)
      ..withDosageGiven(schedule.targetDosage!)
      ..withDosageScheduled(schedule.targetDosage!)
      ..withMedicationUnit(schedule.medicationUnit!)
      ..withDateTime(reminderTime)
      ..withScheduleId(schedule.id)
      ..withScheduledTime(reminderTime);
  }
}

/// Extension methods for fluid session integration tests
extension FluidSessionBuilderIntegrationExtensions on FluidSessionBuilder {
  /// Creates fluid session pre-filled from schedule data
  ///
  /// Used for testing schedule-to-session conversion.
  static FluidSessionBuilder fromSchedule(Schedule schedule) {
    if (schedule.treatmentType != TreatmentType.fluid) {
      throw ArgumentError('Schedule must be fluid therapy type');
    }

    final reminderTime = schedule.reminderTimes.first;

    return FluidSessionBuilder()
      ..withVolumeGiven(schedule.targetVolume!)
      ..withDateTime(reminderTime)
      ..withInjectionSite(
        schedule.preferredLocation ?? FluidLocation.shoulderBladeLeft,
      )
      ..withScheduleId(schedule.id)
      ..withScheduledTime(reminderTime);
  }
}

/// Builder for DailySummary test data
class DailySummaryBuilder {
  /// Creates a daily summary builder with sensible defaults
  DailySummaryBuilder() {
    _date = DateTime(2024, 1, 15);
    _medicationTotalDoses = 0;
    _medicationScheduledDoses = 0;
    _medicationMissedCount = 0;
    _fluidTotalVolume = 0.0;
    _fluidSessionCount = 0;
    _overallTreatmentDone = false;
    _overallAdherence = 0.0;
    _overallStreak = 0;
    _createdAt = DateTime(2024, 1, 15);
    _updatedAt = DateTime(2024, 1, 15);
  }

  late DateTime _date;
  late int _medicationTotalDoses;
  late int _medicationScheduledDoses;
  late int _medicationMissedCount;
  late double _fluidTotalVolume;
  late int _fluidSessionCount;
  late bool _overallTreatmentDone;
  late double _overallAdherence;
  late int _overallStreak;
  late DateTime _createdAt;
  late DateTime _updatedAt;

  /// Sets the date
  DailySummaryBuilder withDate(DateTime date) {
    _date = date;
    return this;
  }

  /// Sets medication count
  DailySummaryBuilder withMedicationCount(int count) {
    _medicationTotalDoses = count;
    return this;
  }

  /// Sets medication scheduled doses
  DailySummaryBuilder withMedicationScheduled(int count) {
    _medicationScheduledDoses = count;
    return this;
  }

  /// Sets medication missed count
  DailySummaryBuilder withMedicationMissed(int count) {
    _medicationMissedCount = count;
    return this;
  }

  /// Sets fluid volume
  DailySummaryBuilder withFluidVolume(double volume) {
    _fluidTotalVolume = volume;
    return this;
  }

  /// Sets fluid session count
  DailySummaryBuilder withFluidSessionCount(int count) {
    _fluidSessionCount = count;
    return this;
  }

  /// Sets treatment done status
  DailySummaryBuilder withTreatmentDone({required bool done}) {
    _overallTreatmentDone = done;
    return this;
  }

  /// Sets adherence percentage
  DailySummaryBuilder withAdherence(double adherence) {
    _overallAdherence = adherence;
    return this;
  }

  /// Sets streak
  DailySummaryBuilder withStreak(int streak) {
    _overallStreak = streak;
    return this;
  }

  /// Builds the daily summary (returns map for Firestore)
  Map<String, dynamic> buildMap() {
    return {
      'date': _date,
      'medicationTotalDoses': _medicationTotalDoses,
      'medicationScheduledDoses': _medicationScheduledDoses,
      'medicationMissedCount': _medicationMissedCount,
      'fluidTotalVolume': _fluidTotalVolume,
      'fluidSessionCount': _fluidSessionCount,
      'overallTreatmentDone': _overallTreatmentDone,
      'overallAdherence': _overallAdherence,
      'overallStreak': _overallStreak,
      'createdAt': _createdAt,
      'updatedAt': _updatedAt,
    };
  }
}
