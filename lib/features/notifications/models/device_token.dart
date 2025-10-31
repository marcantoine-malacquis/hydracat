import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Model representing a device registration for push notifications.
///
/// Each device gets a stable UUID that persists across app reinstalls
/// (stored in secure storage). The device document in Firestore tracks
/// the current user, FCM token, platform, and last activity.
///
/// Used for:
/// - FCM token management
/// - Multi-device support (future V2)
/// - Analytics and debugging
@immutable
class DeviceToken {
  /// Creates a [DeviceToken] instance
  const DeviceToken({
    required this.deviceId,
    required this.platform,
    required this.lastUsedAt,
    required this.createdAt,
    this.userId,
    this.fcmToken,
  });

  /// Unique stable device identifier (UUID v4)
  ///
  /// Generated once per device install and persisted in secure storage.
  /// This ID never changes for a device installation.
  final String deviceId;

  /// Current authenticated user ID
  ///
  /// Null if device is not associated with a user (after sign-out).
  /// Updated on sign-in and cleared on sign-out.
  final String? userId;

  /// Firebase Cloud Messaging token
  ///
  /// Nullable because:
  /// - May not be available on iOS without APNs configuration
  /// - May be temporarily unavailable during token refresh
  /// - May be null on iOS simulator
  final String? fcmToken;

  /// Device platform ('ios' or 'android')
  ///
  /// Used for platform-specific push notification handling (future).
  final String platform;

  /// Last time this device was actively used
  ///
  /// Updated on sign-in and throttled to once per 24 hours to
  /// minimize Firestore write costs.
  final DateTime lastUsedAt;

  /// When this device was first registered
  ///
  /// Set once when device document is created, never updated.
  final DateTime createdAt;

  /// Creates a copy of this device token with updated fields
  DeviceToken copyWith({
    String? deviceId,
    String? userId,
    String? fcmToken,
    String? platform,
    DateTime? lastUsedAt,
    DateTime? createdAt,
  }) {
    return DeviceToken(
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      fcmToken: fcmToken ?? this.fcmToken,
      platform: platform ?? this.platform,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts this device token to a Firestore-compatible map
  ///
  /// Uses FieldValue.serverTimestamp() for timestamp fields to ensure
  /// server-side consistency and avoid client clock skew issues.
  Map<String, dynamic> toFirestore({bool isUpdate = false}) {
    final tokenData = <String, dynamic>{
      'deviceId': deviceId,
      'userId': userId,
      'fcmToken': fcmToken,
      'platform': platform,
      'lastUsedAt': FieldValue.serverTimestamp(),
    };

    // Only set createdAt on initial creation, not on updates
    if (!isUpdate) {
      tokenData['createdAt'] = FieldValue.serverTimestamp();
    }

    return tokenData;
  }

  /// Creates a device token from a Firestore document snapshot
  ///
  /// Returns null if the document doesn't exist or is missing required fields.
  static DeviceToken? fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      return null;
    }

    final tokenData = doc.data() as Map<String, dynamic>?;
    if (tokenData == null) {
      return null;
    }

    // Required fields - return null if missing
    final deviceId = tokenData['deviceId'] as String?;
    final platform = tokenData['platform'] as String?;

    if (deviceId == null || platform == null) {
      return null;
    }

    // Parse timestamps with fallback to current time
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      return DateTime.now();
    }

    return DeviceToken(
      deviceId: deviceId,
      userId: tokenData['userId'] as String?,
      fcmToken: tokenData['fcmToken'] as String?,
      platform: platform,
      lastUsedAt: parseTimestamp(tokenData['lastUsedAt']),
      createdAt: parseTimestamp(tokenData['createdAt']),
    );
  }

  @override
  String toString() {
    final tokenDisplay =
        fcmToken != null ? '${fcmToken!.substring(0, 20)}...' : 'null';
    return 'DeviceToken('
        'deviceId: $deviceId, '
        'userId: $userId, '
        'fcmToken: $tokenDisplay, '
        'platform: $platform, '
        'lastUsedAt: $lastUsedAt, '
        'createdAt: $createdAt'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeviceToken &&
        other.deviceId == deviceId &&
        other.userId == userId &&
        other.fcmToken == fcmToken &&
        other.platform == platform &&
        other.lastUsedAt == lastUsedAt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      deviceId,
      userId,
      fcmToken,
      platform,
      lastUsedAt,
      createdAt,
    );
  }
}
