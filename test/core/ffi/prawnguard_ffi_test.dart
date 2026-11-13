import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_guard/core/ffi/prawnguard_ffi.dart';

void main() {
  group('PrawnGuardFfi — Native C-ABI Integration Bridge', () {
    test('instantiates singleton and checks availability', () {
      final ffi = PrawnGuardFfi.instance;
      expect(ffi, isNotNull);

      if (Platform.isWindows) {
        expect(ffi.isAvailable, isTrue);
        final version = ffi.getVersion();
        expect(version, contains('0.1.0'));
      }
    });

    test('evaluates getMandiPrice via native C-ABI', () {
      final ffi = PrawnGuardFfi.instance;
      if (!ffi.isAvailable) return;

      final price = ffi.getMandiPrice('Bhimavaram', 30);
      expect(price, isNotNull);
      expect(price!, greaterThan(350.0));
    });

    test('evaluates estimateHarvest via native C-ABI', () {
      final ffi = PrawnGuardFfi.instance;
      if (!ffi.isAvailable) return;

      final result = ffi.estimateHarvest('Bhimavaram', 5000.0, 30);
      expect(result, isNotNull);
      expect(result!['gross_revenue_inr'], greaterThan(0.0));
      expect(result['net_revenue_inr'], greaterThan(0.0));
    });

    test('evaluates verifySecurity via native C-ABI', () {
      final ffi = PrawnGuardFfi.instance;
      if (!ffi.isAvailable) return;

      final report = ffi.verifySecurity();
      expect(report, isNotNull);
      expect(report!['opaque_predicates_passed'], isTrue);
      expect(report['defense_score'], 98);
    });

    test('evaluates calculateFeed via native C-ABI', () {
      final ffi = PrawnGuardFfi.instance;
      if (!ffi.isAvailable) return;

      final plan = ffi.calculateFeed(
        stockingDensityPerM2: 60.0,
        areaHa: 1.0,
        survivalRate: 0.85,
        currentAbwG: 18.0,
        doc: 75,
        waterTempC: 29.0,
      );
      expect(plan, isNotNull);
      expect(plan!['adjusted_daily_feed_kg'], greaterThan(0.0));
    });

    test('evaluates evaluateWaterQuality via native C-ABI', () {
      final ffi = PrawnGuardFfi.instance;
      if (!ffi.isAvailable) return;

      final wq = ffi.evaluateWaterQuality(
        ph: 7.8,
        doMgL: 5.5,
        salinityPpt: 15.0,
        tempC: 29.0,
        ammoniaTanMgL: 0.2,
        alkalinityPpm: 120.0,
      );
      expect(wq, isNotNull);
      expect(wq!['severity'], isNotNull);
    });

    test('evaluates parseTeluguVoice via native C-ABI', () {
      final ffi = PrawnGuardFfi.instance;
      if (!ffi.isAvailable) return;

      final res = ffi.parseTeluguVoice('cheruvu 1 lo pH 7.8 DO 3.2');
      expect(res, isNotNull);
      expect(res!['ph'], 7.8);
    });

    test('evaluates analyzeAbw via native C-ABI', () {
      final ffi = PrawnGuardFfi.instance;
      if (!ffi.isAvailable) return;

      final res = ffi.analyzeAbw([12.0, 12.5, 13.0, 12.2, 12.8], 65);
      expect(res, isNotNull);
      expect(res!['mean_abw_grams'], greaterThan(15.0));
    });

    test('evaluates evaluateCreditScore via native C-ABI', () {
      final ffi = PrawnGuardFfi.instance;
      if (!ffi.isAvailable) return;

      final res = ffi.evaluateCreditScore(
        ponds: [
          {
            'id': 'p1',
            'user_id': 'u1',
            'name': 'Pond 1',
            'species': 'vannamei',
            'area_ha': 1.0,
            'stocking_density': 60.0,
            'doc': 75,
            'stocking_date': '2026-08-01',
            'initial_abw': 0.02,
            'current_abw': 18.0,
            'survival_rate': 0.88,
            'status': 'Active',
            'version': 1,
          }
        ],
        totalFeedKg: 5000.0,
      );
      expect(res, isNotNull);
      expect(res!['score'], greaterThan(700));
    });
  });
}
