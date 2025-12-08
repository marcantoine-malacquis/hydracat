/// Test data builders for profile feature tests
///
/// Provides builder classes for creating test data with sensible defaults
/// and fluent API for readability.
// ignore_for_file: avoid_returning_this

library;

import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/models/medical_info.dart';
import 'package:hydracat/features/profile/models/schedule.dart';

// Global counter to ensure unique IDs even in same millisecond
int _globalIdCounter = 0;

/// Builder for creating [CatProfile] test instances
class CatProfileBuilder {
  /// Creates a cat profile builder with sensible defaults
  CatProfileBuilder() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _id = 'test-pet-$timestamp-${_globalIdCounter++}';
    _userId = 'test-user-id';
    _name = 'Fluffy';
    _ageYears = 8;
    _weightKg = 4.5;
    _medicalInfo = const MedicalInfo();
    _createdAt = DateTime(2024, 1, 1, 10);
    _updatedAt = DateTime(2024, 1, 1, 10);
  }

  /// Creates a valid cat profile builder (typical CKD cat)
  factory CatProfileBuilder.valid() {
    return CatProfileBuilder()
      ..withAge(10)
      ..withWeight(4)
      ..withMedicalInfo(
        MedicalInfoBuilder()
            .withCkdDiagnosisDate(DateTime(2022, 6, 15))
            .withIrisStage(IrisStage.stage2)
            .build(),
      );
  }

  /// Creates a senior cat profile builder
  factory CatProfileBuilder.senior() {
    return CatProfileBuilder()
      ..withAge(15)
      ..withWeight(3.5)
      ..withMedicalInfo(
        MedicalInfoBuilder()
            .withCkdDiagnosisDate(DateTime(2020, 3, 10))
            .withIrisStage(IrisStage.stage3)
            .build(),
      );
  }

  /// Creates a young cat profile builder
  factory CatProfileBuilder.young() {
    return CatProfileBuilder()
      ..withAge(2)
      ..withWeight(4.8);
  }

  late String _id;
  late String _userId;
  late String _name;
  late int _ageYears;
  double? _weightKg;
  MedicalInfo _medicalInfo = const MedicalInfo();
  late DateTime _createdAt;
  late DateTime _updatedAt;
  String? _photoUrl;
  String? _breed;
  String? _gender;

  /// Sets the profile ID
  CatProfileBuilder withId(String id) {
    _id = id;
    return this;
  }

  /// Sets the user ID
  CatProfileBuilder withUserId(String userId) {
    _userId = userId;
    return this;
  }

  /// Sets the pet name
  CatProfileBuilder withName(String name) {
    _name = name;
    return this;
  }

  /// Sets the pet age
  CatProfileBuilder withAge(int ageYears) {
    _ageYears = ageYears;
    return this;
  }

  /// Sets the pet weight in kg
  CatProfileBuilder withWeight(double? weightKg) {
    _weightKg = weightKg;
    return this;
  }

  /// Sets the medical information
  CatProfileBuilder withMedicalInfo(MedicalInfo medicalInfo) {
    _medicalInfo = medicalInfo;
    return this;
  }

  /// Sets the created timestamp
  CatProfileBuilder withCreatedAt(DateTime createdAt) {
    _createdAt = createdAt;
    return this;
  }

  /// Sets the updated timestamp
  CatProfileBuilder withUpdatedAt(DateTime updatedAt) {
    _updatedAt = updatedAt;
    return this;
  }

  /// Sets the photo URL
  CatProfileBuilder withPhotoUrl(String? photoUrl) {
    _photoUrl = photoUrl;
    return this;
  }

  /// Sets the breed
  CatProfileBuilder withBreed(String? breed) {
    _breed = breed;
    return this;
  }

  /// Sets the gender
  CatProfileBuilder withGender(String? gender) {
    _gender = gender;
    return this;
  }

  /// Builds the CatProfile instance
  CatProfile build() {
    return CatProfile(
      id: _id,
      userId: _userId,
      name: _name,
      ageYears: _ageYears,
      weightKg: _weightKg,
      medicalInfo: _medicalInfo,
      createdAt: _createdAt,
      updatedAt: _updatedAt,
      photoUrl: _photoUrl,
      breed: _breed,
      gender: _gender,
    );
  }
}

/// Builder for creating [MedicalInfo] test instances
class MedicalInfoBuilder {
  /// Creates a medical info builder with sensible defaults
  MedicalInfoBuilder();

