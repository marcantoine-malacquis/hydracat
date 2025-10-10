import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The application name
  ///
  /// In en, this message translates to:
  /// **'HydraCat'**
  String get appName;

  /// Description of the application
  ///
  /// In en, this message translates to:
  /// **'Hydration tracking for cats with kidney disease'**
  String get appDescription;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get saveAndContinue;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for Now'**
  String get skipForNow;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @continue_.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// No description provided for @finishingSetup.
  ///
  /// In en, this message translates to:
  /// **'Finishing setup...'**
  String get finishingSetup;

  /// Title shown on welcome screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to HydraCat'**
  String get welcomeTitle;

  /// Subtitle on welcome screen
  ///
  /// In en, this message translates to:
  /// **'Managing chronic kidney disease can feel overwhelming, but you\'re not alone. HydraCat helps you track treatments, monitor progress, and stay connected with your vet.'**
  String get welcomeSubtitle;

  /// Secondary welcome message
  ///
  /// In en, this message translates to:
  /// **'Your CKD Journey Starts Here'**
  String get yourCkdJourneyStartsHere;

  /// No description provided for @failedToSkipOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Failed to skip onboarding. Please try again.'**
  String get failedToSkipOnboarding;

  /// Title for user persona selection screen
  ///
  /// In en, this message translates to:
  /// **'How do you manage your pet\'s CKD?'**
  String get userPersonaTitle;

  /// Subtitle for user persona selection screen
  ///
  /// In en, this message translates to:
  /// **'Choose the approach that best matches your current treatment plan.'**
  String get userPersonaSubtitle;

  /// Title for pet basics screen
  ///
  /// In en, this message translates to:
  /// **'Tell us about your cat'**
  String get petBasicsTitle;

  /// No description provided for @petNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Pet Name *'**
  String get petNameLabel;

  /// No description provided for @petNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your cat\'s name'**
  String get petNameHint;

  /// No description provided for @petDateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth *'**
  String get petDateOfBirthLabel;

  /// No description provided for @selectDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Select date of birth'**
  String get selectDateOfBirth;

  /// No description provided for @petGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender *'**
  String get petGenderLabel;

  /// No description provided for @petBreedLabel.
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get petBreedLabel;

  /// No description provided for @petBreedHint.
  ///
  /// In en, this message translates to:
  /// **'Enter breed (optional)'**
  String get petBreedHint;

  /// Error message when saving pet information fails
  ///
  /// In en, this message translates to:
  /// **'Error saving pet information: {error}'**
  String errorSavingPetInfo(String error);

  /// Error message when gender is not selected
  ///
  /// In en, this message translates to:
  /// **'Please select your cat\'s gender'**
  String get petGenderRequired;

  /// Error message when gender value is invalid
  ///
  /// In en, this message translates to:
  /// **'Gender must be either male or female'**
  String get petGenderInvalid;

  /// Error message when pet name is not provided
  ///
  /// In en, this message translates to:
  /// **'Pet name is required'**
  String get petNameRequired;

  /// Error message when pet name exceeds maximum length
  ///
  /// In en, this message translates to:
  /// **'Pet name must be 50 characters or less'**
  String get petNameTooLong;

  /// Error message when pet age is not provided
  ///
  /// In en, this message translates to:
  /// **'Pet age is required'**
  String get petAgeRequired;

  /// Error message when pet age is invalid
  ///
  /// In en, this message translates to:
  /// **'Pet age must be greater than 0'**
  String get petAgeInvalid;

  /// Error message when pet age seems too high
  ///
  /// In en, this message translates to:
  /// **'Pet age seems unrealistic (over 25 years)'**
  String get petAgeUnrealistic;

  /// Error message when weight is invalid
  ///
  /// In en, this message translates to:
  /// **'Weight must be greater than 0'**
  String get petWeightInvalid;

  /// Error message when weight seems too high for a cat
  ///
  /// In en, this message translates to:
  /// **'Weight seems unrealistic (over 15kg for a cat)'**
  String get petWeightUnrealistic;

  /// No description provided for @medicalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical Information'**
  String get medicalInfoTitle;

  /// No description provided for @lastBloodworkResults.
  ///
  /// In en, this message translates to:
  /// **'Last Bloodwork Results'**
  String get lastBloodworkResults;

  /// No description provided for @lastCheckupDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Checkup Date'**
  String get lastCheckupDateLabel;

  /// No description provided for @selectLastCheckupDate.
  ///
  /// In en, this message translates to:
  /// **'Select last checkup date (optional)'**
  String get selectLastCheckupDate;

  /// No description provided for @bloodworkDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Bloodwork Date'**
  String get bloodworkDateLabel;

  /// No description provided for @selectBloodworkDate.
  ///
  /// In en, this message translates to:
  /// **'Select bloodwork date'**
  String get selectBloodworkDate;

  /// No description provided for @bunLabel.
  ///
  /// In en, this message translates to:
  /// **'BUN (Blood Urea Nitrogen)'**
  String get bunLabel;

  /// No description provided for @creatinineLabel.
  ///
  /// In en, this message translates to:
  /// **'Creatinine'**
  String get creatinineLabel;

  /// No description provided for @phosphorusLabel.
  ///
  /// In en, this message translates to:
  /// **'Phosphorus'**
  String get phosphorusLabel;

  /// No description provided for @skipMedicalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip Medical Information?'**
  String get skipMedicalInfoTitle;

  /// No description provided for @skipMedicalInfoMessage.
  ///
  /// In en, this message translates to:
  /// **'You can add this information later from your pet\'s profile.'**
  String get skipMedicalInfoMessage;

  /// Error message when saving medical information fails
  ///
  /// In en, this message translates to:
  /// **'Error saving medical information: {error}'**
  String errorSavingMedicalInfo(String error);

  /// No description provided for @treatmentSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Treatment Setup'**
  String get treatmentSetupTitle;

  /// No description provided for @setUpYourMedications.
  ///
  /// In en, this message translates to:
  /// **'Set up your medications'**
  String get setUpYourMedications;

  /// No description provided for @setUpYourFluidTherapy.
  ///
  /// In en, this message translates to:
  /// **'Set up your fluid therapy'**
  String get setUpYourFluidTherapy;

  /// No description provided for @medicationSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Medication Setup'**
  String get medicationSetupTitle;

  /// No description provided for @addMedicationDetails.
  ///
  /// In en, this message translates to:
  /// **'Add Medication Details'**
  String get addMedicationDetails;

  /// No description provided for @editMedicationDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Medication Details'**
  String get editMedicationDetails;

  /// No description provided for @addMedication.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedication;

  /// No description provided for @medicationInformation.
  ///
  /// In en, this message translates to:
  /// **'Medication Information'**
  String get medicationInformation;

  /// No description provided for @medicationInformationDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter the name and dosage form of the medication.'**
  String get medicationInformationDesc;

  /// No description provided for @medicationNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Medication Name *'**
  String get medicationNameLabel;

  /// No description provided for @medicationNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Benazepril, Furosemide'**
  String get medicationNameHint;

  /// No description provided for @medicationStrengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Medication Strength (optional)'**
  String get medicationStrengthLabel;

  /// No description provided for @medicationStrengthDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter the concentration or strength of the medication'**
  String get medicationStrengthDesc;

  /// No description provided for @strengthAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get strengthAmountLabel;

  /// No description provided for @strengthAmountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 2.5, 1/2, 10'**
  String get strengthAmountHint;

  /// No description provided for @strengthUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get strengthUnitLabel;

  /// No description provided for @customStrengthUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom Unit'**
  String get customStrengthUnitLabel;

  /// No description provided for @customStrengthUnitHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., mg/kg'**
  String get customStrengthUnitHint;

  /// No description provided for @strengthHelperText.
  ///
  /// In en, this message translates to:
  /// **'e.g., 2.5 mg, 5 mg/mL'**
  String get strengthHelperText;

  /// No description provided for @dosageLabel.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosageLabel;

  /// No description provided for @setDosage.
  ///
  /// In en, this message translates to:
  /// **'Set Dosage'**
  String get setDosage;

  /// No description provided for @dosageAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Required: amount per administration'**
  String get dosageAmountRequired;

  /// No description provided for @unitTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit Type *'**
  String get unitTypeLabel;

  /// No description provided for @frequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequencyLabel;

  /// No description provided for @setFrequency.
  ///
  /// In en, this message translates to:
  /// **'Set Frequency'**
  String get setFrequency;

  /// No description provided for @administrationFrequency.
  ///
  /// In en, this message translates to:
  /// **'Administration Frequency'**
  String get administrationFrequency;

  /// No description provided for @reminderTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder Times'**
  String get reminderTimesTitle;

  /// No description provided for @setReminderTimes.
  ///
  /// In en, this message translates to:
  /// **'Set Reminder Times'**
  String get setReminderTimes;

  /// No description provided for @editMedicationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit medication'**
  String get editMedicationTooltip;

  /// No description provided for @deleteMedicationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete medication'**
  String get deleteMedicationTooltip;

  /// No description provided for @deleteMedicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Medication'**
  String get deleteMedicationTitle;

  /// No description provided for @deleteMedicationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this medication?'**
  String get deleteMedicationMessage;

  /// Error message when saving medication fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save medication: {error}'**
  String failedToSaveMedication(String error);

  /// Error message when saving progress fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save progress: {error}'**
  String failedToSaveProgress(String error);

  /// No description provided for @saveMedication.
  ///
  /// In en, this message translates to:
  /// **'Save Medication'**
  String get saveMedication;

  /// No description provided for @fluidTherapySetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Fluid Therapy Setup'**
  String get fluidTherapySetupTitle;

  /// No description provided for @volumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume (ml) *'**
  String get volumeLabel;

  /// No description provided for @volumeHint.
  ///
  /// In en, this message translates to:
  /// **'100.0'**
  String get volumeHint;

  /// No description provided for @volumeHelperText.
  ///
  /// In en, this message translates to:
  /// **'Typical range: 50-300ml for cats'**
  String get volumeHelperText;

  /// No description provided for @preferredLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred Administration Location'**
  String get preferredLocationLabel;

  /// No description provided for @needleGaugeLabel.
  ///
  /// In en, this message translates to:
  /// **'Needle Gauge *'**
  String get needleGaugeLabel;

  /// No description provided for @needleGaugeHint.
  ///
  /// In en, this message translates to:
  /// **'20G, 22G, 25G'**
  String get needleGaugeHint;

  /// Error message when saving fluid therapy setup fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save fluid therapy setup: {error}'**
  String failedToSaveFluidTherapy(String error);

  /// No description provided for @onboardingCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re All Set!'**
  String get onboardingCompleteTitle;

  /// Message shown on completion screen
  ///
  /// In en, this message translates to:
  /// **'Ready to start tracking {petName}\'s care journey'**
  String readyToStartTracking(String petName);

  /// No description provided for @dailyTime.
  ///
  /// In en, this message translates to:
  /// **'Daily time'**
  String get dailyTime;

  /// No description provided for @firstIntake.
  ///
  /// In en, this message translates to:
  /// **'First intake'**
  String get firstIntake;

  /// No description provided for @secondIntake.
  ///
  /// In en, this message translates to:
  /// **'Second intake'**
  String get secondIntake;

  /// No description provided for @thirdIntake.
  ///
  /// In en, this message translates to:
  /// **'Third intake'**
  String get thirdIntake;

  /// Label for time picker when there are more than 3 times
  ///
  /// In en, this message translates to:
  /// **'Time {number}'**
  String timeNumber(int number);

  /// No description provided for @reminderTimesLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder Times'**
  String get reminderTimesLabel;

  /// No description provided for @frequencyOnceDaily.
  ///
  /// In en, this message translates to:
  /// **'Set a time for the daily administration'**
  String get frequencyOnceDaily;

  /// No description provided for @frequencyTwiceDaily.
  ///
  /// In en, this message translates to:
  /// **'Set times for morning and evening administration (12 hours apart recommended)'**
  String get frequencyTwiceDaily;

  /// No description provided for @frequencyThreeTimesDaily.
  ///
  /// In en, this message translates to:
  /// **'Set times for morning, afternoon, and evening administration (8 hours apart recommended)'**
  String get frequencyThreeTimesDaily;

  /// No description provided for @frequencyEveryOtherDay.
  ///
  /// In en, this message translates to:
  /// **'Set a preferred time for every-other-day administration'**
  String get frequencyEveryOtherDay;

  /// No description provided for @frequencyAsNeeded.
  ///
  /// In en, this message translates to:
  /// **'No fixed schedule - you\'ll log when administered'**
  String get frequencyAsNeeded;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logging.
  ///
  /// In en, this message translates to:
  /// **'Session Logging'**
  String get logging;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress & Analytics'**
  String get progress;

  /// No description provided for @resources.
  ///
  /// In en, this message translates to:
  /// **'Resources & Tips'**
  String get resources;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @hydrationSession.
  ///
  /// In en, this message translates to:
  /// **'Hydration Session'**
  String get hydrationSession;

  /// No description provided for @fluidIntake.
  ///
  /// In en, this message translates to:
  /// **'Fluid Intake'**
  String get fluidIntake;

  /// No description provided for @sessionDuration.
  ///
  /// In en, this message translates to:
  /// **'Session Duration'**
  String get sessionDuration;

  /// No description provided for @startSession.
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get startSession;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End Session'**
  String get endSession;

  /// No description provided for @sessionNotes.
  ///
  /// In en, this message translates to:
  /// **'Session Notes'**
  String get sessionNotes;

  /// No description provided for @catName.
  ///
  /// In en, this message translates to:
  /// **'Cat Name'**
  String get catName;

  /// No description provided for @catAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get catAge;

  /// No description provided for @catWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get catWeight;

  /// No description provided for @catBreed.
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get catBreed;

  /// No description provided for @medicalNotes.
  ///
  /// In en, this message translates to:
  /// **'Medical Notes'**
  String get medicalNotes;

  /// No description provided for @milliliters.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get milliliters;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutes;

  /// No description provided for @kilograms.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kilograms;

  /// No description provided for @pounds.
  ///
  /// In en, this message translates to:
  /// **'lbs'**
  String get pounds;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @enterCatName.
  ///
  /// In en, this message translates to:
  /// **'Enter cat name'**
  String get enterCatName;

  /// No description provided for @enterWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter weight'**
  String get enterWeight;

  /// No description provided for @enterAge.
  ///
  /// In en, this message translates to:
  /// **'Enter age'**
  String get enterAge;

  /// No description provided for @addNotes.
  ///
  /// In en, this message translates to:
  /// **'Add notes...'**
  String get addNotes;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
