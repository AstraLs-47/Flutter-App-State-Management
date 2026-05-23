// Unit tests for input validators used in auth forms

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/utils/validators.dart';

void main() {
  group('Validators.validateEmail', () {
    test('returns null for valid email', () {
      expect(Validators.validateEmail('john@example.com'), isNull);
    });

    test('returns null for email with subdomain', () {
      expect(Validators.validateEmail('admin@purepulse.com'), isNull);
    });

    test('returns error for empty email', () {
      expect(Validators.validateEmail(''), isNotNull);
    });

    test('returns error for null email', () {
      expect(Validators.validateEmail(null), isNotNull);
    });

    test('returns error for email without @', () {
      expect(Validators.validateEmail('invalidemail'), isNotNull);
    });

    test('returns error for email without domain', () {
      expect(Validators.validateEmail('user@'), isNotNull);
    });
  });

  group('Validators.validatePassword', () {
    test('returns null for valid password', () {
      expect(Validators.validatePassword('admin123'), isNull);
    });

    test('returns error for empty password', () {
      expect(Validators.validatePassword(''), isNotNull);
    });

    test('returns error for null password', () {
      expect(Validators.validatePassword(null), isNotNull);
    });

    test('returns error for short password (less than 6 chars)', () {
      expect(Validators.validatePassword('abc'), isNotNull);
    });

    test('returns null for exactly 6 characters', () {
      expect(Validators.validatePassword('abcdef'), isNull);
    });
  });

  group('Validators.validateName', () {
    test('returns null for valid name', () {
      expect(Validators.validateName('John Doe'), isNull);
    });

    test('returns error for empty name', () {
      expect(Validators.validateName(''), isNotNull);
    });

    test('returns error for null name', () {
      expect(Validators.validateName(null), isNotNull);
    });

    test('returns error for name shorter than 3 chars', () {
      expect(Validators.validateName('Jo'), isNotNull);
    });

    test('returns null for name with exactly 3 chars', () {
      expect(Validators.validateName('Joe'), isNull);
    });
  });
}
