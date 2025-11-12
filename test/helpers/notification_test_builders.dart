/// Test data builders for notification-related tests
///
/// Provides builder classes for creating test data with sensible defaults
/// and fluent API for readability.
// ignore_for_file: avoid_returning_this

library;

import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/notifications/models/notification_settings.dart';
import 'package:hydracat/features/notifications/models/scheduled_notification_entry.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/models/medical_info.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/providers/profile_provider.dart';

// Global counter to ensure unique IDs
int _globalIdCounter = 0;

/// Builder for creating [AppUser] test instances
class UserBuilder {
  /// Creates a user builder with sensible defaults
  UserBuilder() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _id = 'test-user-$timestamp-${_globalIdCounter++}';
    _email = 'test@example.com';
    _emailVerified = true;
    _hasCompletedOnboarding = true;
  }

  late String _id;
  late String _email;
  late bool _emailVerified;
  late bool _hasCompletedOnboarding;
  String? _displayName;
  String? _primaryPetId;

  /// Sets the user ID
  UserBuilder withId(String id) {
    _id = id;
    return this;
  }

  /// Sets the email
  UserBuilder withEmail(String email) {
    _email = email;
    return this;
  }

  /// Sets the primary pet ID
  UserBuilder withPrimaryPetId(String petId) {
    _primaryPetId = petId;
    return this;
  }

  /// Sets the display name
  UserBuilder withDisplayName(String name) {
    _displayName = name;
    return this;
  }

  /// Builds the user
  AppUser build() {
    return AppUser(
      id: _id,
      email: _email,
      displayName: _displayName,
      emailVerified: _emailVerified,
      hasCompletedOnboarding: _hasCompletedOnboarding,
      primaryPetId: _primaryPetId,
    );
  }
}

/// Builder for creating [CatProfile] test instances
class PetBuilder {
  /// Creates a pet builder with sensible defaults
  PetBuilder() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _id = 'test-pet-$timestamp-${_globalIdCounter++}';
    _userId = 'test-user-id';
    _name = 'Fluffy';
    _ageYears = 5;
    _gender = 'female';
    _createdAt = DateTime.now();
    _updatedAt = DateTime.now();
  }

  late String _id;
  late String _userId;
  late String _name;
  late int _ageYears;
  late String _gender;
  late DateTime _createdAt;
  late DateTime _updatedAt;
  double? _weightKg;
  final MedicalInfo _medicalInfo = const MedicalInfo();

  /// Sets the pet ID
  PetBuilder withId(String id) {
    _id = id;
    return this;
  }

  /// Sets the user ID
  PetBuilder withUserId(String userId) {
    _userId = userId;
    return this;
  }

  /// Sets the pet name
  PetBuilder withName(String name) {
    _name = name;
    return this;
  }

  /// Sets the age
  PetBuilder withAge(int years) {
    _ageYears = years;
    return this;
  }

  /// Sets the weight
  PetBuilder withWeight(double kg) {
    _weightKg = kg;
    return this;
  }

  /// Builds the pet profile
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
      gender: _gender,
    );
  }
}

/// Builder for creating [ProfileState] test instances
class ProfileStateBuilder {
  /// Creates a profile state builder with sensible defaults
  ProfileStateBuilder() {
    _isLoading = false;
    _isRefreshing = false;
    _scheduleIsLoading = false;
    _cacheStatus = CacheStatus.fresh;
  }

  CatProfile? _primaryPet;
  Schedule? _fluidSchedule;
  List<Schedule>? _medicationSchedules;
  late bool _isLoading;
  late bool _isRefreshing;
  late bool _scheduleIsLoading;
  late CacheStatus _cacheStatus;

  /// Sets the primary pet
  ProfileStateBuilder withPrimaryPet(CatProfile pet) {
    _primaryPet = pet;
    return this;
  }

  /// Sets the fluid schedule
  ProfileStateBuilder withFluidSchedule(Schedule schedule) {
    _fluidSchedule = schedule;
    return this;
  }

  /// Sets the medication schedules
  ProfileStateBuilder withMedicationSchedules(List<Schedule> schedules) {
    _medicationSchedules = schedules;
    return this;
  }

  /// Sets loading state
  ProfileStateBuilder withIsLoading({required bool isLoading}) {
    _isLoading = isLoading;
    return this;
  }

  /// Sets cache status
  ProfileStateBuilder withCacheStatus(CacheStatus status) {
    _cacheStatus = status;
    return this;
  }

  /// Builds the profile state
  ProfileState build() {
    return ProfileState(
      primaryPet: _primaryPet,
      fluidSchedule: _fluidSchedule,
      medicationSchedules: _medicationSchedules,
      isLoading: _isLoading,
      isRefreshing: _isRefreshing,
      scheduleIsLoading: _scheduleIsLoading,
      cacheStatus: _cacheStatus,
    );
  }
}

/// Builder for creating [NotificationSettings] test instances
class NotificationSettingsBuilder {
  /// Creates a notification settings builder with sensible defaults
  NotificationSettingsBuilder() {
    _enableNotifications = true;
    _weeklySummaryEnabled = true;
    _endOfDayEnabled = false;
    _endOfDayTime = '22:00';
  }

  late bool _enableNotifications;
  late bool _weeklySummaryEnabled;
  late bool _endOfDayEnabled;
  late String _endOfDayTime;

  /// Sets notification enabled status
  NotificationSettingsBuilder withEnableNotifications({required bool enabled}) {
    _enableNotifications = enabled;
    return this;
  }

  /// Sets weekly summary enabled status
  NotificationSettingsBuilder withWeeklySummaryEnabled({
    required bool enabled,
  }) {
    _weeklySummaryEnabled = enabled;
    return this;
  }

  /// Builds the notification settings
  NotificationSettings build() {
    return NotificationSettings(
      enableNotifications: _enableNotifications,
      weeklySummaryEnabled: _weeklySummaryEnabled,
      endOfDayEnabled: _endOfDayEnabled,
      endOfDayTime: _endOfDayTime,
    );
  }
}

/// Builder for creating [ScheduledNotificationEntry] test instances
class ScheduledNotificationEntryBuilder {
  /// Creates a scheduled notification entry builder with sensible defaults
  ScheduledNotificationEntryBuilder() {
    _notificationId = 12345;
    _scheduleId = 'test-schedule-id';
    _treatmentType = 'medication';
    _timeSlotISO = '08:00';
    _kind = 'initial';
  }

  late int _notificationId;
  late String _scheduleId;
  late String _treatmentType;
  late String _timeSlotISO;
  late String _kind;

  /// Sets the notification ID
  ScheduledNotificationEntryBuilder withNotificationId(int id) {
    _notificationId = id;
    return this;
  }

  /// Sets the schedule ID
  ScheduledNotificationEntryBuilder withScheduleId(String id) {
    _scheduleId = id;
    return this;
  }

  /// Sets the treatment type
  ScheduledNotificationEntryBuilder withTreatmentType(String type) {
    _treatmentType = type;
    return this;
  }

  /// Sets the time slot
  ScheduledNotificationEntryBuilder withTimeSlot(String timeSlot) {
    _timeSlotISO = timeSlot;
    return this;
  }

  /// Sets the kind
  ScheduledNotificationEntryBuilder withKind(String kind) {
    _kind = kind;
    return this;
  }

  /// Builds the scheduled notification entry
  ScheduledNotificationEntry build() {
    return ScheduledNotificationEntry(
      notificationId: _notificationId,
      scheduleId: _scheduleId,
      treatmentType: _treatmentType,
      timeSlotISO: _timeSlotISO,
      kind: _kind,
    );
  }
}
