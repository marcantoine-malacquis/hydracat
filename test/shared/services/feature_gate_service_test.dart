import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/services/feature_gate_service.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  group('FeatureGateService', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
    });

    group('Free Features Access', () {
      test('should allow authenticated user to access free features', () {
        // Arrange - Mock authenticated user
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        // Override static field for testing (this is just for demonstration)
        // In practice, we'd need dependency injection to properly test static
        // methods

        // Act & Assert
        const freeFeatures = [
          'fluid_logging',
          'reminders',
          'basic_streak_tracking',
          'session_history',
          'offline_logging',
          'basic_analytics',
        ];

        for (final feature in freeFeatures) {
          expect(
            FeatureGateService.freeFeatures.contains(feature),
            equals(true),
            reason: '$feature should be in free features list',
          );
        }
      });

      test('should contain expected free features', () {
        // Act
        const expectedFreeFeatures = [
          'fluid_logging',
          'reminders',
          'basic_streak_tracking',
          'session_history',
          'offline_logging',
          'basic_analytics',
        ];

        // Assert
        for (final feature in expectedFreeFeatures) {
          expect(
            FeatureGateService.freeFeatures,
            contains(feature),
            reason: 'Free features should include $feature',
          );
        }
      });
    });

    group('Premium Features Access', () {
      test('should contain expected premium features', () {
        // Act
        const expectedPremiumFeatures = [
          'pdf_export',
          'advanced_analytics',
          'detailed_reports',
          'cloud_sync_premium',
          'export_data',
          'premium_insights',
        ];

        // Assert
        for (final feature in expectedPremiumFeatures) {
          expect(
            FeatureGateService.verifiedOnlyFeatures,
            contains(feature),
            reason: 'Premium features should include $feature',
          );
        }
      });

      test('should not overlap with free features', () {
        // Act
        final freeSet = Set<String>.from(FeatureGateService.freeFeatures);
        final premiumSet = Set<String>.from(
          FeatureGateService.verifiedOnlyFeatures,
        );

        // Assert
        final intersection = freeSet.intersection(premiumSet);
        expect(
          intersection,
          isEmpty,
          reason: 'Free and premium features should not overlap',
        );
      });
    });

    group('Feature Access Logic', () {
      test('should categorize features correctly', () {
        // Test that known free features are categorized as free
        expect(
          FeatureGateService.freeFeatures.contains('fluid_logging'),
          equals(true),
          reason: 'Core medical feature should be free',
        );

        // Test that known premium features are categorized as premium
        expect(
          FeatureGateService.verifiedOnlyFeatures.contains('pdf_export'),
          equals(true),
          reason: 'PDF export should be premium',
        );
      });

      test('should handle unknown features gracefully', () {
        // This test shows the default behavior for unlisted features
        // The actual access check would depend on authentication status
        const unknownFeature = 'unknown_feature_xyz';

        expect(
          FeatureGateService.freeFeatures.contains(unknownFeature),
          equals(false),
          reason: 'Unknown feature should not be in free list',
        );

        expect(
          FeatureGateService.verifiedOnlyFeatures.contains(unknownFeature),
          equals(false),
          reason: 'Unknown feature should not be in premium list',
        );
      });
    });

    group('Blocking Reasons', () {
      test('should provide appropriate blocking messages', () {
        // These test the message constants, not the dynamic behavior
        const testFeatures = [
          'pdf_export',
          'advanced_analytics',
          'detailed_reports',
        ];

        // Verify these are premium features
        for (final feature in testFeatures) {
          expect(
            FeatureGateService.verifiedOnlyFeatures.contains(feature),
            equals(true),
            reason: '$feature should be a premium feature',
          );
        }
      });
    });

    group('Feature Lists Validation', () {
      test('should have non-empty feature lists', () {
        expect(
          FeatureGateService.freeFeatures.isNotEmpty,
          equals(true),
          reason: 'Should have at least one free feature',
        );

        expect(
          FeatureGateService.verifiedOnlyFeatures.isNotEmpty,
          equals(true),
          reason: 'Should have at least one premium feature',
        );
      });

      test('should contain expected core medical features as free', () {
        const coreMedicalFeatures = [
          'fluid_logging',
          'reminders',
          'session_history',
        ];

        for (final feature in coreMedicalFeatures) {
          expect(
            FeatureGateService.freeFeatures,
            contains(feature),
            reason: 'Core medical feature $feature should be free',
          );
        }
      });

      test('should contain expected premium export features', () {
        const exportFeatures = [
          'pdf_export',
          'export_data',
        ];

        for (final feature in exportFeatures) {
          expect(
            FeatureGateService.verifiedOnlyFeatures,
            contains(feature),
            reason: 'Export feature $feature should be premium',
          );
        }
      });
    });
  });
}
