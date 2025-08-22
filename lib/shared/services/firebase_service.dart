import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hydracat/firebase_options.dart';
import 'package:hydracat/shared/services/mcp_service.dart';

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
  late MCPService _mcpService;

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
      // Initialize Firebase Core
      _app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Firebase services
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;
      _messaging = FirebaseMessaging.instance;

      // Initialize MCP service only on supported platforms (desktop/web)
      _mcpService = MCPService();
      if (kIsWeb) {
        try {
          await _mcpService.initialize();
          debugPrint('MCP service initialized successfully');
        } on Exception catch (e) {
          debugPrint(
            'MCP service initialization failed (this is normal on mobile): $e',
          );
        }
      } else {
        debugPrint('MCP service not available on this platform');
      }

      // Configure Firestore settings
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
      if (kDebugMode) {
        await _crashlytics.setCrashlyticsCollectionEnabled(false);
      } else {
        await _crashlytics.setCrashlyticsCollectionEnabled(true);
      }

      // Configure messaging permissions
      await _configureMessaging();

      debugPrint('Firebase and MCP services initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Firebase services: $e');
      rethrow;
    }
  }

  /// Configure Firebase Cloud Messaging
  Future<void> _configureMessaging() async {
    try {
      // Request permission for notifications
      final settings = await _messaging.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
      } else {
        debugPrint('User declined notification permission');
      }

      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        // TODO(me): Send token to server
      }
    } on Exception catch (e) {
      debugPrint('Failed to configure messaging: $e');
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get MCP service instance
  MCPService get mcp => _mcpService;
}
