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
  String get volumeLabel => 'Volume (ml) *';

  @override
  String get volumeHint => '100.0';

  @override
  String get volumeHelperText => 'Typical range: 50-300ml for cats';

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
}
