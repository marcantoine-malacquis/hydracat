import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hydracat/core/config/flavor_config.dart';
import 'package:hydracat/features/notifications/models/device_token.dart';
import 'package:hydracat/shared/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Service for managing device token registration and FCM token updates.
///
/// Handles:
/// - Stable device ID generation and persistence
/// - Device registration in Firestore on sign-in
/// - FCM token refresh handling
/// - Throttled lastUsedAt updates (once per 24h)
/// - Device unregistration on sign-out
///
/// This service enables future push notification features while respecting
/// Firebase cost optimization rules (minimal writes, throttled updates).
class DeviceTokenService {
  /// Factory constructor to get the singleton instance
  factory DeviceTokenService() => _instance ??= DeviceTokenService._();

  /// Private constructor
  DeviceTokenService._();

  static DeviceTokenService? _instance;

  // Storage keys
  static const String _deviceIdKey = 'device_id_v1';
  static const String _lastTokenKeyPrefix = 'notif_device_last_token_';
  static const String _lastRegistrationKeyPrefix =
      'notif_device_last_registration_';

  // Throttle duration for device registration (6 hours)
  // Prevents excessive Firestore writes while ensuring regular updates
  static const Duration _registrationThrottle = Duration(hours: 6);

  // Secure storage for device ID
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Firebase instances
  FirebaseFirestore get _firestore => FirebaseService().firestore;
  FirebaseMessaging get _messaging => FirebaseService().messaging;
  FirebaseCrashlytics get _crashlytics => FirebaseService().crashlytics;

  // Token refresh subscription
  StreamSubscription<String>? _tokenRefreshSubscription;

  // In-memory cache of current user ID
  String? _currentUserId;

  /// Gets or creates a stable device ID.
  ///
  /// The device ID is generated once per app installation and persisted
  /// in secure storage. This ID remains stable across app restarts but
  /// changes on app reinstall (as secure storage is cleared).
  ///
  /// Returns a UUID v4 string.
  Future<String> getOrCreateDeviceId() async {
    try {
      // Try to read existing device ID from secure storage
      final existingId = await _secureStorage.read(key: _deviceIdKey);

      if (existingId != null && existingId.isNotEmpty) {
        _devLog('Using existing device ID: ${existingId.substring(0, 8)}...');
        return existingId;
      }

      // Generate new UUID v4
      const uuid = Uuid();
      final newId = uuid.v4();

      // Persist to secure storage
      await _secureStorage.write(key: _deviceIdKey, value: newId);

      _devLog('Generated new device ID: ${newId.substring(0, 8)}...');
      return newId;
    } on Exception catch (e, stackTrace) {
      _devLog('ERROR: Failed to get/create device ID: $e');

      // Report to Crashlytics in production
      if (!kDebugMode) {
        await _crashlytics.recordError(
          e,
          stackTrace,
          reason: 'Failed to get/create device ID',
        );
      }

      // Fallback: generate temporary ID (not persisted)
      const uuid = Uuid();
      final tempId = uuid.v4();
      _devLog('Using temporary device ID (not persisted): '
          '${tempId.substring(0, 8)}...');
      return tempId;
    }
  }

