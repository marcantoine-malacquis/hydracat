import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/features/qol/exceptions/qol_exceptions.dart';

void main() {
  group('QolException', () {
    test('should create exception with message', () {
      const exception = QolException('Test error');

      expect(exception.message, 'Test error');
      expect(exception.toString(), 'QolException: Test error');
    });

    test('should implement Exception', () {
      const exception = QolException('Test');

      expect(exception, isA<Exception>());
    });
  });

  group('QolValidationException', () {
    test('should create validation exception with message', () {
      const exception = QolValidationException('Invalid score');

      expect(exception.message, 'Invalid score');
      expect(exception.toString(), 'QolValidationException: Invalid score');
    });

    test('should extend QolException', () {
      const exception = QolValidationException('Test');

      expect(exception, isA<QolException>());
      expect(exception, isA<Exception>());
    });

    test('should be throwable and catchable', () {
      expect(
        () => throw const QolValidationException('Validation failed'),
        throwsA(isA<QolValidationException>()),
      );
    });

    test('should be catchable as QolException', () {
      expect(
        () => throw const QolValidationException('Test'),
        throwsA(isA<QolException>()),
      );
    });

    test('should preserve message when caught', () {
      try {
        throw const QolValidationException('Test message');
      } on QolValidationException catch (e) {
        expect(e.message, 'Test message');
      }
    });
  });

  group('QolServiceException', () {
    test('should create service exception with message', () {
      const exception = QolServiceException('Firestore error');

      expect(exception.message, 'Firestore error');
      expect(exception.toString(), 'QolServiceException: Firestore error');
    });

    test('should extend QolException', () {
      const exception = QolServiceException('Test');

      expect(exception, isA<QolException>());
      expect(exception, isA<Exception>());
    });

    test('should be throwable and catchable', () {
      expect(
        () => throw const QolServiceException('Service failed'),
        throwsA(isA<QolServiceException>()),
      );
    });

    test('should be catchable as QolException', () {
      expect(
        () => throw const QolServiceException('Test'),
        throwsA(isA<QolException>()),
      );
    });

    test('should preserve message when caught', () {
      try {
        throw const QolServiceException('Test message');
      } on QolServiceException catch (e) {
        expect(e.message, 'Test message');
      }
    });
  });

  group('exception hierarchy', () {
    test('should differentiate between validation and service exceptions', () {
      const validationEx = QolValidationException('validation');
      const serviceEx = QolServiceException('service');

      expect(validationEx, isA<QolValidationException>());
      expect(validationEx, isNot(isA<QolServiceException>()));

      expect(serviceEx, isA<QolServiceException>());
      expect(serviceEx, isNot(isA<QolValidationException>()));
    });

    test('should allow catching all QoL exceptions', () {
      var caughtCount = 0;

      try {
        throw const QolValidationException('test1');
      } on QolException {
        caughtCount++;
      }

      try {
        throw const QolServiceException('test2');
      } on QolException {
        caughtCount++;
      }

      expect(caughtCount, 2);
    });

    test('should allow specific exception handling', () {
      String? caughtType;

      try {
        throw const QolValidationException('validation error');
      } on QolValidationException {
        caughtType = 'validation';
      } on QolServiceException {
        caughtType = 'service';
      }

      expect(caughtType, 'validation');

      try {
        throw const QolServiceException('service error');
      } on QolValidationException {
        caughtType = 'validation';
      } on QolServiceException {
        caughtType = 'service';
      }

      expect(caughtType, 'service');
    });
  });
}
