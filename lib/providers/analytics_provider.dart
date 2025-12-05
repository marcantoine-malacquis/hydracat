import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/shared/services/firebase_service.dart';

/// Analytics event names
class AnalyticsEvents {
  /// Login event name
  static const String login = 'login';

  /// Sign up event name
  static const String signUp = 'sign_up';

  /// Email verification sent event name
  static const String emailVerificationSent = 'email_verification_sent';

  /// Email verified event name
  static const String emailVerified = 'email_verified';

  /// Password reset event name
  static const String passwordReset = 'password_reset';

  /// Social sign in event name
  static const String socialSignIn = 'social_sign_in';

  /// Sign out event name
  static const String signOut = 'sign_out';

  /// Feature used event name
  static const String featureUsed = 'feature_used';

  /// Screen view event name
  static const String screenView = 'screen_view';

  /// Error event name
  static const String error = 'app_error';

  /// Onboarding started event name
  static const String onboardingStarted = 'onboarding_started';

  /// Onboarding step completed event name
  static const String onboardingStepCompleted = 'onboarding_step_completed';

  /// Onboarding completed event name
  static const String onboardingCompleted = 'onboarding_completed';

  /// Onboarding abandoned event name
  static const String onboardingAbandoned = 'onboarding_abandoned';

  /// Schedules preloaded event name
  static const String schedulesPreloaded = 'schedules_preloaded';

  /// Schedules cache hit event name
  static const String schedulesCacheHit = 'schedules_cache_hit';

  // Duplicate detection optimization (Step 7.3)
  /// Duplicate check cache hit event name
  static const String duplicateCheckCacheHit = 'duplicate_check_cache_hit';

  /// Duplicate check cache miss event name
  static const String duplicateCheckCacheMiss = 'duplicate_check_cache_miss';

  /// Duplicate detected event name
  static const String duplicateDetected = 'duplicate_detected';

  /// Duplicate check query failed event name
  static const String duplicateCheckQueryFailed =
      'duplicate_check_query_failed';

  // Logging events
  /// Session logged event name
  static const String sessionLogged = 'session_logged';

  /// Quick log used event name
  static const String quickLogUsed = 'quick_log_used';

  /// Session updated event name
  static const String sessionUpdated = 'session_updated';

  /// Session deleted event name
  static const String sessionDeleted = 'session_deleted';

  /// Logging popup opened event name
  static const String loggingPopupOpened = 'logging_popup_opened';

  /// Treatment choice selected event name
  static const String treatmentChoiceSelected = 'treatment_choice_selected';

  /// Offline logging queued event name
  static const String offlineLoggingQueued = 'offline_logging_queued';

  /// Sync completed event name
  static const String syncCompleted = 'sync_completed';

  /// Cache warmed on startup event name
  static const String cacheWarmedOnStartup = 'cache_warmed_on_startup';

  // Failures (explicit hooks for product insights)
  /// Session log failed event name
  static const String sessionLogFailed = 'session_log_failed';

  /// Session update failed event name
  static const String sessionUpdateFailed = 'session_update_failed';

  /// Quick log failed event name
  static const String quickLogFailed = 'quick_log_failed';

  /// Offline sync failed event name
  static const String offlineSyncFailed = 'offline_sync_failed';

  /// Validation failed event name
  static const String validationFailed = 'validation_failed';

  /// Duplicate prevented event name
  static const String duplicatePrevented = 'duplicate_prevented';

  // Notification events
  /// Reminder tapped event name
  static const String reminderTapped = 'reminder_tapped';

  /// Reminder snoozed event name
  static const String reminderSnoozed = 'reminder_snoozed';

  /// Notification icon tapped event name
  static const String notificationIconTapped = 'notification_icon_tapped';

  /// Notification permission requested event name
  static const String notificationPermissionRequested =
      'notification_permission_requested';

  /// Notification permission dialog shown event name
  static const String notificationPermissionDialogShown =
      'notification_permission_dialog_shown';

  /// Weekly summary toggle event name
  static const String weeklySummaryToggled = 'weekly_summary_toggled';

  /// Privacy learn more event name
  static const String notificationPrivacyLearnMore =
      'notification_privacy_learn_more';

  /// Notification data cleared event name
  static const String notificationDataCleared = 'notification_data_cleared';

  /// Reminder canceled on log event name
  static const String reminderCanceledOnLog = 'reminder_canceled_on_log';

  /// Multi-day scheduling event name
  static const String multiDayScheduling = 'multi_day_scheduling';

  // Notification reliability events
  /// Index corruption detected event name
  static const String indexCorruptionDetected = 'index_corruption_detected';

  /// Index reconciliation performed event name
  static const String indexReconciliationPerformed =
      'index_reconciliation_performed';

  /// Notification limit reached event name
  static const String notificationLimitReached = 'notification_limit_reached';

  /// Notification limit warning event name
  static const String notificationLimitWarning = 'notification_limit_warning';

  // Schedule CRUD notification events
  /// Schedule created with reminders scheduled event name
  static const String scheduleCreatedRemindersScheduled =
      'schedule_created_reminders_scheduled';

  /// Schedule updated with reminders rescheduled event name
  static const String scheduleUpdatedRemindersRescheduled =
      'schedule_updated_reminders_rescheduled';

  /// Schedule deleted with reminders canceled event name
  static const String scheduleDeletedRemindersCanceled =
      'schedule_deleted_reminders_canceled';

  /// Schedule deactivated with reminders canceled event name
  static const String scheduleDeactivatedRemindersCanceled =
      'schedule_deactivated_reminders_canceled';

