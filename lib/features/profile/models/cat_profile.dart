import 'package:flutter/foundation.dart';

import 'package:hydracat/features/profile/models/medical_info.dart';

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
    this.trackingStartDate,
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
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      medicalInfo: json['medicalInfo'] != null
          ? MedicalInfo.fromJson(json['medicalInfo'] as Map<String, dynamic>)
          : const MedicalInfo(),
      photoUrl: json['photoUrl'] as String?,
      breed: json['breed'] as String?,
      gender: json['gender'] as String?,
      trackingStartDate: json['trackingStartDate'] != null
          ? DateTime.parse(json['trackingStartDate'] as String)
          : null,
    );
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

  /// Date when treatment tracking started for this pet
  ///
  /// Represents the earliest date of treatment data collection.
  /// Used to determine which calendar dates should show status dots.
  /// Dates before this will show no dots (tracking hadn't started yet).
  ///
  /// Set to:
  /// - Pet profile creation date initially
  /// - Earliest schedule creation date if schedules exist
  /// - Earliest session date if backdated logs exist
  ///
  /// Immutable after initial setting (represents historical truth).
  final DateTime? trackingStartDate;

  /// Pet's weight in pounds (converted from kg)
  double? get weightLbs => weightKg != null ? weightKg! * 2.20462 : null;

  /// Pet's age in months (approximate)
  int get ageMonths => ageYears * 12;

  /// Whether this profile has essential information
  bool get hasEssentialInfo => name.isNotEmpty && ageYears > 0;

  /// Whether this profile is considered complete
  bool get isComplete =>
      hasEssentialInfo && medicalInfo.ckdDiagnosisDate != null;

  /// Checks if tracking has started for a given date
  ///
  /// Returns true if:
  /// - trackingStartDate is null (no tracking limit set)
  /// - date is on or after trackingStartDate
  ///
  /// Returns false if date is before trackingStartDate.
  ///
  /// Used by calendar to determine if dots should be shown for a date.
  bool hasTrackingStarted(DateTime date) {
    if (trackingStartDate == null) return true;
    return date.isAfter(trackingStartDate!) ||
        date.isAtSameMomentAs(trackingStartDate!);
  }

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
      'trackingStartDate': trackingStartDate?.toIso8601String(),
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
    double? weightKg,
    MedicalInfo? medicalInfo,
    String? photoUrl,
    String? breed,
    String? gender,
    DateTime? trackingStartDate,
  }) {
    return CatProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      ageYears: ageYears ?? this.ageYears,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      weightKg: weightKg ?? this.weightKg,
      medicalInfo: medicalInfo ?? this.medicalInfo,
      photoUrl: photoUrl ?? this.photoUrl,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      trackingStartDate: trackingStartDate ?? this.trackingStartDate,
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
    return updateWeightKg(newWeightLbs / 2.20462);
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

    // Tracking start date validation
    if (trackingStartDate != null) {
      if (trackingStartDate!.isAfter(DateTime.now())) {
        errors.add('Tracking start date cannot be in the future');
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
        other.trackingStartDate == trackingStartDate;
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
      trackingStartDate,
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
        'trackingStartDate: $trackingStartDate'
        ')';
  }
}
