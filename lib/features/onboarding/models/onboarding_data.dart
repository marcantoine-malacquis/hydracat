// Required for clearMedicalInfo() and clearTreatmentInfo() methods
// where null values are explicitly passed to clear existing data
// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/foundation.dart';

import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/models/medical_info.dart';
import 'package:hydracat/features/profile/models/user_persona.dart';

/// Temporary data collection during onboarding flow
@immutable
class OnboardingData {
  /// Creates an [OnboardingData] instance
  const OnboardingData({
    this.userId,
    this.treatmentApproach,
    this.petName,
    this.petAge,
    this.petDateOfBirth,
    this.petGender,
    this.petBreed,
    this.petWeightKg,
    this.ckdDiagnosisDate,
    this.irisStage,
    this.notes,
    this.hasSkippedWelcome = false,
    this.useMetricUnits = true,
    this.bloodworkDate,
    this.creatinineMgDl,
    this.bunMgDl,
    this.sdmaMcgDl,
    this.medications,
    this.fluidTherapy,
  });

  /// Creates empty initial data
  const OnboardingData.empty()
    : userId = null,
      treatmentApproach = null,
      petName = null,
      petAge = null,
      petDateOfBirth = null,
      petGender = null,
      petBreed = null,
      petWeightKg = null,
      ckdDiagnosisDate = null,
      irisStage = null,
      notes = null,
      hasSkippedWelcome = false,
      useMetricUnits = true,
      bloodworkDate = null,
      creatinineMgDl = null,
      bunMgDl = null,
      sdmaMcgDl = null,
      medications = null,
      fluidTherapy = null;