  // Notification error events
  /// Plugin initialization failed event name
  static const String notificationPluginInitFailed =
      'notification_plugin_init_failed';

  /// Permission revoked event name
  static const String notificationPermissionRevoked =
      'notification_permission_revoked';

  /// Scheduling failed event name
  static const String notificationSchedulingFailed =
      'notification_scheduling_failed';

  /// Cancellation failed event name
  static const String notificationCancellationFailed =
      'notification_cancellation_failed';

  /// Reconciliation failed event name
  static const String notificationReconciliationFailed =
      'notification_reconciliation_failed';

  /// Index rebuild succeeded event name
  static const String notificationIndexRebuildSuccess =
      'notification_index_rebuild_success';

  /// Index rebuild failed event name
  static const String notificationIndexRebuildFailed =
      'notification_index_rebuild_failed';

  // Weekly progress events
  /// Weekly progress card viewed event name
  static const String weeklyProgressViewed = 'weekly_progress_viewed';

  /// Weekly goal achieved event name
  static const String weeklyGoalAchieved = 'weekly_goal_achieved';

  /// Weekly progress card tapped event name (future enhancement)
  static const String weeklyCardTapped = 'weekly_card_tapped';
}

/// Analytics parameters
class AnalyticsParams {
  /// Method parameter name
  static const String method = 'method';

  /// Provider parameter name
  static const String provider = 'provider';

  /// Screen name parameter name
  static const String screenName = 'screen_name';

  /// Feature name parameter name
  static const String featureName = 'feature_name';

  /// Error type parameter name
  static const String errorType = 'error_type';

  /// User verified parameter name
  static const String userVerified = 'user_verified';

  /// User type parameter name
  static const String userType = 'user_type';

  /// Onboarding step parameter name
  static const String step = 'step';

  /// Next step parameter name
  static const String nextStep = 'next_step';

  /// Progress percentage parameter name
  static const String progressPercentage = 'progress_percentage';

  /// Pet ID parameter name
  static const String petId = 'pet_id';

  /// Schedule type parameter name (medication, fluid)
  static const String scheduleType = 'schedule_type';

  /// Has medication schedule parameter
  static const String hasMedication = 'has_medication';

  /// Has fluid schedule parameter
  static const String hasFluid = 'has_fluid';

  /// Duration parameter name
  static const String duration = 'duration_seconds';

  /// Completion rate parameter name
  static const String completionRate = 'completion_rate';

  /// Medication count parameter name
  static const String medicationCount = 'medication_count';

  /// Has fluid schedule parameter name
  static const String hasFluidSchedule = 'has_fluid_schedule';

  /// Cache miss parameter name
  static const String cacheMiss = 'cache_miss';

  // Logging params
  /// Treatment type parameter name
  static const String treatmentType = 'treatment_type';

  /// Session count parameter name
  static const String sessionCount = 'session_count';

  /// Is quick log parameter name
  static const String isQuickLog = 'is_quick_log';

  /// Logging mode parameter name
  static const String loggingMode = 'logging_mode';

  /// Volume given parameter name
  static const String volumeGiven = 'volume_given';

  /// Adherence status parameter name
  static const String adherenceStatus = 'adherence_status';

  /// Popup type parameter name
  static const String popupType = 'popup_type';

  /// Choice parameter name
  static const String choice = 'choice';

  /// Queue size parameter name
  static const String queueSize = 'queue_size';

  /// Sync duration parameter name
  static const String syncDuration = 'sync_duration_ms';

  /// Failure count parameter name
  static const String failureCount = 'failure_count';

  /// Medication session count parameter name
  static const String medicationSessionCount = 'medication_session_count';

  /// Fluid session count parameter name
  static const String fluidSessionCount = 'fluid_session_count';

  // Extended logging params
  /// Source of logging action (manual | quick_log | update)
  static const String source = 'source';

  /// Error code reported by backend if any
  static const String errorCode = 'error_code';

  /// Exception type/class name (non-sensitive)
  static const String exception = 'exception';

  /// Duration in milliseconds for the operation
  static const String durationMs = 'duration_ms';

  // Notification reliability params
  /// Schedule ID parameter name
  static const String scheduleId = 'schedule_id';

  /// Reminder count parameter name
  static const String reminderCount = 'reminder_count';

  /// Canceled count parameter name
  static const String canceledCount = 'canceled_count';

  /// Added count parameter name
  static const String addedCount = 'added_count';

  /// Removed count parameter name
  static const String removedCount = 'removed_count';

  /// Current count parameter name
  static const String currentCount = 'current_count';

  /// Result parameter name
  static const String result = 'result';

  // Weekly progress params
  /// Weekly progress fill percentage parameter (0.0 to 2.0, where 1.0 = 100%)
  static const String weeklyFillPercentage = 'weekly_fill_percentage';

  /// Weekly current volume parameter (ml)
  static const String weeklyCurrentVolume = 'weekly_current_volume';

  /// Weekly goal volume parameter (ml)
  static const String weeklyGoalVolume = 'weekly_goal_volume';

  /// Days remaining in week parameter (0-6)
  static const String daysRemainingInWeek = 'days_remaining_in_week';

  /// Achieved early flag parameter (completed before Sunday)
  static const String achievedEarly = 'achieved_early';

  /// Last injection site parameter
  static const String lastInjectionSite = 'last_injection_site';
}

/// Standardized error type constants for analytics tracking
class AnalyticsErrorTypes {
  // Cache errors
  /// Cache read failure error type
  static const String cacheReadFailure = 'cache_read_failure';

