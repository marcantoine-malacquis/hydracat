import 'package:flutter/foundation.dart';
import 'package:hydracat/core/utils/date_utils.dart';

/// Enumeration of treatment frequencies
enum TreatmentFrequency {
  /// Once daily
  onceDaily,

  /// Twice daily
  twiceDaily,

  /// Three times daily
  thriceDaily,

  /// Every other day
  everyOtherDay,

  /// Every 3 days (specific to mirtazapine)
  every3Days;

  /// User-friendly display name for the frequency
  String get displayName => switch (this) {
    TreatmentFrequency.onceDaily => 'Once daily',
    TreatmentFrequency.twiceDaily => 'Twice daily',
    TreatmentFrequency.thriceDaily => 'Thrice daily',
    TreatmentFrequency.everyOtherDay => 'Every other day',
    TreatmentFrequency.every3Days => 'Every 3 days',
  };

  /// Number of administrations per day for this frequency
  int get administrationsPerDay => switch (this) {
    TreatmentFrequency.onceDaily => 1,
    TreatmentFrequency.twiceDaily => 2,
    TreatmentFrequency.thriceDaily => 3,
    // Conceptually 0.5, but UI shows 1 time
    TreatmentFrequency.everyOtherDay => 1,
    // Conceptually 0.33, but UI shows 1 time
    TreatmentFrequency.every3Days => 1,
  };

  /// Whether this frequency requires multiple daily administrations
  bool get hasMultipleDaily => administrationsPerDay > 1;

  /// Creates a TreatmentFrequency from a string value
  static TreatmentFrequency? fromString(String value) {
    return TreatmentFrequency.values
        .where((frequency) => frequency.name == value)
        .firstOrNull;
  }
}

/// Enumeration of medication units (alphabetical order)
enum MedicationUnit {
  /// Ampoules
  ampoules,

  /// Capsules
  capsules,

  /// Drops
  drops,

  /// Injections
  injections,

  /// Micrograms
  micrograms,

  /// Milligrams
  milligrams,

  /// Milliliters
  milliliters,

  /// Pills
  pills,

  /// Portions
  portions,

  /// Sachets
  sachets,

  /// Tablespoon
  tablespoon,

  /// Teaspoon
  teaspoon;

  /// User-friendly display name for the unit
  String get displayName => switch (this) {
    MedicationUnit.ampoules => 'Ampoules',
    MedicationUnit.capsules => 'Capsules',
    MedicationUnit.drops => 'Drops',
    MedicationUnit.injections => 'Injections',
    MedicationUnit.micrograms => 'Micrograms',
    MedicationUnit.milligrams => 'Milligrams',
    MedicationUnit.milliliters => 'Milliliters',
    MedicationUnit.pills => 'Pills',
    MedicationUnit.portions => 'Portions',
    MedicationUnit.sachets => 'Sachets',
    MedicationUnit.tablespoon => 'Tablespoon',
    MedicationUnit.teaspoon => 'Teaspoon',
  };

  /// Short form of the unit for display in summaries
  String get shortForm => switch (this) {
    MedicationUnit.ampoules => 'ampoule',
    MedicationUnit.capsules => 'capsule',
    MedicationUnit.drops => 'drop',
    MedicationUnit.injections => 'injection',
    MedicationUnit.micrograms => 'mcg',
    MedicationUnit.milligrams => 'mg',
    MedicationUnit.milliliters => 'ml',
    MedicationUnit.pills => 'pill',
    MedicationUnit.portions => 'portion',
    MedicationUnit.sachets => 'sachet',
    MedicationUnit.tablespoon => 'tbsp',
    MedicationUnit.teaspoon => 'tsp',
  };

  /// Creates a MedicationUnit from a string value
  static MedicationUnit? fromString(String value) {
    return MedicationUnit.values
        .where((unit) => unit.name == value)
        .firstOrNull;
  }
}

/// Enumeration of preferred fluid therapy locations
enum FluidLocation {
  /// Shoulder blade area - left side
  shoulderBladeLeft,

  /// Shoulder blade area - right side
  shoulderBladeRight,

  /// Hip bones area - left side
  hipBonesLeft,

  /// Hip bones area - right side
  hipBonesRight;

  /// User-friendly display name for the location
  String get displayName => switch (this) {
    FluidLocation.shoulderBladeLeft => 'Shoulder blade - left',
    FluidLocation.shoulderBladeRight => 'Shoulder blade - right',
    FluidLocation.hipBonesLeft => 'Hip bones - left',
    FluidLocation.hipBonesRight => 'Hip bones - right',
  };

  /// Creates a FluidLocation from a string value
  static FluidLocation? fromString(String value) {
    return FluidLocation.values
        .where((location) => location.name == value)
        .firstOrNull;
  }
}