  /// Creates a complete CKD medical info builder
  factory MedicalInfoBuilder.complete() {
    return MedicalInfoBuilder()
      ..withCkdDiagnosisDate(DateTime(2022, 6, 15))
      ..withIrisStage(IrisStage.stage2)
      ..withLabValues(LabValuesBuilder().build());
  }

  DateTime? _ckdDiagnosisDate;
  IrisStage? _irisStage;
  LabValues? _labValues;

  /// Sets the CKD diagnosis date
  MedicalInfoBuilder withCkdDiagnosisDate(DateTime? date) {
    _ckdDiagnosisDate = date;
    return this;
  }

  /// Sets the IRIS stage
  MedicalInfoBuilder withIrisStage(IrisStage? stage) {
    _irisStage = stage;
    return this;
  }

  /// Sets the lab values
  MedicalInfoBuilder withLabValues(LabValues? labValues) {
    _labValues = labValues;
    return this;
  }

  /// Builds the MedicalInfo instance
  MedicalInfo build() {
    return MedicalInfo(
      ckdDiagnosisDate: _ckdDiagnosisDate,
      irisStage: _irisStage,
      labValues: _labValues,
    );
  }
}

/// Builder for creating [LabValues] test instances
class LabValuesBuilder {
  /// Creates a lab values builder with sensible defaults
  LabValuesBuilder() {
    _bloodworkDate = DateTime(2024, 1, 10);
    _creatinineMgDl = 2.1;
    _bunMgDl = 35.0;
    _sdmaMcgDl = 18.0;
  }

  /// Creates lab values for Stage 2 CKD
  factory LabValuesBuilder.stage2() {
    return LabValuesBuilder()
      ..withCreatinine(2)
      ..withBun(32)
      ..withSdma(16);
  }

  /// Creates lab values for Stage 3 CKD
  factory LabValuesBuilder.stage3() {
    return LabValuesBuilder()
      ..withCreatinine(3.2)
      ..withBun(55)
      ..withSdma(28);
  }

  /// Creates elevated lab values
  factory LabValuesBuilder.elevated() {
    return LabValuesBuilder()
      ..withCreatinine(4.5)
      ..withBun(75)
      ..withSdma(35);
  }

  DateTime? _bloodworkDate;
  double? _creatinineMgDl;
  double? _bunMgDl;
  double? _sdmaMcgDl;

  /// Sets the bloodwork date
  LabValuesBuilder withBloodworkDate(DateTime? date) {
    _bloodworkDate = date;
    return this;
  }

  /// Sets the creatinine level
  LabValuesBuilder withCreatinine(double? value) {
    _creatinineMgDl = value;
    return this;
  }

  /// Sets the BUN level
  LabValuesBuilder withBun(double? value) {
    _bunMgDl = value;
    return this;
  }

  /// Sets the SDMA level
  LabValuesBuilder withSdma(double? value) {
    _sdmaMcgDl = value;
    return this;
  }

