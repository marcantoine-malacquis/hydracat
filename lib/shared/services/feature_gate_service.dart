import 'package:firebase_auth/firebase_auth.dart';

/// Service to check feature access based on user verification status
class FeatureGateService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if current user can access premium features
  static bool canAccessPremiumFeatures() {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  /// Check if current user can access verification-gated features
  static bool canAccessVerifiedFeatures() {
    return canAccessPremiumFeatures();
  }

  /// Check if current user can access expensive operations
  static bool canAccessExpensiveOperations() {
    return canAccessPremiumFeatures();
  }

  /// Get user verification status
  static bool get isUserVerified {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  /// Check if user is authenticated (regardless of verification)
  static bool get isUserAuthenticated {
    return _auth.currentUser != null;
  }

  /// Features that require email verification
  static const List<String> verifiedOnlyFeatures = [
    'pdf_export',
    'advanced_analytics',
    'detailed_reports',
    'cloud_sync_premium',
    'export_data',
    'premium_insights',
  ];

  /// Features available to unverified users
  static const List<String> freeFeatures = [
    'fluid_logging',
    'reminders',
    'basic_streak_tracking',
    'session_history',
    'offline_logging',
    'basic_analytics',
  ];

  /// Check if specific feature is accessible
  static bool canAccessFeature(String featureId) {
    if (freeFeatures.contains(featureId)) {
      return isUserAuthenticated;
    }

    if (verifiedOnlyFeatures.contains(featureId)) {
      return canAccessPremiumFeatures();
    }

    // Default to requiring authentication only
    return isUserAuthenticated;
  }

  /// Get reason why feature is blocked (for user messaging)
  static String? getBlockedReason(String featureId) {
    if (!isUserAuthenticated) {
      return 'Please sign in to access this feature.';
    }

    if (verifiedOnlyFeatures.contains(featureId) && !isUserVerified) {
      return 'Verify your email to access premium features and '
          'protect your data.';
    }

    return null; // Feature is accessible
  }
}