  /// Creates an [OnboardingData] from JSON data
  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      userId: json['userId'] as String?,
      treatmentApproach: json['treatmentApproach'] != null
          ? UserPersona.fromString(json['treatmentApproach'] as String)
          : null,
      petName: json['petName'] as String?,
      petAge: json['petAge'] as int?,
      petDateOfBirth: json['petDateOfBirth'] != null
          ? DateTime.parse(json['petDateOfBirth'] as String)
          : null,
      petGender: json['petGender'] as String?,
      petBreed: json['petBreed'] as String?,
      petWeightKg: json['petWeightKg'] != null
          ? (json['petWeightKg'] as num).toDouble()
          : null,
      ckdDiagnosisDate: json['ckdDiagnosisDate'] != null
          ? DateTime.parse(json['ckdDiagnosisDate'] as String)
          : null,
      irisStage: json['irisStage'] != null
          ? IrisStage.fromString(json['irisStage'] as String)
          : null,
      notes: json['notes'] as String?,
      hasSkippedWelcome: json['hasSkippedWelcome'] as bool? ?? false,
      useMetricUnits: json['useMetricUnits'] as bool? ?? true,
      bloodworkDate: json['bloodworkDate'] != null
          ? DateTime.parse(json['bloodworkDate'] as String)
          : null,
      creatinineMgDl: json['creatinineMgDl'] != null
          ? (json['creatinineMgDl'] as num).toDouble()
          : null,
      bunMgDl: json['bunMgDl'] != null
          ? (json['bunMgDl'] as num).toDouble()
          : null,
      sdmaMcgDl: json['sdmaMcgDl'] != null
          ? (json['sdmaMcgDl'] as num).toDouble()
          : null,
      medications: json['medications'] != null
          ? (json['medications'] as List<dynamic>)
                .map((e) => MedicationData.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      fluidTherapy: json['fluidTherapy'] != null
          ? FluidTherapyData.fromJson(
              json['fluidTherapy'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// User ID (if authenticated)
  final String? userId;

  /// Selected treatment approach/persona
  final UserPersona? treatmentApproach;

  /// Pet's name
  final String? petName;

  /// Pet's age in years
  final int? petAge;

  /// Pet's date of birth
  final DateTime? petDateOfBirth;

  /// Pet's gender ('male' or 'female')
  final String? petGender;

  /// Pet's breed
  final String? petBreed;

  /// Pet's weight in kilograms
  final double? petWeightKg;

  /// Date when CKD was diagnosed
  final DateTime? ckdDiagnosisDate;

  /// Current IRIS stage
  final IrisStage? irisStage;

  /// Additional notes
  final String? notes;

  /// Whether the user skipped the welcome screen
  final bool hasSkippedWelcome;

  /// Whether to use metric units (kg) vs imperial (lbs)
  final bool useMetricUnits;

  /// Date when bloodwork was performed
  final DateTime? bloodworkDate;

  /// Creatinine level in mg/dL
  final double? creatinineMgDl;

  /// Blood Urea Nitrogen (BUN) level in mg/dL
  final double? bunMgDl;

  /// Symmetric Dimethylarginine (SDMA) level in μg/dL
  final double? sdmaMcgDl;

  /// List of medications for treatment
  final List<MedicationData>? medications;

  /// Fluid therapy configuration
  final FluidTherapyData? fluidTherapy;

  /// Pet's weight in pounds (converted from kg)
  double? get petWeightLbs =>
      petWeightKg != null ? petWeightKg! * 2.20462 : null;

  /// Whether persona selection is complete
  bool get hasPersonaSelection => treatmentApproach != null;

  /// Whether basic pet info is complete
  bool get hasBasicPetInfo =>
      petName != null && petName!.isNotEmpty && petAge != null && petAge! > 0;

  /// Whether we have minimum required data for first checkpoint
  bool get hasMinimumData => hasPersonaSelection && hasBasicPetInfo;

  /// Whether treatment setup is relevant (based on persona)
  bool get needsTreatmentSetup => treatmentApproach != null;

  /// Whether any lab values are present
  bool get hasLabValues =>
      creatinineMgDl != null || bunMgDl != null || sdmaMcgDl != null;

  /// Whether lab values have complete data (values + bloodwork date)
  bool get hasCompleteLabData => hasLabValues && bloodworkDate != null;

  /// Whether medical info has any data
  bool get hasMedicalInfo =>
      ckdDiagnosisDate != null ||
      irisStage != null ||
      (notes != null && notes!.isNotEmpty) ||
      hasLabValues;

  /// Whether any treatment data is present
  bool get hasTreatmentData {
    return (medications != null && medications!.isNotEmpty) ||
        fluidTherapy != null;
  }

  /// Whether treatment setup is complete based on selected persona
  bool get isTreatmentSetupComplete {
    if (treatmentApproach == null) return false;

    return switch (treatmentApproach!) {
      UserPersona.medicationOnly =>
        medications != null && medications!.isNotEmpty,
      UserPersona.fluidTherapyOnly => fluidTherapy != null,
      UserPersona.medicationAndFluidTherapy =>
        medications != null && medications!.isNotEmpty && fluidTherapy != null,
    };
  }

  /// Whether data is complete enough for final profile creation
  bool get isReadyForProfileCreation {
    if (!hasMinimumData) return false;

    // For treatment-only personas, medical info is optional
    if (treatmentApproach == UserPersona.fluidTherapyOnly) {
      return isTreatmentSetupComplete;
    }

    // For other personas, require medical info OR treatment setup
    return (hasMedicalInfo || ckdDiagnosisDate != null) &&
        (!needsTreatmentSetup || isTreatmentSetupComplete);
  }

  /// Converts [OnboardingData] to JSON data
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'treatmentApproach': treatmentApproach?.name,
      'petName': petName,
      'petAge': petAge,
      'petDateOfBirth': petDateOfBirth?.toIso8601String(),
      'petGender': petGender,
      'petBreed': petBreed,
      'petWeightKg': petWeightKg,
      'ckdDiagnosisDate': ckdDiagnosisDate?.toIso8601String(),
      'irisStage': irisStage?.name,
      'notes': notes,
      'hasSkippedWelcome': hasSkippedWelcome,
      'useMetricUnits': useMetricUnits,
      'bloodworkDate': bloodworkDate?.toIso8601String(),
      'creatinineMgDl': creatinineMgDl,
      'bunMgDl': bunMgDl,
      'sdmaMcgDl': sdmaMcgDl,
      'medications': medications?.map((e) => e.toJson()).toList(),
      'fluidTherapy': fluidTherapy?.toJson(),
    };
  }

  /// Creates a copy of this [OnboardingData] with the given fields replaced
  OnboardingData copyWith({
    String? userId,
    UserPersona? treatmentApproach,
    String? petName,
    int? petAge,
    DateTime? petDateOfBirth,
    String? petGender,
    String? petBreed,
    double? petWeightKg,
    DateTime? ckdDiagnosisDate,
    IrisStage? irisStage,
    String? notes,
    bool? hasSkippedWelcome,
    bool? useMetricUnits,
    DateTime? bloodworkDate,
    double? creatinineMgDl,
    double? bunMgDl,
    double? sdmaMcgDl,
    List<MedicationData>? medications,
    FluidTherapyData? fluidTherapy,
  }) {
    return OnboardingData(
      userId: userId ?? this.userId,
      treatmentApproach: treatmentApproach ?? this.treatmentApproach,
      petName: petName ?? this.petName,
      petAge: petAge ?? this.petAge,
      petDateOfBirth: petDateOfBirth ?? this.petDateOfBirth,
      petGender: petGender ?? this.petGender,
      petBreed: petBreed ?? this.petBreed,
      petWeightKg: petWeightKg ?? this.petWeightKg,
      ckdDiagnosisDate: ckdDiagnosisDate ?? this.ckdDiagnosisDate,
      irisStage: irisStage ?? this.irisStage,
      notes: notes ?? this.notes,
      hasSkippedWelcome: hasSkippedWelcome ?? this.hasSkippedWelcome,
      useMetricUnits: useMetricUnits ?? this.useMetricUnits,
      bloodworkDate: bloodworkDate ?? this.bloodworkDate,
      creatinineMgDl: creatinineMgDl ?? this.creatinineMgDl,
      bunMgDl: bunMgDl ?? this.bunMgDl,
      sdmaMcgDl: sdmaMcgDl ?? this.sdmaMcgDl,
      medications: medications ?? this.medications,
      fluidTherapy: fluidTherapy ?? this.fluidTherapy,
    );
  }

  /// Updates weight with a new value in kilograms
  OnboardingData updateWeightKg(double newWeightKg) {
    return copyWith(petWeightKg: newWeightKg);
  }

  /// Updates weight with a new value in pounds (converted to kg)
  OnboardingData updateWeightLbs(double newWeightLbs) {
    return updateWeightKg(newWeightLbs / 2.20462);
  }

  /// Clears all medical information
  OnboardingData clearMedicalInfo() {
    // We need to explicitly pass null values to clear existing medical data
    return copyWith(
      ckdDiagnosisDate: null,
      irisStage: null,
      notes: null,
      bloodworkDate: null,
      creatinineMgDl: null,
      bunMgDl: null,
      sdmaMcgDl: null,
    );
  }

  /// Clears all treatment information
  OnboardingData clearTreatmentInfo() {
    // We need to explicitly pass null values to clear existing treatment data
    return copyWith(
      medications: null,
      fluidTherapy: null,
    );
  }

  /// Adds a medication to the medications list
  OnboardingData addMedication(MedicationData medication) {
    final currentMedications = medications ?? <MedicationData>[];
    return copyWith(
      medications: [...currentMedications, medication],
    );
  }

  /// Removes a medication from the medications list
  OnboardingData removeMedication(int index) {
    if (medications == null || index < 0 || index >= medications!.length) {
      return this;
    }
    final updatedMedications = List<MedicationData>.from(medications!)
      ..removeAt(index);
    return copyWith(
      medications: updatedMedications,
    );
  }

  /// Updates a medication at the given index
  OnboardingData updateMedication(int index, MedicationData medication) {
    if (medications == null || index < 0 || index >= medications!.length) {
      return this;
    }
    final updatedMedications = List<MedicationData>.from(medications!);
    updatedMedications[index] = medication;
    return copyWith(medications: updatedMedications);
  }

  /// Validates the collected data
  List<String> validate() {
    final errors = <String>[];

    // Pet name validation
    if (petName != null) {
      if (petName!.isEmpty) {
        errors.add('Pet name cannot be empty');
      } else if (petName!.length > 50) {
        errors.add('Pet name must be 50 characters or less');
      }
    }

    // Age validation
    if (petAge != null) {
      if (petAge! < 0) {
        errors.add('Age cannot be negative');
      } else if (petAge! > 25) {
        errors.add('Age seems unrealistic (over 25 years)');
      }
    }

    // Weight validation
    if (petWeightKg != null) {
      if (petWeightKg! <= 0) {
        errors.add('Weight must be greater than 0');
      } else if (petWeightKg! > 15) {
        errors.add('Weight seems unrealistic (over 15kg for a cat)');
      }
    }

    // CKD diagnosis date validation
    if (ckdDiagnosisDate != null && ckdDiagnosisDate!.isAfter(DateTime.now())) {
      errors.add('CKD diagnosis date cannot be in the future');
    }

    // Age vs diagnosis consistency
    if (petAge != null &&
        ckdDiagnosisDate != null &&
        petAge! > 0 &&
        ckdDiagnosisDate != null) {
      final diagnosisAge =
          DateTime.now().difference(ckdDiagnosisDate!).inDays / 365.25;
      if (diagnosisAge > petAge!) {
        errors.add('CKD diagnosis date suggests pet is older than stated age');
      }
    }

    // Bloodwork date validation
    if (bloodworkDate != null && bloodworkDate!.isAfter(DateTime.now())) {
      errors.add('Bloodwork date cannot be in the future');
    }

    // If any lab values are provided, bloodwork date should be provided
    if (hasLabValues && bloodworkDate == null) {
      errors.add('Bloodwork date is required when lab values are provided');
    }

    // Validate creatinine range (structural only)
    if (creatinineMgDl != null && creatinineMgDl! <= 0) {
      errors.add('Creatinine must be a positive number');
    }

    // Validate BUN range (structural only)
    if (bunMgDl != null && bunMgDl! <= 0) {
      errors.add('BUN must be a positive number');
    }

    // Validate SDMA range (structural only)
    if (sdmaMcgDl != null && sdmaMcgDl! <= 0) {
      errors.add('SDMA must be a positive number');
    }

    // Validate medications
    if (medications != null) {
      for (var i = 0; i < medications!.length; i++) {
        final medication = medications![i];
        if (!medication.isValid) {
          errors.add('Medication ${i + 1} has invalid data');
        }
      }
    }

    // Validate fluid therapy
    if (fluidTherapy != null && !fluidTherapy!.isValid) {
      errors.add('Fluid therapy has invalid data');
    }

    // Validate treatment completeness based on persona
    // (skip validation during onboarding)
    if (treatmentApproach != null && isReadyForProfileCreation) {
      switch (treatmentApproach!) {
        case UserPersona.medicationOnly:
          if (medications == null || medications!.isEmpty) {
            errors.add(
              'At least one medication is required for '
              'medication-only treatment',
            );
          }
        case UserPersona.fluidTherapyOnly:
          if (fluidTherapy == null) {
            errors.add(
              'Fluid therapy setup is required for fluid therapy treatment',
            );
          }
        case UserPersona.medicationAndFluidTherapy:
          if (medications == null || medications!.isEmpty) {
            errors.add(
              'At least one medication is required for '
              'combination treatment',
            );
          }
          if (fluidTherapy == null) {
            errors.add(
              'Fluid therapy setup is required for combination treatment',
            );
          }
      }
    }

    return errors;
  }

  /// Converts to a complete CatProfile for final save
  CatProfile? toCatProfile({required String petId}) {
    if (!hasMinimumData || userId == null || treatmentApproach == null) {
      return null;
    }

    final labValues = hasLabValues || bloodworkDate != null
        ? LabValues(
            bloodworkDate: bloodworkDate,
            creatinineMgDl: creatinineMgDl,
            bunMgDl: bunMgDl,
            sdmaMcgDl: sdmaMcgDl,
          )
        : null;

    final medicalInfo = MedicalInfo(
      ckdDiagnosisDate: ckdDiagnosisDate,
      irisStage: irisStage,
      notes: notes,
      labValues: labValues,
    );

    final now = DateTime.now();

    return CatProfile(
      id: petId,
      userId: userId!,
      name: petName!,
      ageYears: petAge!,
      weightKg: petWeightKg!,
      treatmentApproach: treatmentApproach!,
      medicalInfo: medicalInfo,
      createdAt: now,
      updatedAt: now,
      gender: petGender,
      breed: petBreed,
    );
  }

  /// Creates a minimal CatProfile for checkpoint saves
  CatProfile? toMinimalCatProfile({required String petId}) {
    if (!hasBasicPetInfo || userId == null || treatmentApproach == null) {
      return null;
    }

    final now = DateTime.now();

    return CatProfile(
      id: petId,
      userId: userId!,
      name: petName!,
      ageYears: petAge!,
      weightKg: petWeightKg!,
      treatmentApproach: treatmentApproach!,
      createdAt: now,
      updatedAt: now,
      gender: petGender,
      breed: petBreed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OnboardingData &&
        other.userId == userId &&
        other.treatmentApproach == treatmentApproach &&
        other.petName == petName &&
        other.petAge == petAge &&
        other.petDateOfBirth == petDateOfBirth &&
        other.petGender == petGender &&
        other.petBreed == petBreed &&
        other.petWeightKg == petWeightKg &&
        other.ckdDiagnosisDate == ckdDiagnosisDate &&
        other.irisStage == irisStage &&
        other.notes == notes &&
        other.hasSkippedWelcome == hasSkippedWelcome &&
        other.useMetricUnits == useMetricUnits &&
        other.bloodworkDate == bloodworkDate &&
        other.creatinineMgDl == creatinineMgDl &&
        other.bunMgDl == bunMgDl &&
        other.sdmaMcgDl == sdmaMcgDl &&
        listEquals(other.medications, medications) &&
        other.fluidTherapy == fluidTherapy;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      treatmentApproach,
      petName,
      petAge,
      petDateOfBirth,
      petGender,
      petBreed,
      petWeightKg,
      ckdDiagnosisDate,
      irisStage,
      notes,
      hasSkippedWelcome,
      useMetricUnits,
      bloodworkDate,
      creatinineMgDl,
      bunMgDl,
      sdmaMcgDl,
      Object.hashAll(medications ?? []),
      fluidTherapy,
    );
  }

  @override
  String toString() {
    return 'OnboardingData('
        'userId: $userId, '
        'treatmentApproach: $treatmentApproach, '
        'petName: $petName, '
        'petAge: $petAge, '
        'petDateOfBirth: $petDateOfBirth, '
        'petGender: $petGender, '
        'petBreed: $petBreed, '
        'petWeightKg: $petWeightKg, '
        'ckdDiagnosisDate: $ckdDiagnosisDate, '
        'irisStage: $irisStage, '
        'notes: $notes, '
        'hasSkippedWelcome: $hasSkippedWelcome, '
        'useMetricUnits: $useMetricUnits, '
        'bloodworkDate: $bloodworkDate, '
        'creatinineMgDl: $creatinineMgDl, '
        'bunMgDl: $bunMgDl, '
        'sdmaMcgDl: $sdmaMcgDl, '
        'medications: $medications, '
        'fluidTherapy: $fluidTherapy'
        ')';
  }
}