  /// Cache update failure error type
  static const String cacheUpdateFailure = 'cache_update_failure';

  /// Cache cleanup failure error type
  static const String cacheCleanupFailure = 'cache_cleanup_failure';

  /// Cache initialization failure error type
  static const String cacheInitializationFailure =
      'cache_initialization_failure';

  /// Cache warming failure error type
  static const String cacheWarmingFailure = 'cache_warming_failure';

  // Logging errors
  /// Log medication failure error type
  static const String logMedicationFailure = 'log_medication_failure';

  /// Log fluid failure error type
  static const String logFluidFailure = 'log_fluid_failure';

  /// Quick log failure error type
  static const String quickLogFailure = 'quick_log_failure';

  /// Session update failure error type
  static const String sessionUpdateFailure = 'session_update_failure';

  // Offline/sync errors
  /// Offline queue full error type
  static const String offlineQueueFull = 'offline_queue_full';

  /// Sync operation failure error type
  static const String syncOperationFailure = 'sync_operation_failure';

  // Validation errors
  /// Validation failure error type
  static const String validationFailure = 'validation_failure';

  /// Duplicate check query failed error type
  static const String duplicateCheckQueryFailed =
      'duplicate_check_query_failed';
}

/// User types for analytics
enum UserType {
  /// Anonymous user type
  anonymous,

  /// Unverified user type
  unverified,

  /// Verified user type
  verified,
}

/// Analytics service that integrates with authentication
class AnalyticsService {
  /// Creates an [AnalyticsService] with Firebase Analytics
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;
  bool _isEnabled = true;

