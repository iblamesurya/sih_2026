import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prawn_guard/core/theme/app_theme.dart';
import 'package:prawn_guard/core/services/auth_service.dart';
import 'package:prawn_guard/core/services/offline_sync_service.dart';
import 'package:prawn_guard/core/services/alert_system.dart';
import 'package:prawn_guard/core/services/subscription_service.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    final binaryMessenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    binaryMessenger.setMockMessageHandler('flutter/assets', (ByteData? message) async {
      if (message == null) return null;
      final key = utf8.decode(message.buffer.asUint8List());
      if (key == 'AssetManifest.bin') {
        const codec = StandardMessageCodec();
        return codec.encodeMessage(<String, List<Object>>{
          'google_fonts/SpaceGrotesk-Bold.ttf': ['google_fonts/SpaceGrotesk-Bold.ttf'],
          'google_fonts/SpaceGrotesk-SemiBold.ttf': ['google_fonts/SpaceGrotesk-SemiBold.ttf'],
          'google_fonts/Outfit-Regular.ttf': ['google_fonts/Outfit-Regular.ttf'],
          'google_fonts/Outfit-SemiBold.ttf': ['google_fonts/Outfit-SemiBold.ttf'],
        });
      }
      if (key == 'AssetManifest.json') {
        return ByteData.sublistView(utf8.encode('{}'));
      }
      if (key == 'FontManifest.json') {
        return ByteData.sublistView(utf8.encode('[]'));
      }
      // Return dummy 100-byte TTF buffer
      return ByteData(100);
    });
  });

  group('Tier 1 — Feature Coverage: F-01 Deep Ocean Matte Theme & Typography', () {
    test('1.1 AppColors contains exact Deep Ocean Matte primary palette tokens', () {
      expect(AppColors.background, const Color(0xFF0A0A0B));
      expect(AppColors.surfaceBase, const Color(0xFF0F0F0F));
      expect(AppColors.surface, const Color(0xFF171717));
      expect(AppColors.surfaceElevated, const Color(0xFF222222));
      expect(AppColors.primary, const Color(0xFF00E5FF));
      expect(AppColors.secondary, const Color(0xFF10B981));
    });

    test('1.2 AppColors contains exact alert and feedback palette tokens', () {
      expect(AppColors.alertUrgent, const Color(0xFFE55C5C));
      expect(AppColors.alertWatch, const Color(0xFFE5B05C));
      expect(AppColors.alertInfo, const Color(0xFF5C9EE5));
      expect(AppColors.cardBorder, const Color(0x14FFFFFF));
      expect(AppColors.glassBackground, const Color(0x0DFFFFFF));
    });

    test('1.3 AppColors contains text hierarchy color tokens', () {
      expect(AppColors.textPrimary, const Color(0xFFFFFFFF));
      expect(AppColors.textSecondary, const Color(0xFF9E9E9E));
      expect(AppColors.textTertiary, const Color(0xFF616161));
    });

    test('1.4 AppTheme.darkTheme configures Material 3 dark surface and card properties', () {
      final theme = AppTheme.darkTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.cardColor, AppColors.surface);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.cardTheme.color, AppColors.surface);
      final shape = theme.cardTheme.shape as RoundedRectangleBorder?;
      expect(shape, isNotNull);
      expect(shape!.side.color, AppColors.cardBorder);
      expect(shape.side.width, 1.0);
    });

    test('1.5 AppTheme.darkTheme text styles use Space Grotesk for headers and Outfit for body', () {
      final textTheme = AppTheme.darkTheme.textTheme;
      expect(textTheme.displayLarge?.fontFamily, contains('SpaceGrotesk'));
      expect(textTheme.headlineMedium?.fontFamily, contains('SpaceGrotesk'));
      expect(textTheme.titleLarge?.fontFamily, contains('SpaceGrotesk'));
      expect(textTheme.bodyLarge?.fontFamily, contains('Outfit'));
      expect(textTheme.bodyMedium?.fontFamily, contains('Outfit'));
      expect(textTheme.labelSmall?.fontFamily, contains('Outfit'));
    });
  });

  group('Tier 1 — Feature Coverage: F-02 Bilingual Localization Subsystem', () {
    late Map<String, dynamic> enJson;
    late Map<String, dynamic> teJson;

    setUpAll(() {
      final enFile = File('lib/l10n/en.json');
      final teFile = File('lib/l10n/te.json');
      expect(enFile.existsSync(), isTrue, reason: 'en.json must exist');
      expect(teFile.existsSync(), isTrue, reason: 'te.json must exist');
      enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      teJson = jsonDecode(teFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('2.1 en.json and te.json are valid non-empty JSON dictionaries', () {
      expect(enJson.isNotEmpty, isTrue);
      expect(teJson.isNotEmpty, isTrue);
      expect(enJson.length, greaterThanOrEqualTo(20));
      expect(teJson.length, greaterThanOrEqualTo(20));
    });

    test('2.2 en.json and te.json maintain 100% key parity without missing entries', () {
      final enKeys = enJson.keys.toSet();
      final teKeys = teJson.keys.toSet();
      final missingInTe = enKeys.difference(teKeys);
      final missingInEn = teKeys.difference(enKeys);
      expect(missingInTe, isEmpty, reason: 'Keys in en.json missing from te.json');
      expect(missingInEn, isEmpty, reason: 'Keys in te.json missing from en.json');
    });

    test('2.3 Essential app and finance localization keys are present', () {
      final expectedKeys = [
        'appName',
        'prawnCreditTitle',
        'financeOverview',
        'expenses',
        'harvests',
        'creditScore',
        'totalExpenses',
        'harvestRevenue',
        'netProfit',
        'addExpense',
        'addHarvest',
        'applyCredit',
        'creditLimit',
        'category',
        'amount',
        'date',
        'pond',
        'biomassKg',
        'countPerKg',
        'pricePerKg',
        'totalRevenue',
        'exportInvoice',
        'shareWhatsapp',
        'tier1Eligible',
        'fcrRating',
      ];
      for (final key in expectedKeys) {
        expect(enJson.containsKey(key), isTrue, reason: 'en.json missing $key');
        expect(teJson.containsKey(key), isTrue, reason: 'te.json missing $key');
      }
    });

    test('2.4 All localization values are non-empty strings', () {
      for (final entry in enJson.entries) {
        expect(entry.value, isA<String>());
        expect((entry.value as String).trim().isNotEmpty, isTrue);
      }
      for (final entry in teJson.entries) {
        expect(entry.value, isA<String>());
        expect((entry.value as String).trim().isNotEmpty, isTrue);
      }
    });

    test('2.5 te.json values contain authentic Telugu Unicode script characters', () {
      final teluguUnicodeRegex = RegExp(r'[\u0C00-\u0C7F]');
      int teluguCharCount = 0;
      for (final val in teJson.values) {
        if (teluguUnicodeRegex.hasMatch(val as String)) {
          teluguCharCount++;
        }
      }
      expect(teluguCharCount, greaterThanOrEqualTo(teJson.length - 2));
    });
  });

  group('Tier 1 — Feature Coverage: F-03 AuthService Phone & Email Mapping', () {
    test('3.1 Normalizes standard 10-digit Indian mobile number', () {
      expect(AuthService.normalizePhone('9876543210'), '9876543210');
      expect(AuthService.phoneToEmail('9876543210'), '9876543210@prawnguard.app');
    });

    test('3.2 Normalizes mobile numbers with +91 country prefix and whitespace', () {
      expect(AuthService.normalizePhone('+91 98765 43210'), '9876543210');
      expect(AuthService.normalizePhone('+919876543210'), '9876543210');
      expect(AuthService.phoneToEmail('+91 98765 43210'), '9876543210@prawnguard.app');
    });

    test('3.3 Normalizes mobile numbers with leading 0 or 91 country code prefix', () {
      expect(AuthService.normalizePhone('09876543210'), '9876543210');
      expect(AuthService.normalizePhone('919876543210'), '9876543210');
      expect(AuthService.phoneToEmail('09876543210'), '9876543210@prawnguard.app');
    });

    test('3.4 Normalizes numbers with special characters, dashes, and parentheses', () {
      expect(AuthService.normalizePhone('+91 (987) 654-3210'), '9876543210');
      expect(AuthService.phoneToEmail('+91 (987) 654-3210'), '9876543210@prawnguard.app');
    });

    test('3.5 Normalizes all valid Indian mobile starter digits (6, 7, 8, 9)', () {
      expect(AuthService.normalizePhone('6123456789'), '6123456789');
      expect(AuthService.normalizePhone('7890123456'), '7890123456');
      expect(AuthService.normalizePhone('8901234567'), '8901234567');
      expect(AuthService.normalizePhone('9012345678'), '9012345678');
    });
  });

  group('Tier 1 — Feature Coverage: F-04 OfflineSyncService Mutation Queuing & FIFO', () {
    late OfflineSyncService syncService;

    setUp(() async {
      final prefs = await setupMockPreferences();
      syncService = OfflineSyncService(prefs);
      await syncService.clearQueue();
    });

    test('4.1 Enqueuing a mutation enriches payload with metadata (id, created_at, status)', () async {
      await syncService.enqueue({
        'table': 'water_logs',
        'action': 'insert',
        'payload': {'pond_id': 'p1', 'ph': 7.8},
      });

      final queue = await syncService.getQueue();
      expect(queue.length, 1);
      final item = queue.first;
      expect(item['table'], 'water_logs');
      expect(item['action'], 'insert');
      expect(item['id'], isNotNull);
      expect(item['created_at'], isNotNull);
      expect(item['status'], 'pending');
    });

    test('4.2 getQueue() preserves strict FIFO insertion order', () async {
      await syncService.enqueue({'seq': 1, 'table': 'feed_logs'});
      await syncService.enqueue({'seq': 2, 'table': 'water_logs'});
      await syncService.enqueue({'seq': 3, 'table': 'expenses'});

      final queue = await syncService.getQueue();
      expect(queue.length, 3);
      expect(queue[0]['seq'], 1);
      expect(queue[1]['seq'], 2);
      expect(queue[2]['seq'], 3);
    });

    test('4.3 queueLength and getQueueLength() return accurate counts', () async {
      expect(await syncService.queueLength, 0);
      await syncService.enqueue({'action': 'insert'});
      expect(await syncService.queueLength, 1);
      expect(await syncService.getQueueLength(), 1);
      await syncService.enqueue({'action': 'update'});
      expect(await syncService.queueLength, 2);
    });

    test('4.4 clearQueue() completely flushes all mutations', () async {
      await syncService.enqueue({'item': 1});
      await syncService.enqueue({'item': 2});
      expect(await syncService.queueLength, 2);

      await syncService.clearQueue();
      expect(await syncService.queueLength, 0);
      expect(await syncService.getQueue(), isEmpty);
    });

    test('4.5 drainQueue() processes mutations sequentially in FIFO order', () async {
      final List<int> processedOrder = [];
      await syncService.enqueue({'op': 101});
      await syncService.enqueue({'op': 102});
      await syncService.enqueue({'op': 103});

      final processedCount = await syncService.drainQueue(
        executor: (mutation) async {
          processedOrder.add(mutation['op'] as int);
          return true;
        },
      );

      expect(processedCount, 3);
      expect(processedOrder, [101, 102, 103]);
      expect(await syncService.queueLength, 0);
    });
  });

  group('Tier 1 — Feature Coverage: F-06 AlertSystem Individual Parameter Evaluations', () {
    const alertSystem = AlertSystem();

    test('5.1 Evaluates pH across optimal, watch, and urgent ranges', () {
      // Optimal: 7.5 - 8.5
      final opt = alertSystem.evaluatePh(7.8);
      expect(opt.severity, AlertSeverity.optimal);

      // Watch Low: 7.0 - 7.5
      final watchLow = alertSystem.evaluatePh(7.2);
      expect(watchLow.severity, AlertSeverity.watch);

      // Watch High: 8.5 - 9.0
      final watchHigh = alertSystem.evaluatePh(8.8);
      expect(watchHigh.severity, AlertSeverity.watch);

      // Urgent Low: < 7.0
      final urgLow = alertSystem.evaluatePh(6.4);
      expect(urgLow.severity, AlertSeverity.urgent);

      // Urgent High: > 9.0
      final urgHigh = alertSystem.evaluatePh(9.3);
      expect(urgHigh.severity, AlertSeverity.urgent);
    });

    test('5.2 Evaluates Dissolved Oxygen (DO) across optimal, watch, and urgent ranges', () {
      final opt = alertSystem.evaluateDO(5.5);
      expect(opt.severity, AlertSeverity.optimal);

      final watch = alertSystem.evaluateDO(3.5);
      expect(watch.severity, AlertSeverity.watch);

      final urgent = alertSystem.evaluateDO(2.4);
      expect(urgent.severity, AlertSeverity.urgent);
    });

    test('5.3 Evaluates Ammonia (NH3) across optimal, watch, and urgent ranges', () {
      final opt = alertSystem.evaluateAmmonia(0.02);
      expect(opt.severity, AlertSeverity.optimal);

      final watch = alertSystem.evaluateAmmonia(0.07);
      expect(watch.severity, AlertSeverity.watch);

      final urgent = alertSystem.evaluateAmmonia(0.25);
      expect(urgent.severity, AlertSeverity.urgent);
    });

    test('5.4 Evaluates Alkalinity across optimal and watch ranges', () {
      final opt = alertSystem.evaluateAlkalinity(130.0);
      expect(opt.severity, AlertSeverity.optimal);

      final watchLow = alertSystem.evaluateAlkalinity(75.0);
      expect(watchLow.severity, AlertSeverity.watch);

      final watchHigh = alertSystem.evaluateAlkalinity(220.0);
      expect(watchHigh.severity, AlertSeverity.watch);
    });

    test('5.5 Evaluates Salinity and Temperature water quality parameters', () {
      final salOpt = alertSystem.evaluateSalinity(18.0);
      expect(salOpt.severity, AlertSeverity.optimal);

      final salWatch = alertSystem.evaluateSalinity(3.0);
      expect(salWatch.severity, AlertSeverity.watch);

      final tempOpt = alertSystem.evaluateTemperature(28.0);
      expect(tempOpt.severity, AlertSeverity.optimal);

      final tempWatch = alertSystem.evaluateTemperature(22.0);
      expect(tempWatch.severity, AlertSeverity.watch);
    });
  });

  group('Tier 1 — Feature Coverage: F-07 FeedAIService Bio-Energetic Engine', () {
    const feedAI = FeedAIService();

    test('6.1 Calculates live biomass accurately from stocking density, area, survival & ABW', () {
      // 50 pcs/m², 1.0 ha (10,000 m²), 80% survival, 15.0g ABW -> (50 * 10000 * 0.8 * 15) / 1000 = 6,000 kg
      final biomass = feedAI.calculateBiomass(
        density: 50,
        areaHa: 1.0,
        survivalRate: 0.80,
        abw: 15.0,
      );
      expect(biomass, 6000.0);
    });

    test('6.2 Calculates DOC-based feeding rate clamped between 3.0% and 8.0%', () {
      // DOC 40 -> 0.08 - (40 * 0.0005) = 0.06 (6.0%)
      final rateDoc40 = feedAI.calculateFeedingRate(40);
      expect(rateDoc40, closeTo(0.06, 0.0001));

      // DOC 10 -> 0.08 - (10 * 0.0005) = 0.075 (7.5%)
      final rateDoc10 = feedAI.calculateFeedingRate(10);
      expect(rateDoc10, closeTo(0.075, 0.0001));
    });

    test('6.3 Temperature adjustment factor scales appropriately with metabolic requirements', () {
      expect(feedAI.calculateTempFactor(22.0), 0.85); // Cold
      expect(feedAI.calculateTempFactor(28.5), 1.00); // Optimal
      expect(feedAI.calculateTempFactor(34.0), 0.90); // Heat stress
    });

    test('6.4 4-Meal daily schedule splits daily ration into exact 20% / 30% / 30% / 20% shares', () {
      final plan = feedAI.calculateDailyFeed(
        density: 40,
        areaHa: 1.0,
        survivalRate: 0.85,
        abw: 16.0,
        doc: 40,
        temperature: 28.0,
      );

      final totalFeed = plan.adjustedDailyFeedKg;
      expect(plan.meal1Kg, closeTo(totalFeed * 0.20, 0.01));
      expect(plan.meal2Kg, closeTo(totalFeed * 0.30, 0.01));
      expect(plan.meal3Kg, closeTo(totalFeed * 0.30, 0.01));
      expect(plan.meal4Kg, closeTo(totalFeed * 0.20, 0.01));
    });

    test('6.5 Sum of all 4 meals equals exactly 100% of adjusted daily feed', () {
      final plan = feedAI.calculateDailyFeed(
        density: 60,
        areaHa: 1.5,
        survivalRate: 0.90,
        abw: 20.0,
        doc: 65,
        temperature: 29.0,
        trayAdjustment: 0.05,
      );

      expect(plan.mealsTotal, closeTo(plan.adjustedDailyFeedKg, 0.001));
    });
  });

  group('Tier 1 — Feature Coverage: F-08 TeluguVoiceNLUService Entity Extraction', () {
    const voiceNlu = TeluguVoiceNLUService();

    test('7.1 Extracts pond index from natural speech transcript', () {
      final parsed = voiceNlu.parseVoiceInput('Pond 2 lo telemetry log cheyyi');
      expect(parsed.pondIndex, 2);
    });

    test('7.2 Extracts Dissolved Oxygen (DO) level from speech transcript', () {
      final parsed = voiceNlu.parseVoiceInput('DO 5.2 mg/l recorded');
      expect(parsed.doLevel, 5.2);
    });

    test('7.3 Extracts pH level from speech transcript', () {
      final parsed = voiceNlu.parseVoiceInput('morning pH 7.8 vachindi');
      expect(parsed.ph, 7.8);
    });

    test('7.4 Extracts feed quantity in kilograms from speech transcript', () {
      final parsed = voiceNlu.parseVoiceInput('evening feed 25 kg vesamu');
      expect(parsed.feedKg, 25.0);
    });

    test('7.5 Extracts multi-parameter compound utterance in single phrase', () {
      final parsed = voiceNlu.parseVoiceInput(
        'Pond 3 lo pH 8.1, DO 4.8, salinity 16, ammonia 0.04, feed 30 kg',
      );
      expect(parsed.pondIndex, 3);
      expect(parsed.ph, 8.1);
      expect(parsed.doLevel, 4.8);
      expect(parsed.salinity, 16.0);
      expect(parsed.ammonia, 0.04);
      expect(parsed.feedKg, 30.0);
    });
  });

  group('Tier 1 — Feature Coverage: F-09 SubscriptionService Quota Gates', () {
    const subService = SubscriptionService();

    test('8.1 Free tier permits up to 3 scans/day; Pro tier has unlimited allowance', () {
      expect(subService.canPerformScan(currentScansToday: 0, isPro: false), isTrue);
      expect(subService.canPerformScan(currentScansToday: 2, isPro: false), isTrue);
      expect(subService.canPerformScan(currentScansToday: 3, isPro: false), isFalse);

      expect(subService.canPerformScan(currentScansToday: 10, isPro: true), isTrue);
      expect(subService.canPerformScan(currentScansToday: 100, isPro: true), isTrue);
    });

    test('8.2 getRemainingScans correctly decrements for Free tier and returns high count for Pro', () {
      expect(subService.getRemainingScans(currentScansToday: 0, isPro: false), 3);
      expect(subService.getRemainingScans(currentScansToday: 1, isPro: false), 2);
      expect(subService.getRemainingScans(currentScansToday: 3, isPro: false), 0);
      expect(subService.getRemainingScans(currentScansToday: 5, isPro: false), 0);

      expect(subService.getRemainingScans(currentScansToday: 5, isPro: true), 999999);
    });

    test('8.3 checkScanQuota produces informative upgrade prompt upon quota exhaustion', () {
      final allowed = subService.checkScanQuota(currentScansToday: 1, isPro: false);
      expect(allowed.isAllowed, isTrue);
      expect(allowed.remaining, 2);
      expect(allowed.upgradePrompt, isNull);

      final blocked = subService.checkScanQuota(currentScansToday: 3, isPro: false);
      expect(blocked.isAllowed, isFalse);
      expect(blocked.remaining, 0);
      expect(blocked.upgradePrompt, contains('199'));
    });

    test('8.4 Pond quota limits Free tier to 3 ponds and allows unlimited on Pro', () {
      expect(subService.canAddPond(currentPondCount: 0, isPro: false), isTrue);
      expect(subService.canAddPond(currentPondCount: 2, isPro: false), isTrue);
      expect(subService.canAddPond(currentPondCount: 3, isPro: false), isFalse);

      expect(subService.canAddPond(currentPondCount: 50, isPro: true), isTrue);
    });

    test('8.5 Monthly feed calculations and PDF export report quota gates', () {
      expect(subService.canPerformFeedCalculation(currentCalcsThisMonth: 4, isPro: false), isTrue);
      expect(subService.canPerformFeedCalculation(currentCalcsThisMonth: 5, isPro: false), isFalse);
      expect(subService.canPerformFeedCalculation(currentCalcsThisMonth: 10, isPro: true), isTrue);

      expect(subService.canExportReport(currentReportsThisMonth: 2, isPro: false), isTrue);
      expect(subService.canExportReport(currentReportsThisMonth: 3, isPro: false), isFalse);
      expect(subService.canExportReport(currentReportsThisMonth: 10, isPro: true), isTrue);
    });
  });
}
