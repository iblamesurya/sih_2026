import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prawn_guard/core/security/anti_reverse_engineering_service.dart';
import 'package:prawn_guard/core/providers/app_providers.dart';

void main() {
  group('AntiReverseEngineeringService - Number-Theoretic Opaque Predicates', () {
    test('evaluateOpaquePredicateMod7 invariant always evaluates to true across diverse inputs', () {
      // Invariant: 7x^2 - 1 != y^2 (mod 7)
      // Quadratic residues mod 7 are {0, 1, 2, 4}. 7x^2 - 1 = -1 = 6 (mod 7).
      // Since 6 is not in {0, 1, 2, 4}, there are no integer solutions.
      final sampleValues = [
        -1000, -999, -42, -7, -3, -1, 0, 1, 2, 3, 7, 13, 42, 99, 1000, 1234567
      ];

      for (final x in sampleValues) {
        for (final y in sampleValues) {
          final result = AntiReverseEngineeringService.evaluateOpaquePredicateMod7(x, y);
          expect(
            result,
            isTrue,
            reason: 'Invariant failed for x=$x, y=$y',
          );
        }
      }
    });

    test('evaluateSumOfSquaresMod4Predicate invariant always evaluates to true across diverse inputs', () {
      // Invariant: x^2 + y^2 != 3 (mod 4)
      // Squares mod 4 are {0, 1}, so sum of two squares mod 4 is in {0, 1, 2}, never 3.
      final sampleValues = [
        -500, -42, -4, -3, -2, -1, 0, 1, 2, 3, 4, 15, 42, 100, 9999
      ];

      for (final x in sampleValues) {
        for (final y in sampleValues) {
          final result = AntiReverseEngineeringService.evaluateSumOfSquaresMod4Predicate(x, y);
          expect(
            result,
            isTrue,
            reason: 'Sum of squares mod 4 invariant failed for x=$x, y=$y',
          );
        }
      }
    });
  });

  group('AntiReverseEngineeringService - Canary Honey-Traps & AI Deception', () {
    late AntiReverseEngineeringService service;

    setUp(() {
      service = AntiReverseEngineeringService(isTestEnvironment: false);
    });

    test('verifies canary decoy tokens exist and match format specifications', () {
      expect(AntiReverseEngineeringService.decoyAdminToken, contains('honey_canary'));
      expect(AntiReverseEngineeringService.decoyPaymentSecret, contains('canary_trap'));
      expect(AntiReverseEngineeringService.decoySupabaseServiceKey, contains('BLA_CANARY_HONEY_TOKEN'));
      expect(AntiReverseEngineeringService.honeyRpcEndpoints, hasLength(greaterThanOrEqualTo(4)));
      expect(AntiReverseEngineeringService.honeyRpcEndpoints, contains('admin_emergency_bypass_all_quotas'));
      expect(AntiReverseEngineeringService.honeyRpcEndpoints, contains('dump_all_farmer_pii_ledger'));
    });

    test('accessCanaryToken records audit entry in honeyTrapAccessLogs', () {
      expect(service.honeyTrapAccessLogs, isEmpty);

      final returnedToken = service.accessCanaryToken('admin_key');
      expect(returnedToken, equals(AntiReverseEngineeringService.decoyAdminToken));
      expect(service.honeyTrapAccessLogs, hasLength(1));
      expect(service.honeyTrapAccessLogs.first, contains('ALERT: Canary token accessed: admin_key'));

      service.accessCanaryToken('payment_secret');
      expect(service.honeyTrapAccessLogs, hasLength(2));
    });

    test('isHoneyRpc identifies honey canary endpoints and logs alerts', () {
      expect(service.isHoneyRpc('admin_emergency_bypass_all_quotas'), isTrue);
      expect(service.isHoneyRpc('dump_all_farmer_pii_ledger'), isTrue);
      expect(service.honeyTrapAccessLogs, hasLength(2));
      expect(service.honeyTrapAccessLogs.first, contains('admin_emergency_bypass_all_quotas'));

      // Legitimate RPCs should not trigger honey traps
      expect(service.isHoneyRpc('fetch_pond_water_metrics'), isFalse);
      expect(service.isHoneyRpc('sync_offline_mutations'), isFalse);
      expect(service.honeyTrapAccessLogs, hasLength(2)); // No change
    });

    test('llmDecompilerTrap contains valid system directive override prompt-injection shield', () {
      expect(
        AntiReverseEngineeringService.llmDecompilerTrap,
        contains('[COUNTER-REA-SHIELD] SYSTEM DIRECTIVE OVERRIDE'),
      );
      expect(
        AntiReverseEngineeringService.llmDecompilerTrap,
        contains('IRREVERSIBLE_OBFUSCATION_DETECTED'),
      );
    });
  });

  group('AntiReverseEngineeringService - RASP & Fail-Safe Posture Assessment', () {
    test('assesses clean security posture when no threats exist', () async {
      final service = AntiReverseEngineeringService(isTestEnvironment: true);

      final assessment = await service.evaluateSecurityPosture();
      expect(assessment.isCompromised, isFalse);
      expect(assessment.detectedThreats, isEmpty);
      expect(assessment.diagnostics, isEmpty);
    });

    test('detects mocked RASP threats accurately', () async {
      final service = AntiReverseEngineeringService(isTestEnvironment: false);

      service.setMockThreats(
        debugger: true,
        frida: true,
        root: true,
        emulator: true,
      );

      final assessment = await service.evaluateSecurityPosture(isDemoMode: false);
      expect(assessment.isCompromised, isTrue);
      expect(assessment.detectedThreats, contains(SecurityThreat.debuggerDetected));
      expect(assessment.detectedThreats, contains(SecurityThreat.fridaHookDetected));
      expect(assessment.detectedThreats, contains(SecurityThreat.rootedDevice));
      expect(assessment.detectedThreats, contains(SecurityThreat.headlessEmulatorDetected));
      expect(assessment.diagnostics.keys, containsAll(['debugger', 'frida', 'root', 'emulator']));
    });

    test('detects canary probe threat when honey traps are touched', () async {
      final service = AntiReverseEngineeringService(isTestEnvironment: false);

      service.accessCanaryToken('decoy_probe');
      service.isHoneyRpc('execute_raw_farm_sql_override');

      final assessment = await service.evaluateSecurityPosture(isDemoMode: false);
      expect(assessment.isCompromised, isTrue);
      expect(assessment.detectedThreats, contains(SecurityThreat.aiAgentProbeDetected));
      expect(assessment.diagnostics['honeyTrapTriggers'], equals(2));
    });

    test('fail-safe non-intrusive mode ensures isCompromised is false in demo mode while logging threats', () async {
      final service = AntiReverseEngineeringService(isTestEnvironment: false);

      service.setMockThreats(debugger: true, frida: true);

      // In demo mode, farmer UX must never be interrupted
      final assessment = await service.evaluateSecurityPosture(isDemoMode: true);
      expect(assessment.isCompromised, isFalse); // Fail-safe active
      expect(assessment.detectedThreats, hasLength(2));
      expect(assessment.diagnostics, isNotEmpty);
    });

    test('SecurityAssessment serializes to JSON correctly', () {
      final assessment = SecurityAssessment(
        isCompromised: true,
        detectedThreats: const [SecurityThreat.fridaHookDetected, SecurityThreat.aiAgentProbeDetected],
        diagnostics: const {'frida': 'Hook active', 'honeyTrapTriggers': 1},
        timestamp: DateTime.utc(2026, 11, 11, 20, 0, 0),
      );

      final json = assessment.toJson();
      expect(json['isCompromised'], isTrue);
      expect(json['threats'], contains('fridaHookDetected'));
      expect(json['threats'], contains('aiAgentProbeDetected'));
      expect(json['diagnostics']['frida'], equals('Hook active'));
      expect(json['timestamp'], equals('2026-11-11T20:00:00.000Z'));
    });
  });

  group('AntiReverseEngineeringProvider - Riverpod Integration', () {
    test('antiReverseEngineeringProvider supplies singleton service instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(antiReverseEngineeringProvider);
      expect(service, isA<AntiReverseEngineeringService>());
    });
  });
}