  /// Enable or disable analytics tracking
  void setEnabled({required bool enabled}) {
    _isEnabled = enabled;
    _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  /// Check if analytics is enabled
  bool get isEnabled => _isEnabled;

  /// Set user ID for analytics tracking
  Future<void> setUserId(String? userId) async {
    if (!_isEnabled) return;

    await _analytics.setUserId(id: userId);
  }

  /// Set user properties based on auth state
  Future<void> setUserProperties({
    required UserType userType,
    String? provider,
  }) async {
    if (!_isEnabled) return;

    await _analytics.setUserProperty(
      name: AnalyticsParams.userType,
      value: userType.name,
    );

    if (provider != null) {
      await _analytics.setUserProperty(
        name: AnalyticsParams.provider,
        value: provider,
      );
    }
  }

  /// Track login events
  Future<void> trackLogin({
    required String method,
    bool success = true,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.login,
      parameters: {
        AnalyticsParams.method: method,
        'success': success,
      },
    );
  }

  /// Track sign up events
  Future<void> trackSignUp({
    required String method,
    bool success = true,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.signUp,
      parameters: {
        AnalyticsParams.method: method,
        'success': success,
      },
    );
  }

  /// Track email verification sent
  Future<void> trackEmailVerificationSent() async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.emailVerificationSent,
    );
  }

  /// Track email verification completed
  Future<void> trackEmailVerified() async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.emailVerified,
    );
  }

  /// Track password reset
  Future<void> trackPasswordReset() async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.passwordReset,
    );
  }

  /// Track social sign-in
  Future<void> trackSocialSignIn({
    required String provider,
    bool success = true,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.socialSignIn,
      parameters: {
        AnalyticsParams.provider: provider,
        'success': success,
      },
    );
  }

  /// Track sign out
  Future<void> trackSignOut() async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.signOut,
    );
  }

  /// Track feature usage
  Future<void> trackFeatureUsed({
    required String featureName,
    bool isVerifiedUser = false,
    Map<String, dynamic>? additionalParams,
  }) async {
    if (!_isEnabled) return;

    final params = <String, dynamic>{
      AnalyticsParams.featureName: featureName,
      AnalyticsParams.userVerified: isVerifiedUser,
    };

    if (additionalParams != null) {
      params.addAll(additionalParams);
    }

    await _analytics.logEvent(
      name: AnalyticsEvents.featureUsed,
      parameters: Map<String, Object>.from(params),
    );
  }

  /// Track screen views
  Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  /// Track errors (non-sensitive only)
  Future<void> trackError({
    required String errorType,
    String? errorContext,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.error,
      parameters: {
        AnalyticsParams.errorType: errorType,
        if (errorContext != null) 'context': errorContext,
      },
    );
  }

  /// Track logging failures with standardized context
  Future<void> trackLoggingFailure({
    required String errorType,
    String? treatmentType,
    String? source,
    String? errorCode,
    String? exception,
    Map<String, Object?> extra = const {},
  }) async {
    if (!_isEnabled) return;

    final params = <String, Object?>{
      AnalyticsParams.errorType: errorType,
      if (treatmentType != null) AnalyticsParams.treatmentType: treatmentType,
      if (source != null) AnalyticsParams.source: source,
      if (errorCode != null) AnalyticsParams.errorCode: errorCode,
      if (exception != null) AnalyticsParams.exception: exception,
      ...extra,
    };

    await _analytics.logEvent(
      name: AnalyticsEvents.error,
      parameters: Map<String, Object>.from(
        params..removeWhere((k, v) => v == null),
      ),
    );
  }

  /// Clear user data (on sign out)
  Future<void> clearUserData() async {
    if (!_isEnabled) return;

    await _analytics.setUserId();
    await _analytics.resetAnalyticsData();
  }

  /// Track onboarding started
  Future<void> trackOnboardingStarted({
    required String userId,
    String? timestamp,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.onboardingStarted,
      parameters: {
        'user_id': userId,
        if (timestamp != null) 'timestamp': timestamp,
      },
    );
  }

  /// Track onboarding step completed
  Future<void> trackOnboardingStepCompleted({
    required String userId,
    required String step,
    required String nextStep,
    required double progressPercentage,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.onboardingStepCompleted,
      parameters: {
        'user_id': userId,
        AnalyticsParams.step: step,
        AnalyticsParams.nextStep: nextStep,
        AnalyticsParams.progressPercentage: progressPercentage,
      },
    );
  }

  /// Track onboarding completed
  Future<void> trackOnboardingCompleted({
    required String userId,
    required String petId,
    int? durationSeconds,
    double completionRate = 1.0,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.onboardingCompleted,
      parameters: {
        'user_id': userId,
        AnalyticsParams.petId: petId,
        if (durationSeconds != null) AnalyticsParams.duration: durationSeconds,
        AnalyticsParams.completionRate: completionRate,
      },
    );
  }

  /// Track first schedule created (behavioral event)
  Future<void> trackFirstScheduleCreated({
    required String scheduleType,
    int? daysSinceSignup,
    int? totalScheduleCount,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: 'first_schedule_created',
      parameters: {
        AnalyticsParams.scheduleType: scheduleType,
        if (daysSinceSignup != null) 'days_since_signup': daysSinceSignup,
        if (totalScheduleCount != null) 'total_schedules': totalScheduleCount,
      },
    );
  }

  /// Track treatment pattern detected (behavioral event)
  Future<void> trackTreatmentPatternDetected({
    required bool hasMedication,
    required bool hasFluid,
    int? medicationCount,
    int? daysActive,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: 'treatment_pattern_detected',
      parameters: {
        AnalyticsParams.hasMedication: hasMedication,
        AnalyticsParams.hasFluid: hasFluid,
        if (medicationCount != null) 'medication_count': medicationCount,
        if (daysActive != null) 'days_active': daysActive,
      },
    );
  }

  /// Track onboarding abandoned
  Future<void> trackOnboardingAbandoned({
    required String userId,
    required String lastStep,
    required double progressPercentage,
    int? timeSpentSeconds,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.onboardingAbandoned,
      parameters: {
        'user_id': userId,
        AnalyticsParams.step: lastStep,
        AnalyticsParams.progressPercentage: progressPercentage,
        if (timeSpentSeconds != null) 'time_spent_seconds': timeSpentSeconds,
      },
    );
  }

  /// Track session logging events
  Future<void> trackSessionLogged({
    required String treatmentType,
    required int sessionCount,
    required bool isQuickLog,
    required String adherenceStatus,
    String? medicationName,
    double? volumeGiven,
    String? source,
    int? durationMs,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.sessionLogged,
      parameters: {
        AnalyticsParams.treatmentType: treatmentType,
        AnalyticsParams.sessionCount: sessionCount,
        AnalyticsParams.isQuickLog: isQuickLog,
        AnalyticsParams.adherenceStatus: adherenceStatus,
        if (medicationName != null) 'medication_name': medicationName,
        if (volumeGiven != null) AnalyticsParams.volumeGiven: volumeGiven,
        if (source != null) AnalyticsParams.source: source,
        if (durationMs != null) AnalyticsParams.durationMs: durationMs,
      },
    );
  }

  /// Track session deletion
  Future<void> trackSessionDeletion({
    required String treatmentType,
    required double volume,
    required bool inventoryAdjusted,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.sessionDeleted,
      parameters: {
        AnalyticsParams.treatmentType: treatmentType,
        AnalyticsParams.volumeGiven: volume.toInt(),
        'inventory_adjusted': inventoryAdjusted,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track quick-log feature usage
  Future<void> trackQuickLogUsed({
    required int sessionCount,
    required int medicationCount,
    required int fluidCount,
    int? durationMs,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.quickLogUsed,
      parameters: {
        AnalyticsParams.sessionCount: sessionCount,
        AnalyticsParams.medicationCount: medicationCount,
        'fluid_count': fluidCount,
        if (durationMs != null) AnalyticsParams.durationMs: durationMs,
      },
    );
  }

  /// Track session update events (future-ready)
  Future<void> trackSessionUpdated({
    required String treatmentType,
    required String updateReason,
    String? source,
    int? durationMs,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.sessionUpdated,
      parameters: {
        AnalyticsParams.treatmentType: treatmentType,
        'update_reason': updateReason,
        if (source != null) AnalyticsParams.source: source,
        if (durationMs != null) AnalyticsParams.durationMs: durationMs,
      },
    );
  }

  /// Track logging popup opened
  Future<void> trackLoggingPopupOpened({
    required String popupType,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.loggingPopupOpened,
      parameters: {
        AnalyticsParams.popupType: popupType,
      },
    );
  }

  /// Track treatment choice selection (from popup)
  Future<void> trackTreatmentChoiceSelected({
    required String choice,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.treatmentChoiceSelected,
      parameters: {
        AnalyticsParams.choice: choice,
      },
    );
  }

  /// Track notification tap with result outcome.
  ///
  /// Tracks when a user taps a notification reminder to deep-link to
  /// the logging screen. The [result] parameter indicates whether the
  /// tap was successful or why it failed.
  ///
  /// Result values:
  /// - 'success': Notification tapped, schedule found, logging screen shown
  /// - 'schedule_not_found': Schedule deleted since notification scheduled
  /// - 'user_not_authenticated': User logged out or session expired
  /// - 'onboarding_not_completed': User hasn't finished onboarding
  /// - 'pet_not_loaded': Pet profile not loaded
  /// - 'invalid_payload': Malformed notification payload
  /// - 'invalid_treatment_type': Unknown treatment type in payload
  /// - 'processing_error': Exception during payload processing
  Future<void> trackReminderTapped({
    required String treatmentType,
    required String kind,
    required String scheduleId,
    required String result,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.reminderTapped,
      parameters: {
        AnalyticsParams.treatmentType: treatmentType,
        'kind': kind,
        'schedule_id': scheduleId,
        'result': result,
      },
    );
  }

  /// Track notification snooze action.
  ///
  /// Tracks when user taps "Snooze 15 min" action button on a notification.
  /// Helps understand snooze feature usage and identify failure patterns.
  ///
  /// Parameters:
  /// - [treatmentType]: Type of treatment ('medication' or 'fluid')
  /// - [kind]: Original notification kind that was snoozed
  ///   ('initial' or 'followup')
  /// - [scheduleId]: Schedule ID for analytics correlation
  /// - [timeSlot]: Original time slot in "HH:mm" format
  /// - [result]: Outcome of snooze operation
  ///
  /// Result values:
  /// - 'success': Snooze scheduled successfully
  /// - 'invalid_payload': Malformed notification payload
  /// - 'invalid_kind': Attempted to snooze a 'snooze' notification
  /// - 'scheduling_failed': Plugin.showZoned threw exception
  /// - 'unknown_error': Unexpected error during snooze operation
  Future<void> trackReminderSnoozed({
    required String treatmentType,
    required String kind,
    required String scheduleId,
    required String timeSlot,
    required String result,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.reminderSnoozed,
      parameters: {
        AnalyticsParams.treatmentType: treatmentType,
        'kind': kind,
        'schedule_id': scheduleId,
        'time_slot': timeSlot,
        'result': result,
      },
    );
  }

  /// Track reminder cancellation after successful treatment logging.
  ///
  /// Tracks when notifications (initial, follow-up, snooze) are canceled
  /// after a user logs a treatment. Helps monitor notification cleanup
  /// effectiveness and identify issues with cancellation logic.
  ///
  /// This event is fired ONLY when a logged session matches a schedule
  /// (has both scheduleId and scheduledTime) and we attempt to cancel
  /// pending notifications for that time slot.
  ///
  /// Parameters:
  /// - [treatmentType]: Type of treatment ('medication' or 'fluid')
  /// - [scheduleId]: Schedule ID that the logged session matched to
  /// - [timeSlot]: Time slot in "HH:mm" format that was canceled
  /// - [canceledCount]: Number of notifications successfully canceled
  /// - [result]: Outcome of cancellation operation
  ///
  /// Result values:
  /// - 'success': At least one notification canceled successfully
  /// - 'none_found': No notifications were scheduled for this slot
  /// - 'error': Exception occurred during cancellation (check logs)
  ///
  /// Example usage:
  /// ```dart
  /// await analyticsService.trackReminderCanceledOnLog(
  ///   treatmentType: 'medication',
  ///   scheduleId: 'schedule_123',
  ///   timeSlot: '09:30',
  ///   canceledCount: 2, // initial + followup
  ///   result: 'success',
  /// );
  /// ```
  Future<void> trackReminderCanceledOnLog({
    required String treatmentType,
    required String scheduleId,
    required String timeSlot,
    required int canceledCount,
    required String result,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.reminderCanceledOnLog,
      parameters: {
        AnalyticsParams.treatmentType: treatmentType,
        'schedule_id': scheduleId,
        'time_slot': timeSlot,
        'canceled_count': canceledCount,
        'result': result,
      },
    );
  }

  /// Track notification icon tap in app bar.
  ///
  /// Tracks when user taps the bell icon in the home screen app bar.
  /// Helps understand permission request funnel and settings navigation.
  ///
  /// Permission status values:
  /// - 'enabled': Both permission granted and app setting enabled
  /// - 'denied': Permission denied (can request again)
  /// - 'permanentlyDenied': Permission permanently denied (Android only)
  /// - 'notDetermined': Permission not yet requested
  /// - 'setting_disabled': Permission granted but app setting disabled
  ///
  /// Action taken values:
  /// - 'navigated_to_app_settings': Navigated to notification settings screen
  /// - 'opened_permission_dialog': Showed permission request dialog
  /// - 'dismissed': User dismissed without action (if applicable)
  Future<void> trackNotificationIconTapped({
    required String permissionStatus,
    required String actionTaken,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.notificationIconTapped,
      parameters: {
        'permission_status': permissionStatus,
        'action_taken': actionTaken,
      },
    );
  }

  /// Track notification permission request and result.
  ///
  /// Tracks when app requests notification permission from the system
  /// and captures the user's response. Critical for understanding
  /// permission grant/denial rates.
  ///
  /// Parameters:
  /// - [previousStatus]: Permission status before request
  /// - [newStatus]: Permission status after request
  /// - [granted]: true if permission was granted, false otherwise
  Future<void> trackNotificationPermissionRequested({
    required String previousStatus,
    required String newStatus,
    required bool granted,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.notificationPermissionRequested,
      parameters: {
        'previous_status': previousStatus,
        'new_status': newStatus,
        'granted': granted,
      },
    );
  }

  /// Track notification permission dialog display.
  ///
  /// Tracks when the educational permission dialog is shown to the user.
  /// Helps understand drop-off in permission request funnel.
  ///
  /// Parameters:
  /// - [reason]: Why notifications are disabled (permission/setting/both)
  /// - [permissionStatus]: Current platform permission status
  Future<void> trackNotificationPermissionDialogShown({
    required String reason,
    required String permissionStatus,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.notificationPermissionDialogShown,
      parameters: {
        'reason': reason,
        'permission_status': permissionStatus,
      },
    );
  }

  /// Track weekly summary notification toggle change.
  ///
  /// Tracks when user enables or disables weekly summary notifications
  /// in the notification settings screen. Captures both success and
  /// failure cases to monitor scheduling issues.
  ///
  /// Parameters:
  /// - [enabled]: true if user enabled, false if disabled
  /// - [result]: 'success' if operation completed, 'error' if failed
  /// - [errorMessage]: Optional error message if result is 'error'
  Future<void> trackWeeklySummaryToggled({
    required bool enabled,
    required String result,
    String? errorMessage,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.weeklySummaryToggled,
      parameters: {
        'enabled': enabled,
        'result': result,
        if (errorMessage != null) 'error_message': errorMessage,
      },
    );
  }

  /// Tracks when user taps "Learn More" to view notification privacy details.
  ///
  /// This helps understand user engagement with privacy information and
  /// identify where users are most curious about data handling.
  ///
  /// Parameters:
  /// - [source]: Where the tap occurred ('preprompt' or 'settings')
  ///
  /// Example usage:
  /// ```dart
  /// await analyticsService.trackNotificationPrivacyLearnMore(
  ///   source: 'preprompt',
  /// );
  /// ```
  Future<void> trackNotificationPrivacyLearnMore({
    required String source,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.notificationPrivacyLearnMore,
      parameters: {
        'source': source, // 'preprompt' or 'settings'
      },
    );
  }

  /// Track multi-day scheduling completion.
  ///
  /// Tracks when notifications are scheduled for multiple days ahead
  /// to measure the effectiveness of the multi-day scheduling strategy.
  ///
  /// Parameters:
  /// - [daysScheduled]: Number of days scheduled
  /// - [totalNotifications]: Total number of notifications scheduled
  Future<void> trackMultiDayScheduling({
    required int daysScheduled,
    required int totalNotifications,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.multiDayScheduling,
      parameters: {
        'days': daysScheduled,
        'count': totalNotifications,
      },
    );
  }

  /// Tracks when user clears notification data.
  ///
  /// This helps monitor how often users need to reset their notification
  /// system and identify potential issues with notification reliability.
  ///
  /// Parameters:
  /// - [result]: Operation result ('success' or 'error')
  /// - [canceledCount]: Number of notifications canceled
  /// - [errorMessage]: Error details if result='error' (optional)
  ///
  /// Example usage:
  /// ```dart
  /// // Success case
  /// await analyticsService.trackNotificationDataCleared(
  ///   result: 'success',
  ///   canceledCount: 5,
  /// );
  ///
  /// // Error case
  /// await analyticsService.trackNotificationDataCleared(
  ///   result: 'error',
  ///   canceledCount: 0,
  ///   errorMessage: 'Permission denied',
  /// );
  /// ```
  Future<void> trackNotificationDataCleared({
    required String result,
    required int canceledCount,
    String? errorMessage,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.notificationDataCleared,
      parameters: {
        'result': result, // 'success' or 'error'
        'canceled_count': canceledCount,
        if (errorMessage != null) 'error_message': errorMessage,
      },
    );
  }

  /// Track offline queue and sync events
  Future<void> trackOfflineSync({
    required int queueSize,
    required int successCount,
    required int failureCount,
    required int syncDurationMs,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.syncCompleted,
      parameters: {
        AnalyticsParams.queueSize: queueSize,
        'success_count': successCount,
        AnalyticsParams.failureCount: failureCount,
        AnalyticsParams.syncDuration: syncDurationMs,
      },
    );
  }

  /// Track index corruption detection.
  ///
  /// Fired when NotificationIndexStore detects checksum validation failure,
  /// indicating data corruption in SharedPreferences.
  Future<void> trackIndexCorruptionDetected({
    required String userId,
    required String petId,
    required String date,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.indexCorruptionDetected,
      parameters: {
        'user_id': userId,
        AnalyticsParams.petId: petId,
        'date': date,
      },
    );
  }

  /// Track index reconciliation operation and discrepancy counts.
  Future<void> trackIndexReconciliationPerformed({
    required String userId,
    required String petId,
    required int added,
    required int removed,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.indexReconciliationPerformed,
      parameters: {
        'user_id': userId,
        AnalyticsParams.petId: petId,
        AnalyticsParams.addedCount: added,
        AnalyticsParams.removedCount: removed,
      },
    );
  }

  /// Track notification limit reached (50 per pet).
  Future<void> trackNotificationLimitReached({
    required String petId,
    required int currentCount,
    required String scheduleId,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.notificationLimitReached,
      parameters: {
        AnalyticsParams.petId: petId,
        AnalyticsParams.currentCount: currentCount,
        AnalyticsParams.scheduleId: scheduleId,
      },
    );
  }

  /// Track notification limit warning (80% threshold).
  Future<void> trackNotificationLimitWarning({
    required String petId,
    required int currentCount,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.notificationLimitWarning,
      parameters: {
        AnalyticsParams.petId: petId,
        AnalyticsParams.currentCount: currentCount,
      },
    );
  }

  /// Track notification scheduling after schedule creation.
  Future<void> trackScheduleCreatedRemindersScheduled({
    required String treatmentType,
    required String scheduleId,
    required int reminderCount,
    required String result,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.scheduleCreatedRemindersScheduled,
      parameters: {
        AnalyticsParams.treatmentType: treatmentType,
        AnalyticsParams.scheduleId: scheduleId,
        AnalyticsParams.reminderCount: reminderCount,
        AnalyticsParams.result: result,
      },
    );
  }

  /// Track notification rescheduling after schedule update.
  Future<void> trackScheduleUpdatedRemindersRescheduled({
    required String treatmentType,
    required String scheduleId,
    required int reminderCount,
    required String result,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.scheduleUpdatedRemindersRescheduled,
      parameters: {
        AnalyticsParams.treatmentType: treatmentType,
        AnalyticsParams.scheduleId: scheduleId,
        AnalyticsParams.reminderCount: reminderCount,
        AnalyticsParams.result: result,
      },
    );
  }

  /// Track notification cancellation after schedule deletion.
  Future<void> trackScheduleDeletedRemindersCanceled({
    required String treatmentType,
    required String scheduleId,
    required int canceledCount,
    required String result,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.scheduleDeletedRemindersCanceled,
      parameters: {
        AnalyticsParams.treatmentType: treatmentType,
        AnalyticsParams.scheduleId: scheduleId,
        AnalyticsParams.canceledCount: canceledCount,
        AnalyticsParams.result: result,
      },
    );
  }

  /// Track notification cancellation after schedule deactivation.
  Future<void> trackScheduleDeactivatedRemindersCanceled({
    required String treatmentType,
    required String scheduleId,
    required int canceledCount,
    required String result,
  }) async {
    if (!_isEnabled) return;

    await _analytics.logEvent(
      name: AnalyticsEvents.scheduleDeactivatedRemindersCanceled,
      parameters: {
        AnalyticsParams.treatmentType: treatmentType,
        AnalyticsParams.scheduleId: scheduleId,
        AnalyticsParams.canceledCount: canceledCount,
        AnalyticsParams.result: result,
      },
    );
  }

  /// Track notification error events.
  ///
  /// Used by NotificationErrorHandler to track all error scenarios:
  /// - Plugin initialization failures
  /// - Scheduling/cancellation failures
  /// - Permission revocation
  /// - Index corruption and rebuild attempts
  ///
  /// Parameters:
  /// - [errorType]: Type of error (e.g., 'notification_plugin_init_failed')
  /// - [operation]: Operation that failed
  /// (e.g., 'schedule_medication_reminder')
  /// - [userId]: Current user ID (required)
  /// - [petId]: Pet ID if applicable (optional)
  /// - [scheduleId]: Schedule ID if applicable (optional)
  /// - [errorMessage]: Human-readable error message (optional)
  /// - [additionalContext]: Additional key-value pairs for debugging (optional)
  Future<void> trackNotificationError({
    required String errorType,
    required String operation,
    required String userId,
    String? petId,
    String? scheduleId,
    String? errorMessage,
    Map<String, dynamic>? additionalContext,
  }) async {
    if (!_isEnabled) return;

    final parameters = <String, dynamic>{
      'operation': operation,
      'user_id': userId,
    };

    if (petId != null) {
      parameters[AnalyticsParams.petId] = petId;
    }

    if (scheduleId != null) {
      parameters[AnalyticsParams.scheduleId] = scheduleId;
    }

    if (errorMessage != null) {
      parameters['error_message'] = errorMessage;
    }

    if (additionalContext != null) {
      parameters.addAll(additionalContext);
    }

    await _analytics.logEvent(
      name: errorType,
      parameters: Map<String, Object>.from(parameters),
    );
  }

  /// Tracks when background scheduling completes successfully via FCM.
  Future<void> trackBackgroundSchedulingSuccess({
    required int notificationCount,
    required String triggerSource,
  }) async {
    if (!_isEnabled) return;

    try {
      await _analytics.logEvent(
        name: 'background_scheduling_success',
        parameters: {
          'notification_count': notificationCount,
          'trigger_source': triggerSource,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Failed to track background scheduling: $e');
      }
      // Don't throw - analytics failure shouldn't break functionality
    }
  }

  /// Tracks when background scheduling fails.
  Future<void> trackBackgroundSchedulingError({
    required String errorReason,
    required String triggerSource,
  }) async {
    if (!_isEnabled) return;

    try {
      await _analytics.logEvent(
        name: 'background_scheduling_error',
        parameters: {
          'error_reason': errorReason,
          'trigger_source': triggerSource,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Failed to track background error: $e');
      }
    }
  }

  /// Tracks when FCM daily wake-up message is received.
  Future<void> trackFcmDailyWakeupReceived() async {
    if (!_isEnabled) return;

    try {
      await _analytics.logEvent(
        name: 'fcm_daily_wakeup_received',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Failed to track FCM wake-up: $e');
      }
    }
  }

  /// Track weekly progress card view.
  ///
  /// Tracks when the weekly progress card is displayed to the user with data.
  /// Helps understand engagement with the weekly progress feature.
  ///
  /// Parameters:
  /// - [fillPercentage]: Current progress (0.0 to 2.0, where 1.0 = 100%)
  /// - [currentVolume]: Volume given this week (ml)
  /// - [goalVolume]: Weekly goal volume (ml)
  /// - [daysRemainingInWeek]: Days left in current week (0-6)
  /// - [lastInjectionSite]: Last injection site used (optional)
  /// - [petId]: Pet identifier (optional)
  Future<void> trackWeeklyProgressViewed({
    required double fillPercentage,
    required double currentVolume,
    required int goalVolume,
    required int daysRemainingInWeek,
    String? lastInjectionSite,
    String? petId,
  }) async {
    if (!_isEnabled) return;

    try {
      await _analytics.logEvent(
        name: AnalyticsEvents.weeklyProgressViewed,
        parameters: {
          AnalyticsParams.weeklyFillPercentage: fillPercentage,
          AnalyticsParams.weeklyCurrentVolume: currentVolume,
          AnalyticsParams.weeklyGoalVolume: goalVolume,
          AnalyticsParams.daysRemainingInWeek: daysRemainingInWeek,
          if (lastInjectionSite != null)
            AnalyticsParams.lastInjectionSite: lastInjectionSite,
          if (petId != null) AnalyticsParams.petId: petId,
        },
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Failed to track weekly progress viewed: $e');
      }
    }
  }

  /// Track weekly goal achievement.
  ///
  /// Tracks when user completes their weekly fluid therapy goal
  /// (fillPercentage >= 1.0). Fires once per week when threshold is crossed,
  /// celebrating the milestone.
  ///
  /// Parameters:
  /// - [finalVolume]: Total volume given when goal achieved (ml)
  /// - [goalVolume]: Weekly goal volume (ml)
  /// - [daysRemainingInWeek]: Days left in week when achieved (0-6)
  /// - [achievedEarly]: true if completed before Sunday
  /// - [petId]: Pet identifier (optional)
  Future<void> trackWeeklyGoalAchieved({
    required double finalVolume,
    required int goalVolume,
    required int daysRemainingInWeek,
    required bool achievedEarly,
    String? petId,
  }) async {
    if (!_isEnabled) return;

    try {
      await _analytics.logEvent(
        name: AnalyticsEvents.weeklyGoalAchieved,
        parameters: {
          AnalyticsParams.weeklyCurrentVolume: finalVolume,
          AnalyticsParams.weeklyGoalVolume: goalVolume,
          AnalyticsParams.daysRemainingInWeek: daysRemainingInWeek,
          AnalyticsParams.achievedEarly: achievedEarly,
          if (petId != null) AnalyticsParams.petId: petId,
        },
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Failed to track weekly goal achieved: $e');
      }
    }
  }
}

/// Notifier class for managing analytics with authentication integration
class AnalyticsNotifier extends StateNotifier<bool> {
  /// Creates an [AnalyticsNotifier] with the provided dependencies
  AnalyticsNotifier(this._ref, this._analyticsService) : super(true) {
    _listenToAuthChanges();
    // Enable analytics by default in production, disable in debug
    _analyticsService.setEnabled(enabled: !kDebugMode);
  }

  final Ref _ref;
  final AnalyticsService _analyticsService;

  /// Listen to authentication state changes
  void _listenToAuthChanges() {
    _ref.listen(
      authProvider,
      _handleAuthStateChange,
    );
  }

  /// Handle authentication state changes
  void _handleAuthStateChange(AuthState? previous, AuthState current) {
    switch (current) {
      case AuthStateAuthenticated(user: final user):
        _handleUserAuthenticated(
          user.id,
          user.emailVerified,
          user.provider.name,
        );
      case AuthStateUnauthenticated():
        _handleUserSignedOut();
      case AuthStateLoading():
        // No action needed during loading
        break;
      case AuthStateError():
        // No action needed for auth errors
        break;
    }

    // Track authentication state changes
    _trackAuthStateChange(previous, current);
  }

  /// Handle authenticated user
  void _handleUserAuthenticated(
    String userId,
    bool emailVerified,
    String provider,
  ) {
    // Set user ID for analytics
    _analyticsService.setUserId(userId);

    // Set user properties
    final userType = emailVerified ? UserType.verified : UserType.unverified;
    _analyticsService.setUserProperties(
      userType: userType,
      provider: provider,
    );
  }

  /// Handle user signed out
  void _handleUserSignedOut() {
    // Clear analytics user data and set anonymous user properties
    _analyticsService
      ..clearUserData()
      ..setUserProperties(
        userType: UserType.anonymous,
      );
  }

  /// Track authentication state changes
  void _trackAuthStateChange(AuthState? previous, AuthState current) {
    // Track login success
    if (previous is! AuthStateAuthenticated &&
        current is AuthStateAuthenticated) {
      _analyticsService.trackLogin(
        method: current.user.provider.name,
      );
    }

    // Track sign out
    if (previous is AuthStateAuthenticated &&
        current is AuthStateUnauthenticated) {
      _analyticsService.trackSignOut();
    }

    // Track login errors
    if (current is AuthStateError) {
      _analyticsService.trackError(
        errorType: 'auth_error',
        errorContext: current.code ?? 'unknown',
      );
    }
  }

  /// Enable or disable analytics
  void setEnabled({required bool enabled}) {
    state = enabled;
    _analyticsService.setEnabled(enabled: enabled);
  }

  /// Get analytics service for direct usage
  AnalyticsService get service => _analyticsService;
}

/// Provider for Firebase Analytics service
final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseService().analytics;
});

/// Provider for analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final analytics = ref.read(firebaseAnalyticsProvider);
  return AnalyticsService(analytics);
});

/// Provider for analytics state management
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, bool>((ref) {
  final analyticsService = ref.read(analyticsServiceProvider);
  return AnalyticsNotifier(ref, analyticsService);
});

/// Convenience provider to check if analytics is enabled
final isAnalyticsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(analyticsProvider);
});

/// Convenience provider to get analytics service directly
final analyticsServiceDirectProvider = Provider<AnalyticsService>((ref) {
  final notifier = ref.read(analyticsProvider.notifier);
  return notifier.service;
});
