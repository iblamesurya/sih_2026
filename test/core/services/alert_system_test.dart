import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_guard/core/services/alert_system.dart';

void main() {
  const alertSystem = AlertSystem();

  group('AlertSystem - pH Thresholds', () {
    test('pH < 7.0 is Urgent', () {
      final alert = alertSystem.evaluatePh(6.8);
      expect(alert.severity, equals(AlertSeverity.urgent));
      expect(alert.isUrgent, isTrue);
    });

    test('pH > 9.0 is Urgent', () {
      final alert = alertSystem.evaluatePh(9.3);
      expect(alert.severity, equals(AlertSeverity.urgent));
      expect(alert.isUrgent, isTrue);
    });

    test('pH between 7.0 and 7.5 is Watch', () {
      final alert = alertSystem.evaluatePh(7.2);
      expect(alert.severity, equals(AlertSeverity.watch));
      expect(alert.isWatch, isTrue);
    });

    test('pH between 8.5 and 9.0 is Watch', () {
      final alert = alertSystem.evaluatePh(8.7);
      expect(alert.severity, equals(AlertSeverity.watch));
      expect(alert.isWatch, isTrue);
    });

    test('pH between 7.5 and 8.5 is Optimal', () {
      final alert = alertSystem.evaluatePh(7.9);
      expect(alert.severity, equals(AlertSeverity.optimal));
      expect(alert.isOptimal, isTrue);
    });
  });

  group('AlertSystem - Dissolved Oxygen (DO) Thresholds', () {
    test('DO < 3.0 mg/L is Urgent', () {
      final alert = alertSystem.evaluateDO(2.5);
      expect(alert.severity, equals(AlertSeverity.urgent));
      expect(alert.isUrgent, isTrue);
    });

    test('DO between 3.0 and 4.0 mg/L is Watch', () {
      final alert = alertSystem.evaluateDO(3.5);
      expect(alert.severity, equals(AlertSeverity.watch));
      expect(alert.isWatch, isTrue);
    });

    test('DO > 4.0 mg/L is Optimal', () {
      final alert = alertSystem.evaluateDO(5.2);
      expect(alert.severity, equals(AlertSeverity.optimal));
      expect(alert.isOptimal, isTrue);
    });
  });

  group('AlertSystem - Ammonia (NH3) Thresholds & Emerson TAN Conversion', () {
    test('Ammonia > 0.1 mg/L is Urgent', () {
      final alert = alertSystem.evaluateAmmonia(0.18);
      expect(alert.severity, equals(AlertSeverity.urgent));
      expect(alert.isUrgent, isTrue);
    });

    test('Ammonia between 0.05 and 0.1 mg/L is Watch', () {
      final alert = alertSystem.evaluateAmmonia(0.07);
      expect(alert.severity, equals(AlertSeverity.watch));
      expect(alert.isWatch, isTrue);
    });

    test('Ammonia < 0.05 mg/L is Optimal', () {
      final alert = alertSystem.evaluateAmmonia(0.02);
      expect(alert.severity, equals(AlertSeverity.optimal));
      expect(alert.isOptimal, isTrue);
    });

    test('Emerson equation converts TAN to Un-ionized NH3 accurately based on pH and Temperature', () {
      // At TAN = 1.0 mg/L, pH = 8.2, Temp = 30.0°C -> ~11.2% un-ionized NH3 (~0.112 mg/L -> Urgent)
      final nh3HighPh = alertSystem.calculateUnIonizedNh3FromTan(
        tanMgL: 1.0,
        ph: 8.2,
        temperatureC: 30.0,
      );
      expect(nh3HighPh, greaterThan(0.10));
      expect(alertSystem.evaluateAmmonia(nh3HighPh).isUrgent, isTrue);

      // At TAN = 0.5 mg/L, pH = 7.6, Temp = 28.0°C -> ~2.7% un-ionized NH3 (~0.013 mg/L -> Optimal)
      final nh3NormalPh = alertSystem.calculateUnIonizedNh3FromTan(
        tanMgL: 0.5,
        ph: 7.6,
        temperatureC: 28.0,
      );
      expect(nh3NormalPh, lessThan(0.05));
      expect(alertSystem.evaluateAmmonia(nh3NormalPh).isOptimal, isTrue);
    });
  });

  group('AlertSystem - Alkalinity Thresholds', () {
    test('Alkalinity < 100 mg/L is Watch', () {
      final alert = alertSystem.evaluateAlkalinity(85.0);
      expect(alert.severity, equals(AlertSeverity.watch));
    });

    test('Alkalinity between 100 and 150 mg/L is Optimal', () {
      final alert = alertSystem.evaluateAlkalinity(130.0);
      expect(alert.severity, equals(AlertSeverity.optimal));
    });
  });

  group('AlertSystem - Aggregate Multi-Parameter Evaluation', () {
    test('returns alerts for all provided parameters and computes overall severity', () {
      final alerts = alertSystem.evaluateParameters(
        ph: 6.8, // Urgent
        dissolvedOxygen: 3.5, // Watch
        ammonia: 0.02, // Optimal
        alkalinity: 125.0, // Optimal
      );

      expect(alerts.length, equals(4));
      expect(alertSystem.getOverallSeverity(alerts), equals(AlertSeverity.urgent));
    });

    test('computes watch overall severity when no urgent alerts exist', () {
      final alerts = alertSystem.evaluateParameters(
        ph: 7.9, // Optimal
        dissolvedOxygen: 3.8, // Watch
        ammonia: 0.03, // Optimal
      );

      expect(alerts.length, equals(3));
      expect(alertSystem.getOverallSeverity(alerts), equals(AlertSeverity.watch));
    });

    test('computes optimal overall severity when all parameters are optimal', () {
      final alerts = alertSystem.evaluateParameters(
        ph: 8.0,
        dissolvedOxygen: 5.5,
        ammonia: 0.01,
        alkalinity: 135.0,
      );

      expect(alerts.length, equals(4));
      expect(alertSystem.getOverallSeverity(alerts), equals(AlertSeverity.optimal));
    });
  });
}
