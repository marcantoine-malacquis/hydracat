import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';

void main() {
  group('Authentication Models Tests', () {
    group('AppUser', () {
      test('should create AppUser with required fields', () {
        const user = AppUser(
          id: 'test-id',
          email: 'test@example.com',
          emailVerified: true,
        );

        expect(user.id, 'test-id');
        expect(user.email, 'test@example.com');
        expect(user.emailVerified, true);
        expect(user.provider, AuthProvider.email); // Default value
      });

      test('should serialize to and from JSON', () {
        const user = AppUser(
          id: 'test-id',
          email: 'test@example.com',
          displayName: 'Test User',
          emailVerified: true,
          provider: AuthProvider.google,
        );

        // Test toJson
        final json = user.toJson();
        expect(json['id'], 'test-id');
        expect(json['email'], 'test@example.com');
        expect(json['displayName'], 'Test User');
        expect(json['emailVerified'], true);
        expect(json['provider'], 'google');

        // Test fromJson
        final userFromJson = AppUser.fromJson(json);
        expect(userFromJson.id, user.id);
        expect(userFromJson.email, user.email);
        expect(userFromJson.displayName, user.displayName);
        expect(userFromJson.emailVerified, user.emailVerified);
        expect(userFromJson.provider, user.provider);
      });

      test('should support copyWith functionality', () {
        const user = AppUser(
          id: 'test-id',
          email: 'test@example.com',
        );

        final updatedUser = user.copyWith(
          displayName: 'Updated Name',
          emailVerified: true,
        );

        expect(updatedUser.id, user.id); // Should remain the same
        expect(updatedUser.email, user.email); // Should remain the same
        expect(updatedUser.displayName, 'Updated Name'); // Should be updated
        expect(updatedUser.emailVerified, true); // Should be updated
      });

      test('should handle DateTime serialization correctly', () {
        final now = DateTime.now();
        final user = AppUser(
          id: 'test-id',
          email: 'test@example.com',
          createdAt: now,
          lastSignInAt: now,
        );

        final json = user.toJson();
        final userFromJson = AppUser.fromJson(json);

        expect(userFromJson.createdAt, isNotNull);
        expect(userFromJson.lastSignInAt, isNotNull);
        // Note: DateTime precision might differ slightly in JSON serialization
      });

      test('should handle equality correctly', () {
        const user1 = AppUser(
          id: 'test-id',
          email: 'test@example.com',
        );

        const user2 = AppUser(
          id: 'test-id',
          email: 'test@example.com',
        );

        const user3 = AppUser(
          id: 'different-id',
          email: 'test@example.com',
        );

        expect(user1, equals(user2));
        expect(user1, isNot(equals(user3)));
        expect(user1.hashCode, equals(user2.hashCode));
      });
    });

    group('AuthState', () {
      test('should create loading state', () {
        const state = AuthStateLoading();

        expect(state.isLoading, true);
        expect(state.isAuthenticated, false);
        expect(state.isUnauthenticated, false);
        expect(state.hasError, false);
        expect(state.user, null);
      });

      test('should create unauthenticated state', () {
        const state = AuthStateUnauthenticated();

        expect(state.isUnauthenticated, true);
        expect(state.isLoading, false);
        expect(state.isAuthenticated, false);
        expect(state.hasError, false);
        expect(state.user, null);
      });

      test('should create authenticated state', () {
        const user = AppUser(id: 'test-id', email: 'test@example.com');
        const state = AuthStateAuthenticated(user: user);

        expect(state.isAuthenticated, true);
        expect(state.isLoading, false);
        expect(state.isUnauthenticated, false);
        expect(state.hasError, false);
        expect(state.user, user);
      });

      test('should create error state', () {
        const state = AuthStateError(message: 'Test error', code: 'TEST_001');

        expect(state.hasError, true);
        expect(state.isAuthenticated, false);
        expect(state.isLoading, false);
        expect(state.isUnauthenticated, false);
        expect(state.errorMessage, 'Test error');
        expect(state.errorCode, 'TEST_001');
      });

      test('should serialize to and from JSON', () {
        const user = AppUser(id: 'test-id', email: 'test@example.com');
        const state = AuthStateAuthenticated(user: user);

        // Test toJson
        final json = state.toJson();
        expect(json['type'], 'authenticated');
        expect(json['user'], isA<Map<String, dynamic>>());

        // Test fromJson
        final stateFromJson = AuthState.fromJson(json);
        expect(stateFromJson.isAuthenticated, true);
        expect(stateFromJson.user?.id, user.id);
      });

      test('should support pattern matching with when', () {
        const errorState = AuthStateError(message: 'Test error');

        final result = errorState.when(
          loading: () => 'loading',
          unauthenticated: () => 'unauthenticated',
          authenticated: (user) => 'authenticated with ${user.id}',
          error: (message, code, details) => 'error: $message',
        );

        expect(result, 'error: Test error');
      });

      test('should support pattern matching with maybeWhen', () {
        const loadingState = AuthStateLoading();

        final result = loadingState.maybeWhen(
          loading: () => 'is loading',
          orElse: () => 'something else',
        );

        expect(result, 'is loading');

        // Test orElse case
        const user = AppUser(id: 'test-id', email: 'test@example.com');
        const authState = AuthStateAuthenticated(user: user);

        final orElseResult = authState.maybeWhen(
          loading: () => 'is loading',
          orElse: () => 'something else',
        );

        expect(orElseResult, 'something else');
      });

      test('should handle JSON serialization for all state types', () {
        // Test loading state
        const loadingState = AuthStateLoading();
        final loadingJson = loadingState.toJson();
        final loadingFromJson = AuthState.fromJson(loadingJson);
        expect(loadingFromJson, isA<AuthStateLoading>());

        // Test unauthenticated state
        const unauthState = AuthStateUnauthenticated();
        final unauthJson = unauthState.toJson();
        final unauthFromJson = AuthState.fromJson(unauthJson);
        expect(unauthFromJson, isA<AuthStateUnauthenticated>());

        // Test error state
        const errorState = AuthStateError(
          message: 'Test error',
          code: 'ERR001',
        );
        final errorJson = errorState.toJson();
        final errorFromJson = AuthState.fromJson(errorJson) as AuthStateError;
        expect(errorFromJson.message, 'Test error');
        expect(errorFromJson.code, 'ERR001');
      });
    });
  });
}
