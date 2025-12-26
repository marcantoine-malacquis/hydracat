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
  String get continueButton => 'Continue';

  @override
  String get close => 'Close';

  @override
  String get exit => 'Exit';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get discard => 'Discard';

  @override
  String get discardChanges => 'Discard Changes?';

  @override
  String get discardChangesMessage =>
      'You have unsaved changes. Are you sure you want to discard them?';

  @override
  String get optional => 'optional';

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
  String get petNameLabel => 'What is your cat\'s name?';

  @override
  String get petNameHint => 'Enter your cat\'s name';

  @override
  String get petDateOfBirthLabel => 'Date of Birth';

  @override
  String get selectDateOfBirth => 'Select date of birth';

  @override
  String get petGenderLabel => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get petBreedLabel => 'Breed';

  @override
  String get petBreedHint => 'Enter breed (optional)';

  @override
  String get petWeightLabel => 'Weight';

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
  String get petNameGenderTitle => 'Pet Information';

  @override
  String get petNameGenderQuestion => 'What is your cat\'s name?';

  @override
  String get petDateOfBirthTitle => 'Date of Birth';

  @override
  String get petDateOfBirthQuestion => 'When was your cat born?';

  @override
  String get petBreedTitle => 'Breed';

  @override
  String get petBreedQuestion => 'What breed is your cat?';

  @override
  String get petWeightTitle => 'Weight';

  @override
  String get petWeightQuestion => 'How much does your cat weigh?';

  @override
  String get medicalInfoTitle => 'Medical Information';

  @override
  String get lastBloodworkResults => 'Last Bloodwork Results';

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
  String get editMedication => 'Edit Medication';

  @override
  String get medicationInformation => 'Medication Information';

  @override
  String get medicationInformationDesc =>
      'Enter the name and dosage form of the medication.';

  @override
  String get whatMedicationToAdd => 'What medication do you want to add?';

  @override
  String get medicationNameLabel => 'Medication Name *';

  @override
  String get medicationNameHint => 'e.g., Benazepril, Epakitin';

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
  String get strengthUnitLabel => 'Strenght unit';

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
  String get unitTypeLabel => 'Dose unit';

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
  String get medicationNameRequired => 'Medication name is required';

  @override
  String get strengthUnitRequired => 'Please select a strength unit';

  @override
  String get customStrengthUnitRequired => 'Please specify the custom unit';

  @override
  String get dosageRequired => 'Dosage is required';

  @override
  String get dosageHint => 'e.g., 1, 1/2, 2.5';

  @override
  String get dosageDescriptionPart1 => 'Enter the ';

  @override
  String get dosageDescriptionPart2 => 'amount per administration';

  @override
  String get dosageDescriptionPart3 => ' and select the medication unit.';

  @override
  String get frequencyDescription =>
      'How often should this medication be given?';

  @override
  String get reminderTimesDescription =>
      'Set the times when you want to be reminded to give this medication.';

  @override
  String reminderTimesIncomplete(int count) {
    return 'Please set all $count reminder times';
  }

  @override
  String get errorSavingMedication =>
      'Failed to save medication. Please check all fields and try again.';

  @override
  String get medicationSearchPlaceholder => 'Search medications...';

  @override
  String get medicationNotInDatabase =>
      'Medication not found? You can still add it manually.';

  @override
  String get medicationSuggestionsTitle => 'Suggested Medications';

  @override
  String get medicationDatabaseLoadError =>
      'Could not load medication database. Manual entry is still available.';

  @override
  String get medicationAutocompleteHint => 'Start typing to see suggestions';

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
  String get noTimeSet => 'No time set';

  @override
  String get setReminder => 'Set reminder';

  @override
  String get setReminderSubtitle => 'Receive notifications at scheduled times';

  @override
  String get noReminderInfo =>
      'This medication will appear in your list but won\'t send notifications. You can log it anytime throughout the day.';

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
  String get progressChartEmptyTitle => 'No data yet for this week';

  @override
  String get progressChartEmptySubtitle =>
      'Log today\'s fluids to see your progress here.';

  @override
  String get progressChartEmptyCta => 'Log fluids';

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
  String medicationUnitPill(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pills',
      one: 'pill',
    );
    return '$_temp0';
  }

  @override
  String medicationUnitSachet(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sachets',
      one: 'Sachet',
    );
    return '$_temp0';
  }

  @override
  String medicationUnitCapsule(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Capsules',
      one: 'Capsule',
    );
    return '$_temp0';
  }

  @override
  String medicationUnitTablet(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tablets',
      one: 'Tablet',
    );
    return '$_temp0';
  }

  @override
  String medicationUnitDrop(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'drops',
      one: 'drop',
    );
    return '$_temp0';
  }

  @override
  String medicationUnitAmpoule(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ampoules',
      one: 'ampoule',
    );
    return '$_temp0';
  }

  @override
  String medicationUnitInjection(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'injections',
      one: 'injection',
    );
    return '$_temp0';
  }

  @override
  String medicationUnitPortion(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'portions',
      one: 'portion',
    );
    return '$_temp0';
  }

  @override
  String get medicationUnitMg => 'mg';

  @override
  String get medicationUnitMl => 'mL';

  @override
  String get medicationUnitMcg => 'mcg';

  @override
  String get medicationUnitTbsp => 'tbsp';

  @override
  String get medicationUnitTsp => 'tsp';

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
  String get medicationLogged => 'Medication logged';

  @override
  String get fluidSessionLogged => 'Fluid session logged';

  @override
  String get loggingCloseTooltip => 'Close';

  @override
  String get loggingClosePopupSemantic => 'Close popup';

  @override
  String loggingPopupSemantic(String title) {
    return '$title popup';
  }

  @override
  String get fluidLoggingTitle => 'Fluid Therapy';

  @override
  String get fluidLogButton => 'Log Fluid Session';

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
  String get fluidStressLevelLabel => 'Session stress';

  @override
  String get fluidLogButtonLabel => 'Log fluid session button';

  @override
  String get fluidLogButtonHint =>
      'Logs fluid therapy session and updates treatment records';

  @override
  String get calculateFromWeight => 'Calculate fluid volume from weight';

  @override
  String get weightCalculatorTitle => 'Fluid Volume Calculator';

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
  String get medicationLoggingTitle => 'Medication';

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
  String get treatmentChoiceTitle => 'What would you like to log?';

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
  String get treatmentChoiceSymptomsLabel => 'Log symptoms';

  @override
  String get treatmentChoiceSymptomsHint =>
      'Opens symptoms logging form to record daily health symptoms';

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
  String get dosageAdjustLink => 'Adjust dose';

  @override
  String get dosageCollapseLink => 'Collapse';

  @override
  String get dosageGivenLabel => 'Dosage given:';

  @override
  String get dosagePresetFull => 'Full';

  @override
  String get dosagePresetHalf => 'Half';

  @override
  String get dosagePresetSkip => 'Skip';

  @override
  String get dosageBadgeMissed => 'Skipped';

  @override
  String dosageBadgePartial(int percent) {
    return '$percent% of scheduled';
  }

  @override
  String dosageBadgeExtra(int percent) {
    return '$percent% of scheduled';
  }

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
  String get injectionSiteLabel => 'Injection site';

  @override
  String get injectionSiteSelectorSemantic => 'Injection site selector';

  @override
  String injectionSiteCurrentSelection(String site) {
    return 'Current selection: $site';
  }

  @override
  String get injectionSiteNoSelection => 'No injection site selected';

  @override
  String get injectionSiteRequired =>
      'Injection site is required for proper rotation tracking';

  @override
  String get injectionSiteShoulderBladeLeft => 'Shoulder blade - left';

  @override
  String get injectionSiteShoulderBladeRight => 'Shoulder blade - right';

  @override
  String get injectionSiteShoulderBladeMiddle => 'Shoulder blade - middle';

  @override
  String get injectionSiteHipBonesLeft => 'Hip bones - left';

  @override
  String get injectionSiteHipBonesRight => 'Hip bones - right';

  @override
  String get injectionSitesAnalyticsTitle => 'Injection Sites';

  @override
  String get injectionSitesRotationPattern => 'Rotation Pattern';

  @override
  String injectionSitesBasedOnSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sessions',
      one: 'session',
    );
    return 'Based on the last $count $_temp0';
  }

  @override
  String get injectionSitesNoSessionsYet => 'No sessions tracked yet';

  @override
  String get injectionSitesErrorLoading => 'Error loading injection site data';

  @override
  String get injectionSitesEmptyStateMessage =>
      'Start tracking injection sites\nto see your rotation pattern';

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
  String get notificationSettingsWeeklySummaryDescription => 'Monday morning';

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

  @override
  String get qolNavigationTitle => 'Quality of Life';

  @override
  String get qolNavigationSubtitle => 'Track your cat\'s wellbeing over time';

  @override
  String get qolDomainVitality => 'Vitality';

  @override
  String get qolDomainVitalityDesc => 'Energy and activity levels';

  @override
  String get qolDomainComfort => 'Comfort';

  @override
  String get qolDomainComfortDesc => 'Physical comfort and mobility';

  @override
  String get qolDomainEmotional => 'Emotional Wellbeing';

  @override
  String get qolDomainEmotionalDesc => 'Mood and social behavior';

  @override
  String get qolDomainAppetite => 'Appetite';

  @override
  String get qolDomainAppetiteDesc => 'Interest in food and eating';

  @override
  String get qolDomainTreatmentBurden => 'Treatment Burden';

  @override
  String get qolDomainTreatmentBurdenDesc => 'Stress from CKD care';

  @override
  String get qolQuestionVitality1 =>
      'In the past 7 days, how would you describe your cat\'s overall energy level compared to their usual self?';

  @override
  String get qolQuestionVitality2 =>
      'In the past 7 days, how often did your cat get up, walk around, or explore on their own instead of staying in one place?';

  @override
  String get qolQuestionVitality3 =>
      'In the past 7 days, how often did your cat show interest in play, toys, or interacting with objects around them?';

  @override
  String get qolQuestionComfort1 =>
      'In the past 7 days, how comfortable did your cat seem when moving, jumping, or changing position?';

  @override
  String get qolQuestionComfort2 =>
      'In the past 7 days, how often did you notice signs like stiffness, limping, or hesitation to jump up or down?';

  @override
  String get qolQuestionComfort3 =>
      'In the past 7 days, did your cat show signs of discomfort when using the litter box (straining, vocalizing, or spending a long time)?';

  @override
  String get qolQuestionEmotional1 =>
      'In the past 7 days, how would you describe your cat\'s overall mood?';

  @override
  String get qolQuestionEmotional2 =>
      'In the past 7 days, how often did your cat seek contact with you (coming to you, asking for attention, or being near you)?';

  @override
  String get qolQuestionEmotional3 =>
      'In the past 7 days, how often did your cat hide away or seem more withdrawn than usual?';

  @override
  String get qolQuestionAppetite1 =>
      'In the past 7 days, how would you describe your cat\'s appetite overall?';

  @override
  String get qolQuestionAppetite2 =>
      'In the past 7 days, how often did your cat finish most of their main meals?';

  @override
  String get qolQuestionAppetite3 =>
      'In the past 7 days, how interested was your cat in treats or favorite foods?';

  @override
  String get qolQuestionTreatment1 =>
      'In the past 7 days, how easy or difficult was it to give your cat their CKD treatments (subcutaneous fluids, pills, liquid medications, etc.)?';

  @override
  String get qolQuestionTreatment2 =>
      'In the past 7 days, how stressed did your cat seem about treatments or being handled for their CKD care?';

  @override
  String get qolVitality1Label0 =>
      'Much lower than usual (very sleepy, hardly active)';

  @override
  String get qolVitality1Label1 => 'Lower than usual (noticeably less active)';

  @override
  String get qolVitality1Label2 => 'About the same as usual';

  @override
  String get qolVitality1Label3 => 'A bit higher than usual';

  @override
  String get qolVitality1Label4 =>
      'Much higher than usual (very lively and active)';

  @override
  String get qolVitality2Label0 =>
      'Almost never (stayed in one place most of the time)';

  @override
  String get qolVitality2Label1 => 'Rarely (only got up a few times each day)';

  @override
  String get qolVitality2Label2 =>
      'Sometimes (mixed between resting and moving)';

  @override
  String get qolVitality2Label3 =>
      'Often (regularly moved around during the day)';

  @override
  String get qolVitality2Label4 =>
      'Very often (frequently exploring or changing spots)';

  @override
  String get qolVitality3Label0 => 'Never (showed no interest at all)';

  @override
  String get qolVitality3Label1 => 'Rarely (once or twice all week)';

  @override
  String get qolVitality3Label2 => 'Sometimes (a few times during the week)';

  @override
  String get qolVitality3Label3 => 'Often (regularly showed interest)';

  @override
  String get qolVitality3Label4 =>
      'Very often (frequently engaged with toys or play)';

  @override
  String get qolComfort1Label0 =>
      'Very uncomfortable (often struggled or seemed in pain)';

  @override
  String get qolComfort1Label1 =>
      'Uncomfortable (noticeable difficulty or stiffness)';

  @override
  String get qolComfort1Label2 =>
      'Somewhat comfortable (a little stiff but mostly coping)';

  @override
  String get qolComfort1Label3 =>
      'Comfortable (moves well with only mild issues)';

  @override
  String get qolComfort1Label4 =>
      'Very comfortable (moves freely with no visible problems)';

  @override
  String get qolComfort2Label0 => 'Every day or almost every day';

  @override
  String get qolComfort2Label1 => 'Several times this week';

  @override
  String get qolComfort2Label2 => 'Once or twice this week';

  @override
  String get qolComfort2Label3 => 'Rarely (only once or twice this month)';

  @override
  String get qolComfort2Label4 => 'Not at all in the past 7 days';

  @override
  String get qolComfort3Label0 =>
      'Very often (showed clear discomfort most times)';

  @override
  String get qolComfort3Label1 =>
      'Often (frequently showed signs of discomfort)';

  @override
  String get qolComfort3Label2 => 'Sometimes (occasional signs of discomfort)';

  @override
  String get qolComfort3Label3 => 'Rarely (only once or twice this week)';

  @override
  String get qolComfort3Label4 =>
      'Not at all (used litter box comfortably all week)';

  @override
  String get qolEmotional1Label0 =>
      'Very low (seemed miserable or very unhappy most of the time)';

  @override
  String get qolEmotional1Label1 => 'Low (often seemed unhappy or dull)';

  @override
  String get qolEmotional1Label2 =>
      'Neutral (neither especially unhappy nor especially happy)';

  @override
  String get qolEmotional1Label3 =>
      'Generally happy (seemed content most of the time)';

  @override
  String get qolEmotional1Label4 =>
      'Very happy (bright, cheerful, and engaged most of the time)';

  @override
  String get qolEmotional2Label0 => 'Never (did not seek contact at all)';

  @override
  String get qolEmotional2Label1 => 'Rarely (once a day or less)';

  @override
  String get qolEmotional2Label2 => 'Sometimes (a few times a day)';

  @override
  String get qolEmotional2Label3 => 'Often (regularly during the day)';

  @override
  String get qolEmotional2Label4 =>
      'Very often (actively seeks you out many times a day)';

  @override
  String get qolEmotional3Label0 =>
      'Much more than usual (hid or stayed away most of the time)';

  @override
  String get qolEmotional3Label1 =>
      'More than usual (clearly hiding or withdrawn)';

  @override
  String get qolEmotional3Label2 => 'About the same as usual';

  @override
  String get qolEmotional3Label3 =>
      'Less than usual (slightly more visible and present)';

  @override
  String get qolEmotional3Label4 =>
      'Much less than usual (very rarely hiding or withdrawn)';

  @override
  String get qolAppetite1Label0 =>
      'Almost no appetite (hardly eating anything)';

  @override
  String get qolAppetite1Label1 =>
      'Very poor appetite (eating much less than usual)';

  @override
  String get qolAppetite1Label2 =>
      'Reduced appetite (eating somewhat less than usual)';

  @override
  String get qolAppetite1Label3 =>
      'Normal appetite (eating about their usual amount)';

  @override
  String get qolAppetite1Label4 =>
      'Very good appetite (keen to eat, may ask for more)';

  @override
  String get qolAppetite2Label0 => 'Almost never (left most of each meal)';

  @override
  String get qolAppetite2Label1 => 'Rarely (finished less than half of meals)';

  @override
  String get qolAppetite2Label2 => 'Sometimes (finished about half of meals)';

  @override
  String get qolAppetite2Label3 => 'Often (finished most meals)';

  @override
  String get qolAppetite2Label4 => 'Almost always (finished nearly every meal)';

  @override
  String get qolAppetite3Label0 =>
      'Not interested at all (refused or ignored them)';

  @override
  String get qolAppetite3Label1 =>
      'Slightly interested (occasionally accepted, often refused)';

  @override
  String get qolAppetite3Label2 =>
      'Moderately interested (accepted some, refused some)';

  @override
  String get qolAppetite3Label3 =>
      'Very interested (usually keen to take them)';

  @override
  String get qolAppetite3Label4 =>
      'Extremely interested (actively asks for or searches for them)';

  @override
  String get qolTreatment1Label0 =>
      'Extremely difficult (usually failed or very stressful for both)';

  @override
  String get qolTreatment1Label1 =>
      'Difficult (needed a lot of effort or caused clear distress)';

  @override
  String get qolTreatment1Label2 =>
      'Manageable (sometimes a struggle but usually possible)';

  @override
  String get qolTreatment1Label3 =>
      'Easy (minor resistance but generally straightforward)';

  @override
  String get qolTreatment1Label4 =>
      'Very easy (your cat accepts treatments calmly)';

  @override
  String get qolTreatment2Label0 =>
      'Extremely stressed (panics, fights, or freezes every time)';

  @override
  String get qolTreatment2Label1 => 'Very stressed (clearly upset most times)';

  @override
  String get qolTreatment2Label2 =>
      'Moderately stressed (shows some stress but copes)';

  @override
  String get qolTreatment2Label3 =>
      'Slightly stressed (a bit tense but settles quickly)';

  @override
  String get qolTreatment2Label4 =>
      'Not at all stressed (relaxed or only minimally bothered)';

  @override
  String get qolRecallPeriod => 'In the past 7 days...';

  @override
  String get qolNotSure => 'Not sure / Unable to observe this week';

  @override
  String get qolRadarChartTitle => 'Quality of Life Profile';

  @override
  String get qolInsufficientData => 'Insufficient data';

  @override
  String get qolIncomplete => 'Incomplete';

  @override
  String get qolHistorySectionTitle => 'Recent Assessments';

  @override
  String get qolNeedMoreData => 'Need at least 2 assessments to see trends';

  @override
  String get qolDomainVitalityShort => 'Vital.';

  @override
  String get qolDomainComfortShort => 'Comf.';

  @override
  String get qolDomainEmotionalShort => 'Emot.';

  @override
  String get qolDomainAppetiteShort => 'Appe.';

  @override
  String get qolDomainTreatmentBurdenShort => 'Treat.';

  @override
  String get qolOverallScore => 'Overall Score';

  @override
  String get qolScoreBandVeryGood => 'Very Good';

  @override
  String get qolScoreBandGood => 'Good';

  @override
  String get qolScoreBandFair => 'Fair';

  @override
  String get qolScoreBandLow => 'Low';

  @override
  String qolBasedOnDomains(int count) {
    return 'Based on $count of 5 domains';
  }

  @override
  String qolQuestionsAnswered(int answered, int total) {
    return '$answered of $total questions answered';
  }

  @override
  String qolAssessedOn(String date) {
    return 'Assessed on $date';
  }

  @override
  String get qolComparedToLast => 'vs. last assessment';

  @override
  String get qolLowConfidenceExplanation =>
      'This domain has less than 50% of questions answered, so the score may not be reliable.';

  @override
  String get qolQuestionnaireTitle => 'QoL Assessment';

  @override
  String get qolQuestionnaireEditTitle => 'Edit Assessment';

  @override
  String get qolHistoryTitle => 'Quality of Life';

  @override
  String get qolTrendChartTitle => 'QoL Trends';

  @override
  String qolQuestionProgress(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get qolComplete => 'Complete';

  @override
  String get qolStartAssessment => 'Start Assessment';

  @override
  String get qolStartFirstAssessment => 'Start First Assessment';

  @override
  String get qolContinue => 'Continue';

  @override
  String get qolSave => 'Save';

  @override
  String get qolDiscardTitle => 'Discard progress?';

  @override
  String qolDiscardMessage(int answered) {
    return 'You\'ve answered $answered of 14 questions. Exit without saving?';
  }

  @override
  String get qolKeepEditing => 'Keep editing';

  @override
  String get qolSaveError => 'Failed to save assessment. Please try again.';

  @override
  String get qolLoadError =>
      'Unable to load assessments. Check your connection.';

  @override
  String get qolResultsTitle => 'QoL Results';

  @override
  String get qolDomainScoresTitle => 'Domain Scores';

  @override
  String get viewHistory => 'View History';

  @override
  String get qolEmptyStateTitle => 'Track Your Cat\'s Quality of Life';

  @override
  String get qolEmptyStateMessage =>
      'Complete assessments weekly to identify trends and share insights with your vet.';

  @override
  String get qolHistoryEmptyMessage =>
      'No assessments yet. Start your first one to begin tracking.';

  @override
  String get qolHomeCardEmptyMessage => 'Track your cat\'s wellbeing over time';

  @override
  String get qolFirstAssessmentMessage =>
      'This is your baseline. Complete another in 7 days to see trends.';

  @override
  String get qolDeleteConfirmTitle => 'Delete Assessment?';

  @override
  String qolDeleteConfirmMessage(String date) {
    return 'This will permanently delete the assessment from $date.';
  }

  @override
  String get qolDeleteSuccess => 'Assessment deleted successfully';

  @override
  String get qolDeleteError => 'Failed to delete assessment. Please try again.';

  @override
  String get qolNeedMoreAssessments =>
      'Complete another assessment to see trends and comparisons.';

  @override
  String get qolInsufficientDataForInterpretation =>
      'Insufficient data to provide trend interpretation. Complete more questions in your next assessment.';

  @override
  String get qolInterpretationStable =>
      'Your cat\'s quality of life has remained stable since the last assessment.';

  @override
  String get qolInterpretationImproving =>
      'Quality of life scores have improved. Great progress!';

  @override
  String get qolInterpretationDeclining =>
      'Quality of life scores are lower than the last assessment. Consider discussing recent changes with your veterinarian.';

  @override
  String get qolInterpretationNotableDropComfort =>
      'Comfort scores have dropped notably. You may want to discuss pain management with your vet.';

  @override
  String get qolInterpretationNotableDropAppetite =>
      'Appetite scores are significantly lower. Monitor eating habits closely and consult your vet.';

  @override
  String get qolInterpretationNotableDropVitality =>
      'Vitality scores have decreased notably. Your cat may be experiencing lower energy levels.';

  @override
  String get qolInterpretationNotableDropEmotional =>
      'Emotional wellbeing scores have dropped significantly. Your cat may be experiencing stress or discomfort.';

  @override
  String get qolInterpretationNotableDropTreatmentBurden =>
      'Treatment burden scores indicate increased stress from CKD care. Consider discussing ways to make treatments easier.';

  @override
  String get qolTrendDisclaimer =>
      'These trends are observational only. Always consult your veterinarian for medical decisions.';

  @override
  String get qolDisclaimer =>
      'This tool tracks quality of life trends over time for your reference. It is not a diagnostic instrument and does not replace veterinary care. Always consult your veterinarian for medical decisions.';

  @override
  String get qolScientificAttribution =>
      'HydraCAT\'s Quality of Life assessment is informed by published psychometric research on feline health-related quality of life, including studies by Bijsmans et al. (2016), Lorbach et al. (2022), and Wright et al. (2025). This tool is independently developed and is not affiliated with or endorsed by the authors of these studies.';
}
