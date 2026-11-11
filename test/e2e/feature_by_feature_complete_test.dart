import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prawn_guard/core/providers/app_providers.dart';
import 'package:prawn_guard/core/services/prawndoc_ai_service.dart';
import 'package:prawn_guard/core/services/feed_ai_service.dart';
import 'package:prawn_guard/core/services/telugu_voice_nlu_service.dart';
import 'package:prawn_guard/core/services/weather_service.dart';
import 'package:prawn_guard/core/services/emergency_alarm_service.dart';
import 'package:prawn_guard/core/services/offline_sync_service.dart';
import 'package:prawn_guard/features/prawndoc/presentation/pages/prawndoc_page.dart';
import 'package:prawn_guard/features/feed/presentation/pages/feed_ai_page.dart';
import 'package:prawn_guard/features/ponds/presentation/pages/telemetry_logging_page.dart';
import 'package:prawn_guard/features/weather/presentation/pages/weather_page.dart';
import 'package:prawn_guard/features/market/presentation/pages/mandi_prices_page.dart';
import 'package:prawn_guard/features/ponds/presentation/pages/abw_camera_sampling_page.dart';
import 'package:prawn_guard/features/finance/presentation/pages/prawn_credit_page.dart';
import 'package:prawn_guard/features/ponds/presentation/pages/pond_list_page.dart';
import 'package:prawn_guard/features/community/presentation/pages/community_page.dart';
import 'package:prawn_guard/features/reports/presentation/pages/reports_page.dart';

