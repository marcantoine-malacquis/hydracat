import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/core/utils/dosage_text_utils.dart';
import 'package:hydracat/features/profile/models/schedule_dto.dart';
import 'package:hydracat/l10n/app_localizations.dart';

/// Sentinel value for [MedicationData.copyWith] to distinguish between
/// "not provided" and "explicitly set to null"
const _undefined = Object();

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

/// Enumeration of medication strength units
enum MedicationStrengthUnit {
  /// Milligrams
  mg,

  /// Milligrams per milliliter
  mgPerMl,

  /// Micrograms
  mcg,

  /// Micrograms per milliliter
  mcgPerMl,

  /// Grams
  g,

  /// Percentage
  percent,

  /// International Units
  iu,

  /// International Units per milliliter
  iuPerMl,

  /// Milligrams per gram
  mgPerG,

  /// Micrograms per gram
  mcgPerG,

  /// Other (custom unit)
  other;

  /// User-friendly display name for the strength unit
  String get displayName => switch (this) {
    MedicationStrengthUnit.mg => 'mg',
    MedicationStrengthUnit.mgPerMl => 'mg/mL',
    MedicationStrengthUnit.mcg => 'mcg',
    MedicationStrengthUnit.mcgPerMl => 'mcg/mL',
    MedicationStrengthUnit.g => 'g',
    MedicationStrengthUnit.percent => '%',
    MedicationStrengthUnit.iu => 'IU',
    MedicationStrengthUnit.iuPerMl => 'IU/mL',
    MedicationStrengthUnit.mgPerG => 'mg/g',
    MedicationStrengthUnit.mcgPerG => 'mcg/g',
    MedicationStrengthUnit.other => 'Other',
  };

  /// Creates a MedicationStrengthUnit from a string value
  ///
  /// Accepts both enum name (e.g., "mgPerMl") and display name
  /// (e.g., "mg/mL") for backward compatibility with existing data.
  static MedicationStrengthUnit? fromString(String value) {
    // First try to match by enum name (preferred format)
    final byName = MedicationStrengthUnit.values
        .where((unit) => unit.name == value)
        .firstOrNull;
    if (byName != null) return byName;

    // Then try to match by display name (for backward compatibility)
    return MedicationStrengthUnit.values
        .where((unit) => unit.displayName == value)
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
    MedicationUnit.ampoules => 'Ampoule(s)',
    MedicationUnit.capsules => 'Capsule(s)',
    MedicationUnit.drops => 'Drop(s)',
    MedicationUnit.injections => 'Injection(s)',
    MedicationUnit.micrograms => 'Microgram(s)',
    MedicationUnit.milligrams => 'Milligram(s)',
    MedicationUnit.milliliters => 'Milliliter(s)',
    MedicationUnit.pills => 'Pill(s)',
    MedicationUnit.portions => 'Portion(s)',
    MedicationUnit.sachets => 'Sachet(s)',
    MedicationUnit.tablespoon => 'Tablespoon(s)',
    MedicationUnit.teaspoon => 'Teaspoon(s)',
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
  ///
  /// Accepts both enum name (e.g., "sachets") and display name
  /// (e.g., "Sachet(s)") for backward compatibility with existing data.
  static MedicationUnit? fromString(String value) {
    // First try to match by enum name (preferred format)
    final byName = MedicationUnit.values
        .where((unit) => unit.name == value)
        .firstOrNull;
    if (byName != null) return byName;

    // Then try to match by display name (for backward compatibility)
    return MedicationUnit.values
        .where((unit) => unit.displayName == value)
        .firstOrNull;
  }
}

/// Enumeration of preferred fluid therapy locations
enum FluidLocation {
  /// Shoulder blade area - left side
  shoulderBladeLeft,

  /// Shoulder blade area - middle
  shoulderBladeMiddle,

  /// Shoulder blade area - right side
  shoulderBladeRight,

  /// Hip bones area - left side
  hipBonesLeft,

  /// Hip bones area - right side
  hipBonesRight;

  /// User-friendly display name for the location
  String get displayName => switch (this) {
    FluidLocation.shoulderBladeLeft => 'Shoulder blade - left',
    FluidLocation.shoulderBladeMiddle => 'Shoulder blade - middle',
    FluidLocation.shoulderBladeRight => 'Shoulder blade - right',
    FluidLocation.hipBonesLeft => 'Hip bones - left',
    FluidLocation.hipBonesRight => 'Hip bones - right',
  };

  /// Get localized display name for the location
  String getLocalizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      FluidLocation.shoulderBladeLeft => l10n.injectionSiteShoulderBladeLeft,
      FluidLocation.shoulderBladeMiddle =>
        l10n.injectionSiteShoulderBladeMiddle,
      FluidLocation.shoulderBladeRight => l10n.injectionSiteShoulderBladeRight,
      FluidLocation.hipBonesLeft => l10n.injectionSiteHipBonesLeft,
      FluidLocation.hipBonesRight => l10n.injectionSiteHipBonesRight,
    };
  }

  /// Creates a FluidLocation from a string value
  static FluidLocation? fromString(String value) {
    return FluidLocation.values
        .where((location) => location.name == value)
        .firstOrNull;
  }
}

