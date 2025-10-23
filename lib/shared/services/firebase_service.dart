import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/core/config/flavor_config.dart';
import 'package:hydracat/firebase_options.dart';

/// Service class for managing Firebase initialization and configuration.
class FirebaseService {
  /// Factory constructor to get the singleton instance
  factory FirebaseService() => _instance ??= FirebaseService._();

  /// Private unnamed constructor
  FirebaseService._();
  static FirebaseService? _instance;

  late FirebaseApp _app;
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  late FirebaseAnalytics _analytics;
  late FirebaseCrashlytics _crashlytics;
  late FirebaseMessaging _messaging;

  /// Getter for the Firebase app instance
  FirebaseApp get app => _app;

  /// Getter for the Firebase auth instance
  FirebaseAuth get auth => _auth;

  /// Getter for the Firestore instance
  FirebaseFirestore get firestore => _firestore;

  /// Getter for the Firebase analytics instance
  FirebaseAnalytics get analytics => _analytics;

  /// Getter for the Firebase crashlytics instance
  FirebaseCrashlytics get crashlytics => _crashlytics;

  /// Getter for the Firebase messaging instance
  FirebaseMessaging get messaging => _messaging;

  /// Initialize Firebase services
  Future<void> initialize() async {
    try {
      _devLog('Initializing Firebase with current platform options...');
      
      // Check if Firebase is already initialized
      if (Firebase.apps.isNotEmpty) {
        _app = Firebase.app();
        _devLog('Firebase app already initialized: ${_app.name}');
      } else {
        // No apps exist, initialize new one
        _devLog('No existing Firebase app found, initializing new one...');
        _app = await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _devLog('Firebase app initialized: ${_app.name}');
      }

      // Initialize Firebase services (using default instances)
      _devLog('Initializing Firebase Auth...');
      _auth = FirebaseAuth.instance;
      
      _devLog('Initializing Firestore...');
      _firestore = FirebaseFirestore.instance;
      
      _devLog('Initializing Firebase Analytics...');
      _analytics = FirebaseAnalytics.instance;
      
      _devLog('Initializing Firebase Crashlytics...');
      _crashlytics = FirebaseCrashlytics.instance;
      
      _devLog('Initializing Firebase Messaging...');
      _messaging = FirebaseMessaging.instance;

      // Configure Firestore settings
      _devLog('Configuring Firestore settings...');
      if (kDebugMode) {
        _firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } else {
        _firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: 100 * 1024 * 1024, // 100 MB
        );
      }

      // Configure Crashlytics
      _devLog('Configuring Crashlytics...');
      if (kDebugMode) {
        await _crashlytics.setCrashlyticsCollectionEnabled(false);
      } else {
        await _crashlytics.setCrashlyticsCollectionEnabled(true);
      }

      // Configure messaging permissions
      _devLog('Configuring messaging...');
      await _configureMessaging();

      _devLog('Firebase initialized successfully');
    } catch (e, stackTrace) {
      _devLog('Failed to initialize Firebase: $e');
      _devLog('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Configure Firebase Cloud Messaging
  Future<void> _configureMessaging() async {
    try {
      // Set foreground notification presentation options (iOS)
      if (Platform.isIOS) {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          sound: true,
        );
        _devLog('iOS foreground notification options configured');
      }

      // Request permission for notifications
      final settings = await _messaging.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _devLog('User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        _devLog('User granted provisional notification permission');
      } else {
        _devLog(
          'User declined notification permission: '
          '${settings.authorizationStatus}',
        );
      }

      // Get APNs token (iOS only) - required for remote notifications
      var hasApnsToken = false;
      if (Platform.isIOS) {
        try {
          final apnsToken = await _messaging.getAPNSToken();
          if (apnsToken != null) {
            _devLog('APNs Token obtained: ${apnsToken.substring(0, 20)}...');
            hasApnsToken = true;
          } else {
            _devLog(
              'APNs Token: null - This is expected if:\n'
              '  - Running on iOS Simulator (APNs not available)\n'
              '  - No Apple Developer account configured\n'
              '  - APNs certificates/keys not uploaded to Firebase\n'
              'Local notifications will work, '
              'but remote notifications require APNs configuration.',
            );
          }
        } on Exception catch (e) {
          _devLog('Error getting APNs token: $e');
        }
      }

      // Get FCM token
      // Note: On iOS, FCM token requires APNs token to be available
      try {
        final token = await _messaging.getToken();
        if (token != null) {
          _devLog('FCM Token: ${token.substring(0, 20)}...');
          // Implement later - Send token to Firestore devices (Step 0.4)
        } else {
          _devLog('FCM Token: null');
        }
      } on Exception catch (e) {
        if (Platform.isIOS && !hasApnsToken) {
          _devLog(
            'FCM Token unavailable (APNs token required on iOS). '
            'This is expected without Apple Developer account setup.',
          );
        } else {
          _devLog('Error getting FCM token: $e');
        }
      }

      _devLog('Firebase Messaging configured successfully');
    } on Exception catch (e) {
      _devLog('Failed to configure messaging: $e');
      // Don't rethrow - messaging failure shouldn't block app initialization
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Log messages only in development flavor
  void _devLog(String message) {
    if (FlavorConfig.isDevelopment) {
      debugPrint('[Firebase Dev] $message');
    }
  }
}
