import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:prawn_guard/core/services/offline_sync_service.dart';
import 'package:prawn_guard/core/services/alert_system.dart';
import 'package:prawn_guard/core/services/subscription_service.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tier 3 — Cross-Feature Pairwise: OfflineSync + BaseRepository SafeMutate', () {
    late OfflineSyncService syncService;
    late TestWaterLogRepository repository;

    setUp(() async {
      final prefs = await setupMockPreferences();
      syncService = OfflineSyncService(prefs);
      await syncService.clearQueue();
      repository = TestWaterLogRepository(syncService);
    });

    test('1.1 SocketException during network action enqueues mutation and returns fallback', () async {
      final result = await repository.submitWaterLog(
        pondId: 'pond_01',
        ph: 7.6,
        dissolvedOxygen: 5.2,
        ammonia: 0.02,
        networkCaller: () async {
          throw const SocketException('No route to host');
        },
      );

      expect(result, isNotNull);
      expect(result!['status'], 'queued_offline');
      expect(result['pond_id'], 'pond_01');

      expect(await syncService.queueLength, 1);
      final queue = await syncService.getQueue();
      expect(queue.first['table'], 'water_logs');
      expect(queue.first['action'], 'insert');
      expect(queue.first['payload']['ph'], 7.6);
    });

    test('1.2 Multiple network failure types (Timeout, ClientException) queue in FIFO order', () async {
      // 1. Timeout failure
      await repository.submitWaterLog(
        pondId: 'pond_01',
        ph: 7.5,
        dissolvedOxygen: 4.8,
        ammonia: 0.03,
        networkCaller: () async => throw http.ClientException('Connection aborted'),
      );

      // 2. Client exception failure
      await repository.submitWaterLog(
        pondId: 'pond_02',
        ph: 8.1,
        dissolvedOxygen: 5.5,
        ammonia: 0.01,
        networkCaller: () async => throw const SocketException('Network unreachable'),
      );

      expect(await syncService.queueLength, 2);
      final queue = await syncService.getQueue();
      expect(queue[0]['payload']['pond_id'], 'pond_01');
      expect(queue[1]['payload']['pond_id'], 'pond_02');
    });

    test('1.3 Reconnected network drains queued mutations sequentially via mock executor', () async {
      await repository.submitWaterLog(
        pondId: 'p1',
        ph: 7.8,
        dissolvedOxygen: 5.0,
        ammonia: 0.02,
        networkCaller: () async => throw const SocketException('Offline'),
      );
      await repository.submitWaterLog(
        pondId: 'p2',
        ph: 7.9,
        dissolvedOxygen: 5.2,
        ammonia: 0.01,
        networkCaller: () async => throw const SocketException('Offline'),
      );

      expect(await syncService.queueLength, 2);

      final List<String> uploadedPonds = [];
      final drainedCount = await syncService.drainQueue(
        executor: (mutation) async {
          uploadedPonds.add(mutation['payload']['pond_id'] as String);
          return true;
        },
      );

      expect(drainedCount, 2);
      expect(uploadedPonds, ['p1', 'p2']);
      expect(await syncService.queueLength, 0);
    });

    test('1.4 Online successful network action bypasses offline queue completely', () async {
      final result = await repository.submitWaterLog(
        pondId: 'p_online',
        ph: 8.0,
        dissolvedOxygen: 6.0,
        ammonia: 0.01,
        networkCaller: () async => {
          'id': 'log_999',
          'pond_id': 'p_online',
          'status': 'synced_remote',
        },
      );

      expect(result!['status'], 'synced_remote');
      expect(await syncService.queueLength, 0);
    });
  });

  group('Tier 3 — Cross-Feature Pairwise: Telugu Voice NLU -> AlertSystem Threshold Engine', () {
    const voiceNlu = TeluguVoiceNLUService();
    const alertSystem = AlertSystem();

    test('2.1 High-risk voice input triggers 3 Urgent alerts in AlertSystem', () {
      const speech = 'Pond 1 lo pH 6.8, DO 2.8, ammonia 0.15';
      final telemetry = voiceNlu.parseVoiceInput(speech);

      expect(telemetry.pondIndex, 1);
      expect(telemetry.ph, 6.8);
      expect(telemetry.doLevel, 2.8);
      expect(telemetry.ammonia, 0.15);

      final alerts = alertSystem.evaluateParameters(
        ph: telemetry.ph,
        dissolvedOxygen: telemetry.doLevel,
        ammonia: telemetry.ammonia,
      );

      expect(alerts.length, 3);
      for (final alert in alerts) {
        expect(alert.severity, AlertSeverity.urgent);
        expect(alert.recommendation.isNotEmpty, isTrue);
        expect(alert.teluguRecommendation.isNotEmpty, isTrue);
      }
    });

    test('2.2 Optimal voice input produces Optimal status across all parameters', () {
      const speech = 'Pond 2 lo pH 7.8, DO 5.5, ammonia 0.02, salinity 18';
      final telemetry = voiceNlu.parseVoiceInput(speech);

      final alerts = alertSystem.evaluateParameters(
        ph: telemetry.ph,
        dissolvedOxygen: telemetry.doLevel,
        ammonia: telemetry.ammonia,
        salinity: telemetry.salinity,
      );

      expect(alerts.length, 4);
      for (final alert in alerts) {
        expect(alert.severity, AlertSeverity.optimal);
      }
    });

    test('2.3 Sub-optimal voice input triggers Watch alerts with actionable advice', () {
      const speech = 'Pond 3 lo pH 7.2, DO 3.6, ammonia 0.08';
      final telemetry = voiceNlu.parseVoiceInput(speech);

      final alerts = alertSystem.evaluateParameters(
        ph: telemetry.ph,
        dissolvedOxygen: telemetry.doLevel,
        ammonia: telemetry.ammonia,
      );

      expect(alerts.length, 3);
      for (final alert in alerts) {
        expect(alert.severity, AlertSeverity.watch);
      }
    });

    test('2.4 Partial speech input safely evaluates only present parameters', () {
      const speech = 'Pond 4 lo DO 2.5';
      final telemetry = voiceNlu.parseVoiceInput(speech);

      final alerts = alertSystem.evaluateParameters(
        ph: telemetry.ph,
        dissolvedOxygen: telemetry.doLevel,
        ammonia: telemetry.ammonia,
      );

      expect(alerts.length, 1);
      expect(alerts.first.parameter, 'Dissolved Oxygen');
      expect(alerts.first.severity, AlertSeverity.urgent);
    });
  });

  group('Tier 3 — Cross-Feature Pairwise: FeedAIService Calculations -> Feed Log Mutations', () {
    late OfflineSyncService syncService;
    const feedAI = FeedAIService();

    setUp(() async {
      final prefs = await setupMockPreferences();
      syncService = OfflineSyncService(prefs);
      await syncService.clearQueue();
    });

    test('3.1 Daily feed plan partitions into 4 structured feed_logs mutations and enqueues to sync service', () async {
      final plan = feedAI.calculateDailyFeed(
        density: 50,
        areaHa: 1.0,
        survivalRate: 0.85,
        abw: 18.0,
        doc: 50,
        temperature: 28.0,
      );

      final meals = [
        {'mealNumber': 1, 'time': '06:00', 'kg': plan.meal1Kg, 'percent': 20},
        {'mealNumber': 2, 'time': '11:00', 'kg': plan.meal2Kg, 'percent': 30},
        {'mealNumber': 3, 'time': '16:00', 'kg': plan.meal3Kg, 'percent': 30},
        {'mealNumber': 4, 'time': '21:00', 'kg': plan.meal4Kg, 'percent': 20},
      ];

      for (final meal in meals) {
        await syncService.enqueue({
          'table': 'feed_logs',
          'action': 'insert',
          'payload': {
            'pond_id': 'pond_alpha',
            'meal_number': meal['mealNumber'],
            'scheduled_time': meal['time'],
            'feed_kg': meal['kg'],
            'percent_share': meal['percent'],
          },
        });
      }

      expect(await syncService.queueLength, 4);
      final queue = await syncService.getQueue();

      double totalEnqueuedKg = 0;
      for (final item in queue) {
        expect(item['table'], 'feed_logs');
        totalEnqueuedKg += (item['payload']['feed_kg'] as num).toDouble();
      }

      expect(totalEnqueuedKg, closeTo(plan.adjustedDailyFeedKg, 0.01));
    });
  });

  group('Tier 3 — Cross-Feature Pairwise: SubscriptionService Quota Decrement -> PrawnDoc AI', () {
    const subService = SubscriptionService();
    const prawnDocAI = PrawnDocAIService(subService);

    test('4.1 Free tier quota decrements on scan and blocks 4th request until Pro upgrade', () {
      int scansToday = 0;
      bool isPro = false;

      // Scan 1: WSSV
      expect(subService.canPerformScan(currentScansToday: scansToday, isPro: isPro), isTrue);
      final diag1 = prawnDocAI.diagnose(
        detectedDisease: ShrimpDisease.wssv,
        confidence: 0.96,
        currentScansToday: scansToday,
        isPro: isPro,
      );
      expect(diag1.disease, ShrimpDisease.wssv);
      scansToday++; // scansToday = 1

      // Scan 2: EHP
      expect(subService.canPerformScan(currentScansToday: scansToday, isPro: isPro), isTrue);
      final diag2 = prawnDocAI.diagnose(
        detectedDisease: ShrimpDisease.ehp,
        confidence: 0.92,
        currentScansToday: scansToday,
        isPro: isPro,
      );
      expect(diag2.disease, ShrimpDisease.ehp);
      scansToday++; // scansToday = 2

      // Scan 3: Healthy
      expect(subService.canPerformScan(currentScansToday: scansToday, isPro: isPro), isTrue);
      final diag3 = prawnDocAI.diagnose(
        detectedDisease: ShrimpDisease.healthy,
        confidence: 0.98,
        currentScansToday: scansToday,
        isPro: isPro,
      );
      expect(diag3.disease, ShrimpDisease.healthy);
      scansToday++; // scansToday = 3

      // Scan 4: Free tier blocked
      expect(subService.canPerformScan(currentScansToday: scansToday, isPro: isPro), isFalse);
      expect(
        () => prawnDocAI.diagnose(
          detectedDisease: ShrimpDisease.vibrioLuminescence,
          confidence: 0.94,
          currentScansToday: scansToday,
          isPro: isPro,
        ),
        throwsStateError,
      );

      // User upgrades to Pro tier
      isPro = true;
      expect(subService.canPerformScan(currentScansToday: scansToday, isPro: isPro), isTrue);
      final diag4 = prawnDocAI.diagnose(
        detectedDisease: ShrimpDisease.vibrioLuminescence,
        confidence: 0.94,
        currentScansToday: scansToday,
        isPro: isPro,
      );
      expect(diag4.disease, ShrimpDisease.vibrioLuminescence);
    });
  });
}
