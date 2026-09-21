import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_guard/core/services/alert_system.dart';
import 'package:prawn_guard/core/services/auth_service.dart';

void main() {
  group('Challenger 2 - AlertSystem Boundary Stress Tests', () {
    const alertSystem = AlertSystem();

    group('pH Exact Boundary Conditions', () {
      test('pH 6.99 triggers Urgent severity', () {
        final alert = alertSystem.evaluatePh(6.99);
        expect(alert.severity, equals(AlertSeverity.urgent));
        expect(alert.isUrgent, isTrue);
        expect(alert.isWatch, isFalse);
        expect(alert.isOptimal, isFalse);
        expect(alert.teluguMessage.isNotEmpty, isTrue);
        expect(alert.teluguRecommendation.isNotEmpty, isTrue);
      });

      test('pH 7.00 triggers Watch severity', () {
        final alert = alertSystem.evaluatePh(7.00);
        expect(alert.severity, equals(AlertSeverity.watch));
        expect(alert.isWatch, isTrue);
        expect(alert.isUrgent, isFalse);
        expect(alert.isOptimal, isFalse);
      });

      test('pH 7.49 triggers Watch severity', () {
        final alert = alertSystem.evaluatePh(7.49);
        expect(alert.severity, equals(AlertSeverity.watch));
        expect(alert.isWatch, isTrue);
      });

      test('pH 7.50 triggers Optimal severity', () {
        final alert = alertSystem.evaluatePh(7.50);
        expect(alert.severity, equals(AlertSeverity.optimal));
        expect(alert.isOptimal, isTrue);
        expect(alert.isUrgent, isFalse);
        expect(alert.isWatch, isFalse);
      });

      test('pH 8.50 triggers Optimal severity', () {
        final alert = alertSystem.evaluatePh(8.50);
        expect(alert.severity, equals(AlertSeverity.optimal));
        expect(alert.isOptimal, isTrue);
      });

      test('pH 8.51 triggers Watch severity', () {
        final alert = alertSystem.evaluatePh(8.51);
        expect(alert.severity, equals(AlertSeverity.watch));
        expect(alert.isWatch, isTrue);
      });

      test('pH 9.00 triggers Watch severity', () {
        final alert = alertSystem.evaluatePh(9.00);
        expect(alert.severity, equals(AlertSeverity.watch));
        expect(alert.isWatch, isTrue);
      });

      test('pH 9.01 triggers Urgent severity', () {
        final alert = alertSystem.evaluatePh(9.01);
        expect(alert.severity, equals(AlertSeverity.urgent));
        expect(alert.isUrgent, isTrue);
      });

      test('Extreme low and high ph values trigger Urgent severity', () {
        expect(alertSystem.evaluatePh(0.0).severity, equals(AlertSeverity.urgent));
        expect(alertSystem.evaluatePh(4.5).severity, equals(AlertSeverity.urgent));
        expect(alertSystem.evaluatePh(11.0).severity, equals(AlertSeverity.urgent));
        expect(alertSystem.evaluatePh(14.0).severity, equals(AlertSeverity.urgent));
      });
    });


    group('Dissolved Oxygen (DO) Exact Boundary Conditions', () {
      test('DO 2.99 triggers Urgent severity', () {
        final alert = alertSystem.evaluateDO(2.99);
        expect(alert.severity, equals(AlertSeverity.urgent));
        expect(alert.isUrgent, isTrue);
        expect(alert.teluguMessage.isNotEmpty, isTrue);
      });

      test('DO 3.00 triggers Watch severity', () {
        final alert = alertSystem.evaluateDO(3.00);
        expect(alert.severity, equals(AlertSeverity.watch));
        expect(alert.isWatch, isTrue);
      });

      test('DO 3.99 triggers Watch severity', () {
        final alert = alertSystem.evaluateDO(3.99);
        expect(alert.severity, equals(AlertSeverity.watch));
        expect(alert.isWatch, isTrue);
      });

      test('DO 4.00 triggers Watch severity', () {
        final alert = alertSystem.evaluateDO(4.00);
        expect(alert.severity, equals(AlertSeverity.watch));
        expect(alert.isWatch, isTrue);
      });

      test('DO 4.01 triggers Optimal severity', () {
        final alert = alertSystem.evaluateDO(4.01);
        expect(alert.severity, equals(AlertSeverity.optimal));
        expect(alert.isOptimal, isTrue);
      });

      test('DO 0.0 (anoxia) triggers Urgent and high DO (8.5) triggers Optimal', () {
        expect(alertSystem.evaluateDO(0.0).severity, equals(AlertSeverity.urgent));
        expect(alertSystem.evaluateDO(8.5).severity, equals(AlertSeverity.optimal));
      });
    });


    group('Ammonia (NH3) Exact Boundary Conditions', () {
      test('Ammonia 0.049 triggers Optimal severity', () {
        final alert = alertSystem.evaluateAmmonia(0.049);
        expect(alert.severity, equals(AlertSeverity.optimal));
        expect(alert.isOptimal, isTrue);
      });

      test('Ammonia 0.05 triggers Watch severity', () {
        final alert = alertSystem.evaluateAmmonia(0.05);
        expect(alert.severity, equals(AlertSeverity.watch));
        expect(alert.isWatch, isTrue);
      });

      test('Ammonia 0.10 triggers Watch severity', () {
        final alert = alertSystem.evaluateAmmonia(0.10);
        expect(alert.severity, equals(AlertSeverity.watch));
        expect(alert.isWatch, isTrue);
      });

      test('Ammonia 0.101 triggers Urgent severity', () {
        final alert = alertSystem.evaluateAmmonia(0.101);
        expect(alert.severity, equals(AlertSeverity.urgent));
        expect(alert.isUrgent, isTrue);
      });

      test('Ammonia 0.00 is Optimal and 0.50 is Urgent', () {
        expect(alertSystem.evaluateAmmonia(0.00).severity, equals(AlertSeverity.optimal));
        expect(alertSystem.evaluateAmmonia(0.50).severity, equals(AlertSeverity.urgent));
      });
    });


    group('Alkalinity Exact Boundary Conditions', () {
      test('Alkalinity 99.9 triggers Watch severity', () {
        final alert = alertSystem.evaluateAlkalinity(99.9);
        expect(alert.severity, equals(AlertSeverity.watch));
        expect(alert.isWatch, isTrue);
      });

      test('Alkalinity 100.0 triggers Optimal severity', () {
        final alert = alertSystem.evaluateAlkalinity(100.0);
        expect(alert.severity, equals(AlertSeverity.optimal));
        expect(alert.isOptimal, isTrue);
      });

      test('Alkalinity 150.0 triggers Optimal severity', () {
        final alert = alertSystem.evaluateAlkalinity(150.0);
        expect(alert.severity, equals(AlertSeverity.optimal));
        expect(alert.isOptimal, isTrue);
      });

      test('Alkalinity 150.1 triggers Watch severity (High)', () {
        final alert = alertSystem.evaluateAlkalinity(150.1);
        expect(alert.severity, equals(AlertSeverity.watch));
        expect(alert.isWatch, isTrue);
      });
    });


    group('Salinity & Temperature Boundaries', () {
      test('Salinity boundaries (4.99 Watch, 5.0 Optimal, 35.0 Optimal, 35.01 Watch)', () {
        expect(alertSystem.evaluateSalinity(4.99).severity, equals(AlertSeverity.watch));
        expect(alertSystem.evaluateSalinity(5.00).severity, equals(AlertSeverity.optimal));
        expect(alertSystem.evaluateSalinity(25.0).severity, equals(AlertSeverity.optimal));
        expect(alertSystem.evaluateSalinity(35.00).severity, equals(AlertSeverity.optimal));
        expect(alertSystem.evaluateSalinity(35.01).severity, equals(AlertSeverity.watch));
      });

      test('Temperature boundaries (21.99 Urgent, 22.0 Watch, 25.99 Watch, 26.0 Optimal, 32.0 Optimal, 32.01 Watch, 34.0 Watch, 34.01 Urgent)', () {
        expect(alertSystem.evaluateTemperature(21.99).severity, equals(AlertSeverity.urgent));
        expect(alertSystem.evaluateTemperature(22.00).severity, equals(AlertSeverity.watch));
        expect(alertSystem.evaluateTemperature(25.99).severity, equals(AlertSeverity.watch));
        expect(alertSystem.evaluateTemperature(26.00).severity, equals(AlertSeverity.optimal));
        expect(alertSystem.evaluateTemperature(32.00).severity, equals(AlertSeverity.optimal));
        expect(alertSystem.evaluateTemperature(32.01).severity, equals(AlertSeverity.watch));
        expect(alertSystem.evaluateTemperature(34.00).severity, equals(AlertSeverity.watch));
        expect(alertSystem.evaluateTemperature(34.01).severity, equals(AlertSeverity.urgent));
      });
    });

    group('Multi-Parameter Evaluation and Overall Severity', () {
      test('Evaluates empty telemetry as optimal with 0 alerts', () {
        final alerts = alertSystem.evaluateParameters();
        expect(alerts, isEmpty);
        expect(alertSystem.getOverallSeverity(alerts), equals(AlertSeverity.optimal));
      });

      test('Any urgent alert sets overall severity to urgent', () {
        final alerts = alertSystem.evaluateParameters(
          ph: 7.8,
          dissolvedOxygen: 2.99,
          ammonia: 0.02,
          alkalinity: 120.0,
        );
        expect(alerts.length, equals(4));
        expect(alertSystem.getOverallSeverity(alerts), equals(AlertSeverity.urgent));
      });

      test('Watch alert without urgent sets overall severity to watch', () {
        final alerts = alertSystem.evaluateParameters(
          ph: 7.2,
          dissolvedOxygen: 4.5,
          ammonia: 0.03,
          alkalinity: 130.0,
        );
        expect(alerts.length, equals(4));
        expect(alertSystem.getOverallSeverity(alerts), equals(AlertSeverity.watch));
      });

      test('All optimal parameters yield overall optimal severity', () {
        final alerts = alertSystem.evaluateParameters(
          ph: 8.0,
          dissolvedOxygen: 5.0,
          ammonia: 0.02,
          alkalinity: 120.0,
          salinity: 15.0,
          temperature: 28.0,
        );
        expect(alerts.length, equals(6));
        expect(alertSystem.getOverallSeverity(alerts), equals(AlertSeverity.optimal));
      });
    });
  });

  group('Challenger 2 - AuthService Adversarial Stress Tests', () {
    group('Indian Phone Number Normalization', () {
      test('handles standard "+919876543210"', () {
        expect(AuthService.normalizePhone('+919876543210'), equals('9876543210'));
      });

      test('handles standard "9876543210"', () {
        expect(AuthService.normalizePhone('9876543210'), equals('9876543210'));
      });

      test('handles leading zero "09876543210"', () {
        expect(AuthService.normalizePhone('09876543210'), equals('9876543210'));
      });

      test('handles formatted "+91 98765 43210"', () {
        expect(AuthService.normalizePhone('+91 98765 43210'), equals('9876543210'));
      });

      test('handles exotic spacing, parentheses, dashes "+91 (98765) - 43210"', () {
        expect(
          AuthService.normalizePhone('+91 (98765) - 43210'),
          equals('9876543210'),
        );
      });

      test('handles 12-digit string without plus "919876543210"', () {
        expect(AuthService.normalizePhone('919876543210'), equals('9876543210'));
      });

      test('maps normalized phone numbers to @prawnguard.app email domain', () {
        expect(
          AuthService.phoneToEmail('+919876543210'),
          equals('9876543210@prawnguard.app'),
        );
        expect(
          AuthService.phoneToEmail('9876543210'),
          equals('9876543210@prawnguard.app'),
        );
        expect(
          AuthService.phoneToEmail('09876543210'),
          equals('9876543210@prawnguard.app'),
        );
        expect(
          AuthService.phoneToEmail('+91 98765 43210'),
          equals('9876543210@prawnguard.app'),
        );
      });
    });

    group('Adversarial & Invalid Phone Input Rejection', () {
      final invalidInputs = [
        '',
        '   ',
        '\t\n\r',
        '12345',
        '98765',
        'abcdefghij',
        '98765abcde',
        '+91 98765 ABCDE',
        '987654321',
        '98765432100',
        '+9198765432100',
        '009876543210',
        '+14155552671',
        '+447911123456',
        "'; DROP TABLE profiles; --",
        '<script>alert("xss")</script>',
        '9876543210\nadmin',
        '9876543210@gmail.com',
        '+91-0000000000000000',
        'null',
        'undefined',
      ];

      for (int i = 0; i < invalidInputs.length; i++) {
        final input = invalidInputs[i];
        test('rejects adversarial input #' + (i + 1).toString(), () {
          expect(
            () => AuthService.normalizePhone(input),
            throwsArgumentError,
            reason: 'Expected normalizePhone to reject invalid input at index ' + i.toString(),
          );
          expect(
            () => AuthService.phoneToEmail(input),
            throwsArgumentError,
            reason: 'Expected phoneToEmail to reject invalid input at index ' + i.toString(),
          );
        });
      }
    });

    group('OTP Token Validation', () {
      final authService = AuthService();

      test('rejects empty and whitespace OTP tokens', () {
        expect(
          () => authService.verifyOtp('9876543210', ''),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => authService.verifyOtp('9876543210', '   '),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => authService.verifyOtp('9876543210', '\t\n'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
