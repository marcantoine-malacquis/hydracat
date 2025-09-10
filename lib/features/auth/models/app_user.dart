import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Enumeration of authentication provider types
enum AuthProvider {
  /// Email and password authentication
  email,

  /// Google Sign-In authentication
  google,

  /// Apple Sign-In authentication (iOS only)
  apple,

  /// Anonymous authentication
  anonymous,
}

/// Core user model that represents an authenticated user in the HydraCat app
@immutable
class AppUser {
  /// Creates an [AppUser] instance
  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoURL,
    this.emailVerified = false,
    this.provider = AuthProvider.email,
    this.createdAt,
    this.lastSignInAt,
    this.hasCompletedOnboarding = false,
    this.primaryPetId,
  });

  /// Creates an [AppUser] from JSON data
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      provider: AuthProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => AuthProvider.email,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastSignInAt: json['lastSignInAt'] != null
          ? DateTime.parse(json['lastSignInAt'] as String)
          : null,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      primaryPetId: json['primaryPetId'] as String?,
    );
  }

  /// Creates an [AppUser] from a Firebase [User] object
  factory AppUser.fromFirebaseUser(User firebaseUser) {
    var provider = AuthProvider.email;

    for (final providerData in firebaseUser.providerData) {
      switch (providerData.providerId) {
        case 'google.com':
          provider = AuthProvider.google;
        case 'apple.com':
          provider = AuthProvider.apple;
        case 'password':
          provider = AuthProvider.email;
        case 'anonymous':
          provider = AuthProvider.anonymous;
      }
    }

    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      emailVerified: firebaseUser.emailVerified,
      provider: provider,
      createdAt: firebaseUser.metadata.creationTime,
      lastSignInAt: firebaseUser.metadata.lastSignInTime,
    );
  }

  /// Unique user identifier from Firebase Auth
  final String id;

  /// User's email address
  final String? email;

  /// User's display name
  final String? displayName;

  /// URL to the user's profile photo
  final String? photoURL;

  /// Whether the user's email has been verified
  final bool emailVerified;

  /// The authentication provider used to sign in
  final AuthProvider provider;

  /// Timestamp when the user was created
  final DateTime? createdAt;

  /// Timestamp when the user last signed in
  final DateTime? lastSignInAt;

  /// Whether the user has completed the onboarding flow
  final bool hasCompletedOnboarding;

  /// ID of the user's primary pet profile
  final String? primaryPetId;

  /// Converts [AppUser] to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'provider': provider.name,
      'createdAt': createdAt?.toIso8601String(),
      'lastSignInAt': lastSignInAt?.toIso8601String(),
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'primaryPetId': primaryPetId,
    };
  }

  /// Creates a copy of this [AppUser] with the given fields replaced
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    bool? emailVerified,
    AuthProvider? provider,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    bool? hasCompletedOnboarding,
    String? primaryPetId,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      hasCompletedOnboarding: hasCompletedOnboarding ?? 
          this.hasCompletedOnboarding,
      primaryPetId: primaryPetId ?? this.primaryPetId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppUser &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoURL == photoURL &&
        other.emailVerified == emailVerified &&
        other.provider == provider &&
        other.createdAt == createdAt &&
        other.lastSignInAt == lastSignInAt &&
        other.hasCompletedOnboarding == hasCompletedOnboarding &&
        other.primaryPetId == primaryPetId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      displayName,
      photoURL,
      emailVerified,
      provider,
      createdAt,
      lastSignInAt,
      hasCompletedOnboarding,
      primaryPetId,
    );
  }

  @override
  String toString() {
    return 'AppUser('
        'id: $id, '
        'email: $email, '
        'displayName: $displayName, '
        'photoURL: $photoURL, '
        'emailVerified: $emailVerified, '
        'provider: $provider, '
        'createdAt: $createdAt, '
        'lastSignInAt: $lastSignInAt, '
        'hasCompletedOnboarding: $hasCompletedOnboarding, '
        'primaryPetId: $primaryPetId'
        ')';
  }
}
