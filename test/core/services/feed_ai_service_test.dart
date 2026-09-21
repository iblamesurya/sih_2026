import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_guard/core/services/feed_ai_service.dart';

void main() {
  group('FeedAIService — Biomass Calculation', () {
    const feedAI = FeedAIService();

    test('calculates live biomass accurately from stocking density, area in ha, survival & ABW', () {
      // 50 pcs/m², 1.0 ha (10,000 m²), 80% survival (0.80), 15.0g ABW
      // Live count = 50 * 10,000 * 0.80 = 400,000 shrimp
      // Biomass = (400,000 * 15.0) / 1000 = 6,000.0 kg
      final biomass = feedAI.calculateBiomass(
        density: 50,
        areaHa: 1.0,
        survivalRate: 0.80,
        abw: 15.0,
      );
      expect(biomass, 6000.0);
    });

    test('calculates live biomass accurately for different pond sizes and survival rates', () {
      // 60 pcs/m², 1.5 ha (15,000 m²), 90% survival (0.90), 20.0g ABW
      // Total count = 60 * 15,000 = 900,000
      // Live count = 900,000 * 0.90 = 810,000
      // Biomass = (810,000 * 20.0) / 1000 = 16,200.0 kg
      final biomass = feedAI.calculateBiomass(
        density: 60,
        areaHa: 1.5,
        survivalRate: 0.90,
        abw: 20.0,
      );
      expect(biomass, 16200.0);
    });

    test('handles survival rate provided as whole percentage (e.g. 85 instead of 0.85)', () {
      final biomassDecimal = feedAI.calculateBiomass(
        density: 40,
        areaHa: 0.5,
        survivalRate: 0.85,
        abw: 12.0,
      );
      final biomassPercent = feedAI.calculateBiomass(
        density: 40,
        areaHa: 0.5,
        survivalRate: 85.0,
        abw: 12.0,
      );
      expect(biomassDecimal, biomassPercent);
      expect(biomassDecimal, 2040.0);
    });

    test('calculateBiomassFromSqMeters calculates accurately when direct m² is given', () {
      // 40 pcs/m², 5000 m², 85% survival, 16.0g ABW -> (40 * 5000 * 0.85 * 16) / 1000 = 2720 kg
      final biomass = feedAI.calculateBiomassFromSqMeters(
        density: 40,
        areaM2: 5000,
        survivalRate: 0.85,
        abw: 16.0,
      );
      expect(biomass, 2720.0);
    });

    test('zero or negative inputs return 0.0 kg safely without exception or NaN', () {
      expect(
        feedAI.calculateBiomass(density: 0, areaHa: 1.0, survivalRate: 0.85, abw: 15.0),
        0.0,
      );
      expect(
        feedAI.calculateBiomass(density: -50, areaHa: 1.0, survivalRate: 0.85, abw: 15.0),
        0.0,
      );
      expect(
        feedAI.calculateBiomass(density: 50, areaHa: 0.0, survivalRate: 0.85, abw: 15.0),
        0.0,
      );
      expect(
        feedAI.calculateBiomass(density: 50, areaHa: -1.0, survivalRate: 0.85, abw: 15.0),
        0.0,
      );
      expect(
        feedAI.calculateBiomass(density: 50, areaHa: 1.0, survivalRate: 0.0, abw: 15.0),
        0.0,
      );
      expect(
        feedAI.calculateBiomass(density: 50, areaHa: 1.0, survivalRate: -0.5, abw: 15.0),
        0.0,
      );
      expect(
        feedAI.calculateBiomass(density: 50, areaHa: 1.0, survivalRate: 0.85, abw: 0.0),
        0.0,
      );
      expect(
        feedAI.calculateBiomass(density: 50, areaHa: 1.0, survivalRate: 0.85, abw: -10.0),
        0.0,
      );
    });
  });

  group('FeedAIService — DOC-Based Feeding Rate Curve', () {
    const feedAI = FeedAIService();

    test('feeding rate curve decreases linearly with DOC and clamps between 3.0% and 8.0%', () {
      // DOC 0 -> 0.08 (8.0%)
      expect(feedAI.calculateFeedingRate(0), 0.08);

      // DOC 10 -> 0.08 - (10 * 0.0005) = 0.075 (7.5%)
      expect(feedAI.calculateFeedingRate(10), closeTo(0.075, 0.0001));

      // DOC 40 -> 0.08 - (40 * 0.0005) = 0.060 (6.0%)
      expect(feedAI.calculateFeedingRate(40), closeTo(0.060, 0.0001));

      // DOC 60 -> 0.08 - (60 * 0.0005) = 0.050 (5.0%)
      expect(feedAI.calculateFeedingRate(60), closeTo(0.050, 0.0001));

      // DOC 80 -> 0.08 - (80 * 0.0005) = 0.040 (4.0%)
      expect(feedAI.calculateFeedingRate(80), closeTo(0.040, 0.0001));

      // DOC 100 -> 0.08 - (100 * 0.0005) = 0.030 (3.0%)
      expect(feedAI.calculateFeedingRate(100), closeTo(0.030, 0.0001));
    });

    test('clamping at extreme DOC values', () {
      // Negative DOC -> clamped to 0.08
      expect(feedAI.calculateFeedingRate(-10), 0.08);
      expect(feedAI.calculateFeedingRate(-50), 0.08);

      // DOC beyond 100 -> clamped to 0.03
      expect(feedAI.calculateFeedingRate(120), 0.03);
      expect(feedAI.calculateFeedingRate(150), 0.03);
      expect(feedAI.calculateFeedingRate(200), 0.03);
    });
  });

  group('FeedAIService — Temperature Adjustment Factor', () {
    const feedAI = FeedAIService();

    test('scales correctly across temperature regions', () {
      // Cold (< 24.0°C) -> 0.85
      expect(feedAI.calculateTempFactor(20.0), 0.85);
      expect(feedAI.calculateTempFactor(22.5), 0.85);
      expect(feedAI.calculateTempFactor(23.9), 0.85);

      // Optimal (24.0°C to 32.0°C) -> 1.00
      expect(feedAI.calculateTempFactor(24.0), 1.00);
      expect(feedAI.calculateTempFactor(28.0), 1.00);
      expect(feedAI.calculateTempFactor(32.0), 1.00);

      // Heat stress (> 32.0°C) -> 0.90
      expect(feedAI.calculateTempFactor(32.1), 0.90);
      expect(feedAI.calculateTempFactor(35.0), 0.90);
      expect(feedAI.calculateTempFactor(40.0), 0.90);
    });

    test('handles extreme cold and heat safely', () {
      expect(feedAI.calculateTempFactor(-10.0), 0.85);
      expect(feedAI.calculateTempFactor(55.0), 0.90);
    });
  });

  group('FeedAIService — Check-Tray Feedback Adjustments', () {
    const feedAI = FeedAIService();

    test('calculates tray factor from numeric adjustments clamped to [0.80, 1.10]', () {
      expect(feedAI.calculateTrayFactor(null), 1.00);
      expect(feedAI.calculateTrayFactor(0.00), 1.00);
      expect(feedAI.calculateTrayFactor(-0.20), 0.80);
      expect(feedAI.calculateTrayFactor(-0.10), 0.90);
      expect(feedAI.calculateTrayFactor(-0.15), 0.85);
      expect(feedAI.calculateTrayFactor(0.05), 1.05);
      expect(feedAI.calculateTrayFactor(0.10), 1.10);
    });

    test('clamps out-of-bound tray adjustments strictly', () {
      expect(feedAI.calculateTrayFactor(-0.50), 0.80);
      expect(feedAI.calculateTrayFactor(-0.35), 0.80);
      expect(feedAI.calculateTrayFactor(0.25), 1.10);
      expect(feedAI.calculateTrayFactor(0.60), 1.10);
    });

    test('converts CheckTrayStatus enum to appropriate delta', () {
      expect(feedAI.trayAdjustmentFromStatus(CheckTrayStatus.clean), -0.20);
      expect(feedAI.trayAdjustmentFromStatus(CheckTrayStatus.trace), 0.10);
      expect(feedAI.trayAdjustmentFromStatus(CheckTrayStatus.normal), -0.10);
      expect(feedAI.trayAdjustmentFromStatus(CheckTrayStatus.heavy), -0.15);
      expect(feedAI.trayAdjustmentFromStatus(CheckTrayStatus.uneaten), -0.20);
    });
  });

  group('FeedAIService — 4-Meal Daily Schedule & Distribution', () {
    const feedAI = FeedAIService();

    test('distributes feed into exact 20% / 30% / 30% / 20% splits', () {
      final plan = feedAI.calculateDailyFeed(
        density: 40,
        areaHa: 1.0,
        survivalRate: 0.85,
        abw: 16.0,
        doc: 40,
        temperature: 28.0,
      );

      final total = plan.adjustedDailyFeedKg;
      expect(plan.meal1Kg, closeTo(total * 0.20, 0.001));
      expect(plan.meal2Kg, closeTo(total * 0.30, 0.001));
      expect(plan.meal3Kg, closeTo(total * 0.30, 0.001));
      expect(plan.meal4Kg, closeTo(total * 0.20, 0.001));
    });

    test('mealsTotal equals exactly 100% of adjustedDailyFeedKg', () {
      final plan = feedAI.calculateDailyFeed(
        density: 55,
        areaHa: 1.2,
        survivalRate: 0.88,
        abw: 18.5,
        doc: 50,
        temperature: 33.5, // Heat stress (0.90)
        trayAdjustment: 0.08, // Tray boost (+8%)
      );

      expect(plan.mealsTotal, closeTo(plan.adjustedDailyFeedKg, 0.0001));
      expect(plan.tempFactor, 0.90);
      expect(plan.trayFactor, closeTo(1.08, 0.0001));
    });

    test('supports CheckTrayStatus parameter in calculateDailyFeed', () {
      final planClean = feedAI.calculateDailyFeed(
        density: 50,
        areaHa: 1.0,
        survivalRate: 0.80,
        abw: 15.0,
        doc: 40,
        temperature: 28.0,
        trayStatus: CheckTrayStatus.clean,
      );
      expect(planClean.trayFactor, 0.80);

      final planTrace = feedAI.calculateDailyFeed(
        density: 50,
        areaHa: 1.0,
        survivalRate: 0.80,
        abw: 15.0,
        doc: 40,
        temperature: 28.0,
        trayStatus: CheckTrayStatus.trace,
      );
      expect(planTrace.trayFactor, 1.10);
    });

    test('mealSchedule items contain formatted hours and Telugu labels', () {
      final plan = feedAI.calculateDailyFeed(
        density: 50,
        areaHa: 1.0,
        survivalRate: 0.85,
        abw: 16.0,
        doc: 45,
        temperature: 29.0,
      );

      expect(plan.mealSchedule.length, 4);
      expect(plan.mealSchedule[0].mealNumber, 1);
      expect(plan.mealSchedule[0].mealTime, '06:00 AM');
      expect(plan.mealSchedule[0].percentShare, 0.20);
      expect(plan.mealSchedule[0].teluguLabel, contains('ఉదయం'));

      expect(plan.mealSchedule[1].mealNumber, 2);
      expect(plan.mealSchedule[1].mealTime, '11:00 AM');
      expect(plan.mealSchedule[1].percentShare, 0.30);
      expect(plan.mealSchedule[1].teluguLabel, contains('మధ్యాహ్నం'));

      expect(plan.mealSchedule[2].mealNumber, 3);
      expect(plan.mealSchedule[2].mealTime, '04:00 PM');
      expect(plan.mealSchedule[2].percentShare, 0.30);
      expect(plan.mealSchedule[2].teluguLabel, contains('సాయంత్రం'));

      expect(plan.mealSchedule[3].mealNumber, 4);
      expect(plan.mealSchedule[3].mealTime, '09:00 PM');
      expect(plan.mealSchedule[3].percentShare, 0.20);
      expect(plan.mealSchedule[3].teluguLabel, contains('రాత్రి'));
    });

    test('DailyFeedPlan serializes to JSON correctly', () {
      final plan = feedAI.calculateDailyFeed(
        density: 50,
        areaHa: 1.0,
        survivalRate: 0.85,
        abw: 15.0,
        doc: 30,
        temperature: 28.0,
      );

      final json = plan.toJson();
      expect(json['biomassKg'], plan.biomassKg);
      expect(json['feedingRate'], plan.feedingRate);
      expect(json['adjustedDailyFeedKg'], plan.adjustedDailyFeedKg);
      expect(json['meal1Kg'], plan.meal1Kg);
      expect(json['mealsTotal'], plan.mealsTotal);
      expect(json['mealSchedule'], isList);
    });
  });

  group('FeedAIService — FCR & Growth Rate Metrics', () {
    const feedAI = FeedAIService();

    test('calculates FCR (Food Conversion Ratio) correctly', () {
      // 7,200 kg feed consumed to produce 6,000 kg harvested shrimp -> FCR = 7200 / 6000 = 1.20
      final fcr = feedAI.calculateFcr(
        totalFeedUsedKg: 7200.0,
        biomassHarvestedKg: 6000.0,
      );
      expect(fcr, closeTo(1.20, 0.01));
    });

    test('handles zero harvested biomass in FCR calculation safely', () {
      expect(feedAI.calculateFcr(totalFeedUsedKg: 5000, biomassHarvestedKg: 0), 0.0);
      expect(feedAI.calculateFcr(totalFeedUsedKg: 0, biomassHarvestedKg: 5000), 0.0);
    });

    test('calculates Average Daily Gain (ADG) in grams/day', () {
      // Grew from 10.0g to 18.0g over 20 days -> (18 - 10) / 20 = 0.40 g/day
      final adg = feedAI.calculateAdg(
        currentAbw: 18.0,
        previousAbw: 10.0,
        days: 20,
      );
      expect(adg, closeTo(0.40, 0.01));
    });

    test('handles invalid ADG time intervals and negative growth safely', () {
      expect(feedAI.calculateAdg(currentAbw: 18.0, previousAbw: 10.0, days: 0), 0.0);
      expect(feedAI.calculateAdg(currentAbw: 10.0, previousAbw: 18.0, days: 10), 0.0);
    });
  });
}
