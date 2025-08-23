import 'dart:io';
import 'package:flutter/foundation.dart';

/// Environment configuration service that loads Firebase configuration
/// from environment variables or build-time defines.
class EnvConfig {
  static const String _defaultEnv = 'dev';

  /// Get the current environment
  static String get environment =>
      const String.fromEnvironment('ENV', defaultValue: _defaultEnv);

  /// Build-time configuration map for Firebase values
  static const Map<String, String> _buildTimeConfig = {
    'FIREBASE_API_KEY_IOS': String.fromEnvironment('FIREBASE_API_KEY_IOS'),
    'FIREBASE_APP_ID_IOS': String.fromEnvironment('FIREBASE_APP_ID_IOS'),
    'FIREBASE_MESSAGING_SENDER_ID_IOS': String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID_IOS',
    ),
    'FIREBASE_PROJECT_ID_IOS': String.fromEnvironment(
      'FIREBASE_PROJECT_ID_IOS',
    ),
    'FIREBASE_STORAGE_BUCKET_IOS': String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET_IOS',
    ),
    'FIREBASE_IOS_BUNDLE_ID_IOS': String.fromEnvironment(
      'FIREBASE_IOS_BUNDLE_ID_IOS',
    ),
    'FIREBASE_API_KEY_ANDROID': String.fromEnvironment(
      'FIREBASE_API_KEY_ANDROID',
    ),
    'FIREBASE_APP_ID_ANDROID': String.fromEnvironment(
      'FIREBASE_APP_ID_ANDROID',
    ),
    'FIREBASE_MESSAGING_SENDER_ID_ANDROID': String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID_ANDROID',
    ),
    'FIREBASE_PROJECT_ID_ANDROID': String.fromEnvironment(
      'FIREBASE_PROJECT_ID_ANDROID',
    ),
    'FIREBASE_STORAGE_BUCKET_ANDROID': String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET_ANDROID',
    ),
  };

  /// Load environment variables from file
  static Map<String, String> _loadEnvFile() {
    try {
      // Method 1: Try relative to current directory
      final envFile = File('config/env.$environment');
      if (envFile.existsSync()) {
        debugPrint('✅ Found environment file: ${envFile.absolute.path}');
        final lines = envFile.readAsLinesSync();
        return _parseEnvLines(lines);
      }

      // Method 2: Try to find the file relative to the current directory
      final currentDir = Directory.current;
      debugPrint('🔍 Current directory: ${currentDir.path}');

      final projectRoot = _findProjectRoot(currentDir);
      if (projectRoot != null) {
        debugPrint('🔍 Project root found: ${projectRoot.path}');
        final envFileFromRoot = File(
          '${projectRoot.path}/config/env.$environment',
        );
        if (envFileFromRoot.existsSync()) {
          debugPrint(
            '✅ Found environment file from project root: '
            '${envFileFromRoot.absolute.path}',
          );
          final lines = envFileFromRoot.readAsLinesSync();
          return _parseEnvLines(lines);
        }
      }

      // Method 3: Try to find the file by going up directories
      Directory? searchDir = currentDir;
      const maxDepth = 10; // Prevent infinite loops
      var depth = 0;

      while (searchDir != null && depth < maxDepth) {
        final envFile = File('${searchDir.path}/config/env.$environment');
        if (envFile.existsSync()) {
          debugPrint(
            '✅ Found environment file by searching up directories: '
            '${envFile.absolute.path}',
          );
          final lines = envFile.readAsLinesSync();
          return _parseEnvLines(lines);
        }

        try {
          searchDir = searchDir.parent;
          depth++;
        } on Exception {
          break;
        }
      }

      // If still not found, return empty map
      debugPrint('⚠️ Could not find environment file: config/env.$environment');
      debugPrint(
        '   Searched in current directory and up to $depth parent directories',
      );
      return {};
    } on Exception catch (e) {
      // If any error occurs, return empty map
      debugPrint('⚠️ Error loading environment file: $e');
      return {};
    }
  }

  /// Parse environment file lines into a map
  static Map<String, String> _parseEnvLines(List<String> lines) {
    final envVars = <String, String>{};

    for (final line in lines) {
      if (line.trim().isEmpty || line.startsWith('#')) continue;

      final parts = line.split('=');
      if (parts.length == 2) {
        envVars[parts[0].trim()] = parts[1].trim();
      }
    }

    return envVars;
  }

  /// Find project root by looking for pubspec.yaml
  static Directory? _findProjectRoot(Directory currentDir) {
    try {
      var dir = currentDir;
      while (dir.path != dir.parent.path) {
        if (File('${dir.path}/pubspec.yaml').existsSync()) {
          return dir;
        }
        dir = dir.parent;
      }
    } on Exception {
      // If any error occurs, return null
    }
    return null;
  }

  /// Get Firebase configuration value with fallback to build-time defines
  static String getFirebaseConfig(String key, {String? defaultValue}) {
    // First try build-time configuration map (from --dart-define flags)
    if (_buildTimeConfig.containsKey(key)) {
      final buildTimeValue = _buildTimeConfig[key]!;
      if (buildTimeValue.isNotEmpty) {
        final truncatedBuildValue = buildTimeValue.length > 10
            ? '${buildTimeValue.substring(0, 10)}...'
            : buildTimeValue;
        debugPrint(
          '✅ Found Firebase config "$key" in build-time config: '
          '$truncatedBuildValue',
        );
        return buildTimeValue;
      }
    }

    // Second try environment variables (from shell script)
    final envValue = Platform.environment[key];
    if (envValue != null && envValue.isNotEmpty) {
      final truncatedEnvValue = envValue.length > 10
          ? '${envValue.substring(0, 10)}...'
          : envValue;
      debugPrint(
        '✅ Found Firebase config "$key" in environment variables: '
        '$truncatedEnvValue',
      );
      return envValue;
    }

    // Third try environment variables from file
    final envVars = _loadEnvFile();
    if (envVars.containsKey(key)) {
      debugPrint(
        '✅ Found Firebase config "$key" in environment file: '
        '${envVars[key]}',
      );
      return envVars[key]!;
    }

    // Finally use default if provided
    if (defaultValue != null) {
      debugPrint('✅ Using default Firebase config "$key": $defaultValue');
      return defaultValue;
    }

    // Log what we found for debugging
    debugPrint(
      '❌ Firebase config "$key" not found for environment '
      '"$environment"',
    );
    debugPrint('   Build-time config keys: ${_buildTimeConfig.keys.toList()}');
    final configValues = _buildTimeConfig.map(
      (k, v) => MapEntry(
        k,
        v.isEmpty
            ? 'empty'
            : '${v.substring(0, v.length > 10 ? 10 : v.length)}...',
      ),
    );
    debugPrint('   Build-time config values: $configValues');
    debugPrint('   Environment variables loaded: ${envVars.keys.toList()}');
    final firebaseKeys = Platform.environment.keys
        .where((k) => k.startsWith('FIREBASE_'))
        .toList();
    debugPrint('   Platform environment variables: $firebaseKeys');

    throw Exception(
      'Firebase configuration key "$key" not found for environment '
      '"$environment"',
    );
  }

  /// Test method to debug environment loading
  static void debugEnvironmentLoading() {
    debugPrint('🔍 === Environment Loading Debug ===');
    debugPrint('   Current environment: $environment');
    debugPrint('   Current directory: ${Directory.current.path}');

    // Test build-time defines first
    debugPrint('   Testing build-time config map:');
    for (final entry in _buildTimeConfig.entries) {
      if (entry.value.isNotEmpty) {
        final truncatedValue = entry.value.length > 10
            ? '${entry.value.substring(0, 10)}...'
            : entry.value;
        debugPrint('     ✅ ${entry.key}: $truncatedValue');
      } else {
        debugPrint('     ❌ ${entry.key}: empty or not found');
      }
    }

    final envVars = _loadEnvFile();
    debugPrint('   Environment variables loaded: ${envVars.keys.length} keys');
    if (envVars.isNotEmpty) {
      debugPrint('   Keys: ${envVars.keys.toList()}');
    }

    debugPrint('   Platform environment variables:');
    final platformKeys = Platform.environment.keys
        .where((k) => k.startsWith('FIREBASE_'))
        .toList();
    if (platformKeys.isNotEmpty) {
      for (final key in platformKeys) {
        final value = Platform.environment[key];
        debugPrint(
          '     $key: '
          '${value?.substring(0, value.length > 10 ? 10 : value.length)}...',
        );
      }
    } else {
      debugPrint('     None found');
    }

    debugPrint('🔍 === End Debug ===');
  }

  /// Firebase configuration keys for Android
  /// API key for Android Firebase configuration
  static const String apiKeyAndroid = 'FIREBASE_API_KEY_ANDROID';

  /// App ID for Android Firebase configuration
  static const String appIdAndroid = 'FIREBASE_APP_ID_ANDROID';

  /// Messaging sender ID for Android Firebase configuration
  static const String messagingSenderIdAndroid =
      'FIREBASE_MESSAGING_SENDER_ID_ANDROID';

  /// Project ID for Android Firebase configuration
  static const String projectIdAndroid = 'FIREBASE_PROJECT_ID_ANDROID';

  /// Storage bucket for Android Firebase configuration
  static const String storageBucketAndroid = 'FIREBASE_STORAGE_BUCKET_ANDROID';

  /// Firebase configuration keys for iOS
  /// API key for iOS Firebase configuration
  static const String apiKeyIos = 'FIREBASE_API_KEY_IOS';

  /// App ID for iOS Firebase configuration
  static const String appIdIos = 'FIREBASE_APP_ID_IOS';

  /// Messaging sender ID for iOS Firebase configuration
  static const String messagingSenderIdIos = 'FIREBASE_MESSAGING_SENDER_ID_IOS';

  /// Project ID for iOS Firebase configuration
  static const String projectIdIos = 'FIREBASE_PROJECT_ID_IOS';

  /// Storage bucket for iOS Firebase configuration
  static const String storageBucketIos = 'FIREBASE_STORAGE_BUCKET_IOS';

  /// iOS bundle identifier for Firebase configuration
  static const String iosBundleIdIos = 'FIREBASE_IOS_BUNDLE_ID_IOS';
}