  /// Registers the current device in Firestore.
  ///
  /// Called on sign-in and when FCM token refreshes. Updates or creates
  /// the device document in Firestore with current user ID, FCM token,
  /// platform, and timestamps.
  ///
  /// Optimizations:
  /// - Skips Firestore write if token unchanged (cost optimization)
  /// - Gracefully handles missing FCM token (iOS simulator, APNs issues)
  /// - Non-blocking errors (logs but doesn't throw)
  Future<void> registerDevice(String userId) async {
    try {
      _currentUserId = userId;

      // Get device ID
      final deviceId = await getOrCreateDeviceId();

      // Get FCM token (may be null on iOS without APNs)
      String? fcmToken;
      try {
        fcmToken = await _messaging.getToken();
      } on Exception catch (e) {
        _devLog('Warning: Failed to get FCM token: $e');
        // Continue with null token - device will still be registered
      }

      // Check if we should throttle this registration
      final prefs = await SharedPreferences.getInstance();
      final lastRegistrationKey = '$_lastRegistrationKeyPrefix$deviceId';
      final lastRegistrationStr = prefs.getString(lastRegistrationKey);
      final lastTokenKey = '$_lastTokenKeyPrefix$deviceId';
      final lastToken = prefs.getString(lastTokenKey);

      // Session-based throttling: don't register multiple times in 6 hours
      if (lastRegistrationStr != null) {
        final lastRegistration = DateTime.parse(lastRegistrationStr);
        final timeSinceRegistration =
            DateTime.now().difference(lastRegistration);

        if (timeSinceRegistration < _registrationThrottle) {
          // Check if token actually changed (force registration)
          final tokenToCompare = fcmToken ?? '';
          final lastTokenCompare = lastToken ?? '';
          final tokenChanged = tokenToCompare != lastTokenCompare;

          if (!tokenChanged) {
            final minutes = timeSinceRegistration.inMinutes;
            _devLog(
              'Registration throttled (${minutes}min since last registration)',
            );
            return;
          } else {
            _devLog(
              'FCM token changed, forcing registration despite throttle',
            );
          }
        }
      }

      // Get platform info
      final platform = Platform.isIOS ? 'ios' : 'android';

      // Create device token model
      final deviceToken = DeviceToken(
        deviceId: deviceId,
        platform: platform,
        lastUsedAt: DateTime.now(),
        createdAt: DateTime.now(),
        userId: userId,
        fcmToken: fcmToken,
      );

      // Upsert to Firestore devices collection
      _devLog('Registering device in Firestore...');
      _devLog('  Device ID: ${deviceId.substring(0, 8)}...');
      _devLog('  User ID: ${userId.substring(0, 8)}...');
      _devLog('  Platform: $platform');
      final tokenDisplay =
          fcmToken != null ? '${fcmToken.substring(0, 20)}...' : 'null';
      _devLog('  FCM Token: $tokenDisplay');

      final isUpdate = lastToken != null && lastToken.isNotEmpty;
      await _firestore
          .collection('devices')
          .doc(deviceId)
          .set(
            deviceToken.toFirestore(isUpdate: isUpdate),
            SetOptions(merge: true),
          );

      // Store last token for future comparison
      final tokenToStore = fcmToken ?? '';
      await prefs.setString(lastTokenKey, tokenToStore);

      // Update registration timestamp (session throttle)
      await prefs.setString(
        lastRegistrationKey,
        DateTime.now().toIso8601String(),
      );

      _devLog('Device registered successfully');
    } on Exception catch (e, stackTrace) {
      _devLog('ERROR: Failed to register device: $e');

      // Report to Crashlytics in production
      if (!kDebugMode) {
        await _crashlytics.recordError(
          e,
          stackTrace,
          reason: 'Failed to register device',
          information: ['userId: $userId'],
        );
      }

      // Don't throw - registration failure shouldn't block sign-in
    }
  }


  /// Unregisters the current device on sign-out.
  ///
  /// Clears the userId from the device document but keeps the device
  /// record for analytics and debugging purposes.
  Future<void> unregisterDevice() async {
    try {
      final deviceId = await getOrCreateDeviceId();

      _devLog('Unregistering device on sign-out...');
      _devLog('  Device ID: ${deviceId.substring(0, 8)}...');

      // Clear userId but keep device record
      await _firestore.collection('devices').doc(deviceId).update({
        'userId': null,
        'lastUsedAt': FieldValue.serverTimestamp(),
      });

      // Clear in-memory user ID
      _currentUserId = null;

      _devLog('Device unregistered successfully');
    } on Exception catch (e, stackTrace) {
      _devLog('Warning: Failed to unregister device: $e');

      // Report to Crashlytics in production
      if (!kDebugMode) {
        await _crashlytics.recordError(
          e,
          stackTrace,
          reason: 'Failed to unregister device',
        );
      }

      // Don't throw - unregistration failure shouldn't block sign-out
    }
  }

  /// Starts listening to FCM token refresh events.
  ///
  /// Should be called once during app initialization (in FirebaseService).
  /// Automatically re-registers device when FCM token changes.
  void listenToTokenRefresh() {
    // Cancel existing subscription if any
    _tokenRefreshSubscription?.cancel();

    _devLog('Starting FCM token refresh listener...');

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (newToken) async {
        _devLog('FCM token refreshed: ${newToken.substring(0, 20)}...');

        // Only register if user is authenticated
        if (_currentUserId != null) {
          _devLog('Re-registering device with new token...');
          await registerDevice(_currentUserId!);
        } else {
          _devLog(
            'Skipping device registration (no authenticated user)',
          );
        }
      },
      onError: (Object error) {
        _devLog('Error in token refresh listener: $error');

        // Report to Crashlytics in production
        if (!kDebugMode) {
          _crashlytics.recordError(
            error,
            StackTrace.current,
            reason: 'FCM token refresh listener error',
          );
        }
      },
    );

    _devLog('FCM token refresh listener started');
  }

  /// Stops listening to FCM token refresh events.
  ///
  /// Called when service is disposed (rarely needed).
  void stopListeningToTokenRefresh() {
    _devLog('Stopping FCM token refresh listener...');
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _devLog('FCM token refresh listener stopped');
  }

  /// Logs messages only in development flavor.
  void _devLog(String message) {
    if (FlavorConfig.isDevelopment) {
      debugPrint('[DeviceToken Dev] $message');
    }
  }

  /// Disposes resources (for testing purposes).
  void dispose() {
    stopListeningToTokenRefresh();
    _currentUserId = null;
  }
}
