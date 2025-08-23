/// App configuration with build-time environment detection
///
/// Usage:
/// - Development: flutter run --flavor dev --dart-define=FLAVOR=dev
/// - Production: flutter run --flavor prod --dart-define=FLAVOR=prod
class AppConfig {
  /// The current environment flavor (dev, prod, etc.)
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  /// Whether the app is running in production mode
  static bool get isProd => flavor == 'prod';

  /// Whether the app is running in development mode
  static bool get isDev => flavor == 'dev';

  /// Get the Firebase project ID based on environment
  static String get firebaseProjectId {
    switch (flavor) {
      case 'prod':
        return 'myckdapp';
      case 'dev':
      default:
        return 'hydracattest';
    }
  }

  /// Get a human-readable environment name
  static String get environmentName {
    switch (flavor) {
      case 'prod':
        return 'Production';
      case 'dev':
      default:
        return 'Development';
    }
  }

  /// Whether to enable debug features
  static bool get enableDebugFeatures => isDev;

  /// Whether to enable analytics in this environment
  static bool get enableAnalytics => true; // Enable for both environments

  /// Whether to enable crashlytics in this environment
  static bool get enableCrashlytics => true; // Enable for both environments
}
