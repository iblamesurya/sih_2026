import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_guard/core/services/auth_service.dart';

void main() {
  group('AuthService - Phone Normalization & Email Mapping', () {
    test('normalizes standard 10-digit Indian phone numbers', () {
      expect(AuthService.normalizePhone('9876543210'), equals('9876543210'));
      expect(AuthService.normalizePhone('8123456789'), equals('8123456789'));
      expect(AuthService.normalizePhone('7012345678'), equals('7012345678'));
      expect(AuthService.normalizePhone('6301234567'), equals('6301234567'));
    });

    test('strips +91 prefix and whitespace/hyphens/parentheses', () {
      expect(AuthService.normalizePhone('+919876543210'), equals('9876543210'));
      expect(AuthService.normalizePhone('+91 98765 43210'), equals('9876543210'));
      expect(AuthService.normalizePhone('+91-98765-43210'), equals('9876543210'));
      expect(AuthService.normalizePhone('+91 (98765) 43210'), equals('9876543210'));
    });

    test('strips leading 0 and 91 (12 digits total)', () {
      expect(AuthService.normalizePhone('09876543210'), equals('9876543210'));
      expect(AuthService.normalizePhone('919876543210'), equals('9876543210'));
    });

    test('correctly maps phone numbers to @prawnguard.app email addresses', () {
      expect(
        AuthService.phoneToEmail('9876543210'),
        equals('9876543210@prawnguard.app'),
      );
      expect(
        AuthService.phoneToEmail('+91 98765 43210'),
        equals('9876543210@prawnguard.app'),
      );
      expect(
        AuthService.phoneToEmail('09876543210'),
        equals('9876543210@prawnguard.app'),
      );
    });

    test('throws ArgumentError on invalid phone inputs', () {
      expect(() => AuthService.normalizePhone(''), throwsArgumentError);
      expect(() => AuthService.normalizePhone('   '), throwsArgumentError);
      expect(() => AuthService.normalizePhone('12345'), throwsArgumentError);
      expect(() => AuthService.normalizePhone('abcdefghij'), throwsArgumentError);
      expect(() => AuthService.normalizePhone('+12345678901234'), throwsArgumentError);
      expect(() => AuthService.phoneToEmail('invalid'), throwsArgumentError);
    });

    test('rejects empty OTP token in verifyOtp', () async {
      final authService = AuthService();
      expect(
        () => authService.verifyOtp('9876543210', ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => authService.verifyOtp('9876543210', '   '),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