void _configureTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('10 Core Features — Feature-by-Feature Verification Suite', () {
    testWidgets('Feature 1: PrawnDoc AI diagnoses all 12 diseases + Healthy and renders UI',
        (WidgetTester tester) async {
      _configureTallViewport(tester);
      const service = PrawnDocAIService();

      // Verify all 12 core diseases + healthy can be diagnosed via analyzeShrimpImage
      final coreDiseases = [
        ShrimpDisease.wssv,
        ShrimpDisease.ahpnd,
        ShrimpDisease.ehp,
        ShrimpDisease.wfs,
        ShrimpDisease.rms,
        ShrimpDisease.blackGill,
        ShrimpDisease.imnv,
        ShrimpDisease.vibriosis,
        ShrimpDisease.lss,
        ShrimpDisease.yhv,
        ShrimpDisease.microsporidiosis,
        ShrimpDisease.gillTurbidity,
        ShrimpDisease.healthy,
      ];

      for (int i = 0; i < coreDiseases.length; i++) {
        final d = coreDiseases[i];
        final result = await service.analyzeShrimpImage(
          imageBytes: Uint8List.fromList([1, 2, 3, i]),
          suspectedDisease: d,
          currentScansToday: 0,
          isPro: true,
        );
        expect(result.disease, d);
        expect(result.confidence, greaterThanOrEqualTo(0.84));
        expect(result.teluguSummary, isNotEmpty);
      }

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: PrawnDocPage()),
        ),
      );
      await tester.pump();

      expect(find.textContaining('PrawnDoc'), findsWidgets);
      expect(find.textContaining('Running Mortality'), findsWidgets);
      expect(find.textContaining('Analyze Shrimp Specimen'), findsOneWidget);
    });

    testWidgets('Feature 2: Bio-Energetic Feed AI & Check-Tray Feedback Loop',
        (WidgetTester tester) async {
      _configureTallViewport(tester);
      const feedService = FeedAIService();

      // Tray empty -> +10% (trayFactor = 1.10)
      final planEmpty = feedService.calculateDailyFeed(
        density: 50,
        areaHa: 1.0,
        survivalRate: 0.85,
        abw: 18.0,
        doc: 60,
        temperature: 29.0,
        trayAdjustment: 0.10,
      );
      expect(planEmpty.trayFactor, 1.10);
      expect(planEmpty.mealSchedule.length, 4);

      // Tray 25% leftover -> -15% (trayFactor = 0.85)
      final plan25 = feedService.calculateDailyFeed(
        density: 50,
        areaHa: 1.0,
        survivalRate: 0.85,
        abw: 18.0,
        doc: 60,
        temperature: 29.0,
        trayAdjustment: -0.15,
      );
      expect(plan25.trayFactor, 0.85);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FeedAiPage()),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Empty (+10%)'), findsOneWidget);
      expect(find.textContaining('25% Left (-15%)'), findsOneWidget);
      expect(find.textContaining('06:00 AM'), findsOneWidget);
      expect(find.textContaining('09:00 PM'), findsOneWidget);
    });

    testWidgets('Feature 3: Telugu Voice NLU spoken Telugu numbers & TelemetryLoggingPage',
        (WidgetTester tester) async {
      _configureTallViewport(tester);
      const nlu = TeluguVoiceNLUService();
      final parsed = nlu.parseVoiceInput(
        'చెరువు ఒకటిలో పీహెచ్ 7.9 ఉంది, ఆక్సిజన్ 4.8, అమ్మోనియా సున్నా, మేత 30 కేజీలు వేసాను',
      );
      expect(parsed.pondIndex, 1);
      expect(parsed.ph, 7.9);
      expect(parsed.doLevel, 4.8);
      expect(parsed.ammonia, 0.0);
      expect(parsed.feedKg, 30.0);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: TelemetryLoggingPage()),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Alkalinity (ppm)'), findsOneWidget);
      expect(find.textContaining('చెరువు ఒకటిలో పీహెచ్ 7.9'), findsOneWidget);
    });

    testWidgets('Feature 4: 24/7 Hypoxia Emergency Alarm & Weather Intelligence',
        (WidgetTester tester) async {
      _configureTallViewport(tester);
      final weatherService = WeatherService();
      const alarmService = EmergencyAlarmService();

      final criticalWeather = WeatherData(
        temperature: 32.0,
        feelsLike: 36.0,
        humidity: 88,
        cloudCover: 90,
        windSpeed: 2.0,
        rainfall: 12.0,
        condition: 'Rain',
        description: 'overcast rain',
        locationName: 'Bhimavaram',
        timestamp: DateTime.now(),
      );
      final hypoxia = weatherService.evaluateHypoxiaRisk(criticalWeather);
      expect(hypoxia.isHighRisk, isTrue);

      final alarm = alarmService.evaluateHypoxiaForecast(
        riskScore: hypoxia.riskScore,
        locationName: 'Bhimavaram',
        triggerSoundAndHaptics: false,
      );
      expect(alarm, isNotNull);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: WeatherPage()),
        ),
      );
      await tester.pump();

      final simBtn = find.textContaining('Simulate 3:00 AM Midnight Hypoxia Emergency Siren');
      expect(simBtn, findsOneWidget);
      await tester.tap(simBtn);
      await tester.pump();

      expect(
        find.textContaining('3:00 AM Emergency Alert: Midnight DO Crash Risk'),
        findsOneWidget,
      );
    });

    test('Feature 5: 100% Offline-First Sync Engine FIFO Queue & Snapshot Persistence',
        () async {
      final syncService = OfflineSyncService();
      await syncService.clearQueue();

      await syncService.enqueue({
        'table': 'water_logs',
        'action': 'insert',
        'payload': {'pond_id': '1', 'ph': 7.9, 'dissolved_oxygen': 4.8},
      });
      await syncService.enqueue({
        'table': 'feed_logs',
        'action': 'insert',
        'payload': {'pond_id': '1', 'daily_feed_kg': 30.0},
      });

      final count = await syncService.getQueueLength();
      expect(count, 2);

      final flushed = await syncService.drainQueue(
        executor: (item) async => true,
      );
      expect(flushed, 2);
      expect(await syncService.getQueueLength(), 0);
    });

    testWidgets('Feature 6: Live Mandi / Market Prices & Harvest Timing Optimizer',
        (WidgetTester tester) async {
      _configureTallViewport(tester);
      final prices = defaultAndhraMandiPrices();
      expect(
        prices.any((p) => p['district'] == 'Kaikaluru (Kolleru / Eluru)'),
        isTrue,
      );
      expect(prices.any((p) => p['count_size'] == '70c'), isTrue);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: MandiPricesPage()),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Harvest Timing Optimizer'), findsOneWidget);
      expect(find.textContaining('Kaikaluru (Kolleru / Eluru)'), findsWidgets);
      expect(find.text('70c'), findsWidgets);
    });

    testWidgets('Feature 7: AI Camera Shrimp ABW & Growth Curve vs Benchmark',
        (WidgetTester tester) async {
      _configureTallViewport(tester);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AbwCameraSamplingPage()),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Pond Growth Curve vs. Industry Benchmark'), findsOneWidget);
      expect(find.textContaining('Save Sample & Update Pond ABW'), findsOneWidget);
    });

    testWidgets('Feature 8: Farm Finance Ledger & PrawnCredit Score Engine',
        (WidgetTester tester) async {
      _configureTallViewport(tester);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: PrawnCreditPage()),
        ),
      );
      await tester.pump();

      expect(find.textContaining('PrawnCredit & Finance'), findsOneWidget);
      expect(find.textContaining('Log Expense'), findsOneWidget);
    });

    testWidgets('Feature 9: Multi-Pond Dashboard & Bilingual Threshold Status Badges',
        (WidgetTester tester) async {
      _configureTallViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentLocaleProvider.overrideWith((ref) => const Locale('te')),
            pondListProvider.overrideWith((ref) => [
                  {
                    'id': '1',
                    'name': 'Pond 1 (North Field)',
                    'areaHa': 1.2,
                    'stockingDensity': 50,
                    'doc': 52,
                    'species': 'L. vannamei',
                  },
                ]),
            waterLogsProvider.overrideWith((ref) => [
                  {
                    'id': 'w1',
                    'pond_id': '1',
                    'ph': 7.85,
                    'dissolved_oxygen': 4.8,
                    'salinity': 18.0,
                    'ammonia': 0.02,
                  },
                ]),
          ],
          child: const MaterialApp(home: PondListPage()),
        ),
      );
      await tester.pump();

      expect(find.text('Optimal (సురక్షితం)'), findsOneWidget);
    });

    testWidgets('Feature 10: One-Click PDF Crop Reports & Farmer Community Hub Outbreak Alert',
        (WidgetTester tester) async {
      _configureTallViewport(tester);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: CommunityPage()),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Regional Outbreak Alert (10 km Radius)'), findsOneWidget);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ReportsPage()),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Available Exportable Reports'), findsOneWidget);
      expect(find.byTooltip('Preview Full Crop Audit'), findsOneWidget);
    });
  });
}