/// Enumeration of needle gauge sizes for fluid therapy
enum NeedleGauge {
  /// 18 gauge needle
  gauge18,

  /// 20 gauge needle
  gauge20,

  /// 22 gauge needle
  gauge22,

  /// 25 gauge needle
  gauge25;

  /// User-friendly display name for the needle gauge
  String get displayName => switch (this) {
    NeedleGauge.gauge18 => '18G',
    NeedleGauge.gauge20 => '20G',
    NeedleGauge.gauge22 => '22G',
    NeedleGauge.gauge25 => '25G',
  };

  /// Creates a NeedleGauge from a string value
  ///
  /// Accepts both enum name (e.g., "gauge20") and display name (e.g., "20G")
  static NeedleGauge? fromString(String value) {
    // First try to match by enum name
    final byName = NeedleGauge.values
        .where((gauge) => gauge.name == value)
        .firstOrNull;
    if (byName != null) return byName;

    // Then try to match by display name
    return NeedleGauge.values
        .where((gauge) => gauge.displayName == value)
        .firstOrNull;
  }

  /// Creates a NeedleGauge from a nullable string value
  ///
  /// Returns null if the input is null or cannot be parsed
  static NeedleGauge? fromStringOrNull(String? value) {
    if (value == null || value.isEmpty) return null;
    return fromString(value);
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
    this.strengthAmount,
    this.strengthUnit,
    this.customStrengthUnit,
    this.canonicalGenericName,
    this.isDatabaseLinked = false,
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
      dosage: json['dosage'] != null
          ? (json['dosage'] as num).toDouble()
          : null,
      strengthAmount: json['strengthAmount'] as String?,
      strengthUnit: json['strengthUnit'] != null
          ? MedicationStrengthUnit.fromString(json['strengthUnit'] as String)
          : null,
      customStrengthUnit: json['customStrengthUnit'] as String?,
      canonicalGenericName: json['canonicalGenericName'] as String?,
      isDatabaseLinked: json['isDatabaseLinked'] as bool? ?? false,
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

  /// Optional dosage information
  final double? dosage;

  /// Optional medication strength amount (e.g., "2.5", "1/2", "10")
  final String? strengthAmount;

  /// Optional medication strength unit
  final MedicationStrengthUnit? strengthUnit;

  /// Custom strength unit when strengthUnit is 'other'
  final String? customStrengthUnit;

  /// Canonical generic medication name for data integrity
  ///
  /// When medication is selected from database, this stores the generic
  /// (INN) name regardless of whether user entered brand or generic name.
  /// Null for manually entered medications.
  final String? canonicalGenericName;

  /// Whether this medication was linked from the medication database
  ///
  /// True if selected from autocomplete, false if manually entered.
  final bool isDatabaseLinked;

  /// Generate a human-readable summary of this medication
  String get summary {
    final dosageValue = dosage ?? 1;
    final dosageWithUnit = DosageTextUtils.formatDosageWithUnit(
      dosageValue,
      unit.shortForm,
    );

    return '$dosageWithUnit ${_summaryFrequencyText()}';
  }

  /// Get formatted strength for display (e.g., "2.5 mg" or null)
  String? get formattedStrength {
    if (strengthAmount == null || strengthAmount!.isEmpty) {
      return null;
    }

    if (strengthUnit == null) {
      return strengthAmount;
    }

    final unitDisplay = strengthUnit == MedicationStrengthUnit.other
        ? customStrengthUnit ?? 'Other'
        : strengthUnit!.displayName;

    return '$strengthAmount $unitDisplay';
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

  /// Whether this medication has valid data
  bool get isValid {
    return name.isNotEmpty &&
        reminderTimes.length == frequency.administrationsPerDay;
  }

  /// Converts this [MedicationData] to a schedule DTO
  ///
  /// Creates a type-safe medication schedule with reminder times as
  /// DateTime objects. The schedule ID and timestamps will be added
  /// by ScheduleService
  ScheduleDto toSchedule({String? scheduleId}) {
    return ScheduleDto.medication(
      id: scheduleId,
      medicationName: name,
      targetDosage: dosage ?? 1.0,
      medicationUnit: unit.name,
      frequency: frequency,
      reminderTimes: reminderTimes,
      medicationStrengthAmount: strengthAmount,
      medicationStrengthUnit: strengthUnit?.name,
      customMedicationStrengthUnit: customStrengthUnit,
    );
  }

  /// Converts [MedicationData] to JSON data
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'unit': unit.name,
      'frequency': frequency.name,
      'reminderTimes': reminderTimes.map((e) => e.toIso8601String()).toList(),
      'dosage': dosage,
      'strengthAmount': strengthAmount,
      'strengthUnit': strengthUnit?.name,
      'customStrengthUnit': customStrengthUnit,
      if (canonicalGenericName != null)
        'canonicalGenericName': canonicalGenericName,
      'isDatabaseLinked': isDatabaseLinked,
    };
  }