/// Data class for individual medication information
@immutable
class MedicationData {
  /// Creates a [MedicationData] instance
  const MedicationData({
    required this.name,
    required this.unit,
    required this.frequency,
    required this.reminderTimes,
    this.dosage,
  });

  /// Creates a [MedicationData] from JSON data
  factory MedicationData.fromJson(Map<String, dynamic> json) {
    return MedicationData(
      name: json['name'] as String,
      unit:
          MedicationUnit.fromString(json['unit'] as String) ??
          MedicationUnit.pills,
      frequency:
          TreatmentFrequency.fromString(json['frequency'] as String) ??
          TreatmentFrequency.onceDaily,
      reminderTimes: (json['reminderTimes'] as List<dynamic>)
          .map((e) => DateTime.parse(e as String))
          .toList(),
      dosage: json['dosage'] as String?,
    );
  }

  /// Medication name
  final String name;

  /// Medication unit
  final MedicationUnit unit;

  /// Treatment frequency
  final TreatmentFrequency frequency;

  /// List of reminder times for administrations
  final List<DateTime> reminderTimes;

  /// Optional dosage information (e.g., "1/2", "1", "2")
  final String? dosage;

  /// Generate a human-readable summary of this medication
  String get summary {
    final dosageText = dosage ?? '1';
    final unitText = _getUnitText(dosageText);

    return '$dosageText $unitText ${_summaryFrequencyText()}';
  }

  /// Frequency phrasing tailored for card summaries
  String _summaryFrequencyText() {
    return switch (frequency) {
      TreatmentFrequency.onceDaily => 'once a day',
      TreatmentFrequency.twiceDaily => 'twice per day',
      TreatmentFrequency.thriceDaily => 'three times per day',
      TreatmentFrequency.everyOtherDay => 'every other day',
      TreatmentFrequency.every3Days => 'every 3 days',
    };
  }

  /// Get the appropriate unit text based on dosage
  String _getUnitText(String dosageText) {
    // Handle fractional dosages
    if (dosageText.contains('/')) {
      return unit.shortForm;
    }

    // Handle plural/singular forms
    try {
      final dosageNum = double.parse(dosageText);
      if (dosageNum == 1.0) {
        return unit.shortForm;
      } else {
        // For most units, just add 's' for plural
        return switch (unit) {
          MedicationUnit.drops => '${unit.shortForm}s',
          MedicationUnit.pills => '${unit.shortForm}s',
          MedicationUnit.capsules => '${unit.shortForm}s',
          MedicationUnit.ampoules => '${unit.shortForm}s',
          MedicationUnit.injections => '${unit.shortForm}s',
          MedicationUnit.portions => '${unit.shortForm}s',
          MedicationUnit.sachets => '${unit.shortForm}s',
          // Units that don't change in plural
          _ => unit.shortForm,
        };
      }
    } on FormatException {
      return unit.shortForm;
    }
  }

  /// Whether this medication has valid data
  bool get isValid {
    return name.isNotEmpty &&
        reminderTimes.length == frequency.administrationsPerDay;
  }

  /// Converts this [MedicationData] to a schedule document
  ///
  /// Creates a medication schedule with reminder times as DateTime objects.
  /// The schedule ID and timestamps will be added by ScheduleService
  Map<String, dynamic> toSchedule({String? scheduleId}) {
    // Store reminder times as full DateTime ISO strings (consistent with fluid)
    final reminderTimeStrings = reminderTimes
        .map((dateTime) => dateTime.toIso8601String())
        .toList();

    return {
      if (scheduleId != null) 'id': scheduleId,
      'treatmentType': 'medication',
      'medicationName': name,
      'targetDosage': dosage ?? '1',
      'medicationUnit': unit.name,
      'frequency': frequency.name,
      'reminderTimes': reminderTimeStrings,
      'isActive': true,
      // createdAt and updatedAt are added by ScheduleService
      // with server timestamps
    };
  }

  /// Converts [MedicationData] to JSON data
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'unit': unit.name,
      'frequency': frequency.name,
      'reminderTimes': reminderTimes.map((e) => e.toIso8601String()).toList(),
      'dosage': dosage,
    };
  }

  /// Creates a copy of this [MedicationData] with the given fields replaced
  MedicationData copyWith({
    String? name,
    MedicationUnit? unit,
    TreatmentFrequency? frequency,
    List<DateTime>? reminderTimes,
    String? dosage,
  }) {
    return MedicationData(
      name: name ?? this.name,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      dosage: dosage ?? this.dosage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MedicationData &&
        other.name == name &&
        other.unit == unit &&
        other.frequency == frequency &&
        listEquals(other.reminderTimes, reminderTimes) &&
        other.dosage == dosage;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      unit,
      frequency,
      Object.hashAll(reminderTimes),
      dosage,
    );
  }

  @override
  String toString() {
    return 'MedicationData('
        'name: $name, '
        'unit: $unit, '
        'frequency: $frequency, '
        'reminderTimes: $reminderTimes, '
        'dosage: $dosage'
        ')';
  }
}

