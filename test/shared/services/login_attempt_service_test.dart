import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/models/login_attempt_data.dart';
import 'package:hydracat/shared/services/login_attempt_service.dart';
import 'package:hydracat/shared/services/secure_preferences_service.dart';
import 'package:mocktail/mocktail.dart';

class MockSecurePreferencesService extends Mock
    implements SecurePreferencesService {}

void main() {
  group('LoginAttemptService', () {
    late MockSecurePreferencesService mockSecureStorage;
    late LoginAttemptService loginAttemptService;
    const testEmail = 'test@example.com';

    setUp(() {
      mockSecureStorage = MockSecurePreferencesService();
      loginAttemptService = LoginAttemptService(
        secureStorage: mockSecureStorage,
      );
    });

    group('isAccountLockedOut', () {
      test('returns false when no attempt data exists', () async {
        when(
          () => mockSecureStorage.getSecureData(any()),
        ).thenAnswer((_) async => null);

        final result = await loginAttemptService.isAccountLockedOut(testEmail);

        expect(result, false);
      });

      test('returns true when account is locked out', () async {
        final lockoutTime = DateTime.now().add(const Duration(minutes: 5));
        final attemptData = LoginAttemptData(
          email: testEmail,
          failedAttempts: BruteForceConfig.maxAttempts,
          firstFailureTime: DateTime.now().subtract(const Duration(minutes: 1)),
          lockoutUntil: lockoutTime,
        );

        when(
          () => mockSecureStorage.getSecureData(any()),
        ).thenAnswer((_) async => attemptData.toJson());

        final result = await loginAttemptService.isAccountLockedOut(testEmail);

        expect(result, true);
      });

      test('returns false when data has expired (24+ hours old)', () async {
        final attemptData = LoginAttemptData(
          email: testEmail,
          failedAttempts: BruteForceConfig.maxAttempts,
          // Make firstFailureTime older than 24 hours to trigger hasExpired
          firstFailureTime: DateTime.now().subtract(const Duration(hours: 25)),
          lockoutUntil: DateTime.now().add(const Duration(minutes: 5)),
        );

        when(
          () => mockSecureStorage.getSecureData(any()),
        ).thenAnswer((_) async => attemptData.toJson());
        when(
          () => mockSecureStorage.removeSecureData(any()),
        ).thenAnswer((_) async {});

        final result = await loginAttemptService.isAccountLockedOut(testEmail);

        expect(result, false);
        // Verify that expired data is cleaned up
        verify(
          () => mockSecureStorage.removeSecureData(
            'login_attempts_test@example.com',
          ),
        ).called(1);
      });

      test(
        'returns false when lockout has expired but data is not expired',
        () async {
          final expiredLockoutTime = DateTime.now().subtract(
            const Duration(minutes: 1),
          );
          final attemptData = LoginAttemptData(
            email: testEmail,
            failedAttempts: BruteForceConfig.maxAttempts,
            firstFailureTime: DateTime.now().subtract(const Duration(hours: 1)),
            lockoutUntil: expiredLockoutTime,
          );

          when(
            () => mockSecureStorage.getSecureData(any()),
          ).thenAnswer((_) async => attemptData.toJson());

          final result = await loginAttemptService.isAccountLockedOut(
            testEmail,
          );

          expect(result, false);
        },
      );
    });

    group('recordFailedAttempt', () {
      test('creates new attempt data for first failure', () async {
        when(
          () => mockSecureStorage.getSecureData(any()),
        ).thenAnswer((_) async => null);
        when(
          () => mockSecureStorage.setSecureData(any(), any()),
        ).thenAnswer((_) async {});

        final result = await loginAttemptService.recordFailedAttempt(testEmail);

        expect(result.email, testEmail);
        expect(result.failedAttempts, 1);
        expect(result.isLockedOut, false);
        verify(() => mockSecureStorage.setSecureData(any(), any())).called(1);
      });

      test('increments attempt count for existing data', () async {
        final existingData = LoginAttemptData(
          email: testEmail,
          failedAttempts: 2,
          firstFailureTime: DateTime.now().subtract(
            const Duration(minutes: 10),
          ),
        );

        when(
          () => mockSecureStorage.getSecureData(any()),
        ).thenAnswer((_) async => existingData.toJson());
        when(
          () => mockSecureStorage.setSecureData(any(), any()),
        ).thenAnswer((_) async {});

        final result = await loginAttemptService.recordFailedAttempt(testEmail);

        expect(result.email, testEmail);
        expect(result.failedAttempts, 3);
        expect(result.isLockedOut, false);
      });

      test('applies lockout when max attempts reached', () async {
        final existingData = LoginAttemptData(
          email: testEmail,
          failedAttempts: BruteForceConfig.maxAttempts - 1,
          firstFailureTime: DateTime.now().subtract(
            const Duration(minutes: 10),
          ),
        );

        when(
          () => mockSecureStorage.getSecureData(any()),
        ).thenAnswer((_) async => existingData.toJson());
        when(
          () => mockSecureStorage.setSecureData(any(), any()),
        ).thenAnswer((_) async {});

        final result = await loginAttemptService.recordFailedAttempt(testEmail);

        expect(result.email, testEmail);
        expect(result.failedAttempts, BruteForceConfig.maxAttempts);
        expect(result.isLockedOut, true);
        expect(result.lockoutUntil, isNotNull);
      });
    });

    group('recordSuccessfulLogin', () {
      test('removes attempt data on successful login', () async {
        when(
          () => mockSecureStorage.removeSecureData(any()),
        ).thenAnswer((_) async {});

        await loginAttemptService.recordSuccessfulLogin(testEmail);

        verify(() => mockSecureStorage.removeSecureData(any())).called(1);
      });
    });

    group('getWarningMessage', () {
      test('returns warning when close to lockout threshold', () async {
        final attemptData = LoginAttemptData(
          email: testEmail,
          failedAttempts: BruteForceConfig.maxAttempts - 2, // 3 attempts
          firstFailureTime: DateTime.now().subtract(const Duration(minutes: 5)),
        );

        when(
          () => mockSecureStorage.getSecureData(any()),
        ).thenAnswer((_) async => attemptData.toJson());

        final result = await loginAttemptService.getWarningMessage(testEmail);

        expect(result, isNotNull);
        expect(result, contains('2 attempts left'));
      });

      test('returns null when not close to threshold', () async {
        final attemptData = LoginAttemptData(
          email: testEmail,
          failedAttempts: 1,
          firstFailureTime: DateTime.now().subtract(const Duration(minutes: 5)),
        );

        when(
          () => mockSecureStorage.getSecureData(any()),
        ).thenAnswer((_) async => attemptData.toJson());

        final result = await loginAttemptService.getWarningMessage(testEmail);

        expect(result, isNull);
      });
    });

    test('trims email addresses consistently', () async {
      const emailWithSpaces = '  test@example.com  ';

      when(
        () => mockSecureStorage.getSecureData(any()),
      ).thenAnswer((_) async => null);

      await loginAttemptService.isAccountLockedOut(emailWithSpaces);

      verify(
        () => mockSecureStorage.getSecureData(
          'login_attempts_test@example.com',
        ),
      ).called(1);
    });
  });
}