  /// Builds the LabValues instance
  LabValues build() {
    return LabValues(
      bloodworkDate: _bloodworkDate,
      creatinineMgDl: _creatinineMgDl,
      bunMgDl: _bunMgDl,
      sdmaMcgDl: _sdmaMcgDl,
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
    _reminderTimes = [DateTime(2024, 1, 15, 9)];
    _isActive = true;
    _createdAt = DateTime(2024, 1, 1, 10);
    _updatedAt = DateTime(2024, 1, 1, 10);
  }

  /// Creates a medication schedule builder
  factory ScheduleBuilder.medication() {
    return ScheduleBuilder()
      ..asMedication()
      ..withMedicationName('Amlodipine')
      ..withTargetDosage(1)
      ..withMedicationUnit('pills')
      ..withFrequency(TreatmentFrequency.onceDaily)
      ..withReminderTimes([DateTime(2024, 1, 15, 9)]);
  }

  /// Creates a fluid schedule builder
  factory ScheduleBuilder.fluid() {
    return ScheduleBuilder()
      ..asFluid()
      ..withTargetVolume(150)
      ..withPreferredLocation(FluidLocation.shoulderBladeLeft)
      ..withNeedleGauge('18G')
      ..withFrequency(TreatmentFrequency.onceDaily)
      ..withReminderTimes([DateTime(2024, 1, 15, 19)]);
  }

  /// Creates a twice-daily medication schedule
  factory ScheduleBuilder.twiceDaily() {
    return ScheduleBuilder.medication()
      ..withFrequency(TreatmentFrequency.twiceDaily)
      ..withReminderTimes([
        DateTime(2024, 1, 15, 8),
        DateTime(2024, 1, 15, 20),
      ]);
  }

  late String _id;
  late TreatmentType _treatmentType;
  late TreatmentFrequency _frequency;
  late List<DateTime> _reminderTimes;
  late bool _isActive;
  late DateTime _createdAt;
  late DateTime _updatedAt;
  double? _targetVolume;
  FluidLocation? _preferredLocation;
  String? _needleGauge;
  String? _medicationName;
  double? _targetDosage;
  String? _medicationUnit;
  String? _medicationStrengthAmount;
  String? _medicationStrengthUnit;
  String? _customMedicationStrengthUnit;

  /// Sets the schedule ID
  ScheduleBuilder withId(String id) {
    _id = id;
    return this;
  }

  /// Sets as medication schedule
  ScheduleBuilder asMedication() {
    _treatmentType = TreatmentType.medication;
    return this;
  }

  /// Sets as fluid schedule
  ScheduleBuilder asFluid() {
    _treatmentType = TreatmentType.fluid;
    return this;
  }

  /// Sets the treatment frequency
  ScheduleBuilder withFrequency(TreatmentFrequency frequency) {
    _frequency = frequency;
    return this;
  }

  /// Sets the reminder times
  ScheduleBuilder withReminderTimes(List<DateTime> times) {
    _reminderTimes = times;
    return this;
  }

  /// Sets the active status
  ScheduleBuilder withIsActive({required bool isActive}) {
    _isActive = isActive;
    return this;
  }

  /// Sets the created timestamp
  ScheduleBuilder withCreatedAt(DateTime createdAt) {
    _createdAt = createdAt;
    return this;
  }

  /// Sets the updated timestamp
  ScheduleBuilder withUpdatedAt(DateTime updatedAt) {
    _updatedAt = updatedAt;
    return this;
  }

  /// Sets the target volume (for fluid schedules)
  ScheduleBuilder withTargetVolume(double? volume) {
    _targetVolume = volume;
    return this;
  }

  /// Sets the preferred location (for fluid schedules)
  ScheduleBuilder withPreferredLocation(FluidLocation? location) {
    _preferredLocation = location;
    return this;
  }

  /// Sets the needle gauge (for fluid schedules)
  ScheduleBuilder withNeedleGauge(String? gauge) {
    _needleGauge = gauge;
    return this;
  }

  /// Sets the medication name
  ScheduleBuilder withMedicationName(String? name) {
    _medicationName = name;
    return this;
  }

  /// Sets the target dosage
  ScheduleBuilder withTargetDosage(double? dosage) {
    _targetDosage = dosage;
    return this;
  }

  /// Sets the medication unit
  ScheduleBuilder withMedicationUnit(String? unit) {
    _medicationUnit = unit;
    return this;
  }

  /// Sets the medication strength amount
  ScheduleBuilder withMedicationStrengthAmount(String? amount) {
    _medicationStrengthAmount = amount;
    return this;
  }

  /// Sets the medication strength unit
  ScheduleBuilder withMedicationStrengthUnit(String? unit) {
    _medicationStrengthUnit = unit;
    return this;
  }

  /// Sets the custom medication strength unit
  ScheduleBuilder withCustomMedicationStrengthUnit(String? unit) {
    _customMedicationStrengthUnit = unit;
    return this;
  }

  /// Builds the Schedule instance
  Schedule build() {
    return Schedule(
      id: _id,
      treatmentType: _treatmentType,
      frequency: _frequency,
      reminderTimes: _reminderTimes,
      isActive: _isActive,
      createdAt: _createdAt,
      updatedAt: _updatedAt,
      targetVolume: _targetVolume,
      preferredLocation: _preferredLocation,
      needleGauge: _needleGauge,
      medicationName: _medicationName,
      targetDosage: _targetDosage,
      medicationUnit: _medicationUnit,
      medicationStrengthAmount: _medicationStrengthAmount,
      medicationStrengthUnit: _medicationStrengthUnit,
      customMedicationStrengthUnit: _customMedicationStrengthUnit,
    );
  }
}