/// Data class for fluid therapy information
@immutable
class FluidTherapyData {
  /// Creates a [FluidTherapyData] instance
  const FluidTherapyData({
    required this.frequency,
    required this.volumePerAdministration,
    required this.preferredLocation,
    required this.needleGauge,
  });

  /// Creates a [FluidTherapyData] from JSON data
  factory FluidTherapyData.fromJson(Map<String, dynamic> json) {
    return FluidTherapyData(
      frequency:
          TreatmentFrequency.fromString(json['frequency'] as String) ??
          TreatmentFrequency.onceDaily,
      volumePerAdministration: (json['volumePerAdministration'] as num)
          .toDouble(),
      preferredLocation:
          FluidLocation.fromString(json['preferredLocation'] as String) ??
          FluidLocation.shoulderBladeLeft,
      needleGauge: json['needleGauge'] as String,
    );
  }

  /// Treatment frequency for fluid therapy
  final TreatmentFrequency frequency;

  /// Volume per administration in milliliters
  final double volumePerAdministration;

  /// Preferred location for fluid administration
  final FluidLocation preferredLocation;

  /// Needle gauge preference
  final String needleGauge;

  /// Generate a human-readable summary of fluid therapy setup
  String get summary {
    return '${volumePerAdministration}ml '
        '${frequency.displayName.toLowerCase()} '
        'at ${preferredLocation.displayName}';
  }

  /// Whether this fluid therapy data has valid information
  bool get isValid {
    return volumePerAdministration > 0 && needleGauge.isNotEmpty;
  }

  /// Converts [FluidTherapyData] to JSON data
  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.name,
      'volumePerAdministration': volumePerAdministration,
      'preferredLocation': preferredLocation.name,
      'needleGauge': needleGauge,
    };
  }

  /// Creates a copy of this [FluidTherapyData] with the given fields replaced
  FluidTherapyData copyWith({
    TreatmentFrequency? frequency,
    double? volumePerAdministration,
    FluidLocation? preferredLocation,
    String? needleGauge,
  }) {
    return FluidTherapyData(
      frequency: frequency ?? this.frequency,
      volumePerAdministration:
          volumePerAdministration ?? this.volumePerAdministration,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      needleGauge: needleGauge ?? this.needleGauge,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FluidTherapyData &&
        other.frequency == frequency &&
        other.volumePerAdministration == volumePerAdministration &&
        other.preferredLocation == preferredLocation &&
        other.needleGauge == needleGauge;
  }

  @override
  int get hashCode {
    return Object.hash(
      frequency,
      volumePerAdministration,
      preferredLocation,
      needleGauge,
    );
  }

  /// Converts this [FluidTherapyData] to a schedule document
  ///
  /// Creates a fluid therapy schedule with default reminder times based on
  /// frequency. The schedule ID and timestamps will be added by ScheduleService
  Map<String, dynamic> toSchedule({String? scheduleId}) {
    // Generate default reminder times based on frequency
    final defaultTimes = AppDateUtils.generateDefaultReminderTimes(
      frequency.administrationsPerDay,
    );

    // Convert TimeOfDay to DateTime
    final reminderDateTimes = defaultTimes
        .map(AppDateUtils.timeOfDayToDateTime)
        .toList();

    return {
      if (scheduleId != null) 'id': scheduleId,
      'treatmentType': 'fluid',
      'frequency': frequency.name,
      'targetVolume': volumePerAdministration,
      'preferredLocation': preferredLocation.name,
      'needleGauge': needleGauge,
      'reminderTimes': reminderDateTimes
          .map((dt) => dt.toIso8601String())
          .toList(),
      'isActive': true,
      // createdAt and updatedAt are added by ScheduleService
      // with server timestamps
    };
  }

  @override
  String toString() {
    return 'FluidTherapyData('
        'frequency: $frequency, '
        'volumePerAdministration: $volumePerAdministration, '
        'preferredLocation: $preferredLocation, '
        'needleGauge: $needleGauge'
        ')';
  }
}

/// Base class for treatment-related data
@immutable
abstract class TreatmentData {
  /// Creates a [TreatmentData] instance
  const TreatmentData();

  /// Whether this treatment data is valid
  bool get isValid;

  /// Human-readable summary of the treatment
  String get summary;

  /// Converts treatment data to JSON
  Map<String, dynamic> toJson();
}
