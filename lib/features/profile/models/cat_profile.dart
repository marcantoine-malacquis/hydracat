import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:hydracat/core/utils/weight_utils.dart';
import 'package:hydracat/features/profile/models/medical_info.dart';

/// Sentinel value for [CatProfile.copyWith] to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

/// Core pet profile model for CKD management
@immutable
class CatProfile {
  /// Creates a [CatProfile] instance
  const CatProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.ageYears,
    required this.createdAt,
    required this.updatedAt,
    this.weightKg,
    this.medicalInfo = const MedicalInfo(),
    this.photoUrl,
    this.breed,
    this.gender,
    this.dateOfBirth,
    this.lastFluidInjectionSite,
    this.lastFluidSessionDate,
  });

  /// Creates a [CatProfile] from JSON data
  factory CatProfile.fromJson(Map<String, dynamic> json) {
    return CatProfile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      ageYears: json['ageYears'] as int,
      weightKg: json['weightKg'] != null
          ? (json['weightKg'] as num).toDouble()
          : null,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      medicalInfo: json['medicalInfo'] != null
          ? MedicalInfo.fromJson(json['medicalInfo'] as Map<String, dynamic>)
          : const MedicalInfo(),
      photoUrl: json['photoUrl'] as String?,
      breed: json['breed'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? _parseDateTime(json['dateOfBirth'])
          : null,
      lastFluidInjectionSite: json['lastFluidInjectionSite'] as String?,
      lastFluidSessionDate: json['lastFluidSessionDate'] != null
          ? _parseDateTime(json['lastFluidSessionDate'])
          : null,
    );
  }

  /// Helper to parse DateTime from either Timestamp or String
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else {
      throw FormatException('Invalid datetime format: $value');
    }
  }

  /// Unique identifier for the pet profile
  final String id;

  /// ID of the user who owns this pet
  final String userId;

  /// Pet's name
  final String name;

  /// Pet's age in years
  final int ageYears;

  /// Pet's weight in kilograms (optional)
  final double? weightKg;

  /// Medical information specific to CKD
  final MedicalInfo medicalInfo;

  /// Timestamp when the profile was created
  final DateTime createdAt;

  /// Timestamp when the profile was last updated
  final DateTime updatedAt;

  /// Optional URL to pet's photo
  final String? photoUrl;

  /// Pet's breed (optional)
  final String? breed;

  /// Pet's gender (optional)
  final String? gender;

  /// Pet's date of birth (optional)
  final DateTime? dateOfBirth;

  /// Last injection site used for fluid therapy
  ///
  /// Stored as the FluidLocation enum name (e.g., "shoulderBladeLeft").
  /// Used for continuous injection site rotation tracking across weeks.
  final String? lastFluidInjectionSite;

  /// Date/time of last fluid therapy session
  ///
  /// Updated each time a fluid session is logged.
  /// Used with lastFluidInjectionSite for site rotation tracking.
  final DateTime? lastFluidSessionDate;

  /// Pet's weight in pounds (converted from kg)
  double? get weightLbs =>
      weightKg != null ? WeightUtils.convertKgToLbs(weightKg!) : null;

  /// Pet's age in months (approximate)
  int get ageMonths => ageYears * 12;

  /// Whether this profile has essential information
  bool get hasEssentialInfo => name.isNotEmpty && ageYears > 0;

  /// Whether this profile is considered complete
  bool get isComplete =>
      hasEssentialInfo && medicalInfo.ckdDiagnosisDate != null;

  /// Converts [CatProfile] to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'ageYears': ageYears,
      'weightKg': weightKg,
      'medicalInfo': medicalInfo.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'photoUrl': photoUrl,
      'breed': breed,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'lastFluidInjectionSite': lastFluidInjectionSite,
      'lastFluidSessionDate': lastFluidSessionDate?.toIso8601String(),
    };
  }

  /// Creates a copy of this [CatProfile] with the given fields replaced
  CatProfile copyWith({
    String? id,
    String? userId,
    String? name,
    int? ageYears,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? weightKg = _undefined,
    MedicalInfo? medicalInfo,
    Object? photoUrl = _undefined,
    Object? breed = _undefined,
    Object? gender = _undefined,
    Object? dateOfBirth = _undefined,
    Object? lastFluidInjectionSite = _undefined,
    Object? lastFluidSessionDate = _undefined,
  }) {
    return CatProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      ageYears: ageYears ?? this.ageYears,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      weightKg: weightKg == _undefined ? this.weightKg : weightKg as double?,
      medicalInfo: medicalInfo ?? this.medicalInfo,
      photoUrl: photoUrl == _undefined ? this.photoUrl : photoUrl as String?,
      breed: breed == _undefined ? this.breed : breed as String?,
      gender: gender == _undefined ? this.gender : gender as String?,
      dateOfBirth: dateOfBirth == _undefined
          ? this.dateOfBirth
          : dateOfBirth as DateTime?,
      lastFluidInjectionSite: lastFluidInjectionSite == _undefined
          ? this.lastFluidInjectionSite
          : lastFluidInjectionSite as String?,
      lastFluidSessionDate: lastFluidSessionDate == _undefined
          ? this.lastFluidSessionDate
          : lastFluidSessionDate as DateTime?,
    );
  }

  /// Updates the weight with a new value in kilograms
  CatProfile updateWeightKg(double newWeightKg) {
    return copyWith(
      weightKg: newWeightKg,
      updatedAt: DateTime.now(),
    );
  }

  /// Updates the weight with a new value in pounds (converted to kg)
  CatProfile updateWeightLbs(double newWeightLbs) {
    return updateWeightKg(WeightUtils.convertLbsToKg(newWeightLbs));
  }

  /// Validates the pet profile data for consistency
  List<String> validate() {
    final errors = <String>[];

    // Name validation
    if (name.isEmpty) {
      errors.add('Pet name is required');
    } else if (name.length > 50) {
      errors.add('Pet name must be 50 characters or less');
    }

    // Age validation
    if (ageYears < 0) {
      errors.add('Age cannot be negative');
    } else if (ageYears > 25) {
      errors.add('Age seems unrealistic (over 25 years)');
    }

    // Weight validation (optional)
    if (weightKg != null) {
      if (weightKg! <= 0) {
        errors.add('Weight must be greater than 0');
      } else if (weightKg! > 15) {
        errors.add('Weight seems unrealistic (over 15kg for a cat)');
      }
    }

    // Gender validation (required)
    if (gender == null || gender!.isEmpty) {
      errors.add('Gender is required');
    } else if (gender != 'male' && gender != 'female') {
      errors.add('Gender must be either male or female');
    }

    // Medical info validation
    errors.addAll(medicalInfo.validate());

    // Age vs diagnosis date validation
    if (medicalInfo.ckdDiagnosisDate != null) {
      final diagnosisAge =
          DateTime.now().difference(medicalInfo.ckdDiagnosisDate!).inDays /
          365.25;
      if (diagnosisAge > ageYears) {
        errors.add('CKD diagnosis date suggests pet is older than stated age');
      }
    }

    return errors;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CatProfile &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.ageYears == ageYears &&
        other.weightKg == weightKg &&
        other.medicalInfo == medicalInfo &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.photoUrl == photoUrl &&
        other.breed == breed &&
        other.gender == gender &&
        other.dateOfBirth == dateOfBirth &&
        other.lastFluidInjectionSite == lastFluidInjectionSite &&
        other.lastFluidSessionDate == lastFluidSessionDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      name,
      ageYears,
      weightKg,
      medicalInfo,
      createdAt,
      updatedAt,
      photoUrl,
      breed,
      gender,
      dateOfBirth,
      lastFluidInjectionSite,
      lastFluidSessionDate,
    );
  }

  @override
  String toString() {
    return 'CatProfile('
        'id: $id, '
        'userId: $userId, '
        'name: $name, '
        'ageYears: $ageYears, '
        'weightKg: $weightKg, '
        'medicalInfo: $medicalInfo, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'photoUrl: $photoUrl, '
        'breed: $breed, '
        'gender: $gender, '
        'dateOfBirth: $dateOfBirth, '
        'lastFluidInjectionSite: $lastFluidInjectionSite, '
        'lastFluidSessionDate: $lastFluidSessionDate'
        ')';
  }
}