  /// Creates a copy of this [MedicationData] with the given fields replaced
  MedicationData copyWith({
    String? name,
    MedicationUnit? unit,
    TreatmentFrequency? frequency,
    List<DateTime>? reminderTimes,
    Object? dosage = _undefined,
    Object? strengthAmount = _undefined,
    Object? strengthUnit = _undefined,
    Object? customStrengthUnit = _undefined,
    Object? canonicalGenericName = _undefined,
    bool? isDatabaseLinked,
  }) {
    return MedicationData(
      name: name ?? this.name,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      dosage: dosage == _undefined ? this.dosage : dosage as double?,
      strengthAmount: strengthAmount == _undefined
          ? this.strengthAmount
          : strengthAmount as String?,
      strengthUnit: strengthUnit == _undefined
          ? this.strengthUnit
          : strengthUnit as MedicationStrengthUnit?,
      customStrengthUnit: customStrengthUnit == _undefined
          ? this.customStrengthUnit
          : customStrengthUnit as String?,
      canonicalGenericName: canonicalGenericName == _undefined
          ? this.canonicalGenericName
          : canonicalGenericName as String?,
      isDatabaseLinked: isDatabaseLinked ?? this.isDatabaseLinked,
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
        other.dosage == dosage &&
        other.strengthAmount == strengthAmount &&
        other.strengthUnit == strengthUnit &&
        other.customStrengthUnit == customStrengthUnit &&
        other.canonicalGenericName == canonicalGenericName &&
        other.isDatabaseLinked == isDatabaseLinked;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      unit,
      frequency,
      Object.hashAll(reminderTimes),
      dosage,
      strengthAmount,
      strengthUnit,
      customStrengthUnit,
      canonicalGenericName,
      isDatabaseLinked,
    );
  }

  @override
  String toString() {
    return 'MedicationData('
        'name: $name, '
        'unit: $unit, '
        'frequency: $frequency, '
        'reminderTimes: $reminderTimes, '
        'dosage: $dosage, '
        'strengthAmount: $strengthAmount, '
        'strengthUnit: $strengthUnit, '
        'customStrengthUnit: $customStrengthUnit'
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
          FluidLocation.shoulderBladeMiddle,
      needleGauge:
          NeedleGauge.fromString(json['needleGauge'] as String) ??
          NeedleGauge.gauge20,
    );
  }

  /// Treatment frequency for fluid therapy
  final TreatmentFrequency frequency;

  /// Volume per administration in milliliters
  final double volumePerAdministration;

  /// Preferred location for fluid administration
  final FluidLocation preferredLocation;

  /// Needle gauge preference
  final NeedleGauge needleGauge;

  /// Generate a human-readable summary of fluid therapy setup
  String get summary {
    return '${volumePerAdministration}ml '
        '${frequency.displayName.toLowerCase()} '
        'at ${preferredLocation.displayName}';
  }

  /// Whether this fluid therapy data has valid information
  bool get isValid {
    return volumePerAdministration > 0;
  }

  /// Converts [FluidTherapyData] to JSON data
  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.name,
      'volumePerAdministration': volumePerAdministration,
      'preferredLocation': preferredLocation.name,
      'needleGauge': needleGauge.name,
    };
  }

  /// Creates a copy of this [FluidTherapyData] with the given fields replaced
  FluidTherapyData copyWith({
    TreatmentFrequency? frequency,
    double? volumePerAdministration,
    FluidLocation? preferredLocation,
    NeedleGauge? needleGauge,
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

  /// Converts this [FluidTherapyData] to a schedule DTO
  ///
  /// Creates a type-safe fluid therapy schedule with default reminder
  /// times based on frequency. The schedule ID and timestamps will be
  /// added by ScheduleService
  ScheduleDto toSchedule({String? scheduleId}) {
    // Generate default reminder times based on frequency
    final defaultTimes = AppDateUtils.generateDefaultReminderTimes(
      frequency.administrationsPerDay,
    );

    // Convert TimeOfDay to DateTime
    final reminderDateTimes = defaultTimes
        .map(AppDateUtils.timeOfDayToDateTime)
        .toList();

    return ScheduleDto.fluid(
      id: scheduleId,
      targetVolume: volumePerAdministration,
      frequency: frequency,
      preferredLocation: preferredLocation,
      needleGauge: needleGauge,
      reminderTimes: reminderDateTimes,
    );
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
