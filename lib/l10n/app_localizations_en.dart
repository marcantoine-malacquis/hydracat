// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'HydraCat';

  @override
  String get appDescription =>
      'Hydration tracking for cats with kidney disease';

  @override
  String get save => 'Save';

  @override
  String get saveAndContinue => 'Save & Continue';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get confirm => 'Confirm';

  @override
  String get retry => 'Retry';

  @override
  String get skip => 'Skip';

  @override
  String get skipForNow => 'Skip for Now';

  @override
  String get getStarted => 'Get Started';

  @override
  String get goBack => 'Go Back';

  @override
  String get continue_ => 'Continue';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Information';

  @override
  String get finishingSetup => 'Finishing setup...';

  @override
  String get welcomeTitle => 'Welcome to HydraCat';

  @override
  String get welcomeSubtitle =>
      'Managing chronic kidney disease can feel overwhelming, but you\'re not alone. HydraCat helps you track treatments, monitor progress, and stay connected with your vet.';

  @override
  String get yourCkdJourneyStartsHere => 'Your CKD Journey Starts Here';

  @override
  String get failedToSkipOnboarding =>
      'Failed to skip onboarding. Please try again.';

  @override
  String get userPersonaTitle => 'How do you manage your pet\'s CKD?';

  @override
  String get userPersonaSubtitle =>
      'Choose the approach that best matches your current treatment plan.';

  @override
  String get petBasicsTitle => 'Tell us about your cat';

  @override
  String get petNameLabel => 'Pet Name *';

  @override
  String get petNameHint => 'Enter your cat\'s name';

  @override
  String get petDateOfBirthLabel => 'Date of Birth *';

  @override
  String get selectDateOfBirth => 'Select date of birth';

  @override
  String get petGenderLabel => 'Gender *';

  @override
  String get petBreedLabel => 'Breed';

  @override
  String get petBreedHint => 'Enter breed (optional)';

  @override
  String errorSavingPetInfo(String error) {
    return 'Error saving pet information: $error';
  }

  @override
  String get petGenderRequired => 'Please select your cat\'s gender';

  @override
  String get petGenderInvalid => 'Gender must be either male or female';

  @override
  String get petNameRequired => 'Pet name is required';

  @override
  String get petNameTooLong => 'Pet name must be 50 characters or less';

  @override
  String get petAgeRequired => 'Pet age is required';

  @override
  String get petAgeInvalid => 'Pet age must be greater than 0';

  @override
  String get petAgeUnrealistic => 'Pet age seems unrealistic (over 25 years)';

  @override
  String get petWeightInvalid => 'Weight must be greater than 0';

  @override
  String get petWeightUnrealistic =>
      'Weight seems unrealistic (over 15kg for a cat)';

  @override
  String get medicalInfoTitle => 'Medical Information';

  @override
  String get lastBloodworkResults => 'Last Bloodwork Results';

  @override
  String get lastCheckupDateLabel => 'Last Checkup Date';

  @override
  String get selectLastCheckupDate => 'Select last checkup date (optional)';

  @override
  String get bloodworkDateLabel => 'Bloodwork Date';

  @override
  String get selectBloodworkDate => 'Select bloodwork date';

  @override
  String get bunLabel => 'BUN (Blood Urea Nitrogen)';

  @override
  String get creatinineLabel => 'Creatinine';

  @override
  String get phosphorusLabel => 'Phosphorus';

  @override
  String get skipMedicalInfoTitle => 'Skip Medical Information?';

  @override
  String get skipMedicalInfoMessage =>
      'You can add this information later from your pet\'s profile.';

  @override
  String errorSavingMedicalInfo(String error) {
    return 'Error saving medical information: $error';
  }

  @override
  String get treatmentSetupTitle => 'Treatment Setup';

  @override
  String get setUpYourMedications => 'Set up your medications';

  @override
  String get setUpYourFluidTherapy => 'Set up your fluid therapy';

  @override
  String get medicationSetupTitle => 'Medication Setup';

  @override
  String get addMedicationDetails => 'Add Medication Details';

  @override
  String get editMedicationDetails => 'Edit Medication Details';

  @override
  String get addMedication => 'Add Medication';

  @override
  String get medicationInformation => 'Medication Information';

  @override
  String get medicationInformationDesc =>
      'Enter the name and dosage form of the medication.';

  @override
  String get medicationNameLabel => 'Medication Name *';

  @override
  String get medicationNameHint => 'e.g., Benazepril, Furosemide';

  @override
  String get medicationStrengthLabel => 'Medication Strength (optional)';

  @override
  String get medicationStrengthDesc =>
      'Enter the concentration or strength of the medication';

  @override
  String get strengthAmountLabel => 'Amount';

  @override
  String get strengthAmountHint => 'e.g., 2.5, 1/2, 10';

  @override
  String get strengthUnitLabel => 'Unit';

  @override
  String get customStrengthUnitLabel => 'Custom Unit';

  @override
  String get customStrengthUnitHint => 'e.g., mg/kg';

  @override
  String get strengthHelperText => 'e.g., 2.5 mg, 5 mg/mL';

  @override
  String get dosageLabel => 'Dosage';

  @override
  String get setDosage => 'Set Dosage';

  @override
  String get dosageAmountRequired => 'Required: amount per administration';

  @override
  String get unitTypeLabel => 'Unit Type *';

  @override
  String get frequencyLabel => 'Frequency';

  @override
  String get setFrequency => 'Set Frequency';

  @override
  String get administrationFrequency => 'Administration Frequency';

  @override
  String get reminderTimesTitle => 'Reminder Times';

  @override
  String get setReminderTimes => 'Set Reminder Times';

  @override
  String get editMedicationTooltip => 'Edit medication';

  @override
  String get deleteMedicationTooltip => 'Delete medication';

  @override
  String get deleteMedicationTitle => 'Delete Medication';

  @override
  String get deleteMedicationMessage =>
      'Are you sure you want to delete this medication?';

  @override
  String failedToSaveMedication(String error) {
    return 'Failed to save medication: $error';
  }

  @override
  String failedToSaveProgress(String error) {
    return 'Failed to save progress: $error';
  }

  @override
  String get saveMedication => 'Save Medication';

  @override
  String get fluidTherapySetupTitle => 'Fluid Therapy Setup';

  @override
  String get volumeLabel => 'Volume per session (mL) *';

  @override
  String get volumeHint => '100.0';

  @override
  String get volumeHelperText => 'Typical range: 50-300ml for cats';

  @override
  String totalPlannedToday(int volume) {
    return 'Total planned today: $volume mL';
  }

  @override
  String get preferredLocationLabel => 'Preferred Administration Location';

  @override
  String get needleGaugeLabel => 'Needle Gauge *';

  @override
  String get needleGaugeHint => '20G, 22G, 25G';

  @override
  String failedToSaveFluidTherapy(String error) {
    return 'Failed to save fluid therapy setup: $error';
  }

  @override
  String get onboardingCompleteTitle => 'You\'re All Set!';

  @override
  String readyToStartTracking(String petName) {
    return 'Ready to start tracking $petName\'s care journey';
  }

  @override
  String get dailyTime => 'Daily time';

  @override
  String get firstIntake => 'First intake';

  @override
  String get secondIntake => 'Second intake';

  @override
  String get thirdIntake => 'Third intake';

  @override
  String timeNumber(int number) {
    return 'Time $number';
  }

  @override
  String get reminderTimesLabel => 'Reminder Times';

  @override
  String get frequencyOnceDaily => 'Set a time for the daily administration';

  @override
  String get frequencyTwiceDaily =>
      'Set times for morning and evening administration (12 hours apart recommended)';

  @override
  String get frequencyThreeTimesDaily =>
      'Set times for morning, afternoon, and evening administration (8 hours apart recommended)';

  @override
  String get frequencyEveryOtherDay =>
      'Set a preferred time for every-other-day administration';

  @override
  String get frequencyAsNeeded =>
      'No fixed schedule - you\'ll log when administered';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get logging => 'Session Logging';

  @override
  String get progress => 'Progress & Analytics';

  @override
  String get resources => 'Resources & Tips';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get hydrationSession => 'Hydration Session';

  @override
  String get fluidIntake => 'Fluid Intake';

  @override
  String get sessionDuration => 'Session Duration';

  @override
  String get startSession => 'Start Session';

  @override
  String get endSession => 'End Session';

  @override
  String get sessionNotes => 'Session Notes';

  @override
  String get catName => 'Cat Name';

  @override
  String get catAge => 'Age';

  @override
  String get catWeight => 'Weight';

  @override
  String get catBreed => 'Breed';

  @override
  String get medicalNotes => 'Medical Notes';

  @override
  String get milliliters => 'ml';

  @override
  String get minutes => 'min';

  @override
  String get kilograms => 'kg';

  @override
  String get pounds => 'lbs';

  @override
  String get years => 'years';

  @override
  String get enterCatName => 'Enter cat name';

  @override
  String get enterWeight => 'Enter weight';

  @override
  String get enterAge => 'Enter age';

  @override
  String get addNotes => 'Add notes...';

  @override
  String get loggingNotesLabel => 'Notes (optional)';

  @override
  String get loggingNotesHintSession => 'Add any notes about this session...';

  @override
  String get loggingNotesHintTreatment =>
      'Add any notes about this treatment...';

  @override
  String get loggingUserNotFound => 'User or pet not found. Please try again.';

  @override
  String get loggingCloseTooltip => 'Close';

  @override
  String get loggingClosePopupSemantic => 'Close popup';

  @override
  String loggingPopupSemantic(String title) {
    return '$title popup';
  }

  @override
  String get fluidLoggingTitle => 'Log Fluid Session';

  @override
  String get fluidLoggingLoadingMessage => 'Logging fluid session';

  @override
  String get fluidVolumeRequired => 'Volume is required';

  @override
  String get fluidVolumeInvalid => 'Please enter a valid number';

  @override
  String get fluidVolumeMin => 'Volume must be at least 1ml';

  @override
  String get fluidVolumeMax => 'Volume must be 500ml or less';

  @override
  String fluidAlreadyLoggedToday(int volume) {
    return '${volume}mL already logged today';
  }

  @override
  String get fluidStressLevelLabel => 'Stress Level (optional):';

  @override
  String get fluidLogButtonLabel => 'Log fluid session button';

  @override
  String get fluidLogButtonHint =>
      'Logs fluid therapy session and updates treatment records';

  @override
  String get calculateFromWeight => 'Calculate from weight';

  @override
  String get weightCalculatorTitle => 'Calculate Fluid Volume from Weight';

  @override
  String get continueFromSameBag => 'Continue from same bag?';

  @override
  String get useThisWeight => 'Use This Weight';

  @override
  String get beforeFluidTherapy => 'Before fluid therapy:';

  @override
  String get initialWeightLabel => 'Initial weight';

  @override
  String get afterFluidTherapy => 'After fluid therapy:';

  @override
  String get finalWeightLabel => 'Final weight';

  @override
  String fluidAdministered(String volume) {
    return 'Fluid administered: ~$volume mL';
  }

  @override
  String get ringersDensityNote => '(1g Ringer\'s ≈ 1mL)';

  @override
  String get importantTipsTitle => '⚠️ Important tips:';

  @override
  String get weightTip1 => 'Weigh same components both times';

  @override
  String get weightTip2 => 'Use stable surface & calibrate scale';

  @override
  String get useThisVolume => 'Use This Volume';

  @override
  String remainingWeight(String weight) {
    return '${weight}g remaining';
  }

  @override
  String lastUsedDate(String date) {
    return 'Last used $date';
  }

  @override
  String get medicationLoggingTitle => 'Log Medication';

  @override
  String get medicationLoggingLoadingMessage => 'Logging medication session';

  @override
  String get medicationSelectLabel => 'Select Medications:';

  @override
  String get medicationSelectAll => 'Select All';

  @override
  String get medicationDeselectAll => 'Deselect All';

  @override
  String get medicationNoneScheduled => 'No medications scheduled for today';

  @override
  String get medicationLogButton => 'Log Medication';

  @override
  String medicationLogButtonMultiple(int count) {
    return 'Log $count Medications';
  }

  @override
  String get medicationLogButtonSemanticSingle =>
      'Logs 1 selected medication and updates treatment records';

  @override
  String medicationLogButtonSemanticMultiple(int count) {
    return 'Logs $count selected medications and updates treatment records';
  }

  @override
  String get treatmentChoiceTitle => 'Add one-time entry';

  @override
  String get treatmentChoiceMedicationLabel => 'Log medication';

  @override
  String get treatmentChoiceMedicationHint =>
      'Opens medication logging form to record treatment';

  @override
  String get treatmentChoiceFluidLabel => 'Log fluid therapy';

  @override
  String get treatmentChoiceFluidHint =>
      'Opens fluid therapy logging form to record subcutaneous fluids';

  @override
  String get treatmentChoiceSemanticLabel => 'Choose treatment type to log';

  @override
  String get treatmentChoiceCancelSemantic =>
      'Closes treatment selection without logging';

  @override
  String get duplicateDialogTitle => 'Already Logged';

  @override
  String duplicateDialogMessage(String medication, String time) {
    return 'You already logged $medication at $time.';
  }

  @override
  String get duplicateDialogCurrentSession => 'Current Session';

  @override
  String get duplicateDialogNewEntry => 'Your New Entry';

  @override
  String get duplicateDialogSummaryWarning =>
      'Your treatment records will be updated to reflect the new values.';

  @override
  String get duplicateDialogCreateNew => 'Create New';

  @override
  String get duplicateDialogCreateNewMessage =>
      'Creating duplicate sessions will be available soon';

  @override
  String get duplicateDialogUpdate => 'Update';

  @override
  String get duplicateDialogUpdateMessage => 'Update feature coming soon';

  @override
  String duplicateDialogLoggedAt(String time) {
    return 'Logged at $time';
  }

  @override
  String get duplicateDialogDosage => 'Dosage';

  @override
  String get duplicateDialogStatus => 'Status';

  @override
  String get duplicateDialogStatusCompleted => 'Completed';

  @override
  String get duplicateDialogStatusNotCompleted => 'Not completed';

  @override
  String get duplicateDialogNotes => 'Notes';

  @override
  String get duplicateDialogNoNotes => 'No notes';

  @override
  String get quickLogTreatmentSingular => 'treatment';

  @override
  String get quickLogTreatmentPlural => 'treatments';

  @override
  String quickLogSuccess(int count, String treatment, String petName) {
    return '$count $treatment logged for $petName ✓';
  }

  @override
  String quickLogSuccessSemantic(int count, String treatment, String petName) {
    return '$count $treatment logged for $petName';
  }

  @override
  String get quickLogSuccessHint => 'Success. Tap anywhere to dismiss.';

  @override
  String get injectionSiteLabel => 'Injection Site';

  @override
  String get injectionSiteSelectorSemantic => 'Injection site selector';

  @override
  String injectionSiteCurrentSelection(String site) {
    return 'Current selection: $site';
  }

  @override
  String get injectionSiteNoSelection => 'No injection site selected';

  @override
  String get stressLevelSelectorSemantic => 'Stress level selector';

  @override
  String get stressLevelLow => 'Low';

  @override
  String get stressLevelMedium => 'Medium';

  @override
  String get stressLevelHigh => 'High';

  @override
  String get stressLevelLowTooltip => 'Low stress level';

  @override
  String get stressLevelMediumTooltip => 'Medium stress level';

  @override
  String get stressLevelHighTooltip => 'High stress level';

  @override
  String stressLevelCurrentSelection(String level) {
    return 'Current selection: $level stress level';
  }

  @override
  String get stressLevelNoSelection => 'No stress level selected';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorPermissionDenied =>
      'Unable to save. Please check your account permissions.';

  @override
  String get errorConnectionTimeout =>
      'Connection timeout. Your data is saved offline and will sync automatically.';

  @override
  String get errorServiceUnavailable =>
      'Service temporarily unavailable. Please try again in a moment.';

  @override
  String get errorOffline =>
      'Unable to save right now. Your data is saved offline.';

  @override
  String get errorSyncLater => '(will sync later)';

  @override
  String get errorSyncWhenOnline => 'Will sync when online.';

  @override
  String get errorValidationGeneric =>
      'Please check your entries and try again.';

  @override
  String get errorScheduleNotFound =>
      'We couldn\'t find a matching schedule. Logging as a one-time entry.';

  @override
  String get errorDuplicateSession =>
      'You\'ve already logged this treatment today. Would you like to update it instead?';

  @override
  String get successOfflineLogged =>
      'Logged successfully! Will sync when you are back online.';

  @override
  String errorSyncFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count treatments',
      one: '1 treatment',
    );
    return '$_temp0 could not sync. Check your connection and tap retry.';
  }

  @override
  String warningQueueSize(int count) {
    return 'You have $count treatments waiting to sync. Connect to internet soon to avoid data loss.';
  }

  @override
  String errorQueueFull(int count) {
    return 'Too many treatments waiting to sync ($count). Please connect to internet to free up space.';
  }

  @override
  String get notificationMedicationTitle => 'Medication reminder';

  @override
  String notificationMedicationBody(String petName) {
    return 'Time for $petName\'s medication';
  }

  @override
  String get notificationFluidTitle => 'Fluid therapy reminder';

  @override
  String notificationFluidBody(String petName) {
    return 'Time for $petName\'s fluid therapy';
  }

  @override
  String get notificationFollowupTitle => 'Treatment reminder';

  @override
  String notificationFollowupBody(String petName) {
    return '$petName may still need their treatment';
  }

  @override
  String notificationMedicationTitleA11y(String petName) {
    return 'Treatment reminder: Medication for $petName';
  }

  @override
  String notificationMedicationBodyA11y(String petName) {
    return 'It\'s time to give $petName their medication.';
  }

  @override
  String notificationFluidTitleA11y(String petName) {
    return 'Treatment reminder: Fluid therapy for $petName';
  }

  @override
  String notificationFluidBodyA11y(String petName) {
    return 'It\'s time to give $petName their fluid therapy.';
  }

  @override
  String notificationFollowupTitleA11y(String petName) {
    return 'Treatment reminder for $petName';
  }

  @override
  String notificationFollowupBodyA11y(String petName) {
    return '$petName may still need their treatment.';
  }

  @override
  String get notificationWeeklySummaryTitle => 'Your weekly summary is ready!';

  @override
  String get notificationWeeklySummaryBody =>
      'Tap to see your progress and treatment adherence.';

  @override
  String notificationGroupSummaryTitle(Object petName) {
    return '$petName\'s Reminders';
  }

  @override
  String notificationGroupSummaryMedicationOnly(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count medication reminders',
      one: '1 medication reminder',
    );
    return '$_temp0';
  }

  @override
  String notificationGroupSummaryFluidOnly(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fluid therapy reminders',
      one: '1 fluid therapy reminder',
    );
    return '$_temp0';
  }

  @override
  String notificationGroupSummaryBoth(num fluidCount, num medCount) {
    String _temp0 = intl.Intl.pluralLogic(
      medCount,
      locale: localeName,
      other: '$medCount medications',
      one: '1 medication',
    );
    String _temp1 = intl.Intl.pluralLogic(
      fluidCount,
      locale: localeName,
      other: '$fluidCount fluid therapies',
      one: '1 fluid therapy',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String get notificationActionLogNow => 'Log treatment now';

  @override
  String notificationMultipleTreatmentsTitle(String petName) {
    return 'Treatment reminder for $petName';
  }

  @override
  String notificationMultipleTreatmentsBody(int count) {
    return 'It\'s time for $count treatments';
  }

  @override
  String get notificationMixedTreatmentsBody =>
      'It\'s time for medication and fluid therapy';

  @override
  String notificationMultipleFollowupTitle(String petName) {
    return 'Treatment reminder for $petName';
  }

  @override
  String notificationMultipleFollowupBody(String petName, int count) {
    return '$petName may still need $count treatments';
  }

  @override
  String get notificationAuthRequired =>
      'Please log in to record this treatment';

  @override
  String get notificationScheduleNotFound =>
      'Reminder was for a treatment that\'s no longer scheduled. You can still log other treatments.';

  @override
  String get notificationStatusEnabledTooltip => 'Notifications enabled';

  @override
  String get notificationStatusDisabledTooltip =>
      'Notifications disabled - tap to enable';

  @override
  String get notificationStatusPermanentTooltip =>
      'Notifications disabled - tap to open Settings';

  @override
  String get notificationPermissionDialogTitle => 'Never Miss a Treatment';

  @override
  String notificationPermissionMessageNotDetermined(String petName) {
    return 'Enable notifications to receive timely reminders for $petName\'s medications and fluid therapy. You\'re doing an amazing job caring for your cat - let us help you stay on track.';
  }

  @override
  String notificationPermissionMessageDenied(String petName) {
    return 'Treatment reminders help you provide the best care for $petName. Enable notifications to receive gentle reminders at the right times.';
  }

  @override
  String notificationPermissionMessagePermanent(String petName) {
    return 'To receive treatment reminders for $petName, please enable notifications in your device Settings. This ensures you never miss important medication or fluid therapy times.';
  }

  @override
  String get notificationPermissionMessageGeneric =>
      'Enable notifications to receive treatment reminders.';

  @override
  String get notificationPermissionIosHint =>
      'You can always change this later in your device Settings.';

  @override
  String get notificationPermissionAndroidHint =>
      'This is the only time we\'ll ask - you can enable later in Settings if needed.';

  @override
  String get notificationPermissionAllowButton => 'Allow Notifications';

  @override
  String get notificationPermissionOpenSettingsButton => 'Open Settings';

  @override
  String get notificationPermissionMaybeLaterButton => 'Maybe Later';

  @override
  String get notificationPermissionGrantedSuccess =>
      'Notifications enabled! You\'ll receive treatment reminders.';

  @override
  String get notificationPermissionDeniedFeedback =>
      'Notifications remain disabled. You can enable them anytime in Settings.';

  @override
  String get notificationSettingsTitle => 'Notification Settings';

  @override
  String get notificationSettingsPermissionGranted =>
      'Notification permission granted';

  @override
  String get notificationSettingsPermissionDenied =>
      'Notification permission denied';

  @override
  String get notificationSettingsPermissionBannerMessage =>
      'Notifications are disabled in your device settings. Enable them to receive treatment reminders.';

  @override
  String get notificationSettingsOpenSettingsButton => 'Open Settings';

  @override
  String get notificationSettingsEnableToggleLabel => 'Enable Notifications';

  @override
  String get notificationSettingsWeeklySummaryLabel => 'Weekly Summary';

  @override
  String get notificationSettingsWeeklySummaryDescription =>
      'Get a summary of your treatment adherence every Monday morning';

  @override
  String get notificationSettingsWeeklySummarySuccess =>
      'Weekly summary enabled';

  @override
  String get notificationSettingsWeeklySummaryDisabledSuccess =>
      'Weekly summary disabled';

  @override
  String get notificationSettingsWeeklySummaryError =>
      'Failed to update weekly summary setting. Please try again.';

  @override
  String get notificationSettingsFeatureRequiresMasterToggle =>
      'Enable notifications above to use these features';

  @override
  String get notificationSettingsFeatureRequiresPetProfile =>
      'Please set up your pet profile first to use notification features';

  @override
  String get notificationPrivacyNoticeShort =>
      'We protect your privacy by using generic notification content with no medical details. All notification data is stored locally on your device only.';

  @override
  String get notificationPrivacyLearnMoreButton => 'Learn More';

  @override
  String get notificationPrivacyBottomSheetTitle => 'Notification Privacy';

  @override
  String get notificationPrivacyLoadError =>
      'Unable to load privacy policy. Please try again.';

  @override
  String get notificationSettingsPrivacyPolicyLabel => 'Privacy Policy';

  @override
  String get notificationSettingsPrivacyPolicyDescription =>
      'How we handle notification data';

  @override
  String get notificationSettingsDataManagementTitle => 'Data Management';

  @override
  String get notificationSettingsClearDataButton => 'Clear Notification Data';

  @override
  String get notificationSettingsClearDataDescription =>
      'Cancel all scheduled notifications and clear stored data';

  @override
  String get notificationSettingsClearDataConfirmTitle =>
      'Clear Notification Data?';

  @override
  String get notificationSettingsClearDataConfirmMessage =>
      'This will cancel all scheduled notifications and clear stored notification data. Your notification settings will be preserved.\n\nThis action cannot be undone.';

  @override
  String get notificationSettingsClearDataConfirmButton => 'Clear Data';

  @override
  String notificationSettingsClearDataSuccess(int count) {
    return 'Notification data cleared successfully ($count notifications canceled)';
  }

  @override
  String notificationSettingsClearDataError(String error) {
    return 'Failed to clear notification data: $error';
  }

  @override
  String get notificationPermissionRevokedTitle =>
      'Notification Permission Revoked';

  @override
  String get notificationPermissionRevokedMessage =>
      'We noticed that notification permission was disabled. To continue receiving treatment reminders, please re-enable notifications.';

  @override
  String get notificationPermissionRevokedAction => 'Open Settings';

  @override
  String get notificationInitializationFailedTitle =>
      'Notification Setup Issue';

  @override
  String get notificationInitializationFailedMessage =>
      'We\'re having trouble setting up reminders. You can still log treatments normally. Restart the app to try again.';

  @override
  String get notificationSchedulingFailedToast =>
      'Unable to schedule reminder right now. Don\'t worry - you can still log treatments.';

  @override
  String get notificationReconciliationFailedToast =>
      'Some reminders couldn\'t be restored. Check your notification settings.';

  @override
  String get a11yOn => 'on';

  @override
  String get a11yOff => 'off';

  @override
  String get a11yNotifMasterLabel => 'Enable notifications';

  @override
  String get a11yNotifMasterHint => 'Turns all notification features on or off';

  @override
  String get a11yWeeklySummaryLabel => 'Weekly summary notifications';

  @override
  String get a11yWeeklySummaryHint => 'Sends a summary every Monday at 9 a.m.';

  @override
  String get a11yOpenSystemSettingsLabel => 'Open system notification settings';

  @override
  String get a11yOpenSystemSettingsHint =>
      'Opens the device settings to manage notification permission';

  @override
  String get a11ySettingsHeaderNotifications => 'Notifications';

  @override
  String get a11ySettingsHeaderReminderFeatures => 'Reminder features';

  @override
  String get a11ySettingsHeaderPrivacyAndData => 'Privacy & data';
}
