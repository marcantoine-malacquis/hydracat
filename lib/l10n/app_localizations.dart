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

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes?'**
  String get discardChanges;

  /// No description provided for @discardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to discard them?'**
  String get discardChangesMessage;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

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
  /// **'What is your cat\'s name?'**
  String get petNameLabel;

  /// No description provided for @petNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your cat\'s name'**
  String get petNameHint;

  /// No description provided for @petDateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get petDateOfBirthLabel;

  /// No description provided for @selectDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Select date of birth'**
  String get selectDateOfBirth;

  /// No description provided for @petGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get petGenderLabel;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

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

  /// No description provided for @petWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get petWeightLabel;

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

  /// Title for pet name and gender screen
  ///
  /// In en, this message translates to:
  /// **'Pet Information'**
  String get petNameGenderTitle;

  /// Main question on pet name and gender screen
  ///
  /// In en, this message translates to:
  /// **'What is your cat\'s name?'**
  String get petNameGenderQuestion;

  /// Title for pet date of birth screen
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get petDateOfBirthTitle;

  /// Main question on pet date of birth screen
  ///
  /// In en, this message translates to:
  /// **'When was your cat born?'**
  String get petDateOfBirthQuestion;

  /// Title for pet breed screen
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get petBreedTitle;

  /// Main question on pet breed screen
  ///
  /// In en, this message translates to:
  /// **'What breed is your cat?'**
  String get petBreedQuestion;

  /// Title for pet weight screen
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get petWeightTitle;

  /// Main question on pet weight screen
  ///
  /// In en, this message translates to:
  /// **'How much does your cat weigh?'**
  String get petWeightQuestion;

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

  /// No description provided for @editMedication.
  ///
  /// In en, this message translates to:
  /// **'Edit Medication'**
  String get editMedication;

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

  /// No description provided for @whatMedicationToAdd.
  ///
  /// In en, this message translates to:
  /// **'What medication do you want to add?'**
  String get whatMedicationToAdd;

  /// No description provided for @medicationNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Medication Name *'**
  String get medicationNameLabel;

  /// No description provided for @medicationNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Benazepril, Epakitin'**
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
  /// **'Strenght unit'**
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
  /// **'Dose unit'**
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

  /// No description provided for @medicationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Medication name is required'**
  String get medicationNameRequired;

  /// No description provided for @strengthUnitRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a strength unit'**
  String get strengthUnitRequired;

  /// No description provided for @customStrengthUnitRequired.
  ///
  /// In en, this message translates to:
  /// **'Please specify the custom unit'**
  String get customStrengthUnitRequired;

  /// No description provided for @dosageRequired.
  ///
  /// In en, this message translates to:
  /// **'Dosage is required'**
  String get dosageRequired;

  /// No description provided for @dosageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 1, 1/2, 2.5'**
  String get dosageHint;

  /// No description provided for @dosageDescriptionPart1.
  ///
  /// In en, this message translates to:
  /// **'Enter the '**
  String get dosageDescriptionPart1;

  /// No description provided for @dosageDescriptionPart2.
  ///
  /// In en, this message translates to:
  /// **'amount per administration'**
  String get dosageDescriptionPart2;

  /// No description provided for @dosageDescriptionPart3.
  ///
  /// In en, this message translates to:
  /// **' and select the medication unit.'**
  String get dosageDescriptionPart3;

  /// No description provided for @frequencyDescription.
  ///
  /// In en, this message translates to:
  /// **'How often should this medication be given?'**
  String get frequencyDescription;

  /// No description provided for @reminderTimesDescription.
  ///
  /// In en, this message translates to:
  /// **'Set the times when you want to be reminded to give this medication.'**
  String get reminderTimesDescription;

  /// Error when not all reminder times are set
  ///
  /// In en, this message translates to:
  /// **'Please set all {count} reminder times'**
  String reminderTimesIncomplete(int count);

  /// No description provided for @errorSavingMedication.
  ///
  /// In en, this message translates to:
  /// **'Failed to save medication. Please check all fields and try again.'**
  String get errorSavingMedication;

  /// Placeholder text for medication search field
  ///
  /// In en, this message translates to:
  /// **'Search medications...'**
  String get medicationSearchPlaceholder;

  /// Info message when medication not in database
  ///
  /// In en, this message translates to:
  /// **'Medication not found? You can still add it manually.'**
  String get medicationNotInDatabase;

  /// Title for medication suggestions dropdown
  ///
  /// In en, this message translates to:
  /// **'Suggested Medications'**
  String get medicationSuggestionsTitle;

  /// Error message when database fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load medication database. Manual entry is still available.'**
  String get medicationDatabaseLoadError;

  /// Hint text for autocomplete field
  ///
  /// In en, this message translates to:
  /// **'Start typing to see suggestions'**
  String get medicationAutocompleteHint;

  /// No description provided for @fluidTherapySetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Fluid Therapy Setup'**
  String get fluidTherapySetupTitle;

  /// No description provided for @volumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume per session (mL) *'**
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

  /// No description provided for @totalPlannedToday.
  ///
  /// In en, this message translates to:
  /// **'Total planned today: {volume} mL'**
  String totalPlannedToday(int volume);

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

  /// Displayed when a medication has no specific reminder time
  ///
  /// In en, this message translates to:
  /// **'No time set'**
  String get noTimeSet;

  /// Toggle label to enable/disable reminder times
  ///
  /// In en, this message translates to:
  /// **'Set reminder'**
  String get setReminder;

  /// Subtitle for set reminder toggle explaining what it does
  ///
  /// In en, this message translates to:
  /// **'Receive notifications at scheduled times'**
  String get setReminderSubtitle;

  /// Info message shown when reminder is disabled
  ///
  /// In en, this message translates to:
  /// **'This medication will appear in your list but won\'t send notifications. You can log it anytime throughout the day.'**
  String get noReminderInfo;

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

  /// Title shown in empty state when no fluid data exists for the focused week
  ///
  /// In en, this message translates to:
  /// **'No data yet for this week'**
  String get progressChartEmptyTitle;

  /// Subtitle shown in empty state explaining how to populate the chart
  ///
  /// In en, this message translates to:
  /// **'Log today\'s fluids to see your progress here.'**
  String get progressChartEmptySubtitle;

  /// Button text to navigate to fluid logging screen from empty chart state
  ///
  /// In en, this message translates to:
  /// **'Log fluids'**
  String get progressChartEmptyCta;

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

  /// Plural-aware medication unit for pills
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{pill} other{pills}}'**
  String medicationUnitPill(num count);

  /// Plural-aware medication unit for sachets
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Sachet} other{Sachets}}'**
  String medicationUnitSachet(num count);

  /// Plural-aware medication unit for capsules
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Capsule} other{Capsules}}'**
  String medicationUnitCapsule(num count);

  /// Plural-aware medication unit for tablets
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Tablet} other{Tablets}}'**
  String medicationUnitTablet(num count);

  /// Plural-aware medication unit for drops
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{drop} other{drops}}'**
  String medicationUnitDrop(num count);

  /// Plural-aware medication unit for ampoules
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{ampoule} other{ampoules}}'**
  String medicationUnitAmpoule(num count);

  /// Plural-aware medication unit for injections
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{injection} other{injections}}'**
  String medicationUnitInjection(num count);

  /// Plural-aware medication unit for portions
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{portion} other{portions}}'**
  String medicationUnitPortion(num count);

  /// Non-countable medication unit for milligrams
  ///
  /// In en, this message translates to:
  /// **'mg'**
  String get medicationUnitMg;

  /// Non-countable medication unit for milliliters
  ///
  /// In en, this message translates to:
  /// **'mL'**
  String get medicationUnitMl;

  /// Non-countable medication unit for micrograms
  ///
  /// In en, this message translates to:
  /// **'mcg'**
  String get medicationUnitMcg;

  /// Non-countable medication unit for tablespoon
  ///
  /// In en, this message translates to:
  /// **'tbsp'**
  String get medicationUnitTbsp;

  /// Non-countable medication unit for teaspoon
  ///
  /// In en, this message translates to:
  /// **'tsp'**
  String get medicationUnitTsp;

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

  /// No description provided for @loggingNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get loggingNotesLabel;

  /// No description provided for @loggingNotesHintSession.
  ///
  /// In en, this message translates to:
  /// **'Add any notes about this session...'**
  String get loggingNotesHintSession;

  /// No description provided for @loggingNotesHintTreatment.
  ///
  /// In en, this message translates to:
  /// **'Add any notes about this treatment...'**
  String get loggingNotesHintTreatment;

  /// No description provided for @loggingUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User or pet not found. Please try again.'**
  String get loggingUserNotFound;

  /// No description provided for @medicationLogged.
  ///
  /// In en, this message translates to:
  /// **'Medication logged'**
  String get medicationLogged;

  /// No description provided for @fluidSessionLogged.
  ///
  /// In en, this message translates to:
  /// **'Fluid session logged'**
  String get fluidSessionLogged;

  /// No description provided for @loggingCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get loggingCloseTooltip;

  /// No description provided for @loggingClosePopupSemantic.
  ///
  /// In en, this message translates to:
  /// **'Close popup'**
  String get loggingClosePopupSemantic;

  /// No description provided for @loggingPopupSemantic.
  ///
  /// In en, this message translates to:
  /// **'{title} popup'**
  String loggingPopupSemantic(String title);

  /// No description provided for @fluidLoggingTitle.
  ///
  /// In en, this message translates to:
  /// **'Fluid Therapy'**
  String get fluidLoggingTitle;

  /// No description provided for @fluidLogButton.
  ///
  /// In en, this message translates to:
  /// **'Log Fluid Session'**
  String get fluidLogButton;

  /// No description provided for @fluidLoggingLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Logging fluid session'**
  String get fluidLoggingLoadingMessage;

  /// No description provided for @fluidVolumeRequired.
  ///
  /// In en, this message translates to:
  /// **'Volume is required'**
  String get fluidVolumeRequired;

  /// No description provided for @fluidVolumeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get fluidVolumeInvalid;

  /// No description provided for @fluidVolumeMin.
  ///
  /// In en, this message translates to:
  /// **'Volume must be at least 1ml'**
  String get fluidVolumeMin;

  /// No description provided for @fluidVolumeMax.
  ///
  /// In en, this message translates to:
  /// **'Volume must be 500ml or less'**
  String get fluidVolumeMax;

  /// No description provided for @fluidAlreadyLoggedToday.
  ///
  /// In en, this message translates to:
  /// **'{volume}mL already logged today'**
  String fluidAlreadyLoggedToday(int volume);

  /// No description provided for @fluidStressLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Session stress'**
  String get fluidStressLevelLabel;

  /// No description provided for @fluidLogButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Log fluid session button'**
  String get fluidLogButtonLabel;

  /// No description provided for @fluidLogButtonHint.
  ///
  /// In en, this message translates to:
  /// **'Logs fluid therapy session and updates treatment records'**
  String get fluidLogButtonHint;

  /// No description provided for @calculateFromWeight.
  ///
  /// In en, this message translates to:
  /// **'Calculate fluid volume from weight'**
  String get calculateFromWeight;

  /// No description provided for @weightCalculatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Fluid Volume Calculator'**
  String get weightCalculatorTitle;

  /// No description provided for @continueFromSameBag.
  ///
  /// In en, this message translates to:
  /// **'Continue from same bag?'**
  String get continueFromSameBag;

  /// No description provided for @useThisWeight.
  ///
  /// In en, this message translates to:
  /// **'Use This Weight'**
  String get useThisWeight;

  /// No description provided for @beforeFluidTherapy.
  ///
  /// In en, this message translates to:
  /// **'Before fluid therapy:'**
  String get beforeFluidTherapy;

  /// No description provided for @initialWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Initial weight'**
  String get initialWeightLabel;

  /// No description provided for @afterFluidTherapy.
  ///
  /// In en, this message translates to:
  /// **'After fluid therapy:'**
  String get afterFluidTherapy;

  /// No description provided for @finalWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Final weight'**
  String get finalWeightLabel;

  /// No description provided for @fluidAdministered.
  ///
  /// In en, this message translates to:
  /// **'Fluid administered: ~{volume} mL'**
  String fluidAdministered(String volume);

  /// No description provided for @ringersDensityNote.
  ///
  /// In en, this message translates to:
  /// **'(1g Ringer\'s ≈ 1mL)'**
  String get ringersDensityNote;

  /// No description provided for @importantTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Important tips:'**
  String get importantTipsTitle;

  /// No description provided for @weightTip1.
  ///
  /// In en, this message translates to:
  /// **'Weigh same components both times'**
  String get weightTip1;

  /// No description provided for @weightTip2.
  ///
  /// In en, this message translates to:
  /// **'Use stable surface & calibrate scale'**
  String get weightTip2;

  /// No description provided for @useThisVolume.
  ///
  /// In en, this message translates to:
  /// **'Use This Volume'**
  String get useThisVolume;

  /// No description provided for @remainingWeight.
  ///
  /// In en, this message translates to:
  /// **'{weight}g remaining'**
  String remainingWeight(String weight);

  /// No description provided for @lastUsedDate.
  ///
  /// In en, this message translates to:
  /// **'Last used {date}'**
  String lastUsedDate(String date);

  /// No description provided for @medicationLoggingTitle.
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get medicationLoggingTitle;

  /// No description provided for @medicationLoggingLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Logging medication session'**
  String get medicationLoggingLoadingMessage;

  /// No description provided for @medicationSelectLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Medications:'**
  String get medicationSelectLabel;

  /// No description provided for @medicationSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get medicationSelectAll;

  /// No description provided for @medicationDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get medicationDeselectAll;

  /// No description provided for @medicationNoneScheduled.
  ///
  /// In en, this message translates to:
  /// **'No medications scheduled for today'**
  String get medicationNoneScheduled;

  /// No description provided for @medicationLogButton.
  ///
  /// In en, this message translates to:
  /// **'Log Medication'**
  String get medicationLogButton;

  /// No description provided for @medicationLogButtonMultiple.
  ///
  /// In en, this message translates to:
  /// **'Log {count} Medications'**
  String medicationLogButtonMultiple(int count);

  /// No description provided for @medicationLogButtonSemanticSingle.
  ///
  /// In en, this message translates to:
  /// **'Logs 1 selected medication and updates treatment records'**
  String get medicationLogButtonSemanticSingle;

  /// No description provided for @medicationLogButtonSemanticMultiple.
  ///
  /// In en, this message translates to:
  /// **'Logs {count} selected medications and updates treatment records'**
  String medicationLogButtonSemanticMultiple(int count);

  /// No description provided for @treatmentChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to log?'**
  String get treatmentChoiceTitle;

  /// No description provided for @treatmentChoiceMedicationLabel.
  ///
  /// In en, this message translates to:
  /// **'Log medication'**
  String get treatmentChoiceMedicationLabel;

  /// No description provided for @treatmentChoiceMedicationHint.
  ///
  /// In en, this message translates to:
  /// **'Opens medication logging form to record treatment'**
  String get treatmentChoiceMedicationHint;

  /// No description provided for @treatmentChoiceFluidLabel.
  ///
  /// In en, this message translates to:
  /// **'Log fluid therapy'**
  String get treatmentChoiceFluidLabel;

  /// No description provided for @treatmentChoiceFluidHint.
  ///
  /// In en, this message translates to:
  /// **'Opens fluid therapy logging form to record subcutaneous fluids'**
  String get treatmentChoiceFluidHint;

  /// No description provided for @treatmentChoiceSymptomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Log symptoms'**
  String get treatmentChoiceSymptomsLabel;

  /// No description provided for @treatmentChoiceSymptomsHint.
  ///
  /// In en, this message translates to:
  /// **'Opens symptoms logging form to record daily health symptoms'**
  String get treatmentChoiceSymptomsHint;

  /// No description provided for @treatmentChoiceSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose treatment type to log'**
  String get treatmentChoiceSemanticLabel;

  /// No description provided for @treatmentChoiceCancelSemantic.
  ///
  /// In en, this message translates to:
  /// **'Closes treatment selection without logging'**
  String get treatmentChoiceCancelSemantic;

  /// No description provided for @duplicateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Already Logged'**
  String get duplicateDialogTitle;

  /// No description provided for @duplicateDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'You already logged {medication} at {time}.'**
  String duplicateDialogMessage(String medication, String time);

  /// No description provided for @duplicateDialogCurrentSession.
  ///
  /// In en, this message translates to:
  /// **'Current Session'**
  String get duplicateDialogCurrentSession;

  /// No description provided for @duplicateDialogNewEntry.
  ///
  /// In en, this message translates to:
  /// **'Your New Entry'**
  String get duplicateDialogNewEntry;

  /// No description provided for @duplicateDialogSummaryWarning.
  ///
  /// In en, this message translates to:
  /// **'Your treatment records will be updated to reflect the new values.'**
  String get duplicateDialogSummaryWarning;

  /// No description provided for @duplicateDialogCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get duplicateDialogCreateNew;

  /// No description provided for @duplicateDialogCreateNewMessage.
  ///
  /// In en, this message translates to:
  /// **'Creating duplicate sessions will be available soon'**
  String get duplicateDialogCreateNewMessage;

  /// No description provided for @duplicateDialogUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get duplicateDialogUpdate;

  /// No description provided for @duplicateDialogUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'Update feature coming soon'**
  String get duplicateDialogUpdateMessage;

  /// No description provided for @duplicateDialogLoggedAt.
  ///
  /// In en, this message translates to:
  /// **'Logged at {time}'**
  String duplicateDialogLoggedAt(String time);

  /// No description provided for @duplicateDialogDosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get duplicateDialogDosage;

  /// No description provided for @duplicateDialogStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get duplicateDialogStatus;

  /// No description provided for @duplicateDialogStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get duplicateDialogStatusCompleted;

  /// No description provided for @duplicateDialogStatusNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get duplicateDialogStatusNotCompleted;

  /// No description provided for @duplicateDialogNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get duplicateDialogNotes;

  /// No description provided for @duplicateDialogNoNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get duplicateDialogNoNotes;

  /// No description provided for @dosageAdjustLink.
  ///
  /// In en, this message translates to:
  /// **'Adjust dose'**
  String get dosageAdjustLink;

  /// No description provided for @dosageCollapseLink.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get dosageCollapseLink;

  /// No description provided for @dosageGivenLabel.
  ///
  /// In en, this message translates to:
  /// **'Dosage given:'**
  String get dosageGivenLabel;

  /// No description provided for @dosagePresetFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get dosagePresetFull;

  /// No description provided for @dosagePresetHalf.
  ///
  /// In en, this message translates to:
  /// **'Half'**
  String get dosagePresetHalf;

  /// No description provided for @dosagePresetSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get dosagePresetSkip;

  /// No description provided for @dosageBadgeMissed.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get dosageBadgeMissed;

  /// No description provided for @dosageBadgePartial.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of scheduled'**
  String dosageBadgePartial(int percent);

  /// No description provided for @dosageBadgeExtra.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of scheduled'**
  String dosageBadgeExtra(int percent);

  /// No description provided for @quickLogTreatmentSingular.
  ///
  /// In en, this message translates to:
  /// **'treatment'**
  String get quickLogTreatmentSingular;

  /// No description provided for @quickLogTreatmentPlural.
  ///
  /// In en, this message translates to:
  /// **'treatments'**
  String get quickLogTreatmentPlural;

  /// No description provided for @quickLogSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count} {treatment} logged for {petName} ✓'**
  String quickLogSuccess(int count, String treatment, String petName);

  /// No description provided for @quickLogSuccessSemantic.
  ///
  /// In en, this message translates to:
  /// **'{count} {treatment} logged for {petName}'**
  String quickLogSuccessSemantic(int count, String treatment, String petName);

  /// No description provided for @quickLogSuccessHint.
  ///
  /// In en, this message translates to:
  /// **'Success. Tap anywhere to dismiss.'**
  String get quickLogSuccessHint;

  /// No description provided for @injectionSiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Injection site'**
  String get injectionSiteLabel;

  /// No description provided for @injectionSiteSelectorSemantic.
  ///
  /// In en, this message translates to:
  /// **'Injection site selector'**
  String get injectionSiteSelectorSemantic;

  /// No description provided for @injectionSiteCurrentSelection.
  ///
  /// In en, this message translates to:
  /// **'Current selection: {site}'**
  String injectionSiteCurrentSelection(String site);

  /// No description provided for @injectionSiteNoSelection.
  ///
  /// In en, this message translates to:
  /// **'No injection site selected'**
  String get injectionSiteNoSelection;

  /// Error message when injection site is not selected
  ///
  /// In en, this message translates to:
  /// **'Injection site is required for proper rotation tracking'**
  String get injectionSiteRequired;

  /// Display name for left shoulder blade injection site
  ///
  /// In en, this message translates to:
  /// **'Shoulder blade - left'**
  String get injectionSiteShoulderBladeLeft;

  /// Display name for right shoulder blade injection site
  ///
  /// In en, this message translates to:
  /// **'Shoulder blade - right'**
  String get injectionSiteShoulderBladeRight;

  /// Display name for middle shoulder blade injection site
  ///
  /// In en, this message translates to:
  /// **'Shoulder blade - middle'**
  String get injectionSiteShoulderBladeMiddle;

  /// Display name for left hip bones injection site
  ///
  /// In en, this message translates to:
  /// **'Hip bones - left'**
  String get injectionSiteHipBonesLeft;

  /// Display name for right hip bones injection site
  ///
  /// In en, this message translates to:
  /// **'Hip bones - right'**
  String get injectionSiteHipBonesRight;

  /// Title for injection sites analytics screen
  ///
  /// In en, this message translates to:
  /// **'Injection Sites'**
  String get injectionSitesAnalyticsTitle;

  /// Header for injection site rotation pattern section
  ///
  /// In en, this message translates to:
  /// **'Rotation Pattern'**
  String get injectionSitesRotationPattern;

  /// Subtitle showing session count for analytics
  ///
  /// In en, this message translates to:
  /// **'Based on the last {count} {count, plural, =1{session} other{sessions}}'**
  String injectionSitesBasedOnSessions(int count);

  /// Subtitle when no sessions are available
  ///
  /// In en, this message translates to:
  /// **'No sessions tracked yet'**
  String get injectionSitesNoSessionsYet;

  /// Error message when injection site data fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading injection site data'**
  String get injectionSitesErrorLoading;

  /// Empty state message when no injection sites have been tracked
  ///
  /// In en, this message translates to:
  /// **'Start tracking injection sites\nto see your rotation pattern'**
  String get injectionSitesEmptyStateMessage;

  /// No description provided for @stressLevelSelectorSemantic.
  ///
  /// In en, this message translates to:
  /// **'Stress level selector'**
  String get stressLevelSelectorSemantic;

  /// No description provided for @stressLevelLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get stressLevelLow;

  /// No description provided for @stressLevelMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get stressLevelMedium;

  /// No description provided for @stressLevelHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get stressLevelHigh;

  /// No description provided for @stressLevelLowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Low stress level'**
  String get stressLevelLowTooltip;

  /// No description provided for @stressLevelMediumTooltip.
  ///
  /// In en, this message translates to:
  /// **'Medium stress level'**
  String get stressLevelMediumTooltip;

  /// No description provided for @stressLevelHighTooltip.
  ///
  /// In en, this message translates to:
  /// **'High stress level'**
  String get stressLevelHighTooltip;

  /// No description provided for @stressLevelCurrentSelection.
  ///
  /// In en, this message translates to:
  /// **'Current selection: {level} stress level'**
  String stressLevelCurrentSelection(String level);

  /// No description provided for @stressLevelNoSelection.
  ///
  /// In en, this message translates to:
  /// **'No stress level selected'**
  String get stressLevelNoSelection;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Unable to save. Please check your account permissions.'**
  String get errorPermissionDenied;

  /// No description provided for @errorConnectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout. Your data is saved offline and will sync automatically.'**
  String get errorConnectionTimeout;

  /// No description provided for @errorServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Service temporarily unavailable. Please try again in a moment.'**
  String get errorServiceUnavailable;

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'Unable to save right now. Your data is saved offline.'**
  String get errorOffline;

  /// No description provided for @errorSyncLater.
  ///
  /// In en, this message translates to:
  /// **'(will sync later)'**
  String get errorSyncLater;

  /// No description provided for @errorSyncWhenOnline.
  ///
  /// In en, this message translates to:
  /// **'Will sync when online.'**
  String get errorSyncWhenOnline;

  /// No description provided for @errorValidationGeneric.
  ///
  /// In en, this message translates to:
  /// **'Please check your entries and try again.'**
  String get errorValidationGeneric;

  /// No description provided for @errorScheduleNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find a matching schedule. Logging as a one-time entry.'**
  String get errorScheduleNotFound;

  /// No description provided for @errorDuplicateSession.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already logged this treatment today. Would you like to update it instead?'**
  String get errorDuplicateSession;

  /// No description provided for @successOfflineLogged.
  ///
  /// In en, this message translates to:
  /// **'Logged successfully! Will sync when you are back online.'**
  String get successOfflineLogged;

  /// No description provided for @errorSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 treatment} other{{count} treatments}} could not sync. Check your connection and tap retry.'**
  String errorSyncFailed(int count);

  /// No description provided for @warningQueueSize.
  ///
  /// In en, this message translates to:
  /// **'You have {count} treatments waiting to sync. Connect to internet soon to avoid data loss.'**
  String warningQueueSize(int count);

  /// No description provided for @errorQueueFull.
  ///
  /// In en, this message translates to:
  /// **'Too many treatments waiting to sync ({count}). Please connect to internet to free up space.'**
  String errorQueueFull(int count);

  /// Title for medication reminder notifications
  ///
  /// In en, this message translates to:
  /// **'Medication reminder'**
  String get notificationMedicationTitle;

  /// Body text for medication reminder notifications
  ///
  /// In en, this message translates to:
  /// **'Time for {petName}\'s medication'**
  String notificationMedicationBody(String petName);

  /// Title for fluid therapy reminder notifications
  ///
  /// In en, this message translates to:
  /// **'Fluid therapy reminder'**
  String get notificationFluidTitle;

  /// Body text for fluid therapy reminder notifications
  ///
  /// In en, this message translates to:
  /// **'Time for {petName}\'s fluid therapy'**
  String notificationFluidBody(String petName);

  /// Title for follow-up reminder notifications
  ///
  /// In en, this message translates to:
  /// **'Treatment reminder'**
  String get notificationFollowupTitle;

  /// Body text for follow-up reminder notifications
  ///
  /// In en, this message translates to:
  /// **'{petName} may still need their treatment'**
  String notificationFollowupBody(String petName);

  /// Accessible long-form title for medication reminders
  ///
  /// In en, this message translates to:
  /// **'Treatment reminder: Medication for {petName}'**
  String notificationMedicationTitleA11y(String petName);

  /// Accessible long-form body for medication reminders
  ///
  /// In en, this message translates to:
  /// **'It\'s time to give {petName} their medication.'**
  String notificationMedicationBodyA11y(String petName);

  /// Accessible long-form title for fluid therapy reminders
  ///
  /// In en, this message translates to:
  /// **'Treatment reminder: Fluid therapy for {petName}'**
  String notificationFluidTitleA11y(String petName);

  /// Accessible long-form body for fluid therapy reminders
  ///
  /// In en, this message translates to:
  /// **'It\'s time to give {petName} their fluid therapy.'**
  String notificationFluidBodyA11y(String petName);

  /// Accessible long-form title for follow-up reminders
  ///
  /// In en, this message translates to:
  /// **'Treatment reminder for {petName}'**
  String notificationFollowupTitleA11y(String petName);

  /// Accessible long-form body for follow-up reminders
  ///
  /// In en, this message translates to:
  /// **'{petName} may still need their treatment.'**
  String notificationFollowupBodyA11y(String petName);

  /// Title for weekly treatment summary notification (Monday 09:00)
  ///
  /// In en, this message translates to:
  /// **'Your weekly summary is ready!'**
  String get notificationWeeklySummaryTitle;

  /// Body text for weekly treatment summary notification
  ///
  /// In en, this message translates to:
  /// **'Tap to see your progress and treatment adherence.'**
  String get notificationWeeklySummaryBody;

  /// Title for notification group summary (Android/iOS grouping)
  ///
  /// In en, this message translates to:
  /// **'{petName}\'s Reminders'**
  String notificationGroupSummaryTitle(Object petName);

  /// Group summary body when only medication reminders exist
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 medication reminder} other{{count} medication reminders}}'**
  String notificationGroupSummaryMedicationOnly(num count);

  /// Group summary body when only fluid therapy reminders exist
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 fluid therapy reminder} other{{count} fluid therapy reminders}}'**
  String notificationGroupSummaryFluidOnly(num count);

  /// Group summary body when both medication and fluid reminders exist
  ///
  /// In en, this message translates to:
  /// **'{medCount, plural, =1{1 medication} other{{medCount} medications}}, {fluidCount, plural, =1{1 fluid therapy} other{{fluidCount} fluid therapies}}'**
  String notificationGroupSummaryBoth(num fluidCount, num medCount);

  /// Text for notification action button to log treatment immediately. Used by screen readers (VoiceOver/TalkBack) to announce the action.
  ///
  /// In en, this message translates to:
  /// **'Log treatment now'**
  String get notificationActionLogNow;

  /// Title for bundled treatment notifications at same time
  ///
  /// In en, this message translates to:
  /// **'Treatment reminder for {petName}'**
  String notificationMultipleTreatmentsTitle(String petName);

  /// Body for multiple treatments at same time
  ///
  /// In en, this message translates to:
  /// **'It\'s time for {count} treatments'**
  String notificationMultipleTreatmentsBody(int count);

  /// Body for mixed treatment types (medication + fluid) at same time
  ///
  /// In en, this message translates to:
  /// **'It\'s time for medication and fluid therapy'**
  String get notificationMixedTreatmentsBody;

  /// Title for bundled follow-up notifications
  ///
  /// In en, this message translates to:
  /// **'Treatment reminder for {petName}'**
  String notificationMultipleFollowupTitle(String petName);

  /// Body for multiple unlogged treatments follow-up
  ///
  /// In en, this message translates to:
  /// **'{petName} may still need {count} treatments'**
  String notificationMultipleFollowupBody(String petName, int count);

  /// Message shown when user taps notification but is not authenticated
  ///
  /// In en, this message translates to:
  /// **'Please log in to record this treatment'**
  String get notificationAuthRequired;

  /// Message shown when notification refers to a deleted schedule
  ///
  /// In en, this message translates to:
  /// **'Reminder was for a treatment that\'s no longer scheduled. You can still log other treatments.'**
  String get notificationScheduleNotFound;

  /// Tooltip for bell icon when notifications are enabled
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationStatusEnabledTooltip;

  /// Tooltip for bell icon when notifications are disabled (not permanent)
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled - tap to enable'**
  String get notificationStatusDisabledTooltip;

  /// Tooltip for bell icon when notification permission is permanently denied
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled - tap to open Settings'**
  String get notificationStatusPermanentTooltip;

  /// Title for notification permission dialog
  ///
  /// In en, this message translates to:
  /// **'Never Miss a Treatment'**
  String get notificationPermissionDialogTitle;

  /// Dialog message when permission has not been requested yet
  ///
  /// In en, this message translates to:
  /// **'Enable notifications to receive timely reminders for {petName}\'s medications and fluid therapy. You\'re doing an amazing job caring for your cat - let us help you stay on track.'**
  String notificationPermissionMessageNotDetermined(String petName);

  /// Dialog message when permission was denied but can be requested again
  ///
  /// In en, this message translates to:
  /// **'Treatment reminders help you provide the best care for {petName}. Enable notifications to receive gentle reminders at the right times.'**
  String notificationPermissionMessageDenied(String petName);

  /// Dialog message when permission is permanently denied (must use Settings)
  ///
  /// In en, this message translates to:
  /// **'To receive treatment reminders for {petName}, please enable notifications in your device Settings. This ensures you never miss important medication or fluid therapy times.'**
  String notificationPermissionMessagePermanent(String petName);

  /// Fallback dialog message when pet name is not available
  ///
  /// In en, this message translates to:
  /// **'Enable notifications to receive treatment reminders.'**
  String get notificationPermissionMessageGeneric;

  /// Platform-specific hint for iOS users (reassurance)
  ///
  /// In en, this message translates to:
  /// **'You can always change this later in your device Settings.'**
  String get notificationPermissionIosHint;

  /// Platform-specific hint for Android users (emphasizes one-time ask)
  ///
  /// In en, this message translates to:
  /// **'This is the only time we\'ll ask - you can enable later in Settings if needed.'**
  String get notificationPermissionAndroidHint;

  /// Button text to trigger system permission request
  ///
  /// In en, this message translates to:
  /// **'Allow Notifications'**
  String get notificationPermissionAllowButton;

  /// Button text to open system Settings app
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get notificationPermissionOpenSettingsButton;

  /// Button text to dismiss permission dialog
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get notificationPermissionMaybeLaterButton;

  /// Success message shown after user grants notification permission
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled! You\'ll receive treatment reminders.'**
  String get notificationPermissionGrantedSuccess;

  /// Gentle feedback message when user denies notification permission
  ///
  /// In en, this message translates to:
  /// **'Notifications remain disabled. You can enable them anytime in Settings.'**
  String get notificationPermissionDeniedFeedback;

  /// Title for notification settings screen
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettingsTitle;

  /// Status card text when permission is granted
  ///
  /// In en, this message translates to:
  /// **'Notification permission granted'**
  String get notificationSettingsPermissionGranted;

  /// Status card text when permission is denied
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied'**
  String get notificationSettingsPermissionDenied;

  /// Banner message explaining how to enable notifications
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled in your device settings. Enable them to receive treatment reminders.'**
  String get notificationSettingsPermissionBannerMessage;

  /// Button to open system settings from notification settings screen
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get notificationSettingsOpenSettingsButton;

  /// Label for master notification enable toggle
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get notificationSettingsEnableToggleLabel;

  /// Label for weekly summary notification toggle
  ///
  /// In en, this message translates to:
  /// **'Weekly Summary'**
  String get notificationSettingsWeeklySummaryLabel;

  /// Description text explaining weekly summary notifications
  ///
  /// In en, this message translates to:
  /// **'Monday morning'**
  String get notificationSettingsWeeklySummaryDescription;

  /// Success message when weekly summary is enabled
  ///
  /// In en, this message translates to:
  /// **'Weekly summary enabled'**
  String get notificationSettingsWeeklySummarySuccess;

  /// Success message when weekly summary is disabled
  ///
  /// In en, this message translates to:
  /// **'Weekly summary disabled'**
  String get notificationSettingsWeeklySummaryDisabledSuccess;

  /// Error message when weekly summary toggle fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update weekly summary setting. Please try again.'**
  String get notificationSettingsWeeklySummaryError;

  /// Helper text shown when master toggle is disabled
  ///
  /// In en, this message translates to:
  /// **'Enable notifications above to use these features'**
  String get notificationSettingsFeatureRequiresMasterToggle;

  /// Message shown when pet profile is not set up
  ///
  /// In en, this message translates to:
  /// **'Please set up your pet profile first to use notification features'**
  String get notificationSettingsFeatureRequiresPetProfile;

  /// Brief privacy notice shown in permission preprompt dialog
  ///
  /// In en, this message translates to:
  /// **'We protect your privacy by using generic notification content with no medical details. All notification data is stored locally on your device only.'**
  String get notificationPrivacyNoticeShort;

  /// Button to open detailed privacy information
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get notificationPrivacyLearnMoreButton;

  /// Title for privacy details bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Notification Privacy'**
  String get notificationPrivacyBottomSheetTitle;

  /// Error message when privacy policy markdown fails to load
  ///
  /// In en, this message translates to:
  /// **'Unable to load privacy policy. Please try again.'**
  String get notificationPrivacyLoadError;

  /// Label for privacy policy navigation row in settings
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get notificationSettingsPrivacyPolicyLabel;

  /// Description text for privacy policy row
  ///
  /// In en, this message translates to:
  /// **'How we handle notification data'**
  String get notificationSettingsPrivacyPolicyDescription;

  /// Section title for data management options
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get notificationSettingsDataManagementTitle;

  /// Button label to clear all notification data
  ///
  /// In en, this message translates to:
  /// **'Clear Notification Data'**
  String get notificationSettingsClearDataButton;

  /// Description text explaining what clear data does
  ///
  /// In en, this message translates to:
  /// **'Cancel all scheduled notifications and clear stored data'**
  String get notificationSettingsClearDataDescription;

  /// Title for clear data confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Clear Notification Data?'**
  String get notificationSettingsClearDataConfirmTitle;

  /// Message explaining what will happen when clearing data
  ///
  /// In en, this message translates to:
  /// **'This will cancel all scheduled notifications and clear stored notification data. Your notification settings will be preserved.\n\nThis action cannot be undone.'**
  String get notificationSettingsClearDataConfirmMessage;

  /// Confirmation button to proceed with clearing data
  ///
  /// In en, this message translates to:
  /// **'Clear Data'**
  String get notificationSettingsClearDataConfirmButton;

  /// Success message after clearing data
  ///
  /// In en, this message translates to:
  /// **'Notification data cleared successfully ({count} notifications canceled)'**
  String notificationSettingsClearDataSuccess(int count);

  /// Error message when clearing data fails
  ///
  /// In en, this message translates to:
  /// **'Failed to clear notification data: {error}'**
  String notificationSettingsClearDataError(String error);

  /// Title for dialog shown when notification permission is revoked after being granted
  ///
  /// In en, this message translates to:
  /// **'Notification Permission Revoked'**
  String get notificationPermissionRevokedTitle;

  /// Message explaining that notification permission was revoked and needs to be re-enabled
  ///
  /// In en, this message translates to:
  /// **'We noticed that notification permission was disabled. To continue receiving treatment reminders, please re-enable notifications.'**
  String get notificationPermissionRevokedMessage;

  /// Button text to open system notification settings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get notificationPermissionRevokedAction;

  /// Title for dialog shown when notification plugin initialization fails (rare)
  ///
  /// In en, this message translates to:
  /// **'Notification Setup Issue'**
  String get notificationInitializationFailedTitle;

  /// Message explaining notification setup issue and that treatment logging still works
  ///
  /// In en, this message translates to:
  /// **'We\'re having trouble setting up reminders. You can still log treatments normally. Restart the app to try again.'**
  String get notificationInitializationFailedMessage;

  /// Toast message shown when scheduling fails (currently unused, reserved for future UI)
  ///
  /// In en, this message translates to:
  /// **'Unable to schedule reminder right now. Don\'t worry - you can still log treatments.'**
  String get notificationSchedulingFailedToast;

  /// Toast message shown when reconciliation fails (currently unused, reserved for future UI)
  ///
  /// In en, this message translates to:
  /// **'Some reminders couldn\'t be restored. Check your notification settings.'**
  String get notificationReconciliationFailedToast;

  /// No description provided for @a11yOn.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get a11yOn;

  /// No description provided for @a11yOff.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get a11yOff;

  /// No description provided for @a11yNotifMasterLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get a11yNotifMasterLabel;

  /// No description provided for @a11yNotifMasterHint.
  ///
  /// In en, this message translates to:
  /// **'Turns all notification features on or off'**
  String get a11yNotifMasterHint;

  /// No description provided for @a11yWeeklySummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary notifications'**
  String get a11yWeeklySummaryLabel;

  /// No description provided for @a11yWeeklySummaryHint.
  ///
  /// In en, this message translates to:
  /// **'Sends a summary every Monday at 9 a.m.'**
  String get a11yWeeklySummaryHint;

  /// No description provided for @a11yOpenSystemSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Open system notification settings'**
  String get a11yOpenSystemSettingsLabel;

  /// No description provided for @a11yOpenSystemSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Opens the device settings to manage notification permission'**
  String get a11yOpenSystemSettingsHint;

  /// No description provided for @a11ySettingsHeaderNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get a11ySettingsHeaderNotifications;

  /// No description provided for @a11ySettingsHeaderReminderFeatures.
  ///
  /// In en, this message translates to:
  /// **'Reminder features'**
  String get a11ySettingsHeaderReminderFeatures;

  /// No description provided for @a11ySettingsHeaderPrivacyAndData.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get a11ySettingsHeaderPrivacyAndData;

  /// No description provided for @qolNavigationTitle.
  ///
  /// In en, this message translates to:
  /// **'Quality of Life'**
  String get qolNavigationTitle;

  /// No description provided for @qolNavigationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your cat\'s wellbeing over time'**
  String get qolNavigationSubtitle;

  /// No description provided for @qolDomainVitality.
  ///
  /// In en, this message translates to:
  /// **'Vitality'**
  String get qolDomainVitality;

  /// No description provided for @qolDomainVitalityDesc.
  ///
  /// In en, this message translates to:
  /// **'Energy and activity levels'**
  String get qolDomainVitalityDesc;

  /// No description provided for @qolDomainComfort.
  ///
  /// In en, this message translates to:
  /// **'Comfort'**
  String get qolDomainComfort;

  /// No description provided for @qolDomainComfortDesc.
  ///
  /// In en, this message translates to:
  /// **'Physical comfort and mobility'**
  String get qolDomainComfortDesc;

  /// No description provided for @qolDomainEmotional.
  ///
  /// In en, this message translates to:
  /// **'Emotional Wellbeing'**
  String get qolDomainEmotional;

  /// No description provided for @qolDomainEmotionalDesc.
  ///
  /// In en, this message translates to:
  /// **'Mood and social behavior'**
  String get qolDomainEmotionalDesc;

  /// No description provided for @qolDomainAppetite.
  ///
  /// In en, this message translates to:
  /// **'Appetite'**
  String get qolDomainAppetite;

  /// No description provided for @qolDomainAppetiteDesc.
  ///
  /// In en, this message translates to:
  /// **'Interest in food and eating'**
  String get qolDomainAppetiteDesc;

  /// No description provided for @qolDomainTreatmentBurden.
  ///
  /// In en, this message translates to:
  /// **'Treatment Burden'**
  String get qolDomainTreatmentBurden;

  /// No description provided for @qolDomainTreatmentBurdenDesc.
  ///
  /// In en, this message translates to:
  /// **'Stress from CKD care'**
  String get qolDomainTreatmentBurdenDesc;

  /// No description provided for @qolQuestionVitality1.
  ///
  /// In en, this message translates to:
  /// **'In the past 7 days, how would you describe your cat\'s overall energy level compared to their usual self?'**
  String get qolQuestionVitality1;

  /// No description provided for @qolQuestionVitality2.
  ///
  /// In en, this message translates to:
  /// **'In the past 7 days, how often did your cat get up, walk around, or explore on their own instead of staying in one place?'**
  String get qolQuestionVitality2;

  /// No description provided for @qolQuestionVitality3.
  ///
  /// In en, this message translates to:
  /// **'In the past 7 days, how often did your cat show interest in play, toys, or interacting with objects around them?'**
  String get qolQuestionVitality3;

  /// No description provided for @qolQuestionComfort1.
  ///
  /// In en, this message translates to:
  /// **'In the past 7 days, how comfortable did your cat seem when moving, jumping, or changing position?'**
  String get qolQuestionComfort1;

  /// No description provided for @qolQuestionComfort2.
  ///
  /// In en, this message translates to:
  /// **'In the past 7 days, how often did you notice signs like stiffness, limping, or hesitation to jump up or down?'**
  String get qolQuestionComfort2;

  /// No description provided for @qolQuestionComfort3.
  ///
  /// In en, this message translates to:
  /// **'In the past 7 days, did your cat show signs of discomfort when using the litter box (straining, vocalizing, or spending a long time)?'**
  String get qolQuestionComfort3;

  /// No description provided for @qolQuestionEmotional1.
  ///
  /// In en, this message translates to:
  /// **'In the past 7 days, how would you describe your cat\'s overall mood?'**
  String get qolQuestionEmotional1;

  /// No description provided for @qolQuestionEmotional2.
  ///
  /// In en, this message translates to:
  /// **'In the past 7 days, how often did your cat seek contact with you (coming to you, asking for attention, or being near you)?'**
  String get qolQuestionEmotional2;

  /// No description provided for @qolQuestionEmotional3.
  ///
  /// In en, this message translates to:
  /// **'In the past 7 days, how often did your cat hide away or seem more withdrawn than usual?'**
  String get qolQuestionEmotional3;

  /// No description provided for @qolQuestionAppetite1.
  ///
  /// In en, this message translates to:
  /// **'In the past 7 days, how would you describe your cat\'s appetite overall?'**
  String get qolQuestionAppetite1;

  /// No description provided for @qolQuestionAppetite2.
  ///
  /// In en, this message translates to:
  /// **'In the past 7 days, how often did your cat finish most of their main meals?'**
  String get qolQuestionAppetite2;

  /// No description provided for @qolQuestionAppetite3.
  ///
  /// In en, this message translates to:
  /// **'In the past 7 days, how interested was your cat in treats or favorite foods?'**
  String get qolQuestionAppetite3;

  /// No description provided for @qolQuestionTreatment1.
  ///
  /// In en, this message translates to:
  /// **'In the past 7 days, how easy or difficult was it to give your cat their CKD treatments (subcutaneous fluids, pills, liquid medications, etc.)?'**
  String get qolQuestionTreatment1;

  /// No description provided for @qolQuestionTreatment2.
  ///
  /// In en, this message translates to:
  /// **'In the past 7 days, how stressed did your cat seem about treatments or being handled for their CKD care?'**
  String get qolQuestionTreatment2;

  /// No description provided for @qolVitality1Label0.
  ///
  /// In en, this message translates to:
  /// **'Much lower than usual (very sleepy, hardly active)'**
  String get qolVitality1Label0;

  /// No description provided for @qolVitality1Label1.
  ///
  /// In en, this message translates to:
  /// **'Lower than usual (noticeably less active)'**
  String get qolVitality1Label1;

  /// No description provided for @qolVitality1Label2.
  ///
  /// In en, this message translates to:
  /// **'About the same as usual'**
  String get qolVitality1Label2;

  /// No description provided for @qolVitality1Label3.
  ///
  /// In en, this message translates to:
  /// **'A bit higher than usual'**
  String get qolVitality1Label3;

  /// No description provided for @qolVitality1Label4.
  ///
  /// In en, this message translates to:
  /// **'Much higher than usual (very lively and active)'**
  String get qolVitality1Label4;

  /// No description provided for @qolVitality2Label0.
  ///
  /// In en, this message translates to:
  /// **'Almost never (stayed in one place most of the time)'**
  String get qolVitality2Label0;

  /// No description provided for @qolVitality2Label1.
  ///
  /// In en, this message translates to:
  /// **'Rarely (only got up a few times each day)'**
  String get qolVitality2Label1;

  /// No description provided for @qolVitality2Label2.
  ///
  /// In en, this message translates to:
  /// **'Sometimes (mixed between resting and moving)'**
  String get qolVitality2Label2;

  /// No description provided for @qolVitality2Label3.
  ///
  /// In en, this message translates to:
  /// **'Often (regularly moved around during the day)'**
  String get qolVitality2Label3;

  /// No description provided for @qolVitality2Label4.
  ///
  /// In en, this message translates to:
  /// **'Very often (frequently exploring or changing spots)'**
  String get qolVitality2Label4;

  /// No description provided for @qolVitality3Label0.
  ///
  /// In en, this message translates to:
  /// **'Never (showed no interest at all)'**
  String get qolVitality3Label0;

  /// No description provided for @qolVitality3Label1.
  ///
  /// In en, this message translates to:
  /// **'Rarely (once or twice all week)'**
  String get qolVitality3Label1;

  /// No description provided for @qolVitality3Label2.
  ///
  /// In en, this message translates to:
  /// **'Sometimes (a few times during the week)'**
  String get qolVitality3Label2;

  /// No description provided for @qolVitality3Label3.
  ///
  /// In en, this message translates to:
  /// **'Often (regularly showed interest)'**
  String get qolVitality3Label3;

  /// No description provided for @qolVitality3Label4.
  ///
  /// In en, this message translates to:
  /// **'Very often (frequently engaged with toys or play)'**
  String get qolVitality3Label4;

  /// No description provided for @qolComfort1Label0.
  ///
  /// In en, this message translates to:
  /// **'Very uncomfortable (often struggled or seemed in pain)'**
  String get qolComfort1Label0;

  /// No description provided for @qolComfort1Label1.
  ///
  /// In en, this message translates to:
  /// **'Uncomfortable (noticeable difficulty or stiffness)'**
  String get qolComfort1Label1;

  /// No description provided for @qolComfort1Label2.
  ///
  /// In en, this message translates to:
  /// **'Somewhat comfortable (a little stiff but mostly coping)'**
  String get qolComfort1Label2;

  /// No description provided for @qolComfort1Label3.
  ///
  /// In en, this message translates to:
  /// **'Comfortable (moves well with only mild issues)'**
  String get qolComfort1Label3;

  /// No description provided for @qolComfort1Label4.
  ///
  /// In en, this message translates to:
  /// **'Very comfortable (moves freely with no visible problems)'**
  String get qolComfort1Label4;

  /// No description provided for @qolComfort2Label0.
  ///
  /// In en, this message translates to:
  /// **'Every day or almost every day'**
  String get qolComfort2Label0;

  /// No description provided for @qolComfort2Label1.
  ///
  /// In en, this message translates to:
  /// **'Several times this week'**
  String get qolComfort2Label1;

  /// No description provided for @qolComfort2Label2.
  ///
  /// In en, this message translates to:
  /// **'Once or twice this week'**
  String get qolComfort2Label2;

  /// No description provided for @qolComfort2Label3.
  ///
  /// In en, this message translates to:
  /// **'Rarely (only once or twice this month)'**
  String get qolComfort2Label3;

  /// No description provided for @qolComfort2Label4.
  ///
  /// In en, this message translates to:
  /// **'Not at all in the past 7 days'**
  String get qolComfort2Label4;

  /// No description provided for @qolComfort3Label0.
  ///
  /// In en, this message translates to:
  /// **'Very often (showed clear discomfort most times)'**
  String get qolComfort3Label0;

  /// No description provided for @qolComfort3Label1.
  ///
  /// In en, this message translates to:
  /// **'Often (frequently showed signs of discomfort)'**
  String get qolComfort3Label1;

  /// No description provided for @qolComfort3Label2.
  ///
  /// In en, this message translates to:
  /// **'Sometimes (occasional signs of discomfort)'**
  String get qolComfort3Label2;

  /// No description provided for @qolComfort3Label3.
  ///
  /// In en, this message translates to:
  /// **'Rarely (only once or twice this week)'**
  String get qolComfort3Label3;

  /// No description provided for @qolComfort3Label4.
  ///
  /// In en, this message translates to:
  /// **'Not at all (used litter box comfortably all week)'**
  String get qolComfort3Label4;

  /// No description provided for @qolEmotional1Label0.
  ///
  /// In en, this message translates to:
  /// **'Very low (seemed miserable or very unhappy most of the time)'**
  String get qolEmotional1Label0;

  /// No description provided for @qolEmotional1Label1.
  ///
  /// In en, this message translates to:
  /// **'Low (often seemed unhappy or dull)'**
  String get qolEmotional1Label1;

  /// No description provided for @qolEmotional1Label2.
  ///
  /// In en, this message translates to:
  /// **'Neutral (neither especially unhappy nor especially happy)'**
  String get qolEmotional1Label2;

  /// No description provided for @qolEmotional1Label3.
  ///
  /// In en, this message translates to:
  /// **'Generally happy (seemed content most of the time)'**
  String get qolEmotional1Label3;

  /// No description provided for @qolEmotional1Label4.
  ///
  /// In en, this message translates to:
  /// **'Very happy (bright, cheerful, and engaged most of the time)'**
  String get qolEmotional1Label4;

  /// No description provided for @qolEmotional2Label0.
  ///
  /// In en, this message translates to:
  /// **'Never (did not seek contact at all)'**
  String get qolEmotional2Label0;

  /// No description provided for @qolEmotional2Label1.
  ///
  /// In en, this message translates to:
  /// **'Rarely (once a day or less)'**
  String get qolEmotional2Label1;

  /// No description provided for @qolEmotional2Label2.
  ///
  /// In en, this message translates to:
  /// **'Sometimes (a few times a day)'**
  String get qolEmotional2Label2;

  /// No description provided for @qolEmotional2Label3.
  ///
  /// In en, this message translates to:
  /// **'Often (regularly during the day)'**
  String get qolEmotional2Label3;

  /// No description provided for @qolEmotional2Label4.
  ///
  /// In en, this message translates to:
  /// **'Very often (actively seeks you out many times a day)'**
  String get qolEmotional2Label4;

  /// No description provided for @qolEmotional3Label0.
  ///
  /// In en, this message translates to:
  /// **'Much more than usual (hid or stayed away most of the time)'**
  String get qolEmotional3Label0;

  /// No description provided for @qolEmotional3Label1.
  ///
  /// In en, this message translates to:
  /// **'More than usual (clearly hiding or withdrawn)'**
  String get qolEmotional3Label1;

  /// No description provided for @qolEmotional3Label2.
  ///
  /// In en, this message translates to:
  /// **'About the same as usual'**
  String get qolEmotional3Label2;

  /// No description provided for @qolEmotional3Label3.
  ///
  /// In en, this message translates to:
  /// **'Less than usual (slightly more visible and present)'**
  String get qolEmotional3Label3;

  /// No description provided for @qolEmotional3Label4.
  ///
  /// In en, this message translates to:
  /// **'Much less than usual (very rarely hiding or withdrawn)'**
  String get qolEmotional3Label4;

  /// No description provided for @qolAppetite1Label0.
  ///
  /// In en, this message translates to:
  /// **'Almost no appetite (hardly eating anything)'**
  String get qolAppetite1Label0;

  /// No description provided for @qolAppetite1Label1.
  ///
  /// In en, this message translates to:
  /// **'Very poor appetite (eating much less than usual)'**
  String get qolAppetite1Label1;

  /// No description provided for @qolAppetite1Label2.
  ///
  /// In en, this message translates to:
  /// **'Reduced appetite (eating somewhat less than usual)'**
  String get qolAppetite1Label2;

  /// No description provided for @qolAppetite1Label3.
  ///
  /// In en, this message translates to:
  /// **'Normal appetite (eating about their usual amount)'**
  String get qolAppetite1Label3;

  /// No description provided for @qolAppetite1Label4.
  ///
  /// In en, this message translates to:
  /// **'Very good appetite (keen to eat, may ask for more)'**
  String get qolAppetite1Label4;

  /// No description provided for @qolAppetite2Label0.
  ///
  /// In en, this message translates to:
  /// **'Almost never (left most of each meal)'**
  String get qolAppetite2Label0;

  /// No description provided for @qolAppetite2Label1.
  ///
  /// In en, this message translates to:
  /// **'Rarely (finished less than half of meals)'**
  String get qolAppetite2Label1;

  /// No description provided for @qolAppetite2Label2.
  ///
  /// In en, this message translates to:
  /// **'Sometimes (finished about half of meals)'**
  String get qolAppetite2Label2;

  /// No description provided for @qolAppetite2Label3.
  ///
  /// In en, this message translates to:
  /// **'Often (finished most meals)'**
  String get qolAppetite2Label3;

  /// No description provided for @qolAppetite2Label4.
  ///
  /// In en, this message translates to:
  /// **'Almost always (finished nearly every meal)'**
  String get qolAppetite2Label4;

  /// No description provided for @qolAppetite3Label0.
  ///
  /// In en, this message translates to:
  /// **'Not interested at all (refused or ignored them)'**
  String get qolAppetite3Label0;

  /// No description provided for @qolAppetite3Label1.
  ///
  /// In en, this message translates to:
  /// **'Slightly interested (occasionally accepted, often refused)'**
  String get qolAppetite3Label1;

  /// No description provided for @qolAppetite3Label2.
  ///
  /// In en, this message translates to:
  /// **'Moderately interested (accepted some, refused some)'**
  String get qolAppetite3Label2;

  /// No description provided for @qolAppetite3Label3.
  ///
  /// In en, this message translates to:
  /// **'Very interested (usually keen to take them)'**
  String get qolAppetite3Label3;

  /// No description provided for @qolAppetite3Label4.
  ///
  /// In en, this message translates to:
  /// **'Extremely interested (actively asks for or searches for them)'**
  String get qolAppetite3Label4;

  /// No description provided for @qolTreatment1Label0.
  ///
  /// In en, this message translates to:
  /// **'Extremely difficult (usually failed or very stressful for both)'**
  String get qolTreatment1Label0;

  /// No description provided for @qolTreatment1Label1.
  ///
  /// In en, this message translates to:
  /// **'Difficult (needed a lot of effort or caused clear distress)'**
  String get qolTreatment1Label1;

  /// No description provided for @qolTreatment1Label2.
  ///
  /// In en, this message translates to:
  /// **'Manageable (sometimes a struggle but usually possible)'**
  String get qolTreatment1Label2;

  /// No description provided for @qolTreatment1Label3.
  ///
  /// In en, this message translates to:
  /// **'Easy (minor resistance but generally straightforward)'**
  String get qolTreatment1Label3;

  /// No description provided for @qolTreatment1Label4.
  ///
  /// In en, this message translates to:
  /// **'Very easy (your cat accepts treatments calmly)'**
  String get qolTreatment1Label4;

  /// No description provided for @qolTreatment2Label0.
  ///
  /// In en, this message translates to:
  /// **'Extremely stressed (panics, fights, or freezes every time)'**
  String get qolTreatment2Label0;

  /// No description provided for @qolTreatment2Label1.
  ///
  /// In en, this message translates to:
  /// **'Very stressed (clearly upset most times)'**
  String get qolTreatment2Label1;

  /// No description provided for @qolTreatment2Label2.
  ///
  /// In en, this message translates to:
  /// **'Moderately stressed (shows some stress but copes)'**
  String get qolTreatment2Label2;

  /// No description provided for @qolTreatment2Label3.
  ///
  /// In en, this message translates to:
  /// **'Slightly stressed (a bit tense but settles quickly)'**
  String get qolTreatment2Label3;

  /// No description provided for @qolTreatment2Label4.
  ///
  /// In en, this message translates to:
  /// **'Not at all stressed (relaxed or only minimally bothered)'**
  String get qolTreatment2Label4;

  /// No description provided for @qolRecallPeriod.
  ///
  /// In en, this message translates to:
  /// **'In the past 7 days...'**
  String get qolRecallPeriod;

  /// No description provided for @qolNotSure.
  ///
  /// In en, this message translates to:
  /// **'Not sure / Unable to observe this week'**
  String get qolNotSure;

  /// No description provided for @qolRadarChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Quality of Life Profile'**
  String get qolRadarChartTitle;

  /// No description provided for @qolInsufficientData.
  ///
  /// In en, this message translates to:
  /// **'Insufficient data'**
  String get qolInsufficientData;

  /// No description provided for @qolIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get qolIncomplete;

  /// No description provided for @qolHistorySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Assessments'**
  String get qolHistorySectionTitle;

  /// No description provided for @qolNeedMoreData.
  ///
  /// In en, this message translates to:
  /// **'Need at least 2 assessments to see trends'**
  String get qolNeedMoreData;

  /// No description provided for @qolDomainVitalityShort.
  ///
  /// In en, this message translates to:
  /// **'Vital.'**
  String get qolDomainVitalityShort;

  /// No description provided for @qolDomainComfortShort.
  ///
  /// In en, this message translates to:
  /// **'Comf.'**
  String get qolDomainComfortShort;

  /// No description provided for @qolDomainEmotionalShort.
  ///
  /// In en, this message translates to:
  /// **'Emot.'**
  String get qolDomainEmotionalShort;

  /// No description provided for @qolDomainAppetiteShort.
  ///
  /// In en, this message translates to:
  /// **'Appe.'**
  String get qolDomainAppetiteShort;

  /// No description provided for @qolDomainTreatmentBurdenShort.
  ///
  /// In en, this message translates to:
  /// **'Treat.'**
  String get qolDomainTreatmentBurdenShort;

  /// No description provided for @qolOverallScore.
  ///
  /// In en, this message translates to:
  /// **'Overall Score'**
  String get qolOverallScore;

  /// No description provided for @qolScoreBandVeryGood.
  ///
  /// In en, this message translates to:
  /// **'Very Good'**
  String get qolScoreBandVeryGood;

  /// No description provided for @qolScoreBandGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get qolScoreBandGood;

  /// No description provided for @qolScoreBandFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get qolScoreBandFair;

  /// No description provided for @qolScoreBandLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get qolScoreBandLow;

  /// No description provided for @qolBasedOnDomains.
  ///
  /// In en, this message translates to:
  /// **'Based on {count} of 5 domains'**
  String qolBasedOnDomains(int count);

  /// No description provided for @qolQuestionsAnswered.
  ///
  /// In en, this message translates to:
  /// **'{answered} of {total} questions answered'**
  String qolQuestionsAnswered(int answered, int total);

  /// No description provided for @qolAssessedOn.
  ///
  /// In en, this message translates to:
  /// **'Assessed on {date}'**
  String qolAssessedOn(String date);

  /// No description provided for @qolComparedToLast.
  ///
  /// In en, this message translates to:
  /// **'vs. last assessment'**
  String get qolComparedToLast;

  /// No description provided for @qolLowConfidenceExplanation.
  ///
  /// In en, this message translates to:
  /// **'This domain has less than 50% of questions answered, so the score may not be reliable.'**
  String get qolLowConfidenceExplanation;

  /// No description provided for @qolQuestionnaireTitle.
  ///
  /// In en, this message translates to:
  /// **'QoL Assessment'**
  String get qolQuestionnaireTitle;

  /// No description provided for @qolQuestionnaireEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Assessment'**
  String get qolQuestionnaireEditTitle;

  /// No description provided for @qolHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Quality of Life'**
  String get qolHistoryTitle;

  /// No description provided for @qolTrendChartTitle.
  ///
  /// In en, this message translates to:
  /// **'QoL Trends'**
  String get qolTrendChartTitle;

  /// No description provided for @qolQuestionProgress.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String qolQuestionProgress(int current, int total);

  /// No description provided for @qolComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get qolComplete;

  /// No description provided for @qolStartAssessment.
  ///
  /// In en, this message translates to:
  /// **'Start Assessment'**
  String get qolStartAssessment;

  /// No description provided for @qolStartFirstAssessment.
  ///
  /// In en, this message translates to:
  /// **'Start First Assessment'**
  String get qolStartFirstAssessment;

  /// No description provided for @qolContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get qolContinue;

  /// No description provided for @qolSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get qolSave;

  /// No description provided for @qolDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard progress?'**
  String get qolDiscardTitle;

  /// No description provided for @qolDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve answered {answered} of 14 questions. Exit without saving?'**
  String qolDiscardMessage(int answered);

  /// No description provided for @qolKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get qolKeepEditing;

  /// No description provided for @qolSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save assessment. Please try again.'**
  String get qolSaveError;

  /// No description provided for @qolLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load assessments. Check your connection.'**
  String get qolLoadError;

  /// No description provided for @qolResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'QoL Results'**
  String get qolResultsTitle;

  /// No description provided for @qolDomainScoresTitle.
  ///
  /// In en, this message translates to:
  /// **'Domain Scores'**
  String get qolDomainScoresTitle;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewHistory;

  /// No description provided for @qolEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Your Cat\'s Quality of Life'**
  String get qolEmptyStateTitle;

  /// No description provided for @qolEmptyStateMessage.
  ///
  /// In en, this message translates to:
  /// **'Complete assessments weekly to identify trends and share insights with your vet.'**
  String get qolEmptyStateMessage;

  /// No description provided for @qolHistoryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No assessments yet. Start your first one to begin tracking.'**
  String get qolHistoryEmptyMessage;

  /// No description provided for @qolHomeCardEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Track your cat\'s wellbeing over time'**
  String get qolHomeCardEmptyMessage;

  /// No description provided for @qolFirstAssessmentMessage.
  ///
  /// In en, this message translates to:
  /// **'This is your baseline. Complete another in 7 days to see trends.'**
  String get qolFirstAssessmentMessage;

  /// No description provided for @qolDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Assessment?'**
  String get qolDeleteConfirmTitle;

  /// No description provided for @qolDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the assessment from {date}.'**
  String qolDeleteConfirmMessage(String date);

  /// No description provided for @qolDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Assessment deleted successfully'**
  String get qolDeleteSuccess;

  /// No description provided for @qolDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete assessment. Please try again.'**
  String get qolDeleteError;

  /// No description provided for @qolNeedMoreAssessments.
  ///
  /// In en, this message translates to:
  /// **'Complete another assessment to see trends and comparisons.'**
  String get qolNeedMoreAssessments;

  /// No description provided for @qolInsufficientDataForInterpretation.
  ///
  /// In en, this message translates to:
  /// **'Insufficient data to provide trend interpretation. Complete more questions in your next assessment.'**
  String get qolInsufficientDataForInterpretation;

  /// No description provided for @qolInterpretationStable.
  ///
  /// In en, this message translates to:
  /// **'Your cat\'s quality of life has remained stable since the last assessment.'**
  String get qolInterpretationStable;

  /// No description provided for @qolInterpretationImproving.
  ///
  /// In en, this message translates to:
  /// **'Quality of life scores have improved. Great progress!'**
  String get qolInterpretationImproving;

  /// No description provided for @qolInterpretationDeclining.
  ///
  /// In en, this message translates to:
  /// **'Quality of life scores are lower than the last assessment. Consider discussing recent changes with your veterinarian.'**
  String get qolInterpretationDeclining;

  /// No description provided for @qolInterpretationNotableDropComfort.
  ///
  /// In en, this message translates to:
  /// **'Comfort scores have dropped notably. You may want to discuss pain management with your vet.'**
  String get qolInterpretationNotableDropComfort;

  /// No description provided for @qolInterpretationNotableDropAppetite.
  ///
  /// In en, this message translates to:
  /// **'Appetite scores are significantly lower. Monitor eating habits closely and consult your vet.'**
  String get qolInterpretationNotableDropAppetite;

  /// No description provided for @qolInterpretationNotableDropVitality.
  ///
  /// In en, this message translates to:
  /// **'Vitality scores have decreased notably. Your cat may be experiencing lower energy levels.'**
  String get qolInterpretationNotableDropVitality;

  /// No description provided for @qolInterpretationNotableDropEmotional.
  ///
  /// In en, this message translates to:
  /// **'Emotional wellbeing scores have dropped significantly. Your cat may be experiencing stress or discomfort.'**
  String get qolInterpretationNotableDropEmotional;

  /// No description provided for @qolInterpretationNotableDropTreatmentBurden.
  ///
  /// In en, this message translates to:
  /// **'Treatment burden scores indicate increased stress from CKD care. Consider discussing ways to make treatments easier.'**
  String get qolInterpretationNotableDropTreatmentBurden;

  /// No description provided for @qolTrendDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'These trends are observational only. Always consult your veterinarian for medical decisions.'**
  String get qolTrendDisclaimer;

  /// No description provided for @qolDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This tool tracks quality of life trends over time for your reference. It is not a diagnostic instrument and does not replace veterinary care. Always consult your veterinarian for medical decisions.'**
  String get qolDisclaimer;

  /// No description provided for @qolScientificAttribution.
  ///
  /// In en, this message translates to:
  /// **'HydraCAT\'s Quality of Life assessment is informed by published psychometric research on feline health-related quality of life, including studies by Bijsmans et al. (2016), Lorbach et al. (2022), and Wright et al. (2025). This tool is independently developed and is not affiliated with or endorsed by the authors of these studies.'**
  String get qolScientificAttribution;
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
