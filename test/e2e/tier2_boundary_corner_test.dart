import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_guard/core/services/auth_service.dart';
import 'package:prawn_guard/core/services/offline_sync_service.dart';
import 'package:prawn_guard/core/services/alert_system.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tier 2 — Boundary & Corner: OfflineSyncService FIFO Queue Overflow', () {
    late OfflineSyncService syncService;

    setUp(() async {
      final prefs = await setupMockPreferences();
      syncService = OfflineSyncService(prefs);
      await syncService.clearQueue();
    });

    test('1.1 Exactly 100 items fills queue to maximum capacity without eviction', () async {
      for (int i = 0; i < 100; i++) {
        await syncService.enqueue({'seq': i});
      }

      expect(await syncService.queueLength, 100);
      final queue = await syncService.getQueue();
      expect(queue.length, 100);
      expect(queue.first['seq'], 0);
      expect(queue.last['seq'], 99);
    });

    test('1.2 Enqueuing 105 items: size is capped at 100 and first 5 items (0..4) are dropped in FIFO order', () async {
      for (int i = 0; i < 105; i++) {
        await syncService.enqueue({'seq': i, 'name': 'item_$i'});
      }

      expect(await syncService.queueLength, 100);
      final queue = await syncService.getQueue();
      expect(queue.length, 100);

      // Oldest 5 items (seq 0, 1, 2, 3, 4) MUST have been evicted
      expect(queue.first['seq'], 5);
      expect(queue.first['name'], 'item_5');

      // Latest item (seq 104) MUST be at the end
      expect(queue.last['seq'], 104);
      expect(queue.last['name'], 'item_104');

      // Verify sequence is strictly continuous from 5 to 104
      for (int i = 0; i < 100; i++) {
        expect(queue[i]['seq'], i + 5);
      }
    });

    test('1.3 Enqueuing 200 items in high-throughput burst preserves only latest 100 (100..199)', () async {
      for (int i = 0; i < 200; i++) {
        await syncService.enqueue({'seq': i});
      }

      expect(await syncService.queueLength, 100);
      final queue = await syncService.getQueue();
      expect(queue.first['seq'], 100);
      expect(queue.last['seq'], 199);
    });

    test('1.4 Rapid interleaved enqueue, partial drain, and overflow maintains consistency', () async {
      for (int i = 0; i < 50; i++) {
        await syncService.enqueue({'seq': i});
      }
      expect(await syncService.queueLength, 50);

      // Drain 20 items
      int drained = 0;
      await syncService.drainQueue(
        executor: (m) async {
          drained++;
          return drained <= 20;
        },
      );
      expect(await syncService.queueLength, 30);

      // Enqueue 80 more items -> total 110 -> 10 evicted
      for (int i = 50; i < 130; i++) {
        await syncService.enqueue({'seq': i});
      }
      expect(await syncService.queueLength, 100);

      final queue = await syncService.getQueue();
      expect(queue.first['seq'], 30); // 20-29 were evicted
      expect(queue.last['seq'], 129);
    });

    test('1.5 Corrupted non-JSON strings in storage are gracefully skipped without crashing', () async {
      final prefs = await setupMockPreferences({
        OfflineSyncService.queueKey: [
          '{"seq": 1, "table": "ponds"}',
          '{INVALID_JSON_CORRUPTED_BLOB}',
          '{"seq": 2, "table": "water_logs"}',
        ],
      });
      final robustSync = OfflineSyncService(prefs);

      final queue = await robustSync.getQueue();
      expect(queue.length, 2);
      expect(queue[0]['seq'], 1);
      expect(queue[1]['seq'], 2);

      // Drain skips corrupted item
      final count = await robustSync.drainQueue(executor: (m) async => true);
      expect(count, 2);
      expect(await robustSync.queueLength, 0);
    });
  });

  group('Tier 2 — Boundary & Corner: AlertSystem Exact Threshold Boundaries', () {
    const alertSystem = AlertSystem();

    test('2.1 Exact pH boundaries (7.0, 7.5, 8.5, 9.0) and epsilon deviations', () {
      // pH 7.0 -> watch
      expect(alertSystem.evaluatePh(7.0).severity, AlertSeverity.watch);
      // pH 6.99 -> urgent
      expect(alertSystem.evaluatePh(6.99).severity, AlertSeverity.urgent);

      // pH 7.5 -> optimal
      expect(alertSystem.evaluatePh(7.5).severity, AlertSeverity.optimal);
      // pH 7.49 -> watch
      expect(alertSystem.evaluatePh(7.49).severity, AlertSeverity.watch);

      // pH 8.5 -> optimal
      expect(alertSystem.evaluatePh(8.5).severity, AlertSeverity.optimal);
      // pH 8.51 -> watch
      expect(alertSystem.evaluatePh(8.51).severity, AlertSeverity.watch);

      // pH 9.0 -> watch
      expect(alertSystem.evaluatePh(9.0).severity, AlertSeverity.watch);
      // pH 9.01 -> urgent
      expect(alertSystem.evaluatePh(9.01).severity, AlertSeverity.urgent);
    });

    test('2.2 Exact Dissolved Oxygen (DO) boundaries (3.0, 4.0 mg/L) and epsilon deviations', () {
      // DO 3.0 -> watch
      expect(alertSystem.evaluateDO(3.0).severity, AlertSeverity.watch);
      // DO 2.99 -> urgent
      expect(alertSystem.evaluateDO(2.99).severity, AlertSeverity.urgent);

      // DO 4.0 -> watch
      expect(alertSystem.evaluateDO(4.0).severity, AlertSeverity.watch);
      // DO 4.01 -> optimal
      expect(alertSystem.evaluateDO(4.01).severity, AlertSeverity.optimal);
    });

    test('2.3 Exact Ammonia (NH3) boundaries (0.05, 0.10 mg/L) and epsilon deviations', () {
      // NH3 0.05 -> watch
      expect(alertSystem.evaluateAmmonia(0.05).severity, AlertSeverity.watch);
      // NH3 0.049 -> optimal
      expect(alertSystem.evaluateAmmonia(0.049).severity, AlertSeverity.optimal);

      // NH3 0.10 -> watch
      expect(alertSystem.evaluateAmmonia(0.10).severity, AlertSeverity.watch);
      // NH3 0.101 -> urgent
      expect(alertSystem.evaluateAmmonia(0.101).severity, AlertSeverity.urgent);
    });

    test('2.4 Exact Alkalinity boundaries (100.0, 150.0 mg/L) and epsilon deviations', () {
      // Alkalinity 100.0 -> optimal
      expect(alertSystem.evaluateAlkalinity(100.0).severity, AlertSeverity.optimal);
      // Alkalinity 99.9 -> watch
      expect(alertSystem.evaluateAlkalinity(99.9).severity, AlertSeverity.watch);

      // Alkalinity 150.0 -> optimal
      expect(alertSystem.evaluateAlkalinity(150.0).severity, AlertSeverity.optimal);
      // Alkalinity 150.1 -> watch
      expect(alertSystem.evaluateAlkalinity(150.1).severity, AlertSeverity.watch);
    });

    test('2.5 Extreme / catastrophic physical inputs handled safely', () {
      expect(alertSystem.evaluatePh(0.0).severity, AlertSeverity.urgent);
      expect(alertSystem.evaluatePh(14.0).severity, AlertSeverity.urgent);
      expect(alertSystem.evaluateDO(0.0).severity, AlertSeverity.urgent);
      expect(alertSystem.evaluateDO(25.0).severity, AlertSeverity.optimal);
      expect(alertSystem.evaluateAmmonia(10.0).severity, AlertSeverity.urgent);
    });
  });

  group('Tier 2 — Boundary & Corner: FeedAIService Clamping & Extreme Adjustments', () {
    const feedAI = FeedAIService();

    test('3.1 Exact temperature threshold boundaries (23.9°C, 24.0°C, 32.0°C, 32.1°C)', () {
      expect(feedAI.calculateTempFactor(23.9), 0.85);
      expect(feedAI.calculateTempFactor(24.0), 1.00);
      expect(feedAI.calculateTempFactor(32.0), 1.00);
      expect(feedAI.calculateTempFactor(32.1), 0.90);
    });

    test('3.2 DOC feeding rate clamping at lower bound (0.03) and upper bound (0.08)', () {
      // DOC 0 -> 0.08 (upper limit)
      expect(feedAI.calculateFeedingRate(0), 0.08);
      // Negative DOC -> clamped to 0.08
      expect(feedAI.calculateFeedingRate(-10), 0.08);
      // DOC 100 -> 0.08 - (100 * 0.0005) = 0.03 (lower bound)
      expect(feedAI.calculateFeedingRate(100), 0.03);
      // DOC 150 -> clamped to 0.03
      expect(feedAI.calculateFeedingRate(150), 0.03);
    });

    test('3.3 Extreme check-tray adjustments strictly clamped to [0.80, 1.10]', () {
      // Clean tray (-20%) -> 0.80
      expect(feedAI.calculateTrayFactor(-0.20), 0.80);
      // Trace tray (+10%) -> 1.10
      expect(feedAI.calculateTrayFactor(0.10), 1.10);
      // Extreme over-adjustment (-50%) clamped to 0.80
      expect(feedAI.calculateTrayFactor(-0.50), 0.80);
      // Extreme over-adjustment (+40%) clamped to 1.10
      expect(feedAI.calculateTrayFactor(0.40), 1.10);
    });

    test('3.4 Zero or negative biomass inputs produce 0.0 kg feed safely without NaN', () {
      final zeroDensity = feedAI.calculateDailyFeed(
        density: 0,
        areaHa: 1.0,
        survivalRate: 0.8,
        abw: 15.0,
        doc: 30,
        temperature: 28.0,
      );
      expect(zeroDensity.biomassKg, 0.0);
      expect(zeroDensity.adjustedDailyFeedKg, 0.0);
      expect(zeroDensity.mealsTotal, 0.0);

      final zeroSurvival = feedAI.calculateDailyFeed(
        density: 50,
        areaHa: 1.0,
        survivalRate: 0.0,
        abw: 15.0,
        doc: 30,
        temperature: 28.0,
      );
      expect(zeroSurvival.biomassKg, 0.0);
      expect(zeroSurvival.adjustedDailyFeedKg, 0.0);
    });

    test('3.5 Extreme weather temperatures evaluated safely', () {
      expect(feedAI.calculateTempFactor(-5.0), 0.85); // Extreme frost
      expect(feedAI.calculateTempFactor(48.0), 0.90); // Heatwave
    });
  });

  group('Tier 2 — Boundary & Corner: TeluguVoiceNLUService Mixed Script & Edge Cases', () {
    const voiceNlu = TeluguVoiceNLUService();

    test('4.1 Mixed Telugu script with English keywords ("చెరువు 2 లో pH 7.5, DO 4.2")', () {
      final parsed = voiceNlu.parseVoiceInput('చెరువు 2 లో pH 7.5, DO 4.2');
      expect(parsed.pondIndex, 2);
      expect(parsed.ph, 7.5);
      expect(parsed.doLevel, 4.2);
    });

    test('4.2 Irregular whitespace, capitalization, colons, and punctuation', () {
      final parsed = voiceNlu.parseVoiceInput('   POND   4   lo   ph   :   8.2   ,   DO   =  6.1  ');
      expect(parsed.pondIndex, 4);
      expect(parsed.ph, 8.2);
      expect(parsed.doLevel, 6.1);
    });

    test('4.3 Partial inputs with missing parameters extract only available entities', () {
      final onlyPond = voiceNlu.parseVoiceInput('Pond 5 lo inspection');
      expect(onlyPond.pondIndex, 5);
      expect(onlyPond.ph, isNull);
      expect(onlyPond.doLevel, isNull);

      final onlyFeed = voiceNlu.parseVoiceInput('morning feed 40 kg given');
      expect(onlyFeed.pondIndex, isNull);
      expect(onlyFeed.feedKg, 40.0);
    });

    test('4.4 Completely empty or non-telemetry random conversation returns empty telemetry', () {
      final empty = voiceNlu.parseVoiceInput('');
      expect(empty.isEmpty, isTrue);

      final chat = voiceNlu.parseVoiceInput('namaskaram ela unnaru memu bagunnamu');
      expect(chat.isEmpty, isTrue);
    });

    test('4.5 Transliterated Telugu phrases with full telemetry set', () {
      final parsed = voiceNlu.parseVoiceInput(
        'cheruvu 1 lo salinity 15 ammonia 0.03 temp 29.5 feed 18 kg',
      );
      expect(parsed.pondIndex, 1);
      expect(parsed.salinity, 15.0);
      expect(parsed.ammonia, 0.03);
      expect(parsed.temperature, 29.5);
      expect(parsed.feedKg, 18.0);
    });
  });

  group('Tier 2 — Boundary & Corner: AuthService Invalid Phone & Null/Empty Rejection', () {
    test('5.1 Empty string and whitespace-only strings throw ArgumentError', () {
      expect(() => AuthService.normalizePhone(''), throwsArgumentError);
      expect(() => AuthService.normalizePhone('   '), throwsArgumentError);
      expect(() => AuthService.normalizePhone('\t\n'), throwsArgumentError);
    });

    test('5.2 Short phone numbers (< 10 digits) throw ArgumentError', () {
      expect(() => AuthService.normalizePhone('98765'), throwsArgumentError);
      expect(() => AuthService.normalizePhone('98765432'), throwsArgumentError);
      expect(() => AuthService.normalizePhone('+91987654'), throwsArgumentError);
    });

    test('5.3 Phone numbers containing alphabetic characters throw ArgumentError', () {
      expect(() => AuthService.normalizePhone('98765abcde'), throwsArgumentError);
      expect(() => AuthService.normalizePhone('+91 98765-PHONE'), throwsArgumentError);
      expect(() => AuthService.normalizePhone('not_a_phone'), throwsArgumentError);
    });

    test('5.4 International numbers or non-10 digit inputs throw ArgumentError', () {
      expect(() => AuthService.normalizePhone('+1 555 123 4567'), throwsArgumentError);
      expect(() => AuthService.normalizePhone('+44 7911 123456'), throwsArgumentError);
      expect(() => AuthService.normalizePhone('12345'), throwsArgumentError);
    });

    test('5.5 Excessively long phone numbers throw ArgumentError', () {
      expect(() => AuthService.normalizePhone('987654321012345'), throwsArgumentError);
      expect(() => AuthService.normalizePhone('+9198765432109999'), throwsArgumentError);
    });
  });
}
