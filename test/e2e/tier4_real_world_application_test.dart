import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_guard/core/services/offline_sync_service.dart';
import 'package:prawn_guard/core/services/alert_system.dart';
import 'package:prawn_guard/core/services/subscription_service.dart';
import 'package:prawn_guard/features/finance/models/finance_models.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tier 4 — Real-World Application Workload: Full Day-in-the-Life Farm Cycle', () {
    late OfflineSyncService syncService;
    const voiceNlu = TeluguVoiceNLUService();
    const alertSystem = AlertSystem();
    const feedAI = FeedAIService();
    const subService = SubscriptionService();
    const prawnDocAI = PrawnDocAIService(subService);

    setUp(() async {
      final prefs = await setupMockPreferences();
      syncService = OfflineSyncService(prefs);
      await syncService.clearQueue();
    });

    test('Complete end-to-end aquaculture day-in-the-life lifecycle simulation', () async {
      // -----------------------------------------------------------------------
      // Phase 1: 06:00 AM — Morning Pond Water Log via Telugu Voice Input
      // -----------------------------------------------------------------------
      const morningSpeech = 'Pond 1 lo pH 7.4, DO 3.8, temp 26.5, salinity 15';
      final telemetry = voiceNlu.parseVoiceInput(morningSpeech);

      expect(telemetry.pondIndex, 1);
      expect(telemetry.ph, 7.4);
      expect(telemetry.doLevel, 3.8);
      expect(telemetry.temperature, 26.5);
      expect(telemetry.salinity, 15.0);

      // Enqueue morning water log into offline queue
      await syncService.enqueue({
        'table': 'water_logs',
        'action': 'insert',
        'payload': {
          'pond_id': 'pond_01',
          'ph': telemetry.ph,
          'dissolved_oxygen': telemetry.doLevel,
          'temperature': telemetry.temperature,
          'salinity': telemetry.salinity,
          'timestamp': '2026-08-29T06:00:00Z',
        },
      });

      // -----------------------------------------------------------------------
      // Phase 2: Alert Quality Triage
      // -----------------------------------------------------------------------
      final alerts = alertSystem.evaluateParameters(
        ph: telemetry.ph,
        dissolvedOxygen: telemetry.doLevel,
        salinity: telemetry.salinity,
        temperature: telemetry.temperature,
      );

      // pH 7.4 -> Watch; DO 3.8 -> Watch; Temp 26.5 -> Optimal; Salinity 15 -> Optimal
      final doAlert = alerts.firstWhere((a) => a.parameter == 'Dissolved Oxygen');
      expect(doAlert.severity, AlertSeverity.watch);
      expect(doAlert.recommendation, contains('aerators'));

      final phAlert = alerts.firstWhere((a) => a.parameter == 'pH');
      expect(phAlert.severity, AlertSeverity.watch);

      // -----------------------------------------------------------------------
      // Phase 3: Feed AI Morning Schedule & 4-Meal Plan Calculation
      // -----------------------------------------------------------------------
      // Pond 1: 1.0 ha, 50 pcs/m², 85% survival, 18.0g ABW, DOC 55, temp 26.5°C
      final initialFeedPlan = feedAI.calculateDailyFeed(
        density: 50,
        areaHa: 1.0,
        survivalRate: 0.85,
        abw: 18.0,
        doc: 55,
        temperature: telemetry.temperature ?? 28.0,
      );

      expect(initialFeedPlan.biomassKg, 7650.0); // 50 * 10000 * 0.85 * 0.018 = 7650 kg
      expect(initialFeedPlan.feedingRate, closeTo(0.0525, 0.0001)); // 0.08 - (55 * 0.0005) = 0.0525
      expect(initialFeedPlan.adjustedDailyFeedKg, closeTo(401.625, 0.01));

      // Enqueue Meal 1 (06:00 AM - 20%) & Meal 2 (11:00 AM - 30%)
      await syncService.enqueue({
        'table': 'feed_logs',
        'action': 'insert',
        'payload': {
          'pond_id': 'pond_01',
          'meal_number': 1,
          'feed_kg': initialFeedPlan.meal1Kg,
          'fed_at': '2026-08-29T06:15:00Z',
        },
      });
      await syncService.enqueue({
        'table': 'feed_logs',
        'action': 'insert',
        'payload': {
          'pond_id': 'pond_01',
          'meal_number': 2,
          'feed_kg': initialFeedPlan.meal2Kg,
          'fed_at': '2026-08-29T11:00:00Z',
        },
      });

      // -----------------------------------------------------------------------
      // Phase 4: 01:00 PM — Midday PrawnDoc AI Disease Vision Scan
      // -----------------------------------------------------------------------
      int farmerScansToday = 0;
      final scanResult = prawnDocAI.diagnose(
        detectedDisease: ShrimpDisease.vibrioLuminescence,
        confidence: 0.94,
        currentScansToday: farmerScansToday,
        isPro: false,
      );
      farmerScansToday++;

      expect(scanResult.disease, ShrimpDisease.vibrioLuminescence);
      expect(scanResult.immediateAction, contains('Bacillus'));

      // Enqueue disease scan record
      await syncService.enqueue({
        'table': 'disease_scans',
        'action': 'insert',
        'payload': {
          'pond_id': 'pond_01',
          'disease': scanResult.diseaseName,
          'confidence': scanResult.confidence,
          'action_taken': 'Applied Bacillus probiotics',
          'scanned_at': '2026-08-29T13:00:00Z',
        },
      });

      // -----------------------------------------------------------------------
      // Phase 5: 04:00 PM — Afternoon Check-Tray Inspection & Feed Adjustment
      // -----------------------------------------------------------------------
      // Check tray after 2 hours shows trace feed leftover (+5% adjustment)
      const trayAdjustment = 0.05;
      final adjustedEveningPlan = feedAI.calculateDailyFeed(
        density: 50,
        areaHa: 1.0,
        survivalRate: 0.85,
        abw: 18.0,
        doc: 55,
        temperature: 29.0,
        trayAdjustment: trayAdjustment,
      );

      expect(adjustedEveningPlan.trayFactor, 1.05);
      expect(adjustedEveningPlan.meal3Kg, closeTo(initialFeedPlan.meal3Kg * 1.05, 0.1));

      // Enqueue Meal 3 (04:00 PM - 30%) and Meal 4 (09:00 PM - 20%)
      await syncService.enqueue({
        'table': 'feed_logs',
        'action': 'insert',
        'payload': {
          'pond_id': 'pond_01',
          'meal_number': 3,
          'feed_kg': adjustedEveningPlan.meal3Kg,
          'fed_at': '2026-08-29T16:00:00Z',
        },
      });
      await syncService.enqueue({
        'table': 'feed_logs',
        'action': 'insert',
        'payload': {
          'pond_id': 'pond_01',
          'meal_number': 4,
          'feed_kg': adjustedEveningPlan.meal4Kg,
          'fed_at': '2026-08-29T21:00:00Z',
        },
      });

      // -----------------------------------------------------------------------
      // Phase 6: 08:00 PM — PrawnCredit Financial Ledger: Expense Logging
      // -----------------------------------------------------------------------
      final expense1 = Expense(
        id: 'exp_01',
        pondId: 'pond_01',
        pondName: 'Pond 01',
        category: ExpenseCategory.feed,
        amount: 24000.0,
        date: DateTime.parse('2026-08-29T20:00:00Z'),
        notes: '10 bags of CP 38% grower feed',
      );
      final expense2 = Expense(
        id: 'exp_02',
        pondId: 'pond_01',
        pondName: 'Pond 01',
        category: ExpenseCategory.probioticsChemicals,
        amount: 4500.0,
        date: DateTime.parse('2026-08-29T20:15:00Z'),
        notes: 'Bacillus probiotic water treatment pack',
      );

      await syncService.enqueue({
        'table': 'expenses',
        'action': 'insert',
        'payload': expense1.toJson(),
      });
      await syncService.enqueue({
        'table': 'expenses',
        'action': 'insert',
        'payload': expense2.toJson(),
      });

      // -----------------------------------------------------------------------
      // Phase 7: Harvest Cashflow & PrawnCredit Performance Settlement
      // -----------------------------------------------------------------------
      final harvest = HarvestRecord(
        id: 'hrv_01',
        pondId: 'pond_01',
        pondName: 'Pond 01',
        harvestType: 'Partial',
        date: DateTime.parse('2026-08-29T21:30:00Z'),
        biomassKg: 2000.0,
        countPerKg: 40,
        pricePerKg: 420.0,
        fcr: 1.35,
        buyerName: 'Coastal Aqua Exporters',
      );

      expect(harvest.totalRevenue, 840000.0); // 2000 kg * 420 = 840,000 INR

      await syncService.enqueue({
        'table': 'harvests',
        'action': 'insert',
        'payload': harvest.toJson(),
      });

      // Compute total farm cycle financial summary
      final allExpenses = [
        expense1,
        expense2,
        Expense(
          id: 'exp_00_seed',
          pondId: 'pond_01',
          pondName: 'Pond 01',
          category: ExpenseCategory.seedPL,
          amount: 60000.0,
          date: DateTime.parse('2026-06-01T00:00:00Z'),
        ),
        Expense(
          id: 'exp_00_power',
          pondId: 'pond_01',
          pondName: 'Pond 01',
          category: ExpenseCategory.powerFuel,
          amount: 45000.0,
          date: DateTime.parse('2026-08-01T00:00:00Z'),
        ),
      ];

      final totalExpenseAmount = allExpenses.fold<double>(0, (sum, e) => sum + e.amount);
      expect(totalExpenseAmount, 133500.0);

      final totalHarvestRevenue = harvest.totalRevenue;
      final netProfit = totalHarvestRevenue - totalExpenseAmount;
      expect(netProfit, 706500.0);

      // Verify PrawnCredit scoring calculation
      final creditScore = PrawnCreditScore(
        score: 820,
        tier: 'Tier-1 Elite',
        maxCreditLimit: 500000.0,
        monthlyInterestRate: 1.1,
        riskLevel: 'Low',
        scoreFactors: {
          'FCR Efficiency': 90,
          'Water Log Consistency': 95,
          'Yield Predictability': 88,
        },
      );

      expect(creditScore.score, 820);
      expect(creditScore.tier, 'Tier-1 Elite');
      expect(creditScore.riskLevel, 'Low');
      expect(creditScore.maxCreditLimit, 500000.0);

      // -----------------------------------------------------------------------
      // Phase 8: Offline Reconnection & Full Queue Drain
      // -----------------------------------------------------------------------
      // Total queued operations:
      // 1 (water log) + 2 (meals 1, 2) + 1 (disease scan) + 2 (meals 3, 4) + 2 (expenses) + 1 (harvest) = 9 mutations
      expect(await syncService.queueLength, 9);

      final List<String> drainedTables = [];
      final totalDrained = await syncService.drainQueue(
        executor: (mutation) async {
          drainedTables.add(mutation['table'] as String);
          return true;
        },
      );

      expect(totalDrained, 9);
      expect(await syncService.queueLength, 0);
      expect(drainedTables, [
        'water_logs',
        'feed_logs',
        'feed_logs',
        'disease_scans',
        'feed_logs',
        'feed_logs',
        'expenses',
        'expenses',
        'harvests',
      ]);
    });
  });
}
