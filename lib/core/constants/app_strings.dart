/// Constants for all app strings used throughout the HydraCat application.
///
/// **DEPRECATED**: This class is being phased out in favor of Flutter's l10n system.
/// New code should use `context.l10n` for localized strings instead.
///
/// Migration status:
/// - ✅ Onboarding feature: Migrated to l10n
/// - ⚠️ Other features: Still using AppStrings (to be migrated)
///
/// Example usage of new l10n system:
/// ```dart
/// // Old way (deprecated):
/// Text(AppStrings.appName)
///
/// // New way (preferred):
/// Text(context.l10n.appName)
/// ```
///
/// See: lib/l10n/app_en.arb for string definitions
@Deprecated('Use context.l10n instead. See lib/l10n/app_localizations.dart')
class AppStrings {
  // App information
  /// The name of the application
  static const String appName = 'HydraCat';

  /// Description of the application
  static const String appDescription =
      'Hydration tracking for cats with kidney disease';

  /// Current version of the application
  static const String appVersion = '1.0.0';

  // Navigation
  /// Home navigation label
  static const String home = 'Home';

  /// Profile navigation label
  static const String profile = 'Profile';

  /// Session logging navigation label
  static const String logging = 'Session Logging';

  /// Progress and analytics navigation label
  static const String progress = 'Progress & Analytics';

  /// Resources and tips navigation label
  static const String resources = 'Resources & Tips';

  /// Login navigation label
  static const String login = 'Login';

  /// Logout navigation label
  static const String logout = 'Logout';

  // Common actions
  /// Save action label
  static const String save = 'Save';

  /// Cancel action label
  static const String cancel = 'Cancel';

  /// Delete action label
  static const String delete = 'Delete';

  /// Edit action label
  static const String edit = 'Edit';

  /// Add action label
  static const String add = 'Add';

  /// Confirm action label
  static const String confirm = 'Confirm';

  /// Retry action label
  static const String retry = 'Retry';

  // Messages
  /// Loading message
  static const String loading = 'Loading...';

  /// Error message
  static const String error = 'Error';

  /// Success message
  static const String success = 'Success';

  /// Warning message
  static const String warning = 'Warning';

  /// Information message
  static const String info = 'Information';

  // Hydration specific
  /// Hydration session label
  static const String hydrationSession = 'Hydration Session';

  /// Fluid intake label
  static const String fluidIntake = 'Fluid Intake';

  /// Session duration label
  static const String sessionDuration = 'Session Duration';

  /// Start session label
  static const String startSession = 'Start Session';

  /// End session label
  static const String endSession = 'End Session';

  /// Session notes label
  static const String sessionNotes = 'Session Notes';

  // Cat profile
  /// Cat name label
  static const String catName = 'Cat Name';

  /// Cat age label
  static const String catAge = 'Age';

  /// Cat weight label
  static const String catWeight = 'Weight';

  /// Cat breed label
  static const String catBreed = 'Breed';

  /// Medical notes label
  static const String medicalNotes = 'Medical Notes';

  // Units
  /// Milliliters unit
  static const String milliliters = 'ml';

  /// Minutes unit
  static const String minutes = 'min';

  /// Kilograms unit
  static const String kilograms = 'kg';

  /// Pounds unit
  static const String pounds = 'lbs';

  /// Years unit
  static const String years = 'years';

  // Placeholder text
  /// Placeholder for cat name input
  static const String enterCatName = 'Enter cat name';

  /// Placeholder for weight input
  static const String enterWeight = 'Enter weight';

  /// Placeholder for age input
  static const String enterAge = 'Enter age';

  /// Placeholder for notes input
  static const String addNotes = 'Add notes...';
}
