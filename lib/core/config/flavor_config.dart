/// Available flavors for the application.
enum Flavor {
  /// Development environment.
  development,

  /// Production environment.
  production,
}

/// Configuration manager for application flavors.
class FlavorConfig {
  static Flavor? _flavor;

  /// Gets the current flavor, defaults to development.
  static Flavor get currentFlavor {
    return _flavor ?? Flavor.development;
  }

  /// Gets the current flavor name as string.
  static String get currentFlavorName {
    switch (currentFlavor) {
      case Flavor.development:
        return 'development';
      case Flavor.production:
        return 'production';
    }
  }

  /// Returns true if current flavor is development.
  static bool get isDevelopment => currentFlavor == Flavor.development;

  /// Returns true if current flavor is production.
  static bool get isProduction => currentFlavor == Flavor.production;

  /// Gets the current flavor.
  static Flavor get flavor => _flavor ?? Flavor.development;

  /// Sets the current flavor.
  static set flavor(Flavor value) {
    _flavor = value;
  }

  /// Gets the app name based on current flavor.
  static String get appName {
    switch (currentFlavor) {
      case Flavor.development:
        return 'Hydracat Dev';
      case Flavor.production:
        return 'Hydracat';
    }
  }

  /// Gets the app suffix based on current flavor.
  static String get appSuffix {
    switch (currentFlavor) {
      case Flavor.development:
        return '.dev';
      case Flavor.production:
        return '';
    }
  }
}
